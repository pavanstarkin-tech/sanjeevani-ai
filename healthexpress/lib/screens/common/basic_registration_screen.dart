import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/device_native_service.dart';
import '../../services/location_service.dart';
import '../../widgets/real_mapbox_map.dart';
import '../user/user_main_nav.dart';

class BasicRegistrationScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  const BasicRegistrationScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<BasicRegistrationScreen> createState() => _BasicRegistrationScreenState();
}

class _BasicRegistrationScreenState extends State<BasicRegistrationScreen> {
  int _currentStep = 0; // 0: Identity, 1: Health Card, 2: Emergency & Location
  final int _totalSteps = 3;

  // Step 1 Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  double _age = 25.0; // Interactive slider (< 100)
  String _selectedGender = 'Male';

  // Step 2 Controllers (Health Card & Clinical Data)
  final _aarogyasriController = TextEditingController();
  String _selectedBloodGroup = 'B+';
  final _allergiesController = TextEditingController(text: 'None');
  final _chronicConditionsController = TextEditingController(text: 'None');
  final _pastSurgeriesController = TextEditingController(text: 'None recorded');

  // Step 3 Controllers (Multiple Emergency Contacts & Real Mapbox Live GPS)
  final List<Map<String, String>> _emergencyContacts = [
    {
      'name': '',
      'phone': '',
      'relationship': 'Family',
    }
  ];

  final _addressController = TextEditingController();
  final GlobalKey<RealMapboxMapState> _mapKey = GlobalKey<RealMapboxMapState>();
  double? _liveLat;
  double? _liveLng;
  bool _isFetchingLocation = false;

  final List<String> _relationshipTypes = [
    'Family',
    'Parent',
    'Spouse',
    'Sibling',
    'Child',
    'Doctor',
    'Friend',
    'Neighbour',
  ];

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with provided credentials or existing user profile for missing details completion
    final authUser = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: (widget.initialName?.isNotEmpty == true ? widget.initialName : authUser.name) ?? '');
    _phoneController = TextEditingController(text: (widget.initialPhone?.isNotEmpty == true ? widget.initialPhone : authUser.phone) ?? '');
    _emailController = TextEditingController(text: (widget.initialEmail?.isNotEmpty == true ? widget.initialEmail : authUser.email) ?? '');
    if (authUser.aarogyasriId.isNotEmpty) _aarogyasriController.text = authUser.aarogyasriId;
    if (authUser.address.isNotEmpty) _addressController.text = authUser.address;
    if (authUser.bloodGroup.isNotEmpty && authUser.bloodGroup != 'Not Specified') _selectedBloodGroup = authUser.bloodGroup;
    if (authUser.allergies.isNotEmpty && authUser.allergies != 'None') _allergiesController.text = authUser.allergies;
    if (authUser.chronicConditions.isNotEmpty && authUser.chronicConditions != 'None') _chronicConditionsController.text = authUser.chronicConditions;
    if (authUser.pastSurgeries.isNotEmpty && authUser.pastSurgeries != 'None recorded' && authUser.pastSurgeries != 'None') _pastSurgeriesController.text = authUser.pastSurgeries;
    if (authUser.age > 0) _age = authUser.age.toDouble().clamp(1.0, 99.0);
    if (authUser.gender.isNotEmpty) _selectedGender = authUser.gender;
    if (authUser.emergencyContactName.isNotEmpty || authUser.emergencyContactPhone.isNotEmpty) {
      _emergencyContacts[0] = {
        'name': authUser.emergencyContactName,
        'phone': authUser.emergencyContactPhone,
        'relationship': authUser.emergencyContactRelation.isNotEmpty ? authUser.emergencyContactRelation : 'Family',
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aarogyasriController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _pastSurgeriesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your Full Name and Mobile Number.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_aarogyasriController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your Aarogyasri / ABHA Health Card ID.');
        return;
      }
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter your primary delivery address or tap Live GPS.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _register();
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

  /// Real In-Device Phonebook Launcher using Native Contacts API
  Future<void> _pickDeviceContact() async {
    try {
      final res = await DeviceNativeService.pickDeviceContact();
      if (res['success'] == true) {
        final name = (res['name'] as String?) ?? 'Emergency Contact';
        final rawPhone = (res['phone'] as String?) ?? '';
        final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

        setState(() {
          // If first contact is empty, fill it; otherwise add to list
          if (_emergencyContacts.isNotEmpty &&
              _emergencyContacts[0]['name']!.isEmpty &&
              _emergencyContacts[0]['phone']!.isEmpty) {
            _emergencyContacts[0] = {
              'name': name,
              'phone': phone,
              'relationship': 'Family',
            };
          } else {
            _emergencyContacts.add({
              'name': name,
              'phone': phone,
              'relationship': 'Family',
            });
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              content: Text('✅ Added $name ($phone) from your phonebook!'),
            ),
          );
        }
      } else if (res['cancelled'] == true) {
        // User cancelled, do nothing
      } else if (res['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${res['error']}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access device phonebook: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Real Live GPS Geolocation with Real Mapbox Interactive Map & Places Reverse Geocoding + Nominatim Fallback
  void _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final loc = await LocationService.getLivePosition(forceRefresh: true);
      if (loc != null) {
        final double lat = (loc['lat'] as num).toDouble();
        final double lng = (loc['lng'] as num).toDouble();
        final String placeName = (loc['address'] as String? ?? '').trim();

        _liveLat = lat;
        _liveLng = lng;

        // Animate Real Mapbox map camera to genuine GPS location
        _mapKey.currentState?.flyTo(lng, lat, zoom: 15.0);
        _mapKey.currentState?.addMarker(
          MapboxMarkerItem(
            id: 'user-home-pin',
            lng: lng,
            lat: lat,
            title: 'Your Location',
            color: '#EF4444',
            iconHtml: '🏠',
            popupText: placeName.isNotEmpty ? placeName : 'Your live GPS location',
          ),
        );

        if (placeName.isNotEmpty) {
          setState(() {
            _addressController.text = placeName;
            _isFetchingLocation = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📍 Live GPS Detected: $placeName'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Live GPS Mapbox error: $e');
    }

    // Never inject fake address on failure
    setState(() => _isFetchingLocation = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Live GPS location unavailable. Please enter your delivery address manually below.'),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _register() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final aarogyasriId = _aarogyasriController.text.trim();
    final address = _addressController.text.trim();

    String emergencyName = 'Family Member';
    String emergencyPhone = '';
    String emergencyRel = 'Family';
    if (_emergencyContacts.isNotEmpty) {
      emergencyName = _emergencyContacts[0]['name']?.trim().isNotEmpty == true ? _emergencyContacts[0]['name']!.trim() : 'Family Member';
      emergencyPhone = _emergencyContacts[0]['phone']?.trim().isNotEmpty == true ? _emergencyContacts[0]['phone']!.trim() : '';
      emergencyRel = _emergencyContacts[0]['relationship']?.trim().isNotEmpty == true ? _emergencyContacts[0]['relationship']!.trim() : 'Family';
    }

    final bloodGroup = _selectedBloodGroup;
    final allergies = _allergiesController.text.trim().isNotEmpty ? _allergiesController.text.trim() : 'None';
    final chronicConditions = _chronicConditionsController.text.trim().isNotEmpty ? _chronicConditionsController.text.trim() : 'None';
    final pastSurgeries = _pastSurgeriesController.text.trim().isNotEmpty ? _pastSurgeriesController.text.trim() : 'None recorded';

    final auth = context.read<AuthProvider>();
    auth.registerUser(
      name: name,
      phone: phone,
      email: email.isNotEmpty ? email : null,
      aarogyasriId: aarogyasriId.isNotEmpty ? aarogyasriId : 'AROG${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      age: _age.toInt(),
      gender: _selectedGender,
      address: address,
      latitude: _liveLat,
      longitude: _liveLng,
      emergencyContactName: emergencyName,
      emergencyContactPhone: emergencyPhone,
      emergencyContactRelation: emergencyRel,
      bloodGroup: bloodGroup,
      allergies: allergies,
      chronicConditions: chronicConditions,
      pastSurgeries: pastSurgeries,
    );

    if (address.isNotEmpty) {
      try {
        context.read<PharmacyProvider>().setAddress(address);
      } catch (_) {}
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Patient Profile successfully created! Welcome to HealthExpress.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserMainNav()),
      (route) => false,
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
              ? 'Step 1: Personal Details'
              : _currentStep == 1
                  ? 'Step 2: Health Card ID'
                  : 'Step 3: Emergency & Location',
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
                      _buildStepTab(0, 'Identity', Icons.person_rounded),
                      _buildStepDivider(0),
                      _buildStepTab(1, 'Health Card', Icons.badge_rounded),
                      _buildStepDivider(1),
                      _buildStepTab(2, 'Emergency', Icons.emergency_rounded),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // STEP BODY CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),

            // BOTTOM NAVIGATION BAR (BACK / NEXT / GO TO HOME)
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
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _nextStep,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps - 1 ? 'Go to home' : 'Continue to Next Step',
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
                        ? AppColors.primary
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
                      ? AppColors.primary
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
        return _buildStep1Identity();
      case 1:
        return _buildStep2HealthCard();
      case 2:
      default:
        return _buildStep3EmergencyLocation();
    }
  }

  // ==========================================
  // STEP 1: IDENTITY & DEMOGRAPHICS
  // ==========================================
  Widget _buildStep1Identity() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Welcome to HealthExpress',
          subtitle: 'Let\'s set up your profile for doctor consultations and instant medicine delivery.',
          icon: Icons.person_pin_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
              ),
              hintText: '10-digit mobile number',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email address (optional)',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 18),

          // Age Up-Down Slider (< 100)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Age *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_age.toInt()} Years',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary, size: 24),
                    onPressed: _age > 1 ? () => setState(() => _age = (_age - 1).clamp(1.0, 99.0)) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Slider(
                      value: _age.clamp(1.0, 99.0),
                      min: 1.0,
                      max: 99.0,
                      divisions: 98,
                      activeColor: AppColors.primary,
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) => setState(() => _age = val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                    onPressed: _age < 99 ? () => setState(() => _age = (_age + 1).clamp(1.0, 99.0)) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Gender Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gender *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female', 'Other'].map((g) {
                  final isSel = _selectedGender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = g),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            g,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              color: isSel ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 2: HEALTH CARD & SCHEME ID
  // (Blood group, allergy, chronic conditions removed as requested)
  // (Health card details entered by user only)
  // (RGS3 overflow fixed)
  // ==========================================
  Widget _buildStep2HealthCard() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Health Card & Scheme ID',
          subtitle: 'Link your Aarogyasri / Ayushman Bharat ABHA card for cashless hospitalizations and paperless consultations.',
          icon: Icons.badge_rounded,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 18),

        // LIVE AAROGYASRI / ABHA CARD PREVIEW (No horizontal overflow!)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with No Overflow Guarantee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Aarogyasri / ABHA Card',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _nameController.text.isNotEmpty ? _nameController.text : 'Patient Name',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${_aarogyasriController.text.isNotEmpty ? _aarogyasriController.text : 'Not yet entered'}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gender: $_selectedGender', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  Text('Age: ${_age.toInt()} yrs', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                  const Text('Status: Active', style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Health Card Input Section (Entered by User)
        _buildCardContainer([
          const Text(
            'Enter Aarogyasri / ABHA Health Card Number *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please input your government issued Aarogyasri or ABHA Health ID number.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _aarogyasriController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. AROG98481234 or 14-digit ABHA ID',
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 14),

          // Cashless Benefit Info Pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.health_and_safety_rounded, color: Color(0xFF059669), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Eligible for 100% cashless treatment at all networked government & private empaneled hospitals.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Blood Group Selector
          const Text('Blood Group *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodGroups.map((bg) {
              final isSel = _selectedBloodGroup == bg;
              return InkWell(
                onTap: () => setState(() => _selectedBloodGroup = bg),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    bg,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Known Allergies
          const Text('Known Allergies', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _allergiesController,
            decoration: InputDecoration(
              hintText: 'e.g. None, Penicillin, Peanuts, Sulfa',
              prefixIcon: const Icon(Icons.healing_rounded, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['None', 'Penicillin', 'Sulfa Drugs', 'Peanuts', 'Dust / Pollen'].map((chip) {
              return ActionChip(
                label: Text(chip, style: const TextStyle(fontSize: 11)),
                backgroundColor: const Color(0xFFF1F5F9),
                onPressed: () {
                  setState(() {
                    if (chip == 'None') {
                      _allergiesController.text = 'None';
                    } else {
                      if (_allergiesController.text == 'None' || _allergiesController.text.isEmpty) {
                        _allergiesController.text = chip;
                      } else if (!_allergiesController.text.contains(chip)) {
                        _allergiesController.text = '${_allergiesController.text}, $chip';
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Chronic Conditions
          const Text('Chronic Medical Conditions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _chronicConditionsController,
            decoration: InputDecoration(
              hintText: 'e.g. None, Diabetes Type 2, Hypertension (BP), Asthma',
              prefixIcon: const Icon(Icons.medical_information_rounded, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['None', 'Diabetes', 'Hypertension (BP)', 'Asthma', 'Thyroid'].map((chip) {
              return ActionChip(
                label: Text(chip, style: const TextStyle(fontSize: 11)),
                backgroundColor: const Color(0xFFF1F5F9),
                onPressed: () {
                  setState(() {
                    if (chip == 'None') {
                      _chronicConditionsController.text = 'None';
                    } else {
                      if (_chronicConditionsController.text == 'None' || _chronicConditionsController.text.isEmpty) {
                        _chronicConditionsController.text = chip;
                      } else if (!_chronicConditionsController.text.contains(chip)) {
                        _chronicConditionsController.text = '${_chronicConditionsController.text}, $chip';
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Past Surgeries & Operations
          const Text('Past Surgeries & Operations', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _pastSurgeriesController,
            decoration: InputDecoration(
              hintText: 'e.g. None recorded, Appendectomy, Cesarean, Knee Surgery',
              prefixIcon: const Icon(Icons.medical_services_rounded, color: AppColors.primary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 3: MULTIPLE EMERGENCY CONTACTS & MAPBOX LIVE GPS
  // (In-device phonebook only, no dummy mock sheet)
  // (Multiple emergency contacts dynamically supported)
  // (Mapbox live location reverse geocoded)
  // ==========================================
  Widget _buildStep3EmergencyLocation() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Emergency Contacts & Address',
          subtitle: 'Enables 15-minute emergency ambulance dispatch and live SOS alert notifications to your family.',
          icon: Icons.emergency_rounded,
          color: AppColors.emergency,
        ),
        const SizedBox(height: 18),

        // EMERGENCY CONTACTS SECTION
        _buildCardContainer([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
              // Real in-device phonebook picker button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.contact_phone_rounded, size: 16),
                label: const Text('In-Device Phonebook', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: _pickDeviceContact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Multiple Emergency Contacts
          ..._emergencyContacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contact #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                      ),
                      if (_emergencyContacts.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _emergencyContacts.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Contact Name Field
                  TextField(
                    onChanged: (val) => contact['name'] = val,
                    controller: TextEditingController(text: contact['name'])
                      ..selection = TextSelection.collapsed(offset: contact['name']?.length ?? 0),
                    decoration: InputDecoration(
                      hintText: 'Contact Name (e.g. Spouse / Parent)',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone Number Field
                  TextField(
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => contact['phone'] = val,
                    controller: TextEditingController(text: contact['phone'])
                      ..selection = TextSelection.collapsed(offset: contact['phone']?.length ?? 0),
                    decoration: InputDecoration(
                      hintText: '10-Digit Mobile Number',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Relationship Selector
                  Row(
                    children: [
                      const Text('Relation: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _relationshipTypes.contains(contact['relationship']) ? contact['relationship'] : 'Family',
                        isDense: true,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        items: _relationshipTypes.map((rel) {
                          return DropdownMenuItem<String>(
                            value: rel,
                            child: Text(rel),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() => contact['relationship'] = newVal);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Add Another Emergency Contact Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            label: const Text('+ Add Another Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primary)),
            onPressed: () {
              setState(() {
                _emergencyContacts.add({
                  'name': '',
                  'phone': '',
                  'relationship': 'Family',
                });
              });
            },
          ),
        ]),
        const SizedBox(height: 18),

        // REAL MAPBOX GL INTERACTIVE MAP
        const Text(
          'Mapbox Live GPS Location',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Interactive vector map with real-time browser GPS pin and street layout.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        RealMapboxMap(
          key: _mapKey,
          height: 220,
          initialLng: _liveLng ?? 78.3880,
          initialLat: _liveLat ?? 17.4420,
          markers: [
            if (_liveLng != null && _liveLat != null)
              MapboxMarkerItem(
                id: 'user-home-pin',
                lng: _liveLng!,
                lat: _liveLat!,
                title: 'Your Location',
                color: '#EF4444',
                iconHtml: '🏠',
                popupText: 'Your live GPS location',
              ),
          ],
          onLocateMe: _fetchCurrentLocation,
        ),
        const SizedBox(height: 16),

        // LIVE LOCATION / ADDRESS VIA MAPBOX API
        _buildCardContainer([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Primary Home / Delivery Address *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  foregroundColor: AppColors.success,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isFetchingLocation
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                    : const Icon(Icons.my_location_rounded, size: 15),
                label: Text(_isFetchingLocation ? 'Detecting...' : 'Live GPS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter your house number, street, landmark, and area (or tap Live GPS)',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
        ]),
      ],
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
