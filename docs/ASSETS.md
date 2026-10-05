# Catálogo de Assets — do conceito ao jogo

Hoje **todo o visual é procedural** (primitivas + contorno de nanquim, em `scripts/visual/models.gd` e `diorama_sao_paulo.gd`). Isso permite jogar e balancear antes de investir em arte. Este documento lista cada asset que substituirá um placeholder, com especificação técnica e um **prompt-base** para gerar o conceito (IA ou briefing para artista), mantendo o estilo das [referências](referencias/).

## Especificação técnica comum

| Item | Padrão |
|---|---|
| Formato 3D | `.glb` (glTF 2.0), Y para cima, 1 unidade = 1 casa da arena |
| Orientação | frente do modelo para **-Z** (inimigos são girados 180° no código) |
| Polígonos | personagem ≤ 4k tris · inimigo ≤ 1,5k · chefe ≤ 12k · prop ≤ 800 |
| Texturas | 512² (inimigos/props) · 1024² (personagens/chefe) · paleta pintada à mão, sem PBR complexo |
| Contorno | **não** pintar contorno na textura: o jogo aplica o nanquim via material |
| Animações | `idle`, `walk`, `hit`, `death` (+ `attack` para chefes) — 12–24 fps "stepped" |
| Pasta | `assets/<categoria>/<id>/` (ex.: `assets/inimigos/pombo/pombo.glb`) |
| Troca no código | substituir `Models.build_enemy("pombo", ...)` por `load("res://assets/inimigos/pombo/pombo.glb").instantiate()` |

## Estilo-base (prefixo de todo prompt)

> *Stylized hand-inked 2.5D game asset, chunky low-poly shapes with bold black ink outlines, hand-painted flat textures, warm saturated Brazilian palette, slight weathering, readable silhouette from a 60° top-down diorama camera, fantasy Brazil, no text, isolated on neutral background, game-ready —*

---

## 1. Personagens

| ID | Placeholder atual | Descrição de arte | Prompt (após o prefixo) |
|---|---|---|---|
| `guardiao` | cápsula cinza, ombreiras de couro, escudo com faixa dourada, chapéu de aba vermelho | Gigante gentil de armadura reciclada, escudo de tampa de bueiro paulistano, chapéu de couro de aba larga | *hulking guardian in patched metal armor made from recycled manhole covers and leather straps, oversized round shield with gold trim, wide-brim red leather hat, small head, heavy stance* |
| `cacadora` | cápsula verde, capa, chapéu vermelho, arma longa com ponta luminosa | Caçadora ágil inspirada na fauna (onça, arara), estilingue-arco assimétrico | *agile huntress with long legs, flowing green cape with jaguar spots, macaw feather accents, asymmetric slingshot-bow with glowing yellow tip, wide-brim red hat* |
| `alquimista` | cápsula verde-água, mochila enorme com 3 frascos (fogo/gelo/veneno), óculos dourados | Inventor baixinho com mochila-laboratório de garrafas PET e cobre | *short alchemist with gigantic backpack full of glowing flasks (orange, cyan, green), copper tubes, brass goggles, patched purple hat, recycled-materials aesthetic* |

## 2. Bolas (São Paulo + base)

Esferas com shader próprio; o asset é o **material + VFX de rastro**.

| ID | Visual alvo |
|---|---|
| `pedra` | pedra portuguesa arredondada (calçada) |
| `ferro` | esfera de ferro fundido com rebites e reflexo forte |
| `brasa` | carvão incandescente com rachaduras laranja e fagulhas |
| `glacial` | cristal de gelo facetado girando, névoa fria |
| `peste` | bolha verde viscosa com bolhas internas |
| `arco` | núcleo amarelo com arcos elétricos orbitando |
| `bumerangue` | disco/coco achatado de madeira entalhada |
| `fantasma` | esfera translúcida verde-água com rosto sutil |
| `clone` | esfera rosa com "eco" holográfico |
| `parasita` | semente orgânica com garras |
| `gravidade` | esfera escura que distorce o fundo (shader de refração) |
| `espelho` | esfera cromada que reflete o cenário (MASP refletido) |
| Fusões | combinação dos dois visuais + anel orbital da 2ª cor |

## 3. Inimigos — São Paulo

| ID | Nome | Placeholder | Prompt |
|---|---|---|---|
| `pombo` | Pombo Mecânico | esfera cinza, asas que batem, olhos vermelhos, engrenagem nas costas | *clockwork city pigeon with brass gears on its back, red glowing eyes, chubby body, flapping tin wings* |
| `drone` | Drone de Entrega | caixa escura, 4 rotores, pacote embaixo, olho vermelho | *corrupted delivery drone carrying a cardboard package bomb, 4 spinning rotors, red camera eye* |
| `robo` | Robô Zona Azul | corpo azul com faixa creme, cabeça com antena e olhos ciano | *parking-meter robot in blue and cream "Zona Azul" livery, armored front plate, antenna with red light* |
| `fusca` | Fusca Corrompido | carro roxo arredondado, faróis vermelhos (2 casas de largura) | *possessed purple Volkswagen Beetle with glowing red headlights, cracked windshield, smoke, 2 tiles wide* |
| `concreto` | Golem de Concreto | blocos cinza com musgo e vergalhão, olhos laranja | *concrete golem made of sidewalk slabs and exposed rebar, moss on shoulders, orange glowing eyes* |
| *elite* | variante dourada | tom dourado + coroa | mesma base com *gold trim and a small crown* |

## 4. Chefe — O Arranha-Céu

| Parte | Descrição |
|---|---|
| Corpo | prédio de 3 volumes escalonados, fachada cinza-azulada, janelas amarelas |
| Rosto | duas janelas grandes vermelhas (olhos), garagem como boca |
| Pontos fracos | 5 janelas na base — as **acesas** levam 2,5x de dano |
| Braços | dois guindastes amarelos que balançam |
| Topo | antena com luz vermelha piscando |
| Animações | `despertar` (janelas acendendo), `ataque_vidraca` (estilhaços caem), `invocar_drones`, `fase2` (fachada racha), `queda` |

Prompt: *living skyscraper boss from Avenida Paulista, stepped art-deco tower, facade windows forming angry red eyes, garage-door mouth, two yellow construction-crane arms, antenna with blinking red light, cracked glass, menacing but whimsical*

## 5. Cenário — Avenida Paulista (diorama)

| Asset | Status | Observação |
|---|---|---|
| Asfalto da arena com grade sutil | procedural | textura pintada 1024², linhas da grade a 1 unidade |
| Faixa de pedestres | procedural | é a "linha de defesa" do jogador |
| Calçada em mosaico português (ondas preto/branco) | procedural | textura *tileable* triplanar |
| Prédios laterais com janelas | procedural (6 tons) | kit modular: térreo, andar, cobertura, caixa d'água, antena |
| Letreiros neon | procedural (piscam) | kit de placas sem texto legível (ou com piadas locais) |
| **MASP** + vão livre com feirinha | procedural | asset *hero* do fundo |
| Ipês amarelos/roxos, árvores verdes | procedural | 3 variações cada |
| Postes, ponto de ônibus, banca de jornal | procedural | props |
| Ônibus, táxi, carro (trânsito) | procedural | também usados como obstáculos na faixa de trânsito |
| Chuva, poças com reflexo neon | procedural | partículas + material |

## 6. UI

| Asset | Placeholder | Alvo |
|---|---|---|
| Espada de vida | polígono desenhado | espada de madeira/cobre com gema vermelha (ver referências) |
| Orbe de habilidade | círculos | moldura de cobre com orbe animado na cor do personagem |
| Trilha de progresso | barra + caveiras desenhadas | trilha de madeira com caveiras de chapéu (bandeirante/cangaceiro) |
| Ícones de bola/passiva/relíquia | círculo colorido + inicial | ícones pintados 128² |
| Fonte | fonte padrão | fonte display com serifa grossa (OFL) para títulos |

## 7. Áudio (GDD-14)

| Asset | Descrição |
|---|---|
| Música SP | eletrônico urbano acelerado com sample de buzina e metrô |
| SFX bola | "PÁ!" de ricochete (3 variações por material: pedra, ferro, elemental) |
| SFX inimigo | arrulho metálico (pombo), zumbido (drone), apito (zona azul), motor engasgando (fusca), rocha (golem) |
| SFX chefe | sirene de prédio, vidro estilhaçando, guindaste |
| Voz/latido | falas curtas do mercador e do chefe |

## 8. Próximas regiões (concept art primeiro)

As [imagens de referência](referencias/) já cobrem **Sertão Assombrado, Litoral Histórico, Floresta Amazônica Mítica e Pantanal Selvagem** — usar como guia de paleta e composição para os dioramas das fases 2–7.

## Pipeline sugerido

1. **Conceito** (prompt acima ou artista) → 2. **Modelagem low-poly** (Blender) → 3. **Pintura de textura** → 4. **Export .glb** com animações → 5. Colocar em `assets/` → 6. Trocar a função `build_*` correspondente em `models.gd` → 7. Rodar o autoteste e conferir no navegador.
