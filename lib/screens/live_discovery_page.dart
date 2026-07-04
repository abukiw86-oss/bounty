// lib/presentation/live_discovery_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../infrastructure/discovery_repository.dart';
import '../bloc/discovery/discovery-bloc.dart';
import 'live_view.dart';

class LiveDiscoveryPage extends StatelessWidget {
  const LiveDiscoveryPage({super.key});

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
              'Live Feed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Dropdown menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.grey[900],
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      context.read<DiscoveryBloc>().add(RefreshFeedEvent());
                      break;
                    case 'reconnect':
                      context.read<DiscoveryBloc>().add(ReconnectFeedEvent());
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Refresh List',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reconnect',
                    child: Row(
                      children: [
                        Icon(Icons.wifi_find, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Reconnect',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: BlocBuilder<DiscoveryBloc, DiscoveryState>(
            builder: (context, state) {
              if (state.isLoading && state.activeLives.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.pink),
                      SizedBox(height: 16),
                      Text(
                        "Looking for live streams...",
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                );
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<DiscoveryBloc>().add(
                            ReconnectFeedEvent(),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state.activeLives.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<DiscoveryBloc>().add(RefreshFeedEvent());
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: Colors.pink,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.live_tv_outlined,
                                color: Colors.white24,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No users are live right now.",
                                style: TextStyle(color: Colors.white60),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DiscoveryBloc>().add(RefreshFeedEvent());
                  await Future.delayed(const Duration(seconds: 1));
                },
                color: Colors.pink,
                child: Column(
                  children: [
                    // Live count with location filter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.black,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${state.activeLives.length} Live Stream${state.activeLives.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (state.isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.pink,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Grid of live streams
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: state.activeLives.length,
                        itemBuilder: (context, index) {
                          final liveUser = state.activeLives[index];
                          return _LiveStreamCard(
                            liveUser: liveUser,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (newContext) => TikTokViewerPage(
                                    repository: context
                                        .read<DiscoveryRepository>(),
                                    streamUser: liveUser,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Live Stream Card with Location
class _LiveStreamCard extends StatelessWidget {
  final dynamic liveUser;
  final VoidCallback onTap;

  const _LiveStreamCard({required this.liveUser, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLocation = liveUser['location'] != null;
    final isSharingLocation = liveUser['isSharingLocation'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.pinkAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background
            const Positioned.fill(
              child: Icon(Icons.person, color: Colors.white24, size: 64),
            ),

            // LIVE badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    SizedBox(width: 4),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location badge (if sharing location)
            if (isSharingLocation && hasLocation)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 10),
                      SizedBox(width: 2),
                      Text(
                        "Live",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // User info at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    liveUser['username'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location info
                  if (isSharingLocation && hasLocation)
                    _buildLocationInfo(liveUser['location']),
                  // Device info
                  if (liveUser['platform'] != null)
                    Text(
                      liveUser['platform']['device'] ?? '',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(Map<String, dynamic> location) {
    final lat = location['latitude'];
    final lng = location['longitude'];

    if (lat == null || lng == null) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.green, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
