import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';

/// Custom Map Marker Model
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

class RealMapboxMapState extends State<RealMapboxMap> with TickerProviderStateMixin {
  late final MapController _mapController;
  final List<MapboxMarkerItem> _dynamicMarkers = [];
  MapboxMarkerItem? _selectedMarker;
  int _tileStyleIndex = 0; // 0: Mapbox Streets, 1: Mapbox Satellite, 2: Mapbox Navigation, 3: Mapbox Outdoors, 4: Mapbox Dark
  bool _isReady = false;
  AnimationController? _flyAnimationController;

  final List<Map<String, String>> _tileStyles = [
    {
      'name': 'Mapbox Streets',
      'url': 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=${AppConfig.mapboxAccessToken}',
    },
    {
      'name': 'Mapbox Satellite',
      'url': 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}?access_token=${AppConfig.mapboxAccessToken}',
    },
    {
      'name': 'Mapbox Navigation',
      'url': 'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/256/{z}/{x}/{y}?access_token=${AppConfig.mapboxAccessToken}',
    },
    {
      'name': 'Mapbox Outdoors',
      'url': 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/256/{z}/{x}/{y}?access_token=${AppConfig.mapboxAccessToken}',
    },
    {
      'name': 'Mapbox Dark',
      'url': 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}?access_token=${AppConfig.mapboxAccessToken}',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _dynamicMarkers.addAll(widget.markers);
    _isReady = true;
  }

  @override
  void dispose() {
    _flyAnimationController?.stop();
    _flyAnimationController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RealMapboxMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      setState(() {
        _dynamicMarkers.clear();
        _dynamicMarkers.addAll(widget.markers);
      });
    }
  }

  bool get isMapReady => _isReady;
  bool get isSatellite => _tileStyleIndex == 2;

  /// Smoothly animates camera transition from current position to target coordinates
  /// with a silky parabolic zoom-in/zoom-out arc (birds-eye perspective mid-flight).
  void flyTo(double lng, double lat, {double zoom = 15.0}) {
    final targetLatLng = LatLng(lat, lng);
    final targetZoom = zoom;

    LatLng startLatLng;
    double startZoom;
    try {
      startLatLng = _mapController.camera.center;
      startZoom = _mapController.camera.zoom;
    } catch (_) {
      startLatLng = targetLatLng;
      startZoom = targetZoom;
    }

    // Terminate any ongoing flight animation seamlessly
    _flyAnimationController?.stop();
    _flyAnimationController?.dispose();
    _flyAnimationController = null;

    final dLat = (targetLatLng.latitude - startLatLng.latitude).abs();
    final dLng = (targetLatLng.longitude - startLatLng.longitude).abs();
    final distanceDegrees = math.sqrt(dLat * dLat + dLng * dLng);

    // If identical position, no flight needed
    if (distanceDegrees < 0.00008 && (targetZoom - startZoom).abs() < 0.05) {
      return;
    }

    // Parabolic zoom dip: zooms out smoothly during mid-flight (maximum dip at t=0.5)
    final double zoomDip;
    if (distanceDegrees < 0.003) {
      zoomDip = 0.45; // Micro-arc for very close hops
    } else if (distanceDegrees < 0.04) {
      zoomDip = math.min(2.2, 0.75 + (distanceDegrees * 35.0));
    } else {
      zoomDip = math.min(3.4, 1.4 + (distanceDegrees * 20.0));
    }

    // Responsive flight duration (650ms to 1050ms)
    final durationMs = (700 + (distanceDegrees * 2600)).clamp(650, 1050).toInt();

    _flyAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _flyAnimationController!.addListener(() {
      if (!mounted) return;
      final t = _flyAnimationController!.value;
      // Fluid ease-in-out curve
      final curvedT = Curves.easeInOutCubic.transform(t);

      final curLat = startLatLng.latitude + (targetLatLng.latitude - startLatLng.latitude) * curvedT;
      final curLng = startLatLng.longitude + (targetLatLng.longitude - startLatLng.longitude) * curvedT;

      final baseZoom = startZoom + (targetZoom - startZoom) * curvedT;
      // Parabolic flight arc formula: 4 * t * (1 - t) reaches peak 1.0 at midpoint t = 0.5
      final arcFactor = 4.0 * t * (1.0 - t);
      final curZoom = (baseZoom - (arcFactor * zoomDip)).clamp(3.0, 18.5);

      try {
        _mapController.move(LatLng(curLat, curLng), curZoom);
      } catch (_) {}
    });

    _flyAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        try {
          _mapController.move(targetLatLng, targetZoom);
        } catch (_) {}
      }
    });

    _flyAnimationController!.forward();
  }

  void addMarker(MapboxMarkerItem marker) {
    setState(() {
      _dynamicMarkers.removeWhere((m) => m.id == marker.id);
      _dynamicMarkers.add(marker);
    });
  }

  void clearMarkers() {
    setState(() {
      _dynamicMarkers.clear();
      _selectedMarker = null;
    });
  }

  void resize() {
    if (mounted) setState(() {});
  }

  void toggleMapStyle() {
    setState(() {
      _tileStyleIndex = (_tileStyleIndex + 1) % _tileStyles.length;
    });
  }

  Color _parseColor(String colorStr, {Color fallback = AppColors.primary}) {
    try {
      final clean = colorStr.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }


  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final activeStyle = _tileStyles[_tileStyleIndex];

    // Combine static and dynamic markers
    final allMarkersMap = <String, MapboxMarkerItem>{};
    for (final m in widget.markers) {
      allMarkersMap[m.id] = m;
    }
    for (final m in _dynamicMarkers) {
      allMarkersMap[m.id] = m;
    }
    final markersList = allMarkersMap.values.toList();

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // 1. Real Interactive Flutter Map Tile Layer
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.initialLat, widget.initialLng),
                initialZoom: widget.initialZoom,
                minZoom: 3.0,
                maxZoom: 18.5,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onTap: (_, __) {
                  if (_selectedMarker != null) {
                    setState(() => _selectedMarker = null);
                  }
                  widget.onMapTap?.call();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: activeStyle['url']!,
                  userAgentPackageName: 'com.example.healthexpress',
                  maxZoom: 19,
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                // 5km Radius Radar Circle Border around User Location
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(widget.initialLat, widget.initialLng),
                      radius: 5000, // 5km = 5000 meters
                      useRadiusInMeter: true,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.07),
                      borderColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
                // Route polyline (Curved Black Dotted Line per user instruction)
                if (widget.routeCoordinates != null && widget.routeCoordinates!.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routeCoordinates!
                            .map((pt) => LatLng(pt[1], pt[0]))
                            .toList(),
                        color: const Color(0xFF0F172A),
                        strokeWidth: 4.0,
                        pattern: const StrokePattern.dotted(spacingFactor: 1.8),
                      ),
                    ],
                  ),
                // Markers
                MarkerLayer(
                  markers: markersList.map((m) {
                    final pinColor = _parseColor(m.color);
                    final isSelected = _selectedMarker?.id == m.id;
                    final isUserLocation = m.id == 'user-live-gps';

                    if (isUserLocation) {
                      return Marker(
                        point: LatLng(m.lat, m.lng),
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x662563EB),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Marker(
                      point: LatLng(m.lat, m.lng),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 54 : 44,
                      alignment: Alignment.bottomCenter, // Point tip directly at building coordinate!
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMarker = m;
                          });
                          flyTo(m.lng, m.lat, zoom: 15.5);
                          widget.onMarkerTap?.call(m.id);
                        },
                        child: AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSelected ? 36 : 30,
                                height: isSelected ? 36 : 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: pinColor, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: pinColor.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: m.avatarUrl!,
                                          width: isSelected ? 36 : 30,
                                          height: isSelected ? 36 : 30,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Icon(
                                            Icons.person_rounded,
                                            color: pinColor,
                                            size: isSelected ? 20 : 16,
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          (m.id.contains('rider') || m.iconHtml.contains('🛵'))
                                              ? Icons.two_wheeler_rounded
                                              : ((m.id.contains('amb') || m.id.contains('emergency'))
                                                  ? Icons.emergency_rounded
                                                  : ((m.id.contains('destination') || m.iconHtml.contains('🏠') || m.id.contains('home'))
                                                      ? Icons.home_rounded
                                                      : ((m.id.contains('pharmacy') || m.iconHtml.contains('💊'))
                                                          ? Icons.medical_services_rounded
                                                          : Icons.local_hospital_rounded))),
                                          color: pinColor,
                                          size: isSelected ? 20 : 16,
                                        ),
                                      ),
                              ),
                              CustomPaint(
                                size: const Size(10, 6),
                                painter: _TrianglePointerPainter(pinColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;
  _TrianglePointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) => oldDelegate.color != color;
}
