import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/freight_calculator.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';
import '../application/location_distance_service.dart';

final freightCalculatorProvider = Provider<FreightCalculator>(
  (_) => const CommercialFreightCalculator(),
);

final locationDistanceServiceProvider = Provider<LocationDistanceService>(
  (_) => OpenRouteServiceDistanceService(),
);

final ibgeLocalityServiceProvider = Provider<IbgeLocalityService>(
  (_) => IbgeLocalityService(),
);

final ibgeMunicipalitiesProvider = FutureProvider<List<IbgeMunicipality>>((
  ref,
) {
  return ref.watch(ibgeLocalityServiceProvider).municipalities();
});

final quoteInputProvider = NotifierProvider<QuoteInputNotifier, QuoteInput>(
  QuoteInputNotifier.new,
);

final quoteFormProvider = NotifierProvider<QuoteFormNotifier, QuoteFormState>(
  QuoteFormNotifier.new,
);

class QuoteFormState {
  const QuoteFormState({
    this.quoteType = 'Orcamento',
    this.customerName = '',
    this.sellerName = 'Comercial interno',
    this.origin = '',
    this.destination = '',
    this.cargoType = '',
    this.bodyType = 'Aberta',
    this.validityDays = 7,
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
  final String bodyType;
  final int validityDays;
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
    String? bodyType,
    int? validityDays,
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
      bodyType: bodyType ?? this.bodyType,
      validityDays: validityDays ?? this.validityDays,
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

  void reset({String quoteType = 'Orcamento'}) {
    state = QuoteFormState(quoteType: quoteType);
  }
}

class QuoteInputNotifier extends Notifier<QuoteInput> {
  @override
  QuoteInput build() {
    return const QuoteInput(
      distanceKm: 0,
      totalWeightKg: 0,
      totalVolumeM3: 0,
      invoiceValue: 0,
      marginPercent: 20,
    );
  }

  void replace(QuoteInput input) {
    state = input;
  }

  void reset() {
    state = state.copyWith(
      distanceKm: 0,
      totalWeightKg: 0,
      totalVolumeM3: 0,
      invoiceValue: 0,
      returnDistanceKm: 0,
      toll: 0,
      loadingFee: 0,
      unloadingFee: 0,
      minimumAntt: 0,
    );
  }
}

final freightQuoteProvider = Provider<FreightQuote>((ref) {
  final calculator = ref.watch(freightCalculatorProvider);
  final input = ref.watch(quoteInputProvider);
  return calculator.calculate(input);
});
