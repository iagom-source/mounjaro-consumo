/* 02 - Carga e tratamento (SQL Server)
   PMC: lê o JSON do SIDRA (dados/brutos/pmc_8882.json) com OPENROWSET + OPENJSON.
   Requer SQL Server 2019+ para CODEPAGE='65001' (UTF-8) e permissão de leitura no
   arquivo pela conta do serviço do SQL Server. Se falhar, copie o arquivo para uma
   pasta acessível (ex.: C:\temp) e ajuste o caminho abaixo.
   Trends: pendente, ajustar quando o CSV for baixado. */
USE ConsumoMounjaro;
GO

/* Limpa para permitir reexecução */
DELETE FROM dbo.fato_trends;
DELETE FROM dbo.fato_varejo;
DELETE FROM dbo.dim_data;
DELETE FROM dbo.dim_categoria;
TRUNCATE TABLE dbo.stg_pmc;
DBCC CHECKIDENT ('dbo.dim_categoria', RESEED, 0);
GO

/* Carga do JSON do SIDRA em stg_pmc. A 1ª linha do array é o cabeçalho e é descartada. */
DECLARE @arquivo NVARCHAR(500) = N'C:\caminho\mounjaro-consumo\dados\brutos\pmc_8882.json';
DECLARE @sql NVARCHAR(MAX) = N'
DECLARE @json NVARCHAR(MAX) = (SELECT BulkColumn
    FROM OPENROWSET(BULK ''' + @arquivo + N''', SINGLE_CLOB, CODEPAGE = ''65001'') AS j);
INSERT INTO dbo.stg_pmc (mes_codigo, mes, atividade, valor)
SELECT mes_codigo, mes, atividade, valor
FROM OPENJSON(@json) WITH (
    mes_codigo VARCHAR(20)  ''$.D3C'',
    mes        VARCHAR(50)  ''$.D3N'',
    atividade  VARCHAR(200) ''$.D5N'',
    valor      VARCHAR(50)  ''$.V''
)
WHERE TRY_CAST(mes_codigo AS INT) IS NOT NULL;';   -- exclui a linha de cabeçalho
EXEC sp_executesql @sql;

SELECT COUNT(*) AS linhas_stg_pmc,            -- esperado: 129
       COUNT(DISTINCT mes_codigo) AS meses,   -- esperado: 43
       COUNT(DISTINCT atividade) AS atividades -- esperado: 3
FROM dbo.stg_pmc;
GO

/* Nomes curtos e limpos das categorias. Também evita o problema de acentos corrompidos
   (UTF-8 lido em collation Latin1): a correspondência usa só o início do texto, sem acentos. */
UPDATE dbo.stg_pmc
SET atividade = CASE
        WHEN atividade LIKE 'Hipermercados e supermercados%'        THEN 'Supermercados'
        WHEN atividade LIKE 'Hipermercados, supermercados, produt%' THEN 'Alimentos, bebidas e fumo (total)'
        WHEN atividade LIKE 'Artigos farm%'                         THEN 'Farmácia e perfumaria'
        ELSE atividade
    END;
GO

/* Trends: CSV semanal em formato largo (Semana, Mounjaro, caneta emagrecedora).
   As 3 primeiras linhas são cabeçalho, por isso FIRSTROW=4. Valores "<1" viram 0.5 mais abaixo. */
DROP TABLE IF EXISTS dbo.stg_trends_wide;
CREATE TABLE dbo.stg_trends_wide (
    semana  VARCHAR(20),
    col_mounjaro VARCHAR(10),
    col_caneta   VARCHAR(10)
);
TRUNCATE TABLE dbo.stg_trends;

BULK INSERT dbo.stg_trends_wide
FROM 'C:\caminho\mounjaro-consumo\dados\brutos\trends.csv'
WITH (FIRSTROW = 4, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', CODEPAGE = '65001');

/* Formato largo -> longo (um termo por linha); REPLACE remove o CR de arquivos com fim de linha CRLF */
INSERT INTO dbo.stg_trends (periodo, termo, interesse)
SELECT semana, v.termo, REPLACE(v.interesse, CHAR(13), '')
FROM dbo.stg_trends_wide
CROSS APPLY (VALUES ('Mounjaro', col_mounjaro),
                    ('caneta emagrecedora', col_caneta)) AS v(termo, interesse)
WHERE TRY_CAST(semana AS DATE) IS NOT NULL;

SELECT COUNT(*) AS linhas_stg_trends,          -- esperado: 2 x 195 semanas = 390
       COUNT(DISTINCT termo) AS termos          -- esperado: 2
FROM dbo.stg_trends;
GO

/* dim_categoria */
INSERT INTO dbo.dim_categoria (categoria)
SELECT DISTINCT LTRIM(RTRIM(atividade))
FROM dbo.stg_pmc
WHERE atividade IS NOT NULL;

/* dim_data: meses de 2023-01 até o último mês do PMC.
   Lançamento do Mounjaro no Brasil: 2025-05-01 */
DECLARE @ini DATE = '2023-01-01';
DECLARE @fim DATE = (SELECT MAX(DATEFROMPARTS(LEFT(mes_codigo,4), RIGHT(mes_codigo,2), 1)) FROM dbo.stg_pmc);
DECLARE @lancamento DATE = '2025-05-01';

WITH meses AS (
    SELECT @ini AS d
    UNION ALL
    SELECT DATEADD(MONTH, 1, d) FROM meses WHERE d < @fim
)
INSERT INTO dbo.dim_data (data_id, ano, mes, nome_mes, periodo)
SELECT d, YEAR(d), MONTH(d), DATENAME(MONTH, d),
       CASE WHEN d < @lancamento THEN 'Pré-lançamento' ELSE 'Pós-lançamento' END
FROM meses
OPTION (MAXRECURSION 200);

/* fato_varejo */
INSERT INTO dbo.fato_varejo (data_id, categoria_id, indice_volume)
SELECT DATEFROMPARTS(LEFT(s.mes_codigo,4), RIGHT(s.mes_codigo,2), 1),
       c.categoria_id,
       TRY_CAST(REPLACE(s.valor, ',', '.') AS DECIMAL(10,2))
FROM dbo.stg_pmc s
JOIN dbo.dim_categoria c ON c.categoria = LTRIM(RTRIM(s.atividade))
WHERE TRY_CAST(REPLACE(s.valor, ',', '.') AS DECIMAL(10,2)) IS NOT NULL;

/* fato_trends: agrega para mês (média), trata "<1" como 0.5 */
INSERT INTO dbo.fato_trends (data_id, termo, interesse)
SELECT DATEFROMPARTS(YEAR(TRY_CAST(periodo + CASE WHEN LEN(periodo)=7 THEN '-01' ELSE '' END AS DATE)),
                     MONTH(TRY_CAST(periodo + CASE WHEN LEN(periodo)=7 THEN '-01' ELSE '' END AS DATE)), 1),
       termo,
       AVG(CASE WHEN interesse = '<1' THEN 0.5 ELSE TRY_CAST(interesse AS DECIMAL(6,2)) END)
FROM dbo.stg_trends
WHERE TRY_CAST(periodo AS DATE) >= '2023-01-01'
  AND TRY_CAST(periodo AS DATE) < DATEADD(MONTH, 1, (SELECT MAX(data_id) FROM dbo.dim_data))  -- só meses que existem no PMC (até jul/2026)
GROUP BY DATEFROMPARTS(YEAR(TRY_CAST(periodo + CASE WHEN LEN(periodo)=7 THEN '-01' ELSE '' END AS DATE)),
                       MONTH(TRY_CAST(periodo + CASE WHEN LEN(periodo)=7 THEN '-01' ELSE '' END AS DATE)), 1),
         termo;

/* Conferência rápida */
SELECT 'dim_data' AS tabela, COUNT(*) AS linhas FROM dbo.dim_data
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dbo.dim_categoria
UNION ALL SELECT 'fato_varejo',   COUNT(*) FROM dbo.fato_varejo
UNION ALL SELECT 'fato_trends',   COUNT(*) FROM dbo.fato_trends;
GO

