import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/hospital_model.dart';
import '../../models/doctor_model.dart';
import 'book_appointment_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final HospitalModel hospital;
  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDoctorSpecialty = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DoctorModel> get _hospitalDoctors {
    var docs = ProductionDatabase.doctors.where((d) => d.hospitalId == widget.hospital.id).toList();
    if (docs.isEmpty) {
      docs = ProductionDatabase.doctors;
    }
    if (_selectedDoctorSpecialty == 'All') return docs;
    return docs.where((d) => d.specialty.toLowerCase().contains(_selectedDoctorSpecialty.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.favorite_border_rounded, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      h.bannerUrl.startsWith('http')
                          ? h.bannerUrl
                          : 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&q=80&w=800',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primary,
                          child: const Center(
                            child: Icon(Icons.local_hospital_rounded, size: 64, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.location,
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              Text(' ${h.rating} (${h.reviewCount} reviews) • ${h.distanceKm} km', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              if (h.is24x7)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('24x7 Open', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Stats Row (150+ Doctors, 25+ Specialties, 500+ Beds, 24x7 Pharmacy)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatPill(value: '${h.doctorCount}+', label: 'Doctors', icon: Icons.medical_services_outlined),
                  _StatPill(value: '${h.specialtyCount}+', label: 'Specialties', icon: Icons.local_hospital_outlined),
                  _StatPill(value: '${h.bedCount}+', label: 'Beds', icon: Icons.hotel_outlined),
                  _StatPill(value: '24x7', label: 'Pharmacy', icon: Icons.medication_outlined),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Doctors'),
                  Tab(text: 'Departments'),
                  Tab(text: 'About'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Overview
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Appointment Hero Promo Banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E60F6), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Book appointment with trusted specialists', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    const Text('Instant confirmation with digital Aarogyasri pass.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _tabController.animateTo(1),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('View Doctors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              const CircleAvatar(
                                radius: 36,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Top Specialties Grid
                        const Text('Top Specialties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: h.departments.length,
                          itemBuilder: (context, index) {
                            final dep = h.departments[index];
                            return _SpecialtyGridItem(name: dep);
                          },
                        ),
                        const SizedBox(height: 22),

                        // Facilities List
                        const Text('Key Facilities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: h.facilities.map((fac) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                                  const SizedBox(width: 6),
                                  Text(fac, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Doctors List
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Cardiology', 'Neurology', 'Orthopedics', 'General Medicine'].map((spec) {
                              final isSelected = _selectedDoctorSpecialty == spec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(spec),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _selectedDoctorSpecialty = spec);
                                  },
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _hospitalDoctors.length,
                          itemBuilder: (context, index) {
                            final doc = _hospitalDoctors[index];
                            return _HospitalDoctorCard(doctor: doc);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Tab 3: Departments
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: h.departments.length,
                    itemBuilder: (context, index) {
                      final dep = h.departments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dep, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const Text('Comprehensive diagnosis, surgery & outpatient care', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      );
                    },
                  ),

                  // Tab 4: About
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About Hospital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(h.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                        const SizedBox(height: 20),
                        const Text('Address & Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(h.address, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(h.phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.emergency_outlined, color: AppColors.emergency, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Emergency: ${h.emergencyPhone}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.emergency)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatPill({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SpecialtyGridItem extends StatelessWidget {
  final String name;
  const _SpecialtyGridItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HospitalDoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  const _HospitalDoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(doctor.photoUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(doctor.specialty, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text('${doctor.experienceYears}+ Years Exp • ${doctor.qualifications}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    Text(' ${doctor.rating} (${doctor.reviewCount})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('₹${doctor.clinicFee.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doctor)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
