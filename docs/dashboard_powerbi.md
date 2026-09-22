# Dashboard Power BI: Consumo x Mounjaro

## 1. Conexão e modelo
1. Power BI Desktop > Obter dados > SQL Server > servidor local, banco `ConsumoMounjaro`, modo **Importar**.
2. Selecione: `dim_data`, `vw_varejo_variacao`, `vw_trends`.
3. Relacionamentos (modelo estrela, filtro de `dim_data` para as views):
   - `dim_data[data_id]` 1 → * `vw_varejo_variacao[data_id]`
   - `dim_data[data_id]` 1 → * `vw_trends[data_id]`
4. Marque `dim_data` como tabela de datas (coluna `data_id`).
5. Ordene `dim_data[nome_mes]` por `dim_data[mes]`.

## 2. Medidas DAX
Crie uma tabela de medidas (`_Medidas`) e adicione:

```DAX
Índice Volume =
AVERAGE ( vw_varejo_variacao[indice_volume] )

Média Móvel 3M =
AVERAGE ( vw_varejo_variacao[media_movel_3m] )

Var YoY % =
DIVIDE ( AVERAGE ( vw_varejo_variacao[var_yoy_pct] ), 100 )

Var YoY % Pós-lançamento =
CALCULATE ( [Var YoY %], dim_data[periodo] = "Pós-lançamento" )

Interesse Mounjaro =
CALCULATE ( AVERAGE ( vw_trends[interesse] ), vw_trends[termo] = "Mounjaro" )

Interesse Caneta Emagrecedora =
CALCULATE ( AVERAGE ( vw_trends[interesse] ), vw_trends[termo] = "caneta emagrecedora" )

Índice Base 100 (abr/2025) =
VAR base =
    CALCULATE (
        [Índice Volume],
        REMOVEFILTERS ( dim_data ),
        dim_data[data_id] = DATE ( 2025, 4, 1 )
    )
RETURN
    DIVIDE ( [Índice Volume], base ) * 100
```

Formate `Var YoY %` como porcentagem com 1 casa decimal.

## 3. Páginas

### Página 1: Visão geral
- **Título:** "O varejo de alimentos mudou depois das canetas emagrecedoras?"
- **3 cartões** (um por categoria, filtrando `categoria`): `Var YoY % Pós-lançamento`.
- **Gráfico de linhas:** eixo `dim_data[data_id]` (hierarquia contínua), valores `Índice Base 100 (abr/2025)`, legenda `categoria`. Adicione uma caixa de texto ou forma vertical marcando "Mounjaro chega às farmácias (mai/2025)".
- Segmentação de dados: `categoria`.

### Página 2: Comparativo anual
- **Colunas agrupadas:** eixo `dim_data[data_id]` (mês), valores `Var YoY %`, legenda `categoria`, a partir de jan/2024 (filtro: `Var YoY %` não vazio).
- **Leitura:** supermercados e alimentos ficam próximos de zero; farmácia destoa (inclui o próprio medicamento).

### Página 3: Interesse x varejo
- **Gráfico de linhas com eixo secundário:** `Interesse Mounjaro` (linha 1) e `Var YoY %` da categoria "Supermercados" (linha 2).
- **Tabela:** correlação em YoY por categoria (resultado da Q4 do `03_analises.sql`, digitado em uma tabela de apoio ou anotado numa caixa de texto).

### Página 4: Limitações
Caixa de texto com:
- Correlação não é causalidade; inflação, juros e renda também afetam o varejo.
- Google Trends mede interesse de busca, não uso do medicamento.
- O grupo "Farmácia e perfumaria" provavelmente inclui o próprio Mounjaro.
- Cerca de 15 meses de dados pós-lançamento: resultados preliminares.

## 4. Padrões visuais
- Uma cor por categoria, iguais em todas as páginas. Farmácia em cor de destaque, as demais em tons neutros.
- Títulos que dizem a conclusão, não só o nome do gráfico.
- Fonte: rodapé "Fonte: IBGE (PMC, tabela 8882) e Google Trends. Elaboração própria."

## 5. Validação antes de publicar
- `Var YoY % Pós-lançamento` de Supermercados confere com o resultado da Q2 do SQL (sinal e ordem de grandeza).
- Contagem de meses: 43 por categoria.
- Prints de cada página salvos em `docs/`.
