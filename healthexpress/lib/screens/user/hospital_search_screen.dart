import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/hospital_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import 'hospital_detail_screen.dart';

class HospitalSearchScreen extends StatefulWidget {
  const HospitalSearchScreen({super.key});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<HospitalModel> _hospitalsList = List.from(ProductionDatabase.hospitals);

  final List<String> _categories = ['All', 'Multi Speciality', 'Cardiac', 'Ortho', 'Neurology', 'Gynecology'];

  @override
  void initState() {
    super.initState();
    _fetchLiveHospitals();
  }

  Future<void> _fetchLiveHospitals() async {
    try {
      final loc = await LocationService.getLivePosition();
      final lat = loc?['lat'] as double? ?? 17.4420;
      final lng = loc?['lng'] as double? ?? 78.3880;
      final cityName = loc != null ? '${loc['locality']}, ${loc['city']}' : null;

      final liveHospitals = await ApiService.fetchLiveNearbyHospitals(
        latitude: lat,
        longitude: lng,
        cityName: cityName,
        limit: 35,
      );

      if (liveHospitals.isNotEmpty && mounted) {
        setState(() {
          _hospitalsList = liveHospitals;
        });
      } else {
        final remoteHospitals = await ApiService.fetchHospitals(latitude: lat, longitude: lng);
        if (remoteHospitals.isNotEmpty && mounted) {
          setState(() {
            _hospitalsList = remoteHospitals;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HospitalModel> get _filteredHospitals {
    return _hospitalsList.where((h) {
      final matchesSearch = _searchController.text.isEmpty ||
          h.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          h.location.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          h.departments.any((d) => d.toLowerCase().contains(_searchController.text.toLowerCase()));

      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Multi Speciality') ||
          h.departments.any((d) => d.toLowerCase().contains(_selectedCategory.toLowerCase()));

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nearby Hospitals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            Text('Hyderabad, Telangana', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search hospitals, specialties...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
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
              ],
            ),
          ),

          // Hospitals List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHospitals.length,
              itemBuilder: (context, index) {
                final hospital = _filteredHospitals[index];
                return _HospitalCard(hospital: hospital);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  const _HospitalCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Hospital Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                hospital.bannerUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),

            // Hospital Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hospital.location,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Text(' ${hospital.rating} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('(${hospital.reviewCount})', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text('•  ${hospital.distanceKm} km', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hospital.is24x7)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('24x7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ),
                      const SizedBox(width: 6),
                      Text('${hospital.doctorCount}+ Doctors', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
