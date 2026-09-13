-- =====================================================================================
--  ARQUIVO 5:  AS RESPOSTAS
--  Case: Pata Amiga  |  PostgreSQL 16
-- =====================================================================================
--  Rode depois de: 01, 02, 03 e 04.
--
--  As cinco perguntas de negocio. So aqui e' permitido usar subconsulta.
-- =====================================================================================

-- =====================================================================================
--  P1 - Onde esta o gargalo da entrega?
-- =====================================================================================
-- 1a) Tempo medio, em dias, de cada intervalo do processo, e o total ate a
--     entrega (considera so pedidos ja entregues: AVG ignora os NULL da -1)
SELECT
    ROUND(AVG(dias_integracao_separacao), 1) AS media_integracao_separacao,
    ROUND(AVG(dias_separacao_nota), 1)       AS media_separacao_nota,
    ROUND(AVG(dias_nota_despacho), 1)        AS media_nota_despacho,
    ROUND(AVG(dias_despacho_entrega), 1)     AS media_despacho_entrega,
    ROUND(AVG(dias_total_ate_entrega), 1)    AS media_total_ate_entrega
FROM fato_pedido;

-- 1b) O mesmo, por porte de loja: o gargalo e' o mesmo nos tres portes?
SELECT
    l.porte,
    ROUND(AVG(f.dias_integracao_separacao), 1) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 1)       AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 1)        AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 1)     AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 1)    AS media_total_ate_entrega,
    COUNT(*) AS pedidos
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.porte
ORDER BY media_total_ate_entrega DESC;

-- =====================================================================================
--  P2 - Qual categoria concentra o faturamento?
-- =====================================================================================
-- 2a) Faturamento e percentual do total, por categoria PADRONIZADA
SELECT
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido)) AS faturamento,
    ROUND(100.0 * SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;

-- 2b) A categoria campea e' a mesma nos tres portes de loja?
SELECT
    l.porte,
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido)) AS faturamento
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.porte, c.nome_categoria
ORDER BY l.porte, faturamento DESC;

-- =====================================================================================
--  P3 - O desconto funciona igual em todo canal?
-- =====================================================================================
-- 3a) Ticket medio COM e SEM desconto, dentro de cada canal
SELECT
    canal_pedido,
    houve_desconto,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio,
    COUNT(*) AS pedidos
FROM fato_pedido
WHERE houve_desconto IN ('Sim', 'Nao')
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;

-- 3b) Quanto cada canal representa do faturamento total
SELECT
    canal_pedido,
    ROUND(SUM(vl_liquido)) AS faturamento,
    ROUND(100.0 * SUM(vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY faturamento DESC;

-- =====================================================================================
--  P4 - Qual praca de atendimento concentra o faturamento?
-- =====================================================================================
-- Faturamento RATEADO pelo fator_publico (uma loja pode entregar em mais de
-- uma praca) cruzado com domicilios_com_pet. A soma das pracas + os pedidos
-- sem loja fecha com o total da rede (ver 00-conferencia.sql).
SELECT
    p.nome_praca,
    p.regional,
    p.domicilios_com_pet,
    ROUND(SUM(f.vl_liquido * b.fator_publico)) AS faturamento_rateado,
    ROUND(SUM(f.vl_liquido * b.fator_publico) / NULLIF(p.domicilios_com_pet, 0), 4) AS faturamento_por_domicilio
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja
JOIN dim_praca p ON p.sk_praca = b.sk_praca
GROUP BY p.nome_praca, p.regional, p.domicilios_com_pet
ORDER BY faturamento_rateado DESC;

-- =====================================================================================
--  P5 - Onde abrir a proxima loja, e o que os dados NAO permitem afirmar?
-- =====================================================================================
-- 5a) Lojas ranqueadas por ITENS VENDIDOS POR MIL HABITANTES (nao em valor
--     absoluto), cruzado com o tempo medio de entrega de cada uma
SELECT
    l.nome_loja,
    l.cidade,
    l.populacao_cidade,
    SUM(f.qt_itens) AS itens_vendidos,
    ROUND(1000.0 * SUM(f.qt_itens) / l.populacao_cidade, 2) AS itens_por_mil_habitantes,
    ROUND(AVG(f.dias_total_ate_entrega), 1) AS tempo_medio_entrega_dias
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.nome_loja, l.cidade, l.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;

-- 5b) Faturamento por faixa de franquia ATUAL (foto de hoje - o passado foi
--     sobrescrito, entao isto NAO responde "quanto veio de lojas que ja
--     eram Ouro na data do pedido")
SELECT
    l.faixa_franquia,
    ROUND(SUM(f.vl_liquido)) AS faturamento,
    ROUND(100.0 * SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_do_total
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
GROUP BY l.faixa_franquia
ORDER BY faturamento DESC;

-- 5c) O que ficou de fora: pedidos sem loja, entregas nao concluidas, e
--     itens/valores em branco
SELECT 'pedidos sem loja identificada' AS metrica, COUNT(*) AS valor FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT 'entregas ainda nao concluidas', COUNT(*) FROM fato_pedido WHERE sk_tempo_entrega = -1
UNION ALL SELECT 'pedidos com qt_itens em branco', COUNT(*) FROM fato_pedido WHERE qt_itens IS NULL
UNION ALL SELECT 'pedidos com vl_liquido em branco', COUNT(*) FROM fato_pedido WHERE vl_liquido IS NULL;
