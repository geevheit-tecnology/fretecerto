import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/quote/application/quote_pdf_service.dart';
import 'package:fretecerto/features/quote/domain/freight_calculator.dart';
import 'package:fretecerto/features/quote/domain/quote_input.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('gera pdf executivo de proposta comercial', () async {
    await initializeDateFormatting('pt_BR');
    const input = QuoteInput(
      distanceKm: 428,
      totalWeightKg: 2400,
      totalVolumeM3: 18,
      invoiceValue: 42000,
      marginPercent: 22,
      toll: 390,
      loadingFee: 180,
      unloadingFee: 220,
      minimumAntt: 4850,
    );
    final quote = const CommercialFreightCalculator().calculate(input);

    final bytes = await const QuotePdfService().buildExecutiveQuote(
      input: input,
      quote: quote,
    );

    expect(bytes.length, greaterThan(5000));
    expect(bytes.take(4), [37, 80, 68, 70]);
  });
}
