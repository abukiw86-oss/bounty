// lib/state/stream_state.dart
enum StreamLiveStatus { initial, loading, ready, live, error }

class StreamLiveState {
  final StreamLiveStatus status;
  final bool isMuted;
  final int viewerCount;
  final String? error;
  final String? deviceName;
  final bool isSharingLocation; // Location sharing state

  StreamLiveState({
    required this.status,
    this.isMuted = false,
    this.viewerCount = 0,
    this.error,
    this.deviceName,
    this.isSharingLocation = false, // Default to false
  });

  StreamLiveState copyWith({
    StreamLiveStatus? status,
    bool? isMuted,
    int? viewerCount,
    String? error,
    String? deviceName,
    bool? isSharingLocation,
  }) {
    return StreamLiveState(
      status: status ?? this.status,
      isMuted: isMuted ?? this.isMuted,
      viewerCount: viewerCount ?? this.viewerCount,
      error: error ?? this.error,
      deviceName: deviceName ?? this.deviceName,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
    );
  }
}
