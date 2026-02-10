import { PutObjectCommand } from "@aws-sdk/client-s3";
import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";
import { v4 as uuidv4 } from "uuid";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({ statusCode: 401, statusMessage: "Unauthorized" });
    }

    // Read Files
    const files = await readMultipartFormData(event);
    if (!files || files.length === 0) {
        throw createError({
            statusCode: 400,
            statusMessage: "No file uploaded",
        });
    }

    const file = files[0]; // Assume single file for now
    const client = await serverSupabaseClient(event);
    const r2 = useR2Client();

    // Metadata
    const ext = file.filename?.split(".").pop() || "bin";
    const newFilename = `${uuidv4()}.${ext}`;
    const mimetype = file.type || "application/octet-stream";
    const bucket = process.env.R2_BUCKET || "default-bucket";

    try {
        // 1. Upload to R2
        const command = new PutObjectCommand({
            Bucket: bucket,
            Key: newFilename,
            Body: file.data,
            ContentType: mimetype,
        });

        await r2.send(command);

        // 2. Save metadata to global_arquivos
        const { data, error } = await client
            .from("global_arquivos")
            .insert({
                nome_original: file.filename,
                path: newFilename,
                mimetype: mimetype,
                tamanho_bytes: file.data.length,
                bucket: bucket,
                criado_por: user.id,
                // empresa_id: optional, can be passed via body if needed
            } as any)
            .select()
            .single();

        if (error) throw error;

        return {
            success: true,
            file: data,
        };
    } catch (err: any) {
        console.error("Upload Error:", err);
        throw createError({
            statusCode: 500,
            statusMessage: `Upload Failed: ${err.message}`,
        });
    }
});
