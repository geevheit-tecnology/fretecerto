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

class IbgeMunicipality {
  const IbgeMunicipality({
    required this.id,
    required this.name,
    required this.uf,
  });

  final int id;
  final String name;
  final String uf;

  String get label => '$name, $uf';
}

class IbgeLocalityService {
  IbgeLocalityService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  List<IbgeMunicipality>? _cache;

  Future<List<IbgeMunicipality>> municipalities() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios',
        queryParameters: {'orderBy': 'nome'},
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      final rows = response.data ?? const [];
      final municipalities = rows
          .map(_parseMunicipality)
          .whereType<IbgeMunicipality>()
          .toList(growable: false);
      _cache = municipalities;
      return municipalities;
    } on DioException {
      return const [];
    }
  }

  static IbgeMunicipality? _parseMunicipality(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final name = value['nome'];
    final micro = value['microrregiao'];
    final meso = micro is Map<String, dynamic> ? micro['mesorregiao'] : null;
    final uf = meso is Map<String, dynamic> ? meso['UF'] : null;
    final sigla = uf is Map<String, dynamic> ? uf['sigla'] : null;
    if (id is! num || name is! String || sigla is! String) return null;
    return IbgeMunicipality(id: id.toInt(), name: name, uf: sigla);
  }
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

enum RouteDistanceSource { openRouteService, offlineEstimate }

class OpenRouteServiceDistanceService implements LocationDistanceService {
  OpenRouteServiceDistanceService({
    String apiKey = const String.fromEnvironment('OPENROUTE_SERVICE_API_KEY'),
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
        final origin = await _geocode(originLabel, key);
        final destination = await _geocode(destinationLabel, key);
        if (origin != null && destination != null) {
          final response = await _dio.post<Map<String, dynamic>>(
            'https://api.openrouteservice.org/v2/directions/driving-hgv/json',
            options: Options(headers: {'Authorization': key}),
            data: {
              'coordinates': [
                [origin.longitude, origin.latitude],
                [destination.longitude, destination.latitude],
              ],
              'units': 'km',
            },
          );
          final parsed = _parseOpenRouteService(response.data);
          if (parsed != null) return parsed;
        }
      } on DioException {
        // Falls back to the local estimate so the quote flow keeps working.
      }
    }

    return _fallback.resolveRoadDistance(originLabel, destinationLabel);
  }

  Future<_Coordinate?> _geocode(String query, String key) async {
    final local = _fallback is OfflineLocationDistanceService
        ? OfflineLocationDistanceService.findLocality(query)
        : null;
    if (local != null) {
      return _Coordinate(local.latitude, local.longitude);
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.openrouteservice.org/geocode/search',
      options: Options(headers: {'Authorization': key}),
      queryParameters: {'text': query, 'boundary.country': 'BR', 'size': 1},
    );
    final features = response.data?['features'];
    if (features is! List || features.isEmpty) return null;
    final first = features.first;
    if (first is! Map<String, dynamic>) return null;
    final geometry = first['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final lon = coordinates[0];
    final lat = coordinates[1];
    if (lat is! num || lon is! num) return null;
    return _Coordinate(lat.toDouble(), lon.toDouble());
  }

  static RouteDistanceResult? _parseOpenRouteService(
    Map<String, dynamic>? data,
  ) {
    final routes = data?['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map<String, dynamic>) return null;
    final summary = route['summary'];
    if (summary is! Map<String, dynamic>) return null;
    final distance = summary['distance'];
    if (distance is! num || distance <= 0) return null;
    final duration = summary['duration'];
    return RouteDistanceResult(
      distanceKm: distance.toDouble(),
      source: RouteDistanceSource.openRouteService,
      durationText: duration is num ? _formatDuration(duration) : null,
    );
  }

  static String _formatDuration(num seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}min';
  }
}

class _Coordinate {
  const _Coordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
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
    Locality(
      name: 'Manaus',
      state: 'AM',
      latitude: -3.1190,
      longitude: -60.0217,
    ),
    Locality(
      name: 'Belem',
      state: 'PA',
      latitude: -1.4558,
      longitude: -48.4902,
    ),
    Locality(
      name: 'Sao Luis',
      state: 'MA',
      latitude: -2.5307,
      longitude: -44.3068,
    ),
    Locality(
      name: 'Teresina',
      state: 'PI',
      latitude: -5.0892,
      longitude: -42.8016,
    ),
    Locality(
      name: 'Natal',
      state: 'RN',
      latitude: -5.7793,
      longitude: -35.2009,
    ),
    Locality(
      name: 'Joao Pessoa',
      state: 'PB',
      latitude: -7.1195,
      longitude: -34.8450,
    ),
    Locality(
      name: 'Maceio',
      state: 'AL',
      latitude: -9.6498,
      longitude: -35.7089,
    ),
    Locality(
      name: 'Aracaju',
      state: 'SE',
      latitude: -10.9472,
      longitude: -37.0731,
    ),
    Locality(
      name: 'Vitoria',
      state: 'ES',
      latitude: -20.3155,
      longitude: -40.3128,
    ),
    Locality(
      name: 'Florianopolis',
      state: 'SC',
      latitude: -27.5949,
      longitude: -48.5482,
    ),
    Locality(
      name: 'Campo Grande',
      state: 'MS',
      latitude: -20.4697,
      longitude: -54.6201,
    ),
    Locality(
      name: 'Cuiaba',
      state: 'MT',
      latitude: -15.6014,
      longitude: -56.0979,
    ),
    Locality(
      name: 'Palmas',
      state: 'TO',
      latitude: -10.1840,
      longitude: -48.3336,
    ),
    Locality(
      name: 'Rio Branco',
      state: 'AC',
      latitude: -9.9754,
      longitude: -67.8243,
    ),
    Locality(
      name: 'Porto Velho',
      state: 'RO',
      latitude: -8.7608,
      longitude: -63.8999,
    ),
    Locality(
      name: 'Boa Vista',
      state: 'RR',
      latitude: 2.8235,
      longitude: -60.6758,
    ),
    Locality(
      name: 'Macapa',
      state: 'AP',
      latitude: 0.0349,
      longitude: -51.0694,
    ),
    Locality(
      name: 'Sorocaba',
      state: 'SP',
      latitude: -23.5015,
      longitude: -47.4526,
    ),
    Locality(
      name: 'Sao Jose dos Campos',
      state: 'SP',
      latitude: -23.2237,
      longitude: -45.9009,
    ),
    Locality(
      name: 'Jundiai',
      state: 'SP',
      latitude: -23.1857,
      longitude: -46.8978,
    ),
    Locality(
      name: 'Uberlandia',
      state: 'MG',
      latitude: -18.9128,
      longitude: -48.2755,
    ),
    Locality(
      name: 'Londrina',
      state: 'PR',
      latitude: -23.3045,
      longitude: -51.1696,
    ),
    Locality(
      name: 'Maringa',
      state: 'PR',
      latitude: -23.4205,
      longitude: -51.9331,
    ),
    Locality(
      name: 'Caxias do Sul',
      state: 'RS',
      latitude: -29.1634,
      longitude: -51.1797,
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
    return findLocality(label);
  }

  static Locality? findLocality(String label) {
    final normalized = _normalize(label).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    for (final locality in localities) {
      final name = _normalize(locality.name);
      final state = _normalize(locality.state);
      final full = _normalize(
        locality.label,
      ).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
      if (full == normalized ||
          name == normalized ||
          (normalized.contains(name) && normalized.contains(state))) {
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
