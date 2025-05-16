import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoreDirectionsScreen extends StatefulWidget {
  final String storeName;
  final double storeLatitude;
  final double storeLongitude;

  const StoreDirectionsScreen({
    Key? key,
    required this.storeName,
    required this.storeLatitude,
    required this.storeLongitude,
  }) : super(key: key);

  @override
  State<StoreDirectionsScreen> createState() => _StoreDirectionsScreenState();
}

class _StoreDirectionsScreenState extends State<StoreDirectionsScreen> {
  final _logger = Logger();
  GoogleMapController? _mapController;
  Position? _currentLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;
  double? _distance;
  List<String> _directions = [];
  String? _duration;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      // Request location permission
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentLocation = position;
        _createMarkers();
      });

      await _getDirections();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error initializing location', error: e);
      if (mounted) {
        setState(() {
          _error = 'Error getting location: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getDirections() async {
    if (_currentLocation == null) return;

    try {
      final apiKey = 'AIzaSyBdDH7-9a47jT5YGJWkKZmxmpKcPT_81LA'; // Your Google Maps API key
      final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
      final destination = '${widget.storeLatitude},${widget.storeLongitude}';
      
      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=walking&key=$apiKey'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Get route points
          final points = PolylinePoints().decodePolyline(
            data['routes'][0]['overview_polyline']['points']
          );

          // Create polyline
          final List<LatLng> polylineCoordinates = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            );

            // Get step-by-step directions
            _directions = data['routes'][0]['legs'][0]['steps']
                .map<String>((step) => step['html_instructions'].toString()
                    .replaceAll(RegExp(r'<[^>]*>'), ''))
                .toList();

            // Get distance and duration
            _distance = data['routes'][0]['legs'][0]['distance']['value'] / 1000;
            _duration = data['routes'][0]['legs'][0]['duration']['text'];
          });
        } else {
          throw Exception('Failed to get directions: ${data['status']}');
        }
      } else {
        throw Exception('Failed to get directions');
      }
    } catch (e) {
      _logger.e('Error getting directions', error: e);
      setState(() {
        _error = 'Error getting directions: $e';
      });
    }
  }

  void _createMarkers() {
    if (_currentLocation == null) return;

    _markers = {
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('store_location'),
        position: LatLng(widget.storeLatitude, widget.storeLongitude),
        infoWindow: InfoWindow(title: widget.storeName),
      ),
    };
  }

  void _fitBounds() {
    if (_currentLocation == null || _mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _currentLocation!.latitude < widget.storeLatitude
            ? _currentLocation!.latitude
            : widget.storeLatitude,
        _currentLocation!.longitude < widget.storeLongitude
            ? _currentLocation!.longitude
            : widget.storeLongitude,
      ),
      northeast: LatLng(
        _currentLocation!.latitude > widget.storeLatitude
            ? _currentLocation!.latitude
            : widget.storeLatitude,
        _currentLocation!.longitude > widget.storeLongitude
            ? _currentLocation!.longitude
            : widget.storeLongitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions to ${widget.storeName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.storeLatitude, widget.storeLongitude),
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _fitBounds();
                      },
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.3,
                      minChildSize: 0.2,
                      maxChildSize: 0.8,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                if (_distance != null && _duration != null)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_distance!.toStringAsFixed(2)} km',
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Distance',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _duration!,
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Duration',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Divider(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Directions',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _directions.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${index + 1}. ',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(_directions[index]),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
} 