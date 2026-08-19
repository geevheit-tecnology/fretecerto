import 'quote_input.dart';

class QuoteValidationResult {
  const QuoteValidationResult(this.messages);

  final List<String> messages;

  bool get isValid => messages.isEmpty;
}

class QuoteValidator {
  const QuoteValidator();

  QuoteValidationResult validate({
    required QuoteInput input,
    required String origin,
    required String destination,
    required String cargoType,
    required String bodyType,
  }) {
    final messages = <String>[];
    if (origin.trim().isEmpty) messages.add('Informe a origem.');
    if (destination.trim().isEmpty) messages.add('Informe o destino.');
    if (origin.trim().isNotEmpty &&
        destination.trim().isNotEmpty &&
        origin.trim().toLowerCase() == destination.trim().toLowerCase()) {
      messages.add('Origem e destino precisam ser diferentes.');
    }
    if (cargoType.trim().isEmpty) messages.add('Informe o tipo de carga.');
    if (bodyType.trim().isEmpty) messages.add('Informe a carroceria.');
    if (input.distanceKm <= 0) messages.add('Informe a distancia da rota.');
    if (input.totalWeightKg <= 0) messages.add('Informe o peso da carga.');
    if (input.marginPercent < 0) {
      messages.add('A margem nao pode ser negativa.');
    }
    if (input.consumptionKmPerLiter <= 0) {
      messages.add('Configure o consumo do veiculo em km/l.');
    }
    return QuoteValidationResult(messages);
  }
}
