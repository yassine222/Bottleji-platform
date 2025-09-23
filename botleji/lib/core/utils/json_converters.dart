import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

class LatLngConverter implements JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    // Handle GeoJSON format: {type: "Point", coordinates: [longitude, latitude]}
    if (json.containsKey('type') && json.containsKey('coordinates')) {
      final coordinates = json['coordinates'] as List<dynamic>;
      if (coordinates.length >= 2) {
        return LatLng(
          (coordinates[1] as num).toDouble(), // latitude
          (coordinates[0] as num).toDouble(), // longitude
        );
      }
    }
    
    // Handle legacy format: {latitude: double, longitude: double}
    if (json.containsKey('latitude') && json.containsKey('longitude')) {
    return LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }
    
    // Fallback for other formats
    return LatLng(0.0, 0.0);
  }

  @override
  Map<String, dynamic> toJson(LatLng latLng) {
    // Return in GeoJSON format to match API expectations
    return {
      'type': 'Point',
      'coordinates': [latLng.longitude, latLng.latitude],
    };
  }
} 