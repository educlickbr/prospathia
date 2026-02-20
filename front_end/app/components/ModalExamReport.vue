<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue';

const props = defineProps<{
    isOpen: boolean;
    exam: any; // Using any for flexibility with the jsonb return, but interfaces are better
}>();

const emit = defineEmits(['close']);

// Hover zoom state
const hoveredItem = ref<any>(null);

// Ref to the white document container to calculate its center
const documentRef = ref<HTMLElement | null>(null);

const hoverCardLeft = computed(() => {
    if (!documentRef.value) return '50vw';
    const rect = documentRef.value.getBoundingClientRect();
    return `${rect.left + rect.width / 2}px`;
});

// Mock clinic data for now (or pass as props in future)
const clinicName = "Clínica Otolithics";
const clinicLogo = "https://otolithics-p.b-cdn.net/logo_otolithics.png"; // Placeholder or from user's ref if valid

// Dynamic Dimensions State
const containerStyle = ref({});

const updateDimensions = () => {
    if (typeof window === 'undefined') return;
    
    // User's formula: height * 0.95, width = height * 0.70707
    const h = window.innerHeight * 0.9; // Adjusted to 0.9 for more top/bottom clearance
    const w = h * 0.70707; // A4 Aspect Ratio (1 / √2)

    containerStyle.value = {
        height: `${h}px`,
        width: `${w}px`,
        // Dynamic font size adjustment to ensure content scales with the container
        // Base A4 height is ~1123px. If screen is smaller, scale font down.
        fontSize: `${(h / 1123) * 16}px` 
    };
};

onMounted(() => {
    updateDimensions();
    window.addEventListener('resize', updateDimensions);
});

onUnmounted(() => {
    window.removeEventListener('resize', updateDimensions);
});

// Helper to format degrees
const graus = (valor: number | null | undefined) => valor !== null && valor !== undefined ? `${valor}°` : '-';

// Helper to find condition data by name (or id_condicao if we had mapping, using name as provided in example)
const getCondition = (name: string) => {
    if (!props.exam || !props.exam.condicoes) return null;
    return props.exam.condicoes.find((c: any) => c.nome_condicao === name);
};

// Computed data structure for the report
const reportData = computed(() => {
    if (!props.exam) return {};

    const conditions = [
        { key: 'estatica_direita', label: 'Estática Direita', type: 'direita' },
        { key: 'neutra', label: 'Neutra', type: 'normal', central: true },
        { key: 'estatica_esquerda', label: 'Estática Esquerda', type: 'esquerda' },
        
        { key: 'dinamica_antihorario', label: 'Dinâmica Sentido Anti-Horário', type: 'normal' },
        { key: 'dinamica_horario', label: 'Dinâmica Sentido Horário', type: 'normal' },
        
        { key: 'haptica_direita', label: 'Háptica Direita', type: 'direita' },
        { key: 'haptica_esquerda', label: 'Háptica Esquerda', type: 'esquerda' }
    ];

    const mapped = conditions.map(conf => {
        const data = getCondition(conf.key);
        return {
            ...conf,
            m1: graus(data?.m1),
            m2: graus(data?.m2),
            m3: graus(data?.m3),
            m4: graus(data?.m4),
            md: graus(data?.md),
            mnd: graus(data?.mnd),
            lin1: data?.md ?? 0, // Rotation 1
            lin2: data?.mnd ?? 0 // Rotation 2
        };
    });

    return {
        header: {
            clinicName: clinicName,
            doctorName: props.exam.profissional_nome || '',
            patientName: props.exam.paciente_nome || '',
            logo: clinicLogo
        },
        rows: [
            [mapped[0], mapped[1], mapped[2]].filter(Boolean),
            [mapped[3], mapped[4]].filter(Boolean),
            [mapped[5], mapped[6]].filter(Boolean)
        ],
        laudo: props.exam.laudo || ''
    };
});

// Function to generate isolated HTML for printing
const generatePrintHtml = (data: any) => {
    
    // Helper to generate a single condition block
    const getConditionHtml = (item: any) => {
        if (!item) return '';
        
        // Map the type to the specific URL since we can't rely on external stylesheet classes
        let bgUrl = '';
        if (item.type === 'normal') bgUrl = 'https://otolithics-p.b-cdn.net/transferidor_cabeca_normal.png';
        if (item.type === 'direita') bgUrl = 'https://otolithics-p.b-cdn.net/transferidor_cabeca_direita.png';
        if (item.type === 'esquerda') bgUrl = 'https://otolithics-p.b-cdn.net/transferidor_cabeca_esquerda.png';

        return `
            <div class="sub-item w-full flex flex-col items-center relative mb-[1.5em]">
                <div class="titulo-condicao text-[0.8em] font-semibold mb-[0.25em] text-[#333]">${item.label}</div>
                
                <div 
                    class="aspect-box w-full bg-contain bg-no-repeat bg-center relative"
                    style="aspect-ratio: 16/9; background-image: url('${bgUrl}');"
                >
                    <div class="linha-angulo absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#FF7900]" style="transform: translateX(-50%) rotate(${item.lin1}deg)"></div>
                    <div class="linha-angulo-azul absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#707070]" style="transform: translateX(-50%) rotate(${item.lin2}deg)"></div>
                </div>

                <div class="medidas-box mt-[0.125em] rounded px-[0.4em] py-[0.125em] text-[0.65em] flex flex-col items-center gap-px">
                    <div class="linha-superior flex gap-[0.5em] justify-center">
                        <div class="medida whitespace-nowrap">M1: ${item.m1}</div>
                        <div class="medida whitespace-nowrap">M2: ${item.m2}</div>
                        <div class="medida whitespace-nowrap">M3: ${item.m3}</div>
                        <div class="medida whitespace-nowrap">M4: ${item.m4}</div>
                    </div>
                    <div class="linha-inferior flex gap-[1em] justify-center">
                        <div class="medida md text-[#FF7900] font-bold whitespace-nowrap">MD: ${item.md}</div>
                        <div class="medida mnd text-[#707070] font-bold whitespace-nowrap">MND: ${item.mnd}</div>
                    </div>
                </div>
            </div>
        `;
    };

    // Extract items by logical column based on the hardcoded structure
    // rows[0] = [Estática Direita, Neutra, Estática Esquerda]
    // rows[1] = [Dinâmica Anti-Horário, Dinâmica Horário]
    // rows[2] = [Háptica Direita, Háptica Esquerda]
    const leftColItems = [data.rows[0]?.[0], data.rows[1]?.[0], data.rows[2]?.[0]].filter(Boolean);
    const centerColItems = [data.rows[0]?.[1]].filter(Boolean); // Only Neutra
    const rightColItems = [data.rows[0]?.[2], data.rows[1]?.[1], data.rows[2]?.[1]].filter(Boolean);

    const logoHtml = data.header?.logo 
        ? `<img src="${data.header.logo}" class="max-h-[3.75em] object-contain">`
        : `<div class="w-[3.75em] h-[3.75em] flex items-center justify-center bg-gray-100 text-[0.5em] text-gray-400">Logo</div>`;

    return `
        <div id="print-container" class="flex flex-col font-poppins !bg-white !text-black p-[24px] box-border">
            <!-- Header (Strict Height) -->
            <div class="area-header flex-none h-[10%] min-h-[5em] px-[2em] py-[1em] flex items-center border-b border-[#ccc] mb-[2em]">
                <div class="header-content flex items-center gap-[2em] w-full">
                    ${logoHtml}
                    <div class="header-text flex flex-col justify-center">
                        <div class="text-[0.9em] font-bold pb-[0.2em]">${data.header?.clinicName || ''}</div>
                        <div class="text-[0.7em] text-[#333]"><span class="font-semibold text-gray-500">Paciente:</span> ${data.header?.patientName || ''}</div>
                        <div class="text-[0.55em] text-[#666]"><span class="font-medium text-gray-400">Profissional Responsável:</span> ${data.header?.doctorName || ''}</div>
                    </div>
                </div>
            </div>

            <!-- Charts Area (Flex-1 to take available space between Header and Footer) -->
            <div class="area-body flex-1 grid grid-cols-3 gap-[1.5em] px-[1em] relative">
                <!-- Coluna Esquerda: Espaço superior criado por margin top ou div vazia isolada para garantir fluxo -->
                <div class="col-esquerda flex flex-col justify-between pt-[3.5em]">
                    ${leftColItems.map(getConditionHtml).join('')}
                </div>
                
                <!-- Coluna Central -->
                <div class="col-central flex flex-col items-start justify-start">
                    ${centerColItems.map(getConditionHtml).join('')}
                </div>
                
                <!-- Coluna Direita -->
                <div class="col-direita flex flex-col justify-between pt-[3.5em]">
                    ${rightColItems.map(getConditionHtml).join('')}
                </div>
            </div>

            <!-- Laudo (Stretches to fill available space at the bottom) -->
            <div class="area-footer flex-1 px-[1em] py-[1em] flex flex-col justify-start items-stretch border-t border-[#ccc] mt-[2em]">
                <div class="laudo-container w-full flex flex-col gap-[0.5em] h-full">
                    <label class="text-[0.8em] font-medium text-[#333]">Laudo</label>
                    <textarea class="w-full flex-1 border border-[#ccc] p-[1em] rounded text-[0.8em] leading-tight resize-none focus:outline-none" readonly>${data.laudo || ''}</textarea>
                </div>
            </div>
        </div>
    `;
};

const handlePrint = () => {
    // We generate the HTML string dynamically instead of reading the DOM
    const printContentHTML = generatePrintHtml(reportData.value);

    // Get all styles to inject into the iframe
    const styleElements = Array.from(document.querySelectorAll('style, link[rel="stylesheet"]'))
        .map(el => el.outerHTML)
        .join('\n');

    const htmlContent = `
        <!DOCTYPE html>
        <!-- Forcing light mode explicitly so Tailwind doesn't use dark variants -->
        <html class="light" style="background-color: white !important;">
        <head>
            <meta charset="utf-8">
            <title>Relatório de Exame - Otolithics</title>
            ${styleElements}
            <!-- Tailwind CDN for basic print support if external stylesheets don't load quickly enough ->
            <script src="https://cdn.tailwindcss.com"></s` + `cript>
            <!-- Tailwind Config to force light mode -->
            <script>
                tailwind.config = { darkMode: 'class' }
            </s` + `cript>
            <style>
                @page { size: A4; margin: 0; }
                /* Force pure white background on the print iframe body wrapper, overriding global dark mode styles */
                body, html { margin: 0 !important; padding: 0 !important; background: white !important; background-color: white !important; color: black !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; width: 210mm; height: 297mm; }
                #print-container { width: 210mm !important; height: 297mm !important; background-color: white !important; color: black !important; font-size: 13.5px; box-sizing: border-box; display: flex; flex-direction: column; overflow: hidden; /* Prevent page break bleeding */ }
                /* Remove any specific dark background classes inherited from Vue rendering */
                .bg-white { background-color: white !important; }
                .text-black { color: black !important; }
                /* Make sure aspect-box backgrounds are definitely printed */
                .aspect-box { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
            </style>
        </head>
        <body style="background-color: white !important; color: black !important;">
            ${printContentHTML}
        </body>
        </html>
    `;

    const iframe = document.createElement('iframe');
    iframe.style.position = 'fixed';
    iframe.style.right = '0';
    iframe.style.bottom = '0';
    iframe.style.width = '0';
    iframe.style.height = '0';
    iframe.style.border = '0';
    document.body.appendChild(iframe);

    const doc = iframe.contentDocument || iframe.contentWindow?.document;
    if (!doc) {
        document.body.removeChild(iframe);
        console.error("Failed to access iframe document");
        return;
    }

    doc.open();
    doc.write(htmlContent);
    doc.close();

    const waitForImages = () => {
        const images = doc.images;
        if (!images.length) {
            printNow();
            return;
        }

        let loadedCount = 0;
        const check = () => {
            loadedCount++;
            if (loadedCount === images.length) {
                printNow();
            }
        };

        for (let img of images) {
            if (img.complete) {
                check();
            } else {
                img.addEventListener('load', check);
                img.addEventListener('error', check);
            }
        }
    };

    const printNow = () => {
        if (!iframe.contentWindow) return;
        iframe.contentWindow.focus();
        iframe.contentWindow.print();
        setTimeout(() => {
            document.body.removeChild(iframe);
        }, 1000);
    };

    iframe.onload = () => {
        waitForImages();
    };
};
</script>

<template>
    <Teleport to="body">
        <div v-if="isOpen" class="fixed inset-0 z-[9999] bg-black/80 backdrop-blur-sm print:bg-white print:static">
            
            <!-- Overlay click to close (behind content) -->
            <!-- Center the document in the viewport -->
            <div class="flex items-center justify-center w-full h-full overflow-y-auto">

                <!-- Wrapper: toolbar + document side by side -->
                <div class="flex flex-row gap-4 items-start">

                    <!-- Side Actions Toolbar -->
                    <div class="flex flex-col gap-2 p-2 bg-div-15 rounded-lg shadow-sm print:hidden self-start mt-4 flex-none">
                        <button 
                            @click="handlePrint" 
                            class="p-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-all shadow-sm flex items-center justify-center group"
                            title="Imprimir"
                        >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                        </button>
                        <button 
                            @click="emit('close')" 
                            class="p-2 bg-danger text-white rounded-lg hover:bg-red-700 transition-all shadow-sm flex items-center justify-center group"
                            title="Fechar"
                        >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                <!-- Modal Document Wrapper -->
                <div 
                    ref="documentRef"
                    class="bg-white text-black relative shadow-2xl overflow-hidden print:w-full print:h-full print:shadow-none print:transform-none flex-shrink-0"
                    :style="containerStyle"
                >
                        <!-- Report HTML Structure (Adapted from User Ref) -->
                        <div id="meu-container" class="flex flex-col h-full font-poppins p-[24px]">

                        <!-- Header -->
                        <div class="area1 flex-none h-[10%] min-h-[5em] px-[1em] py-[1em] flex items-center border-b border-[#ccc] mb-[1.5em]">
                            <div class="header-content flex items-center gap-[2em] w-full">
                                <!-- Placeholder Logo if invalid URL -->
                                <div class="w-[3.75em] h-[3.75em] flex items-center justify-center bg-gray-100 text-[0.5em] text-gray-400" v-if="!reportData.header?.logo">Logo</div>
                                <img 
                                    v-else 
                                    :src="reportData.header?.logo" 
                                    class="max-h-[3.75em] object-contain"
                                    @error="(e) => (e.target as HTMLImageElement).style.display = 'none'"
                                >
                                
                                <div class="header-text flex flex-col justify-center">
                                    <div class="text-[0.9em] font-bold pb-[0.2em]">{{ reportData.header?.clinicName }}</div>
                                    <div class="text-[0.7em] text-[#333]"><span class="font-semibold text-gray-500">Paciente:</span> {{ reportData.header?.patientName }}</div>
                                    <div class="text-[0.55em] text-[#666]"><span class="font-medium text-gray-400">Profissional Responsável:</span> {{ reportData.header?.doctorName }}</div>
                                </div>
                            </div>
                        </div>

                        <!-- Charts Area -->
                        <div class="area-body flex-1 grid grid-cols-3 gap-[1.5em] px-[1em] relative">
                            
                            <!-- Coluna Esquerda -->
                            <div class="col-esquerda flex flex-col justify-between pt-[3.5em]">
                                <template v-for="item in [reportData.rows?.[0]?.[0], reportData.rows?.[1]?.[0], reportData.rows?.[2]?.[0]].filter(Boolean)" :key="item?.key || Math.random()">
                                    <div v-if="item" class="sub-item w-full flex flex-col items-center relative mb-[1.5em] cursor-pointer rounded-md transition-all hover:ring-1 hover:ring-primary/20 hover:bg-primary/5" @mouseenter="hoveredItem = item" @mouseleave="hoveredItem = null">
                                        <div class="titulo-condicao text-[0.8em] font-semibold mb-[0.25em] text-[#333]">{{ item.label }}</div>
                                        <div class="aspect-box w-full bg-contain bg-no-repeat bg-center relative" :class="`aspect-box-${item.type}`" style="aspect-ratio: 16/9;">
                                            <div class="linha-angulo absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#FF7900]" :style="{ transform: `translateX(-50%) rotate(${item.lin1}deg)` }"></div>
                                            <div class="linha-angulo-azul absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#707070]" :style="{ transform: `translateX(-50%) rotate(${item.lin2}deg)` }"></div>
                                        </div>
                                        <div class="medidas-box mt-[0.125em] rounded px-[0.4em] py-[0.125em] text-[0.65em] flex flex-col items-center gap-px">
                                            <div class="linha-superior flex gap-[0.5em] justify-center">
                                                <div class="medida whitespace-nowrap">M1: {{ item.m1 }}</div>
                                                <div class="medida whitespace-nowrap">M2: {{ item.m2 }}</div>
                                                <div class="medida whitespace-nowrap">M3: {{ item.m3 }}</div>
                                                <div class="medida whitespace-nowrap">M4: {{ item.m4 }}</div>
                                            </div>
                                            <div class="linha-inferior flex gap-[1em] justify-center">
                                                <div class="medida md text-[#FF7900] font-bold whitespace-nowrap">MD: {{ item.md }}</div>
                                                <div class="medida mnd text-[#707070] font-bold whitespace-nowrap">MND: {{ item.mnd }}</div>
                                            </div>
                                        </div>
                                    </div>
                                </template>
                            </div>
                            
                            <!-- Coluna Central -->
                            <div class="col-central flex flex-col items-start justify-start">
                                <template v-for="item in [reportData.rows?.[0]?.[1]].filter(Boolean)" :key="item?.key || Math.random()">
                                    <div v-if="item" class="sub-item w-full flex flex-col items-center relative mb-[1.5em] cursor-pointer rounded-md transition-all hover:ring-1 hover:ring-primary/20 hover:bg-primary/5" @mouseenter="hoveredItem = item" @mouseleave="hoveredItem = null">
                                        <div class="titulo-condicao text-[0.8em] font-semibold mb-[0.25em] text-[#333]">{{ item.label }}</div>
                                        <div class="aspect-box w-full bg-contain bg-no-repeat bg-center relative" :class="`aspect-box-${item.type}`" style="aspect-ratio: 16/9;">
                                            <div class="linha-angulo absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#FF7900]" :style="{ transform: `translateX(-50%) rotate(${item.lin1}deg)` }"></div>
                                            <div class="linha-angulo-azul absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#707070]" :style="{ transform: `translateX(-50%) rotate(${item.lin2}deg)` }"></div>
                                        </div>
                                        <div class="medidas-box mt-[0.125em] rounded px-[0.4em] py-[0.125em] text-[0.65em] flex flex-col items-center gap-px">
                                            <div class="linha-superior flex gap-[0.5em] justify-center">
                                                <div class="medida whitespace-nowrap">M1: {{ item.m1 }}</div>
                                                <div class="medida whitespace-nowrap">M2: {{ item.m2 }}</div>
                                                <div class="medida whitespace-nowrap">M3: {{ item.m3 }}</div>
                                                <div class="medida whitespace-nowrap">M4: {{ item.m4 }}</div>
                                            </div>
                                            <div class="linha-inferior flex gap-[1em] justify-center">
                                                <div class="medida md text-[#FF7900] font-bold whitespace-nowrap">MD: {{ item.md }}</div>
                                                <div class="medida mnd text-[#707070] font-bold whitespace-nowrap">MND: {{ item.mnd }}</div>
                                            </div>
                                        </div>
                                    </div>
                                </template>
                            </div>
                            
                            <!-- Coluna Direita -->
                            <div class="col-direita flex flex-col justify-between pt-[3.5em]">
                                <template v-for="item in [reportData.rows?.[0]?.[2], reportData.rows?.[1]?.[1], reportData.rows?.[2]?.[1]].filter(Boolean)" :key="item?.key || Math.random()">
                                    <div v-if="item" class="sub-item w-full flex flex-col items-center relative mb-[1.5em] cursor-pointer rounded-md transition-all hover:ring-1 hover:ring-primary/20 hover:bg-primary/5" @mouseenter="hoveredItem = item" @mouseleave="hoveredItem = null">
                                        <div class="titulo-condicao text-[0.8em] font-semibold mb-[0.25em] text-[#333]">{{ item.label }}</div>
                                        <div class="aspect-box w-full bg-contain bg-no-repeat bg-center relative" :class="`aspect-box-${item.type}`" style="aspect-ratio: 16/9;">
                                            <div class="linha-angulo absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#FF7900]" :style="{ transform: `translateX(-50%) rotate(${item.lin1}deg)` }"></div>
                                            <div class="linha-angulo-azul absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[1px] bg-[#707070]" :style="{ transform: `translateX(-50%) rotate(${item.lin2}deg)` }"></div>
                                        </div>
                                        <div class="medidas-box mt-[0.125em] rounded px-[0.4em] py-[0.125em] text-[0.65em] flex flex-col items-center gap-px">
                                            <div class="linha-superior flex gap-[0.5em] justify-center">
                                                <div class="medida whitespace-nowrap">M1: {{ item.m1 }}</div>
                                                <div class="medida whitespace-nowrap">M2: {{ item.m2 }}</div>
                                                <div class="medida whitespace-nowrap">M3: {{ item.m3 }}</div>
                                                <div class="medida whitespace-nowrap">M4: {{ item.m4 }}</div>
                                            </div>
                                            <div class="linha-inferior flex gap-[1em] justify-center">
                                                <div class="medida md text-[#FF7900] font-bold whitespace-nowrap">MD: {{ item.md }}</div>
                                                <div class="medida mnd text-[#707070] font-bold whitespace-nowrap">MND: {{ item.mnd }}</div>
                                            </div>
                                        </div>
                                    </div>
                                </template>
                            </div>
                        </div>

                        <!-- Laudo -->
                        <div class="area-footer flex-1 px-[1em] py-[1em] flex flex-col justify-start items-stretch border-t border-[#ccc] mt-[2em]">
                            <div class="laudo-container w-full flex flex-col gap-[0.5em] h-full">
                                <label class="text-[0.8em] font-medium text-[#333]">Laudo</label>
                                <textarea class="w-full flex-1 border border-[#ccc] p-[1em] rounded text-[0.8em] leading-tight resize-none focus:outline-none" readonly :value="reportData.laudo"></textarea>
                            </div>
                        </div>

                        </div> <!-- End of meu-container -->
                    </div> <!-- End of Modal Document Wrapper -->

                </div> <!-- End flex row wrapper -->
                
            </div> <!-- End centering div -->
        </div> <!-- End Overlay -->
    </Teleport>

    <!-- Hover Zoom Overlay (separate Teleport so it's always on top) -->
    <Teleport to="body">
        <Transition name="zoom-card">
            <div 
                v-if="hoveredItem"
                class="bg-white rounded-xl shadow-2xl border border-secondary/10 p-8 flex flex-col items-center gap-6 pointer-events-none print:hidden"
                :style="{ position: 'fixed', zIndex: 99999, left: hoverCardLeft, top: '50%', transform: 'translate(-50%, -50%)', width: 'calc(90vh * 0.70707 - 32px)', maxWidth: '700px' }"
                >
                    <!-- Title -->
                    <h3 class="text-base font-bold text-gray-800 text-center">{{ hoveredItem.label }}</h3>

                    <!-- Chart image + lines -->
                    <div 
                        class="w-full bg-contain bg-no-repeat bg-center relative"
                        :class="`aspect-box-${hoveredItem.type}`"
                        style="aspect-ratio: 16/9; width: 100%;"
                    >
                        <div class="linha-angulo absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[2px] bg-[#FF7900]" :style="{ transform: `translateX(-50%) rotate(${hoveredItem.lin1}deg)` }"></div>
                        <div class="linha-angulo-azul absolute bottom-[15%] left-1/2 origin-bottom h-[60%] w-[2px] bg-[#707070]" :style="{ transform: `translateX(-50%) rotate(${hoveredItem.lin2}deg)` }"></div>
                    </div>

                    <!-- Measurements -->
                    <div class="flex flex-col items-center gap-1 text-sm">
                        <div class="flex gap-3 text-gray-600">
                            <span>M1: <strong>{{ hoveredItem.m1 }}</strong></span>
                            <span>M2: <strong>{{ hoveredItem.m2 }}</strong></span>
                            <span>M3: <strong>{{ hoveredItem.m3 }}</strong></span>
                            <span>M4: <strong>{{ hoveredItem.m4 }}</strong></span>
                        </div>
                        <div class="flex gap-6 text-sm font-bold mt-1">
                            <span class="text-[#FF7900]">MD: {{ hoveredItem.md }}</span>
                            <span class="text-[#707070]">MND: {{ hoveredItem.mnd }}</span>
                        </div>
                    </div>
                </div>
        </Transition>
    </Teleport>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

.font-poppins {
    font-family: 'Poppins', sans-serif;
}

/* Specific positioning to match user reference */
/* Converted px/magic numbers to em for scaling */
.linha-cima .sub-item.central { transform: translateY(-2.2em); }
.linha-cima .sub-item:not(.central) { transform: translateY(0.6em); }

.aspect-box-normal { background-image: url('https://otolithics-p.b-cdn.net/transferidor_cabeca_normal.png'); }
.aspect-box-direita { background-image: url('https://otolithics-p.b-cdn.net/transferidor_cabeca_direita.png'); }
.aspect-box-esquerda { background-image: url('https://otolithics-p.b-cdn.net/transferidor_cabeca_esquerda.png'); }

/* Hover zoom card transition */
.zoom-card-enter-active,
.zoom-card-leave-active {
    transition: opacity 0.35s ease-out, transform 0.35s ease-out;
}
.zoom-card-enter-from,
.zoom-card-leave-to {
    opacity: 0;
    transform: scale(0.93) translateY(8px);
}
.zoom-card-enter-to,
.zoom-card-leave-from {
    opacity: 1;
    transform: scale(1) translateY(0);
}

@media print {
    @page {
        size: A4;
        margin: 0;
    }
    body {
        background: white;
    }
    /* Reset styles for print to ensure full page usage */
    #meu-container {
        width: 100% !important;
        height: 100% !important;
    }
    .area1,
    .area2,
    .area3 {
        /* Ensure sizes hold in print - currently empty but reserved for future tweaks */
        display: block;
    }
}
</style>
