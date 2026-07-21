import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/locations/application/location_rate_pdf_service.dart';
import 'package:fretecerto/features/locations/domain/location_rate.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('gera pdf executivo de tabela de localidades', () async {
    await initializeDateFormatting('pt_BR');
    final table = LocationRateTable(
      customerName: 'Forte Expressa Transportes',
      origin: 'Guarulhos, SP',
      validUntil: DateTime(2026, 8, 20),
      rows: const [
        LocationRateRow(
          destination: 'Campinas, SP',
          vehicle: 'VUC',
          maxWeightKg: 3000,
          deadline: '1 dia',
          price: 1250,
          notes: 'Coleta agendada',
        ),
      ],
    );

    final bytes = await const LocationRatePdfService().buildTable(table);

    expect(bytes.length, greaterThan(4000));
    expect(bytes.take(4), [37, 80, 68, 70]);
  });
}
