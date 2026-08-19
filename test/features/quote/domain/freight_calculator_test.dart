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

    expect(quote.suggestedVehicle, 'VUC - 2 eixos');
    expect(quote.bodyType, 'Definir conforme carga');
    expect(quote.totalDistanceKm, 428);
    expect(quote.returnDistanceKm, 0);
    expect(quote.fuelCost, closeTo(1044.32, 0.01));
    expect(quote.arlaCost, closeTo(38.52, 0.01));
    expect(quote.totalVariableCosts, closeTo(2187.64, 0.01));
    expect(quote.totalFixedCosts, closeTo(1285, 0.01));
    expect(quote.operationalCost, closeTo(3472.64, 0.01));
    expect(quote.icmsValue, closeTo(683.98, 0.01));
    expect(quote.pisValue, closeTo(94.05, 0.01));
    expect(quote.cofinsValue, closeTo(433.19, 0.01));
    expect(quote.adValoremValue, closeTo(105, 0.01));
    expect(quote.marginValue, closeTo(763.98, 0.01));
    expect(quote.commercialValue, closeTo(5699.84, 0.01));
    expect(quote.minimumValuePerKm, closeTo(13.32, 0.01));
    expect(quote.isBelowAntt, isFalse);
  });

  test('considera retorno somente quando informado', () {
    const calculator = CommercialFreightCalculator();

    final quote = calculator.calculate(
      const QuoteInput(
        distanceKm: 3000,
        returnDistanceKm: 3000,
        totalWeightKg: 25000,
        totalVolumeM3: 1,
        invoiceValue: 200000,
        marginPercent: 20,
      ),
    );

    expect(quote.outboundDistanceKm, 3000);
    expect(quote.returnDistanceKm, 3000);
    expect(quote.totalDistanceKm, 6000);
    expect(quote.suggestedVehicle, 'Carreta - 5+ eixos');
  });
}
