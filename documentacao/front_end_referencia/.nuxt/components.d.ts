
import type { DefineComponent, SlotsType } from 'vue'
type IslandComponent<T> = DefineComponent<{}, {refresh: () => Promise<void>}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, SlotsType<{ fallback: { error: unknown } }>> & T

type HydrationStrategies = {
  hydrateOnVisible?: IntersectionObserverInit | true
  hydrateOnIdle?: number | true
  hydrateOnInteraction?: keyof HTMLElementEventMap | Array<keyof HTMLElementEventMap> | true
  hydrateOnMediaQuery?: string
  hydrateAfter?: number
  hydrateWhen?: boolean
  hydrateNever?: true
}
type LazyComponent<T> = DefineComponent<HydrationStrategies, {}, {}, {}, {}, {}, {}, { hydrated: () => void }> & T


export const BaseSelect: typeof import("../app/components/BaseSelect.vue").default
export const CandidateCard: typeof import("../app/components/CandidateCard.vue").default
export const CandidateDashboard: typeof import("../app/components/CandidateDashboard.vue").default
export const ConfirmationModal: typeof import("../app/components/ConfirmationModal.vue").default
export const FullPageMenu: typeof import("../app/components/FullPageMenu.vue").default
export const LoadingOverlay: typeof import("../app/components/LoadingOverlay.vue").default
export const ModalDadosCandidato: typeof import("../app/components/ModalDadosCandidato.vue").default
export const ModalDiario: typeof import("../app/components/ModalDiario.vue").default
export const ModalFichaAvaliacao: typeof import("../app/components/ModalFichaAvaliacao.vue").default
export const ModalListaHomologados: typeof import("../app/components/ModalListaHomologados.vue").default
export const ModalListaSelecionados: typeof import("../app/components/ModalListaSelecionados.vue").default
export const ModalMeusDocumentos: typeof import("../app/components/ModalMeusDocumentos.vue").default
export const ModalStatusMatricula: typeof import("../app/components/ModalStatusMatricula.vue").default
export const EducacionalCalendarioTurma: typeof import("../app/components/educacional/CalendarioTurma.vue").default
export const EducacionalModalAulaExtra: typeof import("../app/components/educacional/ModalAulaExtra.vue").default
export const EducacionalModalCurso: typeof import("../app/components/educacional/ModalCurso.vue").default
export const EducacionalModalTurma: typeof import("../app/components/educacional/ModalTurma.vue").default
export const ProducaoModalRelatorioSemanal: typeof import("../app/components/producao/ModalRelatorioSemanal.vue").default
export const ProducaoModalReservaSala: typeof import("../app/components/producao/ModalReservaSala.vue").default
export const ProducaoModalSala: typeof import("../app/components/producao/ModalSala.vue").default
export const ProducaoEstoqueAvariasModal: typeof import("../app/components/producao/estoque/AvariasModal.vue").default
export const ProducaoEstoqueKitFormModal: typeof import("../app/components/producao/estoque/KitFormModal.vue").default
export const ProducaoEstoqueProductFormModal: typeof import("../app/components/producao/estoque/ProductFormModal.vue").default
export const ProducaoEstoqueReservationFormModal: typeof import("../app/components/producao/estoque/ReservationFormModal.vue").default
export const NuxtWelcome: typeof import("../node_modules/nuxt/dist/app/components/welcome.vue").default
export const NuxtLayout: typeof import("../node_modules/nuxt/dist/app/components/nuxt-layout").default
export const NuxtErrorBoundary: typeof import("../node_modules/nuxt/dist/app/components/nuxt-error-boundary.vue").default
export const ClientOnly: typeof import("../node_modules/nuxt/dist/app/components/client-only").default
export const DevOnly: typeof import("../node_modules/nuxt/dist/app/components/dev-only").default
export const ServerPlaceholder: typeof import("../node_modules/nuxt/dist/app/components/server-placeholder").default
export const NuxtLink: typeof import("../node_modules/nuxt/dist/app/components/nuxt-link").default
export const NuxtLoadingIndicator: typeof import("../node_modules/nuxt/dist/app/components/nuxt-loading-indicator").default
export const NuxtTime: typeof import("../node_modules/nuxt/dist/app/components/nuxt-time.vue").default
export const NuxtRouteAnnouncer: typeof import("../node_modules/nuxt/dist/app/components/nuxt-route-announcer").default
export const NuxtImg: typeof import("../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtImg
export const NuxtPicture: typeof import("../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtPicture
export const NuxtPage: typeof import("../node_modules/nuxt/dist/pages/runtime/page").default
export const NoScript: typeof import("../node_modules/nuxt/dist/head/runtime/components").NoScript
export const Link: typeof import("../node_modules/nuxt/dist/head/runtime/components").Link
export const Base: typeof import("../node_modules/nuxt/dist/head/runtime/components").Base
export const Title: typeof import("../node_modules/nuxt/dist/head/runtime/components").Title
export const Meta: typeof import("../node_modules/nuxt/dist/head/runtime/components").Meta
export const Style: typeof import("../node_modules/nuxt/dist/head/runtime/components").Style
export const Head: typeof import("../node_modules/nuxt/dist/head/runtime/components").Head
export const Html: typeof import("../node_modules/nuxt/dist/head/runtime/components").Html
export const Body: typeof import("../node_modules/nuxt/dist/head/runtime/components").Body
export const NuxtIsland: typeof import("../node_modules/nuxt/dist/app/components/nuxt-island").default
export const LazyBaseSelect: LazyComponent<typeof import("../app/components/BaseSelect.vue").default>
export const LazyCandidateCard: LazyComponent<typeof import("../app/components/CandidateCard.vue").default>
export const LazyCandidateDashboard: LazyComponent<typeof import("../app/components/CandidateDashboard.vue").default>
export const LazyConfirmationModal: LazyComponent<typeof import("../app/components/ConfirmationModal.vue").default>
export const LazyFullPageMenu: LazyComponent<typeof import("../app/components/FullPageMenu.vue").default>
export const LazyLoadingOverlay: LazyComponent<typeof import("../app/components/LoadingOverlay.vue").default>
export const LazyModalDadosCandidato: LazyComponent<typeof import("../app/components/ModalDadosCandidato.vue").default>
export const LazyModalDiario: LazyComponent<typeof import("../app/components/ModalDiario.vue").default>
export const LazyModalFichaAvaliacao: LazyComponent<typeof import("../app/components/ModalFichaAvaliacao.vue").default>
export const LazyModalListaHomologados: LazyComponent<typeof import("../app/components/ModalListaHomologados.vue").default>
export const LazyModalListaSelecionados: LazyComponent<typeof import("../app/components/ModalListaSelecionados.vue").default>
export const LazyModalMeusDocumentos: LazyComponent<typeof import("../app/components/ModalMeusDocumentos.vue").default>
export const LazyModalStatusMatricula: LazyComponent<typeof import("../app/components/ModalStatusMatricula.vue").default>
export const LazyEducacionalCalendarioTurma: LazyComponent<typeof import("../app/components/educacional/CalendarioTurma.vue").default>
export const LazyEducacionalModalAulaExtra: LazyComponent<typeof import("../app/components/educacional/ModalAulaExtra.vue").default>
export const LazyEducacionalModalCurso: LazyComponent<typeof import("../app/components/educacional/ModalCurso.vue").default>
export const LazyEducacionalModalTurma: LazyComponent<typeof import("../app/components/educacional/ModalTurma.vue").default>
export const LazyProducaoModalRelatorioSemanal: LazyComponent<typeof import("../app/components/producao/ModalRelatorioSemanal.vue").default>
export const LazyProducaoModalReservaSala: LazyComponent<typeof import("../app/components/producao/ModalReservaSala.vue").default>
export const LazyProducaoModalSala: LazyComponent<typeof import("../app/components/producao/ModalSala.vue").default>
export const LazyProducaoEstoqueAvariasModal: LazyComponent<typeof import("../app/components/producao/estoque/AvariasModal.vue").default>
export const LazyProducaoEstoqueKitFormModal: LazyComponent<typeof import("../app/components/producao/estoque/KitFormModal.vue").default>
export const LazyProducaoEstoqueProductFormModal: LazyComponent<typeof import("../app/components/producao/estoque/ProductFormModal.vue").default>
export const LazyProducaoEstoqueReservationFormModal: LazyComponent<typeof import("../app/components/producao/estoque/ReservationFormModal.vue").default>
export const LazyNuxtWelcome: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/welcome.vue").default>
export const LazyNuxtLayout: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-layout").default>
export const LazyNuxtErrorBoundary: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-error-boundary.vue").default>
export const LazyClientOnly: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/client-only").default>
export const LazyDevOnly: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/dev-only").default>
export const LazyServerPlaceholder: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/server-placeholder").default>
export const LazyNuxtLink: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-link").default>
export const LazyNuxtLoadingIndicator: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-loading-indicator").default>
export const LazyNuxtTime: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-time.vue").default>
export const LazyNuxtRouteAnnouncer: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-route-announcer").default>
export const LazyNuxtImg: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtImg>
export const LazyNuxtPicture: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtPicture>
export const LazyNuxtPage: LazyComponent<typeof import("../node_modules/nuxt/dist/pages/runtime/page").default>
export const LazyNoScript: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").NoScript>
export const LazyLink: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Link>
export const LazyBase: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Base>
export const LazyTitle: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Title>
export const LazyMeta: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Meta>
export const LazyStyle: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Style>
export const LazyHead: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Head>
export const LazyHtml: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Html>
export const LazyBody: LazyComponent<typeof import("../node_modules/nuxt/dist/head/runtime/components").Body>
export const LazyNuxtIsland: LazyComponent<typeof import("../node_modules/nuxt/dist/app/components/nuxt-island").default>

export const componentNames: string[]
