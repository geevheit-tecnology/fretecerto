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
    expect(find.text('Acesso seguro'), findsOneWidget);
    expect(find.text('Entrar no painel'), findsOneWidget);
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
    expect(find.text('Inicio'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Acoes rapidas'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(find.text('Acoes rapidas'), findsOneWidget);

    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();
    expect(find.text('Nova cotacao'), findsWidgets);
    expect(find.text('Formulario rapido sem compromisso'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Consultar ANTT oficial'),
      find.byType(CustomScrollView).last,
      const Offset(0, -300),
    );
    expect(find.text('Consultar ANTT oficial'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Mapa da rota'),
      find.byType(CustomScrollView).last,
      const Offset(0, -300),
    );
    expect(find.text('Mapa da rota'), findsOneWidget);
    expect(find.text('Calcular e aplicar'), findsOneWidget);
    expect(find.text('Conferir no mapa'), findsOneWidget);
    await tester.dragUntilVisible(
      find.textContaining('Preencha os dados principais'),
      find.byType(CustomScrollView).last,
      const Offset(0, -500),
    );
    expect(find.textContaining('Preencha os dados principais'), findsOneWidget);
    expect(find.text('Pedido do cliente'), findsWidgets);
    await tester.dragUntilVisible(
      find.widgetWithText(TextField, 'Origem'),
      find.byType(CustomScrollView).last,
      const Offset(0, 500),
    );
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
    await tester.enterText(
      find.widgetWithText(TextField, 'Cliente'),
      'Forte Expressa',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Origem'),
      'Sao Paulo, SP',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'Curitiba, PR',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Peso total'),
      '25000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tipo de carga'),
      'Aco',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Distancia rodoviaria'),
      '410',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calcular cotacao'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.widgetWithText(OutlinedButton, 'Salvar'),
      find.byType(CustomScrollView).last,
      const Offset(0, -900),
    );
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Painel'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsWidgets);
    await tester.dragUntilVisible(
      find.text('Historico de cotacoes'),
      find.byType(CustomScrollView),
      const Offset(0, -400),
    );
    expect(find.text('Historico de cotacoes'), findsOneWidget);
    expect(find.text('Forte Expressa'), findsWidgets);
    expect(find.text('ANTT nao informado'), findsWidgets);
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
