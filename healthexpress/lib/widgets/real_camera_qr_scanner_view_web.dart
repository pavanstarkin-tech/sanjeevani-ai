// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

@JS('healthExpressQrScanner.start')
external JSPromise<JSString> _jsStartQrScanner(JSString containerId);

@JS('healthExpressQrScanner.stop')
external JSString _jsStopQrScanner();

@JS('healthExpressQrScanner.switchCamera')
external JSPromise<JSString> _jsSwitchCamera();

@JS('healthExpressQrScanner.toggleTorch')
external JSPromise<JSString> _jsToggleTorch(JSBoolean enable);

typedef OnQrScannedCallback = void Function(String qrData);
typedef OnQrInvalidCallback = void Function(String reason);
typedef OnCameraErrorCallback = void Function(String error);

class RealCameraQrScannerView extends StatefulWidget {
  final OnQrScannedCallback onQrScanned;
  final OnQrInvalidCallback? onQrInvalid;
  final OnCameraErrorCallback? onCameraError;
  final double height;
  final BorderRadius? borderRadius;

  const RealCameraQrScannerView({
    super.key,
    required this.onQrScanned,
    this.onQrInvalid,
    this.onCameraError,
    this.height = 300,
    this.borderRadius,
  });

  @override
  State<RealCameraQrScannerView> createState() => RealCameraQrScannerViewState();
}

class RealCameraQrScannerViewState extends State<RealCameraQrScannerView> {
  late final String _containerId;
  late final String _viewType;
  bool _isCameraActive = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isTorchOn = false;

  bool get isCameraActive => _isCameraActive;
  bool get isTorchOn => _isTorchOn;

  @override
  void initState() {
    super.initState();
    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch.toString();
    _containerId = 'camera-video-$uniqueSuffix';
    _viewType = 'camera-qr-view-$uniqueSuffix';

    if (kIsWeb) {
      _setupWebCallbacks();
      _registerPlatformView();
    }
  }

  void _setupWebCallbacks() {
    globalContext.setProperty(
      'onHealthExpressQrScanned'.toJS,
      ((JSAny? data) {
        if (data == null) return;
        final dartString = data.isA<JSString>() ? (data as JSString).toDart : data.toString();
        if (dartString.trim().isNotEmpty && mounted) {
          widget.onQrScanned(dartString.trim());
        }
      }).toJS,
    );

    globalContext.setProperty(
      'onHealthExpressQrInvalid'.toJS,
      ((JSAny? reason) {
        if (reason == null) return;
        final dartString = reason.isA<JSString>() ? (reason as JSString).toDart : reason.toString();
        if (mounted && widget.onQrInvalid != null) {
          widget.onQrInvalid!(dartString);
        }
      }).toJS,
    );

    globalContext.setProperty(
      'onHealthExpressQrError'.toJS,
      ((JSAny? error) {
        if (error == null) return;
        final dartString = error.isA<JSString>() ? (error as JSString).toDart : error.toString();
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = dartString;
            _isCameraActive = false;
          });
          if (widget.onCameraError != null) {
            widget.onCameraError!(dartString);
          }
        }
      }).toJS,
    );
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
        video.style.backgroundColor = '#0F172A';

        Future.delayed(const Duration(milliseconds: 150), () {
          startCamera();
        });

        return video;
      },
    );
  }

  Future<void> startCamera() async {
    if (!kIsWeb) return;
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final jsResult = await _jsStartQrScanner(_containerId.toJS).toDart;
      final parsed = jsonDecode(jsResult.toDart) as Map<String, dynamic>;
      if (parsed['success'] == true) {
        if (mounted) {
          setState(() {
            _isCameraActive = true;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = parsed['error']?.toString() ?? 'Failed to open camera';
            _isCameraActive = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isCameraActive = false;
        });
      }
    }
  }

  Future<void> switchCamera() async {
    if (!kIsWeb || !_isCameraActive) return;
    try {
      await _jsSwitchCamera().toDart;
    } catch (e) {
      debugPrint("Switch camera error: $e");
    }
  }

  Future<void> toggleTorch() async {
    if (!kIsWeb || !_isCameraActive) return;
    try {
      final newTorch = !_isTorchOn;
      final result = await _jsToggleTorch(newTorch.toJS).toDart;
      final parsed = jsonDecode(result.toDart);
      if (parsed['success'] == true) {
        setState(() => _isTorchOn = newTorch);
      }
    } catch (e) {
      debugPrint("Torch error: $e");
    }
  }

  void stopCamera() {
    if (!kIsWeb) return;
    try {
      _jsStopQrScanner();
      setState(() => _isCameraActive = false);
    } catch (e) {
      debugPrint("Stop camera error: $e");
    }
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 2),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live Video Platform View
            if (kIsWeb && !_hasError)
              HtmlElementView(viewType: _viewType)
            else if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.amber, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage.isNotEmpty ? _errorMessage : 'Camera is currently unavailable.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: startCamera,
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
          ],
        ),
      ),
    );
  }
}
