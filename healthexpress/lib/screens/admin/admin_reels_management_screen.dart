import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/doctor_reel_model.dart';
import '../../providers/doctor_reels_provider.dart';
import '../user/doctor_reel_viewer_screen.dart';

class AdminReelsManagementScreen extends StatefulWidget {
  const AdminReelsManagementScreen({super.key});

  @override
  State<AdminReelsManagementScreen> createState() => _AdminReelsManagementScreenState();
}

class _AdminReelsManagementScreenState extends State<AdminReelsManagementScreen> {
  String _filter = 'all'; // all, tagged, untagged
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Doctor Reels & Referral Tags',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Watch All Reels',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorReelViewerScreen(initialIndex: 0)),
              );
            },
          ),
        ],
      ),
      body: Consumer<DoctorReelsProvider>(
        builder: (context, provider, _) {
          final allReels = provider.reels;
          final taggedCount = allReels.where((r) => r.taggedProductId != null).length;
          final untaggedCount = allReels.length - taggedCount;

          final filteredReels = allReels.where((r) {
            if (_filter == 'tagged' && r.taggedProductId == null) return false;
            if (_filter == 'untagged' && r.taggedProductId != null) return false;
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              return r.title.toLowerCase().contains(q) ||
                  r.doctorName.toLowerCase().contains(q) ||
                  r.filename.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Admin Stats Overview Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          title: 'Total Reels',
                          count: allReels.length.toString(),
                          icon: Icons.video_collection_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          title: 'Tagged Products',
                          count: taggedCount.toString(),
                          icon: Icons.sell_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          title: 'No Referral',
                          count: untaggedCount.toString(),
                          icon: Icons.link_off_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search input
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by reel title, doctor, or video file...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All (${allReels.length})',
                          isSelected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'With Product ($taggedCount)',
                          isSelected: _filter == 'tagged',
                          onTap: () => setState(() => _filter = 'tagged'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'No Product ($untaggedCount)',
                          isSelected: _filter == 'untagged',
                          onTap: () => setState(() => _filter = 'untagged'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Reels List
              Expanded(
                child: filteredReels.isEmpty
                    ? const Center(child: Text('No matching reels found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredReels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final reel = filteredReels[index];
                          final actualIndex = allReels.indexOf(reel);
                          return _AdminReelItemCard(
                            reel: reel,
                            onPlay: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DoctorReelViewerScreen(initialIndex: actualIndex),
                                ),
                              );
                            },
                            onTagProduct: () => _openProductPickerModal(context, reel),
                            onRemoveTag: () {
                              provider.tagProductToReel(reel.id, null);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed referral product tag from "${reel.title}"')),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openProductPickerModal(BuildContext context, DoctorReelModel reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(reel: reel),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AdminReelItemCard extends StatelessWidget {
  final DoctorReelModel reel;
  final VoidCallback onPlay;
  final VoidCallback onTagProduct;
  final VoidCallback onRemoveTag;

  const _AdminReelItemCard({
    required this.reel,
    required this.onPlay,
    required this.onTagProduct,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final taggedProduct = reel.taggedProduct;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with Play button
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      reel.doctorAvatar,
                      width: 60,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 75,
                        color: Colors.black,
                        child: const Icon(Icons.video_camera_back_rounded, color: Colors.white54),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onPlay,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title, Doctor & File
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          reel.doctorName,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 12),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'File: ${reel.filename}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Tagged Product Row
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('Referral Product: ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              if (taggedProduct != null)
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            '${taggedProduct.name} (₹${taggedProduct.price.toStringAsFixed(0)})',
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                        tooltip: 'Untag Product',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onRemoveTag,
                      ),
                    ],
                  ),
                )
              else
                const Expanded(
                  child: Text(
                    'None (No Product Tagged)',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: onTagProduct,
                icon: Icon(taggedProduct == null ? Icons.add_rounded : Icons.edit_rounded, size: 14),
                label: Text(
                  taggedProduct == null ? 'Tag Product' : 'Change',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: taggedProduct == null ? AppColors.primary : const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final DoctorReelModel reel;

  const _ProductPickerSheet({required this.reel});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorReelsProvider>();
    final medicines = ProductionDatabase.medicines.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.genericName.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Referral Product to Tag',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Reel: ${widget.reel.title}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search medicine catalog...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              itemCount: medicines.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final med = medicines[index];
                final isSelected = widget.reel.taggedProductId == med.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      med.imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                      ),
                    ),
                  ),
                  title: Text(
                    med.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${med.genericName} • ₹${med.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      provider.tagProductToReel(widget.reel.id, med.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tagged "${med.name}" to "${widget.reel.title}"!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF10B981) : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text(isSelected ? 'Selected' : 'Select'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
