# Bioma 1 — Mata Atlântica (a boca da Grota Funda)

> Decisão (Victor e Isa): **premissa Grota Funda**, começando pela Mata Atlântica. São Paulo vira fase bônus da cidade grande.

## Cenário
Corredor de terra batida entre **paredões de pedra com musgo**, samambaias e bromélias nos degraus; jequitibás, palmeiras-juçara e quaresmeiras (roxas) acima; **cachoeira** no fundo da grota (de onde as assombrações descem); filete d'água no meio do campo; vaga-lumes e névoa leve. Na base da tela, a **cerca de bambu da vila** — inimigo que passa dela "invadiu a vila".

Código: `scripts/visual/diorama_mata_atlantica.gd`.

## Modificador de bioma — Cipós
A partir de 40s, cipós brotam atravessando 3–5 casas de uma fileira, **rebatem as bolas** por ~9s e murcham. Mudam as tabelinhas sem bloquear o jogo.

## Tropas

| Inimigo | Papel | Comportamento |
|---|---|---|
| Vaga-lume Errante | enxame fraco | básico |
| Macaco-Prego Arteiro | atirador | arremessa coquinhos (destrutíveis pelas bolas) |
| Tatu Encouraçado | tanque leve | carapaça absorve o 1º golpe |
| Cupinzeiro Vivo | 2 casas | estoura ao cair e fere vizinhos |
| Toco Assombrado | tanque | resiste a bolas leves; **pesadas** racham |

## Chefe — A Mula sem Cabeça
Padrão do GDD: **atravessa a tela em linha reta e quebra o ritmo das tabelinhas.**

1. **Ronda** no alto da grota.
2. **Aviso:** a fileira por onde ela vai passar acende em vermelho ("Tropel na mata!").
3. **Galope:** cruza a arena na fileira, rebate bolas, pisoteia tropas e deixa **rastro de fogo** (queima quem pisa — inclusive as tropas).
4. **Tonta:** para do outro lado por 2,4s e recebe **dano ×2,5** — a janela de ouro para acertar.

Fase 2 (metade da vida): galope mais rápido, invoca vaga-lumes e **às vezes mira a faixa do jogador** — é preciso andar para frente/trás para desviar.

Ajuste fino em `data/regions.json` (`mata_atlantica.chefe.hp`). Autoteste: luta de 48–69s.

## Pendências de arte
Concept art dos 5 inimigos, da Mula e do cenário (prompts no padrão de `assets/conceitos/README.md`).
