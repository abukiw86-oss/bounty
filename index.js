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
                    activeStreams.set(ws.id, { 
                        id: ws.id, 
                        username: data.username || `User_${ws.id}` 
                    });
                    console.log(`🎥 Stream Started by: ${data.username || 'Unknown'}`);
                    sendLiveListUpdates();
                    break;

                case 'video_frame': 
                    // Relay video frames to viewers
                    wss.clients.forEach((client) => {
                        if (client !== ws && 
                            client.readyState === 1 && 
                            client.watchingStreamId === ws.id) {
                            client.send(JSON.stringify({
                                type: 'incoming_frame',
                                frame: data.frame
                            }));
                        }
                    });
                    break;

                case 'audio_frame':  // NEW: Handle audio frames
                    // Relay audio frames to viewers
                    wss.clients.forEach((client) => {
                        if (client !== ws && 
                            client.readyState === 1 && 
                            client.watchingStreamId === ws.id) {
                            client.send(JSON.stringify({
                                type: 'incoming_audio',
                                audio: data.audio
                            }));
                        }
                    });
                    break;

                case 'join_as_viewer': 
                    ws.watchingStreamId = data.streamId;
                    console.log(`👁️ Viewer joined stream: ${data.streamId}`);
                    
                    // Send viewer count update to broadcaster
                    updateViewerCount(data.streamId);
                    break;

                case 'leave_stream':
                    const streamId = ws.watchingStreamId;
                    ws.watchingStreamId = null;
                    console.log(`👋 Viewer left stream: ${streamId}`);
                    
                    // Update viewer count
                    if (streamId) {
                        updateViewerCount(streamId);
                    }
                    break;
            }
        } catch (error) {
            console.error("Failed to parse incoming message:", error);
        }
    });

    ws.on('close', () => {
        console.log(`🔌 Client disconnected: ${ws.id}`);
        
        // If this was a broadcaster, remove their stream
        if (activeStreams.has(ws.id)) {
            activeStreams.delete(ws.id);
            console.log(`❌ Stream Ended: ${ws.id}`);
            sendLiveListUpdates();
        }
        
        // Update viewer count if this was a viewer
        if (ws.watchingStreamId) {
            updateViewerCount(ws.watchingStreamId);
        }
    });
});

function sendLiveListUpdates() {
    const list = Array.from(activeStreams.values());
    const payload = JSON.stringify({ 
        type: 'live_list_update', 
        streams: list 
    });
    
    wss.clients.forEach((client) => {
        if (client.readyState === 1) {
            client.send(payload);
        }
    });
}

// NEW: Function to update viewer count for a stream
function updateViewerCount(streamId) {
    if (!streamId) return;
    
    // Count viewers for this stream
    let viewerCount = 0;
    wss.clients.forEach((client) => {
        if (client.watchingStreamId === streamId && client.readyState === 1) {
            viewerCount++;
        }
    });
    
    // Find the broadcaster and send the count
    wss.clients.forEach((client) => {
        if (client.id === streamId && client.readyState === 1) {
            client.send(JSON.stringify({
                type: 'viewer_update',
                count: viewerCount
            }));
        }
    });
    
    console.log(`👥 Stream ${streamId} has ${viewerCount} viewers`);
}

console.log('✅ Server ready for video AND audio streaming');