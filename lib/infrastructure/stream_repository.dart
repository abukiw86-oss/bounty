import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img;
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import '../services/device_info_service.dart';
import '../services/location_service.dart';

class StreamRepository {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<Position>? _locationSubscription;

  bool _isBroadcasting = false;
  int _lastVideoSentTime = 0;
  int _frameCount = 0;
  bool _isMuted = false;

  // Device info
  String _deviceName = 'Unknown Device';
  String _deviceId = '';

  // Location data
  Map<String, dynamic>? _currentLocation;
  bool _isSharingLocation = false;

  static const int _videoThrottleMs = 200;
  static const int _skipFrames = 2;

  Function(int)? onViewerCountChanged;
  CameraController? get controller => _cameraController;

  bool get isMuted => _isMuted;
  String get deviceName => _deviceName;
  Map<String, dynamic>? get currentLocation => _currentLocation;
  bool get isSharingLocation => _isSharingLocation;

  void initializeSocket(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel?.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message);
            switch (data['type']) {
              case 'viewer_update':
                onViewerCountChanged?.call(data['count'] ?? 0);
                break;
              default:
                print("Received message type: ${data['type']}");
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

    // Request location permission
    await _requestLocationPermission();

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

  Future<void> _requestLocationPermission() async {
    try {
      await LocationService.checkAndRequestPermission();
      _isSharingLocation = true;
      print("📍 Location permission granted");
    } catch (e) {
      print("⚠️ Location permission denied: $e");
      _isSharingLocation = false;
    }
  }

  /// Toggle location sharing on/off
  Future<void> toggleLocationSharing() async {
    if (_isSharingLocation) {
      // Stop sharing location
      _stopLocationUpdates();
      _isSharingLocation = false;
      _currentLocation = null;
      print("📍 Location sharing disabled");
    } else {
      // Start sharing location
      try {
        await LocationService.checkAndRequestPermission();
        _isSharingLocation = true;
        if (_isBroadcasting) {
          await _getAndUpdateLocation();
          _startLocationUpdates();
        }
        print("📍 Location sharing enabled");
      } catch (e) {
        print("Cannot enable location sharing: $e");
        _isSharingLocation = false;
      }
    }
  }

  void startLiveBroadcast() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _isBroadcasting = true;
    _frameCount = 0;

    // Get current location before starting
    if (_isSharingLocation) {
      _getAndUpdateLocation();
    }

    // Send device info with location metadata
    final Map<String, dynamic> startPayload = {
      'type': 'start_hosting',
      'username': _deviceName,
      'deviceId': _deviceId,
      'platform': _getPlatformInfo(),
      'location': _currentLocation,
      'isSharingLocation': _isSharingLocation,
    };
    _channel?.sink.add(jsonEncode(startPayload));

    print("🔴 Live broadcast started from: $_deviceName");
    if (_currentLocation != null) {
      print(
        "📍 Initial Location: ${_currentLocation!['latitude']}, ${_currentLocation!['longitude']}",
      );
    }

    // Start video stream
    _cameraController!.startImageStream(_processVideoFrame);

    // Start audio stream
    _startAudioStreaming();

    // Start location updates if permitted
    if (_isSharingLocation) {
      _startLocationUpdates();
    }
  }

  Map<String, dynamic> _getPlatformInfo() {
    return {
      'device': _deviceName,
      'deviceId': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get current location once
  Future<void> _getAndUpdateLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      _currentLocation = LocationService.formatLocation(position);
      print(
        "📍 Current location: ${_currentLocation!['latitude']}, ${_currentLocation!['longitude']}",
      );
    } catch (e) {
      print("⚠️ Could not get location: $e");
      _currentLocation = null;
    }
  }

  /// Start real-time location updates
  void _startLocationUpdates() {
    _locationSubscription?.cancel();

    // Get initial location
    _getAndUpdateLocation();

    // Listen for location changes
    _locationSubscription = LocationService.getLocationStream().listen(
      (position) {
        _currentLocation = LocationService.formatLocation(position);

        // Send location update to server
        _sendLocationUpdate();

        print(
          "📍 Location updated: ${_currentLocation!['latitude']}, ${_currentLocation!['longitude']}",
        );
      },
      onError: (error) {
        print("❌ Location stream error: $error");
      },
    );
  }

  /// Send location update to server
  void _sendLocationUpdate() {
    if (!_isBroadcasting || _currentLocation == null) return;

    final locationPayload = jsonEncode({
      'type': 'location_update',
      'deviceId': _deviceId,
      'location': _currentLocation,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _channel?.sink.add(locationPayload);
  }

  /// Stop location updates
  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

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
        'deviceId': _deviceId,
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

    // Stop location updates
    _stopLocationUpdates();

    if (_channel != null) {
      final Map<String, dynamic> leavePayload = {
        'type': 'leave_stream',
        'deviceId': _deviceId,
      };
      _channel!.sink.add(jsonEncode(leavePayload));
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print("🔴 Broadcast stopped");
  }

  Future<void> dispose() async {
    await stopBroadcast();
    await _cameraController?.dispose();
    await _audioRecorder.dispose();
    _locationSubscription?.cancel();
    _channel?.sink.close();
    _cameraController = null;
    print("♻️ StreamRepository disposed");
  }
}
