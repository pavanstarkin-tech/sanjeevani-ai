import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'store_pending_approval_screen.dart';

class StoreOnboardingScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  const StoreOnboardingScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<StoreOnboardingScreen> createState() => _StoreOnboardingScreenState();
}

class _StoreOnboardingScreenState extends State<StoreOnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Pharmacy Credentials
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _licenseController = TextEditingController();
  final _gstinController = TextEditingController();
  final _pharmacistNameController = TextEditingController();
  String _selectedStoreType = 'Retail Chemist';

  // Step 2: Visual Presets & Operating Hours
  bool _is24x7 = false;
  final String _openingTime = '08:00 AM';
  final String _closingTime = '10:00 PM';
  String _selectedPresetImage = 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400';

  // Step 3: Location, Radius & Documents
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  double _deliveryRadiusKm = 3.0;
  bool _isLocating = false;
  bool _uploadedDrugLicense = false;
  bool _uploadedGst = false;

  final List<String> _storeTypes = [
    'Retail Chemist',
    '24/7 Superstore',
    'Dark Store Hub (15-min)',
    'Ayurvedic & Wellness',
  ];

  final List<Map<String, String>> _storePresets = [
    {
      'label': 'Modern Chemist',
      'url': 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Superstore Pharmacy',
      'url': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Dark Store Hub',
      'url': 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?auto=format&fit=crop&q=80&w=400'
    },
  ];

  @override
  void initState() {
    super.initState();
    String formattedName = widget.initialName ?? '';
    if (formattedName.isNotEmpty && !formattedName.toLowerCase().contains('pharmacy') && !formattedName.toLowerCase().contains('med')) {
      formattedName = '$formattedName Pharmacy';
    }
    _nameController = TextEditingController(text: formattedName);
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _pharmacistNameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _licenseController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill Pharmacy Name, Drug License Number, and Mobile Number.');
        return;
      }
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty || _areaController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter Operating Address and Delivery Area.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submitOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _detectLiveGps() async {
    setState(() => _isLocating = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _isLocating = false;
      _addressController.text = 'Plot 42, Silicon Valley Rd, Madhapur, Hyderabad';
      _areaController.text = 'Madhapur / Hitech City, Hyderabad - 500081';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Store Geotagged with Mapbox Live GPS!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitOnboarding() {
    final auth = context.read<AuthProvider>();
    auth.registerStore(
      name: _nameController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      openingTime: _openingTime,
      closingTime: _closingTime,
      is24x7: _is24x7,
      imageUrl: _selectedPresetImage,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Pharmacy Onboarding Submitted! Ready for verification.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const StorePendingApprovalScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: _prevStep,
        ),
        title: Text(
          _currentStep == 0
              ? 'Store Setup: 1/3 Credentials'
              : _currentStep == 1
                  ? 'Store Setup: 2/3 Profile & Hours'
                  : 'Store Setup: 3/3 Location & Radius',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // STEP PROGRESS INDICATOR
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStepTab(0, 'License', Icons.verified_rounded),
                      _buildStepDivider(0),
                      _buildStepTab(1, 'Hours & Photo', Icons.storefront_rounded),
                      _buildStepDivider(1),
                      _buildStepTab(2, 'Delivery Radius', Icons.near_me_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
            ),

            // BODY CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),

            // BOTTOM NAVIGATION BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: _prevStep,
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _nextStep,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps - 1 ? 'Submit Pharmacy Registration' : 'Continue to Next Step',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == _totalSteps - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab(int stepIndex, String title, IconData icon) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (stepIndex < _currentStep) setState(() => _currentStep = stepIndex);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFE2E8F0),
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                size: 14,
                color: (isActive || isDone) ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF0D9488)
                      : isDone
                          ? AppColors.success
                          : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDivider(int afterIndex) {
    final isDone = _currentStep > afterIndex;
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDone ? AppColors.success : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Credentials();
      case 1:
        return _buildStep2ProfileHours();
      case 2:
      default:
        return _buildStep3LocationRadius();
    }
  }

  // ==========================================
  // STEP 1: CREDENTIALS & STORE CATEGORY
  // ==========================================
  Widget _buildStep1Credentials() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Pharmacy License & Registration',
          subtitle: 'Verify your Drug License (Form 20/21) for 15-minute express medicine fulfillment.',
          icon: Icons.local_pharmacy_rounded,
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          const Text('Pharmacy / Medical Store Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Apollo MedPlus Pharmacy',
              prefixIcon: const Icon(Icons.store_rounded, color: Color(0xFF0D9488)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Drug License Number (Form 20 & 21) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _licenseController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. TS-HYD-PHARM-2026-9421',
              prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF0D9488)),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 14),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GSTIN (Tax ID)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _gstinController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: '36AABCS1429B1Z',
                        prefixIcon: const Icon(Icons.receipt_outlined, color: Color(0xFF0D9488), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registered Pharmacist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _pharmacistNameController,
                      decoration: InputDecoration(
                        hintText: 'K. Venkatesh, B.Pharm',
                        prefixIcon: const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF0D9488), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Text('Pharmacy Operating Category *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _storeTypes.map((type) {
              final isSel = _selectedStoreType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSel,
                selectedColor: const Color(0xFF0D9488),
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12.5,
                ),
                onSelected: (val) => setState(() => _selectedStoreType = type),
              );
            }).toList(),
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 2: PROFILE PRESETS & OPERATING HOURS
  // ==========================================
  Widget _buildStep2ProfileHours() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Storefront Photography & Hours',
          subtitle: 'Choose your storefront image and configure 24x7 emergency delivery dispatch.',
          icon: Icons.storefront_rounded,
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          const Text('Select Storefront Appearance *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: _storePresets.map((preset) {
              final isSel = _selectedPresetImage == preset['url'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPresetImage = preset['url']!),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFCCFBF1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            preset['url']!,
                            height: 65,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                            color: isSel ? const Color(0xFF0D9488) : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 24x7 Emergency Switch
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _is24x7 ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _is24x7 ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _is24x7 ? const Color(0xFF0D9488) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('24x7 Emergency Delivery Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary)),
                      Text('Enables overnight 15-minute critical emergency medicine orders.', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _is24x7,
                  activeTrackColor: const Color(0xFF0D9488),
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _is24x7 = val),
                ),
              ],
            ),
          ),
          if (!_is24x7) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Opening Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_openingTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF0D9488)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Closing Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_closingTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF0D9488)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 3: LOCATION & 15-MIN DELIVERY RADIUS
  // ==========================================
  Widget _buildStep3LocationRadius() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Store Location & Delivery Radius',
          subtitle: 'Geotag your physical store location and configure your 15-minute quick delivery zone.',
          icon: Icons.near_me_rounded,
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Physical Store Address *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCCFBF1),
                  foregroundColor: const Color(0xFF0D9488),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isLocating
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488)))
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(_isLocating ? 'Locating...' : 'Live GPS', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: _isLocating ? null : _detectLiveGps,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'e.g. Plot 42, Silicon Valley Rd, Madhapur',
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D9488)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Delivery Area / City *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _areaController,
            decoration: InputDecoration(
              hintText: 'e.g. Madhapur / Hitech City, Hyderabad',
              prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF0D9488)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 20),

          // DELIVERY RADIUS SLIDER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Coverage Radius', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_deliveryRadiusKm.round()} km Radius (15-min ETA)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488)),
                ),
              ),
            ],
          ),
          Slider(
            value: _deliveryRadiusKm,
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: const Color(0xFF0D9488),
            label: '${_deliveryRadiusKm.round()} km',
            onChanged: (val) => setState(() => _deliveryRadiusKm = val),
          ),
          const SizedBox(height: 14),

          // DOCUMENT UPLOAD SIMULATION
          const Text('Verification Documents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDocUploadCard('Drug License Form 20/21', _uploadedDrugLicense, () => setState(() => _uploadedDrugLicense = !_uploadedDrugLicense)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDocUploadCard('GST Certificate Scan', _uploadedGst, () => setState(() => _uploadedGst = !_uploadedGst)),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildDocUploadCard(String label, bool isUploaded, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUploaded ? const Color(0xFF5EEAD4) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              isUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? const Color(0xFF0D9488) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              isUploaded ? 'Attached (PDF)' : 'Tap to upload',
              style: TextStyle(fontSize: 10.5, color: isUploaded ? const Color(0xFF0D9488) : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SHARED UI HELPERS
  // ==========================================
  Widget _buildHeroBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
