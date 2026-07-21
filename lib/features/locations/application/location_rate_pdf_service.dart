import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/formatters/brl.dart';
import '../domain/location_rate.dart';

class LocationRatePdfService {
  const LocationRatePdfService();

  Future<Uint8List> buildTable(LocationRateTable table) async {
    final document = pw.Document(
      title: 'Tabela comercial de localidades',
      author: 'FreteCerto',
    );
    final date = DateFormat('dd/MM/yyyy', 'pt_BR').format(table.validUntil);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
        ),
        build: (_) => [
          _header(table, date),
          pw.SizedBox(height: 18),
          _summary(table),
          pw.SizedBox(height: 16),
          _table(table),
          pw.SizedBox(height: 16),
          _terms(),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'FreteCerto | Tabela ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header(LocationRateTable table, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0E6F68'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tabela de Localidades',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                table.customerName,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
          pw.Text(
            'Validade: $date',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summary(LocationRateTable table) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D8E2E4')),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: _metric('Origem base', table.origin)),
          pw.Expanded(
            child: _metric('Destinos', '${table.rows.length} localidades'),
          ),
          pw.Expanded(child: _metric('Menor valor', brl(_lowestPrice(table)))),
        ],
      ),
    );
  }

  static pw.Widget _metric(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _table(LocationRateTable table) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'Origem',
        'Destino',
        'Veiculo',
        'Peso ate',
        'Prazo',
        'Valor',
        'Obs.',
      ],
      data: table.rows
          .map(
            (row) => [
              table.origin,
              row.destination,
              row.vehicle,
              '${row.maxWeightKg.toStringAsFixed(0)} kg',
              row.deadline,
              brl(row.price),
              row.notes,
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#103B3A')),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerLeft,
      },
    );
  }

  static pw.Widget _terms() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D8E2E4')),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Valores comerciais sujeitos a disponibilidade operacional, validacao cadastral, restricoes de acesso, pedagios especiais, estadia, escolta e alteracoes de combustivel. Tabela nao substitui analise fiscal/contabil.',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
      ),
    );
  }

  static double _lowestPrice(LocationRateTable table) {
    if (table.rows.isEmpty) return 0;
    return table.rows.map((row) => row.price).reduce((a, b) => a < b ? a : b);
  }
}
