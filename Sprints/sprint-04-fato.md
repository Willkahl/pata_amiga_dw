# Sprint 4 — A fato

**Objetivo:** um único `INSERT...SELECT`, sem subconsulta, 4.044 linhas,
nenhuma FK nula. 
**Saida:** `04-fato.sql`.


## O que foi feito
1. Padronizei o **nome da loja** (mecânica + os 3 casos manuais) e **só
   depois** fiz o `LEFT JOIN` com `dim_loja.chave_loja` — nessa ordem, e não
   ao contrário, porque a *busca* antes da padronização deixaria passar as
   grafias sujas. `COALESCE(sk_loja, -1)` cobre os 3 pedidos sem loja.
2. Busquei `sk_categoria` com `JOIN` direto por `categoria_origem` (a grafia
   crua já foi guardada na dimensão — é por isso que não precisa de
   subconsulta aqui).
3. Padronizei `houve_desconto` (17 grafias → 3 valores) e `canal_pedido`
   (testando `WHATS` **antes** de `APP`, porque `"WHATSAPP" LIKE '%APP%'`
   também é verdadeiro).
4. Calculei as 5 colunas de dias com `data_fim::date - data_inicio::date`,
   gravando `NULL` (nunca 0) quando o marco de fim está em branco.

## Conferência
| Teste | Resultado |
|---|---|
| Linhas na fato | 4.044 |
| FK nula / FK órfã (loja, categoria, tempo) | 0 em todas |
| Pedidos na linha -1 de loja | 3 |
| Entregas ainda não concluídas (tempo -1) | 1.953 |
| Pedidos de WhatsApp | 414 (não foram parar no App) |
| Período dos pedidos | 01/09/2023 a 31/03/2024 |
| Dias negativos em qualquer intervalo | 0 |