const { WebSocketServer } = require('ws');

const wss = new WebSocketServer({ port: 3000 });
console.log('🚀 Streaming hub running natively on ws://localhost:3000');

let activeViewers = 0;

wss.on('connection', (ws) => {
    activeViewers++;
    broadcastToAll({ event: 'viewer_update', count: activeViewers });
    console.log(`🔌 Device joined. Total Broadcasters/Viewers: ${activeViewers}`);

    ws.on('message', (message) => {
        try { 
            const payload = JSON.parse(message); 
            wss.clients.forEach((client) => {
                if (client !== ws && client.readyState === 1) {
                    client.send(JSON.stringify({
                        event: 'incoming_frame',
                        frame: payload.frame
                    }));
                }
            });
        } catch(e) { 
            console.log(`📥 Plain text message caught: ${message}`);
        }
    });

    ws.on('close', () => {
        activeViewers = Math.max(0, activeViewers - 1);
        broadcastToAll({ event: 'viewer_update', count: activeViewers });
        console.log('❌ Client disconnected.');
    });
});

function broadcastToAll(obj) {
    wss.clients.forEach(client => {
        if (client.readyState === 1) {
            client.send(JSON.stringify(obj));
        }
    });
}