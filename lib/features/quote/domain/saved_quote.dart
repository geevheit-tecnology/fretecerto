class SavedQuote {
  const SavedQuote({
    required this.id,
    required this.createdAt,
    required this.customerName,
    required this.sellerName,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.quoteType,
    required this.totalWeightKg,
    required this.totalVolumeM3,
    required this.invoiceValue,
    required this.distanceKm,
    required this.totalDistanceKm,
    required this.suggestedVehicle,
    required this.bodyType,
    required this.validityDays,
    required this.commercialValue,
    required this.operationalCost,
    required this.minimumAnttValue,
    required this.isBelowAntt,
    required this.anttCargoType,
    required this.anttAxles,
    required this.isDieselVehicle,
    required this.isNationalTrip,
    required this.isFullTruckload,
    required this.isVehicleComposition,
    required this.isHighPerformance,
    required this.hasEmptyReturn,
    this.status = 'Pronto para proposta',
  });

  final String id;
  final DateTime createdAt;
  final String customerName;
  final String sellerName;
  final String origin;
  final String destination;
  final String cargoType;
  final String quoteType;
  final double totalWeightKg;
  final double totalVolumeM3;
  final double invoiceValue;
  final double distanceKm;
  final double totalDistanceKm;
  final String suggestedVehicle;
  final String bodyType;
  final int validityDays;
  final double commercialValue;
  final double operationalCost;
  final double minimumAnttValue;
  final bool isBelowAntt;
  final String anttCargoType;
  final int anttAxles;
  final bool isDieselVehicle;
  final bool isNationalTrip;
  final bool isFullTruckload;
  final bool isVehicleComposition;
  final bool isHighPerformance;
  final bool hasEmptyReturn;
  final String status;

  Map<String, dynamic> toInsert() {
    return {
      'customer_name': customerName,
      'seller_name': sellerName,
      'origin': origin,
      'destination': destination,
      'cargo_type': cargoType,
      'quote_type': quoteType,
      'total_weight_kg': totalWeightKg,
      'total_volume_m3': totalVolumeM3,
      'invoice_value': invoiceValue,
      'distance_km': distanceKm,
      'total_distance_km': totalDistanceKm,
      'suggested_vehicle': suggestedVehicle,
      'body_type': bodyType,
      'validity_days': validityDays,
      'commercial_value': commercialValue,
      'operational_cost': operationalCost,
      'minimum_antt_value': minimumAnttValue,
      'is_below_antt': isBelowAntt,
      'antt_cargo_type': anttCargoType,
      'antt_axles': anttAxles,
      'is_diesel_vehicle': isDieselVehicle,
      'is_national_trip': isNationalTrip,
      'is_full_truckload': isFullTruckload,
      'is_vehicle_composition': isVehicleComposition,
      'is_high_performance': isHighPerformance,
      'has_empty_return': hasEmptyReturn,
      'status': status,
    };
  }

  factory SavedQuote.fromMap(Map<String, dynamic> map) {
    return SavedQuote(
      id: map['id'].toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      customerName: map['customer_name']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
      cargoType: map['cargo_type']?.toString() ?? '',
      quoteType: map['quote_type']?.toString() ?? 'Orcamento',
      totalWeightKg: _double(map['total_weight_kg']),
      totalVolumeM3: _double(map['total_volume_m3']),
      invoiceValue: _double(map['invoice_value']),
      distanceKm: _double(map['distance_km']),
      totalDistanceKm: _double(map['total_distance_km']),
      suggestedVehicle: map['suggested_vehicle']?.toString() ?? '',
      bodyType: map['body_type']?.toString() ?? '',
      validityDays: int.tryParse(map['validity_days'].toString()) ?? 7,
      commercialValue: _double(map['commercial_value']),
      operationalCost: _double(map['operational_cost']),
      minimumAnttValue: _double(map['minimum_antt_value']),
      isBelowAntt: map['is_below_antt'] == true,
      anttCargoType: map['antt_cargo_type']?.toString() ?? 'Carga geral',
      anttAxles: int.tryParse(map['antt_axles'].toString()) ?? 2,
      isDieselVehicle: map['is_diesel_vehicle'] != false,
      isNationalTrip: map['is_national_trip'] != false,
      isFullTruckload: map['is_full_truckload'] != false,
      isVehicleComposition: map['is_vehicle_composition'] != false,
      isHighPerformance: map['is_high_performance'] == true,
      hasEmptyReturn: map['has_empty_return'] == true,
      status: map['status']?.toString() ?? 'Pronto para proposta',
    );
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
