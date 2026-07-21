import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/quote/domain/freight_calculator.dart';
import 'package:fretecerto/features/quote/domain/quote_input.dart';

void main() {
  test('calcula frete comercial e recomenda veiculo', () {
    const calculator = CommercialFreightCalculator();

    final quote = calculator.calculate(
      const QuoteInput(
        distanceKm: 428,
        totalWeightKg: 2400,
        totalVolumeM3: 18,
        invoiceValue: 42000,
        marginPercent: 22,
        toll: 390,
        loadingFee: 180,
        unloadingFee: 220,
        minimumAntt: 4850,
      ),
    );

    expect(quote.suggestedVehicle, 'VUC');
    expect(quote.bodyType, 'Bau');
    expect(quote.icmsValue, closeTo(452.84, 0.01));
    expect(quote.pisValue, closeTo(62.27, 0.01));
    expect(quote.cofinsValue, closeTo(286.80, 0.01));
    expect(quote.adValoremValue, closeTo(105, 0.01));
    expect(quote.marginValue, closeTo(635.05, 0.01));
    expect(quote.commercialValue, closeTo(4575.55, 0.01));
    expect(quote.isBelowAntt, isTrue);
  });
}
