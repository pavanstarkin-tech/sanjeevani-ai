import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/pharmacy_provider.dart';
import 'device_native_service.dart';

class LocationService {
  static Map<String, dynamic>? _cachedLocation;
  static DateTime? _lastFetchTime;

  /// Fetches real live GPS position of the device, with reverse geocoding
  static Future<Map<String, dynamic>?> getLivePosition({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLocation != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
        return _cachedLocation;
      }
    }

    double? lat;
    double? lng;

    // 1. Try Browser / Device W3C Geolocation API
    try {
      final gpsRes = await DeviceNativeService.getLiveGpsCoordinates();
      if (gpsRes['success'] == true && gpsRes['latitude'] != null && gpsRes['longitude'] != null) {
        lat = double.tryParse(gpsRes['latitude'].toString());
        lng = double.tryParse(gpsRes['longitude'].toString());
      }
    } catch (e) {
      debugPrint('Device GPS error: $e');
    }

    // 2. Fallback to IP-based geolocation if device GPS is denied or unavailable
    if (lat == null || lng == null) {
      try {
        final ipRes = await http.get(Uri.parse('https://ipwho.is/')).timeout(const Duration(seconds: 4));
        if (ipRes.statusCode == 200) {
          final data = jsonDecode(ipRes.body);
          if (data['success'] == true) {
            lat = double.tryParse(data['latitude'].toString());
            lng = double.tryParse(data['longitude'].toString());
          }
        }
      } catch (_) {
        try {
          final ipRes = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
          if (ipRes.statusCode == 200) {
            final data = jsonDecode(ipRes.body);
            lat = double.tryParse(data['latitude']?.toString() ?? '');
            lng = double.tryParse(data['longitude']?.toString() ?? '');
          }
        } catch (_) {}
      }
    }

    // Default fallback to Hyderabad Central if all fail
    lat ??= 17.4420;
    lng ??= 78.3880;

    // 3. Reverse Geocode via Mapbox Geocoding API
    String locality = 'Madhapur';
    String city = 'Hyderabad';
    String state = 'Telangana';
    String pincode = '500081';
    String formattedAddress = 'Hitech City, Madhapur, Hyderabad, Telangana - 500081';

    try {
      final token = AppConfig.mapboxAccessToken;
      final geoUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?types=address,neighborhood,locality,place,postcode,region&access_token=$token';
      final geoRes = await http.get(Uri.parse(geoUrl)).timeout(const Duration(seconds: 4));

      if (geoRes.statusCode == 200) {
        final data = jsonDecode(geoRes.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final first = features[0];
          formattedAddress = first['place_name'] ?? formattedAddress;

          for (final f in features) {
            final types = f['place_type'] as List?;
            if (types != null) {
              if (types.contains('locality') || types.contains('neighborhood')) {
                locality = f['text'] ?? locality;
              } else if (types.contains('place')) {
                city = f['text'] ?? city;
              } else if (types.contains('region')) {
                state = f['text'] ?? state;
              } else if (types.contains('postcode')) {
                pincode = f['text'] ?? pincode;
              }
            }
          }
        }
      } else {
        // Fallback to OpenStreetMap Nominatim Reverse Geocoding
        final osmUrl = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng';
        final osmRes = await http.get(
          Uri.parse(osmUrl),
          headers: {'User-Agent': 'SanjeevaniHealthApp/1.0'},
        ).timeout(const Duration(seconds: 4));

        if (osmRes.statusCode == 200) {
          final data = jsonDecode(osmRes.body);
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            formattedAddress = displayName;
            final addr = data['address'] as Map<String, dynamic>?;
            if (addr != null) {
              locality = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? locality;
              city = addr['city'] ?? addr['town'] ?? addr['village'] ?? city;
              state = addr['state'] ?? state;
              pincode = addr['postcode'] ?? pincode;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      try {
        final osmUrl = 'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng';
        final osmRes = await http.get(
          Uri.parse(osmUrl),
          headers: {'User-Agent': 'SanjeevaniHealthApp/1.0'},
        ).timeout(const Duration(seconds: 4));

        if (osmRes.statusCode == 200) {
          final data = jsonDecode(osmRes.body);
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            formattedAddress = displayName;
            final addr = data['address'] as Map<String, dynamic>?;
            if (addr != null) {
              locality = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? locality;
              city = addr['city'] ?? addr['town'] ?? addr['village'] ?? city;
              state = addr['state'] ?? state;
              pincode = addr['postcode'] ?? pincode;
            }
          }
        }
      } catch (_) {}
    }

    final result = {
      'lat': lat,
      'lng': lng,
      'locality': locality,
      'city': city,
      'state': state,
      'pincode': pincode,
      'address': formattedAddress,
      'isLiveGps': true,
    };

    _cachedLocation = result;
    _lastFetchTime = DateTime.now();
    return result;
  }

  /// Automatically syncs the entire app state (AuthProvider and PharmacyProvider) with Live GPS
  static Future<Map<String, dynamic>?> syncAppLocationWithLiveGps(BuildContext context, {bool forceRefresh = false}) async {
    try {
      final loc = await getLivePosition(forceRefresh: forceRefresh);
      if (loc != null && context.mounted) {
        final address = loc['address'] as String? ?? 'Hyderabad, Telangana';
        final lat = loc['lat'] as double?;
        final lng = loc['lng'] as double?;

        final auth = context.read<AuthProvider>();
        auth.updateAddress(address, latitude: lat, longitude: lng);

        final pharmacy = context.read<PharmacyProvider>();
        pharmacy.setAddress(address);

        return loc;
      }
    } catch (e) {
      debugPrint('syncAppLocationWithLiveGps error: $e');
    }
    return null;
  }
}
