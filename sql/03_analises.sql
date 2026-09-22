/* 03 - Análises e views para o Power BI (SQL Server) */
USE ConsumoMounjaro;
GO

/* View 1: série mensal com variações e média móvel */
CREATE OR ALTER VIEW dbo.vw_varejo_serie AS
SELECT d.data_id, d.ano, d.mes, d.periodo, c.categoria, f.indice_volume,
       LAG(f.indice_volume, 1)  OVER (PARTITION BY c.categoria_id ORDER BY d.data_id) AS indice_mes_anterior,
       LAG(f.indice_volume, 12) OVER (PARTITION BY c.categoria_id ORDER BY d.data_id) AS indice_ano_anterior,
       AVG(f.indice_volume) OVER (PARTITION BY c.categoria_id ORDER BY d.data_id
                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)            AS media_movel_3m
FROM dbo.fato_varejo f
JOIN dbo.dim_data d      ON d.data_id = f.data_id
JOIN dbo.dim_categoria c ON c.categoria_id = f.categoria_id;
GO

/* View 2: variações percentuais MoM e YoY */
CREATE OR ALTER VIEW dbo.vw_varejo_variacao AS
SELECT *,
       CAST((indice_volume / NULLIF(indice_mes_anterior, 0) - 1) * 100 AS DECIMAL(8,2))  AS var_mom_pct,
       CAST((indice_volume / NULLIF(indice_ano_anterior, 0) - 1) * 100 AS DECIMAL(8,2))  AS var_yoy_pct
FROM dbo.vw_varejo_serie;
GO

/* View 3: interesse de busca por mês */
CREATE OR ALTER VIEW dbo.vw_trends AS
SELECT d.data_id, d.ano, d.mes, d.periodo, t.termo, t.interesse
FROM dbo.fato_trends t
JOIN dbo.dim_data d ON d.data_id = t.data_id;
GO

/* Q1: média do índice antes x depois do lançamento, por categoria.
   Compara também o mesmo período do ano anterior (controle simples de sazonalidade). */
SELECT categoria,
       AVG(CASE WHEN periodo = 'Pré-lançamento' THEN indice_volume END) AS media_pre,
       AVG(CASE WHEN periodo = 'Pós-lançamento' THEN indice_volume END) AS media_pos,
       CAST((AVG(CASE WHEN periodo = 'Pós-lançamento' THEN indice_volume END) /
             AVG(CASE WHEN periodo = 'Pré-lançamento' THEN indice_volume END) - 1) * 100 AS DECIMAL(6,2)) AS var_pct
FROM dbo.vw_varejo_serie
GROUP BY categoria;

/* Q2: mesmos meses (mai em diante) de 2025 x 2024, por categoria */
WITH base AS (
    SELECT categoria, ano, indice_volume
    FROM dbo.vw_varejo_serie
    WHERE mes >= 5 AND ano IN (2024, 2025)
)
SELECT categoria,
       AVG(CASE WHEN ano = 2024 THEN indice_volume END) AS media_2024,
       AVG(CASE WHEN ano = 2025 THEN indice_volume END) AS media_2025,
       CAST((AVG(CASE WHEN ano = 2025 THEN indice_volume END) /
             AVG(CASE WHEN ano = 2024 THEN indice_volume END) - 1) * 100 AS DECIMAL(6,2)) AS var_yoy_pct
FROM base
GROUP BY categoria;

/* Q3: correlação de Pearson entre interesse por "Mounjaro" e índice do varejo, por categoria.
   SQL Server não tem CORR(); calculamos pela fórmula. */
WITH j AS (
    SELECT v.categoria, CAST(v.indice_volume AS FLOAT) AS x, CAST(t.interesse AS FLOAT) AS y
    FROM dbo.vw_varejo_serie v
    JOIN dbo.vw_trends t ON t.data_id = v.data_id
    WHERE t.termo = 'Mounjaro'
)
SELECT categoria, COUNT(*) AS n,
       (COUNT(*) * SUM(x*y) - SUM(x) * SUM(y)) /
       NULLIF(SQRT((COUNT(*) * SUM(x*x) - SUM(x)*SUM(x)) * (COUNT(*) * SUM(y*y) - SUM(y)*SUM(y))), 0) AS correlacao
FROM j
GROUP BY categoria;
GO

/* Q4: correlação entre o interesse por "Mounjaro" e a VARIAÇÃO ANUAL (YoY) do varejo.
   Usar YoY remove a tendência de longo prazo e a sazonalidade, evitando correlação espúria.
   Só há YoY a partir de 2024-01 (precisa de 12 meses de histórico). */
WITH j AS (
    SELECT v.categoria, CAST(v.var_yoy_pct AS FLOAT) AS x, CAST(t.interesse AS FLOAT) AS y
    FROM dbo.vw_varejo_variacao v
    JOIN dbo.vw_trends t ON t.data_id = v.data_id
    WHERE t.termo = 'Mounjaro' AND v.var_yoy_pct IS NOT NULL
)
SELECT categoria, COUNT(*) AS n,
       (COUNT(*) * SUM(x*y) - SUM(x) * SUM(y)) /
       NULLIF(SQRT((COUNT(*) * SUM(x*x) - SUM(x)*SUM(x)) * (COUNT(*) * SUM(y*y) - SUM(y)*SUM(y))), 0) AS correlacao_yoy
FROM j
GROUP BY categoria;
GO