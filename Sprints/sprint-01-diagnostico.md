## Sprint 1 — Diagnóstico da origem

**Objetivo:** entender o tamanho do problema antes de tratar qualquer coisa.
**Entrada:** `01-carga-staging.sql` (fornecido). 
**Saida:** o diagnóstico é registrado no README.


## O que foi feito
1. Rodei `01-carga-staging.sql` conferindo as 3 tabelas: `stg_pedido` (4.044),
   `stg_loja` (32), `stg_loja_praca` (48).
2. Escrevi consultas de diagnóstico (sem alterar as `stg_`, utilizando apenas `SELECT`/`COUNT`)
   para responder: quantas grafias de loja e de categoria existem, quantos
   pedidos vieram sem `Cod Loja`, quantos sem nome de loja, e quantos marcos
   do processo de entrega estão em branco.
3. Confirmei a máscara de data do pedido: `MM/DD/YYYY HH12:MI AM` (formato
   americano) contra `TO_TIMESTAMP`, batendo as 4.044 linhas.

## Números encontrados (também estão no README, seção "Diagnóstico")
- 37 grafias distintas de categoria, 128 de nome de loja, 17 de `HouveDesconto`,
  20 de `CanalPedido`.
- 1.575 pedidos sem `Cod Loja` (~39%) — por isso a busca da loja deve ser feita pelo **nome**, não pelo código.
- 3 pedidos sem o nome de loja nenhum — viram a linha -1 na fato.
- Marcos em branco: 1.077 (separação), 1.338 (nota), 1.665 (despacho),
  1.953 (entrega) — processo em aberto, não erro.

## Decisão que sai daqui
Toda a lógica de limpeza vai morar nos `INSERT` das dimensões e da fato
(arquivos 03 e 04). As tabelas `stg_` nunca são alteradas.