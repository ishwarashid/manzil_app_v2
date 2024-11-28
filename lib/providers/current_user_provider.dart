import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrentUserNotifier extends StateNotifier<Map<String, dynamic>> {
  CurrentUserNotifier()
      : super({
    "uid": '',
    "email": '',
    "first_name": '',
    "last_name": '',
    "phone_number": '',
    "coordinates": [],
    "location_text": ''
  });

  // for getting permission
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // Update coordinates
      state = {
        ...state,
        "coordinates": [position.latitude, position.longitude]
      };

      // Get location text using OpenStreetMap
      final locationText = await _getAddressFromCoordinates(
          position.latitude,
          position.longitude
      );

      state = {
        ...state,
        "location_text": locationText
      };
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }

  // for getting text location text location
  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&accept-language=en-US&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
    );

    final response = await http.get(
        url,
        headers: {'Accept': 'application/json'}
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    } else {
      throw Exception('Failed to get address');
    }
  }

  void setUser(Map<String, dynamic> user) {
    state = {
      ...state,
      ...user
    };
  }

  void clearUser() {
    state = {
      "uid": '',
      "email": '',
      "first_name": '',
      "last_name": '',
      "phone_number": '',
      "coordinates": [],
      "location_text": ''
    };
  }
}

final currentUserProvider =
StateNotifierProvider<CurrentUserNotifier, Map<String, dynamic>>((ref) {
  return CurrentUserNotifier();
});