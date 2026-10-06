# assets/conceitos — artes-fonte

Artes conceituais originais (alta resolução, fundo cinza). **Não são carregadas pelo jogo** (`.gdignore`).
O jogo usa os recortes transparentes em `assets/personagens/` e `assets/inimigos/`, gerados com:

```bash
python3 tools/recortar_arte.py assets/conceitos/<arquivo>.jpg assets/<categoria>/<id>/frente.png
# folhas com várias figuras: --caixa x0,y0,x1,y1
```

Padrão visual (todas as peças): vista 3/4 de cima (diorama), contorno de nanquim, pintura à mão,
paleta brasileira quente, **cada figura sobre uma base de calçada portuguesa** — no jogo elas parecem
miniaturas de tabuleiro ("Brasil Fantástico em Miniatura", ver docs/GDD-13).

## Índice

| Peça | Categoria | Arquivo-fonte | Recorte no jogo | Estado |
|---|---|---|---|---|
| **O Guardião** (frente) | Personagem | `guardiao_frente.jpg` | `personagens/guardiao/frente.png` (retrato) | ✅ no jogo |
| **O Guardião** (costas) | Personagem | `guardiao_costas.jpg` | `personagens/guardiao/costas.png` (sprite da arena) | ✅ no jogo |
| Guardião — Variante Dourada | Skin | `folha_personagens_inimigos_3x3.jpg` | `personagens/guardiao/dourado.png` | ✅ recortado (skin futura) |
| **A Caçadora** | Personagem | `fileira_personagens.jpg` | `personagens/cacadora/frente.png` | ✅ no jogo (baixa resolução) |
| **A Alquimista** | Personagem | `fileira_personagens.jpg` | `personagens/alquimista/frente.png` | ✅ no jogo (baixa resolução) |
| **Robô Zona Azul** | Inimigo | `fileira_personagens.jpg` | `inimigos/robo/frente.png` | ✅ no jogo (baixa resolução) |
| **Pombo Mecânico** | Inimigo | `folha_personagens_inimigos_3x3.jpg` | `inimigos/pombo/frente.png` | ✅ no jogo (baixa resolução) |
| **Fusca Corrompido** | Inimigo / obstáculo | `fusca_corrompido.jpg` | `inimigos/fusca/frente.png` | ✅ no jogo |
| Golem de Concreto | Inimigo | `folha_personagens_inimigos_3x3.jpg` | `inimigos/concreto/frente.png` | ✅ no jogo (baixa resolução) |
| Drone de Entrega | Inimigo | `folha_personagens_inimigos_3x3.jpg` | `inimigos/drone/frente.png` | ✅ no jogo (baixa resolução) |
| **O Arranha-Céu da Avenida Paulista** | Chefe | — | — | ⏳ falta a arte (o jogo usa o modelo 3D provisório) |

### Pendentes de arquivo em alta resolução

As versões individuais em alta da **Alquimista, Caçadora, Robô Zona Azul e Golem** foram vistas no chat,
mas ainda não estão no repositório. Coloque-as aqui com estes nomes e rode o recorte:

- `alquimista_frente.jpg` · `cacadora_frente.jpg` · `robo_zona_azul.jpg` · `golem_concreto.jpg` · `pombo_mecanico.jpg` · `arranha_ceu.jpg`

### Prompt sugerido para o chefe

> Hand-inked stylized fantasy illustration, bold black ink outlines, hand-painted textures, warm Brazilian palette.
> Living skyscraper boss from Avenida Paulista, stepped art-deco tower, facade windows forming angry red eyes,
> five glowing yellow windows at the base (weak points), garage-door mouth, two yellow construction-crane arms,
> antenna with blinking red light, standing on a large Portuguese-pavement base, 3/4 top-down diorama view,
> plain light gray background, no text.

### Cuidado com marcas reais

Os conceitos do Guardião trazem "CET" e "SÃO PAULO" nas tampas de bueiro, e o Robô traz "ZONA AZUL".
São nomes/marcas reais; para a arte final, prefira carimbos fictícios (ex.: "BXB", "PREFEITURA DA GROTA", um brasão inventado).
