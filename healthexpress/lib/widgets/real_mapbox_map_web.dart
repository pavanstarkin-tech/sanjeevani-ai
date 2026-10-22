// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';

@JS('healthExpressMapbox.registerContainer')
external void _jsRegisterContainer(JSString containerId, JSObject domElement);

@JS('healthExpressMapbox.initMap')
external JSString _jsInitMap(JSString containerId, JSString optionsJson);

@JS('healthExpressMapbox.flyTo')
external JSBoolean _jsFlyTo(JSString containerId, JSNumber lng, JSNumber lat, JSNumber zoom);

@JS('healthExpressMapbox.addCustomMarker')
external JSBoolean _jsAddCustomMarker(JSString containerId, JSString markerId, JSNumber lng, JSNumber lat, JSString optionsJson);

@JS('healthExpressMapbox.clearAllMarkers')
external void _jsClearAllMarkers(JSString containerId);

@JS('healthExpressMapbox.renderRoute')
external void _jsRenderRoute(JSString containerId, JSArray<JSArray<JSNumber>> coordinates);

@JS('healthExpressMapbox.resizeMap')
external void _jsResizeMap(JSString containerId);

@JS('healthExpressMapbox.destroyMap')
external void _jsDestroyMap(JSString containerId);

/// Custom Mapbox Marker Model
class MapboxMarkerItem {
  final String id;
  final double lng;
  final double lat;
  final String title;
  final String color;
  final String iconHtml;
  final String? popupText;
  final String? popupHtml;
  final bool draggable;
  final bool isRawHtml;
  final double width;
  final double height;
  final String anchor;
  final String? avatarUrl;

  const MapboxMarkerItem({
    required this.id,
    required this.lng,
    required this.lat,
    this.title = '',
    this.color = '#2563EB',
    this.iconHtml = '📍',
    this.popupText,
    this.popupHtml,
    this.draggable = false,
    this.isRawHtml = true,
    this.width = 38,
    this.height = 48,
    this.anchor = 'bottom',
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'color': color,
        'iconHtml': iconHtml,
        'popupText': popupText ?? title,
        'popupHtml': popupHtml,
        'draggable': draggable,
        'isRawHtml': isRawHtml,
        'width': width,
        'height': height,
        'anchor': anchor,
        'avatarUrl': avatarUrl,
      };
}

class RealMapboxMap extends StatefulWidget {
  final double initialLng;
  final double initialLat;
  final double initialZoom;
  final List<MapboxMarkerItem> markers;
  final List<List<double>>? routeCoordinates;
  final bool interactive;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onLocateMe;
  final void Function(String markerId)? onMarkerTap;
  final VoidCallback? onMapTap;

  const RealMapboxMap({
    super.key,
    this.initialLng = 78.3880,
    this.initialLat = 17.4420,
    this.initialZoom = 14.0,
    this.markers = const [],
    this.routeCoordinates,
    this.interactive = true,
    this.height = 220,
    this.borderRadius,
    this.onLocateMe,
    this.onMarkerTap,
    this.onMapTap,
  });

  @override
  State<RealMapboxMap> createState() => RealMapboxMapState();
}

class RealMapboxMapState extends State<RealMapboxMap> {
  late final String _containerId;
  late final String _viewType;
  bool _isMapReady = false;
  bool get isMapReady => _isMapReady;
  String _currentStyle = 'mapbox://styles/mapbox/streets-v12';

  @override
  void initState() {
    super.initState();
    final uniqueSuffix = DateTime.now().microsecondsSinceEpoch.toString();
    _containerId = 'mapbox-container-$uniqueSuffix';
    _viewType = 'mapbox-view-$uniqueSuffix';

    if (kIsWeb) {
      _registerPlatformView();
    }
  }

  @override
  void didUpdateWidget(covariant RealMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers && _isMapReady) {
      clearMarkers();
      for (final m in widget.markers) {
        addMarker(m);
      }
    }
  }

  void _registerPlatformView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final div = web.document.createElement('div') as web.HTMLDivElement;
        div.id = _containerId;
        div.style.width = '100%';
        div.style.height = '100%';
        div.style.position = 'relative';
        div.style.borderRadius = '16px';
        div.style.overflow = 'hidden';

        try {
          _jsRegisterContainer(_containerId.toJS, div as JSObject);
        } catch (_) {}

        // Initialize Mapbox map after attached
        Future.delayed(const Duration(milliseconds: 50), () {
          _initializeMapbox();
        });

        return div;
      },
    );
  }

  void _initializeMapbox() {
    if (!kIsWeb) return;

    try {
      final options = {
        'accessToken': AppConfig.mapboxAccessToken,
        'centerLng': widget.initialLng,
        'centerLat': widget.initialLat,
        'zoom': widget.initialZoom,
        'style': _currentStyle,
        'interactive': widget.interactive,
        'showControls': true,
        'routeCoords': widget.routeCoordinates,
      };

      final res = _jsInitMap(_containerId.toJS, jsonEncode(options).toJS);
      final jsonRes = jsonDecode(res.toDart);
      if (jsonRes['success'] == true) {
        if (mounted) setState(() => _isMapReady = true);

        // Add markers
        for (final m in widget.markers) {
          addMarker(m);
        }

        // Draw route if present
        if (widget.routeCoordinates != null && widget.routeCoordinates!.length > 1) {
          _drawRouteNative(widget.routeCoordinates!);
        }
      }
    } catch (e) {
      debugPrint('RealMapboxMap initialization error: $e');
    }
  }

  /// Fly the camera to new coordinates
  void flyTo(double lng, double lat, {double zoom = 15.0}) {
    if (!kIsWeb) return;
    try {
      _jsFlyTo(_containerId.toJS, lng.toJS, lat.toJS, zoom.toJS);
    } catch (e) {
      debugPrint('Mapbox flyTo error: $e');
    }
  }

  /// Add or update a custom marker
  void addMarker(MapboxMarkerItem marker) {
    if (!kIsWeb) return;
    try {
      _jsAddCustomMarker(
        _containerId.toJS,
        marker.id.toJS,
        marker.lng.toJS,
        marker.lat.toJS,
        jsonEncode(marker.toJson()).toJS,
      );
    } catch (e) {
      debugPrint('Mapbox addMarker error: $e');
    }
  }

  /// Clear all markers on map
  void clearMarkers() {
    if (!kIsWeb) return;
    try {
      _jsClearAllMarkers(_containerId.toJS);
    } catch (e) {
      debugPrint('Mapbox clearMarkers error: $e');
    }
  }

  void _drawRouteNative(List<List<double>> points) {
    try {
      final jsArray = JSArray<JSArray<JSNumber>>();
      for (final pt in points) {
        final sub = JSArray<JSNumber>();
        sub.add(pt[0].toJS);
        sub.add(pt[1].toJS);
        jsArray.add(sub);
      }
      _jsRenderRoute(_containerId.toJS, jsArray);
    } catch (e) {
      debugPrint('Mapbox drawRoute error: $e');
    }
  }

  void resize() {
    if (!kIsWeb) return;
    try {
      _jsResizeMap(_containerId.toJS);
    } catch (_) {}
  }

  void toggleMapStyle() {
    setState(() {
      if (_currentStyle.contains('streets')) {
        _currentStyle = 'mapbox://styles/mapbox/satellite-streets-v12';
      } else {
        _currentStyle = 'mapbox://styles/mapbox/streets-v12';
      }
    });
    _initializeMapbox();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      try {
        _jsDestroyMap(_containerId.toJS);
      } catch (_) {}
    }
    super.dispose();
  }

  bool get isSatellite => _currentStyle.contains('satellite');

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
