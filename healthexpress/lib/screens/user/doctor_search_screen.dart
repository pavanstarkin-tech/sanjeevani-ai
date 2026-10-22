import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import 'doctor_detail_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  final String? initialSpecialty;
  const DoctorSearchScreen({super.key, this.initialSpecialty});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedSpecialty = 'All';
  String _selectedFilter = 'All';
  List<DoctorModel> _doctorsList = List.from(ProductionDatabase.doctors);

  final List<String> _specialties = [
    'All',
    'General Physician',
    'Cardiologist',
    'Neurologist',
    'Orthopedic Surgeon',
    'Gynecologist',
    'ENT Specialist',
    'Pediatrician',
  ];

  final List<String> _filters = ['All', 'Available Today', 'Home Visit', 'Video Consult'];

  @override
  void initState() {
    super.initState();
    if (widget.initialSpecialty != null) {
      _selectedSpecialty = widget.initialSpecialty!;
    }
    _fetchLiveDoctors();
  }

  Future<void> _fetchLiveDoctors() async {
    try {
      final loc = await LocationService.getLivePosition();
      final lat = loc?['lat'] as double?;
      final lng = loc?['lng'] as double?;
      final remoteDoctors = await ApiService.fetchDoctors(latitude: lat, longitude: lng);
      if (remoteDoctors.isNotEmpty && mounted) {
        setState(() {
          _doctorsList = remoteDoctors;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> get _filteredDoctors {
    return _doctorsList.where((doc) {
      final matchesSearch = _searchController.text.isEmpty ||
          doc.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          doc.specialty.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          doc.hospitalName.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesSpecialty = _selectedSpecialty == 'All' || doc.specialty == _selectedSpecialty;

      bool matchesFilter = true;
      if (_selectedFilter == 'Home Visit') {
        matchesFilter = doc.supportedTypes.contains(ConsultationType.homeVisitRMP);
      } else if (_selectedFilter == 'Video Consult') {
        matchesFilter = doc.supportedTypes.contains(ConsultationType.videoConsult);
      }

      return matchesSearch && matchesSpecialty && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locationLabel = auth.currentUser.address.isNotEmpty
        ? auth.currentUser.address.split(',').take(2).join(', ')
        : 'Live GPS Location';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // Search Input Box
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search doctors, clinics, hospitals...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),

                // Specialty Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _specialties.map((spec) {
                      final isSelected = _selectedSpecialty == spec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(spec),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSpecialty = spec);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary Mode Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = f);
                          },
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Doctors List View
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doc = _filteredDoctors[index];
                return _DoctorListCard(doctor: doc);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorListCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(doctor.photoUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.qualifications} • ${doctor.experienceYears}+ Yrs Exp',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospitalName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  Text(' ${doctor.rating} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('(${doctor.reviewCount})', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(width: 12),
                  Text(
                    '₹${doctor.clinicFee.toInt()}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const Text(' / visit', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
