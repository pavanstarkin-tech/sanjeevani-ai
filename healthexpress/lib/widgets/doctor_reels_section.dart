import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';
import '../models/doctor_reel_model.dart';
import '../providers/doctor_reels_provider.dart';
import '../screens/user/doctor_reel_viewer_screen.dart';

class DoctorReelsSection extends StatelessWidget {
  const DoctorReelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorReelsProvider>(
      builder: (context, provider, _) {
        final reels = provider.reels;
        if (reels.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor Health Reels',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Expert short tips from top doctors & specialists',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Reel Cards Carousel with ACTUAL live video previews
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: reels.length,
                itemBuilder: (context, index) {
                  final reel = reels[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == reels.length - 1 ? 0 : 8,
                    ),
                    child: _ReelCard(
                      reel: reel,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DoctorReelViewerScreen(initialIndex: index),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReelCard extends StatefulWidget {
  final DoctorReelModel reel;
  final VoidCallback onTap;

  const _ReelCard({
    required this.reel,
    required this.onTap,
  });

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  Future<void> _initPreview() async {
    try {
      VideoPlayerController controller;
      if (!kIsWeb) {
        final f = File(widget.reel.videoPath);
        if (f.existsSync()) {
          controller = VideoPlayerController.file(f);
        } else {
          controller = VideoPlayerController.asset(widget.reel.videoAsset);
        }
      } else {
        controller = VideoPlayerController.asset(widget.reel.videoAsset);
      }

      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0); // Muted preview for smooth browsing

      if (mounted) {
        await controller.play();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading reel preview for ${widget.reel.id}: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 135,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ACTUAL Video Preview Playing in the Frame
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 9,
                    height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 16,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),

              // Gradient Overlay for text contrast & readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Top Row: Doctor pill badge on left + Play button on right (Ref Image 1)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Green Pill Doctor Badge (Ref Image 1: "venkat farms" style pill)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D), // emerald green
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          reel.doctorName.toLowerCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Circular Play Icon (Ref Image 1)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Content: Reel Title + Referral Product Pill (Ref Image 1)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      reel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Color(0xFFF87171), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${(reel.likesCount / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
