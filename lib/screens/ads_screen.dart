// lib/screens/ads_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// reuse helpers, model, and colors
import '../screens/home.dart'
    show apiUrl, mediaUrlFrom, Ad, primaryColor, secondaryColor, textColor;

class AdsScreen extends StatefulWidget {
  final List<Ad> initialAds;
  const AdsScreen({super.key, required this.initialAds});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  late List<Ad> _ads;
  final Map<int, VideoPlayerController> _controllers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ads = widget.initialAds;
    _init();
  }

  Future<void> _init() async {
    try {
      if (_ads.isEmpty) {
        final res = await http.get(apiUrl('/ads'));
        _ads =
            (jsonDecode(res.body) as List).map((j) => Ad.fromJson(j)).toList();
      }
      for (final ad in _ads) {
        if (ad.mediaType == 'video') {
          final url = mediaUrlFrom(ad.filePath);
          final c = VideoPlayerController.networkUrl(Uri.parse(url));
          await c.initialize();
          c.setLooping(true);
          _controllers[ad.id] = c;
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (mirrors your Home header styling)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child:
                          const Icon(Icons.arrow_back, color: secondaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ads',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Gradient panel like Home
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 213, 236, 221),
                      Color(0xFFF1FAF5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _ads.length,
                        itemBuilder: (_, i) {
                          final ad = _ads[i];
                          final url = mediaUrlFrom(ad.filePath);

                          Widget media;
                          if (ad.mediaType == 'video') {
                            final c = _controllers[ad.id];
                            media = SizedBox(
                              height: 260,
                              child: c != null && c.value.isInitialized
                                  ? Stack(
                                      children: [
                                        // show full video (no cropping)
                                        Center(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                              width: c.value.size.width,
                                              height: c.value.size.height,
                                              child: VideoPlayer(c),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: FloatingActionButton.small(
                                            heroTag: 'play_$i',
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            onPressed: () => setState(() =>
                                                c.value.isPlaying
                                                    ? c.pause()
                                                    : c.play()),
                                            child: Icon(c.value.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator()),
                            );
                          } else {
                            media = SizedBox(
                              height: 260,
                              child: Center(
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain, // respect image
                                  placeholder: (_, __) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            );
                          }

                          // Card that matches your Home cards
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFEFEFEF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: media,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: ad.link.isEmpty
                                            ? null
                                            : () async {
                                                final uri = Uri.parse(ad.link);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                }
                                              },
                                        icon: const Icon(
                                            Icons.open_in_new_outlined),
                                        label: const Text('Visit link'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
