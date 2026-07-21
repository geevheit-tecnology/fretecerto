import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Configuracoes')),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _ConfigCard(
                    icon: Icons.percent,
                    title: 'Impostos e taxas',
                    fields: [
                      'ICMS origem/destino',
                      'PIS',
                      'COFINS',
                      'Ad valorem',
                      'Seguro',
                      'GRIS',
                    ],
                  ),
                  _ConfigCard(
                    icon: Icons.payments_outlined,
                    title: 'Custos operacionais',
                    fields: [
                      'Combustivel por km',
                      'Manutencao por km',
                      'Diaria motorista',
                      'Rastreamento',
                      'Pedagio',
                    ],
                  ),
                  _ConfigCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Veiculos padrao',
                    fields: ['Fiorino', 'VUC', 'Truck', 'Carreta simples'],
                  ),
                  _ConfigCard(
                    icon: Icons.inventory_outlined,
                    title: 'Carrocerias',
                    fields: ['Bau', 'Sider', 'Carga seca', 'Frigorifica'],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _CalculationPolicyCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.icon,
    required this.title,
    required this.fields,
  });

  final IconData icon;
  final String title;
  final List<String> fields;

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
              for (final field in fields) ...[
                TextField(
                  decoration: InputDecoration(
                    labelText: field,
                    suffixIcon: const Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Adicionar parametro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalculationPolicyCard extends StatelessWidget {
  const _CalculationPolicyCard();

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
              children: const [
                _PolicyChip(label: 'Margem padrao', value: '22%'),
                _PolicyChip(label: 'Margem minima', value: '12%'),
                _PolicyChip(label: 'Fator cubagem', value: '300 kg/m3'),
                _PolicyChip(label: 'Piso ANTT', value: 'Configuravel/manual'),
                _PolicyChip(
                  label: 'Consulta ANTT',
                  value: 'calculadorafrete.antt.gov.br',
                ),
                _PolicyChip(label: 'Vigencia', value: 'Julho/2026'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'ICMS por estado, PIS, COFINS, ad valorem, seguro, margem e piso ANTT entram como parametros comerciais configuraveis. A importacao automatica da tabela ANTT oficial ainda depende de integracao com fonte homologada.',
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
