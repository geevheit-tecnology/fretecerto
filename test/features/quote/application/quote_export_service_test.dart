import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/quote/application/quote_export_service.dart';
import 'package:fretecerto/features/quote/domain/freight_calculator.dart';
import 'package:fretecerto/features/quote/domain/quote_input.dart';

void main() {
  test('gera CSV compativel com Excel para proposta', () {
    const input = QuoteInput(
      distanceKm: 428,
      totalWeightKg: 2400,
      totalVolumeM3: 18,
      invoiceValue: 42000,
      marginPercent: 22,
    );
    final quote = const CommercialFreightCalculator().calculate(input);

    final bytes = const QuoteExportService().buildExcelCsv(
      input: input,
      quote: quote,
      quoteType: 'Proposta',
      customerName: 'Cliente Teste',
      sellerName: 'Comercial',
      origin: 'Guarulhos, SP',
      destination: 'Contagem, MG',
      cargoType: 'Carga seca',
    );
    final csv = utf8.decode(bytes);

    expect(csv, contains('Cliente Teste'));
    expect(csv, contains('Guarulhos, SP'));
    expect(csv, contains('Valor final'));
    expect(csv, contains(quote.suggestedVehicle));
  });
}
