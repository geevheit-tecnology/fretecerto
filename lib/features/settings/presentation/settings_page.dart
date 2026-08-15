import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/brl.dart';
import '../../quote/domain/quote_input.dart';
import '../../quote/presentation/quote_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(quoteInputProvider);
    final notifier = ref.read(quoteInputProvider.notifier);

    void update(QuoteInput next) => notifier.replace(next);

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Configuracoes')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsHero(input: input),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ConfigCard(
                    icon: Icons.percent,
                    title: 'Impostos e risco',
                    children: [
                      _ParameterField(
                        label: 'ICMS',
                        suffix: '%',
                        value: input.icmsPercent,
                        onChanged: (value) =>
                            update(input.copyWith(icmsPercent: value)),
                      ),
                      _ParameterField(
                        label: 'PIS',
                        suffix: '%',
                        value: input.pisPercent,
                        onChanged: (value) =>
                            update(input.copyWith(pisPercent: value)),
                      ),
                      _ParameterField(
                        label: 'COFINS',
                        suffix: '%',
                        value: input.cofinsPercent,
                        onChanged: (value) =>
                            update(input.copyWith(cofinsPercent: value)),
                      ),
                      _ParameterField(
                        label: 'Ad valorem',
                        suffix: '%',
                        value: input.adValoremPercent,
                        onChanged: (value) =>
                            update(input.copyWith(adValoremPercent: value)),
                      ),
                      _ParameterField(
                        label: 'Seguro NF',
                        suffix: '%',
                        value: input.insurancePercent,
                        onChanged: (value) =>
                            update(input.copyWith(insurancePercent: value)),
                      ),
                    ],
                  ),
                  _ConfigCard(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Variaveis por viagem',
                    children: [
                      _ParameterField(
                        label: 'Consumo',
                        suffix: 'km/l',
                        value: input.consumptionKmPerLiter,
                        onChanged: (value) => update(
                          input.copyWith(consumptionKmPerLiter: value),
                        ),
                      ),
                      _ParameterField(
                        label: 'Diesel',
                        suffix: 'R\$',
                        value: input.dieselLiterPrice,
                        onChanged: (value) =>
                            update(input.copyWith(dieselLiterPrice: value)),
                      ),
                      _ParameterField(
                        label: 'Arla sobre diesel',
                        suffix: '%',
                        value: input.arlaPercent,
                        onChanged: (value) =>
                            update(input.copyWith(arlaPercent: value)),
                      ),
                      _ParameterField(
                        label: 'Arla litro',
                        suffix: 'R\$',
                        value: input.arlaLiterPrice,
                        onChanged: (value) =>
                            update(input.copyWith(arlaLiterPrice: value)),
                      ),
                      _ParameterField(
                        label: 'Manutencao',
                        suffix: 'R\$/km',
                        value: input.maintenanceCostPerKm,
                        onChanged: (value) =>
                            update(input.copyWith(maintenanceCostPerKm: value)),
                      ),
                      _ParameterField(
                        label: 'Pneus',
                        suffix: 'R\$/km',
                        value: input.tireCostPerKm,
                        onChanged: (value) =>
                            update(input.copyWith(tireCostPerKm: value)),
                      ),
                      _ParameterField(
                        label: 'Rastreamento',
                        suffix: 'R\$',
                        value: input.trackingFee,
                        onChanged: (value) =>
                            update(input.copyWith(trackingFee: value)),
                      ),
                    ],
                  ),
                  _ConfigCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Fixos rateados',
                    children: [
                      _ParameterField(
                        label: 'Depreciacao mensal',
                        suffix: 'R\$',
                        value: input.vehicleDepreciationMonthly,
                        onChanged: (value) => update(
                          input.copyWith(vehicleDepreciationMonthly: value),
                        ),
                      ),
                      _ParameterField(
                        label: 'Salario motorista',
                        suffix: 'R\$',
                        value: input.driverSalaryMonthly,
                        onChanged: (value) =>
                            update(input.copyWith(driverSalaryMonthly: value)),
                      ),
                      _ParameterField(
                        label: 'Encargos motorista',
                        suffix: '%',
                        value: input.driverBurdenPercent,
                        onChanged: (value) =>
                            update(input.copyWith(driverBurdenPercent: value)),
                      ),
                      _ParameterField(
                        label: 'Seguro veiculo anual',
                        suffix: 'R\$',
                        value: input.vehicleInsuranceYearly,
                        onChanged: (value) => update(
                          input.copyWith(vehicleInsuranceYearly: value),
                        ),
                      ),
                      _ParameterField(
                        label: 'Administrativo mensal',
                        suffix: 'R\$',
                        value: input.administrativeCostsMonthly,
                        onChanged: (value) => update(
                          input.copyWith(administrativeCostsMonthly: value),
                        ),
                      ),
                      _ParameterField(
                        label: 'Outros fixos por viagem',
                        suffix: 'R\$',
                        value: input.otherFixedCostsPerTrip,
                        onChanged: (value) => update(
                          input.copyWith(otherFixedCostsPerTrip: value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _CalculationPolicyCard(input: input),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.input});

  final QuoteInput input;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Central de parametros comerciais',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajuste impostos, custos operacionais, margem e regras que entram nas cotacoes antes de enviar proposta ao cliente.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: .86),
          ),
        ),
      ],
    );
    final metrics = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _HeroMetric(label: 'Margem', value: '${input.marginPercent}%'),
        _HeroMetric(label: 'ICMS', value: '${input.icmsPercent}%'),
        _HeroMetric(label: 'Diesel', value: brl(input.dieselLiterPrice)),
        _HeroMetric(
          label: 'ANTT',
          value: input.minimumAntt > 0 ? brl(input.minimumAntt) : 'manual',
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF103B3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, const SizedBox(height: 16), metrics],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: content),
                const SizedBox(width: 20),
                Expanded(child: metrics),
              ],
            ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9DE3DA),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < 840 ? width : 390,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ParameterField extends StatefulWidget {
  const _ParameterField({
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
  State<_ParameterField> createState() => _ParameterFieldState();
}

class _ParameterFieldState extends State<_ParameterField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _ParameterField oldWidget) {
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
          suffixText: widget.suffix,
          suffixIcon: const Icon(Icons.edit_outlined),
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _CalculationPolicyCard extends StatelessWidget {
  const _CalculationPolicyCard({required this.input});

  final QuoteInput input;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politica de calculo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PolicyChip(
                  label: 'Margem atual',
                  value: '${input.marginPercent.toStringAsFixed(1)}%',
                ),
                _PolicyChip(
                  label: 'Viagens por mes',
                  value: input.monthlyTrips.toStringAsFixed(0),
                ),
                _PolicyChip(label: 'Pedagio ida', value: brl(input.toll)),
                _PolicyChip(
                  label: 'Piso ANTT',
                  value: input.minimumAntt > 0
                      ? brl(input.minimumAntt)
                      : 'manual',
                ),
                const _PolicyChip(
                  label: 'Consulta ANTT',
                  value: 'calculadorafrete.antt.gov.br',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Os campos acima alimentam a cotacao atual. O piso ANTT continua manual e deve ser conferido na calculadora oficial antes de enviar proposta comercial.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyChip extends StatelessWidget {
  const _PolicyChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check_circle_outline, size: 18),
      label: Text('$label: $value'),
    );
  }
}
