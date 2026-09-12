# Sprint 5 — Respostas, diagrama e entrega

**Objetivo:** as cinco perguntas de negócio com número e reconciliação
com a origem, o diagrama do modelo e o README final.
**Saida:** `05-respostas.sql`, `diagrama/modelo-estrela.png`, `README.md`.


## O que foi feito
1. Escrevi as 5 consultas em `05-respostas.sql` — utilizando apenas aqui a
   subconsulta (para o percentual do total, ex.: `100.0 * SUM(...) /
   (SELECT SUM(vl_liquido) FROM fato_pedido)`).
2. Rodei as duas reconciliações do `00-conferencia.sql`:
   - `SUM(vl_liquido)` direto na fato **=** `SUM` passando por `JOIN` com
     `dim_categoria` → **R$ 1.793.309** dos dois lados.
   - Faturamento rateado por praça + pedidos sem loja **−** total da rede
     **= 0** (o rateio pelo `fator_publico` fechou com o mesmo valor).
3. Desenhei o diagrama modelo estrela com as 4 pedidos do enunciado:
   fato no centro com o grão escrito, as 3 dimensões ligadas direto, a
   `dim_tempo` ligada duas vezes e a `dim_praca` ligada só
   através da `bridge_loja_praca`.
4. Escrevi o README consolidando diagnóstico, decisões, diagrama e as 5
   respostas com os números, fechando com a recomendação de onde abrir a
   próxima loja e o que os dados não sustentam.
