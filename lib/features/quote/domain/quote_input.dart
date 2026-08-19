class QuoteInput {
  const QuoteInput({
    required this.distanceKm,
    required this.totalWeightKg,
    required this.totalVolumeM3,
    required this.invoiceValue,
    required this.marginPercent,
    this.returnDistanceKm = 0,
    this.toll = 0,
    this.loadingFee = 0,
    this.unloadingFee = 0,
    this.icmsPercent = 12,
    this.pisPercent = 1.65,
    this.cofinsPercent = 7.6,
    this.adValoremPercent = 0.25,
    this.insurancePercent = 0.35,
    this.trackingFee = 85,
    this.minimumAntt = 0,
    this.consumptionKmPerLiter = 2.5,
    this.dieselLiterPrice = 6.1,
    this.arlaPercent = 5,
    this.arlaLiterPrice = 4.5,
    this.maintenanceCostPerKm = 0.2,
    this.tireCostPerKm = 0.15,
    this.otherVariableCosts = 80,
    this.vehicleDepreciationMonthly = 10000,
    this.driverSalaryMonthly = 3000,
    this.driverBurdenPercent = 70,
    this.vehicleInsuranceYearly = 12000,
    this.administrativeCostsMonthly = 8000,
    this.otherFixedCostsPerTrip = 80,
    this.monthlyTrips = 20,
  });

  final double distanceKm;
  final double totalWeightKg;
  final double totalVolumeM3;
  final double invoiceValue;
  final double marginPercent;
  final double returnDistanceKm;
  final double toll;
  final double loadingFee;
  final double unloadingFee;
  final double icmsPercent;
  final double pisPercent;
  final double cofinsPercent;
  final double adValoremPercent;
  final double insurancePercent;
  final double trackingFee;
  final double minimumAntt;
  final double consumptionKmPerLiter;
  final double dieselLiterPrice;
  final double arlaPercent;
  final double arlaLiterPrice;
  final double maintenanceCostPerKm;
  final double tireCostPerKm;
  final double otherVariableCosts;
  final double vehicleDepreciationMonthly;
  final double driverSalaryMonthly;
  final double driverBurdenPercent;
  final double vehicleInsuranceYearly;
  final double administrativeCostsMonthly;
  final double otherFixedCostsPerTrip;
  final double monthlyTrips;

  QuoteInput copyWith({
    double? distanceKm,
    double? totalWeightKg,
    double? totalVolumeM3,
    double? invoiceValue,
    double? marginPercent,
    double? returnDistanceKm,
    double? toll,
    double? loadingFee,
    double? unloadingFee,
    double? icmsPercent,
    double? pisPercent,
    double? cofinsPercent,
    double? adValoremPercent,
    double? insurancePercent,
    double? trackingFee,
    double? minimumAntt,
    double? consumptionKmPerLiter,
    double? dieselLiterPrice,
    double? arlaPercent,
    double? arlaLiterPrice,
    double? maintenanceCostPerKm,
    double? tireCostPerKm,
    double? otherVariableCosts,
    double? vehicleDepreciationMonthly,
    double? driverSalaryMonthly,
    double? driverBurdenPercent,
    double? vehicleInsuranceYearly,
    double? administrativeCostsMonthly,
    double? otherFixedCostsPerTrip,
    double? monthlyTrips,
  }) {
    return QuoteInput(
      distanceKm: distanceKm ?? this.distanceKm,
      totalWeightKg: totalWeightKg ?? this.totalWeightKg,
      totalVolumeM3: totalVolumeM3 ?? this.totalVolumeM3,
      invoiceValue: invoiceValue ?? this.invoiceValue,
      marginPercent: marginPercent ?? this.marginPercent,
      returnDistanceKm: returnDistanceKm ?? this.returnDistanceKm,
      toll: toll ?? this.toll,
      loadingFee: loadingFee ?? this.loadingFee,
      unloadingFee: unloadingFee ?? this.unloadingFee,
      icmsPercent: icmsPercent ?? this.icmsPercent,
      pisPercent: pisPercent ?? this.pisPercent,
      cofinsPercent: cofinsPercent ?? this.cofinsPercent,
      adValoremPercent: adValoremPercent ?? this.adValoremPercent,
      insurancePercent: insurancePercent ?? this.insurancePercent,
      trackingFee: trackingFee ?? this.trackingFee,
      minimumAntt: minimumAntt ?? this.minimumAntt,
      consumptionKmPerLiter:
          consumptionKmPerLiter ?? this.consumptionKmPerLiter,
      dieselLiterPrice: dieselLiterPrice ?? this.dieselLiterPrice,
      arlaPercent: arlaPercent ?? this.arlaPercent,
      arlaLiterPrice: arlaLiterPrice ?? this.arlaLiterPrice,
      maintenanceCostPerKm: maintenanceCostPerKm ?? this.maintenanceCostPerKm,
      tireCostPerKm: tireCostPerKm ?? this.tireCostPerKm,
      otherVariableCosts: otherVariableCosts ?? this.otherVariableCosts,
      vehicleDepreciationMonthly:
          vehicleDepreciationMonthly ?? this.vehicleDepreciationMonthly,
      driverSalaryMonthly: driverSalaryMonthly ?? this.driverSalaryMonthly,
      driverBurdenPercent: driverBurdenPercent ?? this.driverBurdenPercent,
      vehicleInsuranceYearly:
          vehicleInsuranceYearly ?? this.vehicleInsuranceYearly,
      administrativeCostsMonthly:
          administrativeCostsMonthly ?? this.administrativeCostsMonthly,
      otherFixedCostsPerTrip:
          otherFixedCostsPerTrip ?? this.otherFixedCostsPerTrip,
      monthlyTrips: monthlyTrips ?? this.monthlyTrips,
    );
  }
}
