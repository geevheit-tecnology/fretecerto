import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/brl.dart';
import '../../antt/application/antt_official_consultation_service.dart';
import '../../customers/application/customer_repository.dart';
import '../../customers/domain/customer.dart';
import '../application/location_distance_service.dart';
import '../application/quote_export_service.dart';
import '../application/quote_pdf_service.dart';
import '../domain/freight_quote.dart';
import '../domain/quote_input.dart';
import '../domain/quote_validation.dart';
import '../domain/saved_quote.dart';
import 'quote_controller.dart';
import 'quote_history_controller.dart';

class QuotePage extends ConsumerStatefulWidget {
  const QuotePage({super.key});

  @override
  ConsumerState<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends ConsumerState<QuotePage> {
  bool _savingQuote = false;
  bool _hasCalculated = false;
  bool _autoRouteSearching = false;
  Timer? _routeLookupTimer;
  String? _routeLookupMessage;
  QuoteValidationResult? _lastValidation;

  @override
  void dispose() {
    _routeLookupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(quoteInputProvider);
    final form = ref.watch(quoteFormProvider);
    final quote = ref.watch(freightQuoteProvider);
    final distanceService = ref.watch(locationDistanceServiceProvider);
    final ibgeMunicipalities =
        ref.watch(ibgeMunicipalitiesProvider).value ?? const [];
    final validation = _lastValidation;
    final currentValidation = _validate(input, form);
    final resultReady = _hasCalculated && currentValidation.isValid;

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
                commercialValue: resultReady ? quote.commercialValue : 0,
                suggestedVehicle: quote.suggestedVehicle,
                bodyType: form.bodyType,
                totalDistanceKm: quote.totalDistanceKm,
              ),
              const SizedBox(height: 16),
              _ModeGuide(quoteType: form.quoteType),
              const SizedBox(height: 12),
              _QuickActionBar(
                onCalculate: () => _calculateQuote(context, input, form),
                onAntt: () => _openAntt(context),
                onEmail: () {
                  if (!_ensureReadyAndNotify(context, input, form)) return;
                  _sendEmail(context, input, quote, form);
                },
                onWhatsApp: () {
                  if (!_ensureReadyAndNotify(context, input, form)) return;
                  _sendWhatsApp(context, input, quote, form);
                },
                onClear: () {
                  _clearForm(ref, form.quoteType);
                  setState(() {
                    _hasCalculated = false;
                    _lastValidation = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SegmentCard(
                    title: form.quoteType == 'Orcamento'
                        ? 'Pedido do cliente'
                        : 'Cliente e proposta',
                    child: Column(
                      children: [
                        const _WorkflowHint(),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Orcamento',
                              icon: Icon(Icons.flash_on_outlined),
                              label: Text('Orcamento'),
                            ),
                            ButtonSegment(
                              value: 'Proposta',
                              icon: Icon(Icons.description_outlined),
                              label: Text('Proposta'),
                            ),
                          ],
                          selected: {form.quoteType},
                          onSelectionChanged: (values) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(quoteType: values.first));
                          },
                        ),
                        const SizedBox(height: 10),
                        _CustomerPicker(
                          value: form.customerName,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(customerName: value));
                            _markDirty();
                          },
                          onCreate: () =>
                              context.go('/clientes?returnTo=/cotacao'),
                        ),
                        _EditableField(
                          label: 'Vendedor',
                          value: form.sellerName,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(sellerName: value));
                            _markDirty();
                          },
                        ),
                        _NumberField(
                          label: 'Validade comercial',
                          suffix: 'dias',
                          value: form.validityDays.toDouble(),
                          onChanged: (value) {
                            final days = value.round().clamp(1, 90);
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(validityDays: days));
                            _markDirty();
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
                          ibgeMunicipalities: ibgeMunicipalities,
                          onChanged: (value) {
                            final distance = distanceService
                                .estimateRoadDistanceKm(
                                  value,
                                  form.destination,
                                );
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(origin: value));
                            _markDirty();
                            if (distance != null) {
                              _update(
                                ref,
                                input,
                                distanceKm: distance,
                                returnDistanceKm: form.hasEmptyReturn
                                    ? distance
                                    : input.returnDistanceKm,
                              );
                            }
                            _scheduleAutoRouteLookup(distanceService);
                          },
                        ),
                        _LocalityField(
                          label: 'Destino',
                          value: form.destination,
                          service: distanceService,
                          ibgeMunicipalities: ibgeMunicipalities,
                          onChanged: (value) {
                            final distance = distanceService
                                .estimateRoadDistanceKm(form.origin, value);
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(destination: value));
                            _markDirty();
                            if (distance != null) {
                              _update(
                                ref,
                                input,
                                distanceKm: distance,
                                returnDistanceKm: form.hasEmptyReturn
                                    ? distance
                                    : input.returnDistanceKm,
                              );
                            }
                            _scheduleAutoRouteLookup(distanceService);
                          },
                        ),
                        _NumberField(
                          label: 'Distancia rodoviaria',
                          suffix: 'km',
                          value: input.distanceKm,
                          onChanged: (value) => _update(
                            ref,
                            input,
                            distanceKm: value,
                            returnDistanceKm: form.hasEmptyReturn
                                ? value
                                : input.returnDistanceKm,
                          ),
                        ),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cobrar retorno vazio'),
                          subtitle: const Text(
                            'Use somente quando o retorno deve entrar no custo.',
                          ),
                          value: form.hasEmptyReturn,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(hasEmptyReturn: value));
                            _update(
                              ref,
                              input,
                              returnDistanceKm: value ? input.distanceKm : 0,
                            );
                          },
                        ),
                        if (form.hasEmptyReturn)
                          _NumberField(
                            label: 'Km de retorno vazio',
                            suffix: 'km',
                            value: input.returnDistanceKm,
                            onChanged: (value) =>
                                _update(ref, input, returnDistanceKm: value),
                          ),
                        _RouteMapPanel(
                          origin: form.origin,
                          destination: form.destination,
                          distanceKm: input.distanceKm,
                          searching: _autoRouteSearching,
                          message: _routeLookupMessage,
                          service: distanceService,
                          onDistanceResolved: (distance) => _update(
                            ref,
                            input,
                            distanceKm: distance,
                            returnDistanceKm: form.hasEmptyReturn
                                ? distance
                                : input.returnDistanceKm,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SegmentCard(
                    title: 'Carga e veiculo',
                    child: Column(
                      children: [
                        _NumberField(
                          label: 'Peso total',
                          suffix: 'kg',
                          value: input.totalWeightKg,
                          onChanged: (value) =>
                              _update(ref, input, totalWeightKg: value),
                        ),
                        _NumberField(
                          label: 'Cubagem',
                          suffix: 'm3',
                          value: input.totalVolumeM3,
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
                            _markDirty();
                          },
                        ),
                        _BodyTypeSelector(
                          value: form.bodyType,
                          onChanged: (value) {
                            ref
                                .read(quoteFormProvider.notifier)
                                .update(form.copyWith(bodyType: value));
                            _markDirty();
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
                    title: 'Conferencia ANTT',
                    child: _AnttComplianceForm(
                      form: form,
                      input: input,
                      quote: quote,
                      onChanged: (next) {
                        ref.read(quoteFormProvider.notifier).update(next);
                        _markDirty();
                      },
                      onMinimumChanged: (value) =>
                          _update(ref, input, minimumAntt: value),
                    ),
                  ),
                  if (form.quoteType != 'Orcamento')
                    _SegmentCard(
                      title: 'Custos da viagem',
                      child: Column(
                        children: [
                          _MoneyField(
                            label: 'Pedagio total informado',
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
                        if (!resultReady) ...[
                          _CalculationPendingCard(
                            messages: validation?.messages,
                            hasTried: validation != null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (validation != null && !validation.isValid) ...[
                          _ValidationSummary(messages: validation.messages),
                          const SizedBox(height: 12),
                        ],
                        if (resultReady) ...[
                          _ResultRow(
                            'Porte operacional',
                            quote.suggestedVehicle,
                          ),
                          _VehicleRecommendation(
                            vehicle: quote.suggestedVehicle,
                            bodyType: form.bodyType,
                            axleCount: form.anttAxles,
                            weightKg: input.totalWeightKg,
                            volumeM3: input.totalVolumeM3,
                          ),
                          const SizedBox(height: 8),
                          _ResultRow('Carroceria', form.bodyType),
                          _ResultRow(
                            'Validade',
                            '${form.validityDays} dias corridos',
                          ),
                          _ResultRow(
                            'Custo operacional',
                            brl(quote.operationalCost),
                          ),
                          _ResultRow(
                            'Km considerado no custo',
                            '${quote.totalDistanceKm.toStringAsFixed(0)} km',
                          ),
                          if (quote.returnDistanceKm > 0)
                            _ResultRow(
                              'Retorno vazio',
                              '${quote.returnDistanceKm.toStringAsFixed(0)} km',
                            ),
                          _ResultRow(
                            'Custos variaveis',
                            brl(quote.totalVariableCosts),
                          ),
                          _ResultRow(
                            'Custos fixos',
                            brl(quote.totalFixedCosts),
                          ),
                          _ResultRow('Seguro', brl(quote.insuranceValue)),
                          _ResultRow('Ad valorem', brl(quote.adValoremValue)),
                          _ResultRow('Lucro / margem', brl(quote.marginValue)),
                          _ResultRow('ICMS', brl(quote.icmsValue)),
                          _ResultRow('PIS', brl(quote.pisValue)),
                          _ResultRow('COFINS', brl(quote.cofinsValue)),
                          _ResultRow('Piso ANTT', brl(quote.minimumAnttValue)),
                          const SizedBox(height: 8),
                          _CalculationFormulaCard(quote: quote),
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
                        ],
                        OutlinedButton.icon(
                          onPressed: () => _openAntt(context),
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
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          if (!_ensureReadyAndNotify(context, input, form)) {
                            return;
                          }
                          await _sendEmail(context, input, quote, form);
                        },
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('Enviar por email'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          if (!_ensureReadyAndNotify(context, input, form)) {
                            return;
                          }
                          await _sendWhatsApp(context, input, quote, form);
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Enviar WhatsApp'),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!_ensureReadyAndNotify(context, input, form)) {
                            return;
                          }
                          final pdf = await _buildPdf(input, quote, form);
                          await Printing.layoutPdf(
                            name: 'proposta-fretecerto.pdf',
                            onLayout: (_) async => pdf,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          form.quoteType == 'Orcamento'
                              ? 'Gerar orcamento'
                              : 'Gerar proposta',
                        ),
                      ),
                      if (form.quoteType != 'Orcamento') ...[
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            if (!_ensureReadyAndNotify(context, input, form)) {
                              return;
                            }
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
                            if (!_ensureReadyAndNotify(context, input, form)) {
                              return;
                            }
                            final csv = const QuoteExportService()
                                .buildExcelCsv(
                                  input: input,
                                  quote: quote,
                                  quoteType: form.quoteType,
                                  customerName: form.customerName,
                                  sellerName: form.sellerName,
                                  origin: form.origin,
                                  destination: form.destination,
                                  cargoType: form.cargoType,
                                  bodyType: form.bodyType,
                                  validityDays: form.validityDays,
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
                        FilledButton.icon(
                          onPressed: () async {
                            if (!_ensureReadyAndNotify(context, input, form)) {
                              return;
                            }
                            final pdf = await _buildContract(
                              input,
                              quote,
                              form,
                            );
                            await Printing.layoutPdf(
                              name: 'contrato-fretecerto.pdf',
                              onLayout: (_) async => pdf,
                            );
                          },
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Gerar contrato'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            if (!_ensureReadyAndNotify(context, input, form)) {
                              return;
                            }
                            final pdf = await _buildContract(
                              input,
                              quote,
                              form,
                            );
                            await SharePlus.instance.share(
                              ShareParams(
                                subject:
                                    'Contrato de frete - ${form.customerName}',
                                text:
                                    'Segue minuta de contrato de transporte referente a cotacao ${form.origin} -> ${form.destination}.',
                                files: [
                                  XFile.fromData(
                                    pdf,
                                    mimeType: 'application/pdf',
                                    name: _fileName('contrato', 'pdf'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Enviar contrato'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: _savingQuote
                            ? null
                            : () => _saveQuote(context, input, quote, form),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_savingQuote ? 'Salvando...' : 'Salvar'),
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

  Future<void> _saveQuote(
    BuildContext context,
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) async {
    if (_savingQuote) return;
    if (!_ensureReadyAndNotify(context, input, form)) return;
    setState(() => _savingQuote = true);
    final createdAt = DateTime.now();
    final savedQuote = SavedQuote(
      id: createdAt.microsecondsSinceEpoch.toString(),
      createdAt: createdAt,
      customerName: form.customerName,
      sellerName: form.sellerName,
      origin: form.origin,
      destination: form.destination,
      cargoType: form.cargoType,
      quoteType: form.quoteType,
      totalWeightKg: input.totalWeightKg,
      totalVolumeM3: input.totalVolumeM3,
      invoiceValue: input.invoiceValue,
      distanceKm: input.distanceKm,
      totalDistanceKm: quote.totalDistanceKm,
      suggestedVehicle: quote.suggestedVehicle,
      bodyType: form.bodyType,
      validityDays: form.validityDays,
      commercialValue: quote.commercialValue,
      operationalCost: quote.operationalCost,
      minimumAnttValue: quote.minimumAnttValue,
      isBelowAntt: quote.isBelowAntt,
      anttCargoType: form.anttCargoType,
      anttAxles: form.anttAxles,
      isDieselVehicle: form.isDieselVehicle,
      isNationalTrip: form.isNationalTrip,
      isFullTruckload: form.isFullTruckload,
      isVehicleComposition: form.isVehicleComposition,
      isHighPerformance: form.isHighPerformance,
      hasEmptyReturn: form.hasEmptyReturn,
    );
    try {
      await ref.read(quoteHistoryProvider.notifier).save(savedQuote);
    } finally {
      if (mounted) setState(() => _savingQuote = false);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cotacao salva no historico.')),
    );
  }

  void _calculateQuote(
    BuildContext context,
    QuoteInput input,
    QuoteFormState form,
  ) {
    final validation = _validate(input, form);
    setState(() {
      _lastValidation = validation;
      _hasCalculated = validation.isValid;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          validation.isValid
              ? 'Cotacao calculada. Confira o valor e a composicao.'
              : validation.messages.first,
        ),
      ),
    );
  }

  bool _validateAndNotify(
    BuildContext context,
    QuoteInput input,
    QuoteFormState form,
  ) {
    final validation = _validate(input, form);
    setState(() => _lastValidation = validation);
    if (validation.isValid) return true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(validation.messages.first)));
    return false;
  }

  bool _ensureReadyAndNotify(
    BuildContext context,
    QuoteInput input,
    QuoteFormState form,
  ) {
    if (!_validateAndNotify(context, input, form)) return false;
    if (_hasCalculated) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Clique em Calcular cotacao antes de continuar.'),
        ),
      );
    return false;
  }

  static QuoteValidationResult _validate(
    QuoteInput input,
    QuoteFormState form,
  ) {
    return const QuoteValidator().validate(
      input: input,
      origin: form.origin,
      destination: form.destination,
      cargoType: form.cargoType,
      bodyType: form.bodyType,
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
      bodyType: form.bodyType,
      validityDays: form.validityDays,
      anttCargoType: form.anttCargoType,
      anttAxles: form.anttAxles,
      isDieselVehicle: form.isDieselVehicle,
      isNationalTrip: form.isNationalTrip,
      isFullTruckload: form.isFullTruckload,
      isVehicleComposition: form.isVehicleComposition,
      isHighPerformance: form.isHighPerformance,
      hasEmptyReturn: form.hasEmptyReturn,
    );
  }

  static Future<Uint8List> _buildContract(
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) {
    return const QuotePdfService().buildFreightContract(
      input: input,
      quote: quote,
      quoteType: form.quoteType,
      customerName: form.customerName,
      sellerName: form.sellerName,
      origin: form.origin,
      destination: form.destination,
      cargoType: form.cargoType,
      bodyType: form.bodyType,
      validityDays: form.validityDays,
      anttCargoType: form.anttCargoType,
      anttAxles: form.anttAxles,
      isDieselVehicle: form.isDieselVehicle,
      isNationalTrip: form.isNationalTrip,
      isFullTruckload: form.isFullTruckload,
      isVehicleComposition: form.isVehicleComposition,
      isHighPerformance: form.isHighPerformance,
      hasEmptyReturn: form.hasEmptyReturn,
    );
  }

  static Future<void> _openAntt(BuildContext context) async {
    final opened = await const AnttOfficialConsultationService()
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
  }

  static void _clearForm(WidgetRef ref, String quoteType) {
    ref.read(quoteFormProvider.notifier).reset(quoteType: quoteType);
    ref.read(quoteInputProvider.notifier).reset();
  }

  static Future<void> _sendEmail(
    BuildContext context,
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': '${form.quoteType} de frete - ${form.customerName}',
        'body': _commercialMessage(input, quote, form),
      },
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o email.')),
      );
    }
  }

  static Future<void> _sendWhatsApp(
    BuildContext context,
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) async {
    final uri = Uri.https('wa.me', '/', {
      'text': _commercialMessage(input, quote, form),
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o WhatsApp.')),
      );
    }
  }

  static String _commercialMessage(
    QuoteInput input,
    FreightQuote quote,
    QuoteFormState form,
  ) {
    return '''
${form.quoteType} de frete - FreteCerto

Cliente: ${form.customerName}
Rota: ${form.origin} -> ${form.destination}
Carga: ${form.cargoType}
Peso: ${input.totalWeightKg.toStringAsFixed(0)} kg
Cubagem: ${input.totalVolumeM3.toStringAsFixed(1)} m3
Porte operacional: ${quote.suggestedVehicle}
Carroceria: ${form.bodyType}
Tipo ANTT: ${form.anttCargoType}
Eixos ANTT: ${form.anttAxles}
Km considerado no custo: ${quote.totalDistanceKm.toStringAsFixed(0)} km
Piso ANTT informado: ${brl(quote.minimumAnttValue)}
Valor comercial: ${brl(quote.commercialValue)}
Status: ${quote.isBelowAntt ? 'abaixo do piso informado' : 'acima do piso informado'}

Validade: ${form.validityDays} dias corridos, sujeito a confirmacao cadastral, fiscal e operacional.
''';
  }

  static String _fileName(String prefix, String extension) {
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    return '$prefix-fretecerto-$stamp.$extension';
  }

  void _markDirty() {
    if (!_hasCalculated && _lastValidation == null) return;
    setState(() {
      _hasCalculated = false;
      _lastValidation = null;
    });
  }

  void _scheduleAutoRouteLookup(LocationDistanceService service) {
    _routeLookupTimer?.cancel();
    final form = ref.read(quoteFormProvider);
    final origin = form.origin.trim();
    final destination = form.destination.trim();
    if (origin.length < 3 || destination.length < 3) {
      if (_autoRouteSearching || _routeLookupMessage != null) {
        setState(() {
          _autoRouteSearching = false;
          _routeLookupMessage = null;
        });
      }
      return;
    }

    setState(() {
      _autoRouteSearching = true;
      _routeLookupMessage = 'Buscando distancia automaticamente...';
    });

    _routeLookupTimer = Timer(const Duration(milliseconds: 700), () async {
      final currentForm = ref.read(quoteFormProvider);
      final currentInput = ref.read(quoteInputProvider);
      final resolved = await service.resolveRoadDistance(
        currentForm.origin,
        currentForm.destination,
      );
      if (!mounted) return;
      if (resolved == null) {
        setState(() {
          _autoRouteSearching = false;
          _routeLookupMessage =
              'Nao achei essa rota automaticamente. Informe o km manualmente.';
        });
        return;
      }
      _update(
        ref,
        currentInput,
        distanceKm: resolved.distanceKm,
        returnDistanceKm: currentForm.hasEmptyReturn
            ? resolved.distanceKm
            : currentInput.returnDistanceKm,
      );
      final source = switch (resolved.source) {
        RouteDistanceSource.openRouteService => 'rota real',
        RouteDistanceSource.offlineEstimate => 'estimativa local',
      };
      setState(() {
        _autoRouteSearching = false;
        _routeLookupMessage = 'Distancia aplicada automaticamente por $source.';
      });
    });
  }

  void _update(
    WidgetRef ref,
    QuoteInput input, {
    double? distanceKm,
    double? returnDistanceKm,
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
    _markDirty();
    ref
        .read(quoteInputProvider.notifier)
        .replace(
          QuoteInput(
            distanceKm: distanceKm ?? input.distanceKm,
            returnDistanceKm: returnDistanceKm ?? input.returnDistanceKm,
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
          '$suggestedVehicle | ${totalDistanceKm.toStringAsFixed(0)} km calculo',
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

class _ModeGuide extends StatelessWidget {
  const _ModeGuide({required this.quoteType});

  final String quoteType;

  @override
  Widget build(BuildContext context) {
    final isBudget = quoteType == 'Orcamento';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBudget ? const Color(0xFFFFF7E8) : const Color(0xFFEAF4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBudget ? const Color(0xFFF2D09A) : const Color(0xFFC8DEDA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isBudget ? Icons.flash_on_outlined : Icons.verified_outlined,
            color: isBudget ? const Color(0xFF9A5B00) : const Color(0xFF0E6F68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBudget
                      ? 'Formulario rapido sem compromisso'
                      : 'Cotacao comercial com proposta e contrato',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBudget
                      ? 'Use origem, destino, carga, peso, cubagem e valor da mercadoria para responder rapido ao cliente. Os custos finos continuam no motor de calculo.'
                      : 'Use os campos completos para fechar proposta, gerar PDF, planilha, mensagem comercial e minuta de contrato.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  const _QuickActionBar({
    required this.onCalculate,
    required this.onAntt,
    required this.onEmail,
    required this.onWhatsApp,
    required this.onClear,
  });

  final VoidCallback onCalculate;
  final VoidCallback onAntt;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular cotacao'),
            ),
            OutlinedButton.icon(
              onPressed: onAntt,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Consultar ANTT oficial'),
            ),
            FilledButton.tonalIcon(
              onPressed: onEmail,
              icon: const Icon(Icons.mail_outline),
              label: const Text('Email rapido'),
            ),
            FilledButton.tonalIcon(
              onPressed: onWhatsApp,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp rapido'),
            ),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Nova cotacao'),
            ),
          ],
        ),
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

class _WorkflowHint extends StatelessWidget {
  const _WorkflowHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE3DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_outlined, color: Color(0xFF0E6F68)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Informe cliente, origem, destino, peso, carga, carroceria, valor da NF, piso ANTT e validade antes de enviar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF315654),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyTypeSelector extends StatelessWidget {
  const _BodyTypeSelector({required this.value, required this.onChanged});

  static const _options = [
    'Aberta',
    'Bau',
    'Sider',
    'Grade baixa',
    'Graneleira',
    'Tanque',
    'Frigorifica',
    'Prancha',
    'Container',
    'Definir na operacao',
  ];

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _options.contains(value) ? value : _options.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Carroceria solicitada',
          prefixIcon: Icon(Icons.local_shipping_outlined),
        ),
        items: [
          for (final option in _options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _RouteMapPanel extends StatelessWidget {
  const _RouteMapPanel({
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.searching,
    required this.message,
    required this.service,
    required this.onDistanceResolved,
  });

  final String origin;
  final String destination;
  final double distanceKm;
  final bool searching;
  final String? message;
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
                          'Rota automatica indisponivel para essas cidades. A cotacao continua liberada: informe a distancia manualmente.',
                        ),
                      ),
                    );
                    return;
                  }
                  onDistanceResolved(resolved.distanceKm);
                  if (!context.mounted) return;
                  final source = switch (resolved.source) {
                    RouteDistanceSource.openRouteService => 'OpenRouteService',
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
          if (message != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searching)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF0E6F68),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message!,
                    style: const TextStyle(
                      color: Color(0xFF315654),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    required this.axleCount,
    required this.weightKg,
    required this.volumeM3,
  });

  final String vehicle;
  final String bodyType;
  final int axleCount;
  final double weightKg;
  final double volumeM3;

  @override
  Widget build(BuildContext context) {
    final visibleAxles = axleCount.clamp(2, 9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE3DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rule_outlined,
                  color: Color(0xFF0E6F68),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Porte calculado por peso e cubagem. A carroceria deve ser confirmada conforme carga, contrato e operacao.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF315654),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: CustomPaint(
              painter: _TruckPainter(axleCount: visibleAxles),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(vehicle)),
              Chip(label: Text('$visibleAxles eixos ANTT')),
              Chip(label: Text('Carroceria: $bodyType')),
              Chip(label: Text('${weightKg.toStringAsFixed(0)} kg')),
              Chip(label: Text('${volumeM3.toStringAsFixed(0)} m3')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                color: Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Antes de enviar, corrija a cotacao',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF713F12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final message in messages.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '- $message',
                style: const TextStyle(color: Color(0xFF713F12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CalculationFormulaCard extends StatelessWidget {
  const _CalculationFormulaCard({required this.quote});

  final FreightQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como o valor foi formado',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ResultRow('Base operacional', brl(quote.operationalCost)),
          _ResultRow(
            'Seguro + ad valorem + margem',
            brl(
              quote.insuranceValue + quote.adValoremValue + quote.marginValue,
            ),
          ),
          _ResultRow('Impostos por dentro', brl(quote.taxValue)),
          if (quote.minimumAnttValue > 0)
            _ResultRow('Piso ANTT aplicado', quote.isBelowAntt ? 'Sim' : 'Nao'),
        ],
      ),
    );
  }
}

class _CalculationPendingCard extends StatelessWidget {
  const _CalculationPendingCard({required this.hasTried, this.messages});

  final bool hasTried;
  final List<String>? messages;

  @override
  Widget build(BuildContext context) {
    final firstMessage = messages?.isNotEmpty == true ? messages!.first : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE3DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.calculate_outlined, color: Color(0xFF0E6F68)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasTried && firstMessage != null
                  ? firstMessage
                  : 'Preencha os dados principais e clique em Calcular cotacao para liberar o resultado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF315654),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnttComplianceForm extends StatelessWidget {
  const _AnttComplianceForm({
    required this.form,
    required this.input,
    required this.quote,
    required this.onChanged,
    required this.onMinimumChanged,
  });

  final QuoteFormState form;
  final QuoteInput input;
  final FreightQuote quote;
  final ValueChanged<QuoteFormState> onChanged;
  final ValueChanged<double> onMinimumChanged;

  @override
  Widget build(BuildContext context) {
    final requiredDataOk =
        form.isDieselVehicle &&
        form.isNationalTrip &&
        form.isFullTruckload &&
        input.minimumAntt > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: requiredDataOk
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: requiredDataOk
                  ? const Color(0xFFA5D6A7)
                  : const Color(0xFFFFCC80),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                requiredDataOk
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                color: requiredDataOk
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  requiredDataOk
                      ? 'Requisitos principais preenchidos. Confira o piso na calculadora oficial antes de enviar.'
                      : 'Preencha o piso oficial e confira se a operacao entra na regra antes de fechar valor.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: form.anttCargoType,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo de carga na tabela',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'Carga geral', child: Text('Carga geral')),
            DropdownMenuItem(
              value: 'Granel solido',
              child: Text('Granel solido'),
            ),
            DropdownMenuItem(
              value: 'Granel liquido',
              child: Text('Granel liquido'),
            ),
            DropdownMenuItem(
              value: 'Carga frigorificada',
              child: Text('Carga frigorificada'),
            ),
            DropdownMenuItem(
              value: 'Carga perigosa',
              child: Text('Carga perigosa'),
            ),
            DropdownMenuItem(
              value: 'Neogranel',
              child: Text('Neogranel / especial'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(form.copyWith(anttCargoType: value));
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: form.anttAxles,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Eixos para consulta',
            prefixIcon: Icon(Icons.alt_route_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 2, child: Text('2 eixos')),
            DropdownMenuItem(value: 3, child: Text('3 eixos')),
            DropdownMenuItem(value: 4, child: Text('4 eixos')),
            DropdownMenuItem(value: 5, child: Text('5 eixos')),
            DropdownMenuItem(value: 6, child: Text('6 eixos')),
            DropdownMenuItem(value: 7, child: Text('7 eixos')),
            DropdownMenuItem(value: 9, child: Text('9 eixos')),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(form.copyWith(anttAxles: value));
          },
        ),
        const SizedBox(height: 10),
        _MoneyField(
          label: 'Piso ANTT oficial',
          value: input.minimumAntt,
          onChanged: onMinimumChanged,
        ),
        _AnttSwitch(
          title: 'Transporte nacional remunerado',
          value: form.isNationalTrip,
          onChanged: (value) => onChanged(form.copyWith(isNationalTrip: value)),
        ),
        _AnttSwitch(
          title: 'Veiculo movido a diesel',
          value: form.isDieselVehicle,
          onChanged: (value) =>
              onChanged(form.copyWith(isDieselVehicle: value)),
        ),
        _AnttSwitch(
          title: 'Carga lotacao / veiculo dedicado',
          value: form.isFullTruckload,
          onChanged: (value) =>
              onChanged(form.copyWith(isFullTruckload: value)),
        ),
        _AnttSwitch(
          title: 'Composicao veicular',
          value: form.isVehicleComposition,
          onChanged: (value) =>
              onChanged(form.copyWith(isVehicleComposition: value)),
        ),
        _AnttSwitch(
          title: 'Alto desempenho',
          value: form.isHighPerformance,
          onChanged: (value) =>
              onChanged(form.copyWith(isHighPerformance: value)),
        ),
        const SizedBox(height: 8),
        _ResultRow(
          'Distancia da rota',
          '${quote.outboundDistanceKm.toStringAsFixed(0)} km',
        ),
        if (quote.returnDistanceKm > 0)
          _ResultRow(
            'Retorno vazio',
            '${quote.returnDistanceKm.toStringAsFixed(0)} km',
          ),
        _ResultRow(
          'Km considerado no custo',
          '${quote.totalDistanceKm.toStringAsFixed(0)} km',
        ),
        _ResultRow('Valor da cotacao', brl(quote.commercialValue)),
        _ResultRow(
          'Situacao',
          quote.isBelowAntt ? 'abaixo do piso' : 'acima do piso',
        ),
      ],
    );
  }
}

class _AnttSwitch extends StatelessWidget {
  const _AnttSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = width < 760 ? constraints.maxWidth : 420.0;
        return SizedBox(
          width: cardWidth,
          child: Card(
            color: Colors.white,
            surfaceTintColor: Colors.white,
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
      },
    );
  }
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker({
    required this.value,
    required this.onChanged,
    required this.onCreate,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onCreate;

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final _repository = CustomerRepository();
  final _controller = TextEditingController();
  List<Customer> _customers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
    _load();
  }

  @override
  void didUpdateWidget(covariant _CustomerPicker oldWidget) {
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

  Future<void> _load() async {
    final customers = await _repository.recentCustomers();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = _controller.text.trim().toLowerCase();
    final matches = typed.isEmpty
        ? _customers.take(5).toList(growable: false)
        : _customers
              .where((customer) {
                final label = '${customer.name} ${customer.document}'
                    .toLowerCase();
                return label.contains(typed);
              })
              .take(5)
              .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Cliente',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Cadastrar cliente',
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.person_add_alt_outlined),
                    ),
            ),
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 8),
          if (!_loading && matches.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final customer in matches)
                  ActionChip(
                    avatar: Icon(
                      customer.type == 'company'
                          ? Icons.apartment_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                    label: Text(customer.name),
                    onPressed: () {
                      _controller.text = customer.name;
                      widget.onChanged(customer.name);
                    },
                  ),
              ],
            )
          else if (!_loading)
            OutlinedButton.icon(
              onPressed: widget.onCreate,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Cadastrar novo cliente'),
            ),
        ],
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
    required this.ibgeMunicipalities,
    required this.onChanged,
  });

  final String label;
  final String value;
  final LocationDistanceService service;
  final List<IbgeMunicipality> ibgeMunicipalities;
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
  void didUpdateWidget(covariant _LocalityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
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
      child: RawAutocomplete<_LocalityOption>(
        textEditingController: _controller,
        focusNode: _focusNode,
        displayStringForOption: (option) => option.label,
        optionsBuilder: (textEditingValue) {
          return _options(textEditingValue.text);
        },
        onSelected: (option) {
          _controller.text = option.label;
          widget.onChanged(option.label);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              helperText: 'Digite livremente ou selecione uma sugestao.',
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
                      leading: Icon(
                        option.isIbge
                            ? Icons.public_outlined
                            : Icons.location_city_outlined,
                      ),
                      title: Text(option.label),
                      subtitle: Text(option.isIbge ? 'IBGE' : 'Base local'),
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

  Iterable<_LocalityOption> _options(String query) {
    final normalized = _normalizeSearch(query);
    if (normalized.length < 2) return const [];
    final localOptions = widget.service
        .search(query)
        .map((locality) => _LocalityOption(locality.label, isIbge: false));
    final ibgeOptions = widget.ibgeMunicipalities
        .where((municipality) {
          final label = _normalizeSearch(municipality.label);
          return label.contains(normalized);
        })
        .take(12)
        .map(
          (municipality) => _LocalityOption(municipality.label, isIbge: true),
        );

    final seen = <String>{};
    return [...localOptions, ...ibgeOptions]
        .where((option) {
          final key = _normalizeSearch(option.label);
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        })
        .take(12);
  }
}

class _LocalityOption {
  const _LocalityOption(this.label, {required this.isIbge});

  final String label;
  final bool isIbge;
}

String _normalizeSearch(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .trim();
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
  void didUpdateWidget(covariant _MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value.toStringAsFixed(2);
    if (oldWidget.value != widget.value && _controller.text != text) {
      _controller.text = text;
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: 'R\$ ',
        ),
        onChanged: (value) {
          final parsed = _parseCommercialNumber(value);
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
  void didUpdateWidget(covariant _PercentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value.toStringAsFixed(2);
    if (oldWidget.value != widget.value && _controller.text != text) {
      _controller.text = text;
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: widget.label, suffixText: '%'),
        onChanged: (value) {
          final parsed = _parseCommercialNumber(value);
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
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value.toStringAsFixed(0);
    if (oldWidget.value != widget.value && _controller.text != text) {
      _controller.text = text;
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffix,
        ),
        onChanged: (value) {
          final parsed = _parseCommercialNumber(value);
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

double? _parseCommercialNumber(String value) {
  final text = value.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (text.isEmpty) return null;

  final hasComma = text.contains(',');
  final hasDot = text.contains('.');
  if (hasComma && hasDot) {
    final commaIndex = text.lastIndexOf(',');
    final dotIndex = text.lastIndexOf('.');
    if (commaIndex > dotIndex) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(text.replaceAll(',', ''));
  }

  if (hasComma) {
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
  }

  if (hasDot) {
    final parts = text.split('.');
    final looksLikeThousands =
        parts.length > 1 &&
        parts.skip(1).every((part) => part.length == 3) &&
        parts.first.length <= 3;
    if (looksLikeThousands) {
      return double.tryParse(parts.join());
    }
  }

  return double.tryParse(text);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.visible,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
