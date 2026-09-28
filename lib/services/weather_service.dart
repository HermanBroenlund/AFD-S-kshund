import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_models.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<WeatherSnapshot> fetch(double latitude, double longitude) async {
    final uri = Uri.https('api.met.no', '/weatherapi/locationforecast/2.0/compact', {
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
    });
    final response = await _client.get(uri, headers: {
      'User-Agent': 'AFD-Sokshund/0.1 contact: herman.bronlund@afgruppen.no',
    });
    if (response.statusCode != 200) {
      throw Exception('Kunne ikke hente værdata (${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final series = (json['properties'] as Map<String, dynamic>)['timeseries'] as List<dynamic>;
    if (series.isEmpty) throw Exception('Ingen værdata mottatt.');
    final first = series.first as Map<String, dynamic>;
    final data = first['data'] as Map<String, dynamic>;
    final instant = ((data['instant'] as Map<String, dynamic>)['details']) as Map<String, dynamic>;
    final next1 = data['next_1_hours'] as Map<String, dynamic>?;
    final details = next1?['details'] as Map<String, dynamic>?;
    double? d(dynamic v) => v is num ? v.toDouble() : null;
    return WeatherSnapshot(
      temperatureC: d(instant['air_temperature']),
      windSpeedMs: d(instant['wind_speed']),
      windDirectionDeg: d(instant['wind_from_direction']),
      humidityPercent: d(instant['relative_humidity']),
      airPressureHpa: d(instant['air_pressure_at_sea_level']),
      precipitationMm: d(details?['precipitation_amount']),
      fetchedAt: DateTime.now(),
    );
  }
}
