import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/quote/domain/quote_input.dart';
import 'package:fretecerto/features/quote/domain/quote_validation.dart';

void main() {
  test('bloqueia cotacao incompleta', () {
    final result = const QuoteValidator().validate(
      input: const QuoteInput(
        distanceKm: 0,
        totalWeightKg: 0,
        totalVolumeM3: 0,
        invoiceValue: 0,
        marginPercent: 20,
      ),
      origin: '',
      destination: '',
      cargoType: '',
      bodyType: 'Aberta',
    );

    expect(result.isValid, isFalse);
    expect(result.messages, contains('Informe a origem.'));
    expect(result.messages, contains('Informe a distancia da rota.'));
    expect(result.messages, contains('Informe o peso da carga.'));
  });

  test('aceita cotacao com dados minimos', () {
    final result = const QuoteValidator().validate(
      input: const QuoteInput(
        distanceKm: 410,
        totalWeightKg: 25000,
        totalVolumeM3: 1,
        invoiceValue: 200000,
        marginPercent: 20,
      ),
      origin: 'Sao Paulo, SP',
      destination: 'Curitiba, PR',
      cargoType: 'Aco',
      bodyType: 'Aberta',
    );

    expect(result.isValid, isTrue);
    expect(result.messages, isEmpty);
  });
}
