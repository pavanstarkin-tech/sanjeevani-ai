import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/device_native_service.dart';

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
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;

  bool get isStreaming => _isInitialized;
  String get facingMode => _cameras.isNotEmpty && _selectedCameraIndex < _cameras.length
      ? (_cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front ? 'user' : 'environment')
      : 'environment';

  @override
  void initState() {
    super.initState();
    _initLiveCamera();
  }

  Future<void> _initLiveCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _isInitialized = false);
        return;
      }

      int targetIdx = 0;
      if (widget.preferFrontCamera) {
        final frontIdx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        targetIdx = frontIdx != -1 ? frontIdx : 0;
      } else {
        final backIdx = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        targetIdx = backIdx != -1 ? backIdx : 0;
      }
      _selectedCameraIndex = targetIdx;
      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[RealAiLensCameraView] Init error: $e');
      if (mounted) {
        setState(() => _isInitialized = false);
        widget.onCameraError?.call(e.toString());
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final prev = _cameraController;
    _cameraController = null;
    await prev?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isInitialized = true;
        });
        widget.onCameraReady?.call();
      }
    } catch (e) {
      debugPrint('[RealAiLensCameraView] Controller error: $e');
      if (mounted) {
        setState(() => _isInitialized = false);
        widget.onCameraError?.call(e.toString());
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> startCamera() async {
    if (!_isInitialized) {
      await _initLiveCamera();
    }
  }

  Future<String?> captureFrame() async {
    if (_isInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        return 'data:image/jpeg;base64,$b64';
      } catch (e) {
        debugPrint('[RealAiLensCameraView] takePicture error: $e');
      }
    }

    final res = await DeviceNativeService.capturePhoto(preferCamera: true);
    if (res['success'] == true && res['dataUrl'] != null) {
      return res['dataUrl'].toString();
    }
    return null;
  }

  Future<void> switchCamera() async {
    if (_cameras.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupController(_cameras[_selectedCameraIndex]);
  }

  void stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Viewport Base: Live CameraPreview when camera initialized
        if (_isInitialized && _cameraController != null && _cameraController!.value.isInitialized)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize?.height ?? 1,
                height: _cameraController!.value.previewSize?.width ?? 1,
                child: CameraPreview(_cameraController!),
              ),
            ),
          )
        else
          Container(
            color: const Color(0xFFF1F5F9),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sanjeevani AI Vision Lens',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Overlay Layer (Guides, Scanline HUD, Target box)
        if (widget.overlayWidget != null) widget.overlayWidget!,
      ],
    );
  }
}
