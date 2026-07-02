// lib/application/discovery/discovery_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/discovery_repository.dart';

abstract class DiscoveryEvent {}

class ConnectFeedEvent extends DiscoveryEvent {}

class _UpdateFeedListEvent extends DiscoveryEvent {
  final List<dynamic> liveUsers;
  _UpdateFeedListEvent(this.liveUsers);
}

class DiscoveryState {
  final List<dynamic> activeLives;
  final bool isLoading;

  DiscoveryState({required this.activeLives, this.isLoading = true});
}

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final DiscoveryRepository repository;

  DiscoveryBloc(this.repository)
    : super(DiscoveryState(activeLives: [], isLoading: true)) {
    repository.onListUpdated = (usersList) {
      add(_UpdateFeedListEvent(usersList));
    };

    on<ConnectFeedEvent>((event, emit) {
      repository.connectHub('http://192.168.43.124:3000');
    });

    on<_UpdateFeedListEvent>((event, emit) {
      emit(DiscoveryState(activeLives: event.liveUsers, isLoading: false));
    });
  }
}
