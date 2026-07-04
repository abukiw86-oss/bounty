import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;
import 'package:record/record.dart';
import '../services/device_info_service.dart'; // Import the device info service

class StreamRepository {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;

  bool _isBroadcasting = false;
  int _lastVideoSentTime = 0;
  int _frameCount = 0;
  bool _isMuted = false;

  // Device info
  String _deviceName = 'Unknown Device';
  String _deviceId = '';

  static const int _videoThrottleMs = 200;
  static const int _skipFrames = 2;

  Function(int)? onViewerCountChanged;
  CameraController? get controller => _cameraController;

  bool get isMuted => _isMuted;
  String get deviceName => _deviceName;

  void initializeSocket(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel?.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message);
            if (data['type'] == 'viewer_update') {
              onViewerCountChanged?.call(data['count'] ?? 0);
            }
          } catch (e) {
            print("Error parsing incoming message: $e");
          }
        },
        onError: (error) => print("WebSocket Error: $error"),
        onDone: () => print("WebSocket Connection Closed"),
      );
    } catch (e) {
      print("WebSocket Connection initialization failed: $e");
    }
  }

  Future<void> initializeCamera() async {
    // Get device info first
    await _loadDeviceInfo();

    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No hardware lenses found.");

    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();

    if (await _audioRecorder.hasPermission()) {
      print("✅ Audio permission granted");
    } else {
      print("❌ No audio permission");
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      _deviceName = await DeviceInfoService.getDisplayName();
      _deviceId = await DeviceInfoService.getDeviceId();
      print("📱 Device: $_deviceName");
      print("🆔 Device ID: $_deviceId");
    } catch (e) {
      print("Error loading device info: $e");
      _deviceName = 'Flutter User';
      _deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void startLiveBroadcast() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _isBroadcasting = true;
    _frameCount = 0;

    // Send device info instead of hardcoded name
    final Map<String, dynamic> startPayload = {
      'type': 'start_hosting',
      'username': _deviceName, // Dynamic device name
      'deviceId': _deviceId, // Unique device ID
      'platform': _getPlatformInfo(),
    };
    _channel?.sink.add(jsonEncode(startPayload));

    print("🔴 Live broadcast started from: $_deviceName");

    // Start video stream
    _cameraController!.startImageStream(_processVideoFrame);

    // Start audio stream
    _startAudioStreaming();
  }

  Map<String, dynamic> _getPlatformInfo() {
    return {
      'device': _deviceName,
      'deviceId': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Rest of your methods remain the same...
  void _processVideoFrame(CameraImage image) {
    if (!_isBroadcasting) return;

    _frameCount++;
    if (_frameCount % _skipFrames != 0) return;

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastVideoSentTime < _videoThrottleMs) return;
    _lastVideoSentTime = now;

    _convertAndSendVideoFrame(image, now);
  }

  Future<void> _startAudioStreaming() async {
    try {
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 32000,
      );

      final stream = await _audioRecorder.startStream(config);

      _audioSubscription = stream.listen(
        (data) {
          if (!_isBroadcasting || _isMuted) return;

          final audioPayload = jsonEncode({
            'type': 'audio_frame',
            'audio': base64Encode(data),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          _channel?.sink.add(audioPayload);
        },
        onError: (error) => print("❌ Audio stream error: $error"),
        onDone: () => print("Audio stream ended"),
      );

      print("🎤 Audio streaming started");
    } catch (e) {
      print("❌ Audio streaming error: $e");
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    print(_isMuted ? "🔇 Muted" : "🎤 Unmuted");
  }

  Future<void> _convertAndSendVideoFrame(
    CameraImage image,
    int timestamp,
  ) async {
    try {
      final jpegBytes = await _yuv420ToJPEG(image);

      if (jpegBytes == null || jpegBytes.isEmpty) return;

      final String base64Frame = base64Encode(jpegBytes);

      final framePayload = jsonEncode({
        'type': 'video_frame',
        'frame': base64Frame,
        'timestamp': timestamp,
        'deviceId': _deviceId, // Include device ID with frames
      });

      _channel?.sink.add(framePayload);
    } catch (e) {
      print("Video frame error: $e");
    }
  }

  Future<Uint8List?> _yuv420ToJPEG(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      final img.Image rgbImage = img.Image(width: width, height: height);

      final Uint8List yBytes = image.planes[0].bytes;
      final Uint8List uBytes = image.planes[1].bytes;
      final Uint8List vBytes = image.planes[2].bytes;

      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          final int yValue = yBytes[yIndex];
          final int uValue = uBytes[uvIndex] - 128;
          final int vValue = vBytes[uvIndex] - 128;

          int r = (yValue + 1.402 * vValue).round().clamp(0, 255);
          int g = (yValue - 0.344 * uValue - 0.714 * vValue).round().clamp(
            0,
            255,
          );
          int b = (yValue + 1.772 * uValue).round().clamp(0, 255);

          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      final jpegBytes = img.encodeJpg(rgbImage, quality: 30);
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      print("YUV conversion error: $e");
      return null;
    }
  }

  Future<void> stopBroadcast() async {
    _isBroadcasting = false;

    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    try {
      await _audioSubscription?.cancel();
      await _audioRecorder.stop();
      print("🎤 Audio recording stopped");
    } catch (e) {
      print("Error stopping audio: $e");
    }

    if (_channel != null) {
      final Map<String, dynamic> leavePayload = {
        'type': 'leave_stream',
        'deviceId': _deviceId,
      };
      _channel!.sink.add(jsonEncode(leavePayload));
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> dispose() async {
    await stopBroadcast();
    await _cameraController?.dispose();
    await _audioRecorder.dispose();
    _channel?.sink.close();
    _cameraController = null;
  }
}
