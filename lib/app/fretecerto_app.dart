import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/customers/presentation/customers_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/locations/presentation/location_rates_page.dart';
import '../features/quote/presentation/quote_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/users/presentation/users_page.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/cotacao', builder: (_, _) => const QuotePage()),
          GoRoute(path: '/clientes', builder: (_, _) => const CustomersPage()),
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

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 920)
            NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(_routeFor(index)),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Painel'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  selectedIcon: Icon(Icons.request_quote),
                  label: Text('Cotacao'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: Text('Clientes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: Text('Localidades'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group),
                  label: Text('Usuarios'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Configuracoes'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 920
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(_routeFor(index)),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Painel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  selectedIcon: Icon(Icons.request_quote),
                  label: 'Cotacao',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: 'Clientes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Localidades',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group),
                  label: 'Usuarios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Ajustes',
                ),
              ],
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
}
