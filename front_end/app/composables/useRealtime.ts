import { ref } from 'vue';


export const useRealtime = () => {
    const supabase = useSupabaseClient();
    const channels = ref<Record<string, any>>({});
    const messages = ref<any[]>([]);
    const isConnected = ref(false);

    const connect = (channelName: string, eventName: string = 'broadcast') => {
        if (channels.value[channelName]) {
            console.log(`Already connected to ${channelName}`);
            return;
        }

        console.log(`Connecting to channel: ${channelName}`);
        const channel = supabase.channel(channelName);

        channel
            .on(
                'broadcast',
                { event: eventName },
                (payload: { [key: string]: any }) => {
                    console.log('Received message:', payload);
                    // Add timestamp to message
                    const msgWithTime = {
                        ...payload,
                        received_at: new Date().toISOString()
                    };
                    messages.value.unshift(msgWithTime);
                }
            )
            .subscribe((status: 'SUBSCRIBED' | 'TIMED_OUT' | 'CLOSED' | 'CHANNEL_ERROR') => {
                console.log(`Channel ${channelName} status:`, status);
                if (status === 'SUBSCRIBED') {
                    isConnected.value = true;
                } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
                     isConnected.value = false;
                }
            });

        channels.value[channelName] = channel;
    };

    const disconnect = (channelName: string) => {
        if (channels.value[channelName]) {
            console.log(`Disconnecting from ${channelName}`);
            supabase.removeChannel(channels.value[channelName]);
            delete channels.value[channelName];
            isConnected.value = false; // Simplified for single channel test
        }
    };

    const clearMessages = () => {
        messages.value = [];
    };

    return {
        connect,
        disconnect,
        messages,
        isConnected,
        clearMessages
    };
};
