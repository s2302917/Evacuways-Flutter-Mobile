import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_utils.dart' as web_utils;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../controllers/map_controller.dart';
import '../models/center_model.dart';
import '../models/vehicle_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  GoogleMapController? _googleMapController;
  Set<Marker> _markers = {};

  // Default camera position (Iloilo City)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.7202, 122.5621),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      web_utils.registerGoogleMapsView(
        "AIzaSyBymteLIXVnrEQbHo4pUOcuF1O8HX8GzHQ",
      );
    }
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Check and Request Location Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LOCATION PERMISSION DENIED');
        mapController.currentLocationName = "Permission Denied";
        await mapController.fetchResources();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LOCATION PERMISSION DENIED FOREVER');
      mapController.currentLocationName = "Permission Restricted";
      await mapController.fetchResources();
      return;
    }

    // 2. Get current position to update location name
    try {
      Position position = await Geolocator.getCurrentPosition();
      await mapController.updateLocationName(
        position.latitude,
        position.longitude,
      );

      if (_googleMapController != null) {
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('LOCATION FETCH ERROR: $e');
    }

    // 3. Fetch resource data from API
    await mapController.fetchResources();
    _updateMarkers();
  }

  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    for (var center in mapController.centers) {
      if (center.latitude != null && center.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('center_${center.id}'),
            position: LatLng(center.latitude!, center.longitude!),
            infoWindow: InfoWindow(
              title: center.name,
              snippet:
                  'Capacity: ${center.currentIndividuals}/${center.capacity}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () {
              _showResourceDetails(
                title: center.name,
                subtitle: center.status,
                details: {
                  'Barangay': center.barangay,
                  'Occupancy':
                      '${center.currentIndividuals}/${center.capacity}',
                  'Contact':
                      '${center.contactPerson} (${center.contactNumber})',
                },
                lat: center.latitude!,
                lng: center.longitude!,
                isCenter: true,
                centerId: center.id,
              );
            },
          ),
        );
      }
    }

    for (var vehicle in mapController.vehicles) {
      if (vehicle.latitude != null && vehicle.longitude != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('vehicle_${vehicle.vehicleId}'),
            position: LatLng(vehicle.latitude!, vehicle.longitude!),
            infoWindow: InfoWindow(
              title: '${vehicle.vehicleType} (${vehicle.plateNumber})',
              snippet: 'Driver: ${vehicle.driverName ?? "N/A"}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () {
              _showResourceDetails(
                title: vehicle.vehicleType ?? 'Vehicle',
                subtitle: vehicle.status ?? 'Unknown',
                details: {
                  'Plate': vehicle.plateNumber ?? 'N/A',
                  'Driver': vehicle.driverName ?? 'Unknown',
                  'Contact': vehicle.driverContact ?? 'N/A',
                  'Landmark': vehicle.landmark ?? 'N/A',
                },
                lat: vehicle.latitude!,
                lng: vehicle.longitude!,
              );
            },
          ),
        );
      }
    }

    // 3. Admins (Headquarters)
    for (var admin in mapController.admins) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('admin_${admin.id}'),
          position: LatLng(admin.latitude, admin.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: admin.name,
            snippet: 'Admin Headquarters - ${admin.role}',
          ),
          onTap: () {
            _showResourceDetails(
              title: admin.name,
              subtitle: 'Admin Headquarters',
              details: {
                'Role': admin.role,
                'Location': 'Main Operating Center',
              },
              lat: admin.latitude,
              lng: admin.longitude,
            );
          },
        ),
      );
    }

    debugPrint('MAP UPDATING MARKERS: ${newMarkers.length} markers generated');
    setState(() {
      _markers = newMarkers;
    });
  }

  void _showResourceDetails({
    required String title,
    required String subtitle,
    required Map<String, String> details,
    required double lat,
    required double lng,
    bool isCenter = false,
    int? centerId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              subtitle.toLowerCase().contains('open') ||
                                  subtitle.toLowerCase().contains('standby') ||
                                  subtitle.toLowerCase().contains('deployed')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCenter && centerId != null)
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Find the center model and show confirmation
                      final center = mapController.centers.firstWhere(
                        (c) => c.id == centerId,
                        orElse: () => throw Exception('Center not found'),
                      );
                      _showCheckInConfirmation(center);
                    },
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ...details.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          '${e.key}: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          e.value,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
                ,
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url =
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text(
                  'GET DIRECTIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCheckInConfirmation(dynamic resource) {
    final bool isCenter = resource is CenterModel;
    final bool isVehicle = resource is VehicleModel;
    final int resourceId = isCenter ? resource.id : resource.vehicleId;
    final String resourceType = isCenter ? 'center' : 'vehicle';
    final String name = isCenter
        ? resource.name
        : (isVehicle ? (resource.vehicleType ?? 'Vehicle') : "Resource");

    final currentP = mapController.currentPresence;
    final bool isAlreadyHere =
        currentP != null &&
        currentP['resource_id'].toString() == resourceId.toString() &&
        currentP['resource_type'] == resourceType;

    final String message = isAlreadyHere
        ? "Are you no longer at this $resourceType?"
        : (isCenter
              ? "Have you reached at this evacuation center?"
              : "Are you currently inside this rescue vehicle?");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAlreadyHere
              ? "Confirm Departure"
              : (isCenter ? "Confirm Arrival" : "Confirm Boarding"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Resource: $name\n\n$message"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAlreadyHere
                  ? AppColors.danger
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (isAlreadyHere) {
                _cancelCheckIn();
              } else {
                if (isCenter) {
                  _checkInCenter(resource.id, resource.name);
                } else if (resource is VehicleModel) {
                  _checkInVehicle(
                    resource.vehicleId,
                    resource.vehicleType ?? 'Vehicle',
                  );
                }
              }
            },
            child: Text(
              isAlreadyHere ? "I'M NOT HERE ANYMORE" : "YES, I'M HERE",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceBanner(Map<String, dynamic> presence) {
    final String type = presence['resource_type'];
    final String name = type == 'center'
        ? mapController.centers
              .firstWhere(
                (c) => c.id.toString() == presence['resource_id'].toString(),
                orElse: () => CenterModel(
                  id: 0,
                  name: "Unknown Center",
                  barangay: "N/A",
                  capacity: 0,
                  currentIndividuals: 0,
                  status: "N/A",
                ),
              )
              .name
        : mapController.vehicles
                  .firstWhere(
                    (v) =>
                        v.vehicleId.toString() ==
                        presence['resource_id'].toString(),
                    orElse: () => VehicleModel(
                      vehicleId: 0,
                      vehicleType: "Unknown Vehicle",
                      plateNumber: "N/A",
                      capacity: 0,
                      currentOccupants: 0,
                      status: "N/A",
                      createdAt: DateTime.now(),
                    ),
                  )
                  .vehicleType ??
              'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            type == 'center' ? Icons.apartment : Icons.local_shipping,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CURRENTLY AT:",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _cancelCheckIn,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _checkInVehicle(int vehicleId, String vehicleType) async {
    bool success = await mapController.checkIn(
      resourceId: vehicleId,
      resourceType: 'vehicle',
      headcount: 1,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Checked-in to $vehicleType!" : "Check-in failed.",
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  void _cancelCheckIn() async {
    bool success = await mapController.checkOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Successfully checked out." : "Check-out failed.",
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  void _checkInCenter(int centerId, String centerName) async {
    int headcount = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Check-In: $centerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Family Headcount:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: headcount > 1
                        ? () => setDialogState(() => headcount--)
                        : null,
                  ),
                  Text(
                    '$headcount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setDialogState(() => headcount++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      bool success = await mapController.checkIn(
                        resourceId: centerId,
                        resourceType: 'center',
                        headcount: headcount,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "Checked-in successfully!"
                                  : "Check-in failed. Please try again.",
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        );
                        _loadData();
                      }
                    },
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Real Google Map (Conditional)
          // Real Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: kIsWeb, // Enable zoom controls on web
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _googleMapController = controller;
              // If we have data, center on the first available resource
              if (_markers.isNotEmpty) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_markers.first.position, 14.0),
                );
              }
            },
          ),

          // App Bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EvacuWays',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mapController.isLoading
                            ? Icons.hourglass_empty
                            : Icons.refresh,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.38,
            minChildSize: 0.15,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                child: ListenableBuilder(
                  listenable: mapController,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 12,
                                bottom: 16,
                              ),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          if (mapController.currentPresence != null)
                            _buildPresenceBanner(
                              mapController.currentPresence!,
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nearby Resources',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mapController.currentLocationName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.dangerLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.danger,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'LIVE DATA',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                const Text(
                                  'EVACUATION CENTERS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (mapController.centers.isEmpty &&
                                    !mapController.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text('No active centers found.'),
                                    ),
                                  ),

                                ...mapController.centers.map(
                                  (center) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onTap: () =>
                                          _showCheckInConfirmation(center),
                                      borderRadius: BorderRadius.circular(12),
                                      child: _EvacuationCenter(
                                        icon: Icons.apartment,
                                        name: center.name,
                                        details:
                                            'Capacity: ${center.currentIndividuals}/${center.capacity} full\n${center.barangay}',
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (center.latitude != null)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  color: AppColors.success,
                                                ),
                                                onPressed: () =>
                                                    _showCheckInConfirmation(
                                                      center,
                                                    ),
                                              ),
                                            if (center.latitude != null)
                                              GestureDetector(
                                                onTap: () => _openDirections(
                                                  center.latitude!,
                                                  center.longitude!,
                                                ),
                                                child: const Icon(
                                                  Icons.directions,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                const Text(
                                  'RESCUE VEHICLES',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (mapController.vehicles.isEmpty &&
                                    !mapController.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text('No active vehicles found.'),
                                    ),
                                  ),

                                ...mapController.vehicles.map(
                                  (vehicle) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: InkWell(
                                      onTap: () =>
                                          _showCheckInConfirmation(vehicle),
                                      borderRadius: BorderRadius.circular(12),
                                      child: _EvacuationCenter(
                                        icon: Icons.local_shipping,
                                        name:
                                            '${vehicle.vehicleType} (${vehicle.plateNumber})',
                                        details:
                                            'Capacity: ${vehicle.currentOccupants ?? 0}/${vehicle.capacity} full\nDriver: ${vehicle.driverName ?? "N/A"}\nContact: ${vehicle.driverContact ?? "N/A"}\nStatus: ${vehicle.status}',
                                        trailing: vehicle.latitude != null
                                            ? GestureDetector(
                                                onTap: () => _openDirections(
                                                  vehicle.latitude!,
                                                  vehicle.longitude!,
                                                ),
                                                child: const Icon(
                                                  Icons.directions,
                                                  color: AppColors.warning,
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),
                                const Text(
                                  'ADMIN HEADQUARTERS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (mapController.admins.isEmpty &&
                                    !mapController.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No admin headquarters found.',
                                      ),
                                    ),
                                  ),

                                ...mapController.admins.map(
                                  (admin) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _EvacuationCenter(
                                      icon: Icons.business,
                                      name: admin.name,
                                      details:
                                          'System Admin • ${admin.role}\nMain Operating Center',
                                      trailing: GestureDetector(
                                        onTap: () => _openDirections(
                                          admin.latitude,
                                          admin.longitude,
                                        ),
                                        child: const Icon(
                                          Icons.directions,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EvacuationCenter extends StatelessWidget {
  final IconData icon;
  final String name;
  final String details;
  final Widget trailing;

  const _EvacuationCenter({
    required this.icon,
    required this.name,
    required this.details,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
