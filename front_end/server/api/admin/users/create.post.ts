import { serverSupabaseServiceRole } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = serverSupabaseServiceRole(event); // Must use Service Role for Admin User Creation

    // Validate Body
    if (
        !body.email || !body.password || !body.nome_completo ||
        !body.produto_id || !body.papel_id
    ) {
        throw createError({
            statusCode: 400,
            statusMessage:
                "Missing required fields: email, password, nome_completo, produto_id, papel_id",
        });
    }

    // 1. Create Auth User
    const { data: authData, error: authError } = await client.auth.admin
        .createUser({
            email: body.email,
            password: body.password,
            email_confirm: true,
            user_metadata: {
                nome_completo: body.nome_completo,
            },
        });

    if (authError) {
        throw createError({
            statusCode: 500,
            statusMessage: `Auth Error: ${authError.message}`,
        });
    }

    const userId = authData.user.id;

    try {
        // 2. Insert into user_expandido and return ID
        const { data: userExpanded, error: expandidoError } = await (client
            .from("user_expandido") as any)
            .insert({
                user_id: userId,
                nome_completo: body.nome_completo,
                email: body.email,
                telefone: body.telefone || null,
                status: true,
            })
            .select()
            .single();

        if (expandidoError) throw expandidoError;
        if (!userExpanded) throw new Error("Failed to create expanded user");

        // 3. Insert into user_role_auth
        const { error: roleError } = await (client
            .from("user_role_auth") as any)
            .insert({
                user_id: userId,
                role_id: body.papel_id,
                clinica_id: body.empresa_id || null, // Optional context
            });

        if (roleError) throw roleError;

        // 4. Insert into produtos_user (Grant access to product)
        const { error: prodError } = await (client
            .from("produtos_user") as any)
            .insert({
                user_id: userId,
                produto_id: body.produto_id,
                status: true,
                id_user_expandido: userExpanded.id,
            });

        if (prodError) throw prodError;

        // 5. Save Answers (using upsert RPC)
        if (body.respostas && body.respostas.length > 0) {
            const { error: rpcError } = await client.rpc(
                "nxt_upsert_user_completo",
                {
                    p_user_id: userExpanded.id, // Must be user_expandido ID
                    p_dados_user: {}, // Already set
                    p_respostas: body.respostas,
                    p_produto_id: body.produto_id,
                } as any,
            );

            if (rpcError) throw rpcError;
        }

        return { success: true, user_id: userId };
    } catch (err: any) {
        // Rollback Auth User if DB fails?
        // Ideally yes, but complex. For now just throw.
        await client.auth.admin.deleteUser(userId);
        throw createError({
            statusCode: 500,
            statusMessage: `DB Error: ${err.message}`,
        });
    }
});
