import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/service_card.dart';

class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(3.1390, 101.6869); // KL default
  bool _isTaskerMode = true;
  bool _isMapView = true; // Toggle between map and list view
  final PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _currentCardIndex = 0;
  
  final List<ServiceMarker> _serviceMarkers = [
    ServiceMarker(
      id: '1',
      position: const LatLng(3.1410, 101.6889),
      title: 'Clean my house',
      distance: '2.9 km away',
      postedBy: 'Hassan Amin',
      price: 'RM 50.00',
      time: '2 hours ago',
    ),
    ServiceMarker(
      id: '2',
      position: const LatLng(3.1370, 101.6849),
      title: 'Fix my plumbing',
      distance: '1.5 km away',
      postedBy: 'Sarah Lee',
      price: 'RM 80.00',
      time: '3 hours ago',
    ),
    ServiceMarker(
      id: '3',
      position: const LatLng(3.1420, 101.6909),
      title: 'Move furniture',
      distance: '3.2 km away',
      postedBy: 'Ahmad Rizal',
      price: 'RM 120.00',
      time: '5 hours ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      _mapController.move(_currentLocation, 15);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isMapView ? Colors.white : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Show either map or list view
          if (_isMapView)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taskawayasia.taskaway',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                    ..._serviceMarkers.map((service) => Marker(
                      point: service.position,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          final index = _serviceMarkers.indexOf(service);
                          setState(() {
                            _currentCardIndex = index;
                          });
                          _cardPageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            )
          else
            // List view
            Positioned.fill(
              top: _isTaskerMode ? 140 : 150, // Adjusted space for "List" title without search bar
              bottom: _isTaskerMode ? 48 : 0, // Space for VIEW MAP button only in Tasker mode
              child: Container(
                color: const Color(0xFFF8F8F8), // Light gray background
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12), // Padding at the top
                  itemCount: _serviceMarkers.length,
                  itemBuilder: (context, index) {
                    return _ServiceListItem(
                      service: _serviceMarkers[index],
                      index: index,
                    );
                  },
                ),
              ),
            ),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Show "List" title when in Poster mode
                    if (!_isTaskerMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            'List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    // Only show search bar in Tasker mode
                    if (_isTaskerMode)
                      MapSearchBar(
                        isTaskerMode: _isTaskerMode,
                        onToggle: (isTasker) {
                          setState(() {
                            _isTaskerMode = isTasker;
                          });
                        },
                        onSearch: (query) {
                          // Handle search
                        },
                      )
                    else
                      // Show only tabs in Poster mode
                      Container(
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: _TabButton(
                                label: 'TASKER',
                                isSelected: _isTaskerMode,
                                onTap: () => setState(() => _isTaskerMode = true),
                              ),
                            ),
                            Expanded(
                              child: _TabButton(
                                label: 'POSTER',
                                isSelected: !_isTaskerMode,
                                onTap: () => setState(() => _isTaskerMode = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom section for map view only (cards and view toggle)
          if (_isMapView)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    height: 170,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: PageView.builder(
                      controller: _cardPageController,
                      itemCount: _serviceMarkers.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentCardIndex = index;
                        });
                        _mapController.move(_serviceMarkers[index].position, 16);
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ServiceCard(
                            title: _serviceMarkers[index].title,
                            distance: _serviceMarkers[index].distance,
                            postedBy: _serviceMarkers[index].postedBy,
                            price: _serviceMarkers[index].price,
                            isFocused: index == _currentCardIndex,
                            onViewDetails: () {
                              // Navigate to details
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isMapView = false;
                        });
                      },
                      icon: const Icon(Icons.view_list, size: 18),
                      label: const Text(
                        'VIEW LIST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // View toggle button for list view (at bottom) - only in Tasker mode
          if (!_isMapView && _isTaskerMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isMapView = true;
                    });
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'VIEW MAP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceMarker {
  final String id;
  final LatLng position;
  final String title;
  final String distance;
  final String postedBy;
  final String price;
  final String time;

  ServiceMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.distance,
    required this.postedBy,
    required this.price,
    this.time = '2 hours ago',
  });
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final ServiceMarker service;
  final int index;
  
  const _ServiceListItem({
    required this.service,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    // Different statuses for demo
    final statuses = ['Pending', 'Completed', 'Rejected', 'Pending', 'Accepted'];
    final statusColors = {
      'Pending': Colors.orange,
      'Completed': Colors.green,
      'Rejected': Colors.red,
      'Accepted': Colors.blue,
    };
    
    final status = statuses[index % statuses.length];
    final statusColor = statusColors[status] ?? Colors.grey;
    
    return InkWell(
      onTap: () {
        // Navigate to details
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'By ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        service.postedBy,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bidding • 1 Offer',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due date Saturday, 30 Aug 2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side - Price and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.price,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}