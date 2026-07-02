// lib/infrastructure/stream_repository.dart
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class StreamRepository {
  CameraController? _cameraController;
  io.Socket? _socket;
  bool _isBroadcasting = false;

  Function(int)? onViewerCountChanged;

  CameraController? get controller => _cameraController;

  void initializeSocket(String url) {
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.on('viewer_update', (data) {
      if (onViewerCountChanged != null) {
        onViewerCountChanged!(data['count'] ?? 0);
      }
    });

    _socket?.connect();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No hardware lenses found.");
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: true,
    );

    await _cameraController!.initialize();
  }

  void startLiveBroadcast() {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    _isBroadcasting = true;
    _socket?.emit('start_hosting', {'username': 'Abuki_Dev'});

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isBroadcasting) return;

      try {
        final List<int> bytes = image.planes.fold<List<int>>(
          [],
          (prev, plane) => prev..addAll(plane.bytes),
        );
        String base64Frame = base64Encode(bytes);

        _socket?.emit('video_frame', {
          'frame': base64Frame,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        print("Frame dropping occurred: $e");
      }
    });
  }

  Future<void> stopBroadcast() async {
    _isBroadcasting = false;
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    _socket?.emit('leave_stream');
    _socket?.disconnect();
  }

  Future<void> dispose() async {
    await stopBroadcast();
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
