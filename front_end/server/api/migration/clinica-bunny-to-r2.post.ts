import { PutObjectCommand } from "@aws-sdk/client-s3";
import { v4 as uuidv4 } from "uuid";
import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    // Hardcoded source (User confirmed same folder)
    const BUNNY_BASE_URL = "https://otolithics-s.b-cdn.net/usr/";
    const BUCKET = process.env.R2_BUCKET || "prospathia";
    // Admin ID provided by user to satisfy FK constraint during migration
    const ADMIN_AUTH_ID = "1c2b0bac-1bde-4d9f-8561-7f9d1a26eb2d";

    const client = await serverSupabaseClient(event);
    const r2 = useR2Client(); // Use the working composable

    // 1. Fetch Clinicas with images
    const { data, error } = await client
        .from("clinica")
        .select("id, user_id, nome, imagem_clinica")
        .not("imagem_clinica", "is", null);

    if (error) {
        throw createError({ statusCode: 500, statusMessage: error.message });
    }

    const clinicas = data as any[];
    const results = {
        total: clinicas.length,
        migrated: 0,
        failed: 0,
        errors: [] as string[],
    };

    console.log(`Starting migration for ${clinicas.length} clinicas...`);

    for (const clinica of clinicas) {
        try {
            const oldFilename = clinica.imagem_clinica;
            if (!oldFilename) continue;

            const fileUrl = oldFilename.startsWith("http")
                ? oldFilename
                : `${BUNNY_BASE_URL}${oldFilename}`;

            // 2. Download from Bunny
            const response = await fetch(fileUrl);
            if (!response.ok) {
                console.warn(
                    `Bunny Fetch Error (Skipping): ${response.statusText} (${fileUrl})`,
                );
                continue;
            }

            const arrayBuffer = await response.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);

            const contentType = response.headers.get("content-type") ||
                "application/octet-stream";
            const ext = oldFilename.split(".").pop() || "jpg";
            const newFilename = `${uuidv4()}.${ext}`;

            // 3. Upload to R2
            await r2.send(
                new PutObjectCommand({
                    Bucket: BUCKET,
                    Key: newFilename,
                    Body: buffer,
                    ContentType: contentType,
                    Metadata: {
                        original_name: oldFilename,
                        migrated_from: "bunny_clinica",
                        clinica_id: clinica.id,
                    },
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
                    criado_por: ADMIN_AUTH_ID, // Use provided Admin ID
                    empresa_id: clinica.id,
                } as any)
                .select()
                .single();

            if (dbError) throw new Error(`DB Insert Error: ${dbError.message}`);

            // 5. Update clinica
            const { error: updateError } = await (client
                .from("clinica") as any)
                .update({ imagem_clinica: newFilename })
                .eq("id", clinica.id);

            if (updateError) {
                throw new Error(`Clinica Update Error: ${updateError.message}`);
            }

            results.migrated++;
            console.log(
                `Migrated clinica ${clinica.id}: ${oldFilename} -> ${newFilename}`,
            );
        } catch (err: any) {
            results.failed++;
            results.errors.push(`Clinica ${clinica.nome}: ${err.message}`);
            console.error(
                `Migration Failed for clinica ${clinica.id}:`,
                err.message,
            );
        }
    }

    return results;
});
