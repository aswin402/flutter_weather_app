import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weatherapp1/models/weather_model.dart';
import 'package:weatherapp1/services/weather_services.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final WeatherServices _weatherServices = WeatherServices();
  WeatherModel? _weatherData;
  String _locationName = 'Loading...';
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentTime = '';
  int? _humidity; // Added to track humidity separately

  @override
  void initState() {
    super.initState();
    _updateTime();
    _fetchWeather();
    Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final position = await _weatherServices.getCurrentPosition();
      final weather = await _weatherServices.fetchWeather(
        position.latitude,
        position.longitude,
      );
      
      try {
        final location = await _weatherServices.getCityName(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _locationName = location;
          _weatherData = weather;
          _humidity = weather.humidity; // Set humidity from weather data
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _locationName = 'Current Location';
          _weatherData = weather;
          _humidity = weather.humidity; // Set humidity from weather data
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getWeatherAnimation(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
        return 'assets/sunny.json';
      case 'partly cloudy':
        return 'assets/partly_cloudy.json';
      case 'cloudy':
      case 'overcast':
        return 'assets/cloudy.json';
      case 'rain':
      case 'showers':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/thunder.json';
      default:
        return 'assets/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchWeather,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromARGB(255, 47, 113, 255),
                              Color.fromRGBO(0, 0, 0, 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          // Time
                          Text(
                            _currentTime,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Location
                          Text(
                            _locationName.toUpperCase(),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Weather Animation and Condition
                          Center(
                            child: Column(
                              children: [
                                Lottie.asset(
                                  _getWeatherAnimation(_weatherData?.mainCondition),
                                  width: size.width * 0.5,
                                  height: size.width * 0.5,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _weatherData?.mainCondition ?? '--',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Temperature
                          Center(
                            child: Text(
                              '${_weatherData?.temperature.toStringAsFixed(0)}°',
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Additional Info
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildWeatherDetail('Wind', '${_weatherData?.windSpeed.toStringAsFixed(1)} km/h'),
                                _buildWeatherDetail('Humidity', '${_humidity ?? 0}%'), // Use the tracked humidity value
                                _buildWeatherDetail('Feels Like', '${_weatherData?.temperature.toStringAsFixed(0)}°'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}