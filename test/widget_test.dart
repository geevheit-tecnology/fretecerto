import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fretecerto/main.dart';

void main() {
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
    await tester.pumpWidget(const FreteCertoAppBootstrap());
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    expect(find.text('Usuarios e acessos'), findsWidgets);
    expect(find.text('Cadastrar usuario'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Configuracoes'), findsWidgets);
    expect(find.text('Impostos e risco'), findsOneWidget);
    expect(find.text('Variaveis por viagem'), findsOneWidget);
  });

  testWidgets('fluxo principal cabe em mobile', (tester) async {
    await setSurface(tester, width: 390, height: 844);
    await tester.pumpWidget(const FreteCertoAppBootstrap());

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Painel comercial'), findsWidgets);

    await tester.tap(find.text('Cotacao'));
    await tester.pumpAndSettle();
    expect(find.text('Nova cotacao'), findsWidgets);
    expect(find.text('Consultar ANTT oficial'), findsOneWidget);
    await tester.tap(find.text('Orcamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proposta').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Origem'),
      'Santos, SP',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'Ribeirao Preto, SP',
    );
    expect(find.text('Santos, SP'), findsOneWidget);
    expect(find.text('Ribeirao Preto, SP'), findsOneWidget);

    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    expect(find.text('Clientes'), findsWidgets);

    await tester.tap(find.text('Localidades'));
    await tester.pumpAndSettle();
    expect(find.text('Tabela de localidades'), findsWidgets);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Configuracoes'), findsWidgets);
  });

  testWidgets('salva cotacao e exibe no painel', (tester) async {
    await tester.pumpWidget(const FreteCertoAppBootstrap());
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cotacao'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Salvar'),
      find.byType(CustomScrollView),
      const Offset(0, -500),
    );
    await tester.tap(find.text('Salvar'));
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
