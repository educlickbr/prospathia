<script setup lang="ts">
import { useToast } from '../../../composables/useToast';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';

const props = defineProps<{
    isOpen: boolean;
}>();

const emit = defineEmits(['close']);
const { showToast } = useToast();

const isLoading = ref(false);
const activeTab = ref<'config' | 'preview'>('config');
const dataRef = ref(new Date().toISOString().split('T')[0]); // Default to today
const turno = ref('Todos');
const turnos = ['Todos', 'Matutino', 'Vespertino', 'Noturno'];

// Global Config State for Print Header
const config = ref({
    tituloPrincipal: 'Relatório de Retiradas',
    tituloSecundario: 'São Paulo Escola de Dança',
    logoUrl: 'https://spedppull.b-cdn.net/site/sped_logo_total%20(1).png',
    textoRodape: 'Declaro ter recebido os equipamentos acima listados em perfeito estado de conservação e funcionamento.',
});

// Data State
const reportItems = ref<any[]>([]);

// Computed Properties for Display
const formattedPeriod = computed(() => {
    if (!dataRef.value) return '-';
    // Format: "23/01/2026 (Todos)"
    const dateStr = format(parseISO(dataRef.value), 'dd/MM/yyyy', { locale: ptBR });
    return `${dateStr} - ${turno.value}`;
});

// Fetch Data
const fetchData = async () => {
    if (!props.isOpen) return;

    isLoading.value = true;
    try {
        const data = await $fetch('/api/producao/relatorios/retiradas-semana', {
            params: {
              data: dataRef.value,
              turno: turno.value
            }
        });
        
        reportItems.value = (data as any[]) || [];

    } catch (e) {
        console.error('Error fetching report:', e);
        showToast('Erro ao buscar reservas.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

watch(() => props.isOpen, (val) => {
    if (val) {
        fetchData();
        activeTab.value = 'config';
    }
});

// --- Print Logic (Based on ModalListaHomologados) ---

const printReport = () => {
    const htmlContent = generateFullHTML(reportItems.value);
    
    // Create iframe
    const iframe = document.createElement('iframe');
    Object.assign(iframe.style, {
        position: 'fixed',
        right: '0',
        bottom: '0',
        width: '0',
        height: '0',
        border: '0'
    });
    document.body.appendChild(iframe);

    const doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
    if (!doc) return;

    doc.open();
    doc.write(htmlContent);
    doc.close();

    const waitForImages = () => {
        const images = doc.images;
        if (!images.length) {
            printNow(iframe);
            return;
        }

        let loadedCount = 0;
        const checkComplete = () => {
            loadedCount++;
            if (loadedCount === images.length) {
                printNow(iframe);
            }
        };

        for (let i = 0; i < images.length; i++) {
            const img = images[i];
            if (!img) continue; 
            
            if (img.complete) {
                checkComplete();
            } else {
                img.addEventListener('load', checkComplete);
                img.addEventListener('error', checkComplete);
            }
        }
    };

    iframe.onload = () => waitForImages();
    setTimeout(() => waitForImages(), 500); 
};

const printNow = (iframe: HTMLIFrameElement) => {
    if ((iframe as any)._hasPrinted) return;
    (iframe as any)._hasPrinted = true;

    if (!iframe.contentWindow) return;
    
    setTimeout(() => {
        iframe.contentWindow?.focus();
        iframe.contentWindow?.print();
        setTimeout(() => {
             if (document.body.contains(iframe)) {
                 document.body.removeChild(iframe);
             }
        }, 1000);
    }, 300);
};

// --- Generator Functions ---

const generateStyles = () => `
       * { box-sizing: border-box; font-family: 'Poppins', sans-serif; color: #222; font-size: 12px; }
       .pagina { padding: 5mm; width: 100%; margin: 0; }
       .logo-cabecalho { width: 100px; margin-bottom: 15px; }
       .header { text-align: center; margin-bottom: 20px; }
       .title { font-size: 16px; font-weight: 700; margin-bottom: 5px; }
       .subtitle { font-size: 14px; margin-bottom: 5px; }
       .period { font-size: 12px; font-weight: 600; color: #666; }
       
       table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
       th { background: #f3f4f6; padding: 8px; text-align: left; font-weight: 700; border-bottom: 2px solid #ddd; font-size: 11px; text-transform: uppercase; }
       td { padding: 8px; border-bottom: 1px solid #eee; vertical-align: top; }
       tr:last-child td { border-bottom: none; }
       
       .footer { margin-top: 40px; }
       .signature-block { display: flex; justify-content: space-between; gap: 40px; margin-top: 50px; }
       .signature-line { flex: 1; border-top: 1px solid #999; padding-top: 5px; text-align: center; }
       .disclaimer { margin-top: 20px; font-size: 10px; color: #666; text-align: center; font-style: italic; }

       @page { size: A4; margin: 10mm; }
`;

const generateBody = (items: any[]) => {
    // Helper format
    const fmt = (v: any) => v ? format(parseISO(v), 'dd/MM/yyyy HH:mm', { locale: ptBR }) : '-';

    // Pagination Config
    const ITEMS_P1 = 12; // Conservative to ensure spacing
    const ITEMS_PN = 18; 

    // Chunk items
    const pages = [];
    let remaining = [...items];

    // First Page
    pages.push(remaining.splice(0, ITEMS_P1));

    // Subsequent Pages
    while (remaining.length > 0) {
        pages.push(remaining.splice(0, ITEMS_PN));
    }

    // Generate HTML for each page
    return pages.map((pageItems, pageIdx) => {
        const isLastPage = pageIdx === pages.length - 1;
        const rows = pageItems.map((item, idx) => {
            // Calculate absolute index
            const absIdx = (pageIdx === 0 ? 0 : ITEMS_P1 + (pageIdx - 1) * ITEMS_PN) + idx + 1;
            
            return `
            <tr>
                <td>${absIdx}</td>
                <td><strong>${item.nome_usuario}</strong></td>
                <td>${item.nome_produto}</td>
                <td style="text-align: center">${item.quantidade}</td>
                <td>${fmt(item.data_retirada)}</td>
                <td>${fmt(item.data_devolucao_prevista)}</td>
                <td>${item.data_devolvido ? fmt(item.data_devolvido) : ''}</td>
                <td style="border: 1px solid #eee; width: 100px;"></td>
            </tr>
            `;
        }).join("");

        // Page Content
        return `
        <div class="pagina" style="${!isLastPage ? 'page-break-after: always;' : ''}">
            
            ${pageIdx === 0 ? `
            <div class="header">
                <img src="${config.value.logoUrl}" class="logo-cabecalho" />
                <div class="title">${config.value.tituloPrincipal}</div>
                <div class="subtitle">${config.value.tituloSecundario}</div>
                <div class="period">Dia/Turno: ${formattedPeriod.value}</div>
            </div>
            ` : `
            <div class="header" style="margin-bottom: 20px;">
                <div class="period" style="text-align: right; font-size: 10px;">Continuação - Pág. ${pageIdx + 1}</div>
            </div>
            `}

            <table>
                <thead>
                    <tr>
                        <th width="30">#</th>
                        <th>Responsável</th>
                        <th>Produto</th>
                        <th width="40" style="text-align: center">Qtd</th>
                        <th>Retirada</th>
                        <th>Prev. Devolução</th>
                        <th>Devolvido em</th>
                        <th>Visto Receb.</th>
                    </tr>
                </thead>
                <tbody>
                    ${rows}
                </tbody>
            </table>

            ${isLastPage ? `
            <div class="footer">
                <div class="disclaimer">${config.value.textoRodape}</div>
                <div class="signature-block">
                    <div class="signature-line">
                        Responsável pelo Setor
                    </div>
                    <div class="signature-line">
                         Visto da Direção (Opcional)
                    </div>
                </div>
            </div>
            ` : ''}

        </div>
        `;
    }).join("");
};

const generateFullHTML = (items: any[]) => {
    return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Relatório de Retiradas</title>
        <style>${generateStyles()}</style>
      </head>
      <body>${generateBody(items)}</body>
    </html>
    `;
};

</script>

<template>
  <div v-if="isOpen" class="relative z-50">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

    <!-- Modal -->
    <div class="fixed inset-0 z-10 overflow-y-auto">
      <div class="flex min-h-full items-center justify-center p-0 md:p-4 text-center">
        <div class="relative w-full max-w-4xl transform rounded-none md:rounded-xl bg-[#16161E] border border-white/10 text-left shadow-xl transition-all flex flex-col max-h-[90vh]">
            
            <div class="flex items-center justify-between p-6 border-b border-white/10">
                <h3 class="text-xl font-bold text-white">
                    {{ config.tituloPrincipal }}
                    <span class="block text-sm text-secondary font-normal mt-1">{{ formattedPeriod }}</span>
                </h3>
                <button @click="$emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <!-- Tabs -->
            <div class="flex border-b border-white/10 px-6">
                <button 
                    @click="activeTab = 'config'"
                    class="px-4 py-3 text-sm font-bold border-b-2 transition-colors"
                    :class="activeTab === 'config' ? 'border-primary text-primary' : 'border-transparent text-secondary hover:text-white'"
                >
                    Configuração
                </button>
                <button 
                    @click="activeTab = 'preview'"
                    class="px-4 py-3 text-sm font-bold border-b-2 transition-colors"
                    :class="activeTab === 'preview' ? 'border-primary text-primary' : 'border-transparent text-secondary hover:text-white'"
                >
                    Visualizar Relatório
                </button>
            </div>

            <div class="flex-1 overflow-y-auto p-6 custom-scrollbar">
                
                <div v-if="isLoading" class="flex justify-center py-10">
                    <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
                </div>

                <!-- CONFIG TAB -->
                <div v-else-if="activeTab === 'config'" class="space-y-6">
                     <!-- Date Selection -->
                     <div class="bg-white/5 rounded-lg p-5 border border-white/10">
                        <label class="block text-xs font-bold text-secondary mb-2 uppercase tracking-wider">Período de Referência</label>
                        <div class="flex flex-col md:flex-row gap-4 items-end">
                            <div class="w-full md:w-auto">
                                <span class="text-xs text-secondary/70 mb-1 block">Data:</span>
                                <input 
                                    v-model="dataRef" 
                                    type="date" 
                                    class="bg-[#0f0f15] border border-white/10 rounded px-4 py-2 text-white focus:border-primary focus:outline-none w-full"
                                />
                            </div>
                            
                            <div class="w-full md:w-auto">
                                <span class="text-xs text-secondary/70 mb-1 block">Turno:</span>
                                <select 
                                    v-model="turno" 
                                    class="bg-[#0f0f15] border border-white/10 rounded px-4 py-2 text-white focus:border-primary focus:outline-none w-full min-w-[150px]"
                                >
                                    <option v-for="t in turnos" :key="t" :value="t">{{ t }}</option>
                                </select>
                            </div>

                            <button 
                                @click="fetchData" 
                                class="bg-primary hover:bg-primary-600 text-white font-bold py-2 px-6 rounded transition-colors text-sm w-full md:w-auto"
                            >
                                Atualizar
                            </button>
                        </div>
                     </div>

                     <!-- Header Config -->
                     <div class="bg-white/5 rounded-lg p-5 border border-white/10">
                        <h4 class="text-sm font-bold text-white mb-4 uppercase tracking-wider">Personalizar Impressão</h4>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label class="block text-xs font-bold text-secondary mb-1">Título Principal</label>
                                <input v-model="config.tituloPrincipal" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-secondary mb-1">Subtítulo (Instituição)</label>
                                <input v-model="config.tituloSecundario" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                             <div class="md:col-span-2">
                                <label class="block text-xs font-bold text-secondary mb-1">Texto de Rodapé (Termo)</label>
                                <input v-model="config.textoRodape" class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                        </div>
                     </div>
                </div>

                <!-- PREVIEW TAB -->
                <div v-else-if="activeTab === 'preview'" class="space-y-4">
                     <template v-if="reportItems.length > 0">
                        <div class="text-right text-xs text-secondary mb-2">
                            Total de {{ reportItems.length }} registros encontrados.
                        </div>
                        <div class="border border-white/10 rounded-lg overflow-hidden">
                            <table class="w-full text-left text-sm text-white">
                                <thead class="bg-white/5 text-xs uppercase text-secondary font-bold">
                                    <tr>
                                        <th class="px-4 py-3">Responsável</th>
                                        <th class="px-4 py-3">Produto</th>
                                        <th class="px-4 py-3 text-center">Qtd</th>
                                        <th class="px-4 py-3">Retirada</th>
                                        <th class="px-4 py-3">Devolução Prev.</th>
                                        <th class="px-4 py-3">Status</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-white/5">
                                    <tr v-for="(item, idx) in reportItems" :key="idx" class="hover:bg-white/5 transition-colors">
                                        <td class="px-4 py-3 font-medium">{{ item.nome_usuario }}</td>
                                        <td class="px-4 py-3 text-secondary-300">{{ item.nome_produto }}</td>
                                        <td class="px-4 py-3 text-center">{{ item.quantidade }}</td>
                                        <td class="px-4 py-3 text-secondary-400 text-xs">
                                            {{ item.data_retirada ? format(parseISO(item.data_retirada), 'dd/MM HH:mm') : '-' }}
                                        </td>
                                        <td class="px-4 py-3 text-secondary-400 text-xs">
                                            {{ item.data_devolucao_prevista ? format(parseISO(item.data_devolucao_prevista), 'dd/MM HH:mm') : '-' }}
                                        </td>
                                        <td class="px-4 py-3 text-xs">
                                            <span class="px-2 py-0.5 rounded bg-white/10">{{ item.status }}</span>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                     </template>
                     <div v-else class="flex flex-col items-center justify-center py-20 opacity-50">
                          <p>Nenhuma retirada encontrada nesta semana.</p>
                     </div>
                </div>

            </div>

             <!-- Footer -->
            <div class="p-4 border-t border-white/10 flex justify-end gap-3 bg-[#16161E]">
                <button 
                    @click="$emit('close')"
                    class="px-6 py-2.5 bg-white/5 hover:bg-white/10 text-secondary hover:text-white font-bold rounded-lg transition-colors"
                >
                    Fechar
                </button>

                <button 
                    v-if="activeTab === 'preview' && reportItems.length > 0"
                    @click="printReport"
                    class="px-6 py-2.5 bg-primary hover:bg-primary-600 text-white font-bold rounded-lg transition-colors flex items-center gap-2"
                >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                    Imprimir Relatório
                </button>
            </div>

        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(255, 255, 255, 0.05); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }
</style>
