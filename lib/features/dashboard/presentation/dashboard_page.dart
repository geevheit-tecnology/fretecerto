import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/brl.dart';
import '../../quote/domain/saved_quote.dart';
import '../../quote/presentation/quote_history_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quoteHistoryProvider);
    final openQuotes = quotes.length;
    final wallet = quotes.fold<double>(
      0,
      (total, quote) => total + quote.commercialValue,
    );
    final pendingAntt = quotes
        .where((quote) => quote.minimumAnttValue <= 0)
        .length;
    final approvedForSale = quotes.where((quote) => !quote.isBelowAntt).length;

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
                        label: 'Cotacoes salvas',
                        value: '$openQuotes',
                        detail: '$pendingAntt sem piso ANTT',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.trending_up,
                        label: 'Carteira prevista',
                        value: brl(wallet),
                        detail: 'Historico da sessao',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.verified_outlined,
                        label: 'Dentro da politica',
                        value: '$approvedForSale',
                        detail: 'Acima do piso informado',
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
                        'Historico de cotacoes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (quotes.isEmpty)
                        const _EmptyHistory()
                      else
                        for (final quote in quotes)
                          _ProposalTile.fromQuote(quote),
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

  factory _ProposalTile.fromQuote(SavedQuote quote) {
    return _ProposalTile(
      company: quote.customerName,
      route: '${quote.origin} -> ${quote.destination}',
      amount: quote.commercialValue,
      status: quote.isBelowAntt
          ? 'Revisar piso ANTT'
          : quote.minimumAnttValue <= 0
          ? 'ANTT nao informado'
          : 'Pronto para proposta',
    );
  }

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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.save_outlined)),
      title: const Text('Nenhuma cotacao salva ainda'),
      subtitle: const Text(
        'Salve uma cotacao para acompanhar a fila comercial.',
      ),
      trailing: FilledButton.icon(
        onPressed: () => context.go('/cotacao'),
        icon: const Icon(Icons.add),
        label: const Text('Criar'),
      ),
    );
  }
}
