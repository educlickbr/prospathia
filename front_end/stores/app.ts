import { defineStore } from "pinia";

// Role Definitions
export const ROLES = {
    ADMIN: "a1229ff7-4c3f-4b12-8271-81e752684117",
    CLIENTE: "67ed3bd7-72ef-4d92-b43b-78250874be1e",
    PACIENTE: "7f33da80-6bd8-48af-869e-eba4a0878666",
    COLABORADOR: "a5a1ac8a-9ffd-4e4d-8a5f-ea62d5f722e2",
    CLINICA: "2f5bfeb9-e9ff-4335-9e74-33c2f3d25f0d",
};

export const useAppStore = defineStore("app", {
    state: () => ({
        user: null as any,
        profile: null as any,
        company: null as any,
        role: null as any,

        // Expanded Profile Data
        user_expandido_id: null as string | null,
        nome_completo: null as string | null,
        email: null as string | null,
        telefone: null as string | null,
        imagem_user: null as string | null,
        status: true as boolean,

        hash_base: null as string | null,
        auth_token: null as string | null,
        auth_expires: null as number | null,
        auth_scope: null as string | null,

        initialized: false,
        isLoading: false,
        isMenuOpen: false,
        isDark: false,
        statusMessage: {
            title: null as string | null,
            message: null as string | null,
            type: "info" as "success" | "error" | "info" | null,
            actionLabel: null as string | null,
            actionPath: null as string | null,
        },
        // Product Data
        produto: null as {
            id: string;
            nome: string;
            logo_maior: string;
            logo_menor: string;
            ativo: boolean;
        } | null,
    }),
    actions: {
        async initProduct() {
            if (this.produto) return; // Already loaded

            const supabase = useSupabaseClient();
            try {
                // Get domain from window
                const domain = window.location.origin;

                const { data, error } = await supabase.rpc(
                    "nxt_verificar_produto",
                    {
                        p_dominio: domain,
                    } as any,
                ) as { data: any; error: any };

                if (error) throw error;

                if (data && data.encontrado) {
                    this.produto = {
                        id: data.id,
                        nome: data.nome,
                        logo_maior: data.logo_maior,
                        logo_menor: data.logo_menor,
                        ativo: data.ativo,
                    };

                    // Set favicon/title if needed?
                } else {
                    console.error("Produto não encontrado para este domínio.");
                }
            } catch (err) {
                console.error("Erro ao verificar produto:", err);
            }
        },

        async initSession() {
            // First ensure product is loaded
            await this.initProduct();

            const supabase = useSupabaseClient();

            try {
                // Call new RPC with product ID
                const { data, error } = await supabase.rpc(
                    "nxt_credenciais_user_front",
                    {
                        p_produto_id: this.produto?.id || null,
                    } as any,
                ) as { data: any; error: any };

                if (error) throw error;

                if (data) {
                    // Map RPC response to store state
                    // user_expandido
                    if (data.user) {
                        this.user_expandido_id = data.user.id;
                        this.nome_completo = data.user.nome_completo;
                        this.email = data.user.email;
                        this.telefone = data.user.telefone;
                        this.imagem_user = data.user.imagem_user;
                        this.status = data.user.status;

                        // Update base user object (partial)
                        this.user = {
                            id: data.user.user_id,
                            email: data.user.email,
                            // other fields...
                        };
                    }

                    // roles
                    // For now, take the first role or map correctly.
                    // Current store expects a single 'role' object.
                    // New RPC returns 'roles' array.
                    if (data.roles && data.roles.length > 0) {
                        // Logic to pick active role? Or just taking first for now.
                        const firstRole = data.roles[0];
                        this.role = {
                            papel_id: firstRole.role_id,
                            nome: firstRole.nome_role,
                            // Add clinica_id if store supports it
                        };
                    }

                    // Clinica
                    // this.company = data.clinicas; // Map if structure matches
                }
            } catch (err) {
                console.warn("RPC nxt_credenciais_user_front falhou:", err);
                // Fallback to old method if needed? Or just fail.

                // LEGACY FALLBACK (Keep old logic temporarily or remove?)
                // Assuming we want to switch completely.
                // If RPC fails, maybe user is not logged in properly or migration not applied.
            }

            this.initialized = true;
        },
        clearProfile() {
            this.user = null;
            this.profile = null;
            this.role = null;

            this.user_expandido_id = null;
            this.nome_completo = null;
            this.email = null;
            this.telefone = null;
            this.imagem_user = null;
            this.status = true;

            this.hash_base = null;
        },
        async logout() {
            const supabase = useSupabaseClient();
            await supabase.auth.signOut();

            // Clear session data locally
            this.clearProfile();

            // Re-fetch to normalize state
            await this.initSession();
        },
        hasRole(allowedRoles: string[]) {
            if (!this.role) return false;
            return allowedRoles.includes(this.role.papel_id);
        },
        setLoading(val: boolean) {
            this.isLoading = val;
        },
        toggleMenu() {
            this.isMenuOpen = !this.isMenuOpen;
        },
        toggleTheme() {
            this.isDark = !this.isDark;
            if (import.meta.client) {
                if (this.isDark) {
                    document.documentElement.setAttribute("data-theme", "dark");
                } else document.documentElement.removeAttribute("data-theme");
                localStorage.setItem("theme", this.isDark ? "dark" : "light");
            }
        },
        initTheme() {
            if (import.meta.client) {
                const savedTheme = localStorage.getItem("theme");
                this.isDark = savedTheme === "dark" ||
                    (!savedTheme &&
                        window.matchMedia("(prefers-color-scheme: dark)")
                            .matches);
                if (this.isDark) {
                    document.documentElement.setAttribute("data-theme", "dark");
                } else document.documentElement.removeAttribute("data-theme");
            }
        },
        setStatusMessage(
            payload: {
                title?: string;
                message?: string;
                type?: "success" | "error" | "info";
                actionLabel?: string;
                actionPath?: string;
            },
        ) {
            this.statusMessage = {
                title: payload.title || null,
                message: payload.message || null,
                type: payload.type || "info",
                actionLabel: payload.actionLabel || null,
                actionPath: payload.actionPath || null,
            };
        },
        /**
         * 🔄 Renova APENAS a hash do Bunny.net
         * Útil quando a hash expira (5 min) mas não queremos refazer todo o /api/me
         * Muito mais leve: só 1 chamada (hash_app) vs 2 (hash_app + get_user_expandido)
         */
        async refreshHash() {
            try {
                const data = await $fetch("/api/refresh-hash") as any;

                if (data.token) {
                    // Store all necessary Auth params
                    this.hash_base = data.worker_url; // Base URL
                    this.auth_token = data.token;
                    this.auth_expires = data.expires;
                    this.auth_scope = data.scope;

                    console.log("✅ Hash R2 renovada:", data.refreshed_at);
                } else {
                    console.warn("⚠️ Falha ao renovar hash R2:", data);
                }

                return data.token;
            } catch (err) {
                console.error("Erro ao renovar hash:", err);
                return null;
            }
        },
        /**
         * 🔐 Gera URL assinada para o R2 (Worker)
         */
        getSignedUrl(path: string | null) {
            if (!path) {
                return "https://ui-avatars.com/api/?background=random&name=User";
            }
            if (path.startsWith("http")) return path;

            if (!this.hash_base || !this.auth_token) {
                return path;
            }

            const base = this.hash_base.endsWith("/")
                ? this.hash_base
                : this.hash_base + "/";
            const cleanPath = path.startsWith("/") ? path.slice(1) : path;

            return `${base}${cleanPath}?token=${
                encodeURIComponent(this.auth_token)
            }&expires=${this.auth_expires}&scope=${
                encodeURIComponent(this.auth_scope || "/")
            }`;
        },
    },
});
