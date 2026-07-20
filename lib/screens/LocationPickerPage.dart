import 'package:barvin/generated/l10n.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const Color _primaryColor = Color(0xFF567765);
const Color _accentColor = Color(0xFF5D8A4E);

// Used only if GPS is unavailable/denied, so the map has somewhere to
// center. The banner below the app bar makes clear this isn't the user's
// real location whenever it's actually in use.
const LatLng _fallbackCenter = LatLng(36.2021, 43.6150);

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({Key? key}) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _picked;
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  bool _mapReady = false;
  bool _usingFallbackLocation = false;

  @override
  void initState() {
    super.initState();
    // Auto-navigate to user's location on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToMyLocation(autoLoad: true);
    });
  }

  void _debugLog(String message) {
    if (kDebugMode) print('[LOCATION] $message');
  }

  Future<void> _goToMyLocation({bool autoLoad = false}) async {
    if (!autoLoad) {
      setState(() => _isLoadingLocation = true);
    }
    final s = S.of(context);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _debugLog('location services disabled');
        if (!autoLoad && mounted) {
          _showLocationSnack(s.locationServicesDisabled,
              color: Colors.orange.shade700);
        }
        setState(() {
          _isLoadingLocation = false;
          _usingFallbackLocation = true;
        });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _debugLog('permission denied by user');
          if (!autoLoad && mounted) {
            _showLocationSnack(s.locationPermissionDenied,
                color: Colors.orange.shade700);
          }
          setState(() {
            _isLoadingLocation = false;
            _usingFallbackLocation = true;
          });
          return;
        }
      }

      if (perm == LocationPermission.deniedForever) {
        _debugLog('permission permanently denied');
        if (!autoLoad && mounted) {
          _showLocationSnack(s.locationPermissionDeniedForever,
              color: Colors.red.shade700,
              duration: const Duration(seconds: 4));
        }
        setState(() {
          _isLoadingLocation = false;
          _usingFallbackLocation = true;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);

      final latlng = LatLng(pos.latitude, pos.longitude);
      _debugLog('got location (±${pos.accuracy.toStringAsFixed(0)}m)');

      setState(() {
        _userLocation = latlng;
        _picked = latlng;
        _isLoadingLocation = false;
        _usingFallbackLocation = false;
      });

      if (_mapReady) {
        _mapController.move(latlng, 16);
      }
    } catch (e) {
      _debugLog('error: $e');
      setState(() {
        _isLoadingLocation = false;
        _usingFallbackLocation = true;
      });
      if (!autoLoad && mounted) {
        _showLocationSnack(s.locationErrorGeneric(e.toString()),
            color: Colors.red.shade700);
      }
    }
  }

  void _showLocationSnack(String message,
      {required Color color, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xffD3E4C4),
      appBar: AppBar(
        backgroundColor: const Color(0xffFEFAE0),
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryColor),
        title: Text(
          s.locationPickerTitle,
          style: const TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map container with rounded corners
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation ?? _fallbackCenter,
                  initialZoom: 14,
                  onMapReady: () {
                    setState(() => _mapReady = true);
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 16);
                    }
                  },
                  onTap: (_, latlng) {
                    setState(() => _picked = latlng);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.barvin',
                  ),
                  // User's current location marker (blue circle)
                  if (_userLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _userLocation!,
                          radius: 8,
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  // Selected location marker (red pin)
                  if (_picked != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _picked!,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 32,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          alignment: Alignment.topCenter,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoadingLocation)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        s.locationGettingYours,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // My location button
          Positioned(
            bottom: _picked != null ? 100 : 30,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'my_location',
                onPressed: () => _goToMyLocation(),
                backgroundColor: Colors.white,
                elevation: 0,
                child: const Icon(
                  Icons.my_location,
                  color: _primaryColor,
                ),
              ),
            ),
          ),

          // Confirm button
          if (_picked != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 80,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    s.locationConfirm,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(_picked);
                  },
                ),
              ),
            ),

          // Instruction hint at top — calls out explicitly when the map is
          // centered on the fallback location rather than the user's own.
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _usingFallbackLocation
                        ? Icons.info_outline
                        : Icons.touch_app,
                    color: _primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _usingFallbackLocation
                          ? s.locationFallbackHint
                          : s.locationTapHint,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
