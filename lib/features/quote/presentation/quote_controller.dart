import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/freight_calculator.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';
import '../application/location_distance_service.dart';

final freightCalculatorProvider = Provider<FreightCalculator>(
  (_) => const CommercialFreightCalculator(),
);

final locationDistanceServiceProvider = Provider<LocationDistanceService>(
  (_) => GoogleMapsDistanceService(),
);

final quoteInputProvider = NotifierProvider<QuoteInputNotifier, QuoteInput>(
  QuoteInputNotifier.new,
);

final quoteFormProvider = NotifierProvider<QuoteFormNotifier, QuoteFormState>(
  QuoteFormNotifier.new,
);

class QuoteFormState {
  const QuoteFormState({
    this.quoteType = 'Orcamento',
    this.customerName = 'Forte Expressa',
    this.sellerName = 'Comercial interno',
    this.origin = 'Guarulhos, SP',
    this.destination = 'Contagem, MG',
    this.cargoType = 'Carga seca paletizada',
    this.anttCargoType = 'Carga geral',
    this.anttAxles = 2,
    this.isDieselVehicle = true,
    this.isNationalTrip = true,
    this.isFullTruckload = true,
    this.isVehicleComposition = true,
    this.isHighPerformance = false,
    this.hasEmptyReturn = false,
  });

  final String quoteType;
  final String customerName;
  final String sellerName;
  final String origin;
  final String destination;
  final String cargoType;
  final String anttCargoType;
  final int anttAxles;
  final bool isDieselVehicle;
  final bool isNationalTrip;
  final bool isFullTruckload;
  final bool isVehicleComposition;
  final bool isHighPerformance;
  final bool hasEmptyReturn;

  QuoteFormState copyWith({
    String? quoteType,
    String? customerName,
    String? sellerName,
    String? origin,
    String? destination,
    String? cargoType,
    String? anttCargoType,
    int? anttAxles,
    bool? isDieselVehicle,
    bool? isNationalTrip,
    bool? isFullTruckload,
    bool? isVehicleComposition,
    bool? isHighPerformance,
    bool? hasEmptyReturn,
  }) {
    return QuoteFormState(
      quoteType: quoteType ?? this.quoteType,
      customerName: customerName ?? this.customerName,
      sellerName: sellerName ?? this.sellerName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      cargoType: cargoType ?? this.cargoType,
      anttCargoType: anttCargoType ?? this.anttCargoType,
      anttAxles: anttAxles ?? this.anttAxles,
      isDieselVehicle: isDieselVehicle ?? this.isDieselVehicle,
      isNationalTrip: isNationalTrip ?? this.isNationalTrip,
      isFullTruckload: isFullTruckload ?? this.isFullTruckload,
      isVehicleComposition: isVehicleComposition ?? this.isVehicleComposition,
      isHighPerformance: isHighPerformance ?? this.isHighPerformance,
      hasEmptyReturn: hasEmptyReturn ?? this.hasEmptyReturn,
    );
  }
}

class QuoteFormNotifier extends Notifier<QuoteFormState> {
  @override
  QuoteFormState build() => const QuoteFormState();

  void update(QuoteFormState state) {
    this.state = state;
  }
}

class QuoteInputNotifier extends Notifier<QuoteInput> {
  @override
  QuoteInput build() {
    return const QuoteInput(
      distanceKm: 428,
      totalWeightKg: 2400,
      totalVolumeM3: 18,
      invoiceValue: 42000,
      marginPercent: 22,
      toll: 390,
      loadingFee: 180,
      unloadingFee: 220,
      minimumAntt: 5200,
    );
  }

  void replace(QuoteInput input) {
    state = input;
  }
}

final freightQuoteProvider = Provider<FreightQuote>((ref) {
  final calculator = ref.watch(freightCalculatorProvider);
  final input = ref.watch(quoteInputProvider);
  return calculator.calculate(input);
});
