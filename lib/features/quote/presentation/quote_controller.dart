import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/freight_calculator.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';
import '../application/location_distance_service.dart';

final freightCalculatorProvider = Provider<FreightCalculator>(
  (_) => const CommercialFreightCalculator(),
);

final locationDistanceServiceProvider = Provider<LocationDistanceService>(
  (_) => const OfflineLocationDistanceService(),
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
  });

  final String quoteType;
  final String customerName;
  final String sellerName;
  final String origin;
  final String destination;
  final String cargoType;

  QuoteFormState copyWith({
    String? quoteType,
    String? customerName,
    String? sellerName,
    String? origin,
    String? destination,
    String? cargoType,
  }) {
    return QuoteFormState(
      quoteType: quoteType ?? this.quoteType,
      customerName: customerName ?? this.customerName,
      sellerName: sellerName ?? this.sellerName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      cargoType: cargoType ?? this.cargoType,
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
