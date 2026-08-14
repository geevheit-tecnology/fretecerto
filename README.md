# FreteCerto

Aplicativo comercial para cotacao de frete, proposta em PDF, custos operacionais,
rota, carga e sugestao de veiculo.

## Distancia real de rota

O app esta preparado para consultar distancia rodoviaria pelo Google Maps
Distance Matrix API quando uma chave for informada no build:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=SUA_CHAVE
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=SUA_CHAVE
```

Sem a chave, a cotacao continua funcionando com a estimativa local por cidades
cadastradas. Para producao, restrinja a chave no Google Cloud, habilite
billing e habilite a Distance Matrix API.

O botao `Calcular e aplicar` tenta a API real primeiro e aplica o resultado
direto na cotacao. O botao `Conferir no mapa` abre o Google Maps apenas para
visualizacao da rota.
