class WeatherModel {
  final double temperature;
  final String mainCondition;
  final double windSpeed;
  final int humidity;
  final DateTime? time;
  final int weatherCode;

  const WeatherModel({
    required this.temperature,
    required this.mainCondition,
    required this.windSpeed,
    required this.humidity,
    this.time,
    required this.weatherCode,
  });

  factory WeatherModel.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current_weather'];
    final hourly = json['hourly'];
    final hourlyIndex = _findCurrentHourIndex(hourly?['time'], current?['time']);

    return WeatherModel(
      temperature: (current['temperature'] as num?)?.toDouble() ?? 0.0,
      mainCondition: _mapWeatherCodeToCondition(current['weathercode'] ?? 0),
      windSpeed: (current['windspeed'] as num?)?.toDouble() ?? 0.0,
      humidity: _getHourlyValue(hourly?['relativehumidity_2m'], hourlyIndex) ?? 0,
      time: current['time'] != null ? DateTime.parse(current['time']) : null,
      weatherCode: current['weathercode'] ?? 0,
    );
  }

  static int? _findCurrentHourIndex(List<dynamic>? times, String? currentTime) {
    if (times == null || currentTime == null) return null;
    return times.indexWhere((time) => time == currentTime);
  }

  static int? _getHourlyValue(List<dynamic>? values, int? index) {
    if (values == null || index == null || index < 0 || index >= values.length) {
      return null;
    }
    return (values[index] as num?)?.toInt();
  }

  static const Map<int, String> _weatherCodeMap = {
    0: 'Clear',
    1: 'Partly Cloudy',
    2: 'Cloudy',
    3: 'Overcast',
    45: 'Fog',
    48: 'Freezing Fog',
    51: 'Light Drizzle',
    53: 'Moderate Drizzle',
    55: 'Dense Drizzle',
    56: 'Light Freezing Drizzle',
    57: 'Dense Freezing Drizzle',
    61: 'Light Rain',
    63: 'Moderate Rain',
    65: 'Heavy Rain',
    66: 'Light Freezing Rain',
    67: 'Heavy Freezing Rain',
    71: 'Light Snow',
    73: 'Moderate Snow',
    75: 'Heavy Snow',
    77: 'Snow Grains',
    80: 'Light Showers',
    81: 'Moderate Showers',
    82: 'Violent Showers',
    85: 'Light Snow Showers',
    86: 'Heavy Snow Showers',
    95: 'Thunderstorm',
    96: 'Thunderstorm with Light Hail',
    99: 'Thunderstorm with Heavy Hail',
  };

  static String _mapWeatherCodeToCondition(int code) {
    return _weatherCodeMap[code] ?? 'Unknown';
  }

  String get temperatureFormatted => '${temperature.toStringAsFixed(1)}°C';
  String get windSpeedFormatted => '${windSpeed.toStringAsFixed(1)} km/h';
  String get humidityFormatted => '$humidity%';

  @override
  String toString() {
    return 'WeatherModel('
        'temperature: $temperature, '
        'mainCondition: $mainCondition, '
        'windSpeed: $windSpeed, '
        'humidity: $humidity)';
  }
}