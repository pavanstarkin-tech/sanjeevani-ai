import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/doctor_portal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/production_database.dart';
import '../../widgets/real_camera_qr_scanner_view.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorPatientQrScannerScreen extends StatefulWidget {
  const DoctorPatientQrScannerScreen({super.key});

  @override
  State<DoctorPatientQrScannerScreen> createState() => _DoctorPatientQrScannerScreenState();
}

class _DoctorPatientQrScannerScreenState extends State<DoctorPatientQrScannerScreen> with SingleTickerProviderStateMixin {
  final _manualIdController = TextEditingController();
  final GlobalKey<RealCameraQrScannerViewState> _cameraKey = GlobalKey<RealCameraQrScannerViewState>();
  late AnimationController _laserController;
  bool _isProcessing = false;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _handleQrScanned(String rawPayload) {
    if (_isProcessing) return;

    final clean = rawPayload.trim();
    if (clean.isEmpty) return;

    // Validate if it is a genuine Aarogyasri Health Pass
    final isAarogyasri = clean.startsWith('HEALTHEXPRESS:AAROGYASRI:') ||
                         clean.startsWith('AAROGYASRI:') ||
                         clean.startsWith('AROG-') ||
                         clean.contains('|') ||
                         (clean.startsWith('{') && clean.contains('aarogyasriId'));

    if (!isAarogyasri) {
      _showInvalidQrWarning('Unrecognized QR Code. Only HealthExpress Aarogyasri QR codes can be scanned.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _warningMessage = null;
    });

    UserModel patient;
    try {
      patient = context.read<DoctorPortalProvider>().lookupPatientByAarogyasriQR(clean);
    } catch(e) {
      patient = ProductionDatabase.findPatientByAarogyasriId(clean);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aarogyasri Health Pass Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  Text('${patient.name} (${patient.aarogyasriId})', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DoctorPatientDetailScreen(patient: patient),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _warningMessage = null;
          });
        }
      });
    });
  }

  void _showInvalidQrWarning(String reason) {
    setState(() => _warningMessage = reason);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _lookupManualId() {
    final text = _manualIdController.text.trim();
    if (text.isEmpty) {
      _showInvalidQrWarning('Please enter a valid Aarogyasri ID (e.g. AROG-TG-44910).');
      return;
    }
    _handleQrScanned(text);
  }

  @override
  void dispose() {
    _manualIdController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canPop = Navigator.of(context).canPop();

    final List<UserModel> registeredPatients = [];
    if (auth.currentUser.isNotEmpty && auth.currentUser.aarogyasriId.isNotEmpty) {
      registeredPatients.add(auth.currentUser);
    }
    for (final p in ProductionDatabase.registeredPatients) {
      if (!registeredPatients.any((e) => e.aarogyasriId.toLowerCase() == p.aarogyasriId.toLowerCase())) {
        registeredPatients.add(p);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Aarogyasri (RGIS) QR Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: () => _cameraKey.currentState?.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            tooltip: 'Toggle Flashlight',
            onPressed: () => _cameraKey.currentState?.toggleTorch(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Real-Time Patient Health Card Scanner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Point your camera at the patient\'s digital or physical Aarogyasri QR code to pull live clinical records.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 18),

              // Real Camera Optical Viewfinder
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live HTML5 Camera Video Stream
                        RealCameraQrScannerView(
                          key: _cameraKey,
                          height: 300,
                          borderRadius: BorderRadius.circular(22),
                          onQrScanned: _handleQrScanned,
                          onQrInvalid: (reason) => _showInvalidQrWarning(reason),
                        ),

                        // Corner Reticle Accents
                        const Positioned(top: 12, left: 12, child: Icon(Icons.crop_free_rounded, color: Color(0xFF10B981), size: 36)),
                        const Positioned(top: 12, right: 12, child: Icon(Icons.crop_free_rounded, color: Color(0xFF10B981), size: 36)),
                        const Positioned(bottom: 12, left: 12, child: Icon(Icons.crop_free_rounded, color: Color(0xFF10B981), size: 36)),
                        const Positioned(bottom: 12, right: 12, child: Icon(Icons.crop_free_rounded, color: Color(0xFF10B981), size: 36)),

                        // Animated Laser Scan Line
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Positioned(
                              top: 25 + (_laserController.value * 240),
                              child: Container(
                                height: 3,
                                width: 250,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.transparent, Color(0xFF34D399), Color(0xFF10B981), Colors.transparent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.9),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Processing Overlay
                        if (_isProcessing)
                          Container(
                            color: Colors.black.withValues(alpha: 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
                                SizedBox(height: 12),
                                Text(
                                  'Verifying Aarogyasri Pass...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Live Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Camera Active • Auto-Scanning',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              if (_warningMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _warningMessage!,
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Manual ID Entry Fallback Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_rounded, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Manual Aarogyasri ID Lookup',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualIdController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. AROG-TG-44910 or Phone',
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (_) => _lookupManualId(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _lookupManualId,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Registered Patients Quick-Test Bar
              if (registeredPatients.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Test Registered Patients:',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: registeredPatients.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final p = registeredPatients[index];
                      return InkWell(
                        onTap: () => _handleQrScanned(p.toAarogyasriQrPayload()),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded, size: 14, color: Color(0xFF34D399)),
                              const SizedBox(width: 6),
                              Text(
                                '${p.name.split(' ').first} (${p.aarogyasriId})',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
