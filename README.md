# Pata Amiga — Modelo Dimensional (Mini-Projeto Módulo 2)

Case da rede catarinense de pet shops **Pata Amiga**: 32 lojas, 4.044
pedidos entre 01/09/2023 e 31/03/2024, vindos de três sistemas que não se
falam. Este repositório constrói o modelo dimensional que torna
respondíveis as cinco perguntas de negócio da diretoria, com PostgreSQL.

> 🎥 **Vídeo (até 5 min):** `<link do Google Drive, modo leitor público>`

## Estrutura do repositório

```
.
├── README.md                    -> este arquivo
├── sql/
│   ├── 00-conferencia.sql          -> não faz parte da entrega; usado para validar cada etapa
│   ├── 01-carga-staging.sql        -> cria o banco e carrega as 3 tabelas de origem (fornecido)
│   ├── 02-dimensoes-prontas.sql    -> dim_tempo e dim_loja prontas + CREATE TABLE das demais (fornecido)
│   ├── 03-dimensoes.sql            -> dim_categoria, dim_praca, bridge_loja_praca (construído)
│   ├── 04-fato.sql                 -> fato_pedido, 4.044 linhas (construído)
│   └── 05-respostas.sql            -> as 5 consultas de negócio (construído)
├── diagrama/
│   └── Diagrama Modelo Estrela.png -> diagrama criado em powerpoint e salvo em .png
└── sprints/                        -> como o trabalho foi organizado, sprint a sprint
    ├── sprint-01-diagnostico.md
    ├── sprint-02-tratamento-e-base.md
    ├── sprint-03-dimensoes.md
    ├── sprint-04-fato.md
    └── sprint-05-respostas-e-entrega.md
```

## Pré-requisitos para rodar em qualquer máquina

- **PostgreSQL 16** (ou qualquer 13+) instalado e com o serviço rodando.
- **Cliente `psql`** disponível no terminal (ele já vem junto do servidor na maioria das instalações). 
Teste com:
  ```bash
  psql --version
  ```
  Se o comando não for reconhecido no Windows, normalmente é falta do
  caminho de instalação (ex.: `C:\Program Files\PostgreSQL\16\bin`) no
  PATH do sistema.
- Não é preciso nenhuma extensão do VS Code: os comandos abaixo rodam no
  terminal integrado (`` Ctrl+` ``), que usa o mesmo shell do sistema
  operacional.
- O `psql` pode pedir a senha do usuário `postgres` a cada arquivo — isso
  é esperado, não é erro.
- Os scripts têm acentuação (nomes de cidade, categorias). Se aparecer
  caractere estranho no resultado, é só o encoding do terminal — não afeta
  a carga dos dados, que continuam em UTF-8 no banco.

## Como reproduzir o banco do zero

Rode nesta ordem, com PostgreSQL (o primeiro arquivo já cria o banco):

```bash
psql -U postgres -d postgres -f sql/01-carga-staging.sql
psql -U postgres -d dw_pata_amiga -f sql/02-dimensoes-prontas.sql
psql -U postgres -d dw_pata_amiga -f sql/03-dimensoes.sql
psql -U postgres -d dw_pata_amiga -f sql/04-fato.sql
psql -U postgres -d dw_pata_amiga -f sql/05-respostas.sql
```

Depois de cada arquivo, `sql/00-conferencia.sql` traz o bloco de conferência
correspondente — todos os números abaixo foram tirados dele, rodando o projeto inteiro do zero.

## Organização em sprints

O projeto foi dividido em 5 sprints, uma por arquivo/etapa (detalhe de cada
uma em `sprints/`), pensadas para virar branchs/commits distintos:

| Sprint | Entrega | Branch sugerida |
|---|---|---|
| 1 — Diagnóstico | conta os defeitos da origem | `sprint-1-diagnostico` |
| 2 — Tratamento e base | fecha as regras de limpeza; carrega `dim_tempo`/`dim_loja` | `sprint-2-tratamento` |
| 3 — Dimensões próprias | `dim_categoria`, `dim_praca`, `bridge_loja_praca` | `sprint-3-dimensoes` |
| 4 — Fato | `fato_pedido`, 4.044 linhas, zero FK nula | `sprint-4-fato` |
| 5 — Respostas e entrega | as 5 consultas, diagrama, README | `sprint-5-respostas` |

## 1. Diagnóstico da origem

Contagens tiradas de `stg_pedido` / `stg_loja` / `stg_loja_praca` (4.044 /
32 / 48 linhas), antes de qualquer tratamento:

| O que | Valor |
|---|---|
| Grafias distintas de categoria (`CategoriaProduto`) | **37** |
| Grafias distintas de nome de loja (`Loja-Nome`) | **128** — mistura acento/sem acento, caixa alta/baixa, `/SC` no fim, espaço duplo e 3 erros de digitação/apelido/abreviação |
| Grafias distintas de `HouveDesconto` | **17** (`S`, `SIM`, `1`, `X`, `true`... todas caem em 3 valores) |
| Grafias distintas de `CanalPedido` | **20** (`WHATSAPP` contém `APP` — a ordem do de-para importa) |
| Pedidos sem `Cod Loja` preenchido | **1.575 (~39%)** → a *busca* da loja tem de ser pelo nome, não pelo código |
| Pedidos sem nome de loja nenhum | **3** → vão para a linha -1 |
| Marco "Separação" em branco | **1.077** |
| Marco "Nota Fiscal" em branco | **1.338** |
| Marco "Despacho" em branco | **1.665** |
| Marco "Entrega ao cliente" em branco | **1.953** — processo em aberto, não erro |
| Máscara de data do pedido | `MM/DD/YYYY HH12:MI AM` (americana) — confirmada nas 4.044 linhas |

## 2. Decisões de tratamento

- **Data:** pedido em `MM/DD/YYYY HH12:MI AM`; os 4 marcos da entrega em
  `YYYY-MM-DD`; a chave da `dim_tempo` é a própria data virando
  `AAAAMMDD` via `TO_CHAR(..., 'YYYYMMDD')::int`.
- **Números:** vazio ou `-` vira `NULL`, nunca `0` (um `0` no lugar de
  "não aconteceu" faria o gargalo da P1 parecer mais rápido do que é).
  `vl_liquido` usa a expressão do enunciado para conviver com `"R$ 1.850,00"`,
  `"1850.00"` e `"1.200"` na mesma coluna.
- **Categoria:** de-para na ordem `MED → PETISC → RA → HIG → BRINQ → ACESS
  → SERV → Não Informado`, testado em `UPPER(TRANSLATE(...))` sem acento.
  Testar `RA` antes de `MED` faria "Ração Medicamentosa" cair em Ração —
  por isso `MED` vem primeiro.
- **Nome da loja:** primeiro a parte mecânica (`REPLACE` tira `/SC` e
  espaço duplo, `UPPER`+`TRANSLATE` tira acento e caixa), **e só depois** a
  *busca* em `dim_loja.chave_loja`. Os 3 casos que sobram (erro de
  digitação, apelido, abreviação) viraram `CASE WHEN` manual **antes** do
  `JOIN` — nunca depois.
- **Canal:** `WHATS` testado antes de `APP`, ou os 414 pedidos de WhatsApp
  cairiam dentro do App.
- **Categoria/loja na fato:** buscadas por um `JOIN`/`LEFT JOIN` de uma
  linha só, pela grafia crua — nenhuma subconsulta na carga.
- **FK nunca nula:** quando o dado falta (loja, entrega), a FK aponta para
  a linha `-1 = "Não Informado"` da dimensão correspondente.

## 3. O modelo (estrela)

![Modelo dimensional em estrela](Projeto_Pata_Amiga/pata_amiga_dw/diagrama/Diagrama Modelo Estrela.png)

- **`fato_pedido`** no centro — grão: **1 linha = 1 pedido** (4.044 linhas).
- **`dim_tempo`** ligada **duas vezes** à fato (`sk_tempo_pedido` e
  `sk_tempo_entrega`): é a mesma tabela em dois papéis.
- **`dim_loja`** e **`dim_categoria`** ligadas direto à fato.
- **`dim_praca`** não tem FK na fato: ela se liga a `dim_loja` através da
  **`bridge_loja_praca`** (uma loja atende mais de uma praça, com um
  `fator_publico` que soma 1,00 por loja) — o único caminho indireto do
  modelo.
- `numero_pedido` é uma **dimensão degenerada**: fica na própria fato por
  não ter nenhum atributo pendurado nela.

## 4. As cinco respostas

*(números tirados de `sql/05-respostas.sql`, com reconciliação perfeita
contra a fato — ver `00-conferencia.sql`: faturamento total = **R$
1.793.309**, e a soma rateada por praça mais os pedidos sem loja fecha com
diferença **zero** contra o total da rede.)*

### P1 — Onde está o gargalo da entrega?

| Intervalo | Média (dias) |
|---|---|
| Integração → Separação | 2,1 |
| Separação → Nota | 0,6 |
| **Nota → Despacho** | **4,1** ⟵ maior intervalo |
| Despacho → Entrega | 2,1 |
| **Total (Integração → Entrega)** | **9,0** |

O gargalo está entre a nota fiscal e o despacho para a transportadora, não
na entrega em si — como a diretoria suspeitava.

Por porte de loja, o gargalo **não é igual**: lojas **Pequenas** demoram
quase o dobro no total (15,2 dias, com 8,5 dias só de Nota→Despacho) contra
8,0 (Média) e 7,9 dias (Grande). Loja pequena parece ter um funil de
despacho mais lento — possível ponto de atenção operacional.

### P2 — Qual categoria concentra o faturamento?

| Categoria | Faturamento (R$) | % do total |
|---|---|---|
| **Ração** | **1.076.203** | **60,0%** |
| Medicamento | 305.904 | 17,1% |
| Petisco | 128.590 | 7,2% |
| Serviço | 94.001 | 5,2% |
| Higiene | 92.314 | 5,2% |
| Acessório | 64.661 | 3,6% |
| Brinquedo | 31.635 | 1,8% |

Ração é a categoria campeã e é a mesma nos **três** portes de loja (Grande,
Média e Pequena) — a concentração em Ração/Medicamento (77% juntas) é
estrutural da rede, não um efeito de porte.

### P3 — O desconto funciona igual em todo canal?

Ticket médio SEM desconto fica sempre entre R$ 170 e R$ 213 em todos os
canais; COM desconto salta para R$ 488–561 — ou seja, o desconto está
associado a pedidos de ticket **maior**, não menor, e esse padrão é
consistente em todos os canais (não há canal em que o desconto derruba o
ticket). Faturamento por canal:

| Canal | Faturamento (R$) | % do total |
|---|---|---|
| App | 552.134 | 30,8% |
| Site | 450.569 | 25,1% |
| Loja Física | 360.677 | 20,1% |
| WhatsApp | 188.679 | 10,5% |
| Telefone | 123.419 | 6,9% |
| Não Informado | 117.830 | 6,6% |

Como o padrão é igual nos 5 canais, os dados **não sustentam** diferenciar
a política de desconto por canal hoje.

### P4 — Qual praça de atendimento concentra o faturamento?

Faturamento rateado pelo `fator_publico` (a soma bate com o total da rede):

| Praça | Faturamento rateado (R$) | Domicílios com pet | R$ por domicílio |
|---|---|---|---|
| **Vale do Itajaí** | **633.746** | 148.000 | **4,28** |
| Grande Florianópolis | 283.547 | 132.000 | 2,15 |
| Litoral Sul | 137.051 | 58.000 | 2,36 |
| Norte Industrial | 175.432 | 96.000 | 1,83 |
| Litoral Norte | 128.873 | 61.000 | 2,11 |
| Serra Catarinense | 80.478 | 44.000 | 1,83 |
| Carbonífera | 88.707 | 67.000 | 1,32 |
| Extremo Oeste | 98.359 | 63.000 | 1,56 |
| Meio-Oeste | 58.956 | 51.000 | 1,16 |
| **Foz do Itajaí** | 46.750 | 74.000 | **0,63** ⟵ mais baixo |
| Planalto Serrano | 29.323 | 29.000 | 1,01 |
| Planalto Norte | 31.101 | 33.000 | 0,94 |

Vale do Itajaí concentra o faturamento e também tem o maior retorno por
domicílio com pet — praça já bem atendida (6 lojas). Foz do Itajaí é a
praça com o menor faturamento por domicílio, mesmo tendo 74.000 domicílios
com pet — sinal de atendimento indireto (via lojas de outras praças) e
possível espaço de crescimento.

### P5 — Onde abrir a próxima loja?

**a) Itens por mil habitantes × tempo de entrega** — as cidades no topo
(Rio dos Cedros: 41,9 itens/mil hab.; Presidente Getúlio: 34,8; Ibirama:
32,1) são todas lojas **Pequenas**, com a maior demanda relativa da rede,
mas também a entrega mais lenta (14–16 dias) — o mesmo gargalo da P1.

**b) Faturamento por faixa de franquia (foto de HOJE):**

| Faixa (atual) | Faturamento (R$) | % do total |
|---|---|---|
| Ouro | 1.011.264 | 56,4% |
| Diamante | 382.210 | 21,3% |
| Prata | 314.812 | 17,6% |
| Bronze | 84.036 | 4,7% |
| Não Informado (-1) | 986 | 0,05% |

Isso mostra quanto vem de lojas que **hoje** são Ouro — mas o cadastro
(`stg_loja`) só guarda a faixa atual, sem histórico. **Não dá para
responder** "quanto veio de lojas que já eram Ouro na data de cada
pedido", porque a faixa de meses atrás foi sobrescrita pela foto de hoje;
uma loja que subiu de faixa no meio da janela aparece com a faixa nova em
todos os seus pedidos, mesmo os antigos.

**c) O que ficou de fora, e não deve virar recomendação por conta própria:**

| Métrica | Valor |
|---|---|
| Pedidos sem loja identificada | 3 |
| Entregas ainda não concluídas na janela | 1.953 (48,3% do total) |
| Pedidos com quantidade de itens em branco | 257 |
| Pedidos com valor líquido em branco | 121 |

**Recomendação:** Foz do Itajaí (P4) reúne o maior número de domicílios
com pet por faturamento gerado (menor R$/domicílio da rede) e já é hoje
atendida em parte por Itajaí e Brusque (lojas de porte Média, com entrega
de ~8 dias — dentro da média boa da rede, não da faixa lenta das Pequenas).
Isso sugere espaço de demanda não capturado sem herdar o gargalo logístico
das lojas pequenas. **O que os dados não sustentam:** afirmar que a demanda
de Foz do Itajaí é *necessariamente* menor faturamento por escolha do
consumidor — pode ser simplesmente cobertura de atendimento indireta; e
quase metade dos pedidos (1.953) ainda não tem prazo de entrega fechado
dentro da janela, o que **subestima** o tempo médio real de entrega em
todo o P1/P5a, pois só os pedidos já entregues entram no cálculo do `AVG`.

## 5. O que melhoraria com mais tempo

- Reconstruir uma faixa de franquia **histórica** (SCD tipo 2) para
  responder de fato à pergunta de P5-b.
- Investigar os 121 pedidos com `vl_liquido` em branco e os 257 com
  `qt_itens` em branco antes de tratá-los como "apenas ausentes" — hoje
  eles reduzem o faturamento e os itens somados, sem sinalizar isso no
  relatório.
- Fechar uma dimensão de canal/desconto separada, caso esses domínios
  cresçam (hoje ficam na fato por serem só 2 colunas de poucos valores).
