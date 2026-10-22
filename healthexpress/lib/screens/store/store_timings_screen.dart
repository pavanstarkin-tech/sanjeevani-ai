import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class StoreTimingsScreen extends StatefulWidget {
  const StoreTimingsScreen({super.key});

  @override
  State<StoreTimingsScreen> createState() => _StoreTimingsScreenState();
}

class _StoreTimingsScreenState extends State<StoreTimingsScreen> {
  late TextEditingController _openingTimeCtrl;
  late TextEditingController _closingTimeCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _areaCtrl;
  late bool _is24x7;

  @override
  void initState() {
    super.initState();
    final store = context.read<AuthProvider>().currentStore;
    _openingTimeCtrl = TextEditingController(text: store.openingTime);
    _closingTimeCtrl = TextEditingController(text: store.closingTime);
    _phoneCtrl = TextEditingController(text: store.phone);
    _emailCtrl = TextEditingController(text: store.email ?? 'store@pharmacy.com');
    _addressCtrl = TextEditingController(text: store.address);
    _areaCtrl = TextEditingController(text: store.area);
    _is24x7 = store.is24x7;
  }

  @override
  void dispose() {
    _openingTimeCtrl.dispose();
    _closingTimeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final auth = context.read<AuthProvider>();
    auth.updateStoreTimings(
      openingTime: _openingTimeCtrl.text.trim(),
      closingTime: _closingTimeCtrl.text.trim(),
      is24x7: _is24x7,
    );
    auth.updateStoreContact(
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Store timings and contact details updated successfully!'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Store Timings & Contact Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operating Hours Card
            const Text(
              'Operating Hours & 24x7 Mode',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.nightlight_round, color: Color(0xFF0D9488), size: 22),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '24x7 All-Night Pharmacy',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Eligible for emergency night medicine delivery',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _is24x7,
                        onChanged: (val) => setState(() => _is24x7 = val),
                        activeThumbColor: const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                  if (!_is24x7) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Opening Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _openingTimeCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF0D9488)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Closing Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _closingTimeCtrl,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF0D9488)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact & Location Card
            const Text(
              'Store Contact & Address',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Support Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF0D9488)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Official Store Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_rounded, size: 18, color: Color(0xFF0D9488)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Physical Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF0D9488)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Fulfillment Area / Neighborhood', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _areaCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.map_rounded, size: 18, color: Color(0xFF0D9488)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Save Store Details & Timings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
