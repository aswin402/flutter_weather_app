import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:weatherapp1/models/weather_model.dart';

class WeatherServices {
  static const String _baseUrl = 'api.open-meteo.com';
  static const String _path = '/v1/forecast';
  static const String _defaultLocationName = 'My Location';
  static const Duration _geocodingTimeout = Duration(seconds: 8);
  static const Duration _locationTimeout = Duration(seconds: 10);
  static const int _maxGeocodingRetries = 2;

  Future<WeatherModel> fetchWeather(double latitude, double longitude) async {
    try {
      final url = Uri.https(
        _baseUrl,
        _path,
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'current_weather': 'true',
          'hourly': 'temperature_2m,relativehumidity_2m,windspeed_10m',
        },
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['current_weather'] != null) {
          return WeatherModel.fromOpenMeteoJson(data);
        }
        throw Exception('Weather data not available');
      }
      throw Exception('Failed to load weather data');
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      throw Exception('Could not get weather data. Please try again.');
    }
  }

  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location services');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: _locationTimeout,
        );
      } catch (e) {
        debugPrint('High accuracy location failed, trying low accuracy: $e');
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: _locationTimeout,
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
      throw Exception('Could not get location. Please try again.');
    }
  }

  Future<String> getCityName(double latitude, double longitude) async {
    int retryCount = 0;
    String? lastError;

    while (retryCount < _maxGeocodingRetries) {
      try {
        final deviceCity = await _tryDeviceGeocoding(latitude, longitude);
        if (deviceCity != null && deviceCity.isNotEmpty) {
          return deviceCity;
        }

        final osmCity = await _tryOpenStreetMap(latitude, longitude);
        if (osmCity != null && osmCity.isNotEmpty) {
          return osmCity;
        }

      } catch (e) {
        lastError = e.toString();
        debugPrint('Geocoding attempt ${retryCount + 1} failed: $e');
        retryCount++;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    debugPrint('All geocoding methods failed. Last error: ${lastError ?? "Unknown error"}');
    return _defaultLocationName;
  }

  Future<String?> _tryDeviceGeocoding(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(_geocodingTimeout);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint('Device geocoding result: ${_placemarkToDebugString(place)}');
        
        final locationName = _extractBestLocationName(
          place.locality,
          place.subLocality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
          place.isoCountryCode,
        );
        
        if (locationName != null) {
          return locationName;
        }
        throw Exception('All location fields were null');
      }
      throw Exception('No placemarks returned');
    } catch (e) {
      debugPrint('Device geocoding failed: $e');
      rethrow;
    }
  }

  String _placemarkToDebugString(Placemark place) {
    return 'Locality: ${place.locality}, '
           'SubLocality: ${place.subLocality}, '
           'SubAdminArea: ${place.subAdministrativeArea}, '
           'AdminArea: ${place.administrativeArea}, '
           'Country: ${place.country}, '
           'CountryCode: ${place.isoCountryCode}';
  }

  String? _extractBestLocationName(
    String? locality,
    String? subLocality,
    String? subAdminArea,
    String? adminArea,
    String? country,
    String? countryCode,
  ) {
    final name = locality?.trim() ??
                subLocality?.trim() ??
                subAdminArea?.trim() ??
                adminArea?.trim() ??
                country?.trim();
              
    if (name != null && name.isNotEmpty) {
      return name;
    }
    
    if (countryCode != null) {
      return countryCode.toUpperCase();
    }
    
    return null;
  }

  Future<String?> _tryOpenStreetMap(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=10&addressdetails=1')
      ).timeout(_geocodingTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('OSM geocoding result: ${data['address']}');
        
        final address = data['address'];
        if (address is Map) {
          return address['city']?.toString() ??
                 address['town']?.toString() ??
                 address['village']?.toString() ??
                 address['county']?.toString() ??
                 address['state']?.toString() ??
                 address['country']?.toString();
        }
      } else {
        throw Exception('OSM API returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenStreetMap geocoding failed: $e');
      rethrow;
    }
    return null;
  }
}