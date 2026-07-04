// lib/application/discovery/discovery_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/discovery_repository.dart';

abstract class DiscoveryEvent {}

class ConnectFeedEvent extends DiscoveryEvent {}

class RefreshFeedEvent extends DiscoveryEvent {}

class ReconnectFeedEvent extends DiscoveryEvent {}

class _UpdateFeedListEvent extends DiscoveryEvent {
  final List<dynamic> liveUsers;
  _UpdateFeedListEvent(this.liveUsers);
}

class DiscoveryState {
  final List<dynamic> activeLives;
  final bool isLoading;
  final String? error;

  DiscoveryState({
    required this.activeLives,
    this.isLoading = true,
    this.error,
  });

  DiscoveryState copyWith({
    List<dynamic>? activeLives,
    bool? isLoading,
    String? error,
  }) {
    return DiscoveryState(
      activeLives: activeLives ?? this.activeLives,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository repository;

  DiscoveryBloc(this.repository)
    : super(DiscoveryState(activeLives: [], isLoading: true)) {
    repository.onListUpdated = (usersList) {
      add(_UpdateFeedListEvent(usersList));
    };

    on<ConnectFeedEvent>((event, emit) {
      emit(state.copyWith(isLoading: true, error: null));
      repository.connectHub('wss://bounty-n8fj.onrender.com/');
    });

    on<RefreshFeedEvent>((event, emit) {
      emit(state.copyWith(isLoading: true, error: null));
      // Re-request the live list
      repository.requestLiveList();

      // If no response in 5 seconds, stop loading
      Future.delayed(const Duration(seconds: 5), () {
        if (state.isLoading) {
          emit(state.copyWith(isLoading: false));
        }
      });
    });

    on<ReconnectFeedEvent>((event, emit) {
      emit(state.copyWith(isLoading: true, error: null));
      repository.dispose();
      repository.connectHub('wss://bounty-n8fj.onrender.com/');

      // If no response in 5 seconds, show error
      Future.delayed(const Duration(seconds: 5), () {
        if (state.isLoading) {
          emit(
            state.copyWith(
              isLoading: false,
              error: 'Failed to connect. Please try again.',
            ),
          );
        }
      });
    });

    on<_UpdateFeedListEvent>((event, emit) {
      emit(
        DiscoveryState(
          activeLives: event.liveUsers,
          isLoading: false,
          error: null,
        ),
      );
    });
  }
}
