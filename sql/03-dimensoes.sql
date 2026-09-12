-- =====================================================================================
--  ARQUIVO 3:  AS SUAS DIMENSOES
--  Case: Pata Amiga  |  PostgreSQL 16
-- =====================================================================================
--  Rode depois de: 01-carga-staging.sql, 02-dimensoes-prontas.sql
--
--  Preenche dim_categoria, dim_praca e bridge_loja_praca (ja criadas, vazias,
--  no arquivo 02). Sem UPDATE, sem ALTER, sem subconsulta, sem view.
--
--  Padrao central: a linha -1 = "Nao Informado" entra ANTES do INSERT...SELECT,
--  para nenhuma FK ficar nula depois, na fato.
-- =====================================================================================

-- =====================================================================================
--  DIM_CATEGORIA   grao: uma grafia da origem  ->  38 linhas no PostgreSQL
-- =====================================================================================
--  categoria_origem guarda a GRAFIA CRUA: e por ela que a fato encontra a linha,
--  com um JOIN de uma linha so (o padrao da semana).
--
--  A ORDEM DO CASE IMPORTA: "Racao Medicamentosa" contem "RA", entao MED e
--  testado ANTES de RA, ou o item cairia em Racao por engano. Todo teste e
--  feito em UPPER + sem acento (TRANSLATE), para nao depender da grafia crua.

INSERT INTO dim_categoria (sk_categoria, categoria_origem, nome_categoria, grupo_categoria)
VALUES (-1, 'Nao Informado', 'Nao Informado', 'Nao Informado');

INSERT INTO dim_categoria (categoria_origem, nome_categoria, grupo_categoria)
SELECT
    "CategoriaProduto",
    CASE
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%MED%'    THEN 'Medicamento'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%PETISC%' THEN 'Petisco'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%RA%'     THEN 'Racao'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%HIG%'    THEN 'Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%BRINQ%'  THEN 'Brinquedo'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%ACESS%'  THEN 'Acessorio'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%SERV%'   THEN 'Servico'
        ELSE 'Nao Informado'
    END AS nome_categoria,
    CASE
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%MED%'    THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%PETISC%' THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%RA%'     THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%HIG%'    THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%BRINQ%'  THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%ACESS%'  THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE("CategoriaProduto",
                'áàâãäÁÀÂÃÄéèêëÉÈÊËíìîïÍÌÎÏóòôõöÓÒÔÕÖúùûüÚÙÛÜçÇ',
                'aaaaaAAAAAeeeeEEEEiiiiIIIIooooOOOOOuuuuUUUUcC')) LIKE '%SERV%'   THEN 'Bem-estar'
        ELSE 'Nao Informado'
    END AS grupo_categoria
FROM (SELECT DISTINCT "CategoriaProduto" FROM stg_pedido) c;

-- =====================================================================================
--  DIM_PRACA   grao: uma praca de atendimento  ->  13 linhas (12 pracas + a -1)
-- =====================================================================================
--  domicilios_com_pet vem como '148.000': o ponto e milhar, nao decimal.

INSERT INTO dim_praca (sk_praca, cod_praca, nome_praca, regional, domicilios_com_pet)
VALUES (-1, 'N/I', 'Nao Informado', 'Nao Informado', NULL);

INSERT INTO dim_praca (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT
    "CodPraca",
    "NomePraca",
    "Regional",
    CAST(REPLACE("DomiciliosComPet", '.', '') AS INTEGER)
FROM (SELECT DISTINCT "CodPraca", "NomePraca", "Regional", "DomiciliosComPet"
      FROM stg_loja_praca) p;

-- =====================================================================================
--  BRIDGE_LOJA_PRACA   grao: uma loja x uma praca  ->  48 linhas
-- =====================================================================================
--  Ligada pelo COD DA LOJA (chave natural), nao pela sk_loja: a chave natural
--  atravessa recargas. fator_publico soma 1,00 em cada loja.

INSERT INTO bridge_loja_praca (cod_loja, sk_praca, fator_publico)
SELECT
    slp."CodLoja",
    dp.sk_praca,
    CAST(slp."PercentualPublico" AS DECIMAL(6,4))
FROM stg_loja_praca slp
JOIN dim_praca dp ON dp.cod_praca = slp."CodPraca";

-- =====================================================================================
--  CONFERENCIA RAPIDA (repetida com mais detalhe no 00-conferencia.sql)
-- =====================================================================================
SELECT 'dim_categoria' AS tabela, COUNT(*) AS linhas FROM dim_categoria
UNION ALL SELECT 'dim_praca', COUNT(*) FROM dim_praca
UNION ALL SELECT 'bridge_loja_praca', COUNT(*) FROM bridge_loja_praca;
