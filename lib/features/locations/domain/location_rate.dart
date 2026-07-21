class LocationRateTable {
  const LocationRateTable({
    required this.customerName,
    required this.origin,
    required this.validUntil,
    required this.rows,
  });

  final String customerName;
  final String origin;
  final DateTime validUntil;
  final List<LocationRateRow> rows;
}

class LocationRateRow {
  const LocationRateRow({
    required this.destination,
    required this.vehicle,
    required this.maxWeightKg,
    required this.deadline,
    required this.price,
    required this.notes,
  });

  final String destination;
  final String vehicle;
  final double maxWeightKg;
  final String deadline;
  final double price;
  final String notes;
}
