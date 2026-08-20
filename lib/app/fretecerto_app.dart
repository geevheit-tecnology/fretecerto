import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/customers/presentation/customers_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/locations/presentation/location_rates_page.dart';
import '../features/quote/presentation/quote_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/users/presentation/users_page.dart';

GoRouter createRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/cotacao', builder: (_, _) => const QuotePage()),
          GoRoute(
            path: '/clientes',
            builder: (_, state) => CustomersPage(
              returnTo: state.uri.queryParameters['returnTo'],
              customerId: state.uri.queryParameters['customerId'],
            ),
          ),
          GoRoute(
            path: '/localidades',
            builder: (_, _) => const LocationRatesPage(),
          ),
          GoRoute(path: '/usuarios', builder: (_, _) => const UsersPage()),
          GoRoute(
            path: '/configuracoes',
            builder: (_, _) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}

class FreteCertoApp extends StatelessWidget {
  const FreteCertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreteCerto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: createRouter(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = switch (path) {
      '/cotacao' => 1,
      '/clientes' => 2,
      '/localidades' => 3,
      '/usuarios' => 4,
      '/configuracoes' => 5,
      _ => 0,
    };
    final mobileSelectedIndex = switch (path) {
      '/cotacao' => 1,
      '/clientes' => 2,
      '/localidades' => 3,
      '/configuracoes' => 4,
      _ => 0,
    };

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 920)
            _SideMenu(
              selectedIndex: selectedIndex,
              onSelected: (index) => context.go(_routeFor(index)),
              onSignOut: () => _signOut(context),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 920
          ? SafeArea(
              child: NavigationBar(
                selectedIndex: mobileSelectedIndex,
                onDestinationSelected: (index) {
                  if (index == 5) {
                    _signOut(context);
                    return;
                  }
                  context.go(_mobileRouteFor(index));
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Painel',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.request_quote_outlined),
                    selectedIcon: Icon(Icons.request_quote),
                    label: 'Nova',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge),
                    label: 'Clientes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Rotas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: 'Ajustes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.logout),
                    selectedIcon: Icon(Icons.logout),
                    label: 'Sair',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  static String _routeFor(int index) => switch (index) {
    1 => '/cotacao',
    2 => '/clientes',
    3 => '/localidades',
    4 => '/usuarios',
    5 => '/configuracoes',
    _ => '/',
  };

  static String _mobileRouteFor(int index) => switch (index) {
    1 => '/cotacao',
    2 => '/clientes',
    3 => '/localidades',
    4 => '/configuracoes',
    _ => '/',
  };

  static Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/login');
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.selectedIndex,
    required this.onSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF102A2A),
        border: Border(right: BorderSide(color: Color(0xFFE0E6E8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FreteCerto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                    Text(
                      'Comercial de fretes',
                      style: TextStyle(color: Color(0xFFB9D6D2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => onSelected(1),
            icon: const Icon(Icons.add),
            label: const Text('Nova cotacao'),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuItem(
                    selected: selectedIndex == 0,
                    icon: Icons.space_dashboard_outlined,
                    selectedIcon: Icons.space_dashboard,
                    label: 'Painel',
                    detail: 'Prioridades e insights',
                    onTap: () => onSelected(0),
                  ),
                  _MenuItem(
                    selected: selectedIndex == 1,
                    icon: Icons.request_quote_outlined,
                    selectedIcon: Icons.request_quote,
                    label: 'Cotacao',
                    detail: 'Valor, rota e veiculo',
                    onTap: () => onSelected(1),
                  ),
                  _MenuItem(
                    selected: selectedIndex == 2,
                    icon: Icons.apartment_outlined,
                    selectedIcon: Icons.apartment,
                    label: 'Clientes',
                    detail: 'CNPJ e carteira',
                    onTap: () => onSelected(2),
                  ),
                  _MenuItem(
                    selected: selectedIndex == 3,
                    icon: Icons.route_outlined,
                    selectedIcon: Icons.route,
                    label: 'Rotas',
                    detail: 'Tabelas por localidade',
                    onTap: () => onSelected(3),
                  ),
                  _MenuItem(
                    selected: selectedIndex == 4,
                    icon: Icons.group_outlined,
                    selectedIcon: Icons.group,
                    label: 'Usuarios',
                    detail: 'Acessos comerciais',
                    onTap: () => onSelected(4),
                  ),
                  _MenuItem(
                    selected: selectedIndex == 5,
                    icon: Icons.tune_outlined,
                    selectedIcon: Icons.tune,
                    label: 'Configuracoes',
                    detail: 'Custos e impostos',
                    onTap: () => onSelected(5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operacao de hoje',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Revise rotas sem ANTT e envie propostas prontas primeiro.',
                          style: TextStyle(color: Color(0xFFB9D6D2)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected ? const Color(0xFF0E6F68) : Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF102A2A)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        detail,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF526B68)
                              : const Color(0xFFB9D6D2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
