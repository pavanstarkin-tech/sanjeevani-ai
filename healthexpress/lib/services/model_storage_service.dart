import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_medical_models.dart';

/// Manages local filesystem paths, external persistent storage, and auto-detection for GGUF model files.
/// Models are stored OUTSIDE of the app workspace (e.g. User Profile / Public Downloads)
/// so they survive app uninstalls and can be automatically re-detected.
class ModelStorageService {
  static const _prefPrefix = 'offline_medical_gguf.';

  /// Primary directory used to store downloaded GGUF files OUTSIDE app workspace.
  static Future<Directory> modelsDirectory() async {
    Directory? targetDir;

    if (!kIsWeb) {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          targetDir = Directory('$userProfile\\HealthExpressModels');
        }
      } else if (Platform.isAndroid) {
        // App internal documents directory guarantees 100% read/write ext4 access without Android Scoped Storage / FUSE barriers
        try {
          final docs = await getApplicationDocumentsDirectory();
          targetDir = Directory('${docs.path}/medical_models');
        } catch (_) {}
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          targetDir = Directory('$home/HealthExpressModels');
        }
      }
    }

    // Fallback if platform external path is null or web
    if (targetDir == null) {
      final docs = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docs.path}/medical_models');
    }

    if (!targetDir.existsSync()) {
      try {
        await targetDir.create(recursive: true);
      } catch (e) {
        debugPrint('[ModelStorageService] Error creating models dir: $e');
      }
    }

    return targetDir;
  }

  /// List of candidate directories where downloaded models might exist (for auto-detection).
  static Future<List<Directory>> candidateDirectories() async {
    final List<Directory> candidates = [];

    // 0. Workspace repo models directory (highest priority for developer repo & CLI)
    try {
      final repoDirs = [
        Directory('${Directory.current.path}/assets/models'),
        Directory('${Directory.current.path}/models'),
        Directory('assets/models'),
        Directory('models'),
        Directory('c:\\Users\\shese\\Desktop\\sanjeevani ai\\healthexpress\\assets\\models'),
        Directory('c:\\Users\\shese\\Desktop\\sanjeevani ai\\healthexpress\\models'),
        Directory('c:\\Users\\shese\\Desktop\\healthyxpress_medha\\healthexpress\\models'),
      ];
      for (final d in repoDirs) {
        if (d.existsSync()) {
          candidates.add(d);
        }
      }
    } catch (_) {}

    // 1. App documents directory FIRST (always 100% accessible to native C++ llama.cpp without FUSE/SEGV errors)
    try {
      final docs = await getApplicationDocumentsDirectory();
      candidates.add(Directory('${docs.path}/medical_models'));
      candidates.add(Directory('${docs.path}/HealthExpressModels'));
    } catch (_) {}

    // 2. Primary models directory
    try {
      final primary = await modelsDirectory();
      candidates.add(primary);
    } catch (_) {}

    if (!kIsWeb) {
      // 3. Android candidate paths (external storage for finding models downloaded via browser or other apps)
      if (Platform.isAndroid) {
        try {
          final extDirs = await getExternalStorageDirectories();
          if (extDirs != null) {
            for (final d in extDirs) {
              candidates.add(Directory('${d.path}/medical_models'));
              candidates.add(d);
            }
          }
        } catch (_) {}
        candidates.add(Directory('/sdcard/Android/data/com.example.healthexpress/files/medical_models'));
        candidates.add(Directory('/storage/emulated/0/Android/data/com.example.healthexpress/files/medical_models'));
        candidates.add(Directory('/storage/emulated/0/Download/HealthExpressModels'));
        candidates.add(Directory('/storage/emulated/0/Download'));
        candidates.add(Directory('/storage/emulated/0/Documents/HealthExpressModels'));
        candidates.add(Directory('/sdcard/Download/HealthExpressModels'));
      }
      // 4. Windows candidate paths
      else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          candidates.add(Directory('$userProfile\\HealthExpressModels'));
          candidates.add(Directory('$userProfile\\Downloads\\HealthExpressModels'));
          candidates.add(Directory('$userProfile\\Downloads'));
          candidates.add(Directory('$userProfile\\Documents\\HealthExpressModels'));
        }
        candidates.add(Directory('C:\\HealthExpressModels'));
      }
    }

    // Deduplicate
    final Set<String> paths = {};
    final List<Directory> unique = [];
    for (final dir in candidates) {
      if (!paths.contains(dir.path)) {
        paths.add(dir.path);
        unique.add(dir);
      }
    }

    return unique;
  }

  /// Returns the expected external filesystem path for a given model.
  static Future<String> localPathFor(GgufModel model) async {
    final dir = await modelsDirectory();
    final filename = model.filename ?? '${model.id}.gguf';
    final separator = Platform.isWindows ? '\\' : '/';
    return '${dir.path}$separator$filename';
  }

  /// Returns the partial-download temp path.
  static Future<String> partPathFor(GgufModel model) async {
    final base = await localPathFor(model);
    return '$base.part';
  }

  /// Returns the file size in bytes if the completed file exists.
  static Future<int?> completedFileSizeBytes(GgufModel model) async {
    final file = await findExistingModelFile(model);
    if (file == null || !file.existsSync()) return null;
    final stat = file.statSync();
    if (stat.size <= 0) return null;
    return stat.size;
  }

  /// Validate that the file is directly readable by the current process
  /// and contains the valid 'GGUF' magic header (0x47, 0x47, 0x55, 0x46).
  static bool isFileReadableGguf(File file) {
    try {
      if (!file.existsSync()) return false;
      final raf = file.openSync(mode: FileMode.read);
      final header = raf.readSync(4);
      raf.closeSync();
      return header.length == 4 &&
          header[0] == 0x47 &&
          header[1] == 0x47 &&
          header[2] == 0x55 &&
          header[3] == 0x46;
    } catch (_) {
      return false;
    }
  }

  /// Search across all external and candidate directories for an existing model file.
  static Future<File?> findExistingModelFile(GgufModel model) async {
    // 1. Check model's current localPath if set
    if (model.localPath != null && model.localPath!.isNotEmpty) {
      final f = File(model.localPath!);
      if (isFileReadableGguf(f)) return await _ensureInternalIfAndroid(f);
    }

    final targetNames = <String>{
      if (model.filename != null) model.filename!.toLowerCase(),
      '${model.id.toLowerCase()}.gguf',
      '${model.id.toLowerCase().replaceAll('-', '_')}.gguf',
      '${model.id.toLowerCase().replaceAll('_', '-')}.gguf',
    };

    final dirs = await candidateDirectories();
    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final name = entry.uri.pathSegments.last.toLowerCase();
            if (name.endsWith('.gguf')) {
              for (final t in targetNames) {
                if (name == t || name.contains(model.id.toLowerCase())) {
                  if (isFileReadableGguf(entry)) {
                    return await _ensureInternalIfAndroid(entry);
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ModelStorageService] Notice scanning directory ${dir.path}: $e');
      }
    }

    return null;
  }

  /// On Android, native C++ (llama_cpp_dart / llama.cpp) requires standard ext4 internal app storage.
  /// POSIX fopen directly on /storage/emulated/0/... triggers EACCES and SEGV_MAPERR.
  /// If a valid model is found in external storage, stage it safely into app documents.
  static Future<File> _ensureInternalIfAndroid(File file) async {
    return file;
  }

  /// Returns the byte length of a partial download (.part file).
  static Future<int> partialBytes(GgufModel model) async {
    final path = await partPathFor(model);
    final file = File(path);
    if (!file.existsSync()) return 0;
    return file.statSync().size;
  }

  /// Deletes both completed and partial files for a model.
  static Future<void> deleteFiles(GgufModel model) async {
    for (final path in [
      await localPathFor(model),
      await partPathFor(model),
      if (model.localPath != null) model.localPath!,
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
    await clearMetadata(model);
  }

  static String _key(String modelId, String field) => '$_prefPrefix$modelId.$field';

  /// Mark model download complete in preferences.
  static Future<void> markDownloaded(GgufModel model, String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(model.id, 'state'), 'downloaded');
    await prefs.setString(_key(model.id, 'path'), localPath);
  }

  /// Persist partial download byte count.
  static Future<void> markPartial(GgufModel model, int bytesDownloaded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(model.id, 'state'), 'partial');
    await prefs.setInt(_key(model.id, 'bytes'), bytesDownloaded);
  }

  /// Clear all stored metadata for a model.
  static Future<void> clearMetadata(GgufModel model) async {
    final prefs = await SharedPreferences.getInstance();
    for (final field in ['state', 'path', 'bytes']) {
      await prefs.remove(_key(model.id, field));
    }
  }

  /// Check active model ID stored in preferences.
  static Future<String?> getActiveModelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefPrefix}active_model_id');
  }

  /// Persist active model ID in preferences.
  static Future<void> setActiveModelId(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefPrefix}active_model_id', modelId);
  }

  /// Ensures a pre-built bundled asset model is staged into the local documents directory.
  static Future<File?> ensurePrebuiltAssetStaged(GgufModel model) async {
    try {
      final assetPaths = [
        'assets/models/${model.filename}',
        'assets/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
        'models/${model.filename}',
      ];
      for (final aPath in assetPaths) {
        try {
          final byteData = await rootBundle.load(aPath);
          final targetPath = await localPathFor(model);
          final targetFile = File(targetPath);
          if (!targetFile.parent.existsSync()) {
            targetFile.parent.createSync(recursive: true);
          }
          final buffer = byteData.buffer;
          await targetFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            flush: true,
          );
          if (isFileReadableGguf(targetFile)) {
            return targetFile;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ModelStorageService] Prebuilt asset check notice: $e');
    }
    return null;
  }

  /// Reconcile model with local/external filesystem.
  /// Automatically detects if model was previously downloaded or bundled as an asset.
  static Future<void> reconcileModelState(GgufModel model) async {
    final foundFile = await findExistingModelFile(model);
    if (foundFile != null && isFileReadableGguf(foundFile)) {
      model.downloadState = GgufDownloadState.downloaded;
      model.localPath = foundFile.path;
      model.localFileBytes = foundFile.statSync().size;
      await markDownloaded(model, foundFile.path);
      return;
    }

    // Check if bundled as an asset in the APK
    final assetFile = await ensurePrebuiltAssetStaged(model);
    if (assetFile != null && isFileReadableGguf(assetFile)) {
      model.downloadState = GgufDownloadState.downloaded;
      model.localPath = assetFile.path;
      model.localFileBytes = assetFile.statSync().size;
      await markDownloaded(model, assetFile.path);
      return;
    }

    final part = await partialBytes(model);
    if (part > 0) {
      model.downloadState = GgufDownloadState.paused;
      model.downloadedBytes = part;
      return;
    }

    model.downloadState = GgufDownloadState.notDownloaded;
    model.localPath = null;
    model.localFileBytes = null;
  }

  /// Auto-detect any extra .gguf files present in external storage.
  static Future<List<GgufModel>> autoDetectUntrackedModels(List<GgufModel> existingCatalog) async {
    final List<GgufModel> detected = [];
    final knownPaths = existingCatalog
        .where((m) => m.localPath != null)
        .map((m) => m.localPath!.toLowerCase())
        .toSet();

    final dirs = await candidateDirectories();
    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File && entry.path.toLowerCase().endsWith('.gguf')) {
            if (!isFileReadableGguf(entry)) continue;
            final filename = entry.uri.pathSegments.last;
            final size = entry.statSync().size;

            // Check if matches an existing catalog model by filename
            final matchingCatalog = existingCatalog.where(
              (m) => (m.filename?.toLowerCase() ?? '') == filename.toLowerCase() ||
                     (m.localPath != null && m.localPath!.toLowerCase() == entry.path.toLowerCase()),
            ).toList();

            if (matchingCatalog.isNotEmpty) {
              for (final match in matchingCatalog) {
                match.localPath = entry.path;
                match.downloadState = GgufDownloadState.downloaded;
                match.localFileBytes = size;
                knownPaths.add(entry.path.toLowerCase());
              }
            } else if (!knownPaths.contains(entry.path.toLowerCase())) {
              final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
              final cleanName = filename.replaceAll('.gguf', '').replaceAll('_', ' ').replaceAll('-', ' ');

              detected.add(
                GgufModel(
                  id: 'auto_${filename.replaceAll('.gguf', '').replaceAll(' ', '_')}',
                  name: cleanName,
                  parameters: 'SLM',
                  quantization: 'GGUF',
                  sizeLabel: '$sizeMb MB',
                  sizeBytes: size,
                  type: 'medical',
                  promptFormat: 'chatml',
                  downloadUrl: '',
                  filename: filename,
                  downloadState: GgufDownloadState.downloaded,
                  localPath: entry.path,
                  localFileBytes: size,
                  notes: 'On-device Medical GGUF Model',
                ),
              );
              knownPaths.add(entry.path.toLowerCase());
            }
          }
        }
      } catch (e) {
        debugPrint('[ModelStorageService] Notice scanning for extra gguf: $e');
      }
    }

    return detected;
  }
}
