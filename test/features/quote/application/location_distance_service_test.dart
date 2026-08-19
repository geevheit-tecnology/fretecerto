import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/quote/application/location_distance_service.dart';

void main() {
  test('consulta localidade e estima distancia rodoviaria', () {
    const service = OfflineLocationDistanceService();

    final results = service.search('Santos');
    final distance = service.estimateRoadDistanceKm(
      'Santos, SP',
      'Ribeirao Preto, SP',
    );

    expect(results.single.label, 'Santos, SP');
    expect(distance, isNotNull);
    expect(distance!, greaterThan(300));
    expect(distance, lessThan(500));
  });

  test('servico de mapa usa fallback local quando nao existe chave', () async {
    final service = OpenRouteServiceDistanceService(apiKey: '');

    final result = await service.resolveRoadDistance(
      'Santos, SP',
      'Ribeirao Preto, SP',
    );

    expect(result, isNotNull);
    expect(result!.source, RouteDistanceSource.offlineEstimate);
    expect(result.distanceKm, greaterThan(300));
    expect(result.distanceKm, lessThan(500));
  });
}
