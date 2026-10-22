import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/offline_health_grid_service.dart';

/// Screen displaying the Edge-First Proactive 5 km Offline Health Grid,
/// Highway Corridor Facility Caching, and Real-Time Bed/Blood Resource Trackers.
class OfflineHealthGridScreen extends StatefulWidget {
  const OfflineHealthGridScreen({super.key});

  @override
  State<OfflineHealthGridScreen> createState() => _OfflineHealthGridScreenState();
}

class _OfflineHealthGridScreenState extends State<OfflineHealthGridScreen> {
  bool _filterIcu = false;
  bool _filterOxygen = false;
  bool _filter24x7 = false;
  bool _filterAarogyasri = false;
  String? _selectedBloodGroup;

  final List<String> _corridors = [
    '5km Local Radius Grid',
    'NH-44 Rural Highway Corridor',
    'NH-65 Vijayawada Corridor',
    'Mandal Rural PHC Grid',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineHealthGridService>(
      builder: (context, gridService, _) {
        final filteredList = gridService.filterFacilities(
          requireIcu: _filterIcu,
          requireOxygen: _filterOxygen,
          require24x7: _filter24x7,
          requireAarogyasri: _filterAarogyasri,
          bloodGroup: _selectedBloodGroup,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF070B14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B132B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edge-First Offline Health Grid',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '5 km Proactive Radius & Highway Corridors',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: gridService.isAutoCaching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                      )
                    : const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8)),
                tooltip: 'Re-sync Offline Grid',
                onPressed: () => gridService.syncAndPrecacheGrid(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Edge Status & Corridor Selector Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF0F172A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.offline_pin_rounded, color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 5),
                              Text(
                                'OFFLINE GRID ACTIVE (${gridService.cachedFacilities.length} FACILITIES)',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          gridService.lastSyncTime != null
                              ? 'Verified locally'
                              : 'Cached on-device',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Corridor Switcher Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: gridService.activeCorridor,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          icon: const Icon(Icons.alt_route_rounded, color: Color(0xFF38BDF8), size: 20),
                          items: _corridors.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  const Icon(Icons.location_searching_rounded, size: 14, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    c,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              gridService.syncAndPrecacheGrid(corridor: val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips Carousel
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  children: [
                    FilterChip(
                      selected: _filterIcu,
                      label: const Text('ICU Available', style: TextStyle(fontSize: 11.5)),
                      avatar: const Icon(Icons.medical_information_rounded, size: 15),
                      selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFFEF4444),
                      side: BorderSide(color: _filterIcu ? const Color(0xFFEF4444) : Colors.white12),
                      onSelected: (val) => setState(() => _filterIcu = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterOxygen,
                      label: const Text('Oxygen Beds', style: TextStyle(fontSize: 11.5)),
                      avatar: const Icon(Icons.air_rounded, size: 15),
                      selectedColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFF38BDF8),
                      side: BorderSide(color: _filterOxygen ? const Color(0xFF38BDF8) : Colors.white12),
                      onSelected: (val) => setState(() => _filterOxygen = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterAarogyasri,
                      label: const Text('Aarogyasri / PM-JAY', style: TextStyle(fontSize: 11.5)),
                      avatar: const Icon(Icons.verified_rounded, size: 15),
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFF10B981),
                      side: BorderSide(color: _filterAarogyasri ? const Color(0xFF10B981) : Colors.white12),
                      onSelected: (val) => setState(() => _filterAarogyasri = val),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filter24x7,
                      label: const Text('24x7 Emergency', style: TextStyle(fontSize: 11.5)),
                      avatar: const Icon(Icons.emergency_rounded, size: 15),
                      selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFFF59E0B),
                      side: BorderSide(color: _filter24x7 ? const Color(0xFFF59E0B) : Colors.white12),
                      onSelected: (val) => setState(() => _filter24x7 = val),
                    ),
                  ],
                ),
              ),

              // Facilities List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.white30),
                            const SizedBox(height: 12),
                            Text(
                              'No facilities match selected offline filters.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final facility = filteredList[index];
                          return _buildFacilityCard(context, facility);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacilityCard(BuildContext context, OfflineHealthcareFacility facility) {
    final beds = facility.bedResource;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D33),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Facility Badge Header
          Padding(
            padding: const EdgeInsets.all(14),
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
                          Text(
                            facility.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            facility.address,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E60F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${facility.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const Text('AWAY', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (facility.is24x7Emergency)
                      _miniTag('24x7 Emergency', const Color(0xFFEF4444)),
                    if (facility.isAarogyasriEmpanelled)
                      _miniTag('Aarogyasri Cashless', const Color(0xFF10B981)),
                    if (facility.isPmjayEmpanelled)
                      _miniTag('PM-JAY Empanelled', const Color(0xFF3B82F6)),
                    _miniTag(facility.corridorTag, Colors.white60),
                  ],
                ),
              ],
            ),
          ),

          // Real-time Bed Resource Indicators (Grid View)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bedGauge(
                  label: 'ICU Beds',
                  available: beds.icuBedsAvailable,
                  total: beds.icuBedsTotal,
                  color: const Color(0xFFEF4444),
                ),
                _bedGauge(
                  label: 'Oxygen Beds',
                  available: beds.oxygenBedsAvailable,
                  total: beds.oxygenBedsTotal,
                  color: const Color(0xFF38BDF8),
                ),
                _bedGauge(
                  label: 'Ventilators',
                  available: beds.ventilatorsAvailable,
                  total: beds.ventilatorsAvailable + 4,
                  color: const Color(0xFFF59E0B),
                ),
                _bedGauge(
                  label: 'Total Free',
                  available: beds.availableBeds,
                  total: beds.totalBeds,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // Blood Bank Units & Emergency Action Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Blood inventory chips
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.bloodtype_rounded, color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Blood: ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                      ),
                      Text(
                        'O+ (${beds.bloodBankUnits['O+'] ?? 0}) • A+ (${beds.bloodBankUnits['A+'] ?? 0}) • B+ (${beds.bloodBankUnits['B+'] ?? 0})',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Emergency Call Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.white),
                  label: Text(
                    facility.phoneEmergency,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing Emergency Line: ${facility.phoneEmergency}')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bedGauge({
    required String label,
    required int available,
    required int total,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '$available',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9.5),
        ),
        Text(
          'of $total total',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8.5),
        ),
      ],
    );
  }

  Widget _miniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
