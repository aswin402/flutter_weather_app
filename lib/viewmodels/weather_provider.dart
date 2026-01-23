import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weatherapp1/models/weather_model.dart';
import 'package:weatherapp1/services/weather_services.dart';
import 'dart:async';

class WeatherProvider extends ChangeNotifier {
  final WeatherServices _weatherServices = WeatherServices();
  
  WeatherModel? _weather;
  WeatherModel? get weather => _weather;
  
  String _cityName = 'Loading...';
  String get cityName => _cityName;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _currentTime = '';
  String get currentTime => _currentTime;
  
  String _currentDate = '';
  String get currentDate => _currentDate;

  Timer? _timer;

  WeatherProvider() {
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
    fetchWeather();
  }

  void _updateTime() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _currentDate = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Position position = await _weatherServices.getCurrentPosition();
      
      // Parallelize weather fetch and city name fetch
      final results = await Future.wait([
        _weatherServices.fetchWeather(position.latitude, position.longitude),
        _weatherServices.getCityName(position.latitude, position.longitude),
      ]);

      _weather = results[0] as WeatherModel;
      _cityName = results[1] as String;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
