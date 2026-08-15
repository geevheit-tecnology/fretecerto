import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/features/customers/application/cep_lookup_service.dart';

void main() {
  test('normaliza CEP para apenas digitos', () {
    expect(CepLookupService.onlyDigits('01001-000'), '01001000');
  });

  test('rejeita CEP incompleto antes de consultar API', () async {
    final service = CepLookupService();

    expect(() => service.lookup('123'), throwsA(isA<CepLookupException>()));
  });
}
