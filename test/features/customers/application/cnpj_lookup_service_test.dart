import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/customers/application/cnpj_lookup_service.dart';

void main() {
  test('normaliza CNPJ para apenas digitos', () {
    expect(
      CnpjLookupService.onlyDigits('12.345.678/0001-90'),
      '12345678000190',
    );
  });

  test('rejeita CNPJ incompleto antes de consultar API', () async {
    final service = CnpjLookupService();

    expect(() => service.lookup('123'), throwsA(isA<CnpjLookupException>()));
  });
}
