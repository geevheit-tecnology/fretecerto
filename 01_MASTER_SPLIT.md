# Refatoração completa do FreteCerto — Flutter + Supabase

## Contexto

Tenho um aplicativo Flutter chamado **FreteCerto**.

O projeto já existe, já possui funcionalidades implementadas e já está integrado ao **Supabase**.

NÃO quero criar um aplicativo novo.

Quero **evoluir o aplicativo existente**, mantendo sua arquitetura, banco de dados, integrações e funcionalidades que já funcionam.

O objetivo principal desta tarefa é transformar o FreteCerto em um aplicativo:

* simples;
* rápido;
* confiável;
* objetivo;
* profissional;
* fácil de usar;
* visualmente limpo;
* com poucos passos para realizar uma cotação;
* adequado para uso diário por transportadores, embarcadores e profissionais de logística.

A referência visual é um aplicativo moderno de cotação de frete: tela limpa, poucos elementos, botões claros, informações organizadas e foco total na cotação.

---

# REGRA PRINCIPAL

Antes de alterar qualquer coisa:

1. Analise todo o projeto existente.
2. Entenda a arquitetura atual.
3. Identifique onde estão:

   * telas;
   * widgets;
   * modelos;
   * serviços;
   * repositories;
   * providers/controllers;
   * integração Supabase;
   * cálculo de frete;
   * cálculo de custos;
   * rota/distância;
   * geração de PDF;
   * cadastro de cidades;
   * sugestão de veículo;
   * histórico;
   * configurações.
4. Execute os testes existentes.
5. Faça um diagnóstico do que já funciona.
6. NÃO substitua funcionalidades existentes sem necessidade.
7. NÃO recrie o banco Supabase.
8. NÃO crie tabelas duplicadas.
9. NÃO remova dados existentes.
10. NÃO faça mudanças destrutivas.

Primeiro entenda o sistema. Depois refatore.

---

# OBJETIVO DE UX

A aplicação deve seguir o princípio:

> "Abra o aplicativo → informe origem, destino e carga → calcule → veja o resultado."

A cotação precisa ser o fluxo principal do aplicativo.

Evitar telas excessivamente carregadas.

Evitar excesso de menus.

Evitar formulários gigantes.

Evitar informações técnicas desnecessárias para o usuário comum.

---

# NOVA ESTRUTURA DE NAVEGAÇÃO

Organize o aplicativo com uma navegação simples.

Sugestão:

## 1. Cotar

Tela principal.

Campos:

* Origem
* Destino
* Tipo de carga
* Peso
* Tipo de veículo
* Distância
* Custos adicionais, quando necessários

Botão principal:

**CALCULAR COTAÇÃO**

---

## 2. Resultado da Cotação

Após calcular, mostrar de forma extremamente clara:

### Valor recomendado

Exemplo:

R$ 7.850,00

### Resumo

* Origem
* Destino
* Distância
* Peso
* Tipo de carga
* Veículo

### Composição do valor

* Frete base
* Combustível
* Pedágio
* Custos operacionais
* Outros custos
* Margem
* Valor final

Não esconder os valores importantes.

O usuário deve conseguir entender de onde veio o valor.

---

# CONFIABILIDADE DO CÁLCULO

Esta é uma das partes mais importantes.

Não quero que o aplicativo pareça apenas uma calculadora visual.

O cálculo precisa ser determinístico e rastreável.

Cada cotação deve possuir:

* entrada utilizada;
* distância utilizada;
* origem;
* destino;
* peso;
* tipo de veículo;
* tipo de carga;
* parâmetros de cálculo;
* custos;
* resultado final;
* data/hora;
* identificador da cotação.

Sempre que possível, preservar os dados usados para produzir o resultado.

Se o sistema utilizar valores cadastrados no Supabase, utilizar esses dados como fonte oficial.

Não colocar valores fixos espalhados pelo código.

Evitar:

```dart
valor = 7850;
```

ou regras semelhantes hardcoded em widgets.

As regras de negócio devem ficar separadas da interface.

---

# DISTÂNCIA

O README informa que o aplicativo está preparado para utilizar o OpenRouteService quando a chave for informada.

Preservar essa funcionalidade.

O comportamento esperado é:

1. tentar obter a distância rodoviária real;
2. se a API estiver disponível, utilizar o resultado;
3. se a API não estiver disponível, utilizar o mecanismo local já existente;
4. informar claramente ao usuário quando a distância for estimada;
5. nunca apresentar uma distância estimada como se fosse uma distância real.

A funcionalidade existente de:

**"Calcular e aplicar"**

deve continuar funcionando.

A funcionalidade:

**"Conferir no mapa"**

também deve continuar funcionando.

Não remover a integração atual.

---

# SUPABASE

O Supabase já está integrado.

Preservar a integração existente.

Antes de criar qualquer tabela nova, verificar se a informação já existe no banco.

Não duplicar:

* veículos;
* usuários;
* cidades;
* cotações;
* configurações;
* custos;
* parâmetros.

Utilizar repositories/services para acesso aos dados.

Evitar chamadas diretas ao Supabase espalhadas pelas telas.

Se houver código desse tipo:

```dart
supabase.from(...)
```

espalhado por diversos widgets, avaliar a centralização sem quebrar o funcionamento.

---

# DESIGN VISUAL

Quero um design inspirado em aplicativos financeiros/logísticos modernos.

Características:

* fundo claro;
* azul-marinho como cor principal;
* verde para ações positivas;
* cards limpos;
* bordas arredondadas;
* sombras discretas;
* tipografia grande para valores;
* ícones simples;
* bastante espaço em branco;
* boa hierarquia visual.

NÃO deixar o aplicativo excessivamente escuro.

NÃO criar uma interface cheia de gradientes.

NÃO exagerar nas animações.

NÃO criar aparência genérica de dashboard SaaS.

O usuário precisa olhar para a tela e saber imediatamente:

> "Onde faço uma cotação?"

---

# TELA PRINCIPAL

Criar uma Home extremamente objetiva.

Estrutura aproximada:

---

FreteCerto

Cotação de Frete

Origem
[ São Paulo - SP          > ]

Destino
[ Curitiba - PR           > ]

Carga
[ Carga geral             > ]

Peso
[ 10.000 kg                 ]

Veículo
[ Carreta 3 eixos         > ]

[ CALCULAR COTAÇÃO ]

---

Última cotação

São Paulo → Curitiba

R$ 7.850,00

---

Atalhos:

Nova cotação
Histórico
Veículos
Configurações

---

Não precisa reproduzir exatamente esse layout.

Use como direção de UX.

---

# RESULTADO

O resultado deve ser a tela mais importante depois da cotação.

Mostrar primeiro:

## VALOR DA COTAÇÃO

R$ XX.XXX,XX

Depois:

### Resumo da viagem

Origem → Destino

Distância: XXXX km

Carga: XXXXX

Peso: XXXX kg

Veículo: XXXXX

Depois:

### Composição

Frete base
R$ XXXX

Combustível
R$ XXXX

Pedágios
R$ XXXX

Custos operacionais
R$ XXXX

Margem
R$ XXXX

---

TOTAL

R$ XX.XXX

---

# AÇÕES DO RESULTADO

Botões:

**Compartilhar**

**Gerar proposta PDF**

**Salvar cotação**

**Nova cotação**

**Conferir rota**

O usuário deve conseguir executar essas ações sem procurar em menus.

---

# HISTÓRICO

Criar/ajustar uma tela simples de histórico.

Cada item deve mostrar:

Origem → Destino

Data

Valor

Distância

Status

Ao tocar:

abrir os detalhes completos da cotação.

Adicionar busca e filtros apenas se fizerem sentido para a quantidade de registros.

Não transformar o histórico em uma tela complexa.

---

# ESTADOS DA APLICAÇÃO

Todas as telas importantes precisam tratar:

* loading;
* sucesso;
* erro;
* ausência de dados;
* falta de internet;
* API indisponível;
* Supabase indisponível;
* distância estimada;
* cálculo incompleto.

Nunca deixar o usuário olhando para uma tela vazia sem explicação.

Mensagens de erro devem ser humanas.

Evitar mensagens técnicas como:

"Exception: PostgrestException..."

Mostrar algo como:

"Não foi possível consultar os dados agora. Verifique sua conexão e tente novamente."

Registrar o erro tecnicamente nos logs quando apropriado.

---

# VALIDAÇÃO

Validar antes de calcular:

* origem preenchida;
* destino preenchido;
* peso válido;
* tipo de carga;
* veículo;
* distância válida;
* valores numéricos;
* custos adicionais.

Não permitir cotação silenciosamente inválida.

Mostrar exatamente qual campo precisa ser corrigido.

---

# PERFORMANCE

Evitar:

* rebuilds desnecessários;
* consultas repetidas ao Supabase;
* chamadas duplicadas à API de rota;
* carregamento desnecessário de dados;
* chamadas de rede diretamente durante build.

Usar cache quando fizer sentido.

Não prejudicar a simplicidade do código apenas por otimização prematura.

---

# ARQUITETURA

Manter a arquitetura existente sempre que ela estiver saudável.

Se houver necessidade de reorganização, separar claramente:

UI

↓

Controller / State

↓

Use Case / Service

↓

Repository

↓

Supabase / API

Não colocar regra de cálculo dentro de:

* Widget;
* build();
* botão;
* formulário.

A regra de cálculo deve ser testável isoladamente.

---

# TESTES

Criar ou melhorar testes para a parte crítica.

Principalmente:

### Cálculo

Mesma entrada → mesmo resultado.

### Distância

API real disponível.

API indisponível.

Fallback local.

### Validação

Peso inválido.

Origem vazia.

Destino vazio.

### Persistência

Salvar cotação.

Recuperar cotação.

Histórico.

### PDF

Garantir que a geração da proposta continue funcionando.

Não alterar uma funcionalidade existente sem teste quando ela for crítica.

---

# SEGURANÇA

Verificar:

* credenciais;
* variáveis de ambiente;
* Supabase keys;
* secrets;
* tratamento de dados;
* autenticação existente;
* regras de acesso do Supabase.

Não colocar API keys diretamente no código.

Manter o uso existente de:

```bash
--dart-define
```

para configurações sensíveis.

---

# RESPONSIVIDADE

O aplicativo é Flutter.

Garantir boa experiência em:

* Android;
* iPhone;
* tablets;
* Flutter Web, caso o projeto atual utilize.

Não fazer uma tela que funciona apenas em uma resolução.

---

# MICROINTERAÇÕES

Usar somente quando melhorarem a experiência.

Exemplos:

* botão mostrando progresso durante cálculo;
* transição suave para resultado;
* feedback ao salvar;
* confirmação ao gerar PDF.

Evitar animações decorativas.

---

# O QUE NÃO FAZER

NÃO:

* criar outro aplicativo;
* recriar o Supabase;
* apagar tabelas;
* substituir o banco;
* criar dados duplicados;
* remover funcionalidades existentes;
* remover OpenRouteService;
* remover geração de PDF;
* remover histórico;
* colocar regras de negócio dentro da UI;
* criar dezenas de telas desnecessárias;
* transformar o aplicativo em dashboard corporativo;
* usar valores fictícios em produção;
* mascarar falhas de API;
* apresentar estimativa como dado real;
* quebrar funcionalidades existentes para melhorar o visual.

---

# PROCESSO OBRIGATÓRIO

Execute a tarefa em etapas.

## ETAPA 1 — AUDITORIA

Analise:

* estrutura do projeto;
* pubspec;
* arquitetura;
* telas;
* serviços;
* repositories;
* Supabase;
* modelos;
* cálculo;
* rota;
* PDF;
* histórico;
* testes.

Produza um diagnóstico técnico antes das alterações.

## ETAPA 2 — MAPA DO SISTEMA

Identifique:

* o que já funciona;
* o que está incompleto;
* o que está frágil;
* o que pode ser reaproveitado;
* o que precisa ser refatorado.

## ETAPA 3 — REFATORAÇÃO

Faça as alterações de forma incremental.

Prioridade:

1. confiabilidade;
2. cálculo;
3. fluxo de cotação;
4. UX;
5. UI;
6. performance;
7. detalhes visuais.

## ETAPA 4 — TESTES

Executar:

```bash
flutter analyze
flutter test
```

Se o projeto possuir testes adicionais, executar também.

Corrigir todos os erros introduzidos pela alteração.

## ETAPA 5 — VALIDAÇÃO FINAL

Verificar manualmente o fluxo:

```text
Abrir app
↓
Nova cotação
↓
Origem
↓
Destino
↓
Carga
↓
Peso
↓
Veículo
↓
Calcular
↓
Distância
↓
Cálculo
↓
Resultado
↓
Salvar
↓
Histórico
↓
Gerar PDF
↓
Compartilhar
```

Esse fluxo precisa funcionar de ponta a ponta.

---

# IMPORTANTE SOBRE O RESULTADO

Não quero apenas "deixar bonito".

Quero que o FreteCerto pareça um aplicativo profissional de cotação de frete e, principalmente, que o usuário confie no resultado.

A interface deve transmitir:

**Simplicidade + Transparência + Confiabilidade + Logística**

O valor da cotação deve ser o protagonista.

Quando terminar, informe:

1. quais arquivos foram alterados;
2. quais telas foram modificadas;
3. quais regras de negócio foram alteradas;
4. quais funcionalidades existentes foram preservadas;
5. quais problemas de confiabilidade foram encontrados;
6. quais testes foram executados;
7. resultado de `flutter analyze`;
8. resultado de `flutter test`;
9. se houve alteração no Supabase;
10. se houve alteração de schema/migration;
11. qualquer ponto que ainda precise de atenção.

Não faça deploy automaticamente.

Não altere produção sem autorização explícita.
