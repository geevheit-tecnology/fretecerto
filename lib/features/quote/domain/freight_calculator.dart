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
    final returnDistance = input.returnDistanceKm < 0
        ? 0.0
        : input.returnDistanceKm;
    final totalDistance = outboundDistance + returnDistance;
    final consumption = input.consumptionKmPerLiter <= 0
        ? 1.0
        : input.consumptionKmPerLiter;
    final fuelLiters = totalDistance / consumption;
    final fuelCost = fuelLiters * input.dieselLiterPrice;
    final arlaLiters = fuelLiters * (input.arlaPercent / 100);
    final arlaCost = arlaLiters * input.arlaLiterPrice;
    final maintenance = totalDistance * input.maintenanceCostPerKm;
    final tires = totalDistance * input.tireCostPerKm;
    final toll = input.toll;
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
    final netValue = operational + cargoInsurance + adValorem + margin;
    final taxPercent =
        input.icmsPercent + input.pisPercent + input.cofinsPercent;
    final taxFactor = 1 - (taxPercent / 100);
    final grossValue = taxFactor <= 0 ? netValue : netValue / taxFactor;
    final icms = grossValue * (input.icmsPercent / 100);
    final pis = grossValue * (input.pisPercent / 100);
    final cofins = grossValue * (input.cofinsPercent / 100);
    final antt = input.minimumAntt;
    final commercial = antt > grossValue ? antt : grossValue;

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
      bodyType: 'Definir conforme carga',
      isBelowAntt: antt > 0 && grossValue < antt,
    );
  }

  static String _vehicleFor(double weightKg, double volumeM3) {
    if (weightKg <= 700 && volumeM3 <= 4) return 'Leve - 2 eixos';
    if (weightKg <= 1500 && volumeM3 <= 12) return 'Utilitario - 2 eixos';
    if (weightKg <= 3000 && volumeM3 <= 20) return 'VUC - 2 eixos';
    if (weightKg <= 6000 && volumeM3 <= 32) return 'Toco - 2 eixos';
    if (weightKg <= 14000 && volumeM3 <= 55) return 'Truck - 3 eixos';
    return 'Carreta - 5+ eixos';
  }
}
