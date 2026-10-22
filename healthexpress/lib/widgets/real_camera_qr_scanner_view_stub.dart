import 'package:flutter/material.dart';

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
  bool get isCameraActive => false;
  bool get isTorchOn => false;

  Future<void> startCamera() async {}
  Future<void> switchCamera() async {}
  Future<void> toggleTorch() async {}
  void stopCamera() {}

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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Color(0xFF10B981)),
            const SizedBox(height: 12),
            const Text(
              'Live Scanner Ready',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                widget.onQrScanned('HX-DEMO-APPOINTMENT-101');
              },
              child: const Text('Simulate Scan Token'),
            ),
          ],
        ),
      ),
    );
  }
}
