// lib/infrastructure/discovery_repository.dart
import 'package:socket_io_client/socket_io_client.dart' as io;

class DiscoveryRepository {
  io.Socket? _socket;

  Function(List<dynamic>)? onListUpdated;
  Function(String)? onFrameReceived;

  void connectHub(String url) {
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // Listen for the global active list updates
    _socket?.on('live_list_update', (data) {
      if (onListUpdated != null) {
        onListUpdated!(data['streams'] ?? []);
      }
    });

    _socket?.on('incoming_frame', (data) {
      if (onFrameReceived != null) {
        onFrameReceived!(data['frame'] ?? '');
      }
    });

    _socket?.connect();
  }

  void joinStreamAsViewer(String streamId) {
    _socket?.emit('join_as_viewer', {'streamId': streamId});
  }

  void exitStreamViewerMode() {
    _socket?.emit('leave_stream');
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
