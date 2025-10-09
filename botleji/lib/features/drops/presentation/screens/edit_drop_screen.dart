import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class EditDropScreen extends ConsumerStatefulWidget {
  final Drop drop;

  const EditDropScreen({
    super.key,
    required this.drop,
  });

  @override
  ConsumerState<EditDropScreen> createState() => _EditDropScreenState();
}

class _EditDropScreenState extends ConsumerState<EditDropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  // Form controllers
  late TextEditingController _bottlesController;
  late TextEditingController _cansController;
  late TextEditingController _notesController;

  // Form state
  late BottleType _bottleType;
  late int _numberOfBottles;
  late int _numberOfCans;
  late String _notes;
  late bool _leaveOutside;
  late bool _useCurrentLocation;
  late LatLng _selectedDropLocation;
  late String _selectedLocationAddress;
  late bool _isLocationLocked;

  // Image state
  File? _selectedImage;
  bool _isLoading = false;

  // Map controller
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  
  // Custom marker icon
  BitmapDescriptor? _customDropMarker;

  // Focus nodes
  final FocusNode _bottlesFocusNode = FocusNode();
  final FocusNode _cansFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // Load custom marker icon
    
    // Initialize form with current drop data
    _bottleType = widget.drop.bottleType;
    _numberOfBottles = widget.drop.numberOfBottles;
    _numberOfCans = widget.drop.numberOfCans;
    _notes = widget.drop.notes ?? '';
    _leaveOutside = widget.drop.leaveOutside;
    _selectedDropLocation = widget.drop.location;
    _selectedLocationAddress = 'Loading address...';
    _useCurrentLocation = false;
    _isLocationLocked = false;

    // Initialize controllers
    _bottlesController = TextEditingController(text: _numberOfBottles.toString());
    _cansController = TextEditingController(text: _numberOfCans.toString());
    _notesController = TextEditingController(text: _notes);

    // Load address for current location
    _loadAddressForLocation(_selectedDropLocation);
  }

  // Load custom marker icon from assets
  Future<void> _loadCustomMarker() async {
    try {
      // Match default Google Maps marker size (approximately 48x48 actual pixels)
      // Using width parameter to control final size
      final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(24, 24)), // Much smaller logical size
        'assets/icons/drop-pin.png',
      );
      setState(() {
        _customDropMarker = customIcon;
      });
      debugPrint('✅ Custom drop marker loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading custom marker: $e');
      // Fallback to default marker if loading fails
      setState(() {
        _customDropMarker = BitmapDescriptor.defaultMarker;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bottlesFocusNode.dispose();
    _cansFocusNode.dispose();
    _notesFocusNode.dispose();
    _bottlesController.dispose();
    _cansController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAddressForLocation(LatLng location) async {
    try {
      // For now, just set a simple address since geocoding is not available
      setState(() {
        _selectedLocationAddress = 'Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() {
        _selectedLocationAddress = 'Location selected';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),);
      }
    }
  }

  // Compress and upload image to Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      // Compress the image first
      final originalBytes = await imageFile.readAsBytes();
      
      // Try to compress the image
      Uint8List? compressedBytes;
      String? compressionError;
      
      try {
        final image = img.decodeImage(originalBytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 800); // Resize to max 800px width
          compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        }
      } catch (e) {
        compressionError = e.toString();
      }

      // Use compressed image if available, otherwise use original
      final bytesToUpload = compressedBytes ?? originalBytes;
      
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'drops/$timestamp.jpg';
      
      // Get reference to the file
      final fileRef = _storage.ref().child(fileName);
      
      // Set metadata for better caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path}, 
        );
      
      // Upload the file
      final uploadTask = await fileRef.putData(bytesToUpload, metadata);
      
      // Get the download URL
      final url = await fileRef.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Static method for image compression (runs in isolate)
  static Future<Uint8List> _compressImage(Uint8List originalBytes) async {
    try {
      // Decode the image
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }
      
      // Calculate target dimensions (maintain aspect ratio)
      const int maxWidth = 1024;
      const int maxHeight = 1024;
      final double aspectRatio = originalImage.width / originalImage.height;
      
      int targetWidth = originalImage.width;
      int targetHeight = originalImage.height;
      
      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        if (aspectRatio > 1) {
          // Landscape image
          targetWidth = maxWidth;
          targetHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait image
          targetHeight = maxHeight;
          targetWidth = (maxHeight * aspectRatio).round();
        }
      }
      
      // Resize the image
      final resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
      
      // Compress the image with quality 85 (good balance between size and quality)
      return img.encodeJpg(resizedImage, quality: 85);
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get form values
      final numberOfBottles = int.tryParse(_bottlesController.text) ?? _numberOfBottles;
      final numberOfCans = int.tryParse(_cansController.text) ?? _numberOfCans;
      final notes = _notesController.text.isEmpty ? _notes : _notesController.text;

      // Upload new image if selected
      String imageUrl = widget.drop.imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToFirebase(_selectedImage!);
      }

      // Create updated drop data
      final updatedDrop = widget.drop.copyWith(
        imageUrl: imageUrl,
        numberOfBottles: numberOfBottles,
        numberOfCans: numberOfCans,
        bottleType: _bottleType,
        notes: notes.isEmpty ? null : notes,
        leaveOutside: _leaveOutside,
        location: _selectedDropLocation,
        modifiedAt: DateTime.now(),
      );

      // Update the drop
      await ref.read(dropsControllerProvider.notifier).updateDrop(updatedDrop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drop updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating drop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drop'),
        content: const Text(
          'Are you sure you want to delete this drop? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDrop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
      );
  }

  Future<void> _deleteDrop() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the drop
      await ref.read(dropsControllerProvider.notifier).deleteDrop(widget.drop.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drop deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'deleted'); // Return 'deleted' to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting drop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Drop'),
        actions: [
          // Delete button for pending drops
          if (widget.drop.status == DropStatus.pending)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _showDeleteConfirmation,
              tooltip: 'Delete Drop',
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Image section
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  // Current or new image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            widget.drop.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            }
                          ),
                  ),
                  // Change image button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'edit_drop_camera_fab',
                      onPressed: _pickImage,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),

            // Form fields
            Expanded(
              child: SingleChildScrollView(
                physics: _isLocationLocked
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bottle type selection
                    Text(
                      'Bottle Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BottleType>(
                      value: _bottleType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: BottleType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _bottleType = value!;
                          if (value == BottleType.plastic) {
                            _numberOfBottles = 1;
                            _numberOfCans = 0;
                            _bottlesController.text = '1';
                            _cansController.text = '0';
                          } else if (value == BottleType.can) {
                            _numberOfBottles = 0;
                            _numberOfCans = 1;
                            _bottlesController.text = '0';
                            _cansController.text = '1';
                          } else if (value == BottleType.mixed) {
                            _numberOfBottles = 1;
                            _numberOfCans = 1;
                            _bottlesController.text = '1';
                            _cansController.text = '1';
                          }
                        },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bottlesController,
                            focusNode: _bottlesFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Number of Bottles',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of bottles';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 0) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cansController,
                            focusNode: _cansFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Number of Cans',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of cans';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 0) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes field
                    TextFormField(
                      controller: _notesController,
                      focusNode: _notesFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Any additional instructions for the collector...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Leave outside option
                    SwitchListTile(
                      title: const Text('Leave Outside'),
                      subtitle: const Text('Collector can leave items outside if no one is home'),
                      value: _leaveOutside,
                      onChanged: (value) {
                        setState(() {
                          _leaveOutside = value;
                        });
                        },
                    ),
                    const SizedBox(height: 16),

                    // Location section
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Current location address
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Drop Location',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedLocationAddress,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          key: _mapKey,
                          initialCameraPosition: CameraPosition(
                            target: _selectedDropLocation,
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('drop_location'),
                              position: _selectedDropLocation,
                              icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                              infoWindow: const InfoWindow(title: 'Drop Location'),
                            ),
                          },
                          onTap: (LatLng position) {
                            setState(() {
                              _selectedDropLocation = position;
                              _isLocationLocked = true;
                            });
                            _loadAddressForLocation(position);
                          },
                          onCameraMove: (CameraPosition position) {
                            if (!_isLocationLocked && !_useCurrentLocation) {
                              setState(() {
                                _isLocationLocked = true;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    
                    // Location lock indicator and confirm button
                    if (_isLocationLocked && !_useCurrentLocation) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap "Confirm" to set this location',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  _isLocationLocked = false;
                                });
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitEdit,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Updating...'),
                          ],
                        )
                      : const Text('Update Drop'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 