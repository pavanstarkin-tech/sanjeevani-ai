import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/offline_medical_models.dart';
import '../providers/offline_medical_slm_provider.dart';

/// Modal bottom sheet allowing users to view, download, switch,
/// or import on-device Medical SLM GGUF models in clean light theme.
class OfflineModelManagerSheet extends StatelessWidget {
  const OfflineModelManagerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OfflineModelManagerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineMedicalSlmProvider>(
      builder: (context, provider, _) {
        final models = provider.catalogModels;
        final activeModel = provider.activeModel;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: Column(
            children: [
              // Sheet Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'On-Device Medical SLMs',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '100% Offline • Zero Data Leaves Device',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Device RAM & CPU Info Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Engine: llama.cpp ARM64 CPU • Recommended RAM: ≥4 GB. Quantized to Q4_K_M for maximum battery efficiency.',
                        style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Models List
              Expanded(
                child: models.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: models.length,
                        itemBuilder: (context, index) {
                          final model = models[index];
                          final isActive = activeModel?.id == model.id;
                          return _buildModelCard(context, provider, model, isActive);
                        },
                      ),
              ),

              // Import Custom GGUF Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.file_open_rounded, size: 20),
                  label: const Text(
                    'Import Custom .gguf Model from Storage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                      );
                      if (result != null && result.files.single.path != null) {
                        final path = result.files.single.path!;
                        if (path.endsWith('.gguf')) {
                          final customModel = GgufModel(
                            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                            name: result.files.single.name,
                            parameters: 'Custom',
                            quantization: 'User',
                            sizeLabel: '${(result.files.single.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                            sizeBytes: result.files.single.size,
                            type: 'custom',
                            promptFormat: 'chatml',
                            downloadState: GgufDownloadState.downloaded,
                            localPath: path,
                            localFileBytes: result.files.single.size,
                          );
                          await provider.loadModelIntoEngine(customModel);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Loaded custom model: ${result.files.single.name}')),
                            );
                            Navigator.pop(context);
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a valid .gguf model file.')),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint('File picker error: $e');
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelCard(BuildContext context, OfflineMedicalSlmProvider provider, GgufModel model, bool isActive) {
    final isDownloading = model.downloadState == GgufDownloadState.downloading;
    final isDownloaded = model.isOnDisk;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            model.name,
                            style: TextStyle(
                              color: isActive ? AppColors.primary : AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${model.parameters} • ${model.quantization} • ${model.sizeLabel}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Button
              if (isDownloaded)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? const Color(0xFF059669) : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => provider.loadModelIntoEngine(model),
                  child: Text(
                    isActive ? 'Loaded' : 'Select',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              else if (isDownloading)
                IconButton(
                  icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.amber, size: 28),
                  onPressed: () => provider.downloadService.pause(model.id),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Download',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: model.canDownload ? () => provider.downloadModel(model) : null,
                ),
            ],
          ),

          // Download Progress bar
          if (isDownloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: model.downloadFraction,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    model.downloadProgressLabel,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${model.speedLabel ?? ''} • ETA: ${model.etaLabel ?? 'calc...'}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          if (model.notes != null) ...[
            const SizedBox(height: 6),
            Text(
              model.notes!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
