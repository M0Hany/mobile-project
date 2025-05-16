import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/store.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'store_directions_screen.dart';

class StoresMapScreen extends StatefulWidget {
  final List<Store> stores;
  final String searchQuery;

  const StoresMapScreen({
    Key? key,
    required this.stores,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<StoresMapScreen> createState() => _StoresMapScreenState();
}

class _StoresMapScreenState extends State<StoresMapScreen> {
  final _logger = Logger();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _mapInitialized = false;
  String? _mapError;
  bool _isEmulator = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _logger
        .i('Initializing StoresMapScreen with ${widget.stores.length} stores');
    _checkGoogleServices();
  }

  Future<void> _requestLocationPermission() async {
    try {
      _logger.i('Requesting location permissions');
      
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        return;
      }

      // Request both permissions
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        _logger.i('Location permission granted');
        setState(() {
          _locationPermissionGranted = true;
        });
      } else {
        _logger.w('Location permission denied');
      }
    } catch (e, stackTrace) {
      _logger.e('Error requesting location permission', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _checkGoogleServices() async {
    try {
      // Request location permission first
      await _requestLocationPermission();

      // Check if running on emulator
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _isEmulator = androidInfo.isPhysicalDevice == false;
      _logger.i('Running on ${_isEmulator ? 'emulator' : 'physical device'}');

      if (_isEmulator) {
        _logger.w('Running on emulator - some features might be limited');
      }

      // Create markers after check
      _createMarkers();
    } catch (e, stackTrace) {
      _logger.e('Error checking device info', error: e, stackTrace: stackTrace);
      // Create markers anyway
      _createMarkers();
    }
  }

  void _createMarkers() {
    try {
      _logger.d('Creating markers for ${widget.stores.length} stores');
      _markers = widget.stores.map((store) {
        _logger.d(
            'Creating marker for store: ${store.name} at (${store.latitude}, ${store.longitude})');
        return Marker(
          markerId: MarkerId(store.id.toString()),
          position: LatLng(store.latitude, store.longitude),
          infoWindow: InfoWindow(
            title: store.name,
            snippet:
                '${store.category ?? 'Unknown'} • Rating: ${store.rating ?? 'N/A'}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreDirectionsScreen(
                    storeName: store.name,
                    storeLatitude: store.latitude,
                    storeLongitude: store.longitude,
                  ),
                ),
              );
            },
          ),
        );
      }).toSet();
      _logger.i('Successfully created ${_markers.length} markers');
    } catch (e, stackTrace) {
      _logger.e('Error creating markers', error: e, stackTrace: stackTrace);
      _mapError = 'Error creating map markers: $e';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _logger.i('Map created callback triggered');

      // For emulators, add a longer delay
      final delay = _isEmulator
          ? const Duration(seconds: 1)
          : const Duration(milliseconds: 500);

      Future.delayed(delay, () {
        if (mounted) {
          setState(() {
            _mapController = controller;
            _mapInitialized = true;
            _mapError = null;
          });

          // Set map style for better visibility
          controller.setMapStyle('''
            [
              {
                "featureType": "poi",
                "elementType": "labels",
                "stylers": [
                  {
                    "visibility": "off"
                  }
                ]
              }
            ]
          ''');

          _fitBounds();
        }
      });
    } catch (e, stackTrace) {
      _logger.e('Error in onMapCreated', error: e, stackTrace: stackTrace);
      setState(() {
        _mapError = 'Error initializing map: $e';
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _mapError = null;
      _mapInitialized = false;
    });
    _createMarkers();
  }

  void _fitBounds() {
    if (widget.stores.isEmpty) {
      _logger.w('No stores to fit bounds');
      return;
    }

    try {
      _logger.d('Calculating map bounds for ${widget.stores.length} stores');

      double minLat = widget.stores.first.latitude;
      double maxLat = widget.stores.first.latitude;
      double minLng = widget.stores.first.longitude;
      double maxLng = widget.stores.first.longitude;

      for (var store in widget.stores) {
        if (store.latitude < minLat) minLat = store.latitude;
        if (store.latitude > maxLat) maxLat = store.latitude;
        if (store.longitude < minLng) minLng = store.longitude;
        if (store.longitude > maxLng) maxLng = store.longitude;
      }

      _logger.d(
          'Bounds calculated: SW(${minLat - 0.01}, ${minLng - 0.01}), NE(${maxLat + 0.01}, ${maxLng + 0.01})');

      // Add padding to bounds
      const padding = 0.01; // Approximately 1km
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - padding, minLng - padding),
            northeast: LatLng(maxLat + padding, maxLng + padding),
          ),
          50, // padding in pixels
        ),
      );
      _logger.i('Successfully fit bounds');
    } catch (e, stackTrace) {
      _logger.e('Error fitting bounds', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Building StoresMapScreen widget');

    // Calculate initial camera position
    late final LatLng initialPosition;
    try {
      if (widget.stores.isNotEmpty) {
        _logger.d(
            'Calculating initial position from ${widget.stores.length} stores');
        double avgLat =
            widget.stores.map((s) => s.latitude).reduce((a, b) => a + b) /
                widget.stores.length;
        double avgLng =
            widget.stores.map((s) => s.longitude).reduce((a, b) => a + b) /
                widget.stores.length;
        initialPosition = LatLng(avgLat, avgLng);
        _logger.i('Initial position calculated: ($avgLat, $avgLng)');
      } else {
        _logger.w('No stores available, using default position (Cairo)');
        initialPosition = const LatLng(30.0444, 31.2357); // Default to Cairo
      }
    } catch (e, stackTrace) {
      _logger.e('Error calculating initial position',
          error: e, stackTrace: stackTrace);
      initialPosition = const LatLng(30.0444, 31.2357); // Fallback to Cairo
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Stores with "${widget.searchQuery}"'),
        actions: [
          if (_mapError != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryInitialization,
              tooltip: 'Retry loading map',
            ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: !_mapInitialized,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: _locationPermissionGranted,
              mapToolbarEnabled: true,
              zoomControlsEnabled: true,
              trafficEnabled: !_isEmulator,
              mapType: MapType.normal,
              onCameraMove: (position) {
                _logger.v('Camera moved to: ${position.target}');
              },
              compassEnabled: true,
              indoorViewEnabled: !_isEmulator,
              buildingsEnabled: true,
              liteModeEnabled: _isEmulator, // Enable lite mode for emulators
            ),
          ),
          if (!_mapInitialized)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    if (_isEmulator)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Running on emulator\nSome features may be limited',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (_mapError != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _mapError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _retryInitialization,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logger.i('Disposing StoresMapScreen');
    _mapController?.dispose();
    super.dispose();
  }
}
