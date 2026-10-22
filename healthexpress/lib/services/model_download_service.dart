import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/offline_medical_models.dart';
import 'model_storage_service.dart';

/// Manages chunked HTTP downloads for GGUF model files with resume support.
class ModelDownloadService extends ChangeNotifier {
  final Map<String, http.Client> _clients = {};
  final Map<String, bool> _cancelled = {};
  final Map<String, bool> _paused = {};

  bool isDownloading(String modelId) => _clients.containsKey(modelId);

  /// Start or resume downloading [model].
  Future<void> start({
    required GgufModel model,
    required void Function(GgufModel updated) onProgress,
    required void Function(GgufModel updated, String localPath) onComplete,
    required void Function(GgufModel updated, String error) onError,
  }) async {
    if (isDownloading(model.id)) return;
    if (model.downloadUrl == null || model.downloadUrl!.isEmpty) {
      onError(model, 'No direct download URL provided for this model.');
      return;
    }

    _cancelled[model.id] = false;
    _paused[model.id] = false;
    final client = http.Client();
    _clients[model.id] = client;

    final partPath = await ModelStorageService.partPathFor(model);
    final finalPath = await ModelStorageService.localPathFor(model);
    final partFile = File(partPath);

    int resumeFrom = 0;
    if (partFile.existsSync()) {
      resumeFrom = partFile.statSync().size;
    }

    try {
      final uri = Uri.parse(model.downloadUrl!);
      final request = http.Request('GET', uri);

      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
      }

      final response = await client.send(request);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('HTTP ${response.statusCode}: Access restricted. Requires authentication.');
      }
      if (response.statusCode == 404) {
        throw Exception('HTTP 404: File not found on model server.');
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}: Download request failed.');
      }

      final bool supportsRange = response.statusCode == 206;
      if (!supportsRange) resumeFrom = 0;

      final contentLength = response.contentLength;
      final totalBytes = contentLength != null
          ? contentLength + resumeFrom
          : (model.contentLength ?? model.sizeBytes);

      model.contentLength = totalBytes;
      model.downloadState = GgufDownloadState.downloading;
      model.downloadedBytes = resumeFrom;

      final sink = partFile.openWrite(
        mode: (resumeFrom > 0 && supportsRange) ? FileMode.append : FileMode.write,
      );

      int received = resumeFrom;
      final sw = Stopwatch()..start();
      int lastSpeedBytes = resumeFrom;
      int lastSpeedMs = 0;

      await for (final chunk in response.stream) {
        if (_cancelled[model.id] == true) {
          await sink.flush();
          await sink.close();
          _cleanup(model.id);
          await ModelStorageService.deleteFiles(model);
          model.downloadState = GgufDownloadState.notDownloaded;
          model.downloadedBytes = 0;
          onProgress(model);
          return;
        }

        if (_paused[model.id] == true) {
          await sink.flush();
          await sink.close();
          _cleanup(model.id);
          await ModelStorageService.markPartial(model, received);
          model.downloadState = GgufDownloadState.paused;
          model.downloadedBytes = received;
          onProgress(model);
          return;
        }

        sink.add(chunk);
        received += chunk.length;

        final elapsedMs = sw.elapsedMilliseconds;
        if (elapsedMs - lastSpeedMs >= 500) {
          final bytesDelta = received - lastSpeedBytes;
          final timeDeltaSec = (elapsedMs - lastSpeedMs) / 1000.0;
          if (timeDeltaSec > 0) {
            model.speedBytesPerSec = bytesDelta / timeDeltaSec;
            final remainingBytes = totalBytes - received;
            if (model.speedBytesPerSec! > 0 && remainingBytes > 0) {
              model.etaSeconds = remainingBytes / model.speedBytesPerSec!;
            }
          }
          lastSpeedBytes = received;
          lastSpeedMs = elapsedMs;

          model.downloadedBytes = received;
          onProgress(model);
        }
      }

      await sink.flush();
      await sink.close();
      _cleanup(model.id);

      // Rename .part to final .gguf
      if (partFile.existsSync()) {
        await partFile.rename(finalPath);
      }

      final finalFile = File(finalPath);
      final finalBytes = finalFile.existsSync() ? finalFile.statSync().size : received;

      model.downloadState = GgufDownloadState.downloaded;
      model.downloadedBytes = finalBytes;
      model.localPath = finalPath;
      model.localFileBytes = finalBytes;
      model.speedBytesPerSec = null;
      model.etaSeconds = null;

      await ModelStorageService.markDownloaded(model, finalPath);
      onComplete(model, finalPath);
      notifyListeners();
    } catch (e) {
      _cleanup(model.id);
      model.downloadState = GgufDownloadState.failed;
      model.errorMessage = e.toString();
      onError(model, e.toString());
      notifyListeners();
    }
  }

  void pause(String modelId) {
    if (_clients.containsKey(modelId)) {
      _paused[modelId] = true;
    }
  }

  void cancel(String modelId) {
    if (_clients.containsKey(modelId)) {
      _cancelled[modelId] = true;
    }
  }

  void _cleanup(String modelId) {
    _clients[modelId]?.close();
    _clients.remove(modelId);
    _cancelled.remove(modelId);
    _paused.remove(modelId);
  }
}
