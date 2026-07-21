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
}
