<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue';

const props = defineProps<{
    modelValue: any;
    options: any[]; // Array of strings or objects { id: '...', nome: '...' }
    placeholder?: string;
    labelKey?: string; // Key to display in dropdown (default: 'nome')
    valueKey?: string; // Key for value (default: 'id')
    selectedLabelKey?: string; // Key to display in selected state (optional, defaults to labelKey)
    disabled?: boolean;
}>();

const emit = defineEmits(['update:modelValue']);

const isOpen = ref(false);
const containerRef = ref<HTMLElement | null>(null);

const getLabel = (option: any) => {
    if (typeof option === 'string') return option;
    return option[props.labelKey || 'nome'];
};

const getSelectedLabelRaw = (option: any) => {
    if (typeof option === 'string') return option;
    return option[props.selectedLabelKey || props.labelKey || 'nome'];
};

const getValue = (option: any) => {
    if (typeof option === 'string') return option;
    return option[props.valueKey || 'id'];
};

const selectedLabel = computed(() => {
    if (!props.modelValue) return props.placeholder || 'Selecione...';
    const selected = props.options.find(o => getValue(o) === props.modelValue);
    return selected ? getSelectedLabelRaw(selected) : (props.placeholder || 'Selecione...');
});

const toggle = () => {
    if (props.disabled) return;
    isOpen.value = !isOpen.value;
};

const select = (option: any) => {
    emit('update:modelValue', getValue(option));
    isOpen.value = false;
};

const close = (e: MouseEvent) => {
    if (containerRef.value && !containerRef.value.contains(e.target as Node)) {
        isOpen.value = false;
    }
};

onMounted(() => {
    document.addEventListener('click', close);
});

onUnmounted(() => {
    document.removeEventListener('click', close);
});
</script>

<template>
    <div class="relative w-full" ref="containerRef">
        <!-- Trigger -->
        <button 
            type="button"
            @click="toggle"
            :disabled="disabled"
            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-left flex items-center justify-between transition-colors focus:outline-none focus:border-primary"
            :class="[
                isOpen ? 'border-primary ring-1 ring-primary' : '',
                disabled ? 'opacity-50 cursor-not-allowed' : 'hover:border-white/20'
            ]"
        >
            <span :class="!modelValue ? 'text-secondary/30' : 'text-white'">
                {{ selectedLabel }}
            </span>
            <svg 
                class="w-4 h-4 text-secondary transition-transform duration-200"
                :class="isOpen ? 'rotate-180' : ''"
                xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"
            >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
        </button>

        <!-- Dropdown -->
        <transition
            enter-active-class="transition duration-100 ease-out"
            enter-from-class="transform scale-95 opacity-0"
            enter-to-class="transform scale-100 opacity-100"
            leave-active-class="transition duration-75 ease-in"
            leave-from-class="transform scale-100 opacity-100"
            leave-to-class="transform scale-95 opacity-0"
        >
            <div 
                v-if="isOpen" 
                class="absolute z-50 w-full mt-1 bg-[#1A1A24] border border-white/10 rounded-lg shadow-xl max-h-60 overflow-y-auto custom-scrollbar"
            >
                <ul class="py-1">
                    <li v-if="options.length === 0" class="px-4 py-2 text-sm text-secondary italic text-center">
                        Nenhuma opção
                    </li>
                    <li 
                        v-for="option in options" 
                        :key="getValue(option)"
                        @click="select(option)"
                        class="px-4 py-2.5 text-sm cursor-pointer transition-colors flex items-center justify-between group"
                        :class="[
                            modelValue === getValue(option) 
                                ? 'bg-primary/20 text-primary font-bold' 
                                : 'text-white hover:bg-primary hover:text-white'
                        ]"
                    >
                        <span>{{ getLabel(option) }}</span>
                        <svg v-if="modelValue === getValue(option)" class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                    </li>
                </ul>
            </div>
        </transition>
    </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: #16161E; 
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: #333; 
    border-radius: 3px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: #444; 
}
</style>
