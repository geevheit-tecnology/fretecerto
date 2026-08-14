import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/app/fretecerto_app.dart';
import 'package:fretecerto/core/supabase/supabase_config.dart';
import 'package:fretecerto/core/theme/app_theme.dart';
import 'package:fretecerto/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  Future<void> setSurface(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('abre tela de login do FreteCerto', (tester) async {
    await tester.pumpWidget(const FreteCertoAppBootstrap());

    expect(find.text('FreteCerto'), findsOneWidget);
    expect(find.text('Acesso comercial'), findsOneWidget);
  });

  testWidgets('navega para usuarios e configuracoes', (tester) async {
    await setSurface(tester, width: 1200, height: 900);
    await tester.pumpWidget(_TestApp(initialLocation: '/'));

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    expect(find.text('Usuarios e acessos'), findsWidgets);
    expect(find.text('Cadastrar usuario'), findsOneWidget);

    await tester.tap(find.text('Configuracoes'));
    await tester.pumpAndSettle();
    expect(find.text('Configuracoes'), findsWidgets);
    expect(find.text('Impostos e risco'), findsOneWidget);
    expect(find.text('Variaveis por viagem'), findsOneWidget);
  });

  testWidgets('fluxo principal cabe em mobile', (tester) async {
    await setSurface(tester, width: 390, height: 844);
    await tester.pumpWidget(_TestApp(initialLocation: '/'));
    expect(find.text('Painel comercial'), findsWidgets);

    await tester.tap(find.text('Cotacao'));
    await tester.pumpAndSettle();
    expect(find.text('Nova cotacao'), findsWidgets);
    expect(find.text('Consultar ANTT oficial'), findsOneWidget);
    expect(find.text('Mapa da rota'), findsOneWidget);
    expect(find.text('Calcular e aplicar'), findsOneWidget);
    expect(find.text('Conferir no mapa'), findsOneWidget);
    expect(find.text('Veiculo recomendado'), findsOneWidget);
    expect(find.text('Tipo e cliente'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Origem'),
      'Santos, SP',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'Ribeirao Preto, SP',
    );
    expect(find.text('Santos, SP'), findsWidgets);
    expect(find.text('Ribeirao Preto, SP'), findsWidgets);

    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    expect(find.text('Clientes'), findsWidgets);

    await tester.tap(find.text('Rotas'));
    await tester.pumpAndSettle();
    expect(find.text('Tabela de localidades'), findsWidgets);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Configuracoes'), findsWidgets);
  });

  testWidgets('salva cotacao e exibe no painel', (tester) async {
    await setSurface(tester, width: 1200, height: 900);
    await tester.pumpWidget(_TestApp(initialLocation: '/'));

    await tester.tap(find.text('Cotacao'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.widgetWithText(OutlinedButton, 'Salvar'),
      find.byType(CustomScrollView),
      const Offset(0, -500),
    );
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Salvar'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Painel'));
    await tester.pumpAndSettle();
    expect(find.text('Painel comercial'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Historico de cotacoes'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('Historico de cotacoes'), findsOneWidget);
    expect(find.text('Forte Expressa'), findsWidgets);
    expect(find.text('Pronto para proposta'), findsWidgets);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: createRouter(initialLocation: initialLocation),
      ),
    );
  }
}
