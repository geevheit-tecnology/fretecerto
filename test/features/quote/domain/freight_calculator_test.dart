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
    expect(quote.totalDistanceKm, 856);
    expect(quote.fuelCost, closeTo(2088.64, 0.01));
    expect(quote.arlaCost, closeTo(77.04, 0.01));
    expect(quote.totalVariableCosts, closeTo(3810.28, 0.01));
    expect(quote.totalFixedCosts, closeTo(1285, 0.01));
    expect(quote.operationalCost, closeTo(5095.28, 0.01));
    expect(quote.icmsValue, closeTo(776.19, 0.01));
    expect(quote.pisValue, closeTo(106.73, 0.01));
    expect(quote.cofinsValue, closeTo(491.59, 0.01));
    expect(quote.adValoremValue, closeTo(105, 0.01));
    expect(quote.marginValue, closeTo(1120.96, 0.01));
    expect(quote.commercialValue, closeTo(7842.74, 0.01));
    expect(quote.minimumValuePerKm, closeTo(9.16, 0.01));
    expect(quote.isBelowAntt, isFalse);
  });
}
