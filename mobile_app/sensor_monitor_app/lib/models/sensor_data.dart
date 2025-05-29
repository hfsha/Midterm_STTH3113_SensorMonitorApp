class SensorData {
  final int recordId;
  final int deviceId;
  final double temperature;
  final double humidity;
  final String relayStatus;
  final DateTime createdAt;

  SensorData({
    required this.recordId,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.relayStatus,
    required this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      recordId: json['record_id'],
      deviceId: json['device_id'],
      temperature: double.parse(json['temperature'].toString()),
      humidity: double.parse(json['humidity'].toString()),
      relayStatus: json['relay_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
