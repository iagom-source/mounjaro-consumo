# Post 1: Consumo x Mounjaro

> Antes de publicar: preencher os itens em [COLCHETES] e conferir os números contra o resultado final do SQL e do dashboard.

## Texto do post (LinkedIn)

Muita gente diz que as canetas emagrecedoras vão derrubar o consumo de alimentos.

Fui olhar os dados. 📊

Comparei o volume de vendas do varejo brasileiro (IBGE) com o interesse de busca por "Mounjaro" (Google Trends), antes e depois do lançamento no Brasil, em maio de 2025.

O que encontrei:

▪️ Supermercados: +0,4% no volume de vendas (mai–dez/2025 vs. mesmo período de 2024)
▪️ Alimentos, bebidas e fumo: +0,2%
▪️ Farmácia e perfumaria: +5,1%

Ou seja: o volume de alimentos não caiu, mas ficou praticamente parado.

Aí refiz a conta de um jeito mais rigoroso: correlacionei o interesse por "Mounjaro" com a variação anual do varejo (isso tira a tendência e a sazonalidade). Deu negativa nas três categorias: -0,55 em supermercados, -0,52 em alimentos e -0,33 em farmácia.

Traduzindo: nos meses em que o interesse pelas canetas subiu, o crescimento anual do varejo tendeu a perder força.

Mas atenção, porque é aqui que análise vira opinião se a gente não tiver cuidado:
▪️ São só 31 meses, e séries mensais são "coladas" no tempo, então a confiança estatística é bem menor do que o número sugere.
▪️ Juros altos, renda e inflação também desaceleraram o varejo no mesmo período.
▪️ O volume de farmácia subiu, mas a categoria provavelmente inclui o próprio medicamento.

É um sinal para investigar, não uma prova.

O que aprendi:
1️⃣ Comparar "antes x depois" sem controlar a tendência exagera o efeito. A média pós-lançamento era maior só porque o índice sobe com o tempo.
2️⃣ Olhar a variação anual, e não o nível, mudou a conclusão: de "nada acontece" para "há um sinal de desaceleração".
3️⃣ Correlação não é causalidade. Sem dado de compra por pessoa, não dá para afirmar quem deixou de comprar o quê.

Fiz o projeto com SQL Server (modelagem e análise) e Power BI (dashboard), com dados 100% públicos.

Dashboard e código: [LINK DO GITHUB]

Se você trabalha com varejo ou saúde: que outro dado você cruzaria para testar essa hipótese? 👇

#AnáliseDeDados #PowerBI #SQL #DataAnalytics #Varejo

---

## Roteiro do carrossel (9 slides)
1. **Capa:** "As canetas emagrecedoras derrubaram o consumo de alimentos? Fui olhar os dados."
2. **Pergunta e contexto:** Mounjaro chegou às farmácias do Brasil em mai/2025.
3. **Fontes:** IBGE (PMC) + Google Trends, jan/2023 a jul/2026.
4. **Método:** SQL Server (modelo estrela) + Power BI; mesmo mês, ano contra ano.
5. **Resultado 1:** volume estável no ano (supermercados +0,4%, alimentos +0,2%).
6. **Resultado 2:** farmácia +5,1%, com a ressalva de que ela inclui o medicamento.
7. **Resultado 3:** correlação em variação anual negativa (-0,55 / -0,52 / -0,33), com gráfico de linhas Interesse x YoY.
8. **Cuidados:** 31 meses, juros e renda como fatores, e por que "antes x depois" engana.
9. **Fechamento:** conclusão em uma frase + link do GitHub + pergunta para os comentários.

## Dicas de publicação
- Publique de terça a quinta, pela manhã.
- Coloque a imagem principal do dashboard (página 1) como primeira imagem do carrossel.
- Responda os comentários na primeira hora.
- Depois de 1 semana, publique um segundo post com os bastidores: "3 erros que evitei nessa análise".
