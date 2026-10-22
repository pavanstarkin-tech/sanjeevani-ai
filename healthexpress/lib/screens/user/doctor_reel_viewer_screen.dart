import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../models/doctor_reel_model.dart';
import '../../models/medicine_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_reels_provider.dart';
import '../../providers/pharmacy_provider.dart';
import 'cart_checkout_screen.dart';

class DoctorReelViewerScreen extends StatefulWidget {
  final int initialIndex;

  const DoctorReelViewerScreen({super.key, this.initialIndex = 0});

  @override
  State<DoctorReelViewerScreen> createState() => _DoctorReelViewerScreenState();
}

class _DoctorReelViewerScreenState extends State<DoctorReelViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<DoctorReelsProvider>(
        builder: (context, provider, _) {
          final reels = provider.reels;
          if (reels.isEmpty) {
            return const Center(
              child: Text(
                'No reels available',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final reel = reels[index];
              final isCurrent = index == _currentIndex;
              return _ReelPlayerPage(
                reel: reel,
                isActive: isCurrent,
                onBack: () => Navigator.pop(context),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReelPlayerPage extends StatefulWidget {
  final DoctorReelModel reel;
  final bool isActive;
  final VoidCallback onBack;

  const _ReelPlayerPage({
    required this.reel,
    required this.isActive,
    required this.onBack,
  });

  @override
  State<_ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<_ReelPlayerPage> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showPlayPauseOverlay = false;
  bool _hasError = false;

  late AnimationController _likeAnimController;

  @override
  void initState() {
    super.initState();
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.8,
      upperBound: 1.25,
    );

    if (widget.isActive) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant _ReelPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (_controller == null) {
        _initVideo();
      } else {
        _controller?.play();
        setState(() => _isPlaying = true);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _initVideo() async {
    try {
      VideoPlayerController controller;

      // Priority 1: Check if running on local desktop with absolute file
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
      await controller.setVolume(_isMuted ? 0.0 : 1.0);

      if (mounted && widget.isActive) {
        await controller.play();
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video for reel ${widget.reel.id}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
      _showPlayPauseOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showPlayPauseOverlay = false);
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReelCommentsModal(reel: widget.reel),
    );
  }

  void _handleAddToCart(MedicineModel product) {
    final pharmacy = context.read<PharmacyProvider>();
    pharmacy.addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added ${product.name} to cart!',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: const Color(0xFF5EEAD4),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartCheckoutScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final taggedProduct = reel.taggedProduct;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Layer / Fallback Thumbnail
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.black,
            child: Center(
              child: _isInitialized && _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio > 0
                          ? _controller!.value.aspectRatio
                          : 9 / 16,
                      child: VideoPlayer(_controller!),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Placeholder backdrop
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueGrey.shade900,
                                Colors.black,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        if (!_hasError)
                          const CircularProgressIndicator(color: AppColors.primary)
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                reel.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ),

        // Gradient Vignette for readability
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.2, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Animated Play/Pause Feedback Icon
        if (_showPlayPauseOverlay)
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Icon(
                _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

        // Top Header Bar: Back Button, Doctor Pill, Mute & Admin Tag Button
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Doctor / Creator pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          reel.doctorHandle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Mute / Unmute
                  InkWell(
                    onTap: _toggleMute,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Vertical Interaction Action Bar (Like, Comment, Share, Save)
        Positioned(
          right: 12,
          bottom: taggedProduct != null ? 110 : 36,
          child: Column(
            children: [
              // Like Button
              _ReelActionButton(
                icon: reel.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                iconColor: reel.isLiked ? const Color(0xFFEF4444) : Colors.white,
                label: _formatCount(reel.likesCount),
                onTap: () {
                  context.read<DoctorReelsProvider>().toggleLike(reel.id);
                  _likeAnimController.forward().then((_) => _likeAnimController.reverse());
                },
              ),
              const SizedBox(height: 16),

              // Comment Button
              _ReelActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: Colors.white,
                label: _formatCount(reel.commentsCount),
                onTap: () => _showCommentsSheet(context),
              ),
              const SizedBox(height: 16),

              // Share Button
              _ReelActionButton(
                icon: Icons.share_rounded,
                iconColor: Colors.white,
                label: _formatCount(reel.sharesCount),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text('Sharing link for "${reel.title}" copied!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Bookmark / Save
              _ReelActionButton(
                icon: reel.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                iconColor: reel.isSaved ? const Color(0xFFFBBF24) : Colors.white,
                label: reel.isSaved ? 'Saved' : 'Save',
                onTap: () {
                  context.read<DoctorReelsProvider>().toggleSave(reel.id);
                },
              ),
            ],
          ),
        ),

        // Tagged Referral Product Card (Matches Reference Image 2)
        if (taggedProduct != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // Reference Image 2 deep emerald green theme
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Product Thumbnail (White container)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        taggedProduct.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF15803D),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          taggedProduct.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          taggedProduct.packSize,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${taggedProduct.price.toStringAsFixed(0)} / pack',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // + Add Button (Matches Reference Image 2 White Pill "+ Add")
                  ElevatedButton(
                    onPressed: () => _handleAddToCart(taggedProduct),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF15803D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Color(0xFF15803D)),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

/// Comments Bottom Sheet
class _ReelCommentsModal extends StatefulWidget {
  final DoctorReelModel reel;

  const _ReelCommentsModal({required this.reel});

  @override
  State<_ReelCommentsModal> createState() => _ReelCommentsModalState();
}

class _ReelCommentsModalState extends State<_ReelCommentsModal> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final author = auth.currentUser.name.isNotEmpty ? auth.currentUser.name : 'Patient User';

    context.read<DoctorReelsProvider>().addComment(widget.reel.id, author, text);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.reel.comments;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${comments.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text('No comments yet. Be the first to ask the doctor!'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              c.author.isNotEmpty ? c.author[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.author,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• Verified Patient',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.text,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Ask doctor a question...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _postComment,
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
