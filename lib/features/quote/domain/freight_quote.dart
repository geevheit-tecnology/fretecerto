class FreightQuote {
  const FreightQuote({
    required this.operationalCost,
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
}
