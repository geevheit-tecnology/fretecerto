class FreightQuote {
  const FreightQuote({
    required this.operationalCost,
    required this.outboundDistanceKm,
    required this.returnDistanceKm,
    required this.totalDistanceKm,
    required this.fuelLiters,
    required this.fuelCost,
    required this.arlaLiters,
    required this.arlaCost,
    required this.tollCost,
    required this.maintenanceCost,
    required this.tireCost,
    required this.otherVariableCosts,
    required this.totalVariableCosts,
    required this.vehicleDepreciationCost,
    required this.driverSalaryCost,
    required this.driverBurdenCost,
    required this.vehicleInsuranceCost,
    required this.administrativeCost,
    required this.otherFixedCosts,
    required this.totalFixedCosts,
    required this.icmsValue,
    required this.pisValue,
    required this.cofinsValue,
    required this.adValoremValue,
    required this.insuranceValue,
    required this.marginValue,
    required this.minimumAnttValue,
    required this.commercialValue,
    required this.suggestedVehicle,
    required this.bodyType,
    required this.isBelowAntt,
  });

  final double operationalCost;
  final double outboundDistanceKm;
  final double returnDistanceKm;
  final double totalDistanceKm;
  final double fuelLiters;
  final double fuelCost;
  final double arlaLiters;
  final double arlaCost;
  final double tollCost;
  final double maintenanceCost;
  final double tireCost;
  final double otherVariableCosts;
  final double totalVariableCosts;
  final double vehicleDepreciationCost;
  final double driverSalaryCost;
  final double driverBurdenCost;
  final double vehicleInsuranceCost;
  final double administrativeCost;
  final double otherFixedCosts;
  final double totalFixedCosts;
  final double icmsValue;
  final double pisValue;
  final double cofinsValue;
  final double adValoremValue;
  final double insuranceValue;
  final double marginValue;
  final double minimumAnttValue;
  final double commercialValue;
  final String suggestedVehicle;
  final String bodyType;
  final bool isBelowAntt;

  double get taxValue => icmsValue + pisValue + cofinsValue;
  double get minimumValuePerKm =>
      totalDistanceKm <= 0 ? 0 : commercialValue / totalDistanceKm;
  double get costPerKm =>
      totalDistanceKm <= 0 ? 0 : operationalCost / totalDistanceKm;
}
