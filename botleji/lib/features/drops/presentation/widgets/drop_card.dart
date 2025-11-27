import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:intl/intl.dart';
import 'report_drop_dialog.dart';
import 'package:botleji/l10n/app_localizations.dart';

class DropCard extends StatelessWidget {
  final Drop drop;
  final bool showActions;
  final Function(DropStatus)? onStatusUpdate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final LatLng? currentLocation;
  final bool hasActiveCollection; // Add parameter to check for active collection
  final bool isHousehold; // Add parameter to determine if user is household

  const DropCard({
    super.key,
    required this.drop,
    this.showActions = false,
    this.onStatusUpdate,
    this.onEdit,
    this.onDelete,
    this.currentLocation,
    this.hasActiveCollection = false, // Default to false
    this.isHousehold = true, // Default to household for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is an accepted drop (in active collection)
    final isAcceptedDrop = drop.status == DropStatus.accepted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isAcceptedDrop 
                ? const Color(0xFF00695C).withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isAcceptedDrop
                ? const Color(0xFF00695C).withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isAcceptedDrop
                ? const Color(0xFF00695C).withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            width: isAcceptedDrop ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: drop.status == DropStatus.accepted
                    ? [
                        Colors.white,
                        const Color(0xFF00695C).withOpacity(0.03),
                      ]
                    : [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Accepted drop badge (in active collection)
            if (drop.status == DropStatus.accepted && isHousehold) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF00695C).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).inActiveCollection,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00695C),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (drop.isCensored) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  border: Border.all(color: Colors.purple.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hide_image, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Censored: ${drop.censorReason ?? 'Inappropriate image'}',
                        style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Modern header with image and map
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drop image with modern styling
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ImageFiltered(
                            imageFilter: drop.isCensored
                                ? ImageFilter.blur(sigmaX: 6, sigmaY: 6)
                                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Image.network(
                              drop.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey.shade100,
                                        Colors.grey.shade200,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (drop.isCensored)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CENSORED',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Map with modern styling
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Static map image
                          Image.network(
                            _getStaticMapUrl(drop.location),
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.blue.shade100,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.map,
                                    size: 28,
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Custom pin overlay with modern styling
                          Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00695C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Distance overlay (only for collectors)
                          if (showActions && currentLocation != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDistance(drop.location, context),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Modern item counts section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Compact item counts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Bottles count
                      if (drop.numberOfBottles > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF00695C).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/water-bottle.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${drop.numberOfBottles}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Cans count
                      if (drop.numberOfCans > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF00695C).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icons/can.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${drop.numberOfCans}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Total count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00695C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00695C).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 16,
                              color: const Color(0xFF00695C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${drop.numberOfBottles + drop.numberOfCans}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00695C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Leave outside indicator
                      if (drop.leaveOutside)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00695C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF00695C).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.door_front_door,
                                size: 16,
                                color: const Color(0xFF00695C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).outside,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Status badge (hide for censored drops since they have overlay)
                      if (!drop.isCensored)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(drop).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getStatusColor(drop).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(drop),
                                size: 16,
                                color: _getStatusColor(drop),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusDisplayText(context, drop),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(drop),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            
            // Modern notes section
            if (drop.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00695C).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.note_alt,
                        size: 18,
                        color: const Color(0xFF00695C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).note,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drop.notes!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF00695C).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Timeline section for drop progression (household only)
            // Only show timeline for active drops (pending or accepted) that are not censored, flagged, or stale
            if (isHousehold && 
                (drop.status == DropStatus.pending || drop.status == DropStatus.accepted) &&
                !drop.isCensored &&
                !drop.isSuspicious &&
                drop.status != DropStatus.stale) ...[
              const SizedBox(height: 16),
              _buildTimelineSection(context),
            ],
            
            // Collection issues alert for drops with issues (household only)
            if (isHousehold && (drop.isSuspicious || drop.cancellationCount >= 1)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).collectionIssues,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).cancelledTimes(drop.cancellationCount),
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Additional info for collectors
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // Creation time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(drop.createdAt, context),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            // Actions for collectors
            if (showActions && drop.status == DropStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: hasActiveCollection
                          ? null
                          : () {
                              print('🔍 Accept Drop button pressed for drop: ${drop.id}');
                              onStatusUpdate?.call(DropStatus.accepted);
                            },
                      icon: Icon(
                        hasActiveCollection ? Icons.block : Icons.check,
                        size: 16,
                      ),
                      label: Text(
                        hasActiveCollection
                            ? AppLocalizations.of(context).completeCurrentDropFirst
                            : AppLocalizations.of(context).acceptDrop,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasActiveCollection
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReportDropDialog(dropId: drop.id),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Icon(Icons.flag, size: 20),
                    ),
                  ),
                ],
              ),
              if (hasActiveCollection) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have an active collection. Complete or cancel it first.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            
            // Completed status for accepted drops
            if (drop.status == DropStatus.accepted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).dropAcceptedByCollector,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            

            
            // Cancelled status
            if (drop.status == DropStatus.cancelled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).dropCancelled,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Compact edit and delete buttons at bottom right (only for pending drops)
            if ((onEdit != null || onDelete != null) && drop.status == DropStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFF00695C),
                          backgroundColor: const Color(0xFF00695C).withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.red,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ),
                ],
              ),
            ],
                ],
              ),
            ),
          
        ),
      ),
      
    ),
    );
  }

  String _getStatusDisplayText(BuildContext context, Drop drop) {
    // If drop is suspicious (flagged), show "FLAGGED" regardless of actual status
    if (drop.isSuspicious) {
      return AppLocalizations.of(context).flagged;
    }
    return drop.status.localizedDisplayName(context);
  }

  Color _getStatusColor(Drop drop) {
    // If drop is suspicious (flagged), use red color
    if (drop.isSuspicious) {
      return Colors.red;
    }
    
    switch (drop.status) {
      case DropStatus.pending:
        return const Color(0xFF00695C);
      case DropStatus.accepted:
        return Colors.green;
      case DropStatus.collected:
        return Colors.blue;
      case DropStatus.cancelled:
        return Colors.red;
      case DropStatus.expired:
        return Colors.red;
      case DropStatus.stale:
        return Colors.brown;
    }
  }

  IconData _getStatusIcon(Drop drop) {
    // If drop is suspicious (flagged), use flag icon
    if (drop.isSuspicious) {
      return Icons.flag;
    }
    
    switch (drop.status) {
      case DropStatus.pending:
        return Icons.schedule;
      case DropStatus.accepted:
        return Icons.check_circle;
      case DropStatus.collected:
        return Icons.done_all;
      case DropStatus.cancelled:
        return Icons.cancel;
      case DropStatus.expired:
        return Icons.timer_off;
      case DropStatus.stale:
        return Icons.hourglass_empty;
    }
  }

  String _formatDistance(LatLng dropLocation, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (currentLocation == null) return l10n.distanceUnavailable;
    
    final distance = Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      dropLocation.latitude,
      dropLocation.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.round()}${l10n.meters} ${l10n.away}';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}${l10n.kilometers} ${l10n.away}';
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('h:mm a').format(date);
    
    if (dateOnly == today) {
      return l10n.todayAt(timeStr);
    } else if (dateOnly == yesterday) {
      return l10n.yesterdayAt(timeStr);
    } else if (dateOnly == twoDaysAgo) {
      return l10n.daysAgo(2);
    } else if (dateOnly == threeDaysAgo) {
      return l10n.daysAgo(3);
    } else {
      // More than 3 days ago - show exact date
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _getStaticMapUrl(LatLng location) {
    const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
    final baseUrl = 'https://maps.googleapis.com/maps/api/staticmap';
    final parameters = {
      'center': '${location.latitude},${location.longitude}',
      'zoom': '16',
      'size': '600x400',
      'maptype': 'roadmap',
      'key': apiKey,
    };
    final queryParameters = Uri.parse(baseUrl).replace(queryParameters: parameters);
    return queryParameters.toString();
  }


  Widget _getBottleTypeIcon(BottleType bottleType, {double size = 18}) {
    switch (bottleType) {
      case BottleType.plastic:
        return Image.asset(
          'assets/icons/water-bottle.png',
          width: size,
          height: size,
          color: Colors.green[700],
        );
      case BottleType.can:
        return Image.asset(
          'assets/icons/can.png',
          width: size,
          height: size,
          color: Colors.green[700],
        );
      case BottleType.mixed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/water-bottle.png',
              width: size * 0.7,
              height: size * 0.7,
              color: Colors.green[700],
            ),
            const SizedBox(width: 2),
            Image.asset(
              'assets/icons/can.png',
              width: size * 0.7,
              height: size * 0.7,
              color: Colors.green[700],
            ),
          ],
        );
    }
  }

  Widget _buildTimelineSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00695C).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timeline,
                  color: const Color(0xFF00695C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).dropProgress,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00695C),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Animated waiting indicator
              if (drop.status == DropStatus.pending) ...[
                _buildWaitingIndicator(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Timeline steps - compact horizontal layout
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Created step
                  _buildTimelineStep(
                    icon: Icons.add_circle,
                    iconColor: const Color(0xFF00695C),
                    title: l10n.created,
                    subtitle: _formatDate(drop.createdAt, context),
                    isCompleted: true,
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey[400],
                    size: 12,
                  ),
                  // Accepted step (shows as "On the way" for household)
                  _buildTimelineStep(
                    icon: drop.status == DropStatus.accepted ? Icons.directions_walk : Icons.assignment_turned_in,
                    iconColor: drop.status == DropStatus.accepted ? const Color(0xFF00695C) : Colors.grey,
                    title: drop.status == DropStatus.accepted ? l10n.onTheWay : l10n.acceptedStatus,
                    subtitle: drop.status == DropStatus.accepted 
                        ? l10n.collectorOnHisWay
                        : l10n.waiting,
                    isCompleted: drop.status == DropStatus.accepted,
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey[400],
                    size: 12,
                  ),
                  // Collected step
                  _buildTimelineStep(
                    icon: Icons.recycling,
                    iconColor: Colors.grey,
                    title: l10n.collectedStatus,
                    subtitle: l10n.notYetCollected,
                    isCompleted: false,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCompleted ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isCompleted ? const Color(0xFF00695C) : Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: isCompleted ? const Color(0xFF00695C).withOpacity(0.8) : Colors.grey[600],
              fontSize: 8,
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingIndicator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _AnimatedHourglass(),
    );
  }
}

class _AnimatedHourglass extends StatefulWidget {
  @override
  _AnimatedHourglassState createState() => _AnimatedHourglassState();
}

class _AnimatedHourglassState extends State<_AnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: Icon(
            Icons.hourglass_empty,
            color: const Color(0xFF00695C),
            size: 16,
          ),
        );
      },
    );
  }
} 