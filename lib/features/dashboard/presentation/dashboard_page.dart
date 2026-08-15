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
    final bestRoute = quotes.isEmpty
        ? 'Guarulhos, SP -> Contagem, MG'
        : '${quotes.first.origin} -> ${quotes.first.destination}';
    final averageTicket = quotes.isEmpty ? 0 : wallet / quotes.length;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Central de receita'),
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
              _CommandCenter(
                quotes: quotes,
                wallet: wallet,
                pendingAntt: pendingAntt,
              ),
              const SizedBox(height: 18),
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
                        detail: '$pendingAntt precisam revisao fiscal',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.trending_up,
                        label: 'Carteira prevista',
                        value: brl(wallet),
                        detail: 'Pipeline comercial',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.verified_outlined,
                        label: 'Dentro da politica',
                        value: '$approvedForSale',
                        detail: 'Acima do piso informado',
                      ),
                      _MetricCard(
                        width: compact ? constraints.maxWidth : 260,
                        icon: Icons.payments_outlined,
                        label: 'Ticket medio',
                        value: brl(averageTicket),
                        detail: 'Media das propostas',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _InsightPanel(
                        width: compact
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 16) * .58,
                        bestRoute: bestRoute,
                        pendingAntt: pendingAntt,
                        quotes: quotes,
                      ),
                      _TodayPlan(
                        width: compact
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 16) * .42,
                        hasQuotes: quotes.isNotEmpty,
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

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({
    required this.quotes,
    required this.wallet,
    required this.pendingAntt,
  });

  final List<SavedQuote> quotes;
  final double wallet;
  final int pendingAntt;

  @override
  Widget build(BuildContext context) {
    final action = quotes.isEmpty
        ? 'Comece criando uma proposta com cliente, rota e valor da mercadoria.'
        : pendingAntt > 0
        ? 'Revise as propostas sem piso ANTT antes de enviar para cliente.'
        : 'Envie as propostas prontas e registre o retorno do cliente ainda hoje.';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 0 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prioridade de hoje',
                      style: TextStyle(
                        color: Color(0xFF9DE3DA),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroBadge(Icons.route_outlined, 'Rotas com margem'),
                        _HeroBadge(Icons.picture_as_pdf_outlined, 'Enviar PDF'),
                        _HeroBadge(Icons.apartment_outlined, 'CNPJ validado'),
                      ],
                    ),
                  ],
                ),
              ),
              if (compact)
                const SizedBox(height: 18)
              else
                const SizedBox(width: 24),
              Expanded(
                flex: compact ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pulso comercial',
                        style: TextStyle(color: Color(0xFFB9D6D2)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        brl(wallet),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${quotes.length} propostas no funil',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      backgroundColor: Colors.white.withValues(alpha: .12),
      side: BorderSide(color: Colors.white.withValues(alpha: .18)),
      labelStyle: const TextStyle(color: Colors.white),
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

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.width,
    required this.bestRoute,
    required this.pendingAntt,
    required this.quotes,
  });

  final double width;
  final String bestRoute;
  final int pendingAntt;
  final List<SavedQuote> quotes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights inteligentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              _InsightTile(
                icon: Icons.route,
                title: 'Melhor rota para trabalhar agora',
                detail: bestRoute,
                tone: const Color(0xFFEAF4F2),
              ),
              _InsightTile(
                icon: Icons.warning_amber_outlined,
                title: pendingAntt > 0
                    ? 'Existe proposta sem validacao ANTT'
                    : 'Piso ANTT sem pendencias no funil',
                detail: pendingAntt > 0
                    ? '$pendingAntt proposta(s) precisam revisao antes do envio.'
                    : 'Continue salvando o piso informado para manter a proposta defensavel.',
                tone: pendingAntt > 0
                    ? const Color(0xFFFFF7E6)
                    : const Color(0xFFEAF4F2),
              ),
              _InsightTile(
                icon: Icons.send_outlined,
                title: 'Acao recomendada',
                detail: quotes.isEmpty
                    ? 'Crie uma cotacao completa e gere o PDF para testar o fluxo comercial.'
                    : 'Compartilhe PDF e Excel das propostas prontas e acompanhe retorno.',
                tone: const Color(0xFFF6F8F8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPlan extends StatelessWidget {
  const _TodayPlan({required this.width, required this.hasQuotes});

  final double width;
  final bool hasQuotes;

  @override
  Widget build(BuildContext context) {
    final steps = hasQuotes
        ? const [
            'Enviar propostas prontas por WhatsApp ou e-mail.',
            'Revisar margens abaixo do piso configurado.',
            'Cadastrar clientes com CNPJ antes da nova cotacao.',
          ]
        : const [
            'Cadastrar ou consultar um cliente por CNPJ.',
            'Criar cotacao com valor de NF, peso, cubagem e rota.',
            'Gerar PDF e planilha para validar apresentacao.',
          ];
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plano do dia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < steps.length; i++)
                _PlanStep(index: i + 1, text: steps[i]),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.go('/cotacao'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Executar agora'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6E8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('$index', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
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
