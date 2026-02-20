<script setup lang="ts">
import { ref } from 'vue';

const channelName = ref('sala-teste');
const eventName = ref('broadcast');
const { connect, disconnect, messages, isConnected, clearMessages } = useRealtime();

const handleConnect = () => {
    connect(channelName.value, eventName.value);
};

const handleDisconnect = () => {
    disconnect(channelName.value);
};

const formatTime = (isoString: string) => {
    return new Date(isoString).toLocaleTimeString();
};
    const user = useSupabaseUser();
    
    // Auto-fill event name if it's "Test message" from the screenshot context, 
    // but better to just show the user logic.
</script>

<template>
    <div class="min-h-screen bg-gray-900 text-white p-8">
        <div class="max-w-4xl mx-auto flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold">Teste Realtime (Broadcast)</h1>
            <div class="text-right text-xs text-gray-400 bg-gray-800 p-2 rounded border border-gray-700">
                <p>Status Auth: <span :class="user ? 'text-green-400' : 'text-yellow-400'">{{ user ? 'Logado' : 'Anônimo' }}</span></p>
                <div v-if="user">
                    <p>ID: {{ user.id }}</p>
                    <p>Email: {{ user.email }}</p>
                </div>
            </div>
        </div>

        <div class="flex flex-col gap-4 max-w-2xl mx-auto">
            <!-- Connection Controls -->
            <div class="bg-gray-800 p-6 rounded-lg shadow-lg">
                <div class="grid grid-cols-2 gap-4 mb-4">
                    <div>
                        <label class="block text-sm font-medium mb-2 text-gray-400">Nome do Canal (Sala)</label>
                        <input 
                            v-model="channelName" 
                            type="text" 
                            class="w-full bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-blue-500 transition-colors"
                            :disabled="isConnected"
                        />
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-2 text-gray-400">Nome do Evento</label>
                        <input 
                            v-model="eventName" 
                            type="text" 
                            class="w-full bg-gray-700 border border-gray-600 rounded px-4 py-2 focus:outline-none focus:border-blue-500 transition-colors"
                            :disabled="isConnected"
                            placeholder="ex: broadcast, Test message"
                        />
                        <p class="text-[10px] text-yellow-500 mt-1">
                            * Deve ser EXATAMENTE igual ao enviado (ex: "Test message") ou "*" para todos.
                        </p>
                    </div>
                </div>

                <div class="flex gap-4">
                    <button 
                        v-if="!isConnected"
                        @click="handleConnect" 
                        class="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded font-medium transition-colors"
                    >
                        Conectar
                    </button>
                    <button 
                        v-else
                        @click="handleDisconnect" 
                        class="flex-1 bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded font-medium transition-colors"
                    >
                        Desconectar
                    </button>
                </div>
                
                <div class="mt-4 flex items-center justify-between">
                    <div class="flex items-center gap-2">
                        <span class="w-3 h-3 rounded-full" :class="isConnected ? 'bg-green-500' : 'bg-red-500'"></span>
                        <span class="text-sm text-gray-300">
                            {{ isConnected ? 'Conectado' : 'Desconectado' }}
                        </span>
                    </div>
                     <button @click="clearMessages" class="text-xs text-gray-400 hover:text-white underline">Limpar Log</button>
                </div>
            </div>

            <!-- Message Log -->
            <div class="bg-gray-800 p-6 rounded-lg shadow-lg h-96 flex flex-col">
                <h2 class="text-xl font-semibold mb-4 text-gray-200">Mensagens Recebidas</h2>
                <div class="flex-1 overflow-y-auto bg-gray-950 p-4 rounded font-mono text-sm border border-gray-700">
                    <div v-if="messages.length === 0" class="text-gray-500 text-center italic mt-10">
                        Aguardando mensagens...
                    </div>
                    <div v-else class="space-y-3">
                        <div v-for="(msg, index) in messages" :key="index" class="border-l-2 border-blue-500 pl-3 py-1">
                            <div class="text-xs text-blue-400 mb-1 flex justify-between">
                                <span>{{ msg.event }}</span>
                                <span>{{ formatTime(msg.received_at) }}</span>
                            </div>
                            <pre class="whitespace-pre-wrap text-gray-300">{{ JSON.stringify(msg.payload || msg, null, 2) }}</pre>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
