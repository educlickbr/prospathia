<script setup lang="ts">
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import timeGridPlugin from '@fullcalendar/timegrid'
import interactionPlugin from '@fullcalendar/interaction'
import ptBrLocale from '@fullcalendar/core/locales/pt-br'
import ModalAulaExtra from './ModalAulaExtra.vue'
import ConfirmationModal from '../ConfirmationModal.vue'
import { useToast } from '../../../composables/useToast'

const props = defineProps<{
    events: any[],
    turmaId: string | null
}>()

const emit = defineEmits(['refresh'])
const { showToast } = useToast()

const showExtraModal = ref(false)
const selectedDate = ref<string | null>(null)

// Delete Confirm State
const showDeleteModal = ref(false)
const eventToDelete = ref<any>(null)
const isDeleting = ref(false)

const handleDateClick = (arg: any) => {
    if (!props.turmaId) return
    selectedDate.value = arg.dateStr
    showExtraModal.value = true
}

const handleEventClick = (info: any) => {
    if (!props.turmaId) return
    eventToDelete.value = info.event
    showDeleteModal.value = true
}

const confirmDelete = async () => {
    if (!eventToDelete.value) return
    
    isDeleting.value = true
    try {
        const response: any = await $fetch('/api/educacional/calendario/evento', {
            method: 'DELETE' as any,
            body: { id: eventToDelete.value.id }
        })
        
        if (response && response.success) {
            showToast('Evento removido', { type: 'success' })
            emit('refresh')
            showDeleteModal.value = false
        } else {
            showToast('Erro ao remover', { type: 'error' })
        }
    } catch (e) {
        console.error(e)
        showToast('Erro ao remover evento', { type: 'error' })
    } finally {
        isDeleting.value = false
        eventToDelete.value = null
    }
}

const calendarOptions = computed(() => ({
    plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
    initialView: 'dayGridMonth',
    headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek'
    },
    locale: ptBrLocale,
    events: props.events,
    editable: false,
    selectable: true,
    dayMaxEvents: true,
    timeZone: 'local',
    dateClick: handleDateClick,
    eventClick: handleEventClick,
    height: 'auto',
    themeSystem: 'standard'
}))

</script>

<template>
    <div class="calendar-wrapper w-full relative">
        <FullCalendar :options="calendarOptions" />
        
        <ModalAulaExtra 
            :isOpen="showExtraModal"
            :turmaId="turmaId || ''"
            :date="selectedDate"
            @close="showExtraModal = false"
            @save="emit('refresh')"
        />

        <ConfirmationModal
            :isOpen="showDeleteModal"
            title="Remover Evento"
            :message="eventToDelete ? `Deseja realmente remover o evento '${eventToDelete.title}'?` : 'Deseja remover este evento?'"
            confirmText="Remover"
            type="danger"
            :loading="isDeleting"
            @close="showDeleteModal = false"
            @confirm="confirmDelete"
        />
    </div>
</template>

<style>
/* Custom FullCalendar Dark Theme Overrides */
:root {
    --fc-border-color: rgba(255, 255, 255, 0.1);
    --fc-page-bg-color: transparent;
    --fc-neutral-bg-color: rgba(255, 255, 255, 0.05);
    --fc-list-event-hover-bg-color: rgba(255, 255, 255, 0.1);
    --fc-today-bg-color: rgba(255, 255, 255, 0.05) !important;
}

.calendar-wrapper {
    @apply text-white;
}

.fc-toolbar-title {
    @apply text-lg font-bold !important;
}

.fc-button {
    @apply bg-[#0f0f15] border-white/10 text-sm font-medium hover:bg-white/10 hover:border-white/20 !important;
    @apply transition-colors !important;
}

.fc-button-active {
    @apply bg-primary border-primary hover:bg-primary-dark hover:border-primary-dark !important;
    @apply text-white !important;
}

.fc-col-header-cell-cushion {
    @apply text-secondary uppercase text-xs font-bold tracking-wider py-2 !important;
    @apply no-underline !important; 
}

.fc-daygrid-day-number {
    @apply text-sm text-secondary hover:text-white !important;
    @apply no-underline !important;
}

.fc-event {
    @apply cursor-pointer shadow-sm !important;
}

.fc-timegrid-slot-label-cushion {
    @apply text-secondary text-xs !important;
}

</style>
