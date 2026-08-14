import 'dart:math' as math;

import 'package:dio/dio.dart';

class Locality {
  const Locality({
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String state;
  final double latitude;
  final double longitude;

  String get label => '$name, $state';
}

abstract interface class LocationDistanceService {
  List<Locality> search(String query);

  double? estimateRoadDistanceKm(String originLabel, String destinationLabel);

  Future<RouteDistanceResult?> resolveRoadDistance(
    String originLabel,
    String destinationLabel,
  );
}

class RouteDistanceResult {
  const RouteDistanceResult({
    required this.distanceKm,
    required this.source,
    this.durationText,
  });

  final double distanceKm;
  final RouteDistanceSource source;
  final String? durationText;
}

enum RouteDistanceSource { googleMaps, offlineEstimate }

class GoogleMapsDistanceService implements LocationDistanceService {
  GoogleMapsDistanceService({
    String apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    Dio? dio,
    LocationDistanceService fallback = const OfflineLocationDistanceService(),
  }) : _apiKey = apiKey,
       _dio = dio ?? Dio(),
       _fallback = fallback;

  final String _apiKey;
  final Dio _dio;
  final LocationDistanceService _fallback;

  @override
  List<Locality> search(String query) => _fallback.search(query);

  @override
  double? estimateRoadDistanceKm(String originLabel, String destinationLabel) {
    return _fallback.estimateRoadDistanceKm(originLabel, destinationLabel);
  }

  @override
  Future<RouteDistanceResult?> resolveRoadDistance(
    String originLabel,
    String destinationLabel,
  ) async {
    final key = _apiKey.trim();
    if (key.isNotEmpty) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/distancematrix/json',
          queryParameters: {
            'origins': originLabel,
            'destinations': destinationLabel,
            'mode': 'driving',
            'units': 'metric',
            'language': 'pt-BR',
            'region': 'br',
            'key': key,
          },
        );
        final parsed = _parseGoogleDistanceMatrix(response.data);
        if (parsed != null) return parsed;
      } on DioException {
        // Falls back to the local estimate so the quote flow keeps working.
      }
    }

    return _fallback.resolveRoadDistance(originLabel, destinationLabel);
  }

  static RouteDistanceResult? _parseGoogleDistanceMatrix(
    Map<String, dynamic>? data,
  ) {
    if (data == null || data['status'] != 'OK') return null;
    final rows = data['rows'];
    if (rows is! List || rows.isEmpty) return null;
    final firstRow = rows.first;
    if (firstRow is! Map<String, dynamic>) return null;
    final elements = firstRow['elements'];
    if (elements is! List || elements.isEmpty) return null;
    final firstElement = elements.first;
    if (firstElement is! Map<String, dynamic>) return null;
    if (firstElement['status'] != 'OK') return null;
    final distance = firstElement['distance'];
    if (distance is! Map<String, dynamic>) return null;
    final meters = distance['value'];
    if (meters is! num || meters <= 0) return null;
    final duration = firstElement['duration'];
    return RouteDistanceResult(
      distanceKm: meters / 1000,
      source: RouteDistanceSource.googleMaps,
      durationText: duration is Map<String, dynamic>
          ? duration['text'] as String?
          : null,
    );
  }
}

class OfflineLocationDistanceService implements LocationDistanceService {
  const OfflineLocationDistanceService();

  static const _roadFactor = 1.24;

  static const localities = [
    Locality(
      name: 'Guarulhos',
      state: 'SP',
      latitude: -23.4543,
      longitude: -46.5337,
    ),
    Locality(
      name: 'Santos',
      state: 'SP',
      latitude: -23.9608,
      longitude: -46.3336,
    ),
    Locality(
      name: 'Campinas',
      state: 'SP',
      latitude: -22.9056,
      longitude: -47.0608,
    ),
    Locality(
      name: 'Ribeirao Preto',
      state: 'SP',
      latitude: -21.1699,
      longitude: -47.8099,
    ),
    Locality(
      name: 'Sao Paulo',
      state: 'SP',
      latitude: -23.5558,
      longitude: -46.6396,
    ),
    Locality(
      name: 'Rio de Janeiro',
      state: 'RJ',
      latitude: -22.9068,
      longitude: -43.1729,
    ),
    Locality(
      name: 'Belo Horizonte',
      state: 'MG',
      latitude: -19.9167,
      longitude: -43.9345,
    ),
    Locality(
      name: 'Contagem',
      state: 'MG',
      latitude: -19.9317,
      longitude: -44.0536,
    ),
    Locality(
      name: 'Curitiba',
      state: 'PR',
      latitude: -25.4284,
      longitude: -49.2733,
    ),
    Locality(
      name: 'Joinville',
      state: 'SC',
      latitude: -26.3044,
      longitude: -48.8487,
    ),
    Locality(
      name: 'Porto Alegre',
      state: 'RS',
      latitude: -30.0346,
      longitude: -51.2177,
    ),
    Locality(
      name: 'Goiania',
      state: 'GO',
      latitude: -16.6869,
      longitude: -49.2648,
    ),
    Locality(
      name: 'Brasilia',
      state: 'DF',
      latitude: -15.7939,
      longitude: -47.8828,
    ),
    Locality(
      name: 'Salvador',
      state: 'BA',
      latitude: -12.9777,
      longitude: -38.5016,
    ),
    Locality(
      name: 'Recife',
      state: 'PE',
      latitude: -8.0476,
      longitude: -34.8770,
    ),
    Locality(
      name: 'Fortaleza',
      state: 'CE',
      latitude: -3.7319,
      longitude: -38.5267,
    ),
  ];

  @override
  List<Locality> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return localities.take(8).toList();
    return localities
        .where((locality) => _normalize(locality.label).contains(normalized))
        .take(8)
        .toList();
  }

  @override
  double? estimateRoadDistanceKm(String originLabel, String destinationLabel) {
    final origin = _find(originLabel);
    final destination = _find(destinationLabel);
    if (origin == null || destination == null) return null;
    return _haversineKm(origin, destination) * _roadFactor;
  }

  @override
  Future<RouteDistanceResult?> resolveRoadDistance(
    String originLabel,
    String destinationLabel,
  ) async {
    final distance = estimateRoadDistanceKm(originLabel, destinationLabel);
    if (distance == null) return null;
    return RouteDistanceResult(
      distanceKm: distance,
      source: RouteDistanceSource.offlineEstimate,
    );
  }

  static Locality? _find(String label) {
    final normalized = _normalize(label);
    for (final locality in localities) {
      if (_normalize(locality.label) == normalized ||
          _normalize(locality.name) == normalized) {
        return locality;
      }
    }
    return null;
  }

  static double _haversineKm(Locality a, Locality b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLon = _degreesToRadians(b.longitude - a.longitude);
    final lat1 = _degreesToRadians(a.latitude);
    final lat2 = _degreesToRadians(b.latitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .trim();
  }
}
