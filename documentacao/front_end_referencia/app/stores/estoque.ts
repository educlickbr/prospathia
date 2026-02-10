import { defineStore } from "pinia";

export const useEstoqueStore = defineStore("estoque", {
    state: () => ({
        loading: false,
        error: null as string | null,
    }),
    actions: {
        async atualizarProduto(payload: {
            id: string;
            nome: string;
            id_categoria_produto: string;
            id_tipo_produto: string;
            id_unidade: string;
            treshold?: number;
            valor_inicial?: number;
            codigo_barras?: string;
            observacoes?: string;
            imagem_produto?: string;
            mostrar_mais?: boolean;
        }) {
            this.loading = true;
            this.error = null;

            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/produto",
                    {
                        method: "PUT",
                        body: payload,
                    },
                );

                if (!data.success) throw new Error(data.message);
                return data;
            } catch (err: any) {
                console.error("Erro ao atualizar produto:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async deletarProduto(id: string) {
            this.loading = true;
            this.error = null;

            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/produto",
                    {
                        method: "DELETE",
                        body: { id },
                    },
                );

                if (!data.success) throw new Error(data.message);
                return data;
            } catch (err: any) {
                console.error("Erro ao deletar produto:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async criarEstoque(payload: {
            id_produto: string;
            valor_inicial: number;
            id_sala?: string;
            reservas?: string;
            kit?: boolean;
            sala?: boolean;
        }) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;

            try {
                const { data, error } = await supabase.rpc(
                    "nxt_criar_estoque",
                    {
                        p_id_produto: payload.id_produto,
                        p_valor_inicial: payload.valor_inicial,
                        p_id_sala: payload.id_sala,
                        p_reservas: payload.reservas,
                        p_kit: payload.kit ?? false,
                        p_sala: payload.sala ?? false,
                    } as any,
                );

                if (error) throw error;
                return data; // UUID do estoque
            } catch (err: any) {
                console.error("Erro ao criar estoque:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async criarReserva(payload: {
            id_usuario: string;
            id_produto?: string;
            id_estoque?: string;
            data_retirada?: string; // ISO String
            data_devolucao?: string; // ISO String
            observacoes?: string;
        }) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;

            try {
                const { data, error } = await supabase.rpc(
                    "nxt_criar_reserva",
                    {
                        p_id_usuario: payload.id_usuario,
                        p_id_produto: payload.id_produto,
                        p_id_estoque: payload.id_estoque,
                        p_data_retirada: payload.data_retirada,
                        p_data_devolucao: payload.data_devolucao,
                        p_observacoes: payload.observacoes,
                    } as any,
                );

                if (error) throw error;
                return data; // { success: true, ... }
            } catch (err: any) {
                console.error("Erro ao criar reserva:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async devolverReserva(payload: {
            id_reserva: string;
            usuario_devolveu: string;
            observacoes?: string;
        }) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;

            try {
                const { data, error } = await supabase.rpc(
                    "nxt_devolver_reserva",
                    {
                        p_id_reserva: payload.id_reserva,
                        p_usuario_devolveu: payload.usuario_devolveu,
                        p_observacoes: payload.observacoes,
                    } as any,
                );

                if (error) throw error;
                return data;
            } catch (err: any) {
                console.error("Erro ao devolver reserva:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async getReservas(
            params: {
                page?: number;
                limit?: number;
                busca?: string;
                status?: string;
                userId?: string;
            } = {},
        ) {
            this.loading = true;
            this.error = null;
            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/reservas",
                    {
                        params: {
                            page: params.page || 1,
                            limit: params.limit || 12,
                            busca: params.busca,
                            status: params.status,
                            userId: params.userId,
                        },
                    },
                );
                return data;
            } catch (err: any) {
                console.error("Erro ao buscar reservas:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async atualizarStatusReserva(
            payload: { ids: string[]; status: string },
        ) {
            this.loading = true;
            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/reserva-status",
                    {
                        method: "PUT",
                        body: payload,
                    },
                );
                return data;
            } catch (err: any) {
                console.error("Erro ao atualizar status da reserva:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async deletarReserva(ids: string[]) {
            this.loading = true;
            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/reserva",
                    {
                        method: "DELETE",
                        body: { ids },
                    },
                );
                return data;
            } catch (err: any) {
                console.error("Erro ao deletar reserva:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async getReservaItens(ids: string[]) {
            this.loading = true;
            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/reserva-itens",
                    {
                        method: "POST",
                        body: { ids },
                    },
                );
                return data;
            } catch (err: any) {
                console.error("Erro ao buscar detalhes da reserva:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async searchProdutos(busca: string = "") {
            try {
                return await $fetch(
                    "/api/producao/estoque/produtos-disponiveis",
                    {
                        params: { busca },
                    },
                );
            } catch (err) {
                console.error("Erro ao buscar produtos:", err);
                return [];
            }
        },

        async searchUsers(busca: string = "", papeis: string[] = []) {
            try {
                return await $fetch("/api/producao/estoque/users-reserva", {
                    params: { busca, papeis },
                });
            } catch (err) {
                console.error("Erro ao buscar usuários:", err);
                return [];
            }
        },

        async getPapeis() {
            try {
                return await $fetch("/api/producao/estoque/papeis");
            } catch (err) {
                console.error("Erro ao buscar papéis:", err);
                return [];
            }
        },

        async createReserva(
            payload: {
                id_usuario: string;
                id_produto: string;
                quantidade: number;
                data_retirada: string;
                data_devolucao: string;
            },
        ) {
            this.loading = true;
            try {
                const data = await $fetch("/api/producao/estoque/reserva", {
                    method: "POST",
                    body: payload,
                });
                return data;
            } catch (err: any) {
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async getItensEstoque(
            payload: { page?: number; limit?: number; busca?: string } = {},
        ) {
            this.loading = true;
            this.error = null;
            try {
                const data: any = await $fetch("/api/producao/estoque/itens", {
                    params: {
                        page: payload.page,
                        limit: payload.limit,
                        busca: payload.busca,
                    },
                });
                return data;
            } catch (err: any) {
                console.error("Erro ao buscar itens de estoque:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        // --- KITS ACTIONS ---

        async getKits() {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;
            try {
                const { data, error } = await (supabase
                    .from("produto_kit") as any)
                    .select("*")
                    .order("nome");
                if (error) throw error;
                return data;
            } catch (err: any) {
                console.error("Erro ao buscar kits:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async criarKit(payload: { nome: string }) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;
            try {
                const { data, error } = await (supabase
                    .from("produto_kit") as any)
                    .insert({ nome: payload.nome })
                    .select()
                    .single();
                if (error) throw error;
                return data;
            } catch (err: any) {
                console.error("Erro ao criar kit:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async atualizarKit(payload: { id: string; nome: string }) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;
            try {
                const { data, error } = await (supabase
                    .from("produto_kit") as any)
                    .update({ nome: payload.nome, updated_at: new Date() })
                    .eq("id", payload.id)
                    .select()
                    .single();
                if (error) throw error;
                return data;
            } catch (err: any) {
                console.error("Erro ao atualizar kit:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async deletarKit(id: string) {
            const supabase = useSupabaseClient();
            this.loading = true;
            this.error = null;
            try {
                const { error } = await (supabase
                    .from("produto_kit") as any)
                    .delete()
                    .eq("id", id);
                if (error) throw error;
            } catch (err: any) {
                console.error("Erro ao deletar kit:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        // --- PRODUTOS ACTIONS ---

        async getProdutos(payload: {
            busca?: string;
            categoria?: string;
            tipo?: string;
            page?: number;
            limit?: number;
        }) {
            this.loading = true;
            this.error = null;

            try {
                // Using BFF (App API) instead of direct Supabase RPC
                const data = await $fetch("/api/producao/estoque/produtos", {
                    params: {
                        busca: payload.busca,
                        categoria: payload.categoria,
                        tipo: payload.tipo,
                        page: payload.page,
                        limit: payload.limit,
                    },
                });

                return data; // Returns { itens: [], qtd_paginas: ... }
            } catch (err: any) {
                console.error("Erro ao buscar produtos:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async adicionarEstoqueLote(payload: {
            id_produto: string;
            quantidade: number;
            valor_inicial?: number;
        }) {
            this.loading = true;
            this.error = null;

            try {
                const data = await $fetch(
                    "/api/producao/estoque/adicionar-lote",
                    {
                        method: "POST",
                        body: payload,
                    },
                );
                return data;
            } catch (err: any) {
                console.error("Erro ao adicionar estoque em lote:", err);
                this.error = err.message;
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async getCategorias() {
            return await $fetch("/api/producao/estoque/categorias");
        },

        async getUnidades() {
            return await $fetch("/api/producao/estoque/unidades");
        },

        async getTipos() {
            return await $fetch("/api/producao/estoque/tipos");
        },

        async criarProduto(payload: any) {
            this.loading = true;
            try {
                const data: any = await $fetch(
                    "/api/producao/estoque/produto",
                    {
                        method: "POST",
                        body: payload,
                    },
                );

                if (!data.success) throw new Error(data.message);
                return data;
            } catch (err: any) {
                console.error("Erro ao criar produto:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        // --- AVARIAS ACTIONS ---

        async criarAvaria(payload: {
            id_produto_estoque: string;
            id_produto: string;
            descricao: string;
            observacoes?: string;
            status_reparo: string;
            tipo_avaria?: string;
        }) {
            this.loading = true;
            try {
                const data: any = await $fetch("/api/producao/estoque/avaria", {
                    method: "POST",
                    body: payload,
                });
                return data;
            } catch (err: any) {
                console.error("Erro ao criar avaria:", err);
                throw err; // Re-throw to handle in component
            } finally {
                this.loading = false;
            }
        },

        async atualizarAvaria(payload: {
            id: string;
            descricao: string;
            observacoes?: string;
            status_reparo: string;
            tipo_avaria?: string;
        }) {
            this.loading = true;
            try {
                const data: any = await $fetch("/api/producao/estoque/avaria", {
                    method: "PUT",
                    body: payload,
                });
                return data;
            } catch (err: any) {
                console.error("Erro ao atualizar avaria:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async deletarEstoque(id: string) {
            this.loading = true;
            try {
                await $fetch("/api/producao/estoque/item", {
                    method: "DELETE",
                    body: { id },
                });
            } catch (err: any) {
                console.error("Erro ao deletar item de estoque:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        async associarKit(idItem: string, idKit: string | null) {
            this.loading = true;
            try {
                await $fetch("/api/producao/estoque/associate", {
                    method: "PUT",
                    body: { id_item: idItem, id_kit: idKit },
                });
            } catch (err: any) {
                console.error("Erro ao associar kit:", err);
                throw err;
            } finally {
                this.loading = false;
            }
        },

        // --- DASHBOARD ACTIONS ---

        async getDashboardStats() {
            try {
                return await $fetch("/api/producao/dashboard/stats");
            } catch (err) {
                console.error(
                    "Erro ao carregar estatísticas do dashboard:",
                    err,
                );
                return null;
            }
        },

        async getDashboardWeekly() {
            try {
                return await $fetch("/api/producao/dashboard/weekly");
            } catch (err) {
                console.error("Erro ao carregar agenda semanal:", err);
                return [];
            }
        },

        async getRecentActivity() {
            try {
                return await $fetch("/api/producao/dashboard/activity");
            } catch (err) {
                console.error("Erro ao carregar atividades recentes:", err);
                return [];
            }
        },
    },
});
