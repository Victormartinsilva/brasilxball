# GDD-13 — Direção Artística 2.5D: "Brasil Fantástico em Miniatura"

## Regra de ouro técnica

> **2.5D visualmente; 2D mecanicamente.**

Personagens 3D estilizados + ambientes 3D estilizados + câmera fixa/semifixa + gameplay num plano 2D. A sensação de profundidade de um jogo 3D com a leitura imediata de um Breakout. O jogador nunca deve pensar *"a bola está 20 cm atrás daquele inimigo?"*.

```
X = posição horizontal      (física)
Y = profundidade da arena   (física)
Z = principalmente visual   (ordenação, escala, iluminação, animação, partículas, cenário)
```

No código: toda entidade guarda `pos: Vector2`; o nó 3D só espelha `Vector3(x, altura, -y)`.

## Camadas da tela

```
                 FUNDO 3D
        prédios / montanhas / céu / MASP
                    ↓
          AMBIENTE 3D INTERATIVO
      calçadas / árvores / postes / trânsito
                    ↓
              PLANO DE JOGO
        personagem + bolas + inimigos
                    ↓
             PRIMEIRO PLANO
       chuva / folhas / partículas
```

## Câmera "diorama"

- Inclinada (~60°), como olhar uma **maquete viva** de uma cidade brasileira.
- **Fixa durante o combate** (leitura acima de tudo).
- Reações pequenas: bola pesada → micro-impacto; explosão → *shake* leve; entrada de chefe → câmera recua; fase 2 do chefe → tremor.
- Retrato (celular): câmera mais vertical, arena ocupa a tela.

## Personagens (3D low-poly estilizado)

Formas grandes, poucos detalhes, materiais simples, proporções exageradas, contorno de nanquim.

| Personagem | Silhueta | Materiais | Detalhe vivo |
|---|---|---|---|
| **Guardião** | corpo largo, escudo enorme, cabeça pequena, postura pesada | metal envelhecido + couro + tecido | pisadas levantam poeira |
| **Caçadora** | fina, pernas longas, capa com movimento, arma assimétrica | tecidos + fibras + elementos da fauna | corre deixando partículas |
| **Alquimista** | baixa, mochila enorme, frascos, tubos, óculos | vidro + metal + madeira + reciclados | frascos balançam na mochila |

Todos usam **chapéu de aba larga** (referência às imagens de conceito: bandeirante/cangaceiro estilizado).

## Bolas

Trajetória 2D, aparência 3D: Ferro = esfera metálica com reflexo; Fogo = esfera incandescente; Gelo = cristal; Gravidade = esfera que distorce o ambiente; **Espelho = reflete o cenário** (o MASP refletido na bola).

## Iluminação como identidade

| Região | Luz |
|---|---|
| São Paulo | luzes urbanas, reflexos, chuva, neon, entardecer roxo-alaranjado |
| Rio | sol quente, mar brilhando, fim de tarde |
| Amazônia | luz filtrada pelas árvores, partículas no ar |
| Cataratas | névoa, arco-íris ocasional, luz difusa |
| Nordeste | sol forte, sombras duras, céu enorme |

## Escala

A 2.5D permite brincar com escala: árvore gigantesca na Amazônia, Cristo enorme no fundo do Rio, cataratas dominando a tela, prédios imensos em São Paulo. **Chefes ocupam profundidade** — o Arranha-Céu parece um prédio comum no fundo até as janelas acenderem.

## Mapa 2.5D

Um Brasil estilizado onde cada região é uma pequena ilha/diorama. Ao escolher São Paulo, a câmera aproxima, o mapa vira maquete, a maquete ganha vida e a batalha começa.

## Estado atual no protótipo

- ✅ Câmera diorama fixa com *shake* e recuo na entrada do chefe
- ✅ Paulista procedural: asfalto, faixa de pedestres, calçada em mosaico português, prédios com janelas acesas, letreiros neon piscando, ipês amarelos/roxos, postes, poças, MASP com feirinha no vão livre, trânsito ao fundo, chuva
- ✅ Contorno de nanquim (material *next pass* com *cull front*) em personagens, inimigos e prédios
- ✅ Personagens e inimigos de primitivas (placeholders) com animação procedural
- ⏳ Modelos definitivos (.glb), texturas pintadas, partículas de alta qualidade, pós-processamento — ver [ASSETS.md](ASSETS.md)

## Paleta de UI

Madeira escura `#3b2416`, ouro `#e8b04a`, creme `#f3e3c3`, vermelho `#c2412d`, verde-água `#3fb8a5`, nanquim `#120d08`. HUD inspirado nas referências: **espada de vida + orbe de habilidade** à esquerda, **trilha de caveiras** à direita, botões de velocidade `> >> >>>` no topo.
