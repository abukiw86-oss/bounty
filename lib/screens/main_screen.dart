// lib/presentation/tiktok_live_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/live_stream.dart';
import '../infrastructure/stream_repository.dart';
import '../state/stream_state.dart';

class TikTokLivePage extends StatelessWidget {
  const TikTokLivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const FullScreenCameraPreview(),
          const TikTokInteractionOverlay(),
        ],
      ),
    );
  }
}

class FullScreenCameraPreview extends StatelessWidget {
  const FullScreenCameraPreview({super.key});

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
          print(state.error);
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
          if (controller == null || !controller.value.isInitialized) {
            return const Center(
              child: Text(
                "Initializing Camera...",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
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
  const TikTokInteractionOverlay({super.key});

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
            // In your TikTokInteractionOverlay widget
            BlocBuilder<StreamLiveBloc, StreamLiveState>(
              builder: (context, state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (state.status == StreamLiveStatus.live) ...[
                      // Mute/Unmute button
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
                        icon: Icon(
                          state.isSharingLocation
                              ? Icons.location_on
                              : Icons.location_off,
                          color: state.isSharingLocation
                              ? Colors.green
                              : Colors.white70,
                          size: 28,
                        ),
                        onPressed: () {
                          context.read<StreamLiveBloc>().add(
                            ToggleLocationSharingEvent(),
                          );
                        },
                        tooltip: state.isSharingLocation
                            ? 'Location sharing ON'
                            : 'Location sharing OFF',
                      ),

                      // Stop broadcast button
                      IconButton(
                        icon: const Icon(
                          Icons.stop_circle,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        onPressed: () {
                          context.read<StreamLiveBloc>().add(
                            StopBroadcastEvent(),
                          );
                        },
                      ),
                    ],
                    if (state.status == StreamLiveStatus.ready) ...[
                      ElevatedButton(
                        onPressed: () {
                          context.read<StreamLiveBloc>().add(
                            StartBroadcastEvent(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Go Live',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
