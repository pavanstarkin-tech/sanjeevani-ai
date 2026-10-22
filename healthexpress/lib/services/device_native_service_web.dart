import 'dart:convert';
import 'dart:js_interop';

@JS('launchDeviceContactPicker')
external JSPromise<JSString> _jsLaunchDeviceContactPicker();

@JS('getLiveGpsCoordinates')
external JSPromise<JSString> _jsGetLiveGpsCoordinates();

@JS('captureCameraPhotoOrGallery')
external JSPromise<JSString> _jsCaptureCameraPhotoOrGallery(JSBoolean useCamera);

class DeviceNativeService {
  /// Launches native device contact picker (W3C Contacts Manager API)
  static Future<Map<String, dynamic>> pickDeviceContact() async {
    try {
      final promise = _jsLaunchDeviceContactPicker();
      final jsResult = await promise.toDart;
      final resStr = jsResult.toDart;
      return jsonDecode(resStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Fetches real device GPS coordinates via Geolocation API
  static Future<Map<String, dynamic>> getLiveGpsCoordinates() async {
    try {
      final promise = _jsGetLiveGpsCoordinates();
      final jsResult = await promise.toDart;
      final resStr = jsResult.toDart;
      return jsonDecode(resStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Captures camera photo or picks image from gallery/device storage
  static Future<Map<String, dynamic>> capturePhoto({bool preferCamera = true}) async {
    try {
      final promise = _jsCaptureCameraPhotoOrGallery(preferCamera.toJS);
      final jsResult = await promise.toDart;
      final resStr = jsResult.toDart;
      return jsonDecode(resStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
