import 'package:dio/dio.dart';

class CnpjLookupResult {
  const CnpjLookupResult({
    required this.cnpj,
    required this.legalName,
    required this.tradeName,
    required this.city,
    required this.state,
    required this.status,
    required this.mainActivity,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.zipCode,
  });

  final String cnpj;
  final String legalName;
  final String tradeName;
  final String city;
  final String state;
  final String status;
  final String mainActivity;
  final String street;
  final String number;
  final String neighborhood;
  final String zipCode;

  String get displayName => tradeName.isEmpty ? legalName : tradeName;

  String get cityState {
    if (city.isEmpty && state.isEmpty) return '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city, $state';
  }

  String get address {
    final parts = [
      street,
      number,
      neighborhood,
      cityState,
      zipCode,
    ].where((part) => part.trim().isNotEmpty);
    return parts.join(' - ');
  }
}

class CnpjLookupService {
  CnpjLookupService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<CnpjLookupResult> lookup(String cnpj) async {
    final digits = onlyDigits(cnpj);
    if (digits.length != 14) {
      throw const CnpjLookupException('Informe um CNPJ com 14 digitos.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://brasilapi.com.br/api/cnpj/v1/$digits',
      );
      final data = response.data;
      if (data == null) {
        throw const CnpjLookupException('CNPJ nao retornou dados.');
      }
      return CnpjLookupResult(
        cnpj: data['cnpj']?.toString() ?? digits,
        legalName: data['razao_social']?.toString() ?? '',
        tradeName: data['nome_fantasia']?.toString() ?? '',
        city: data['municipio']?.toString() ?? '',
        state: data['uf']?.toString() ?? '',
        status: data['descricao_situacao_cadastral']?.toString() ?? '',
        mainActivity: data['cnae_fiscal_descricao']?.toString() ?? '',
        street: data['logradouro']?.toString() ?? '',
        number: data['numero']?.toString() ?? '',
        neighborhood: data['bairro']?.toString() ?? '',
        zipCode: data['cep']?.toString() ?? '',
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 404) {
        throw const CnpjLookupException('CNPJ nao encontrado.');
      }
      throw const CnpjLookupException(
        'Nao foi possivel consultar o CNPJ agora.',
      );
    }
  }

  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class CnpjLookupException implements Exception {
  const CnpjLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
