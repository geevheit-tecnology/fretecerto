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
    final outboundDistance = input.distanceKm;
    final returnDistance = input.distanceKm;
    final totalDistance = outboundDistance + returnDistance;
    final fuelLiters = totalDistance / input.consumptionKmPerLiter;
    final fuelCost = fuelLiters * input.dieselLiterPrice;
    final arlaLiters = fuelLiters * (input.arlaPercent / 100);
    final arlaCost = arlaLiters * input.arlaLiterPrice;
    final maintenance = totalDistance * input.maintenanceCostPerKm;
    final tires = totalDistance * input.tireCostPerKm;
    final toll = input.toll * 2;
    final variableCosts =
        fuelCost +
        arlaCost +
        toll +
        maintenance +
        tires +
        input.loadingFee +
        input.unloadingFee +
        input.trackingFee +
        input.otherVariableCosts;
    final monthlyTrips = input.monthlyTrips <= 0 ? 1 : input.monthlyTrips;
    final depreciation = input.vehicleDepreciationMonthly / monthlyTrips;
    final driverSalary = input.driverSalaryMonthly / monthlyTrips;
    final driverBurden =
        (input.driverSalaryMonthly * (input.driverBurdenPercent / 100)) /
        monthlyTrips;
    final vehicleInsurance = (input.vehicleInsuranceYearly / 12) / monthlyTrips;
    final administrative = input.administrativeCostsMonthly / monthlyTrips;
    final fixedCosts =
        depreciation +
        driverSalary +
        driverBurden +
        vehicleInsurance +
        administrative +
        input.otherFixedCostsPerTrip;
    final operational = variableCosts + fixedCosts;
    final cargoInsurance = input.invoiceValue * (input.insurancePercent / 100);
    final adValorem = input.invoiceValue * (input.adValoremPercent / 100);
    final margin = operational * (input.marginPercent / 100);
    final taxBase = operational + cargoInsurance + adValorem + margin;
    final icms = taxBase * (input.icmsPercent / 100);
    final pis = taxBase * (input.pisPercent / 100);
    final cofins = taxBase * (input.cofinsPercent / 100);
    final commercial = taxBase + icms + pis + cofins;
    final antt = input.minimumAntt;

    return FreightQuote(
      operationalCost: operational,
      outboundDistanceKm: outboundDistance,
      returnDistanceKm: returnDistance,
      totalDistanceKm: totalDistance,
      fuelLiters: fuelLiters,
      fuelCost: fuelCost,
      arlaLiters: arlaLiters,
      arlaCost: arlaCost,
      tollCost: toll,
      maintenanceCost: maintenance,
      tireCost: tires,
      otherVariableCosts: input.otherVariableCosts,
      totalVariableCosts: variableCosts,
      vehicleDepreciationCost: depreciation,
      driverSalaryCost: driverSalary,
      driverBurdenCost: driverBurden,
      vehicleInsuranceCost: vehicleInsurance,
      administrativeCost: administrative,
      otherFixedCosts: input.otherFixedCostsPerTrip,
      totalFixedCosts: fixedCosts,
      icmsValue: icms,
      pisValue: pis,
      cofinsValue: cofins,
      adValoremValue: adValorem,
      insuranceValue: cargoInsurance,
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
}
