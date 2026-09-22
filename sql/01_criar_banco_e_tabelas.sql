/* 01 - Banco, staging, dimensões e fatos (SQL Server) */
IF DB_ID('ConsumoMounjaro') IS NULL
    CREATE DATABASE ConsumoMounjaro;
GO
USE ConsumoMounjaro;
GO

/* Staging: recebe os CSVs como texto, sem tratamento */
DROP TABLE IF EXISTS dbo.stg_pmc;
CREATE TABLE dbo.stg_pmc (
    mes_codigo   VARCHAR(20),   -- ex.: 202501
    mes          VARCHAR(50),   -- ex.: janeiro 2025
    atividade    VARCHAR(200),
    valor        VARCHAR(50)
);

DROP TABLE IF EXISTS dbo.stg_trends;
CREATE TABLE dbo.stg_trends (
    periodo      VARCHAR(20),   -- ex.: 2025-05 ou 2025-05-04
    termo        VARCHAR(100),
    interesse    VARCHAR(20)    -- pode vir como "<1"
);

/* Dimensões */
DROP TABLE IF EXISTS dbo.fato_varejo, dbo.fato_trends, dbo.dim_data, dbo.dim_categoria;

CREATE TABLE dbo.dim_data (
    data_id      DATE        NOT NULL PRIMARY KEY,   -- primeiro dia do mês
    ano          SMALLINT    NOT NULL,
    mes          TINYINT     NOT NULL,
    nome_mes     VARCHAR(15) NOT NULL,
    periodo      VARCHAR(20) NOT NULL                -- 'Pré-lançamento' | 'Pós-lançamento'
);

CREATE TABLE dbo.dim_categoria (
    categoria_id INT IDENTITY(1,1) PRIMARY KEY,
    categoria    VARCHAR(200) NOT NULL UNIQUE
);

/* Fatos */
CREATE TABLE dbo.fato_varejo (
    data_id       DATE          NOT NULL REFERENCES dbo.dim_data(data_id),
    categoria_id  INT           NOT NULL REFERENCES dbo.dim_categoria(categoria_id),
    indice_volume DECIMAL(10,2) NOT NULL,            -- base 2022 = 100
    PRIMARY KEY (data_id, categoria_id)
);

CREATE TABLE dbo.fato_trends (
    data_id      DATE         NOT NULL REFERENCES dbo.dim_data(data_id),
    termo        VARCHAR(100) NOT NULL,
    interesse    DECIMAL(6,2) NOT NULL,              -- 0 a 100
    PRIMARY KEY (data_id, termo)
);
GO
