import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../common/address_selection_modal.dart';
import 'book_appointment_screen.dart';

class RmpDoctorBookingScreen extends StatefulWidget {
  const RmpDoctorBookingScreen({super.key});

  @override
  State<RmpDoctorBookingScreen> createState() => _RmpDoctorBookingScreenState();
}

class _RmpDoctorBookingScreenState extends State<RmpDoctorBookingScreen> {
  final Set<String> _selectedTreatments = {'Injection / Saline IV', 'Fever & Vitals Check'};
  String _selectedFilter = 'All Nearby';
  String _searchQuery = '';

  // Row 1 of Home Services
  final List<Map<String, dynamic>> _row1Services = [
    {'name': 'Injection / Saline IV', 'icon': Icons.vaccines_rounded, 'desc': 'IV drip & IM injections'},
    {'name': 'Fever & Vitals Check', 'icon': Icons.thermostat_rounded, 'desc': 'BP, Sugar, SpO2 & Temp'},
    {'name': 'Wound Dressing & Bandage', 'icon': Icons.healing_rounded, 'desc': 'Sterile post-op dressing'},
    {'name': 'Blood Sample Collection', 'icon': Icons.biotech_rounded, 'desc': 'CBC, LFT, KFT home draw'},
    {'name': 'ECG at Home', 'icon': Icons.monitor_heart_rounded, 'desc': '12-lead portable ECG'},
  ];

  // Row 2 of Home Services
  final List<Map<String, dynamic>> _row2Services = [
    {'name': 'Nebulization Therapy', 'icon': Icons.air_rounded, 'desc': 'Respiratory relief & asthma'},
    {'name': 'Catheter & Ryles Tube', 'icon': Icons.medical_services_rounded, 'desc': 'Clinical tube replacement'},
    {'name': 'Elderly Bedside Care', 'icon': Icons.elderly_rounded, 'desc': 'Bedridden patient assist'},
    {'name': 'Post-Surgery Home Care', 'icon': Icons.personal_injury_rounded, 'desc': 'Stitch removal & care'},
    {'name': 'Physiotherapy & Mobility', 'icon': Icons.accessibility_new_rounded, 'desc': 'Joint & muscle rehab'},
  ];

  final List<String> _filterTabs = [
    'All Nearby',
    'Fastest (<25 mins)',
    'Top Rated (4.8+)',
    'Under ₹350',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Get all RMP doctors & doorstep providers
    List<DoctorModel> rmpDocs = ProductionDatabase.doctors.where((d) {
      return d.isRmpDoctor || d.supportedTypes.contains(ConsultationType.homeVisitRMP);
    }).toList();

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      rmpDocs = rmpDocs.where((d) =>
        d.name.toLowerCase().contains(q) ||
        d.specialty.toLowerCase().contains(q) ||
        d.location.toLowerCase().contains(q)
      ).toList();
    }

    // Apply Filter Tabs
    if (_selectedFilter == 'Fastest (<25 mins)') {
      rmpDocs = rmpDocs.where((d) => d.distanceKm <= 2.2).toList();
    } else if (_selectedFilter == 'Top Rated (4.8+)') {
      rmpDocs = rmpDocs.where((d) => d.rating >= 4.8).toList();
    } else if (_selectedFilter == 'Under ₹350') {
      rmpDocs = rmpDocs.where((d) => d.homeVisitFee <= 350).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doorstep RMP Doctor Visit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text(
                  '400+ Verified Practitioners Online',
                  style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Location Strip
            InkWell(
              onTap: () => AddressSelectionModal.show(context),
              child: Container(
                color: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        auth.currentUser.address.isNotEmpty
                            ? 'Delivering care to: ${auth.currentUser.address}'
                            : 'Delivering care to: Live Current Location',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text('Change', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Premium Hero Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '⚡ 25-40 MINS DOORSTEP RESPONSE',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Certified RMP Doctor at Home',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Professional medical examination, injections, IV saline, and vital monitoring at your doorstep.',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    // Key Assurance Badges Row
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeroMiniBadge(icon: Icons.verified_user_rounded, text: 'Sterilized Kit'),
                        _HeroMiniBadge(icon: Icons.medication_liquid_rounded, text: 'Emergency Meds'),
                        _HeroMiniBadge(icon: Icons.receipt_long_rounded, text: 'Digital Rx'),
                        _HeroMiniBadge(icon: Icons.shield_rounded, text: 'Aarogyasri Safe'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Required Home Services (Organized into Two Smooth Scrollable Rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Select Required Services',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedTreatments.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Text('Scroll horizontally →', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ROW 1: Horizontal Scrollable Services
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _row1Services.map((service) {
                  final isSelected = _selectedTreatments.contains(service['name']);
                  return _buildServiceChip(service, isSelected);
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // ROW 2: Horizontal Scrollable Services
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _row2Services.map((service) {
                  final isSelected = _selectedTreatments.contains(service['name']);
                  return _buildServiceChip(service, isSelected);
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Search & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Search doctor or locality (e.g. Madhapur)...',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11),
                        ),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = tab),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Available Doctors List Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Doorstep Doctors (${rmpDocs.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.electric_bolt_rounded, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 2),
                      Text(
                        'Instant Booking',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Doctor Cards
            if (rmpDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No matching doorstep doctors found.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try clearing your search query or changing filters.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: rmpDocs.map((doc) => _buildDoctorCard(context, doc)).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // 6. How Doorstep Care Works (3-Step Assurance Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How Doorstep RMP Visit Works',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildProcessStep(
                      stepNumber: '1',
                      title: 'Select Service & Confirm Location',
                      subtitle: 'Choose treatment (saline, injection, dressing) and pick a nearby doctor.',
                      icon: Icons.touch_app_rounded,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: SizedBox(height: 12, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
                    ),
                    _buildProcessStep(
                      stepNumber: '2',
                      title: 'Practitioner Arrives in 25-40 Mins',
                      subtitle: 'Doctor arrives with sterilized equipment, emergency kit, and BP/sugar monitors.',
                      icon: Icons.delivery_dining_rounded,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: SizedBox(height: 12, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
                    ),
                    _buildProcessStep(
                      stepNumber: '3',
                      title: 'Diagnosis & Instant Digital Rx',
                      subtitle: 'Get complete vitals check, treatment at home, and digital prescription on app.',
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(Map<String, dynamic> service, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              if (_selectedTreatments.length > 1) {
                _selectedTreatments.remove(service['name']);
              }
            } else {
              _selectedTreatments.add(service['name']);
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6FFFA) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                service['icon'] as IconData,
                size: 16,
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F766E) : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0D9488)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doc) {
    final currentFee = doc.homeVisitFee > 0 ? doc.homeVisitFee.toInt() : 299;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookAppointmentScreen(
                  doctor: doc,
                  initialType: ConsultationType.homeVisitRMP,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Doctor Photo with Online Dot
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(
                          image: NetworkImage(doc.photoUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Doctor Credentials & Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doc.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 2),
                                Text(
                                  '${doc.rating}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.specialty} • ${doc.experienceYears}+ Yrs Exp',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${doc.distanceKm} km away',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '₹$currentFee',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFCCFBF1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroMiniBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
