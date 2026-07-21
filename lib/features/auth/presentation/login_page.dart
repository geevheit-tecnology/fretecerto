import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final form = Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acesso comercial',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.login),
              label: const Text('Entrar'),
            ),
            TextButton(onPressed: () {}, child: const Text('Recuperar senha')),
          ],
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandPanel(height: 320),
                        const SizedBox(height: 16),
                        form,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _BrandPanel(height: 520)),
                        const SizedBox(width: 32),
                        Expanded(child: form),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = height <= 320;
    return Container(
      height: height,
      padding: EdgeInsets.all(compact ? 22 : 32),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: compact ? 32 : 42,
          ),
          SizedBox(height: compact ? 20 : 132),
          Text(
            'FreteCerto',
            style:
                (compact
                        ? Theme.of(context).textTheme.headlineLarge
                        : Theme.of(context).textTheme.displayMedium)
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
          ),
          const SizedBox(height: 12),
          Text(
            'Orcamentos e propostas de frete rodoviario com composicao comercial clara.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: .86),
            ),
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
