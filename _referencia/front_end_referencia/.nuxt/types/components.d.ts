
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

interface _GlobalComponents {
  'BaseSelect': typeof import("../../app/components/BaseSelect.vue").default
  'CandidateCard': typeof import("../../app/components/CandidateCard.vue").default
  'CandidateDashboard': typeof import("../../app/components/CandidateDashboard.vue").default
  'ConfirmationModal': typeof import("../../app/components/ConfirmationModal.vue").default
  'FullPageMenu': typeof import("../../app/components/FullPageMenu.vue").default
  'LoadingOverlay': typeof import("../../app/components/LoadingOverlay.vue").default
  'ModalDadosCandidato': typeof import("../../app/components/ModalDadosCandidato.vue").default
  'ModalDiario': typeof import("../../app/components/ModalDiario.vue").default
  'ModalFichaAvaliacao': typeof import("../../app/components/ModalFichaAvaliacao.vue").default
  'ModalListaHomologados': typeof import("../../app/components/ModalListaHomologados.vue").default
  'ModalListaSelecionados': typeof import("../../app/components/ModalListaSelecionados.vue").default
  'ModalMeusDocumentos': typeof import("../../app/components/ModalMeusDocumentos.vue").default
  'ModalStatusMatricula': typeof import("../../app/components/ModalStatusMatricula.vue").default
  'EducacionalCalendarioTurma': typeof import("../../app/components/educacional/CalendarioTurma.vue").default
  'EducacionalModalAulaExtra': typeof import("../../app/components/educacional/ModalAulaExtra.vue").default
  'EducacionalModalCurso': typeof import("../../app/components/educacional/ModalCurso.vue").default
  'EducacionalModalTurma': typeof import("../../app/components/educacional/ModalTurma.vue").default
  'ProducaoModalRelatorioSemanal': typeof import("../../app/components/producao/ModalRelatorioSemanal.vue").default
  'ProducaoModalReservaSala': typeof import("../../app/components/producao/ModalReservaSala.vue").default
  'ProducaoModalSala': typeof import("../../app/components/producao/ModalSala.vue").default
  'ProducaoEstoqueAvariasModal': typeof import("../../app/components/producao/estoque/AvariasModal.vue").default
  'ProducaoEstoqueKitFormModal': typeof import("../../app/components/producao/estoque/KitFormModal.vue").default
  'ProducaoEstoqueProductFormModal': typeof import("../../app/components/producao/estoque/ProductFormModal.vue").default
  'ProducaoEstoqueReservationFormModal': typeof import("../../app/components/producao/estoque/ReservationFormModal.vue").default
  'NuxtWelcome': typeof import("../../node_modules/nuxt/dist/app/components/welcome.vue").default
  'NuxtLayout': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-layout").default
  'NuxtErrorBoundary': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-error-boundary.vue").default
  'ClientOnly': typeof import("../../node_modules/nuxt/dist/app/components/client-only").default
  'DevOnly': typeof import("../../node_modules/nuxt/dist/app/components/dev-only").default
  'ServerPlaceholder': typeof import("../../node_modules/nuxt/dist/app/components/server-placeholder").default
  'NuxtLink': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-link").default
  'NuxtLoadingIndicator': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-loading-indicator").default
  'NuxtTime': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-time.vue").default
  'NuxtRouteAnnouncer': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-route-announcer").default
  'NuxtImg': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtImg
  'NuxtPicture': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtPicture
  'NuxtPage': typeof import("../../node_modules/nuxt/dist/pages/runtime/page").default
  'NoScript': typeof import("../../node_modules/nuxt/dist/head/runtime/components").NoScript
  'Link': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Link
  'Base': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Base
  'Title': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Title
  'Meta': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Meta
  'Style': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Style
  'Head': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Head
  'Html': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Html
  'Body': typeof import("../../node_modules/nuxt/dist/head/runtime/components").Body
  'NuxtIsland': typeof import("../../node_modules/nuxt/dist/app/components/nuxt-island").default
  'LazyBaseSelect': LazyComponent<typeof import("../../app/components/BaseSelect.vue").default>
  'LazyCandidateCard': LazyComponent<typeof import("../../app/components/CandidateCard.vue").default>
  'LazyCandidateDashboard': LazyComponent<typeof import("../../app/components/CandidateDashboard.vue").default>
  'LazyConfirmationModal': LazyComponent<typeof import("../../app/components/ConfirmationModal.vue").default>
  'LazyFullPageMenu': LazyComponent<typeof import("../../app/components/FullPageMenu.vue").default>
  'LazyLoadingOverlay': LazyComponent<typeof import("../../app/components/LoadingOverlay.vue").default>
  'LazyModalDadosCandidato': LazyComponent<typeof import("../../app/components/ModalDadosCandidato.vue").default>
  'LazyModalDiario': LazyComponent<typeof import("../../app/components/ModalDiario.vue").default>
  'LazyModalFichaAvaliacao': LazyComponent<typeof import("../../app/components/ModalFichaAvaliacao.vue").default>
  'LazyModalListaHomologados': LazyComponent<typeof import("../../app/components/ModalListaHomologados.vue").default>
  'LazyModalListaSelecionados': LazyComponent<typeof import("../../app/components/ModalListaSelecionados.vue").default>
  'LazyModalMeusDocumentos': LazyComponent<typeof import("../../app/components/ModalMeusDocumentos.vue").default>
  'LazyModalStatusMatricula': LazyComponent<typeof import("../../app/components/ModalStatusMatricula.vue").default>
  'LazyEducacionalCalendarioTurma': LazyComponent<typeof import("../../app/components/educacional/CalendarioTurma.vue").default>
  'LazyEducacionalModalAulaExtra': LazyComponent<typeof import("../../app/components/educacional/ModalAulaExtra.vue").default>
  'LazyEducacionalModalCurso': LazyComponent<typeof import("../../app/components/educacional/ModalCurso.vue").default>
  'LazyEducacionalModalTurma': LazyComponent<typeof import("../../app/components/educacional/ModalTurma.vue").default>
  'LazyProducaoModalRelatorioSemanal': LazyComponent<typeof import("../../app/components/producao/ModalRelatorioSemanal.vue").default>
  'LazyProducaoModalReservaSala': LazyComponent<typeof import("../../app/components/producao/ModalReservaSala.vue").default>
  'LazyProducaoModalSala': LazyComponent<typeof import("../../app/components/producao/ModalSala.vue").default>
  'LazyProducaoEstoqueAvariasModal': LazyComponent<typeof import("../../app/components/producao/estoque/AvariasModal.vue").default>
  'LazyProducaoEstoqueKitFormModal': LazyComponent<typeof import("../../app/components/producao/estoque/KitFormModal.vue").default>
  'LazyProducaoEstoqueProductFormModal': LazyComponent<typeof import("../../app/components/producao/estoque/ProductFormModal.vue").default>
  'LazyProducaoEstoqueReservationFormModal': LazyComponent<typeof import("../../app/components/producao/estoque/ReservationFormModal.vue").default>
  'LazyNuxtWelcome': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/welcome.vue").default>
  'LazyNuxtLayout': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-layout").default>
  'LazyNuxtErrorBoundary': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-error-boundary.vue").default>
  'LazyClientOnly': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/client-only").default>
  'LazyDevOnly': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/dev-only").default>
  'LazyServerPlaceholder': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/server-placeholder").default>
  'LazyNuxtLink': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-link").default>
  'LazyNuxtLoadingIndicator': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-loading-indicator").default>
  'LazyNuxtTime': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-time.vue").default>
  'LazyNuxtRouteAnnouncer': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-route-announcer").default>
  'LazyNuxtImg': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtImg>
  'LazyNuxtPicture': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-stubs").NuxtPicture>
  'LazyNuxtPage': LazyComponent<typeof import("../../node_modules/nuxt/dist/pages/runtime/page").default>
  'LazyNoScript': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").NoScript>
  'LazyLink': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Link>
  'LazyBase': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Base>
  'LazyTitle': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Title>
  'LazyMeta': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Meta>
  'LazyStyle': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Style>
  'LazyHead': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Head>
  'LazyHtml': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Html>
  'LazyBody': LazyComponent<typeof import("../../node_modules/nuxt/dist/head/runtime/components").Body>
  'LazyNuxtIsland': LazyComponent<typeof import("../../node_modules/nuxt/dist/app/components/nuxt-island").default>
}

declare module 'vue' {
  export interface GlobalComponents extends _GlobalComponents { }
}

export {}
