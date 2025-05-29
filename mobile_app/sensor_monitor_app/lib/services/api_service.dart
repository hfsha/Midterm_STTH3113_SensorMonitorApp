import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  static const String baseUrl =
      'https://humancc.site/shahidatulhidayah/iottraining/backend';
  static const int deviceId = 101;

  Future<List<SensorData>> fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dht11_fetch.php?device_id=$deviceId&limit=50'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          return (jsonData['data'] as List)
              .map((item) => SensorData.fromJson(item))
              .toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> postSensorData(
      double temp, double hum, String relayStatus) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/dht11_api.php?id=$deviceId&temp=$temp&hum=$hum&relay=$relayStatus'),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateThresholds(double tempThreshold, double humThreshold) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dht11_api.php'),
        body: json.encode({'device_id': deviceId, 'temp_threshold': tempThreshold, 'hum_threshold': humThreshold}),
        headers: {'Content-Type': 'application/json'},
      );
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to update thresholds: $e');
    }
  }
}
