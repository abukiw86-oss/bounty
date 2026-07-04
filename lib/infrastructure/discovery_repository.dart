// lib/infrastructure/discovery_repository.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class DiscoveryRepository {
  WebSocketChannel? _channel;

  Function(List<dynamic>)? onListUpdated;
  Function(String)? onFrameReceived;
  Function(String)? onAudioReceived;
  Function(Map<String, dynamic>)? onLocationUpdated; // New callback

  void connectHub(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel?.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message);
            switch (data['type']) {
              case 'live_list_update':
                if (onListUpdated != null) {
                  onListUpdated!(data['streams'] ?? []);
                }
                break;

              case 'incoming_frame':
                if (onFrameReceived != null) {
                  onFrameReceived!(data['frame'] ?? '');
                }
                break;

              case 'incoming_audio':
                if (onAudioReceived != null) {
                  onAudioReceived!(data['audio'] ?? '');
                }
                break;

              // Handle location updates
              case 'location_update':
                if (onLocationUpdated != null && data['location'] != null) {
                  onLocationUpdated!(data['location']);
                }
                break;

              default:
                print("Unknown message type: ${data['type']}");
            }
          } catch (e) {
            print("Error decoding WebSocket message: $e");
          }
        },
        onError: (error) {
          print("WebSocket Error: $error");
        },
        onDone: () {
          print("WebSocket Closed");
        },
      );
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
    }
  }

  void joinStreamAsViewer(String streamId) {
    final payload = jsonEncode({
      'type': 'join_as_viewer',
      'streamId': streamId,
    });
    _channel?.sink.add(payload);
  }

  void exitStreamViewerMode() {
    final payload = jsonEncode({'type': 'leave_stream'});
    _channel?.sink.add(payload);
  }

  void requestLiveList() {
    if (_channel != null) {
      final payload = jsonEncode({'type': 'get_live_list'});
      _channel?.sink.add(payload);
    }
  }

  void dispose() {
    _channel?.sink.close();
  }
}
