import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_illustrations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/emergency_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/central_data_service.dart';
import '../common/address_selection_modal.dart';
import '../common/patient_detail_collection_dialog.dart';
import 'offline_ai_doctor_screen.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  bool _sosTriggered = false;
  String? _dispatchedAmbulance;
  EmergencyDispatchModel? _activeDispatch;

  @override
  void initState() {
    super.initState();
    final active = CentralDataService.instance.activeEmergency;
    if (active != null) {
      _sosTriggered = true;
      _dispatchedAmbulance = active.ambulanceProvider;
      _activeDispatch = active;
    }
  }

  void _showEditEmergencyContactDialog() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final nameCtrl = TextEditingController(text: user.emergencyContactName);
    final phoneCtrl = TextEditingController(text: user.emergencyContactPhone);
    final relCtrl = TextEditingController(text: user.emergencyContactRelation.isNotEmpty ? user.emergencyContactRelation : 'Family');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 4),
              const Text('This contact will be notified immediately in case of ambulance dispatch.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.emergency),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 9848012345',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.emergency),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relCtrl,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g. Spouse, Brother, Parent, Friend',
                  prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.emergency),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final rel = relCtrl.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and phone number.')));
                      return;
                    }

                    auth.updateEmergencyContact(name: name, phone: phone, relation: rel.isNotEmpty ? rel : 'Family');
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppColors.success, content: Text('Emergency contact saved successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergency,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _triggerSos(AmbulanceService amb) async {
    final auth = context.read<AuthProvider>();
    final pharmacyProv = context.read<PharmacyProvider>();
    final user = auth.currentUser;

    if (!auth.isProfileComplete) {
      final ok = await PatientDetailCollectionDialog.ensureDetails(
        context,
        title: 'Emergency Contact Details',
        description: 'Please verify your phone number and full name for ambulance crew and hospital casualty triage.',
      );
      if (!ok) return;
    }

    final locationStr = user.address.isNotEmpty ? user.address : pharmacyProv.selectedAddress;

    final dispatch = CentralDataService.instance.triggerEmergencySOS(
      userId: user.id.isNotEmpty ? user.id : 'USR-SOS',
      patientName: user.name.isNotEmpty ? user.name : 'Patient in Need',
      patientPhone: user.phone.isNotEmpty ? user.phone : 'Not provided',
      location: locationStr,
      ambulanceProvider: amb.providerName,
      etaMinutes: amb.etaMinutes,
    );

    setState(() {
      _sosTriggered = true;
      _dispatchedAmbulance = amb.providerName;
      _activeDispatch = dispatch;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emergency,
          duration: const Duration(seconds: 4),
          content: Text('🚨 SOS Alert Dispatched! ${amb.providerName} is en-route (ETA: ${amb.etaMinutes}) to $locationStr. Broadcasted to Hospital Trauma Ward & Emergency Contacts.'),
        ),
      );
    }
  }

  void _cancelSos() {
    if (_activeDispatch != null) {
      CentralDataService.instance.resolveEmergency(_activeDispatch!.id);
    }
    setState(() {
      _sosTriggered = false;
      _dispatchedAmbulance = null;
      _activeDispatch = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency SOS alert cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pharmacyProv = context.watch<PharmacyProvider>();
    final user = auth.currentUser;
    final userLocation = user.address.isNotEmpty ? user.address : pharmacyProv.selectedAddress;
    final hasEmergencyContact = user.emergencyContactName.isNotEmpty && user.emergencyContactPhone.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEF2F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.emergency),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Emergency Response (SOS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.emergency)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active SOS Emergency Alert Banner if Dispatched
            if (_sosTriggered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.emergency, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🚨 LIVE SOS DISPATCH ACTIVE', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('En-route: $_dispatchedAmbulance', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('Location: $userLocation', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelSos,
                      child: const Text('Cancel', style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Big 3D Emergency SOS Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergency.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Text('24/7 PRIORITY DISPATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                            const SizedBox(height: 8),
                            const Text('Medical Emergency?', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            const Text('Instant GPS ambulance dispatch in under 8 mins.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        AppIllustrations.emergencyAmbulance,
                        height: 76,
                        width: 76,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Giant SOS Trigger Button
                  GestureDetector(
                    onTap: () => _triggerSos(ProductionDatabase.ambulances[0]),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emergency_rounded, color: AppColors.emergency, size: 42),
                            const SizedBox(height: 2),
                            Text(
                              _sosTriggered ? 'ACTIVE' : 'SOS',
                              style: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _sosTriggered ? 'Ambulance is en-route to your location' : 'Tap to dispatch nearest emergency ambulance',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Offline First-Aid Instructions Banner (Works with Zero Network)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OfflineAiDoctorScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Color(0xFFEF4444), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Offline AI First-Aid Doctor',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NO INTERNET',
                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Audio-guided CPR, severe bleeding & choking Heimlich instructions.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Verified Emergency Contact Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.contact_phone_rounded, color: AppColors.emergency, size: 18),
                          SizedBox(width: 8),
                          Text('Personal Emergency Contact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      TextButton(
                        onPressed: _showEditEmergencyContactDialog,
                        child: Text(hasEmergencyContact ? 'Edit' : '+ Add', style: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  hasEmergencyContact
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFFEF2F2),
                              child: const Icon(Icons.person_outline_rounded, color: AppColors.emergency, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.emergencyContactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                  Text('${user.emergencyContactPhone} • ${user.emergencyContactRelation}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('Notified on SOS', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('No emergency contact saved. Tap "+ Add" to link a family member.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live Location / Address Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Current Emergency Address', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(userLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => AddressSelectionModal.show(context),
                    child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Nearby Ambulance Services
            const Text('Nearby Ambulance Fleet (Real-Time ETA)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Column(
              children: ProductionDatabase.ambulances.map((amb) {
                final isDispatched = _dispatchedAmbulance == amb.providerName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDispatched ? AppColors.emergency : AppColors.border, width: isDispatched ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_hospital_rounded, color: AppColors.emergency, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(amb.providerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(amb.vehicleType, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_rounded, size: 12, color: AppColors.emergency),
                                const SizedBox(width: 4),
                                Text('ETA ${amb.etaMinutes}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emergency)),
                                const SizedBox(width: 10),
                                Text('${amb.distanceKm} km away', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isDispatched ? null : () => _triggerSos(amb),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDispatched ? Colors.grey : AppColors.emergency,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isDispatched ? 'Dispatched' : 'Dispatch', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
