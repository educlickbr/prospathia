import { DeleteObjectCommand } from "@aws-sdk/client-s3";
import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    if (!user) {
        throw createError({ statusCode: 401, statusMessage: "Unauthorized" });
    }

    const body = await readBody(event);
    const { file_id } = body;

    if (!file_id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing file_id",
        });
    }

    const client = await serverSupabaseClient(event);
    const r2 = useR2Client();

    // 1. Get file info
    const { data, error: fetchError } = await client
        .from("global_arquivos")
        .select("*")
        .eq("id", file_id)
        .single();

    // Cast strict type
    const fileRecord = data as any;

    if (fetchError || !fileRecord) {
        // If not found in DB, maybe already deleted? Just return success to be idempotent.
        console.warn(`File ${file_id} not found in DB during delete request.`);
        return {
            success: true,
            message: "File record not found (already deleted?)",
        };
    }

    const bucket = fileRecord.bucket || process.env.R2_BUCKET || "prospathia";
    const key = fileRecord.path;

    // 2. Delete from R2 (Best Effort)
    try {
        await r2.send(
            new DeleteObjectCommand({
                Bucket: bucket,
                Key: key,
            }),
        );
    } catch (r2Error: any) {
        // Log but proceed to DB delete.
        // We prioritize DB consistency (removing the record) even if R2 fails (orphaned file).
        console.error(`R2 Delete Error for ${key}:`, r2Error);
    }

    // 3. Delete from DB
    const { error: deleteError } = await client
        .from("global_arquivos")
        .delete()
        .eq("id", file_id);

    if (deleteError) {
        throw createError({
            statusCode: 500,
            statusMessage: `DB Delete Error: ${deleteError.message}`,
        });
    }

    return { success: true };
});
