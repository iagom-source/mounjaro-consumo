# Guia de montagem no Power BI Desktop

Arquivos deste pacote:
- `medidas_dax.md`: coluna `Idx`, medidas, parâmetro de campo e conferência.
- `tema_depois_da_caneta.json`: tema visual.
- `deneb_mostrador.json`: especificação do mostrador circular (Deneb).

> Nada aqui foi executado no Power BI Desktop. As medidas e a especificação Vega-Lite foram escritas a partir do modelo do projeto e o JSON foi validado só quanto à sintaxe. Se algo falhar, me mande a mensagem de erro ou um print.

## 1. Preparação
1. Obter dados > SQL Server > banco `ConsumoMounjaro` > modo **Importar**: `dim_data`, `vw_varejo_variacao`, `vw_trends`.
2. Modo Modelo: relacionamentos `dim_data[data_id]` → `vw_varejo_variacao[data_id]` e → `vw_trends[data_id]` (um para muitos, filtro em uma direção).
3. Adicione a coluna `Idx` e as medidas de `medidas_dax.md`, e **confira a tabela do final desse arquivo** antes de desenhar qualquer visual.
4. Exibição > Temas > Procurar temas > `tema_depois_da_caneta.json`.
5. Instale o **Deneb** (Página inicial > Obter mais visuais > procure "Deneb").
6. Página: tamanho personalizado 1280 × 1500 (rolagem vertical), ou 16:9 se preferir várias páginas.

## 2. Página "Painel" (o console)

| Zona | Visual | Configuração |
|---|---|---|
| Topo | Caixa de texto | Título "O carrinho depois da caneta" (fonte Bahnschrift SemiBold Condensed, 48 pt, caixa alta) |
| Esquerda | **Deneb** (mostrador) | Campos: `dim_data[data_id]`, `dim_data[Idx]`, `dim_data[ano]`, medida `Interesse Mounjaro`. Cole `deneb_mostrador.json` no editor de especificação. Decorativo por enquanto (ver seção 7) — o controle real de mês é o segmentador abaixo. |
| Esquerda, abaixo do mostrador | **Segmentador** | Campo `dim_data[data_id]`, formato Lista, seleção única, ordenado por `dim_data[Idx]`. É o controle que de fato muda o mês em toda a página. |
| Centro do mostrador | **HTML Content** | Medida `HTML Centro` (mês + fase). Fundo e borda desligados. |
| Direita, topo | **HTML Content** | Medida `HTML Narrador` |
| Direita, meio | 4 botões | Bookmarks: jan/23, abr/25, mai/25, jul/26 (veja o passo 4) — alternativa rápida ao segmentador |
| Direita, baixo | **HTML Content** | Medida `HTML Gôndola` (as três barras coloridas com a marca do ano anterior) |

**Como a página filtra:** selecionar um mês no segmentador (ou clicar em um botão de capítulo) atualiza `Mês Selecionado`, e por consequência o `HTML Centro`, o `HTML Narrador` e o `HTML Gôndola`. Sem seleção, as medidas usam o último mês da série (jul/2026) por causa do `COALESCE` em `Mês Selecionado`.

## 3. Página "Linha do tempo e trilha"
1. **Gráfico de linhas:** Eixo X = `dim_data[data_id]` (hierarquia contínua, sem subdividir em ano/mês), Valores = parâmetro de campo `Métrica`, Legenda = `vw_varejo_variacao[categoria]`. Segmentação `Métrica` como botões acima.
   - Desligue a interação do mostrador com este gráfico (Formato > Editar interações), para a linha continuar inteira mesmo com um mês selecionado.
2. **Gráfico de dispersão** (a trilha): Valores = `dim_data[data_id]`, Eixo X = `Interesse Mounjaro`, Eixo Y = `Var Anual %`, Legenda = `categoria`, **Eixo de reprodução** = `dim_data[data_id]`. Na reprodução, clique com o botão direito em um ponto > "Mostrar rastro".
   - Adicione uma linha de tendência em Análise > Linha de tendência.
   - Segmentação de `categoria` para escolher a categoria.
3. **Cartões de correlação:** `Correlação Anual x Interesse`, filtrado por categoria (um cartão por categoria, com filtro no nível do visual).

## 4. Botões de capítulo (Bookmarks)
1. Crie uma segmentação temporária de `dim_data[data_id]` (lista) e selecione, por exemplo, jan/2023. Exibição > Indicadores > Adicionar, nome "jan/23".
2. Repita para abr/2025, mai/2025 e jul/2026.
3. Em cada botão (Inserir > Botões > Em branco), Ação > Indicador. Oculte a segmentação temporária no Painel de Seleção depois de criar os indicadores.
4. Nos indicadores, desmarque "Dados" se não quiser que o filtro de outras segmentações seja sobrescrito.

## 5. Página "Achados"
- Três cartões grandes (`Var Mai-Dez 2025 x 2024 %`), um por categoria, fonte "callout".
- Caixa de texto com as cautelas: 31 meses, séries dependentes no tempo, juros e renda, farmácia inclui o medicamento.
- Rodapé: "Fonte: IBGE (PMC, tabela 8882) e Google Trends. Elaboração própria."

## 6. Limites em relação à versão HTML
- **Não há arrasto do anel.** No Power BI, o mostrador responde a clique. Para "reproduzir" a linha do tempo, use o eixo de reprodução da dispersão.
- **As gôndolas são texto** (blocos `█`), não barras desenhadas. Para barras de verdade, use um gráfico de barras 100% empilhadas com uma medida por faixa.
- **Fontes:** Big Shoulders e Instrument Sans não vêm com o Power BI. O tema usa Bahnschrift, Segoe UI e Consolas, que existem no Windows.
- **Fundo pontilhado** do HTML não existe; o tema aplica só a cor de fundo da página.

## 7. Se o Deneb reclamar
- Erro de campo: os nomes na especificação (`Idx`, `ano`, `data_id`, `Interesse Mounjaro`) precisam ser idênticos aos campos arrastados para o Deneb. Renomeie o campo no painel de dados do Deneb ou ajuste a especificação.
- Riscos sobrepostos ou fora do círculo: ajuste `width`/`height` e os raios 92 e 96 nas transformações.
- Sem esmaecimento na seleção: confira se a seleção de pontos de dados está ativada (o campo `__selected__` só existe com ela ligada).
