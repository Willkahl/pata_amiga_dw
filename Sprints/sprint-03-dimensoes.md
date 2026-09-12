# Sprint 3 — As dimensões próprias

**Objetivo:** construir `dim_categoria`, `dim_praca` e `bridge_loja_praca`.
**Entrada:** os `CREATE TABLE` do arquivo 02. 
**Saida:** `03-dimensoes.sql`.


## O que foi feito
1. **`dim_categoria`:** linha -1 inserida primeiro; depois
   `INSERT...SELECT DISTINCT "CategoriaProduto"` com o `CASE WHEN` na ordem
   que evita o erro de "Ração Medicamentosa" cair em Ração (fiz com `MED`
   antes de `RA`). `categoria_origem` guarda a grafia crua — é por ela que a
   fato faz a busca de uma linha só, sem subconsulta.
2. **`dim_praca`:** `domicilios_com_pet` convertido com
   `REPLACE(coluna, '.', '')::int` (o ponto aqui se refere ao milhar).
3. **`bridge_loja_praca`:** ligada pelo `cod_loja` (chave natural, não a
   `sk_loja`), com `fator_publico` em `DECIMAL(6,4)`.

## Conferência (bateu 100% com o `00-conferencia.sql`)
| Teste | Resultado |
|---|---|
| `dim_categoria` | 38 linhas (37 grafias + -1) |
| categorias padronizadas distintas | 8 (7 + -1) |
| "Ração Medicamentosa" → Medicamento | (não caiu em Ração) |
| `dim_praca` / `bridge_loja_praca` | 13 / 48 |
| soma do `fator_publico` por loja | 1,00 em todas as 32 |
| lojas na ponte / praças na ponte | 32 / 12 |

## Decisão tomada
Sem essa dimensão de categoria correta, a P2 inteira sairia errada — por
isso a checagem "Ração Medicamentosa → Medicamento" foi rodada antes de
seguir para a fato.
