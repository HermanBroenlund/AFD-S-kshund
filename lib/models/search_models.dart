import 'package:latlong2/latlong.dart';

enum SearchStatus { planned, active, paused, completed, cancelled }

class SearchDraft {
  const SearchDraft({
    this.id,
    required this.companyName,
    required this.organizationNumber,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.dogId,
    required this.handlerId,
    required this.plannedDate,
    required this.area,
    this.notes,
  });

  final String? id;
  final String companyName;
  final String organizationNumber;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String dogId;
  final String handlerId;
  final DateTime plannedDate;
  final List<LatLng> area;
  final String? notes;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.windSpeedMs,
    required this.windDirectionDeg,
    required this.humidityPercent,
    required this.airPressureHpa,
    required this.precipitationMm,
    required this.fetchedAt,
  });

  final double? temperatureC;
  final double? windSpeedMs;
  final double? windDirectionDeg;
  final double? humidityPercent;
  final double? airPressureHpa;
  final double? precipitationMm;
  final DateTime fetchedAt;
}
