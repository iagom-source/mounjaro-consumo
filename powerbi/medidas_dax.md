# Medidas DAX: Depois da Caneta

Modelo esperado (Importar, banco `ConsumoMounjaro`):

- `dim_data` (`data_id`, `ano`, `mes`, `nome_mes`, `periodo`)
- `vw_varejo_variacao` (`categoria`, `data_id`, `indice_volume`, `indice_ano_anterior`, `var_yoy_pct`, …)
- `vw_trends` (`data_id`, `termo`, `interesse`)
- Relacionamentos: `dim_data[data_id]` 1 → * `vw_varejo_variacao[data_id]` e 1 → * `vw_trends[data_id]`, filtro em sentido único.
- **Não** marque `dim_data` como tabela de datas: ela só tem o primeiro dia de cada mês, e o Power BI exige dias contíguos para isso. As medidas abaixo usam a coluna `Idx` em vez de funções de inteligência de tempo.

## 1. Coluna calculada em `dim_data`

```DAX
Idx = ( YEAR ( dim_data[data_id] ) - 2023 ) * 12 + MONTH ( dim_data[data_id] )
```
Resultado: jan/2023 = 1, mai/2025 = 29, jul/2026 = 43.

## 2. Tabela de medidas
Crie uma tabela vazia `_Medidas` (Página inicial > Inserir dados) e adicione as medidas abaixo nela.

### Base
```DAX
Mês Selecionado =
COALESCE (
    SELECTEDVALUE ( dim_data[data_id] ),
    CALCULATE ( MAX ( dim_data[data_id] ), REMOVEFILTERS ( dim_data ) )
)

Rótulo Mês =
UPPER ( FORMAT ( [Mês Selecionado], "mmm/yy", "pt-BR" ) )

Fase =
IF ( [Mês Selecionado] < DATE ( 2025, 5, 1 ), "PRÉ-LANÇAMENTO", "PÓS-LANÇAMENTO" )

Índice Volume =
AVERAGE ( vw_varejo_variacao[indice_volume] )

Índice Mesmo Mês Ano Anterior =
AVERAGE ( vw_varejo_variacao[indice_ano_anterior] )

Var Anual % =
VAR atual = [Índice Volume]
VAR ant   = [Índice Mesmo Mês Ano Anterior]
RETURN IF ( NOT ISBLANK ( ant ), DIVIDE ( atual, ant ) - 1 )

Interesse Mounjaro =
CALCULATE ( AVERAGE ( vw_trends[interesse] ), vw_trends[termo] = "Mounjaro" )
```
Formatos: `Var Anual %` como porcentagem com 1 casa; `Índice Volume` e `Interesse Mounjaro` com 1 casa.

### Tendência (média móvel de 12 meses, base 100 = abril/2025)
```DAX
Média Móvel 12M =
VAR i = MAX ( dim_data[Idx] )
VAR janela =
    FILTER ( ALL ( dim_data ), dim_data[Idx] <= i && dim_data[Idx] > i - 12 )
RETURN
    IF ( COUNTROWS ( janela ) = 12, AVERAGEX ( janela, [Índice Volume] ) )

Índice Base 100 =
VAR base =
    CALCULATE ( [Média Móvel 12M], REMOVEFILTERS ( dim_data ), dim_data[data_id] = DATE ( 2025, 4, 1 ) )
RETURN
    DIVIDE ( [Média Móvel 12M], base ) * 100
```
Atenção: dentro de `CALCULATE`, `REMOVEFILTERS` + filtro de data deixa uma única linha em `dim_data`, então `MAX ( dim_data[Idx] )` devolve o índice de abril/2025 (28).

### Comparação mai–dez/2025 contra 2024 (mesmo resultado da Q2 do SQL)
```DAX
Média Mai-Dez 2025 =
CALCULATE (
    [Índice Volume], REMOVEFILTERS ( dim_data ),
    dim_data[data_id] >= DATE ( 2025, 5, 1 ), dim_data[data_id] <= DATE ( 2025, 12, 1 )
)

Média Mai-Dez 2024 =
CALCULATE (
    [Índice Volume], REMOVEFILTERS ( dim_data ),
    dim_data[data_id] >= DATE ( 2024, 5, 1 ), dim_data[data_id] <= DATE ( 2024, 12, 1 )
)

Var Mai-Dez 2025 x 2024 % =
DIVIDE ( [Média Mai-Dez 2025], [Média Mai-Dez 2024] ) - 1
```

### Correlação (mesmo resultado da Q4 do SQL)
```DAX
Correlação Anual x Interesse =
VAR t =
    FILTER (
        ADDCOLUMNS ( ALL ( dim_data[data_id] ), "@x", [Interesse Mounjaro], "@y", [Var Anual %] ),
        NOT ISBLANK ( [@y] ) && NOT ISBLANK ( [@x] )
    )
VAR n   = COUNTROWS ( t )
VAR sx  = SUMX ( t, [@x] )
VAR sy  = SUMX ( t, [@y] )
VAR sxy = SUMX ( t, [@x] * [@y] )
VAR sxx = SUMX ( t, [@x] ^ 2 )
VAR syy = SUMX ( t, [@y] ^ 2 )
RETURN
    DIVIDE ( n * sxy - sx * sy, SQRT ( ( n * sxx - sx ^ 2 ) * ( n * syy - sy ^ 2 ) ) )
```
Use em um cartão filtrado por uma categoria (ou em uma tabela com `categoria`).

### Gôndolas de estoque (barras de blocos)
Escala de 80 a 140 pontos de índice, 40 blocos (1,5 ponto por bloco), a mesma do visual em HTML.
```DAX
Gôndola =
VAR lo = 80
VAR hi = 140
VAR nb = 40
VAR n  = ROUND ( ( [Índice Volume] - lo ) / ( hi - lo ) * nb, 0 )
VAR ant = [Índice Mesmo Mês Ano Anterior]
VAR pos = IF ( NOT ISBLANK ( ant ), ROUND ( ( ant - lo ) / ( hi - lo ) * nb, 0 ) )
RETURN
    CONCATENATEX (
        GENERATESERIES ( 1, nb ),
        VAR k = [Value]
        RETURN IF ( k = pos, "┃", IF ( k <= n, "█", "░" ) ),
        "",
        [Value], ASC
    )
```
Coloque em uma tabela ou cartão múltiplo, uma linha por `categoria`, com fonte monoespaçada (Consolas). O `┃` marca o mesmo mês do ano anterior.

### Narrador
```DAX
Narrador =
VAR m   = [Rótulo Mês]
VAR it  = FORMAT ( [Interesse Mounjaro], "0.0", "pt-BR" )
VAR fm  = "+0.0%;-0.0%;0.0%"
VAR s   = CALCULATE ( [Var Anual %], vw_varejo_variacao[categoria] = "Supermercados" )
VAR a   = CALCULATE ( [Var Anual %], vw_varejo_variacao[categoria] = "Alimentos, bebidas e fumo (total)" )
VAR f   = CALCULATE ( [Var Anual %], vw_varejo_variacao[categoria] = "Farmácia e perfumaria" )
VAR d   = [Mês Selecionado]
RETURN
    SWITCH (
        TRUE (),
        d < DATE ( 2024, 1, 1 ),
            m & ". Início da série. Ainda não há um ano de histórico para comparar. Interesse por Mounjaro: " & it & ".",
        d < DATE ( 2025, 5, 1 ),
            m & ". Antes do lançamento. Supermercados " & FORMAT ( s, fm, "pt-BR" ) & " e alimentos "
              & FORMAT ( a, fm, "pt-BR" ) & " contra o mesmo mês do ano anterior. Interesse: " & it & ".",
        d = DATE ( 2025, 5, 1 ),
            m & ". O Mounjaro chega às farmácias. Supermercados " & FORMAT ( s, fm, "pt-BR" )
              & " e alimentos " & FORMAT ( a, fm, "pt-BR" ) & ". Interesse: " & it & ".",
        m & ". Interesse por Mounjaro em " & it & ". Supermercados " & FORMAT ( s, fm, "pt-BR" )
          & ", alimentos " & FORMAT ( a, fm, "pt-BR" ) & " e farmácia " & FORMAT ( f, fm, "pt-BR" )
          & " contra o mesmo mês do ano anterior."
    )
```
Se `FORMAT` com formato de sinal mostrar pontos em vez de vírgulas, confira o idioma do modelo (Arquivo > Opções > Configurações regionais).

## 3. Medidas em HTML (para o visual "HTML Content")

Estas três medidas devolvem uma **string de HTML/CSS pronta**, com a mesma cara da página `dashboard/index.html` (fundo escuro, cor de destaque rosa `#E63E86`, fontes condensadas). Elas substituem os 4 cartões simples do guia original por 3 visuais "HTML Content".

**Instalar o visual (uma vez):** Página inicial > Obter mais visuais > procure **"HTML Content"** (autor CloudScope Analytics) > Adicionar. É um visual não certificado: na primeira vez que você o usa, o Power BI mostra um aviso de segurança — clique em **Habilitar este visual**.
Ele não carrega fontes externas (Google Fonts), por isso as medidas abaixo usam só fontes do Windows (`Consolas`, `Arial Narrow`, `Segoe UI`).

### 3.1 Centro do mostrador (Rótulo Mês + Fase)
```DAX
HTML Centro =
VAR m = [Rótulo Mês]
VAR fase = [Fase]
VAR cor = IF ( fase = "PÓS-LANÇAMENTO", "#E63E86", "#8490A5" )
RETURN
"<div style='font-family:Segoe UI,sans-serif;text-align:center;line-height:1'>" &
"<div style='font-size:11px;letter-spacing:2px;color:#8490A5;font-family:Consolas,monospace'>MÊS ANALISADO</div>" &
"<div style='font-size:56px;font-weight:900;color:#0C1424;margin-top:6px;font-family:Arial Narrow,sans-serif'>" & m & "</div>" &
"<div style='font-size:11px;letter-spacing:2px;margin-top:8px;color:" & cor & ";font-family:Consolas,monospace'>" & fase & "</div>" &
"</div>"
```
**Onde colocar:** insira um visual **HTML Content**, arraste `HTML Centro` para o campo de dados dele, e posicione sobre o centro do mostrador do Deneb (fundo e borda desligados em Formatar visual > Efeitos).

### 3.2 Narrador
```DAX
HTML Narrador =
VAR t = [Narrador]
RETURN
"<div style='font-family:Segoe UI,sans-serif;font-size:18px;line-height:1.5;color:#0C1424;padding:14px'>" &
"<span style='color:#E63E86;font-size:30px;font-weight:900;font-family:Georgia,serif;line-height:0'>“</span> " &
t &
"</div>"
```
**Onde colocar:** outro visual HTML Content, ao lado do mostrador, no lugar do "Cartão com várias linhas" do guia original.

### 3.3 Gôndolas (as três categorias em um só bloco, com barra e marca do ano anterior)
```DAX
HTML Gôndola =
VAR lo = 80
VAR hi = 140
RETURN
CONCATENATEX (
    ADDCOLUMNS (
        VALUES ( vw_varejo_variacao[categoria] ),
        "@idx", CALCULATE ( [Índice Volume] ),
        "@ant", CALCULATE ( [Índice Mesmo Mês Ano Anterior] ),
        "@yoy", CALCULATE ( [Var Anual %] ),
        "@cor",
            SWITCH (
                vw_varejo_variacao[categoria],
                "Supermercados", "#2A78D6",
                "Alimentos, bebidas e fumo (total)", "#EB6834",
                "Farmácia e perfumaria", "#1BAF7A",
                "#8490A5"
            )
    ),
    VAR pct    = MIN ( 100, MAX ( 0, DIVIDE ( [@idx] - lo, hi - lo ) * 100 ) )
    VAR pctAno = IF ( NOT ISBLANK ( [@ant] ), MIN ( 100, MAX ( 0, DIVIDE ( [@ant] - lo, hi - lo ) * 100 ) ) )
    VAR txt    = IF ( ISBLANK ( [@yoy] ), "sem base anual", IF ( [@yoy] >= 0, "▲ ", "▼ " ) & FORMAT ( [@yoy], "+0.0%;-0.0%" ) )
    VAR marca  = IF ( NOT ISBLANK ( pctAno ), "<div style='position:absolute;left:" & pctAno & "%;top:-4px;bottom:-4px;width:2px;background:#0C1424'></div>", "" )
    RETURN
        "<div style='font-family:Segoe UI,sans-serif;margin-bottom:16px'>" &
        "<div style='display:flex;justify-content:space-between;font-size:13px;font-weight:600;color:#0C1424;margin-bottom:5px'>" &
        "<span><span style='display:inline-block;width:10px;height:10px;border-radius:3px;background:" & [@cor] & ";margin-right:7px'></span>" & vw_varejo_variacao[categoria] & "</span>" &
        "<span style='font-family:Consolas,monospace;color:#465269'>" & txt & "</span></div>" &
        "<div style='background:#DBE0E8;border-radius:4px;height:16px;position:relative;overflow:visible'>" &
        "<div style='background:" & [@cor] & ";width:" & pct & "%;height:100%;border-radius:4px'></div>" & marca &
        "</div></div>",
    ""
)
```
**Onde colocar:** um terceiro visual HTML Content, no lugar da tabela de `Gôndola`. A marca preta vertical é o mesmo mês do ano anterior, igual ao traço `┃` da versão em texto.

**Conferência visual:** em jul/26, a medida `HTML Centro` deve mostrar "JUL/26" e "PÓS-LANÇAMENTO" em rosa; em jan/23, "PRÉ-LANÇAMENTO" em cinza. Se o HTML aparecer como texto cru (com as tags `<div>` visíveis) em vez de renderizado, o visual "HTML Content" não foi instalado corretamente, ou o campo foi solto no papel errado — confira se ele está no campo de dados chamado "HTML" ou "Value" do visual, não em "Tooltips" ou outro.

## 4. Parâmetro de campo (Tendência x Variação anual)
Modelagem > Novo parâmetro > Campos. Adicione `Índice Base 100` e `Var Anual %`, marque "Adicionar segmentação" e nomeie `Métrica`. O Power BI gera:
```DAX
Métrica = {
    ( "Tendência (base 100)", NAMEOF ( '_Medidas'[Índice Base 100] ), 0 ),
    ( "Variação anual",       NAMEOF ( '_Medidas'[Var Anual %] ),      1 )
}
```
Use `Métrica` no eixo Y do gráfico de linhas. Formate a segmentação como botões.

## 5. Conferência (compare com o SQL)
| Medida | Supermercados | Alimentos (total) | Farmácia |
|---|---|---|---|
| `Var Mai-Dez 2025 x 2024 %` | +0,4% | +0,2% | +5,1% |
| `Correlação Anual x Interesse` | −0,55 | −0,52 | −0,33 |

Se os valores baterem, o modelo está correto. Se não, verifique primeiro o relacionamento com `dim_data` e a coluna `Idx`.
