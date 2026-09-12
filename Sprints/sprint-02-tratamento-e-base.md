# Sprint 2 — Tratamento (regras) e base do modelo

**Objetivo:** definir as regras de limpeza antes de escrever qualquer `INSERT`
de dimensão, e carregar as duas dimensões que já vêm prontas.
**Entrada:** `02-dimensoes-prontas.sql` (fornecido).
**Saida:** `dim_tempo` e `dim_loja` carregadas; os `CREATE TABLE` vazios das próximas 4 tabelas.


## O que foi feito
1. Rodei `02-dimensoes-prontas.sql`: `dim_tempo` (236 linhas = 235 dias + a -1)
   e `dim_loja` (33 linhas = 32 lojas + a -1).
2. Fechei as três regras que o resto do projeto usará sempre:
   - **Datas:** pedido em `MM/DD/YYYY HH12:MI AM`; os 4 marcos de entrega em
     `YYYY-MM-DD`; a chave da `dim_tempo` é `TO_CHAR(data,'YYYYMMDD')::int`.
   - **Números:** vazio ou `-` vira `NULL` (nunca 0); `R$ 1.850,00` perde o
     `R$`, o ponto de milhar e troca a vírgula por ponto antes do `CAST`.
   - **Texto:** toda comparação de grafia crua é feita em
     `UPPER(TRANSLATE(coluna, <acentuados>, <sem acento>))`, dos dois lados,
     porque o PostgreSQL compara *byte a byte* (`'Timbo' <> 'TIMBO'`).
3. Montei o de-para de categoria (ordem MED → PETISC → RA → HIG → BRINQ →
   ACESS → SERV → Não Informado) e o de-para do nome de loja (mecânico:
   tira `/SC` e espaço duplo; manual: os 3 casos de digitação/apelido/
   abreviação) **antes** de escrever qualquer `INSERT...SELECT`.

## Decisão tomada
Nenhuma dimensão própria é escrita nesta sprint — só a regra. Isso evita a necessidade de 
reescrever o CASE no próximo arquivo(03-dimensoes) no meio do caminho.