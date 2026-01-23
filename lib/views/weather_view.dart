import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:weatherapp1/viewmodels/weather_provider.dart';
import 'package:weatherapp1/widgets/weather_detail_item.dart';

class WeatherView extends StatelessWidget {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          final backgroundColor = _getBackgroundColor(provider.weather?.mainCondition);
          
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.8),
                  backgroundColor.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: SafeArea(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : provider.errorMessage.isNotEmpty
                      ? _ErrorView(message: provider.errorMessage, onRetry: provider.fetchWeather)
                      : _WeatherContent(provider: provider),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor(String? condition) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;

    switch (condition?.toLowerCase()) {
      case 'clear':
        return isNight ? const Color(0xFF1A1A2E) : const Color(0xFF87CEEB);
      case 'partly cloudy':
      case 'cloudy':
      case 'overcast':
        return isNight ? const Color(0xFF2C2C54) : const Color(0xFF708090);
      case 'rain':
      case 'showers':
      case 'drizzle':
        return const Color(0xFF4682B4);
      case 'thunderstorm':
        return const Color(0xFF2F4F4F);
      default:
        return isNight ? const Color(0xFF1A1A2E) : const Color(0xFF87CEEB);
    }
  }
}

class _WeatherContent extends StatelessWidget {
  final WeatherProvider provider;

  const _WeatherContent({required this.provider});

  String _getWeatherAnimation(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear': return 'assets/sunny.json';
      case 'partly cloudy':
      case 'cloudy':
      case 'overcast': return 'assets/cloudy.json';
      case 'rain':
      case 'showers':
      case 'drizzle': return 'assets/rainy.json';
      case 'thunderstorm': return 'assets/thunder.json';
      default: return 'assets/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = provider.weather;
    if (weather == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: provider.fetchWeather,
      color: Colors.white,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                provider.cityName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.currentDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                height: 200,
                child: Lottie.asset(_getWeatherAnimation(weather.mainCondition)),
              ),
              const SizedBox(height: 40),
              Text(
                '${weather.temperature.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 86,
                  fontWeight: FontWeight.w200,
                ),
              ),
              Text(
                weather.mainCondition.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  WeatherDetailItem(
                    icon: Icons.water_drop_outlined,
                    label: 'HUMIDITY',
                    value: '${weather.humidity}%',
                  ),
                  WeatherDetailItem(
                    icon: Icons.air,
                    label: 'WIND',
                    value: '${weather.windSpeed.round()} km/h',
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 60),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
