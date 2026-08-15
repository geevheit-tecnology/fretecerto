import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/formatters/brl.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';

class QuotePdfService {
  const QuotePdfService();

  Future<Uint8List> buildExecutiveQuote({
    required QuoteInput input,
    required FreightQuote quote,
    String quoteType = 'Orcamento comercial',
    String customerName = 'Forte Expressa',
    String sellerName = 'Comercial interno',
    String origin = 'Guarulhos, SP',
    String destination = 'Contagem, MG',
    String cargoType = 'Carga seca paletizada',
    String anttCargoType = 'Carga geral',
    int anttAxles = 2,
    bool isDieselVehicle = true,
    bool isNationalTrip = true,
    bool isFullTruckload = true,
    bool isVehicleComposition = true,
    bool isHighPerformance = false,
    bool hasEmptyReturn = false,
  }) async {
    final document = pw.Document(
      title: 'Proposta comercial de frete',
      author: 'FreteCerto',
      subject: 'Orcamento executivo de frete rodoviario',
    );
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
      'pt_BR',
    ).format(DateTime.now());

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
        ),
        build: (context) => [
          _header(generatedAt),
          pw.SizedBox(height: 22),
          _heroSummary(quote),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _section('Cliente e validade', [
                  _line('Solicitante', customerName),
                  _line('Tipo', quoteType),
                  _line('Vendedor', sellerName),
                  _line('Validade', '7 dias corridos'),
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _section('Rota operacional', [
                  _line('Origem', origin),
                  _line('Destino', destination),
                  _line(
                    'Distancia total',
                    '${quote.totalDistanceKm.toStringAsFixed(0)} km',
                  ),
                  _line(
                    'Ida',
                    '${quote.outboundDistanceKm.toStringAsFixed(0)} km',
                  ),
                  _line(
                    'Retorno',
                    '${quote.returnDistanceKm.toStringAsFixed(0)} km',
                  ),
                  _line('Modalidade', 'Rodoviario dedicado'),
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _section('Carga e recomendacao', [
            _line('Descricao', cargoType),
            _line('Tipo ANTT', anttCargoType),
            _line('Peso total', '${input.totalWeightKg.toStringAsFixed(0)} kg'),
            _line('Cubagem', '${input.totalVolumeM3.toStringAsFixed(1)} m3'),
            _line('Porte operacional', quote.suggestedVehicle),
            _line('Eixos ANTT', '$anttAxles eixos'),
            _line('Carroceria', quote.bodyType),
            _line('Valor aproximado da NF', brl(input.invoiceValue)),
          ]),
          pw.SizedBox(height: 14),
          _section('Conferencia ANTT', [
            _line('Transporte nacional', _yesNo(isNationalTrip)),
            _line('Veiculo diesel', _yesNo(isDieselVehicle)),
            _line('Carga lotacao', _yesNo(isFullTruckload)),
            _line('Composicao veicular', _yesNo(isVehicleComposition)),
            _line('Alto desempenho', _yesNo(isHighPerformance)),
            _line('Retorno vazio', _yesNo(hasEmptyReturn)),
            _line('Piso informado', brl(quote.minimumAnttValue)),
            _line(
              'Status',
              quote.isBelowAntt
                  ? 'Abaixo do piso informado'
                  : 'Acima do piso informado',
            ),
          ]),
          pw.SizedBox(height: 14),
          _commercialTable(input, quote),
          pw.SizedBox(height: 16),
          _anttBox(quote),
          pw.SizedBox(height: 16),
          _terms(),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'FreteCerto | Proposta ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildFreightContract({
    required QuoteInput input,
    required FreightQuote quote,
    required String quoteType,
    required String customerName,
    required String sellerName,
    required String origin,
    required String destination,
    required String cargoType,
    String anttCargoType = 'Carga geral',
    int anttAxles = 2,
    bool isDieselVehicle = true,
    bool isNationalTrip = true,
    bool isFullTruckload = true,
    bool isVehicleComposition = true,
    bool isHighPerformance = false,
    bool hasEmptyReturn = false,
  }) async {
    final document = pw.Document(
      title: 'Contrato de prestacao de servico de transporte',
      author: 'FreteCerto',
      subject: 'Minuta comercial gerada a partir da cotacao',
    );
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
      'pt_BR',
    ).format(DateTime.now());

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
        ),
        build: (context) => [
          _header(generatedAt),
          pw.SizedBox(height: 18),
          pw.Text(
            'Minuta de contrato de transporte rodoviario de cargas',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#103B3A'),
            ),
          ),
          pw.SizedBox(height: 12),
          _section('Partes', [
            _line('Contratante', customerName),
            _line('Contratada', 'FreteCerto / transportadora responsavel'),
            _line('Responsavel comercial', sellerName),
            _line('Documento base', quoteType),
          ]),
          pw.SizedBox(height: 12),
          _section('Objeto', [
            _paragraph(
              'Prestacao de servico de transporte rodoviario de cargas, contemplando coleta, deslocamento e entrega conforme os dados operacionais desta cotacao.',
            ),
            _line('Origem', origin),
            _line('Destino', destination),
            _line('Carga', cargoType),
            _line('Tipo ANTT', anttCargoType),
            _line('Peso total', '${input.totalWeightKg.toStringAsFixed(0)} kg'),
            _line('Cubagem', '${input.totalVolumeM3.toStringAsFixed(1)} m3'),
            _line('Porte operacional', quote.suggestedVehicle),
            _line('Eixos ANTT', '$anttAxles eixos'),
            _line('Carroceria', quote.bodyType),
          ]),
          pw.SizedBox(height: 12),
          _section('Preco e condicoes', [
            _line('Valor do frete', brl(quote.commercialValue)),
            _line(
              'Distancia total estimada',
              '${quote.totalDistanceKm.toStringAsFixed(0)} km',
            ),
            _line('Transporte nacional', _yesNo(isNationalTrip)),
            _line('Veiculo diesel', _yesNo(isDieselVehicle)),
            _line('Carga lotacao', _yesNo(isFullTruckload)),
            _line('Composicao veicular', _yesNo(isVehicleComposition)),
            _line('Alto desempenho', _yesNo(isHighPerformance)),
            _line('Retorno vazio', _yesNo(hasEmptyReturn)),
            _line('Piso ANTT informado', brl(quote.minimumAnttValue)),
            _line('Validade da proposta', '7 dias corridos'),
            _line(
              'Impostos e taxas',
              'Incluidos conforme parametros informados na cotacao',
            ),
          ]),
          pw.SizedBox(height: 12),
          _section('Clausulas operacionais', [
            _paragraph(
              '1. A execucao do transporte depende de confirmacao cadastral, disponibilidade operacional, liberacao documental e validacao fiscal.',
            ),
            _paragraph(
              '2. Custos nao informados, como estadia, reentrega, armazenagem, escolta, ajudantes, restricoes de acesso ou espera excedente, poderao ser cobrados separadamente.',
            ),
            _paragraph(
              '3. A carroceria sera definida pelas partes conforme natureza da carga, necessidade de protecao, forma de carregamento e regras do embarcador.',
            ),
            _paragraph(
              '4. A contratante declara que as informacoes de carga, nota fiscal, origem e destino foram prestadas corretamente para composicao do valor.',
            ),
            _paragraph(
              '5. Esta minuta deve ser revisada juridicamente antes da assinatura definitiva.',
            ),
          ]),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [_signature('Contratante'), _signature('Contratada')],
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'FreteCerto | Contrato ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String generatedAt) {
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
                'FreteCerto',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Proposta comercial de frete rodoviario',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
          pw.Text(
            'Emitido em $generatedAt',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _heroSummary(FreightQuote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D8E2E4')),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Valor comercial sugerido', style: _labelStyle()),
              pw.SizedBox(height: 6),
              pw.Text(
                brl(quote.commercialValue),
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#103B3A'),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Porte operacional', style: _labelStyle()),
              pw.Text(quote.suggestedVehicle, style: _valueStyle()),
              pw.SizedBox(height: 8),
              pw.Text('Carroceria', style: _labelStyle()),
              pw.Text(quote.bodyType, style: _valueStyle()),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _commercialTable(QuoteInput input, FreightQuote quote) {
    final rows = [
      [
        'Combustivel (${quote.fuelLiters.toStringAsFixed(1)} l)',
        brl(quote.fuelCost),
      ],
      [
        'Arla 32 (${quote.arlaLiters.toStringAsFixed(1)} l)',
        brl(quote.arlaCost),
      ],
      ['Pedagio ida e volta', brl(quote.tollCost)],
      ['Lubrificantes / manutencao', brl(quote.maintenanceCost)],
      ['Pneus / depreciacao por km', brl(quote.tireCost)],
      ['Carga e descarga', brl(input.loadingFee + input.unloadingFee)],
      ['Rastreamento / gerenciamento', brl(input.trackingFee)],
      ['Demais variaveis', brl(quote.otherVariableCosts)],
      ['Total custos variaveis', brl(quote.totalVariableCosts)],
      ['Depreciacao do veiculo', brl(quote.vehicleDepreciationCost)],
      ['Salario motorista', brl(quote.driverSalaryCost)],
      ['Encargos motorista', brl(quote.driverBurdenCost)],
      ['Seguro do veiculo', brl(quote.vehicleInsuranceCost)],
      ['Despesas administrativas', brl(quote.administrativeCost)],
      ['Outras despesas fixas', brl(quote.otherFixedCosts)],
      ['Total custos fixos', brl(quote.totalFixedCosts)],
      ['Custo total da viagem', brl(quote.operationalCost)],
      ['Seguro sobre NF', brl(quote.insuranceValue)],
      ['Ad valorem', brl(quote.adValoremValue)],
      ['Lucro / margem', brl(quote.marginValue)],
      ['ICMS', brl(quote.icmsValue)],
      ['PIS', brl(quote.pisValue)],
      ['COFINS', brl(quote.cofinsValue)],
      ['Piso ANTT configurado', brl(quote.minimumAnttValue)],
      ['Custo por km rodado', '${brl(quote.costPerKm)} / km'],
      ['Preco minimo por km', '${brl(quote.minimumValuePerKm)} / km'],
      ['Valor final ao cliente', brl(quote.commercialValue)],
    ];

    return _section(
      'Composicao comercial',
      [],
      child: pw.TableHelper.fromTextArray(
        headers: ['Componente', 'Valor'],
        data: rows,
        headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#103B3A')),
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerRight,
        },
      ),
    );
  }

  static pw.Widget _anttBox(FreightQuote quote) {
    final color = quote.isBelowAntt ? PdfColors.red700 : PdfColors.green700;
    final text = quote.isBelowAntt
        ? 'Atencao: valor abaixo do piso ANTT informado nos parametros.'
        : 'Valor acima do piso ANTT informado nos parametros.';
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _terms() {
    return _section('Condicoes comerciais', [
      _line(
        'Prazo de validade',
        '7 dias ou enquanto houver disponibilidade operacional',
      ),
      _line(
        'Impostos',
        'Estimativas comerciais sujeitas a validacao fiscal/contabil',
      ),
      _line('Fonte ANTT', 'https://calculadorafrete.antt.gov.br/'),
      _line(
        'Escopo',
        'Nao inclui custos nao informados de armazenagem, estadia, escolta ou restricoes especiais',
      ),
      _line(
        'Aprovacao',
        'Proposta sujeita a confirmacao cadastral e operacional',
      ),
    ]);
  }

  static pw.Widget _section(
    String title,
    List<pw.Widget> lines, {
    pw.Widget? child,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D8E2E4')),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: _sectionTitleStyle()),
          pw.SizedBox(height: 10),
          ...lines,
          ?child,
        ],
      ),
    );
  }

  static pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label, style: _labelStyle())),
          pw.Expanded(child: pw.Text(value, style: _valueStyle())),
        ],
      ),
    );
  }

  static pw.Widget _paragraph(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(value, style: _valueStyle(), textAlign: pw.TextAlign.left),
    );
  }

  static pw.Widget _signature(String label) {
    return pw.SizedBox(
      width: 210,
      child: pw.Column(
        children: [
          pw.Container(height: 1, color: PdfColors.grey600),
          pw.SizedBox(height: 6),
          pw.Text(label, style: _labelStyle()),
        ],
      ),
    );
  }

  static String _yesNo(bool value) => value ? 'Sim' : 'Nao';

  static pw.TextStyle _sectionTitleStyle() => pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColor.fromHex('#103B3A'),
  );

  static pw.TextStyle _labelStyle() =>
      const pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

  static pw.TextStyle _valueStyle() =>
      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
}
