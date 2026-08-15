import 'package:dio/dio.dart';

class CepLookupResult {
  const CepLookupResult({
    required this.cep,
    required this.state,
    required this.city,
    required this.neighborhood,
    required this.street,
  });

  final String cep;
  final String state;
  final String city;
  final String neighborhood;
  final String street;

  String get cityState {
    if (city.isEmpty && state.isEmpty) return '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city, $state';
  }

  String get address {
    final parts = [
      street,
      neighborhood,
      cityState,
      cep,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(' - ');
  }
}

class CepLookupService {
  CepLookupService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<CepLookupResult> lookup(String cep) async {
    final digits = onlyDigits(cep);
    if (digits.length != 8) {
      throw const CepLookupException('Informe um CEP com 8 digitos.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://brasilapi.com.br/api/cep/v1/$digits',
      );
      final data = response.data;
      if (data == null) {
        throw const CepLookupException('CEP nao retornou dados.');
      }
      return CepLookupResult(
        cep: data['cep']?.toString() ?? digits,
        state: data['state']?.toString() ?? '',
        city: data['city']?.toString() ?? '',
        neighborhood: data['neighborhood']?.toString() ?? '',
        street: data['street']?.toString() ?? '',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const CepLookupException('CEP nao encontrado.');
      }
      throw const CepLookupException('Nao foi possivel consultar o CEP agora.');
    }
  }

  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class CepLookupException implements Exception {
  const CepLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
