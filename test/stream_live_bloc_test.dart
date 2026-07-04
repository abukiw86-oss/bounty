import 'package:flutter_test/flutter_test.dart';
import 'package:hvc_net/bloc/live_stream.dart';
import 'package:hvc_net/infrastructure/stream_repository.dart';
import 'package:hvc_net/services/foreground_stream_service.dart';
import 'package:hvc_net/state/stream_state.dart';

class FakeStreamRepository extends StreamRepository {
  bool initializeCameraCalled = false;

  @override
  Future<void> initializeCamera() async {
    initializeCameraCalled = true;
  }

  @override
  void initializeSocket(String url) {}
}

class FakeForegroundStreamService extends ForegroundStreamService {
  FakeForegroundStreamService() : super(isTestMode: true);

  bool startCalled = false;
  bool stopCalled = false;

  @override
  Future<void> start() async {
    startCalled = true;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreamLiveBloc', () {
    test('auto-starts broadcasting after initialization completes', () async {
      final repository = FakeStreamRepository();
      final foregroundService = FakeForegroundStreamService();
      final bloc = StreamLiveBloc(repository, service: foregroundService);

      final states = <StreamLiveState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(InitStreamSetupEvent());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.initializeCameraCalled, isTrue);
      expect(foregroundService.startCalled, isTrue);
      expect(
        states.any((state) => state.status == StreamLiveStatus.live),
        isTrue,
      );

      await subscription.cancel();
      await bloc.close();
    });
  });
}
