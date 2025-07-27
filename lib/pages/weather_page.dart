import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:weatherapp1/models/weather_model.dart';
import 'package:weatherapp1/services/weather_services.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with TickerProviderStateMixin {
  final WeatherServices _weatherServices = WeatherServices();
  WeatherModel? _weatherData;
  String _locationName = 'Loading...';
  bool _isLoading = true;
  String _errorMessage = '';
  String _currentTime = '';
  String _currentDate = '';
  int? _humidity;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateTime();
    _fetchWeather();
    Timer.periodic(const Duration(minutes: 1), (timer) => _updateTime());
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate =
          '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
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
          _humidity = weather.humidity;
          _isLoading = false;
        });
        _startAnimations();
      } catch (e) {
        setState(() {
          _locationName = 'Current Location';
          _weatherData = weather;
          _humidity = weather.humidity;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Color _getBackgroundColor(String? condition) {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;

    switch (condition?.toLowerCase()) {
      case 'clear':
        return isNight ? const Color(0xFF1a1a2e) : const Color(0xFF87CEEB);
      case 'partly cloudy':
        return isNight ? const Color(0xFF2c2c54) : const Color(0xFF708090);
      case 'cloudy':
      case 'overcast':
        return const Color(0xFF696969);
      case 'rain':
      case 'showers':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
      case 'light drizzle':
      case 'moderate drizzle':
      case 'dense drizzle':
        return const Color(0xFF4682B4);
      case 'thunderstorm':
        return const Color(0xFF2F4F4F);
      case 'snow':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
        return const Color(0xFFB0C4DE);
      case 'fog':
      case 'freezing fog':
        return const Color(0xFF778899);
      default:
        return isNight ? const Color(0xFF1a1a2e) : const Color(0xFF87CEEB);
    }
  }

  String _getWeatherAnimation(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
        return 'assets/sunny.json';
      case 'partly cloudy':
        return 'assets/cloudy.json';
      case 'cloudy':
      case 'overcast':
        return 'assets/cloudy.json';
      case 'rain':
      case 'showers':
      case 'light rain':
      case 'moderate rain':
      case 'heavy rain':
      case 'light drizzle':
      case 'moderate drizzle':
      case 'dense drizzle':
      case 'light showers':
      case 'moderate showers':
      case 'violent showers':
        return 'assets/rainy.json';
      case 'thunderstorm':
      case 'thunderstorm with light hail':
      case 'thunderstorm with heavy hail':
        return 'assets/thunder.json';
      case 'snow':
      case 'light snow':
      case 'moderate snow':
      case 'heavy snow':
      case 'snow grains':
      case 'light snow showers':
      case 'heavy snow showers':
        return 'assets/cloudy.json'; // Using cloudy for snow as we don't have snow animation
      case 'fog':
      case 'freezing fog':
        return 'assets/cloudy.json';
      default:
        return 'assets/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final backgroundColor = _getBackgroundColor(_weatherData?.mainCondition);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _buildWeatherContent(size, backgroundColor),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 20),
            Text(
              'Getting weather data...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _fetchWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherContent(Size size, Color backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWeather,
          color: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildWeatherDisplay(size),
                        const Spacer(),
                        _buildWeatherDetails(),
                        const SizedBox(height: 30),
                        _buildRefreshButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w200,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentDate,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _locationName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDisplay(Size size) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Lottie.asset(
                _getWeatherAnimation(_weatherData?.mainCondition),
                width: size.width * 0.4,
                height: size.width * 0.4,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${_weatherData?.temperature.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.w100,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _weatherData?.mainCondition ?? '--',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWeatherDetailItem(
            Icons.air_rounded,
            'Wind',
            '${_weatherData?.windSpeed.toStringAsFixed(1)} km/h',
          ),
          _buildDivider(),
          _buildWeatherDetailItem(
            Icons.water_drop_rounded,
            'Humidity',
            '${_humidity ?? 0}%',
          ),
          _buildDivider(),
          _buildWeatherDetailItem(
            Icons.thermostat_rounded,
            'Feels Like',
            '${_weatherData?.temperature.toStringAsFixed(0)}°',
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildRefreshButton() {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_scaleController.value * 0.1),
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: () {
              HapticFeedback.lightImpact();
              _fadeController.reset();
              _slideController.reset();
              _scaleController.reset();
              _fetchWeather();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
