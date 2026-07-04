// lib/application/stream_live_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../infrastructure/stream_repository.dart';
import 'package:hvc_net/state/stream_state.dart';

abstract class StreamLiveEvent {}

class InitStreamSetupEvent extends StreamLiveEvent {}

class StartBroadcastEvent extends StreamLiveEvent {}

class ToggleMuteEvent extends StreamLiveEvent {}

class ToggleLocationSharingEvent extends StreamLiveEvent {}

class StopBroadcastEvent extends StreamLiveEvent {}

class _UpdateViewerCountEvent extends StreamLiveEvent {
  final int count;
  _UpdateViewerCountEvent(this.count);
}

class StreamLiveBloc extends Bloc<StreamLiveEvent, StreamLiveState> {
  final StreamRepository repository;

  StreamLiveBloc(this.repository)
    : super(StreamLiveState(status: StreamLiveStatus.initial)) {
    repository.onViewerCountChanged = (count) {
      add(_UpdateViewerCountEvent(count));
    };

    on<InitStreamSetupEvent>((event, emit) async {
      emit(state.copyWith(status: StreamLiveStatus.loading));
      try {
        repository.initializeSocket('wss://bounty-n8fj.onrender.com/');
        await repository.initializeCamera();
        emit(
          state.copyWith(
            status: StreamLiveStatus.ready,
            isSharingLocation:
                repository.isSharingLocation, // Set initial location state
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(status: StreamLiveStatus.error, error: e.toString()),
        );
      }
    });

    on<StartBroadcastEvent>((event, emit) {
      repository.startLiveBroadcast();
      emit(
        state.copyWith(
          status: StreamLiveStatus.live,
          isSharingLocation:
              repository.isSharingLocation, // Update location state
        ),
      );
    });

    on<ToggleMuteEvent>((event, emit) {
      repository.toggleMute();
      emit(state.copyWith(isMuted: !state.isMuted));
    });

    on<ToggleLocationSharingEvent>((event, emit) async {
      // FIXED: Call the correct method name
      await repository.toggleLocationSharing();
      emit(state.copyWith(isSharingLocation: repository.isSharingLocation));
      print(
        "📍 Location sharing: ${repository.isSharingLocation ? 'ON' : 'OFF'}",
      );
    });

    on<_UpdateViewerCountEvent>((event, emit) {
      emit(state.copyWith(viewerCount: event.count));
    });

    on<StopBroadcastEvent>((event, emit) async {
      await repository.stopBroadcast();
      emit(
        state.copyWith(
          status: StreamLiveStatus.ready,
          viewerCount: 0,
          isSharingLocation: false, // Reset location state when stopping
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await repository.dispose();
    return super.close();
  }
}
