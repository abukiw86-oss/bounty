// lib/presentation/tiktok_viewer_page.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../infrastructure/discovery_repository.dart';

class TikTokViewerPage extends StatefulWidget {
  final DiscoveryRepository repository;
  final dynamic streamUser;

  const TikTokViewerPage({
    Key? key,
    required this.repository,
    required this.streamUser,
  }) : super(key: key);

  @override
  State<TikTokViewerPage> createState() => _TikTokViewerPageState();
}

class _TikTokViewerPageState extends State<TikTokViewerPage> {
  Uint8List? _currentFrameBytes;
  @override
  void initState() {
    initialize();
  }

  @override
  void initialize() {
    super.initState();
    widget.repository.joinStreamAsViewer(widget.streamUser['id']);

    widget.repository.onFrameReceived = (base64String) {
      if (!mounted) return;
      setState(() {
        _currentFrameBytes = base64Decode(base64String);
      });
    };
  }

  @override
  void dispose() {
    widget.repository.exitStreamViewerMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Render Live Base64 Matrix Frame Playback Engine
          Positioned.fill(
            child: _currentFrameBytes != null
                ? Image.memory(
                    _currentFrameBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : const Center(
                    child: Text(
                      "Waiting for incoming frames...",
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
          ),

          // Exit and Overlay Controls Canvas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white30,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.streamUser['username'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Text(
                    "❤️ Double Tap to Like",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
