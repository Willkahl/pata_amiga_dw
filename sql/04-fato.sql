-- =====================================================================================
--  ARQUIVO 4:  A FATO
--  Case: Pata Amiga  |  PostgreSQL 16
-- =====================================================================================
--  Rode depois de: 01, 02 e 03.
--
--  fato_pedido -> grao: 1 linha = 1 pedido -> 4.044 linhas.
--  Um unico INSERT...SELECT. So SELECT, JOIN, LEFT JOIN e CASE WHEN - sem
--  subconsulta (a regra: se precisou de subconsulta para achar a dimensao, a
--  grafia crua nao foi guardada onde deveria).
--
--  A limpeza mora na dimensao; a fato so PROCURA a linha certa. Nenhuma FK
--  fica nula: quando falta, ela aponta para a linha -1.
-- =====================================================================================

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT
    sp."NumeroPedido",

    -- sk_tempo_pedido: a propria data em numero, calculada, sem JOIN
    CAST(TO_CHAR(TO_TIMESTAMP(sp."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'), 'YYYYMMDD') AS INT),

    -- sk_tempo_entrega: -1 se a entrega ainda nao aconteceu (marco em branco)
    CASE WHEN sp."DtEntregaCliente" = '' THEN -1
         ELSE CAST(TO_CHAR(sp."DtEntregaCliente"::date, 'YYYYMMDD') AS INT)
    END,

    -- sk_loja: padroniza o nome da loja (mecanica + os 3 casos manuais) e SO
    -- ENTAO faz o lookup em dim_loja pela chave_loja. -1 se nao encontrar.
    COALESCE(dl.sk_loja, -1),

    -- sk_categoria: encontrado pela GRAFIA CRUA, join de uma linha so
    dc.sk_categoria,

    -- houve_desconto: 17 grafias -> 3 valores
    CASE
        WHEN UPPER(TRIM(sp."HouveDesconto")) IN ('S','SIM','1','X','TRUE','V')  THEN 'Sim'
        WHEN UPPER(TRIM(sp."HouveDesconto")) IN ('N','NAO','0','FALSE','F')     THEN 'Nao'
        ELSE 'Nao Informado'
    END,

    -- canal_pedido: A ORDEM IMPORTA - WHATS antes de APP, ou o WhatsApp cai
    -- dentro do App (WHATSAPP contem APP)
    CASE
        WHEN UPPER(sp."CanalPedido") LIKE '%WHATS%' THEN 'WhatsApp'
        WHEN UPPER(sp."CanalPedido") LIKE '%APP%'   THEN 'App'
        WHEN UPPER(sp."CanalPedido") LIKE '%SITE%'  THEN 'Site'
        WHEN UPPER(sp."CanalPedido") LIKE '%LOJA%'  THEN 'Loja Fisica'
        WHEN UPPER(sp."CanalPedido") LIKE '%TEL%'   THEN 'Telefone'
        ELSE 'Nao Informado'
    END,

    -- dt_pedido: data e hora do pedido, mascara americana
    TO_TIMESTAMP(sp."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'),

    -- qt_itens: regra dos numeros - vazio ou '-' vira NULL, nunca 0
    CASE WHEN TRIM(sp."QTD.Itens") IN ('', '-') THEN NULL
         ELSE CAST(sp."QTD.Itens" AS INTEGER)
    END,

    -- vl_liquido: expressao pronta do enunciado, para os formatos misturados
    CASE WHEN TRIM(REPLACE(sp."ValorLiquidoPedido(R$)", 'R$', '')) IN ('', '-') THEN NULL
         WHEN sp."ValorLiquidoPedido(R$)" LIKE '%,%'
              THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(sp."ValorLiquidoPedido(R$)", 'R$', ''), ' ', ''), '.', ''), ',', '.') AS DECIMAL(15,2))
         ELSE CAST(REPLACE(REPLACE(sp."ValorLiquidoPedido(R$)", 'R$', ''), ' ', '') AS DECIMAL(15,2))
    END,

    -- os quatro intervalos do processo + o total. Marco de FIM em branco = NULL.
    CASE WHEN sp."Dt Separacao Estoque" = '' THEN NULL
         ELSE sp."Dt Separacao Estoque"::date - TO_TIMESTAMP(sp."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date
    END,
    CASE WHEN sp."DtNotaFiscal" = '' THEN NULL
         ELSE sp."DtNotaFiscal"::date - sp."Dt Separacao Estoque"::date
    END,
    CASE WHEN sp."Dt_Despacho_Transportadora" = '' THEN NULL
         ELSE sp."Dt_Despacho_Transportadora"::date - sp."DtNotaFiscal"::date
    END,
    CASE WHEN sp."DtEntregaCliente" = '' THEN NULL
         ELSE sp."DtEntregaCliente"::date - sp."Dt_Despacho_Transportadora"::date
    END,
    CASE WHEN sp."DtEntregaCliente" = '' THEN NULL
         ELSE sp."DtEntregaCliente"::date - TO_TIMESTAMP(sp."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date
    END

FROM stg_pedido sp

-- lookup da loja: normaliza (maiuscula, sem acento, sem "/SC", sem espaco
-- duplo) e SO DEPOIS resolve os 3 casos manuais (erro de digitacao, apelido,
-- abreviacao) que sobram depois da parte mecanica.
LEFT JOIN dim_loja dl ON dl.chave_loja =
    CASE
        WHEN UPPER(TRANSLATE(TRIM(REPLACE(REPLACE(sp."Loja-Nome", '/SC', ''), '  ', ' ')),
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC'))
             = 'PATA AMIGA BLUMENAL CENTRO' THEN 'PATA AMIGA BLUMENAU CENTRO'
        WHEN UPPER(TRANSLATE(TRIM(REPLACE(REPLACE(sp."Loja-Nome", '/SC', ''), '  ', ' ')),
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC'))
             = 'PATA AMIGA FLORIPA NORTE' THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
        WHEN UPPER(TRANSLATE(TRIM(REPLACE(REPLACE(sp."Loja-Nome", '/SC', ''), '  ', ' ')),
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC'))
             = 'PATA AMIGA JGUA DO SUL' THEN 'PATA AMIGA JARAGUA DO SUL'
        ELSE UPPER(TRANSLATE(TRIM(REPLACE(REPLACE(sp."Loja-Nome", '/SC', ''), '  ', ' ')),
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC'))
    END

-- lookup da categoria: pela grafia crua, join de uma linha so
JOIN dim_categoria dc ON dc.categoria_origem = sp."CategoriaProduto";

-- =====================================================================================
--  CONFERENCIA RAPIDA (repetida com mais detalhe no 00-conferencia.sql)
-- =====================================================================================
SELECT COUNT(*) AS linhas_fato FROM fato_pedido;
