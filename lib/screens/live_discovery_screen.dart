// lib/presentation/live_discovery_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../infrastructure/discovery_repository.dart';
import '../bloc/discovery/discovery-bloc.dart';
import 'live_view.dart';

class LiveDiscoveryPage extends StatelessWidget {
  const LiveDiscoveryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => DiscoveryRepository(),
      child: BlocProvider(
        create: (context) =>
            DiscoveryBloc(context.read<DiscoveryRepository>())
              ..add(ConnectFeedEvent()),
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'TikTok Live Feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                );
              }
              if (state.activeLives.isEmpty) {
                return const Center(
                  child: Text(
                    "No users are live right now.",
                    style: TextStyle(color: Colors.white60),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: state.activeLives.length,
                itemBuilder: (context, index) {
                  final liveUser = state.activeLives[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (newContext) => TikTokViewerPage(
                            repository: context.read<DiscoveryRepository>(),
                            streamUser: liveUser,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.pinkAccent.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: Icon(
                              Icons.person,
                              color: Colors.white24,
                              size: 64,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "LIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Text(
                              liveUser['username'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
