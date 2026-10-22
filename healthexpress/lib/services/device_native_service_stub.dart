import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';

class DeviceNativeService {
  /// Launches native in-device contact picker / phonebook
  static Future<Map<String, dynamic>> pickDeviceContact() async {
    try {
      // 1. Request read permission
      try {
        await FlutterContacts.permissions.request(PermissionType.read);
      } catch (permErr) {
        debugPrint('Permission request warning: $permErr');
      }

      // 2. Launch native Android/iOS system contact picker dialog
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone, ContactProperty.name},
      );

      if (contact == null) {
        return {
          'success': false,
          'cancelled': true,
        };
      }

      // 3. Extract display name
      String name = (contact.displayName ?? '').trim();
      if (name.isEmpty && contact.name != null) {
        name = '${contact.name?.first ?? ''} ${contact.name?.last ?? ''}'.trim();
      }
      if (name.isEmpty) {
        name = 'Emergency Contact';
      }

      // 4. Extract phone number
      String phoneNumber = '';
      if (contact.phones.isNotEmpty) {
        final mobile = contact.phones.firstWhere(
          (p) => p.label.label == PhoneLabel.mobile,
          orElse: () => contact.phones.first,
        );
        phoneNumber = mobile.number;
      } else if (contact.id != null) {
        // If system picker only passed the ID, fetch full contact details
        try {
          final full = await FlutterContacts.get(
            contact.id!,
            properties: {ContactProperty.phone, ContactProperty.name},
          );
          if (full != null && full.phones.isNotEmpty) {
            final mobile = full.phones.firstWhere(
              (p) => p.label.label == PhoneLabel.mobile,
              orElse: () => full.phones.first,
            );
            phoneNumber = mobile.number;
          }
        } catch (_) {}
      }

      return {
        'success': true,
        'name': name,
        'phone': phoneNumber,
      };
    } catch (e) {
      debugPrint('DeviceNativeService.pickDeviceContact error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetches real device GPS coordinates with runtime system permissions
  static Future<Map<String, dynamic>> getLiveGpsCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled on device
        try {
          await Geolocator.openLocationSettings();
        } catch (_) {}
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'error': 'Location permission denied by user',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'error': 'Location permission permanently denied. Please enable in app settings.',
        };
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (e) {
      debugPrint('DeviceNativeService.getLiveGpsCoordinates error: $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return {
            'success': true,
            'latitude': last.latitude,
            'longitude': last.longitude,
            'lat': last.latitude,
            'lng': last.longitude,
            'accuracy': last.accuracy,
          };
        }
      } catch (_) {}
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Captures camera photo or picks image from device storage
  static Future<Map<String, dynamic>> capturePhoto({bool preferCamera = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return {
          'success': false,
          'cancelled': true,
        };
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        final f = File(file.path!);
        if (f.existsSync()) {
          bytes = await f.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to read image bytes',
        };
      }

      final ext = file.extension?.toLowerCase() ?? 'jpeg';
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final b64 = base64Encode(bytes);
      final dataUrl = 'data:$mime;base64,$b64';

      return {
        'success': true,
        'dataUrl': dataUrl,
        'name': file.name,
        'size': bytes.length,
      };
    } catch (e) {
      debugPrint('DeviceNativeService.capturePhoto error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
