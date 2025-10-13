import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/presentation/screens/edit_drop_screen.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/providers/connectivity_provider.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:intl/intl.dart';
import 'package:botleji/core/widgets/account_lock_card.dart';

class DropDetailsModal extends ConsumerStatefulWidget {
  final Drop drop;
  final LatLng? currentLocation;
  final BitmapDescriptor? customDropMarker;

  const DropDetailsModal({
    super.key,
    required this.drop,
    this.currentLocation,
    this.customDropMarker,
  });

  @override
  ConsumerState<DropDetailsModal> createState() => _DropDetailsModalState();
}

class _DropDetailsModalState extends ConsumerState<DropDetailsModal> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    if (widget.currentLocation == null) return;
    
    setState(() => _isLoadingRoute = true);
    
    // Create a simple straight-line polyline for visualization
    // In production, you'd fetch actual route from Google Directions API
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [widget.currentLocation!, widget.drop.location],
      color: const Color(0xFF00695C),
      width: 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );
    
    setState(() {
      _polylines = {polyline};
      _isLoadingRoute = false;
    });
  }

  String _calculateDistance() {
    if (widget.currentLocation == null) return 'N/A';
    
    final distanceInMeters = Geolocator.distanceBetween(
      widget.currentLocation!.latitude,
      widget.currentLocation!.longitude,
      widget.drop.location.latitude,
      widget.drop.location.longitude,
    );
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _calculateDuration() {
    if (widget.currentLocation == null) return 'N/A';
    
    final distanceInMeters = Geolocator.distanceBetween(
      widget.currentLocation!.latitude,
      widget.currentLocation!.longitude,
      widget.drop.location.latitude,
      widget.drop.location.longitude,
    );
    
    // Estimate duration (walking speed of 5 km/h)
    final durationMinutes = (distanceInMeters / 1000 / 5 * 60).round();
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    } else {
      final hours = (durationMinutes / 60).floor();
      final mins = durationMinutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  Color _getStatusColor(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return Colors.orange;
      case DropStatus.accepted:
        return Colors.blue;
      case DropStatus.collected:
        return const Color(0xFF00695C);
      case DropStatus.cancelled:
        return Colors.red;
      case DropStatus.expired:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(dropsControllerProvider.notifier).getUserInfo(widget.drop.userId),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {
          'name': 'Unknown User',
          'phoneNumber': 'N/A',
          'profilePhoto': null,
        };

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
            child: Column(
              children: [
                // Handle bar and close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      // Handle bar
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance & Time Card
                      if (widget.currentLocation != null)
                        _buildDistanceTimeCard(),
                      
                      // Mini Map with Route
                      if (widget.currentLocation != null)
                        _buildMiniMap(),
                      
                      const SizedBox(height: 16),
                      
                      // Hero Image with overlay info
                      if (widget.drop.imageUrl?.isNotEmpty == true)
                        _buildHeroImage()
                      else
                        _buildNoImagePlaceholder(),
                      
                      const SizedBox(height: 16),
                      
                      // User Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildUserInfoCard(userData),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Drop Details Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDropDetailsCard(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildActionButtons(),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      children: [
        // Image
        Container(
          height: 220,
          width: double.infinity,
          child: Image.network(
            widget.drop.imageUrl ?? '',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        // Gradient overlay
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        // Overlay info
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            children: [
              // Item count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_drink, size: 18, color: Color(0xFF00695C)),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.drop.numberOfBottles + widget.drop.numberOfCans} items',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.drop.status),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.drop.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00695C).withOpacity(0.1),
            const Color(0xFF004D40).withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling,
                  size: 60,
                  color: const Color(0xFF00695C).withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No image available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Status and item count at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_drink, size: 18, color: Color(0xFF00695C)),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.drop.numberOfBottles + widget.drop.numberOfCans} items',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.drop.status),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.drop.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceTimeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00695C),
              const Color(0xFF004D40),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00695C).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Distance
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.straighten,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _calculateDistance(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 16),
            // Duration
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Est. Time',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _calculateDuration(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (widget.currentLocation!.latitude + widget.drop.location.latitude) / 2,
                    (widget.currentLocation!.longitude + widget.drop.location.longitude) / 2,
                  ),
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit bounds to show both markers
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            widget.currentLocation!.latitude < widget.drop.location.latitude
                                ? widget.currentLocation!.latitude
                                : widget.drop.location.latitude,
                            widget.currentLocation!.longitude < widget.drop.location.longitude
                                ? widget.currentLocation!.longitude
                                : widget.drop.location.longitude,
                          ),
                          northeast: LatLng(
                            widget.currentLocation!.latitude > widget.drop.location.latitude
                                ? widget.currentLocation!.latitude
                                : widget.drop.location.latitude,
                            widget.currentLocation!.longitude > widget.drop.location.longitude
                                ? widget.currentLocation!.longitude
                                : widget.drop.location.longitude,
                          ),
                        ),
                        80,
                      ),
                    );
                  });
                },
                markers: {
                  // Current location marker
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: widget.currentLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(title: 'Your Location'),
                  ),
                  // Drop location marker
                  Marker(
                    markerId: MarkerId('drop_${widget.drop.id}'),
                    position: widget.drop.location,
                    icon: widget.customDropMarker ?? BitmapDescriptor.defaultMarker,
                    infoWindow: InfoWindow(title: 'Drop Location'),
                  ),
                },
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
              // Route label overlay
              if (_isLoadingRoute)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              // Tap to interact overlay
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Route Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF00695C).withOpacity(0.1),
            backgroundImage: userData['profilePhoto'] != null
                ? NetworkImage(userData['profilePhoto'])
                : null,
            child: userData['profilePhoto'] == null
                ? const Icon(Icons.person, size: 32, color: Color(0xFF00695C))
                : null,
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userData['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.home, size: 12, color: Color(0xFF00695C)),
                          SizedBox(width: 4),
                          Text(
                            'Household',
                            style: TextStyle(
                              color: Color(0xFF00695C),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      userData['phoneNumber'] ?? 'N/A',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF00695C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Drop Information',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info grid
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Bottle Type',
            value: widget.drop.bottleType.name.toUpperCase(),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.local_drink_outlined,
            label: 'Plastic Bottles',
            value: '${widget.drop.numberOfBottles}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.recycling_outlined,
            label: 'Cans',
            value: '${widget.drop.numberOfCans}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Total Items',
            value: '${widget.drop.numberOfBottles + widget.drop.numberOfCans}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.door_front_door_outlined,
            label: 'Leave Outside',
            value: widget.drop.leaveOutside ? 'Yes' : 'No',
            valueColor: widget.drop.leaveOutside ? const Color(0xFF00695C) : Colors.grey[700],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: _formatDate(widget.drop.createdAt),
          ),
          
          // Notes (if any)
          if (widget.drop.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.drop.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.grey[900],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final userMode = ref.watch(userModeControllerProvider);
    final currentUserId = ref.read(authNotifierProvider).value?.id;
    
    return userMode.when(
      data: (mode) {
        // Only show action button for pending drops
        if (widget.drop.status != DropStatus.pending) return const SizedBox.shrink();
        
        // For household mode - show Edit Drop button
        if (mode == UserMode.household && widget.drop.userId == currentUserId) {
          return SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDropScreen(drop: widget.drop),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Drop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }
        
        // For collector mode - show Start Collection button
        if (mode == UserMode.collector) {
          final activeCollection = ref.watch(navigationControllerProvider);
          
          // If there's an active collection for same drop
          if (activeCollection != null && activeCollection.dropId == widget.drop.id) {
            return SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        destination: activeCollection.destination,
                        dropId: activeCollection.dropId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Resume Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          }
          
          // If there's a different active collection
          if (activeCollection != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete your current collection before starting a new one.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.directions),
                    label: const Text('Start Collection'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // No active collection — allow starting a new one
          final isOnline = ref.watch(connectivityProvider);
          return SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!isOnline) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You are offline. Please check your internet connection.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
                
                if (currentUserId == null) return;

                // Check if account is locked
                final user = ref.read(authNotifierProvider).value;
                if (user?.isCurrentlyLocked ?? false) {
                  if (context.mounted && user?.accountLockedUntil != null) {
                    Navigator.pop(context); // Close the drop details modal first
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: AccountLockCard(
                          lockedUntil: user!.accountLockedUntil!,
                          onDismiss: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  }
                  return;
                }

                try {
                  // Assign collector to the drop
                  await ref.read(dropsControllerProvider.notifier).assignCollector(
                    widget.drop.id,
                    currentUserId,
                  );
                  
                  // Start collection and save active collection
                  await ref.read(navigationControllerProvider.notifier).startCollection(
                    dropId: widget.drop.id,
                    destination: widget.drop.location,
                    dropoffId: widget.drop.id,
                    imageUrl: widget.drop.imageUrl,
                    numberOfBottles: widget.drop.numberOfBottles,
                    numberOfCans: widget.drop.numberOfCans,
                    bottleType: widget.drop.bottleType.name,
                    notes: widget.drop.notes,
                    leaveOutside: widget.drop.leaveOutside,
                    collectorId: currentUserId,
                  );

                  // Navigate to navigation screen
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NavigationScreen(
                          destination: widget.drop.location,
                          dropId: widget.drop.id,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.directions),
              label: const Text('Start Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

