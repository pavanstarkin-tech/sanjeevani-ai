import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../data/production_database.dart';
import 'doctor_main_nav.dart';

class DoctorOnboardingScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  const DoctorOnboardingScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Professional Identity
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _regNumController = TextEditingController();
  String _selectedSpecialty = 'Cardiologist';
  final Set<String> _selectedQualifications = {'MBBS'};

  // Step 2: Practice & Affiliation
  String _selectedHospitalId = 'HOSP-01'; // Default: KIMS Hospitals
  bool _isIndependent = false;
  double _experienceYears = 5;
  final _locationController = TextEditingController();

  // Step 3: Consultation Fees & Modes
  double _clinicFee = 500;
  double _videoFee = 400;
  double _homeVisitFee = 800;
  bool _enableClinic = true;
  bool _enableVideo = true;
  bool _enableHomeVisit = true;

  final List<Map<String, dynamic>> _specialtiesList = [
    {'name': 'Cardiologist', 'icon': Icons.favorite_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Neurologist', 'icon': Icons.psychology_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Orthopedic', 'icon': Icons.accessibility_new_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Gynecologist', 'icon': Icons.pregnant_woman_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'General Physician', 'icon': Icons.medical_services_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Pediatrician', 'icon': Icons.child_care_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'ENT Specialist', 'icon': Icons.hearing_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Dermatologist', 'icon': Icons.face_retouching_natural_rounded, 'color': Color(0xFFF97316)},
    {'name': 'RMP Doctor (Home Visit)', 'icon': Icons.home_repair_service_rounded, 'color': Color(0xFF14B8A6)},
  ];

  final List<String> _commonQualifications = [
    'MBBS',
    'MD (Medicine)',
    'MD (Cardiology)',
    'MS (Surgery)',
    'DM (Super Specialty)',
    'DNB',
    'FRCS (UK)',
    'RMP License',
  ];

  @override
  void initState() {
    super.initState();
    String formattedName = widget.initialName ?? '';
    if (!formattedName.startsWith('Dr.') && formattedName.isNotEmpty) {
      formattedName = 'Dr. $formattedName';
    }
    _nameController = TextEditingController(text: formattedName);
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _regNumController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _regNumController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill Doctor Name, Phone, and Medical License Number.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
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

  void _completeOnboarding() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final hospitalName = _isIndependent
        ? 'Independent Practice'
        : ProductionDatabase.hospitals.firstWhere((h) => h.id == _selectedHospitalId).name;

    final auth = context.read<AuthProvider>();
    auth.registerDoctor(
      name: name,
      phone: phone,
      email: _emailController.text.trim(),
      specialty: _selectedSpecialty,
      qualifications: _selectedQualifications.join(', '),
      hospitalId: _isIndependent ? 'INDEP-01' : _selectedHospitalId,
      hospitalName: hospitalName,
      clinicFee: _clinicFee,
      regNumber: _regNumController.text.trim(),
      experienceYears: _experienceYears.round(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Doctor Profile & Telehealth Practice Setup Complete!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DoctorMainNav()),
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
              ? 'Doctor Setup: 1/3 Identity'
              : _currentStep == 1
                  ? 'Doctor Setup: 2/3 Practice'
                  : 'Doctor Setup: 3/3 Consultation Fees',
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
                      _buildStepTab(0, 'Credentials', Icons.verified_user_rounded),
                      _buildStepDivider(0),
                      _buildStepTab(1, 'Affiliation', Icons.local_hospital_rounded),
                      _buildStepDivider(1),
                      _buildStepTab(2, 'Fees & Modes', Icons.payments_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
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
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _nextStep,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps - 1 ? 'Activate Doctor Practice' : 'Continue to Next Step',
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
                        ? const Color(0xFF059669)
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
                      ? const Color(0xFF059669)
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
        return _buildStep2Affiliation();
      case 2:
      default:
        return _buildStep3FeesModes();
    }
  }

  // ==========================================
  // STEP 1: CREDENTIALS & SPECIALTY
  // ==========================================
  Widget _buildStep1Identity() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Doctor Verification & Specialty',
          subtitle: 'Verify your Medical Council registration for instant digital prescription authorization.',
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          const Text('Doctor Full Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Dr. Sandeep Attawar',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF059669)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Medical Registration License Number (MCI / NMC) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _regNumController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. MCI-TS-2012-88421',
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF059669)),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                    SizedBox(width: 4),
                    Text('Valid', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Mobile Number (Full-width row)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '9848011223',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF059669), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Address (Full-width row)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'dr.sandeep@healthexpress.ai',
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Text('Primary Clinical Specialty *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialtiesList.map((spec) {
              final isSel = _selectedSpecialty == spec['name'];
              final Color itemColor = spec['color'] as Color;
              return ChoiceChip(
                avatar: Icon(spec['icon'] as IconData, size: 16, color: isSel ? Colors.white : itemColor),
                label: Text(spec['name'] as String),
                selected: isSel,
                selectedColor: const Color(0xFF059669),
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12.5,
                ),
                onSelected: (val) => setState(() => _selectedSpecialty = spec['name'] as String),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          const Text('Medical Degrees & Qualifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonQualifications.map((deg) {
              final isSel = _selectedQualifications.contains(deg);
              return FilterChip(
                label: Text(deg),
                selected: isSel,
                selectedColor: const Color(0xFFD1FAE5),
                checkmarkColor: const Color(0xFF059669),
                labelStyle: TextStyle(
                  color: isSel ? const Color(0xFF059669) : AppColors.textPrimary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedQualifications.add(deg);
                    } else {
                      _selectedQualifications.remove(deg);
                      if (_selectedQualifications.isEmpty) {
                        _selectedQualifications.add('MBBS');
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 2: HOSPITAL AFFILIATION & EXPERIENCE
  // ==========================================
  Widget _buildStep2Affiliation() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Hospital & Practice Location',
          subtitle: 'Link your active hospital OPD hours or establish an independent telehealth clinic.',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Independent Private Clinic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
              Switch(
                value: _isIndependent,
                activeTrackColor: const Color(0xFF059669),
                activeThumbColor: Colors.white,
                onChanged: (val) => setState(() => _isIndependent = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isIndependent
                ? 'You are practicing as an Independent Specialist. Patients book appointments directly with your clinic.'
                : 'Choose your affiliated multi-specialty hospital in Hyderabad for coordinated inpatient admissions and diagnostics.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          if (!_isIndependent) ...[
            const SizedBox(height: 16),
            const Text('Select Affiliated Hospital *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Column(
              children: ProductionDatabase.hospitals.take(4).map((hosp) {
                final isSel = _selectedHospitalId == hosp.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedHospitalId = hosp.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFECFDF5) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            hosp.logoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF059669)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hosp.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hosp.location,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clinical Experience', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_experienceYears.round()} Years Experience',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          Slider(
            value: _experienceYears,
            min: 1,
            max: 40,
            divisions: 39,
            activeColor: const Color(0xFF059669),
            label: '${_experienceYears.round()} yrs',
            onChanged: (val) => setState(() => _experienceYears = val),
          ),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 3: CONSULTATION FEES & TELEHEALTH
  // ==========================================
  Widget _buildStep3FeesModes() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(
          title: 'Consultation Fees & Availability',
          subtitle: 'Set your patient consultation charges and activate instant telehealth / home visit booking.',
          icon: Icons.payments_rounded,
          color: const Color(0xFF059669),
        ),
        const SizedBox(height: 18),

        _buildCardContainer([
          // In-Clinic Consultation
          _buildFeeSliderCard(
            title: 'In-Clinic OPD Consultation',
            icon: Icons.apartment_rounded,
            fee: _clinicFee,
            minFee: 200,
            maxFee: 2500,
            step: 50,
            enabled: _enableClinic,
            onToggle: (v) => setState(() => _enableClinic = v),
            onChanged: (v) => setState(() => _clinicFee = v),
          ),
          const SizedBox(height: 14),

          // Video Tele-Consultation
          _buildFeeSliderCard(
            title: 'HD Video Consultation (Telehealth)',
            icon: Icons.videocam_rounded,
            fee: _videoFee,
            minFee: 200,
            maxFee: 2000,
            step: 50,
            enabled: _enableVideo,
            onToggle: (v) => setState(() => _enableVideo = v),
            onChanged: (v) => setState(() => _videoFee = v),
          ),
          const SizedBox(height: 14),

          // Emergency Home Visit
          _buildFeeSliderCard(
            title: 'Emergency Home Visit Consultation',
            icon: Icons.home_work_rounded,
            fee: _homeVisitFee,
            minFee: 500,
            maxFee: 4000,
            step: 100,
            enabled: _enableHomeVisit,
            onToggle: (v) => setState(() => _enableHomeVisit = v),
            onChanged: (v) => setState(() => _homeVisitFee = v),
          ),
          const SizedBox(height: 18),

          // LIVE DIGITAL PRESCRIPTION PAD PREVIEW
          Container(
            padding: const EdgeInsets.all(14),
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
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 6),
                        const Text('Digital Rx Signature Pad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      ],
                    ),
                    const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 16),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Dr. Sandeep Attawar',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                ),
                Text(
                  '${_selectedQualifications.join(', ')} • $_selectedSpecialty',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                Text(
                  'Reg No: ${_regNumController.text}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildFeeSliderCard({
    required String title,
    required IconData icon,
    required double fee,
    required double minFee,
    required double maxFee,
    required double step,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: enabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: enabled ? const Color(0xFF059669) : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: enabled ? AppColors.textPrimary : Colors.grey,
                  ),
                ),
              ),
              Checkbox(
                value: enabled,
                activeColor: const Color(0xFF059669),
                onChanged: (v) => onToggle(v ?? false),
              ),
            ],
          ),
          if (enabled) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fee per session:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '₹${fee.round()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ],
            ),
            Slider(
              value: fee,
              min: minFee,
              max: maxFee,
              divisions: ((maxFee - minFee) / step).round(),
              activeColor: const Color(0xFF059669),
              onChanged: onChanged,
            ),
          ],
        ],
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
