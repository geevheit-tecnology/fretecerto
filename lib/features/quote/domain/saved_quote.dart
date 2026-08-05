class SavedQuote {
  const SavedQuote({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.suggestedVehicle,
    required this.commercialValue,
    required this.minimumAnttValue,
    required this.isBelowAntt,
  });

  final String id;
  final DateTime createdAt;
  final String customerName;
  final String origin;
  final String destination;
  final String cargoType;
  final String suggestedVehicle;
  final double commercialValue;
  final double minimumAnttValue;
  final bool isBelowAntt;
}
