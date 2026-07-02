// lib/presentation/tiktok_live_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../infrastructure/stream_repository.dart';
import '../bloc/live_stream.dart';
import 'package:hvc_net/state/stream_state.dart';

class TikTokLivePage extends StatelessWidget {
  const TikTokLivePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => StreamRepository(),
      child: BlocProvider(
        create: (context) =>
            StreamLiveBloc(context.read<StreamRepository>())
              ..add(InitStreamSetupEvent()),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const FullScreenCameraPreview(),
              const TikTokInteractionOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenCameraPreview extends StatelessWidget {
  const FullScreenCameraPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreamLiveBloc, StreamLiveState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        if (state.status == StreamLiveStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }
        if (state.status == StreamLiveStatus.error) {
          return Center(
            child: Text(
              "Hardware Error: ${state.error}",
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (state.status == StreamLiveStatus.live ||
            state.status == StreamLiveStatus.ready) {
          final controller = context.read<StreamRepository>().controller;
          if (controller == null) return const SizedBox();

          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          );
        }
        return const Center(
          child: Text(
            "Initializing Camera Matrix...",
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}

class TikTokInteractionOverlay extends StatelessWidget {
  const TikTokInteractionOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Text("🔥"),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Abuki Dev",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Broadcasting Live",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BlocSelector<StreamLiveBloc, StreamLiveState, int>(
                    selector: (state) => state.viewerCount,
                    builder: (context, viewerCount) => Text(
                      "👁️ $viewerCount",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            BlocBuilder<StreamLiveBloc, StreamLiveState>(
              builder: (context, state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (state.status == StreamLiveStatus.ready)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => context.read<StreamLiveBloc>().add(
                          StartBroadcastEvent(),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Text(
                            "GO LIVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (state.status == StreamLiveStatus.live) ...[
                      IconButton(
                        icon: Icon(
                          state.isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.read<StreamLiveBloc>().add(
                          ToggleMuteEvent(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.stop_circle,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        onPressed: () => context.read<StreamLiveBloc>().add(
                          StopBroadcastEvent(),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
