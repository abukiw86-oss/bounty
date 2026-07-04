// lib/presentation/live_view.dart (or tiktok_viewer_page.dart)
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../infrastructure/discovery_repository.dart';

class TikTokViewerPage extends StatefulWidget {
  final DiscoveryRepository repository;
  final dynamic streamUser;

  const TikTokViewerPage({
    super.key,
    required this.repository,
    required this.streamUser,
  });

  @override
  State<TikTokViewerPage> createState() => _TikTokViewerPageState();
}

class _TikTokViewerPageState extends State<TikTokViewerPage> {
  Uint8List? _currentFrameBytes;
  Map<String, dynamic>? _streamerLocation;
  bool _showLocationDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    widget.repository.joinStreamAsViewer(widget.streamUser['id']);

    if (widget.streamUser['location'] != null) {
      _streamerLocation = widget.streamUser['location'];
    }

    // Handle video frames
    widget.repository.onFrameReceived = (base64String) {
      if (!mounted) return;
      try {
        setState(() {
          _currentFrameBytes = base64Decode(base64String);
        });
      } catch (e) {
        print("Error decoding video frame: $e");
      }
    };

    // Handle location updates
    widget.repository.onLocationUpdated = (location) {
      if (!mounted) return;
      setState(() {
        _streamerLocation = location;
      });
    };
  }

  void _toggleLocationDetails() {
    setState(() {
      _showLocationDetails = !_showLocationDetails;
    });
  }

  @override
  void dispose() {
    widget.repository.exitStreamViewerMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        _streamerLocation != null &&
        _streamerLocation!['latitude'] != null &&
        _streamerLocation!['longitude'] != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video display
          Positioned.fill(
            child: _currentFrameBytes != null
                ? Image.memory(
                    _currentFrameBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.pink),
                        SizedBox(height: 16),
                        Text(
                          "Connecting to stream...",
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
          ),

          // UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.streamUser['username'] ?? 'Streamer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Location row in top bar
                              if (hasLocation)
                                GestureDetector(
                                  onTap: _toggleLocationDetails,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.green,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_streamerLocation!['latitude'].toStringAsFixed(2)}, ${_streamerLocation!['longitude'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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

                  // Location detail card (shown when tapped)
                  if (_showLocationDetails && hasLocation)
                    _buildLocationDetailCard(),

                  // Bottom controls
                  Column(
                    children: [
                      // Location mini-map placeholder
                      if (hasLocation && !_showLocationDetails)
                        _buildLocationMiniBar(),

                      const SizedBox(height: 10),

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasLocation)
                            GestureDetector(
                              onTap: _toggleLocationDetails,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                            ),
                          const SizedBox(width: 20),

                          // Like button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❤️ Liked!'),
                                  duration: Duration(milliseconds: 500),
                                  backgroundColor: Colors.pink,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Location mini bar at bottom
  Widget _buildLocationMiniBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Text(
            'Live Location • ${_streamerLocation!['latitude'].toStringAsFixed(3)}, ${_streamerLocation!['longitude'].toStringAsFixed(3)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (_streamerLocation!['speed'] != null &&
              _streamerLocation!['speed'] > 0)
            Text(
              ' • ${_streamerLocation!['speed'].toStringAsFixed(1)} m/s',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // Detailed location card
  Widget _buildLocationDetailCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Streamer Location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleLocationDetails,
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coordinates
          _buildLocationRow(
            Icons.explore,
            'Latitude',
            _streamerLocation!['latitude']?.toStringAsFixed(6) ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildLocationRow(
            Icons.explore,
            'Longitude',
            _streamerLocation!['longitude']?.toStringAsFixed(6) ?? 'N/A',
          ),

          // Accuracy
          if (_streamerLocation!['accuracy'] != null) ...[
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.gps_fixed,
              'Accuracy',
              '${_streamerLocation!['accuracy'].toStringAsFixed(1)}m',
            ),
          ],

          // Altitude
          if (_streamerLocation!['altitude'] != null) ...[
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.height,
              'Altitude',
              '${_streamerLocation!['altitude'].toStringAsFixed(1)}m',
            ),
          ],

          // Speed
          if (_streamerLocation!['speed'] != null &&
              _streamerLocation!['speed'] > 0) ...[
            const SizedBox(height: 8),
            _buildLocationRow(
              Icons.speed,
              'Speed',
              '${_streamerLocation!['speed'].toStringAsFixed(1)} m/s',
            ),
          ],

          const SizedBox(height: 12),

          // Open in maps button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // You can integrate with Google Maps or Apple Maps here
                final lat = _streamerLocation!['latitude'];
                final lng = _streamerLocation!['longitude'];
                // For now, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Open maps at: $lat, $lng'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.map, size: 18),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
