import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_native_service.dart';

class PatientDetailCollectionDialog extends StatefulWidget {
  final String title;
  final String description;
  final UserModel? initialUser;
  final VoidCallback? onComplete;

  const PatientDetailCollectionDialog({
    super.key,
    this.title = 'Complete Your Patient Profile',
    this.description = 'Please verify your contact and clinical details for personalized doctor consultations and safe medicine delivery.',
    this.initialUser,
    this.onComplete,
  });

  static Future<bool> ensureDetails(
    BuildContext context, {
    String title = 'Complete Your Patient Profile',
    String description = 'Please verify your contact and clinical details for personalized doctor consultations and safe medicine delivery.',
  }) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    // If already onboarded or has valid phone and name
    if (auth.isOnboarded || (user.phone.isNotEmpty && user.name.isNotEmpty)) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PatientDetailCollectionDialog(
        title: title,
        description: description,
        initialUser: user,
      ),
    );

    return result ?? false;
  }

  @override
  State<PatientDetailCollectionDialog> createState() => _PatientDetailCollectionDialogState();
}

class _PatientDetailCollectionDialogState extends State<PatientDetailCollectionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicController;
  String _selectedBloodGroup = 'B+';
  String? _uploadedPhoto;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser ?? context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone == '9876543210' ? '' : user.phone);
    _allergiesController = TextEditingController(text: user.allergies == 'No known allergies' ? '' : user.allergies);
    _chronicController = TextEditingController(text: user.chronicConditions == 'None' ? '' : user.chronicConditions);
    _selectedBloodGroup = _bloodGroups.contains(user.bloodGroup) ? user.bloodGroup : 'B+';
    _uploadedPhoto = user.profilePhoto;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _allergiesController.dispose();
    _chronicController.dispose();
    super.dispose();
  }

  void _saveDetails() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient full name')),
      );
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.updatePatientDetails(
      name: name,
      phone: phone,
      profilePhoto: _uploadedPhoto,
      bloodGroup: _selectedBloodGroup,
      allergies: _allergiesController.text.trim().isNotEmpty ? _allergiesController.text.trim() : 'No known allergies',
      chronicConditions: _chronicController.text.trim().isNotEmpty ? _chronicController.text.trim() : 'None',
    );

    Navigator.of(context).pop(true);
    widget.onComplete?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Patient profile updated successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
              const Divider(height: 20),

              // Profile Picture Upload
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final res = await DeviceNativeService.capturePhoto();
                    if (res['success'] == true && res['dataUrl'] != null) {
                      setState(() {
                        _uploadedPhoto = res['dataUrl'] as String;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          color: AppColors.primaryLight,
                          image: _uploadedPhoto != null && _uploadedPhoto!.isNotEmpty
                              ? (_uploadedPhoto!.startsWith('data:image')
                                  ? DecorationImage(
                                      image: MemoryImage(base64Decode(_uploadedPhoto!.split(',').last)),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: NetworkImage(_uploadedPhoto!),
                                      fit: BoxFit.cover,
                                    ))
                              : null,
                        ),
                        child: _uploadedPhoto == null || _uploadedPhoto!.isEmpty
                            ? const Icon(Icons.person_rounded, size: 44, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Upload profile photo (Live Camera / Gallery)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Patient Full Name *',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Mobile Number
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number (for SMS & OTP) *',
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Blood Group Selector
              const Text('Blood Group *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodGroups.map((bg) {
                  final isSelected = _selectedBloodGroup == bg;
                  return ChoiceChip(
                    label: Text(bg),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) => setState(() => _selectedBloodGroup = bg),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Known Allergies
              TextField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Known Drug Allergies (Optional)',
                  hintText: 'e.g. Penicillin, Sulfa, Dust, None',
                  prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Chronic Conditions
              TextField(
                controller: _chronicController,
                decoration: InputDecoration(
                  labelText: 'Chronic Conditions (Optional)',
                  hintText: 'e.g. Diabetes Type-2, Hypertension, None',
                  prefixIcon: const Icon(Icons.medical_information_rounded, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
