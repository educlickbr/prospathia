import { PutObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from "uuid";
import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const config = useRuntimeConfig();
    // Hardcoded source for this migration
    const BUNNY_BASE_URL = "https://otolithics-s.b-cdn.net/usr/";
    const BUCKET = process.env.R2_BUCKET || "prospathia";

    const client = await serverSupabaseClient(event);
    const r2 = useR2Client();

    // 1. Fetch Users with images
    const { data, error } = await client
        .from("user_expandido")
        .select("id, user_id, imagem_user")
        .not("imagem_user", "is", null);

    if (error) {
        throw createError({ statusCode: 500, statusMessage: error.message });
    }

    const users = data as any[]; // Cast to any[]

    const results = {
        total: users.length,
        migrated: 0,
        failed: 0,
        errors: [] as string[],
    };

    console.log(`Starting migration for ${users.length} users...`);

    for (const user of users) {
        try {
            const oldFilename = user.imagem_user;
            if (!oldFilename) continue;

            const fileUrl = `${BUNNY_BASE_URL}${oldFilename}`;

            // 2. Download from Bunny
            const response = await fetch(fileUrl);
            if (!response.ok) {
                // Ignore 404s silently or log as warning?
                // If 404, maybe it's already migrated or lost?
                console.warn(
                    `Bunny Fetch Error (Skipping): ${response.statusText} (${fileUrl})`,
                );
                continue;
            }

            const arrayBuffer = await response.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);

            // Detect Mime (basic)
            const contentType = response.headers.get("content-type") ||
                "application/octet-stream";
            const ext = oldFilename.split(".").pop() || "bin";
            const newFilename = `${uuidv4()}.${ext}`;

            // 3. Upload to R2
            await r2.send(
                new PutObjectCommand({
                    Bucket: BUCKET,
                    Key: newFilename,
                    Body: buffer,
                    ContentType: contentType,
                }),
            );

            // 4. Record in global_arquivos
            const { error: dbError } = await client
                .from("global_arquivos")
                .insert({
                    nome_original: oldFilename,
                    path: newFilename,
                    mimetype: contentType,
                    tamanho_bytes: buffer.length,
                    bucket: BUCKET,
                    criado_por: user.user_id,
                    empresa_id: null,
                } as any) // Cast payload
                .select()
                .single();

            if (dbError) throw new Error(`DB Insert Error: ${dbError.message}`);

            // 5. Update user_expandido
            const { error: updateError } = await (client
                .from("user_expandido") as any)
                .update({ imagem_user: newFilename })
                .eq("id", user.id);

            if (updateError) {
                throw new Error(`User Update Error: ${updateError.message}`);
            }

            results.migrated++;
            console.log(
                `Migrated user ${user.id}: ${oldFilename} -> ${newFilename}`,
            );
        } catch (err: any) {
            results.failed++;
            results.errors.push(
                `User ${user.id} (${user.imagem_user}): ${err.message}`,
            );
            console.error(`Migration Failed for user ${user.id}:`, err.message);
        }
    }

    return results;
});
