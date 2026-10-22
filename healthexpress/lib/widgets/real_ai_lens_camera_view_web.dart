// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import '../core/theme/app_colors.dart';

@JS('aiLensCameraStart')
external JSPromise<JSString> _jsCameraStart(JSString containerId, JSString facingMode);

@JS('aiLensCameraCaptureFrame')
external JSString _jsCameraCaptureFrame(JSString containerId);

@JS('aiLensCameraSwitch')
external JSPromise<JSString> _jsCameraSwitch();

@JS('aiLensCameraStop')
external JSString _jsCameraStop();

typedef OnSnapshotCapturedCallback = void Function(String base64DataUri);

class RealAiLensCameraView extends StatefulWidget {
  final VoidCallback? onCameraReady;
  final Function(String error)? onCameraError;
  final Widget? overlayWidget;
  final bool preferFrontCamera;

  const RealAiLensCameraView({
    super.key,
    this.onCameraReady,
    this.onCameraError,
    this.overlayWidget,
    this.preferFrontCamera = false,
  });

  @override
  State<RealAiLensCameraView> createState() => RealAiLensCameraViewState();
}

class RealAiLensCameraViewState extends State<RealAiLensCameraView> {
  late final String _containerId;
  late final String _viewType;
  bool _isStreaming = false;
  bool _hasError = false;
  String _errorMessage = '';
  late String _facingMode;

  bool get isStreaming => _isStreaming;
  String get facingMode => _facingMode;

  @override
  void initState() {
    super.initState();
    _facingMode = widget.preferFrontCamera ? 'user' : 'environment';
    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch.toString();
    _containerId = 'ai-lens-camera-video-$uniqueSuffix';
    _viewType = 'ai-lens-camera-view-$uniqueSuffix';

    if (kIsWeb) {
      _registerPlatformView();
    }
  }

  void _registerPlatformView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final video = web.document.createElement('video') as web.HTMLVideoElement;
        video.id = _containerId;
        video.setAttribute('playsinline', 'true');
        video.setAttribute('autoplay', 'true');
        video.setAttribute('muted', 'true');
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'cover';
        video.style.borderRadius = '20px';
        video.style.backgroundColor = '#000000';

        // Kick off camera stream shortly after mounting
        Future.delayed(const Duration(milliseconds: 100), () {
          startCamera();
        });

        return video;
      },
    );
  }

  Future<void> startCamera() async {
    if (!kIsWeb) return;

    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final jsResult = await _jsCameraStart(_containerId.toJS, _facingMode.toJS).toDart;
      final resStr = jsResult.toDart;
      final parsed = jsonDecode(resStr) as Map<String, dynamic>;

      if (parsed['success'] == true) {
        if (mounted) {
          setState(() {
            _isStreaming = true;
            _hasError = false;
          });
          if (widget.onCameraReady != null) {
            widget.onCameraReady!();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isStreaming = false;
            _hasError = true;
            _errorMessage = parsed['error']?.toString() ?? 'Camera permission required';
          });
          if (widget.onCameraError != null) {
            widget.onCameraError!(_errorMessage);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<String?> captureFrame() async {
    if (!kIsWeb) return null;
    try {
      final jsResult = _jsCameraCaptureFrame(_containerId.toJS);
      final resStr = jsResult.toDart;
      final parsed = jsonDecode(resStr) as Map<String, dynamic>;
      if (parsed['success'] == true && parsed['dataUrl'] != null) {
        return parsed['dataUrl'] as String;
      }
    } catch (e) {
      debugPrint('Snapshot capture error: $e');
    }
    return null;
  }

  Future<void> switchCamera() async {
    if (!kIsWeb) return;
    try {
      final jsResult = await _jsCameraSwitch().toDart;
      final resStr = jsResult.toDart;
      final parsed = jsonDecode(resStr) as Map<String, dynamic>;
      if (parsed['success'] == true) {
        if (mounted) {
          setState(() {
            _facingMode = parsed['facingMode']?.toString() ?? (_facingMode == 'environment' ? 'user' : 'environment');
          });
        }
      }
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  void stopCamera() {
    if (!kIsWeb) return;
    try {
      _jsCameraStop();
      if (mounted) {
        setState(() => _isStreaming = false);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text('Camera available on Web platform', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Live Video Viewfinder
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: HtmlElementView(viewType: _viewType),
        ),

        // Error / Permission Notice if blocked
        if (_hasError)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Camera Access Notice',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage.isNotEmpty
                        ? _errorMessage
                        : 'Please allow camera permission in your browser or select an image from gallery.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: startCamera,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    label: const Text('Allow / Retry Camera', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Overlay Widget (Scanlines, HUD brackets, etc.)
        if (widget.overlayWidget != null) widget.overlayWidget!,
      ],
    );
  }
}
