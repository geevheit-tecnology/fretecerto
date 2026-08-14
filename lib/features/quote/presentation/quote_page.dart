import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/brl.dart';
import '../../antt/application/antt_official_consultation_service.dart';
import '../application/location_distance_service.dart';
import '../application/quote_export_service.dart';
import '../application/quote_pdf_service.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';
import '../domain/saved_quote.dart';
import 'quote_controller.dart';
import 'quote_history_controller.dart';

class QuotePage extends ConsumerWidget {
  const QuotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(quoteInputProvider);
    final form = ref.watch(quoteFormProvider);
    final quote = ref.watch(freightQuoteProvider);
    final distanceService = ref.watch(locationDistanceServiceProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Nova cotacao')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _CommercialHero(
                quoteType: form.quoteType,
                origin: form.origin,
                destination: form.destination,
                cargoType: form.cargoType,
                totalWeightKg: input.totalWeightKg,
                totalVolumeM3: input.totalVolumeM3,
                invoiceValue: input.invoiceValue,
                commercialValue: quote.commercialValue,
                suggestedVehicle: quote.suggestedVehicle,
                bodyType: quote.bodyType,
                totalDistanceKm: quote.totalDistanceKm,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SegmentCard(
                    title: 'Tipo e cliente',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: form.quoteType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            prefixIcon: Icon(Icons.assignment_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Orcamento',
                              child: Text('Orcamento'),
                            ),
                            DropdownMenuItem(
                              value: 'Proposta',
                              child: Text('Proposta'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(quoteType: value));
                          },
                        ),
                        const SizedBox(height: 10),
                        _EditableField(
                          label: 'Solicitante',
                          value: form.customerName,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(customerName: value));
                          },
                        ),
                        _EditableField(
                          label: 'Vendedor',
                          value: form.sellerName,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(sellerName: value));
                          },
                        ),
                      ],
                    ),
                  ),
                  _SegmentCard(
                    title: 'Rota',
                    child: Column(
                      children: [
                        _LocalityField(
                          label: 'Origem',
                          value: form.origin,
                          service: distanceService,
                          onChanged: (value) {
                            final distance = distanceService
                                .estimateRoadDistanceKm(
                                  value,
                                  form.destination,
                                );
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(origin: value));
                            if (distance != null) {
                              _update(ref, input, distanceKm: distance);
                            }
                          },
                        ),
                        _LocalityField(
                          label: 'Destino',
                          value: form.destination,
                          service: distanceService,
                          onChanged: (value) {
                            final distance = distanceService
                                .estimateRoadDistanceKm(form.origin, value);
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(destination: value));
                            if (distance != null) {
                              _update(ref, input, distanceKm: distance);
                            }
                          },
                        ),
                        _NumberSlider(
                          label: 'Distancia rodoviaria',
                          suffix: 'km',
                          value: input.distanceKm,
                          min: 50,
                          max: 1600,
                          onChanged: (value) =>
                              _update(ref, input, distanceKm: value),
                        ),
                        _RouteMapPanel(
                          origin: form.origin,
                          destination: form.destination,
                          distanceKm: input.distanceKm,
                          service: distanceService,
                          onDistanceResolved: (distance) =>
                              _update(ref, input, distanceKm: distance),
                        ),
                      ],
                    ),
                  ),
                  _SegmentCard(
                    title: 'Carga',
                    child: Column(
                      children: [
                        _NumberSlider(
                          label: 'Peso total',
                          suffix: 'kg',
                          value: input.totalWeightKg,
                          min: 100,
                          max: 28000,
                          onChanged: (value) =>
                              _update(ref, input, totalWeightKg: value),
                        ),
                        _NumberSlider(
                          label: 'Cubagem',
                          suffix: 'm3',
                          value: input.totalVolumeM3,
                          min: 1,
                          max: 90,
                          onChanged: (value) =>
                              _update(ref, input, totalVolumeM3: value),
                        ),
                        _EditableField(
                          label: 'Tipo de carga',
                          value: form.cargoType,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(cargoType: value));
                          },
                        ),
                        _MoneyField(
                          label: 'Valor aproximado da NF',
                          value: input.invoiceValue,
                          onChanged: (value) =>
                              _update(ref, input, invoiceValue: value),
                        ),
                        _PercentField(
                          label: 'Margem de lucro',
                          value: input.marginPercent,
                          onChanged: (value) =>
                              _update(ref, input, marginPercent: value),
                        ),
                        _MoneyField(
                          label: 'Piso ANTT confirmado',
                          value: input.minimumAntt,
                          onChanged: (value) =>
                              _update(ref, input, minimumAntt: value),
                        ),
                      ],
                    ),
                  ),
                  _SegmentCard(
                    title: 'Custos da viagem',
                    child: Column(
                      children: [
                        _MoneyField(
                          label: 'Pedagio ida',
                          value: input.toll,
                          onChanged: (value) =>
                              _update(ref, input, toll: value),
                        ),
                        _MoneyField(
                          label: 'Carga',
                          value: input.loadingFee,
                          onChanged: (value) =>
                              _update(ref, input, loadingFee: value),
                        ),
                        _MoneyField(
                          label: 'Descarga',
                          value: input.unloadingFee,
                          onChanged: (value) =>
                              _update(ref, input, unloadingFee: value),
                        ),
                        _MoneyField(
                          label: 'Outros variaveis',
                          value: input.otherVariableCosts,
                          onChanged: (value) =>
                              _update(ref, input, otherVariableCosts: value),
                        ),
                        _NumberField(
                          label: 'Viagens por mes',
                          suffix: 'viagens',
                          value: input.monthlyTrips,
                          onChanged: (value) =>
                              _update(ref, input, monthlyTrips: value),
                        ),
                      ],
                    ),
                  ),
                  _SegmentCard(
                    title: 'Resultado comercial',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResultRow(
                          'Veiculo recomendado',
                          quote.suggestedVehicle,
                        ),
                        _VehicleRecommendation(
                          vehicle: quote.suggestedVehicle,
                          bodyType: quote.bodyType,
                          weightKg: input.totalWeightKg,
                          volumeM3: input.totalVolumeM3,
                        ),
                        const SizedBox(height: 8),
                        _ResultRow('Carroceria', quote.bodyType),
                        _ResultRow(
                          'Custo operacional',
                          brl(quote.operationalCost),
                        ),
                        _ResultRow(
                          'Distancia total',
                          '${quote.totalDistanceKm.toStringAsFixed(0)} km',
                        ),
                        _ResultRow(
                          'Custos variaveis',
                          brl(quote.totalVariableCosts),
                        ),
                        _ResultRow('Custos fixos', brl(quote.totalFixedCosts)),
                        _ResultRow('Seguro', brl(quote.insuranceValue)),
                        _ResultRow('Ad valorem', brl(quote.adValoremValue)),
                        _ResultRow('Lucro / margem', brl(quote.marginValue)),
                        _ResultRow('ICMS', brl(quote.icmsValue)),
                        _ResultRow('PIS', brl(quote.pisValue)),
                        _ResultRow('COFINS', brl(quote.cofinsValue)),
                        _ResultRow('Piso ANTT', brl(quote.minimumAnttValue)),
                        const Divider(height: 28),
                        Text(
                          brl(quote.commercialValue),
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        _ResultRow(
                          'Custo por km',
                          '${brl(quote.costPerKm)} / km',
                        ),
                        _ResultRow(
                          'Preco por km',
                          '${brl(quote.minimumValuePerKm)} / km',
                        ),
                        const SizedBox(height: 8),
                        _AnttBadge(isBelowAntt: quote.isBelowAntt),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final opened =
                                await const AnttOfficialConsultationService()
                                    .openOfficialCalculator();
                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nao foi possivel abrir a calculadora oficial da ANTT.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Consultar ANTT oficial'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.info_outline),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 760
                            ? double.infinity
                            : 520,
                        child: const Text(
                          'Calculo comercial estimativo. Parametros fiscais, custos, margens e piso ANTT devem ser validados pela administracao.',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          final pdf = await _buildPdf(input, quote, form);
                          await Printing.layoutPdf(
                            name: 'proposta-fretecerto.pdf',
                            onLayout: (_) async => pdf,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Gerar PDF'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final pdf = await _buildPdf(input, quote, form);
                          await SharePlus.instance.share(
                            ShareParams(
                              subject:
                                  'Proposta de frete - ${form.customerName}',
                              text:
                                  'Segue proposta comercial de frete ${form.origin} -> ${form.destination}.',
                              files: [
                                XFile.fromData(
                                  pdf,
                                  mimeType: 'application/pdf',
                                  name: _fileName('proposta', 'pdf'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Enviar PDF'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final csv = const QuoteExportService().buildExcelCsv(
                            input: input,
                            quote: quote,
                            quoteType: form.quoteType,
                            customerName: form.customerName,
                            sellerName: form.sellerName,
                            origin: form.origin,
                            destination: form.destination,
                            cargoType: form.cargoType,
                          );
                          await SharePlus.instance.share(
                            ShareParams(
                              subject:
                                  'Planilha da proposta - ${form.customerName}',
                              text:
                                  'Segue planilha comercial da proposta de frete.',
                              files: [
                                XFile.fromData(
                                  csv,
                                  mimeType: 'text/csv',
                                  name: _fileName('proposta', 'csv'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Enviar Excel'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final createdAt = DateTime.now();
                          ref
                              .read(quoteHistoryProvider.notifier)
                              .save(
                                SavedQuote(
                                  id: createdAt.microsecondsSinceEpoch
                                      .toString(),
                                  createdAt: createdAt,
                                  customerName: form.customerName,
                                  origin: form.origin,
                                  destination: form.destination,
                                  cargoType: form.cargoType,
                                  suggestedVehicle: quote.suggestedVehicle,
                                  commercialValue: quote.commercialValue,
                                  minimumAnttValue: quote.minimumAnttValue,
                                  isBelowAntt: quote.isBelowAntt,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cotacao salva no historico.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar'),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  static Future<Uint8List> _buildPdf(
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) {
    return const QuotePdfService().buildExecutiveQuote(
      input: input,
      quote: quote,
      quoteType: form.quoteType,
      customerName: form.customerName,
      sellerName: form.sellerName,
      origin: form.origin,
      destination: form.destination,
      cargoType: form.cargoType,
    );
  }

  static String _fileName(String prefix, String extension) {
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    return '$prefix-fretecerto-$stamp.$extension';
  }

  static void _update(
    WidgetRef ref,
    QuoteInput input, {
    double? distanceKm,
    double? totalWeightKg,
    double? totalVolumeM3,
    double? invoiceValue,
    double? marginPercent,
    double? minimumAntt,
    double? toll,
    double? loadingFee,
    double? unloadingFee,
    double? otherVariableCosts,
    double? monthlyTrips,
  }) {
    ref
        .read(quoteInputProvider.notifier)
        .replace(
          QuoteInput(
            distanceKm: distanceKm ?? input.distanceKm,
            totalWeightKg: totalWeightKg ?? input.totalWeightKg,
            totalVolumeM3: totalVolumeM3 ?? input.totalVolumeM3,
            invoiceValue: invoiceValue ?? input.invoiceValue,
            marginPercent: marginPercent ?? input.marginPercent,
            toll: toll ?? input.toll,
            loadingFee: loadingFee ?? input.loadingFee,
            unloadingFee: unloadingFee ?? input.unloadingFee,
            icmsPercent: input.icmsPercent,
            pisPercent: input.pisPercent,
            cofinsPercent: input.cofinsPercent,
            adValoremPercent: input.adValoremPercent,
            insurancePercent: input.insurancePercent,
            trackingFee: input.trackingFee,
            minimumAntt: minimumAntt ?? input.minimumAntt,
            consumptionKmPerLiter: input.consumptionKmPerLiter,
            dieselLiterPrice: input.dieselLiterPrice,
            arlaPercent: input.arlaPercent,
            arlaLiterPrice: input.arlaLiterPrice,
            maintenanceCostPerKm: input.maintenanceCostPerKm,
            tireCostPerKm: input.tireCostPerKm,
            otherVariableCosts: otherVariableCosts ?? input.otherVariableCosts,
            vehicleDepreciationMonthly: input.vehicleDepreciationMonthly,
            driverSalaryMonthly: input.driverSalaryMonthly,
            driverBurdenPercent: input.driverBurdenPercent,
            vehicleInsuranceYearly: input.vehicleInsuranceYearly,
            administrativeCostsMonthly: input.administrativeCostsMonthly,
            otherFixedCostsPerTrip: input.otherFixedCostsPerTrip,
            monthlyTrips: monthlyTrips ?? input.monthlyTrips,
          ),
        );
  }
}

class _CommercialHero extends StatelessWidget {
  const _CommercialHero({
    required this.quoteType,
    required this.origin,
    required this.destination,
    required this.cargoType,
    required this.totalWeightKg,
    required this.totalVolumeM3,
    required this.invoiceValue,
    required this.commercialValue,
    required this.suggestedVehicle,
    required this.bodyType,
    required this.totalDistanceKm,
  });

  final String quoteType;
  final String origin;
  final String destination;
  final String cargoType;
  final double totalWeightKg;
  final double totalVolumeM3;
  final double invoiceValue;
  final double commercialValue;
  final String suggestedVehicle;
  final String bodyType;
  final double totalDistanceKm;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final routeSummary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quoteType,
          style: const TextStyle(
            color: Color(0xFF80CBC4),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$origin -> $destination',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HeroChip(Icons.inventory_2_outlined, cargoType),
            _HeroChip(
              Icons.scale_outlined,
              '${totalWeightKg.toStringAsFixed(0)} kg',
            ),
            _HeroChip(
              Icons.view_in_ar_outlined,
              '${totalVolumeM3.toStringAsFixed(0)} m3',
            ),
            _HeroChip(Icons.receipt_long_outlined, brl(invoiceValue)),
          ],
        ),
      ],
    );
    final valueSummary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valor comercial',
          style: TextStyle(color: Color(0xFFB2DFDB)),
        ),
        Text(
          brl(commercialValue),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$suggestedVehicle $bodyType | ${totalDistanceKm.toStringAsFixed(0)} km total',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                routeSummary,
                const SizedBox(height: 18),
                valueSummary,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: routeSummary),
                const SizedBox(width: 24),
                Expanded(child: valueSummary),
              ],
            ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}

class _RouteMapPanel extends StatelessWidget {
  const _RouteMapPanel({
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.service,
    required this.onDistanceResolved,
  });

  final String origin;
  final String destination;
  final double distanceKm;
  final LocationDistanceService service;
  final ValueChanged<double> onDistanceResolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8DEDA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mapa da rota',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${distanceKm.toStringAsFixed(0)} km'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 108,
            child: CustomPaint(
              painter: _RoutePainter(),
              child: Row(
                children: [
                  Expanded(
                    child: _RouteStop(label: origin, icon: Icons.trip_origin),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Chip(
                        avatar: const Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                        ),
                        label: Text('${distanceKm.toStringAsFixed(0)} km'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RouteStop(
                      label: destination,
                      icon: Icons.flag_outlined,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final resolved = await service.resolveRoadDistance(
                    origin,
                    destination,
                  );
                  if (resolved == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nao encontrei essa rota na base local. Selecione origem e destino da lista ou informe a distancia manualmente.',
                        ),
                      ),
                    );
                    return;
                  }
                  onDistanceResolved(resolved.distanceKm);
                  if (!context.mounted) return;
                  final source = switch (resolved.source) {
                    RouteDistanceSource.googleMaps => 'Google Maps',
                    RouteDistanceSource.offlineEstimate => 'estimativa local',
                  };
                  final duration = resolved.durationText == null
                      ? ''
                      : ' Tempo: ${resolved.durationText}.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Distancia aplicada: ${resolved.distanceKm.toStringAsFixed(0)} km via $source.$duration',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Calcular e aplicar'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'origin': origin,
                    'destination': destination,
                  });
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Conferir no mapa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.icon,
    this.alignEnd = false,
  });

  final String label;
  final IconData icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0E6F68)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(18, size.height - 34)
      ..cubicTo(
        size.width * .32,
        10,
        size.width * .66,
        10,
        size.width - 18,
        size.height - 34,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VehicleRecommendation extends StatelessWidget {
  const _VehicleRecommendation({
    required this.vehicle,
    required this.bodyType,
    required this.weightKg,
    required this.volumeM3,
  });

  final String vehicle;
  final String bodyType;
  final double weightKg;
  final double volumeM3;

  @override
  Widget build(BuildContext context) {
    final axleCount = switch (vehicle) {
      'Fiorino' || 'Van' || 'VUC' => 2,
      'Toco' => 2,
      'Truck' => 3,
      _ => 5,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: CustomPaint(
              painter: _TruckPainter(axleCount: axleCount),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('$axleCount eixos')),
              Chip(label: Text(bodyType)),
              Chip(label: Text('${weightKg.toStringAsFixed(0)} kg')),
              Chip(label: Text('${volumeM3.toStringAsFixed(0)} m3')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TruckPainter extends CustomPainter {
  const _TruckPainter({required this.axleCount});

  final int axleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF0E6F68);
    final cab = Paint()..color = const Color(0xFF17444A);
    final wheel = Paint()..color = const Color(0xFF111827);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 16, size.width * .64, 34),
      const Radius.circular(6),
    );
    final cabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .68, 24, size.width * .22, 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, body);
    canvas.drawRRect(cabRect, cab);
    for (var i = 0; i < axleCount; i++) {
      final x = 24 + (i * ((size.width - 64) / axleCount));
      canvas.drawCircle(Offset(x, 56), 8, wheel);
      canvas.drawCircle(Offset(x, 56), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _TruckPainter oldDelegate) {
    return oldDelegate.axleCount != axleCount;
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 760 ? width : 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableField extends StatefulWidget {
  const _EditableField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(labelText: widget.label),
      ),
    );
  }
}

class _LocalityField extends StatefulWidget {
  const _LocalityField({
    required this.label,
    required this.value,
    required this.service,
    required this.onChanged,
  });

  final String label;
  final String value;
  final LocationDistanceService service;
  final ValueChanged<String> onChanged;

  @override
  State<_LocalityField> createState() => _LocalityFieldState();
}

class _LocalityFieldState extends State<_LocalityField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RawAutocomplete<Locality>(
        textEditingController: _controller,
        focusNode: _focusNode,
        displayStringForOption: (option) => option.label,
        optionsBuilder: (textEditingValue) {
          return widget.service.search(textEditingValue.text);
        },
        onSelected: (locality) {
          _controller.text = locality.label;
          widget.onChanged(locality.label);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: IconButton(
                tooltip: 'Usar localidade',
                onPressed: () => widget.onChanged(controller.text),
                icon: const Icon(Icons.check),
              ),
            ),
            onChanged: widget.onChanged,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  maxHeight: 240,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_city_outlined),
                      title: Text(option.label),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoneyField extends StatefulWidget {
  const _MoneyField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<_MoneyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: 'R\$ ',
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _PercentField extends StatefulWidget {
  const _PercentField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_PercentField> createState() => _PercentFieldState();
}

class _PercentFieldState extends State<_PercentField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: widget.label, suffixText: '%'),
        onChanged: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffix,
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  const _NumberSlider({
    required this.label,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(0)} $suffix'),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AnttBadge extends StatelessWidget {
  const _AnttBadge({required this.isBelowAntt});

  final bool isBelowAntt;

  @override
  Widget build(BuildContext context) {
    final color = isBelowAntt ? Colors.red.shade700 : Colors.green.shade700;
    return Chip(
      avatar: Icon(
        isBelowAntt ? Icons.warning_amber : Icons.check_circle,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        isBelowAntt
            ? 'Abaixo do piso ANTT informado'
            : 'Acima do piso ANTT informado',
      ),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
