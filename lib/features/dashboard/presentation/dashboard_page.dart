import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/brl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Painel comercial'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => context.go('/cotacao'),
                icon: const Icon(Icons.add),
                label: const Text('Nova cotacao'),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.request_quote,
                        label: 'Cotacoes abertas',
                        value: '18',
                        detail: '7 aguardando retorno',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.trending_up,
                        label: 'Carteira prevista',
                        value: brl(184730),
                        detail: 'Este mes',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.verified_outlined,
                        label: 'Conversao',
                        value: '41%',
                        detail: 'Propostas aprovadas',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fila de propostas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const _ProposalTile(
                        company: 'Forte Expressa',
                        route: 'Guarulhos, SP -> Contagem, MG',
                        amount: 8920,
                        status: 'Em negociacao',
                      ),
                      const _ProposalTile(
                        company: 'Delta Pecas Industriais',
                        route: 'Campinas, SP -> Joinville, SC',
                        amount: 6140,
                        status: 'Aguardando aceite',
                      ),
                      const _ProposalTile(
                        company: 'Rota Farma',
                        route: 'Osasco, SP -> Curitiba, PR',
                        amount: 4760,
                        status: 'Precisa revisar ANTT',
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
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposalTile extends StatelessWidget {
  const _ProposalTile({
    required this.company,
    required this.route,
    required this.amount,
    required this.status,
  });

  final String company;
  final String route;
  final double amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
      title: Text(company),
      subtitle: Text(route),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(brl(amount), style: Theme.of(context).textTheme.titleMedium),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
