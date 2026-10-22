import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/pharmacy_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';

class AddressSelectionModal extends StatefulWidget {
  const AddressSelectionModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddressSelectionModal(),
    );
  }

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal> {
  bool _isAddingNew = false;
  bool _isDetectingGps = false;
  final _flatController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _addressTag = 'Home';

  List<Map<String, String>> _customSavedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('custom_saved_addresses');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _customSavedAddresses = decoded.map((item) => Map<String, String>.from(item)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _persistSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_saved_addresses', jsonEncode(_customSavedAddresses));
    } catch (_) {}
  }

  @override
  void dispose() {
    _flatController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _detectLiveGps() async {
    setState(() => _isDetectingGps = true);
    try {
      final loc = await LocationService.syncAppLocationWithLiveGps(context, forceRefresh: true);
      if (mounted) {
        setState(() => _isDetectingGps = false);
        if (loc != null) {
          Navigator.of(context).pop();
          final formatted = loc['address'] as String? ?? '${loc['locality']}, ${loc['city']}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('📍 Live GPS Address set: $formatted'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get GPS position. Please select an address below.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDetectingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting GPS: $e')),
        );
      }
    }
  }

  void _saveNewAddress() {
    final flat = _flatController.text.trim();
    final area = _areaController.text.trim();
    final city = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Hyderabad';
    final pin = _pincodeController.text.trim();

    if (flat.isEmpty || area.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in House/Flat, Area, and Pincode')),
      );
      return;
    }

    final formatted = '$flat, $area, $city, Telangana - $pin';
    
    // Add to saved addresses
    _customSavedAddresses.add({
      'tag': _addressTag,
      'title': flat,
      'subtitle': '$area, $city - $pin',
      'full': formatted,
    });
    _persistSavedAddresses();

    context.read<PharmacyProvider>().setAddress(formatted);
    context.read<AuthProvider>().updateAddress(formatted);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Delivery address updated to "$_addressTag" ($formatted)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyProv = context.watch<PharmacyProvider>();
    final auth = context.watch<AuthProvider>();
    final userAddress = auth.currentUser.address;
    final currentAddress = pharmacyProv.selectedAddress.isNotEmpty 
        ? pharmacyProv.selectedAddress 
        : (userAddress.isNotEmpty ? userAddress : 'Live GPS Current Location');

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Location Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Real GPS live coordinate synchronization', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // 1. Live GPS Auto-Detect Card
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primaryAccent.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: _isDetectingGps
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                        ),
                  title: const Text(
                    'Use Current Live GPS Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  subtitle: const Text(
                    'Fetches device GPS coordinates & reverse geocodes real address',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                  onTap: _isDetectingGps ? null : _detectLiveGps,
                ),
              ),

              if (!_isAddingNew) ...[
                // Primary Active / Profile Address
                if (userAddress.isNotEmpty) ...[
                  const Text('Live Active Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: currentAddress == userAddress ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: currentAddress == userAddress ? AppColors.primary : AppColors.border,
                        width: currentAddress == userAddress ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.verified_user_rounded,
                        color: currentAddress == userAddress ? AppColors.primary : AppColors.textMuted,
                      ),
                      title: Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Current Location Address',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentAddress == userAddress) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        userAddress,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: currentAddress == userAddress
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted),
                      onTap: () {
                        pharmacyProv.setAddress(userAddress);
                        auth.updateAddress(userAddress);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address set to Current Live Location')),
                        );
                      },
                    ),
                  ),
                ],

                // Saved User Custom Addresses List (if any added by user)
                if (_customSavedAddresses.isNotEmpty) ...[
                  const Text('Your Saved Addresses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  ..._customSavedAddresses.map((addr) {
                    final full = addr['full'] ?? '${addr['title']!}, ${addr['subtitle']!}';
                    final isSelected = currentAddress == full;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          addr['tag'] == 'Home'
                              ? Icons.home_rounded
                              : (addr['tag'] == 'Office' ? Icons.business_rounded : Icons.location_city_rounded),
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                        title: Row(
                          children: [
                            Text(addr['tag']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          full,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted),
                        onTap: () {
                          pharmacyProv.setAddress(full);
                          auth.updateAddress(full);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Address set to ${addr['tag']}')),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Button to Add New Address
                OutlinedButton.icon(
                  onPressed: () => setState(() => _isAddingNew = true),
                  icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                  label: const Text('Add / Enter New Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ] else ...[
                // New Address Form
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enter Address Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => setState(() => _isAddingNew = false),
                      child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tag Selector
                Row(
                  children: ['Home', 'Office', 'Other'].map((t) {
                    final isSel = _addressTag == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (val) => setState(() => _addressTag = t),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _flatController,
                  decoration: InputDecoration(
                    labelText: 'House / Flat / Block / Door No.',
                    hintText: 'e.g. Flat 301, Lakeview Residency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    labelText: 'Street / Area / Landmark',
                    hintText: 'e.g. Main Road, Near Primary Health Center',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City / Town',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pincode',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveNewAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save & Use Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
