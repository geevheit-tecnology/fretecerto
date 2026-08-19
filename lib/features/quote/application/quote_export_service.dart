import 'dart:convert';
import 'dart:typed_data';

import '../../../core/formatters/brl.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';

class QuoteExportService {
  const QuoteExportService();

  Uint8List buildExcelCsv({
    required QuoteInput input,
    required FreightQuote quote,
    required String quoteType,
    required String customerName,
    required String sellerName,
    required String origin,
    required String destination,
    required String cargoType,
    String? bodyType,
    int validityDays = 7,
  }) {
    final resolvedBodyType = bodyType?.trim().isNotEmpty == true
        ? bodyType!.trim()
        : quote.bodyType;
    final rows = [
      ['Campo', 'Valor'],
      ['Tipo', quoteType],
      ['Cliente', customerName],
      ['Vendedor', sellerName],
      ['Origem', origin],
      ['Destino', destination],
      ['Carga', cargoType],
      ['Peso kg', input.totalWeightKg.toStringAsFixed(0)],
      ['Cubagem m3', input.totalVolumeM3.toStringAsFixed(1)],
      ['Valor NF', brl(input.invoiceValue)],
      ['Porte operacional', quote.suggestedVehicle],
      ['Carroceria', resolvedBodyType],
      ['Validade dias', validityDays.toString()],
      ['Distancia da rota km', quote.outboundDistanceKm.toStringAsFixed(0)],
      ['Retorno vazio km', quote.returnDistanceKm.toStringAsFixed(0)],
      ['Km considerado no custo', quote.totalDistanceKm.toStringAsFixed(0)],
      ['Custo operacional', brl(quote.operationalCost)],
      ['Custos variaveis', brl(quote.totalVariableCosts)],
      ['Custos fixos', brl(quote.totalFixedCosts)],
      ['Seguro', brl(quote.insuranceValue)],
      ['Ad valorem', brl(quote.adValoremValue)],
      ['Margem', brl(quote.marginValue)],
      ['ICMS', brl(quote.icmsValue)],
      ['PIS', brl(quote.pisValue)],
      ['COFINS', brl(quote.cofinsValue)],
      ['Piso ANTT', brl(quote.minimumAnttValue)],
      ['Valor final', brl(quote.commercialValue)],
    ];
    final csv = rows.map((row) => row.map(_cell).join(';')).join('\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$csv'));
  }

  static String _cell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
