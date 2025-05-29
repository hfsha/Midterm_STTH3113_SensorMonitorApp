import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/sensor_data.dart';

class SensorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<SensorData> _sensorData = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Add threshold properties
  double _tempThreshold = 26.0; // Default value
  double _humThreshold = 70.0; // Default value

  List<SensorData> get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  // Add getters for thresholds
  double get tempThreshold => _tempThreshold;
  double get humThreshold => _humThreshold;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sensorData = await _apiService.fetchSensorData();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Add method to update thresholds
  Future<void> setThresholds(double temp, double hum) async {
    _tempThreshold = temp;
    _humThreshold = hum;
    notifyListeners();

    // Implement sending thresholds to backend API
    try {
      await _apiService.updateThresholds(temp, hum);
      print('Thresholds updated successfully on backend'); // Optional: for debugging
    } catch (e) {
      // Handle error, e.g., show a message to the user
      _errorMessage = 'Failed to update thresholds on backend: $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
      notifyListeners();
    }
  }
}
