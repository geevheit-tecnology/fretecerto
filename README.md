# FreteCerto

Aplicativo comercial para cotacao de frete, proposta em PDF, custos operacionais,
rota, carga e sugestao de veiculo.

## Distancia real de rota

O app esta preparado para consultar distancia rodoviaria pelo OpenRouteService
quando uma chave for informada no build:

```bash
flutter run --dart-define-from-file=dart_defines/openroute.local.json
flutter build apk --release --dart-define-from-file=dart_defines/openroute.local.json
```

Use `dart_defines/openroute.local.json` para sua chave real. Esse arquivo fica
ignorado pelo git. O arquivo `dart_defines/openroute.example.json` mostra o
formato esperado.

Sem a chave, a cotacao continua funcionando com a estimativa local por cidades
cadastradas.

O botao `Calcular e aplicar` tenta a API real primeiro e aplica o resultado
direto na cotacao. O botao `Conferir no mapa` abre o Google Maps apenas para
visualizacao da rota.
