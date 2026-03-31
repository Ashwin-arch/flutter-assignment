import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() => runApp(const WeatherApp());

// ── Models ──
class WeatherData {
  final String city, country, description, icon, condition;
  final double tempC, feelsLike, windSpeed, lat, lon;
  final int humidity;

  const WeatherData({required this.city, required this.country, required this.tempC, required this.feelsLike,
    required this.humidity, required this.windSpeed, required this.description, required this.icon,
    required this.condition, required this.lat, required this.lon});

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
    city: j['name'], country: j['sys']['country'],
    tempC: (j['main']['temp'] as num).toDouble() - 273.15,
    feelsLike: (j['main']['feels_like'] as num).toDouble() - 273.15,
    humidity: j['main']['humidity'],
    windSpeed: (j['wind']['speed'] as num).toDouble(),
    description: j['weather'][0]['description'],
    icon: j['weather'][0]['icon'],
    condition: j['weather'][0]['main'],
    lat: (j['coord']['lat'] as num).toDouble(),
    lon: (j['coord']['lon'] as num).toDouble(),
  );
}

class AirQualityData {
  final int aqi;
  final double pm25, pm10, o3;
  const AirQualityData({required this.aqi, required this.pm25, required this.pm10, required this.o3});

  factory AirQualityData.fromJson(Map<String, dynamic> j) {
    final c = j['list'][0]['components'];
    return AirQualityData(aqi: j['list'][0]['main']['aqi'], pm25: (c['pm2_5'] as num).toDouble(), pm10: (c['pm10'] as num).toDouble(), o3: (c['o3'] as num).toDouble());
  }

  String get label => ['', 'Good', 'Fair', 'Moderate', 'Poor', 'Very Poor'][aqi];
  Color get color => [Colors.grey, const Color(0xFF4CAF50), const Color(0xFF8BC34A), const Color(0xFFFFEB3B), const Color(0xFFFF9800), const Color(0xFFF44336)][aqi];
}

// ── Service ──
class WeatherService {
  static const String _baseUrl = 'http://localhost:8002/api/v1';

  Future<WeatherData> fetchByCity(String city) async {
    final r = await http.get(Uri.parse('$_baseUrl/weather?city=${Uri.encodeComponent(city)}'));
    if (r.statusCode == 200) return WeatherData.fromJson(jsonDecode(r.body));
    if (r.statusCode == 404) throw Exception('City "$city" not found.');
    throw Exception('Error ${r.statusCode}');
  }

  Future<WeatherData> fetchByCoords(double lat, double lon) async {
    final r = await http.get(Uri.parse('$_baseUrl/weather/coords?lat=$lat&lon=$lon'));
    if (r.statusCode == 200) return WeatherData.fromJson(jsonDecode(r.body));
    throw Exception('Error ${r.statusCode}');
  }

  Future<AirQualityData> fetchAQI(double lat, double lon) async {
    final r = await http.get(Uri.parse('$_baseUrl/air_pollution?lat=$lat&lon=$lon'));
    if (r.statusCode == 200) return AirQualityData.fromJson(jsonDecode(r.body));
    throw Exception('AQI Error ${r.statusCode}');
  }
}

Future<Position> _getPosition() async {
  if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Location services disabled.');
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    throw Exception('Location permission denied.');
  }
  return Geolocator.getCurrentPosition();
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WeatherNow', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)),
    home: const WeatherScreen(),
  );
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _svc = WeatherService();
  final TextEditingController _ctrl = TextEditingController();
  Future<(WeatherData, AirQualityData)>? _future;

  @override
  void initState() { super.initState(); _ctrl.text = 'Bengaluru'; _search(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search() {
    final future = _svc.fetchByCity(_ctrl.text.trim()).then(_both);
    setState(() { _future = future; });
  }

  void _locate() async {
    try {
      final future = _getPosition().then((p) => _svc.fetchByCoords(p.latitude, p.longitude)).then(_both);
      setState(() { _future = future; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')))
        );
      }
    }
  }
  Future<(WeatherData, AirQualityData)> _both(WeatherData w) async => (w, await _svc.fetchAQI(w.lat, w.lon));

  List<Color> _gradient(String? c) => switch (c) {
    'Clear'                  => [const Color(0xFF1A6FA0), const Color(0xFFFFB347)],
    'Rain' || 'Drizzle'      => [const Color(0xFF141E30), const Color(0xFF243B55)],
    'Thunderstorm'           => [const Color(0xFF0F0C29), const Color(0xFF302B63)],
    'Snow'                   => [const Color(0xFFB0C4DE), const Color(0xFF89CFF0)],
    'Mist' || 'Fog' || 'Haze' => [const Color(0xFF606060), const Color(0xFF9E9E9E)],
    _                        => [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(WeatherData, AirQualityData)>(
      future: _future,
      builder: (context, snap) => Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(gradient: LinearGradient(colors: _gradient(snap.data?.$1.condition), begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(child: Column(children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _ctrl, style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Search city...', hintStyle: const TextStyle(color: Colors.white54),
                    filled: true, fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _locate,
                  child: Container(width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white)),
                ),
              ]),
            ),
            // Content
            Expanded(child: switch (snap.connectionState) {
              ConnectionState.waiting => const Center(child: CircularProgressIndicator(color: Colors.white)),
              _ => snap.hasError
                  ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      Text(snap.error.toString().replaceAll('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 16)),
                    ])))
                  : snap.data == null
                      ? const Center(child: Text('Search for a city', style: TextStyle(color: Colors.white70)))
                      : _WeatherBody(weather: snap.data!.$1, aq: snap.data!.$2),
            }),
          ])),
        ),
      ),
    );
  }
}

class _WeatherBody extends StatelessWidget {
  final WeatherData weather;
  final AirQualityData aq;
  const _WeatherBody({required this.weather, required this.aq});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 16),
      Text('${weather.city}, ${weather.country}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(weather.description.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
      Image.network('https://openweathermap.org/img/wn/${weather.icon}@4x.png', width: 140, height: 140,
        errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, size: 100, color: Colors.white)),
      Text('${weather.tempC.toStringAsFixed(0)}°C',
        style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w200, letterSpacing: -4)),
      Text('Feels like ${weather.feelsLike.toStringAsFixed(0)}°C', style: const TextStyle(color: Colors.white60, fontSize: 14)),
      const SizedBox(height: 28),
      // Stats
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _stat(Icons.water_drop_rounded, '${weather.humidity}%', 'Humidity'),
          Container(height: 40, width: 1, color: Colors.white24),
          _stat(Icons.air_rounded, '${weather.windSpeed.toStringAsFixed(1)} m/s', 'Wind'),
          Container(height: 40, width: 1, color: Colors.white24),
          _stat(Icons.thermostat_rounded, '${weather.feelsLike.toStringAsFixed(0)}°', 'Feels like'),
        ]),
      ),
      const SizedBox(height: 16),
      // AQI Card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.air, color: Colors.white70, size: 18), const SizedBox(width: 8),
            const Text('Air Quality', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: aq.color.withOpacity(0.25), borderRadius: BorderRadius.circular(12), border: Border.all(color: aq.color.withOpacity(0.6))),
              child: Text(aq.label, style: TextStyle(color: aq.color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _aqiStat('PM2.5', aq.pm25), _aqiStat('PM10', aq.pm10), _aqiStat('O₃', aq.o3),
          ]),
        ]),
      ),
    ]),
  );

  Widget _stat(IconData icon, String value, String label) => Column(children: [
    Icon(icon, color: Colors.white70, size: 20), const SizedBox(height: 6),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
  ]);

  Widget _aqiStat(String label, double value) => Column(children: [
    Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  ]);
}
