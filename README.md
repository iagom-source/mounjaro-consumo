# Consumo x Mounjaro: o varejo de alimentos mudou depois das canetas emagrecedoras?

Análise de tendência agregada com SQL Server + Power BI, usando dados públicos.

## Pergunta de negócio
A popularização das canetas emagrecedoras (Mounjaro chegou às farmácias brasileiras em **maio/2025**) coincide com mudanças no volume de vendas do varejo de alimentos e supermercados?

## Aviso metodológico
Não existe base pública que ligue quem usa Mounjaro ao que essa pessoa compra. Este projeto mostra **correlação temporal entre séries agregadas**, não causalidade. O interesse de busca no Google Trends é usado como **proxy de adoção**, porque as vendas mensais do medicamento não são abertas.

## Fontes
| Dado | Fonte | Arquivo esperado |
|---|---|---|
| Volume de vendas do varejo (base 2022 = 100) | IBGE, PMC, SIDRA tabela 8882 | `dados/brutos/pmc_8882.json` |
| Interesse de busca (proxy de adoção) | Google Trends, Brasil | `dados/brutos/trends.csv` |

### Como baixar
1. **SIDRA 8882** (varejo por atividades): tipo de índice "volume de vendas"; atividades "Hipermercados e supermercados" e "Hipermercados, supermercados, produtos alimentícios, bebidas e fumo" (opcional: farmácia/perfumaria como comparação); jan/2023 até jul/2026; baixado em JSON pela API do SIDRA (`apisidra.ibge.gov.br/values/t/8882/n1/all/v/7169/p/202301-202607/c11046/56734/c85/103154,90672,103155?formato=json`).
2. **Google Trends**: termos "Mounjaro" e "caneta emagrecedora", Brasil, jan/2023 até hoje; baixar CSV (dados mensais ou semanais).

## Estrutura
```
dados/brutos/   CSVs/JSON originais (não alterar)
sql/            scripts numerados, rodar em ordem
docs/           notas de método
dashboard/      dashboard interativo (HTML/SVG), publicado via GitHub Pages
```

## Ordem de execução (SQL Server)
1. `sql/01_criar_banco_e_tabelas.sql`: banco, staging, dimensões e fatos
2. `sql/02_carga_e_tratamento.sql`: importa os CSVs e popula o modelo
3. `sql/03_analises.sql`: variações, média móvel, pré/pós lançamento e correlação

## Dashboard
Versão interativa publicada em:
https://iagom-source.github.io/mounjaro-consumo/dashboard/index.html

## Limitações
- Correlação não é causalidade: inflação, juros, renda e sazonalidade também afetam o varejo.
- O Google Trends mede interesse, não uso do medicamento.
- Pós-lançamento tem poucos meses de dados; conclusões são preliminares.

