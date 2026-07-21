import 'freight_quote.dart';
import 'quote_input.dart';

abstract interface class FreightCalculator {
  FreightQuote calculate(QuoteInput input);
}

class CommercialFreightCalculator implements FreightCalculator {
  const CommercialFreightCalculator();

  @override
  FreightQuote calculate(QuoteInput input) {
    final vehicle = _vehicleFor(input.totalWeightKg, input.totalVolumeM3);
    final kmCost = _kmCostFor(vehicle);
    final operational =
        (input.distanceKm * kmCost) +
        input.toll +
        input.loadingFee +
        input.unloadingFee +
        input.trackingFee;
    final insurance = input.invoiceValue * (input.insurancePercent / 100);
    final adValorem = input.invoiceValue * (input.adValoremPercent / 100);
    final margin = operational * (input.marginPercent / 100);
    final taxBase = operational + insurance + adValorem + margin;
    final icms = taxBase * (input.icmsPercent / 100);
    final pis = taxBase * (input.pisPercent / 100);
    final cofins = taxBase * (input.cofinsPercent / 100);
    final commercial = taxBase + icms + pis + cofins;
    final antt = input.minimumAntt;

    return FreightQuote(
      operationalCost: operational,
      icmsValue: icms,
      pisValue: pis,
      cofinsValue: cofins,
      adValoremValue: adValorem,
      insuranceValue: insurance,
      marginValue: margin,
      minimumAnttValue: antt,
      commercialValue: commercial,
      suggestedVehicle: vehicle,
      bodyType: input.totalVolumeM3 > 28 ? 'Sider' : 'Bau',
      isBelowAntt: antt > 0 && commercial < antt,
    );
  }

  static String _vehicleFor(double weightKg, double volumeM3) {
    if (weightKg <= 700 && volumeM3 <= 4) return 'Fiorino';
    if (weightKg <= 1500 && volumeM3 <= 12) return 'Van';
    if (weightKg <= 3000 && volumeM3 <= 20) return 'VUC';
    if (weightKg <= 6000 && volumeM3 <= 32) return 'Toco';
    if (weightKg <= 14000 && volumeM3 <= 55) return 'Truck';
    return 'Carreta simples';
  }

  static double _kmCostFor(String vehicle) => switch (vehicle) {
    'Fiorino' => 2.8,
    'Van' => 3.6,
    'VUC' => 4.7,
    'Toco' => 6.1,
    'Truck' => 7.9,
    _ => 10.4,
  };
}
