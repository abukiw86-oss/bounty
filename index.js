const { WebSocketServer } = require('ws');
 
const wss = new WebSocketServer({ port: 3000 });

console.log('🚀 WebSocket server started on ws://localhost:3000');

wss.on('connection', (ws) => {
    console.log('🔌   successfully connected to Kali Localhost!');
    ws.on('message', (message) => {
        console.log(`📥 Received: ${message}`);
        wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === 1) {
                client.send(message);
            }
        });
    });

    ws.on('close', () => {
        console.log('❌ Client disconnected.');
    });
});