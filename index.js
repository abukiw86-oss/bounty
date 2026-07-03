const { WebSocketServer } = require('ws');

const wss = new WebSocketServer({ host: '0.0.0.0', port: 3000 });
console.log('🚀 TikTok Live Router Running on ws://localhost:3000');
 
const activeStreams = new Map();

wss.on('connection', (ws) => { 
    const deviceId = Math.random().toString(36).substring(2, 9);
    ws.id = deviceId;
 
    sendLiveListUpdates();

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);

            switch (data.type) { 

                case 'start_hosting': 
                    activeStreams.set(ws.id, { id: ws.id, username: data.username || `User_${ws.id}` });
                    console.log(`🎥 Stream Started by: ${data.username}`);
                    sendLiveListUpdates();
                    break;

                case 'video_frame': 
                    wss.clients.forEach((client) => {
                        if (client !== ws && client.readyState === 1 && client.watchingStreamId === ws.id) {
                            client.send(JSON.stringify({
                                type: 'incoming_frame',
                                frame: data.frame
                            }));
                        }
                    });
                    break;

                case 'join_as_viewer': 
                    ws.watchingStreamId = data.streamId;
                    console.log(`👁️ Device joined stream target: ${data.streamId}`);
                    break;

                case 'leave_stream':
                    ws.watchingStreamId = null;
                    break;
            }
        } catch (error) {
        console.error("Failed to parse incoming message:", error);
    }
    });

    ws.on('close', () => {
        if (activeStreams.has(ws.id)) {
            activeStreams.delete(ws.id);
            console.log(`❌ Stream Closed by Host: ${ws.id}`);
            sendLiveListUpdates();
        }
    });
});

function sendLiveListUpdates() {
    const list = Array.from(activeStreams.values());
    const payload = JSON.stringify({ type: 'live_list_update', streams: list });
    
    wss.clients.forEach((client) => {
        if (client.readyState === 1) {
            client.send(payload);
        }
    });
}