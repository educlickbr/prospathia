import {
    serverSupabaseClient,
    serverSupabaseServiceRole,
} from "#supabase/server";

export default defineEventHandler(async (event) => {
    try {
        // Use Service Role to bypass RLS if needed, or just admin client
        const client = serverSupabaseServiceRole(event);
        if (!client) {
            throw new Error(
                "Service Role client init failed. Check SUPABASE_SERVICE_KEY",
            );
        }

        const updates = [
            {
                id: "ec2a9eb1-c9fa-4721-ab86-522419a77be4",
                updates: {
                    label: "Tipo de Pessoa",
                    tipo_pergunta: "opcao",
                    opcoes: ["Pessoa Física", "Pessoa Jurídica"],
                    largura: 2,
                    obrigatorio: false,
                    depende: false,
                    depende_de: null,
                    valor_depende: null,
                },
            },
            {
                id: "3a70c50f-7851-44cb-83d6-2735471cb192",
                updates: {
                    label: "CNPJ",
                    tipo_pergunta: "texto",
                    opcoes: null,
                    largura: 1,
                    obrigatorio: false,
                    depende: true,
                    depende_de: "ec2a9eb1-c9fa-4721-ab86-522419a77be4",
                    valor_depende: "Pessoa Jurídica",
                },
            },
            {
                id: "587b003c-caf8-4447-b024-98ad6c00d60c",
                updates: {
                    label: "Razão Social",
                    tipo_pergunta: "texto",
                    opcoes: null,
                    largura: 1,
                    obrigatorio: false,
                    depende: true,
                    depende_de: "ec2a9eb1-c9fa-4721-ab86-522419a77be4",
                    valor_depende: "Pessoa Jurídica",
                },
            },
            {
                id: "689ed8fe-77a4-4360-8703-45d7ff7ecfb7",
                updates: {
                    label: "CPF",
                    tipo_pergunta: "texto",
                    largura: 1,
                    depende: false,
                    depende_de: null,
                },
            },
            {
                id: "f11f7e7e-6dd7-4bec-a9b9-e053b68b6e96",
                updates: {
                    label: "RG",
                    tipo_pergunta: "texto",
                    largura: 1,
                    depende: false,
                    depende_de: null,
                },
            },
            {
                id: "a73e2281-601c-4aa0-92f5-3a2b6801d4da",
                updates: {
                    label: "Sexo",
                    tipo_pergunta: "opcao",
                    opcoes: ["Masculino", "Feminino", "Outro"],
                    largura: 1,
                },
            },
            {
                id: "8608311c-9efb-41eb-91e5-9d0e8f3f0fb5",
                updates: {
                    label: "Data de Nascimento",
                    tipo_pergunta: "data",
                    largura: 1,
                },
            },
            {
                id: "93a82ea3-4af3-4af3-b004-c38a9d1d7b1c",
                updates: {
                    label: "Tipo de Credenciamento",
                    tipo_pergunta: "texto",
                },
            },
            {
                id: "939e5538-4310-41af-8be4-412f265446a9",
                updates: {
                    label: "Número de Credenciamento",
                    tipo_pergunta: "texto",
                },
            },
            {
                id: "ba5156e9-0731-461b-a223-ccceb6559d63",
                updates: { label: "CEP", tipo_pergunta: "texto" },
            },
            {
                id: "9587e6e9-9c3e-44ec-9644-e51df152b540",
                updates: { label: "Cidade", tipo_pergunta: "texto" },
            },
            {
                id: "43f68369-68f3-46de-bbdd-7845b85fd830",
                updates: { label: "Estado", tipo_pergunta: "texto" },
            },
            {
                id: "051d7b53-8a55-4b05-9169-011e2183495a",
                updates: { label: "Endereço", tipo_pergunta: "texto" },
            },
            {
                id: "4ace6765-7c13-47b2-a7f5-b12c794026e9",
                updates: { label: "Número", tipo_pergunta: "texto" },
            },
            {
                id: "3b0b4c51-5fa2-4e9b-b36c-b2793a9447ec",
                updates: { label: "Complemento", tipo_pergunta: "texto" },
            },
            {
                id: "22e335ed-b108-40c0-ab13-f1afdc6c9eeb",
                updates: { label: "Bairro", tipo_pergunta: "texto" },
            },
        ];

        const results = [];

        for (const item of updates) {
            const { error } = await (client
                .from("perguntas_user") as any)
                .update(item.updates)
                .eq("id", item.id);

            if (error) {
                console.error(`Error updating ${item.id}:`, error);
                results.push({ id: item.id, error });
            } else {
                results.push({ id: item.id, success: true });
            }
        }

        return { results };
    } catch (e: any) {
        console.error("Migration Error:", e);
        return { error: e.message, stack: e.stack };
    }
});
