import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapLocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Default to Kuala Lumpur, Malaysia
    _selectedLocation = widget.initialLocation ?? LatLng(3.139, 101.6869);

    // Get initial address if location provided
    if (widget.initialLocation != null) {
      _getAddressFromLatLng(_selectedLocation);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);

        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLatLng(location);
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${ApiConstants.googleMapsApiKey}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  void _onPlaceSelected(Prediction prediction) async {
    if (prediction.placeId == null) {
      print('No place ID in prediction');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Get place details from Google Places API using place_id
      final placeDetails = await _getPlaceDetails(prediction.placeId!);

      if (placeDetails != null && placeDetails['geometry'] != null) {
        final location = placeDetails['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];
        final newLocation = LatLng(lat, lng);

        // Get formatted address from place details
        final formattedAddress = placeDetails['formatted_address'] ?? prediction.description ?? '';

        setState(() {
          _selectedLocation = newLocation;
          _selectedAddress = formattedAddress;
          _searchController.clear();
        });

        // Animate map to new location with proper zoom
        _mapController.move(newLocation, 16.0);

        setState(() {
          _isSearching = false;
        });
      } else {
        throw Exception('Could not get place details');
      }
    } catch (e) {
      print('Error selecting place: $e');
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find location. Please try again.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _confirmLocation() {
    context.pop({
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress.isNotEmpty
          ? _selectedAddress
          : '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taskawayasia.taskaway',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFFFDB5B),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Search Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.md,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: GooglePlaceAutoCompleteTextField(
                            textEditingController: _searchController,
                            googleAPIKey: ApiConstants.googleMapsApiKey,
                            boxDecoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent, width: 0),
                              color: AppColors.white,
                              borderRadius: AppRadius.md,
                            ),
                            inputDecoration: InputDecoration(
                              hintText: 'Search location...',
                              filled: true,
                              fillColor: AppColors.white,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.gray400,
                              ),
                            ),
                            debounceTime: 800,
                            countries: const ["my"], // Malaysia only
                            isLatLngRequired: false,
                            getPlaceDetailWithLatLng: (Prediction prediction) {
                              // This is called when a place is selected
                              _onPlaceSelected(prediction);
                            },
                            itemClick: (Prediction prediction) {
                              // Also handle selection here for immediate response
                              _onPlaceSelected(prediction);
                            },
                            itemBuilder: (context, index, Prediction prediction) {
                              return Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFF788494)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        prediction.description ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            seperatedBuilder: const Divider(),
                            isCrossBtnShown: true,
                            containerHorizontalPadding: 10,
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              // Search button - optional, autocomplete handles search
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: AppRadius.md,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: Color(0xFF788494)),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _isLoadingAddress
                                ? const SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _selectedAddress.isNotEmpty
                                        ? _selectedAddress
                                        : 'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDB5B),
                          foregroundColor: const Color(0xFF000000),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md,
                            side: const BorderSide(color: Color(0xFFFFC333), width: 1),
                          ),
                        ),
                        onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
                        child: Text(
                          'Confirm location',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Crosshair Helper (optional)
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 2,
                  height: 20,
                  color: AppColors.textPrimary.withOpacity(0.3),
                ),
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 20,
                  height: 2,
                  color: AppColors.textPrimary.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}