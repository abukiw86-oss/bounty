enum StreamLiveStatus { initial, loading, ready, live, error }

class StreamLiveState {
  final StreamLiveStatus status;
  final int viewerCount;
  final bool isMuted;
  final String? error;

  StreamLiveState({
    required this.status,
    this.viewerCount = 0,
    this.isMuted = false,
    this.error,
  });

  StreamLiveState copyWith({
    StreamLiveStatus? status,
    int? viewerCount,
    bool? isMuted,
    String? error,
  }) {
    return StreamLiveState(
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      isMuted: isMuted ?? this.isMuted,
      error: error ?? this.error,
    );
  }
}
