# GDD-01 — Ball x Brasil (Documento Geral)

> Roguelite brasileiro de ação, física e construção de builds.
> **Versão:** 0.1 · **Status:** Conceito / Pré-produção → Protótipo jogável (ver [ROADMAP](ROADMAP.md))

| Campo | Valor |
|---|---|
| Gênero | Roguelite + Breakout/Arkanoid + Survivors |
| Plataforma inicial | PC (navegador via Vercel; desktop via Godot) |
| Perspectiva | **2.5D** — visualmente 3D (diorama), mecanicamente 2D ([GDD-13](GDD-13-direcao-artistica-2.5D.md)) |
| Estrutura | Runs curtas + progressão permanente |
| Ambientação | Brasil fantástico, inspirado em cidades, biomas, cultura e paisagens brasileiras |
| Engine | Godot 4.3 (renderer Compatibility, export Web) |

Referências visuais: [`docs/referencias/`](referencias/).

---

## 1. Visão do jogo

O jogo combina **Breakout/Arkanoid**, **Roguelite** e **Survivors**. O jogador controla um personagem na parte inferior da tela enquanto bolas são lançadas automaticamente contra inimigos, obstáculos e estruturas. As bolas ricocheteiam, atravessam inimigos, aplicam efeitos, combinam-se e evoluem durante a partida.

Objetivo: sobreviver às ondas, derrotar chefes e chegar ao final da fase. Entre as partidas, recursos desbloqueiam personagens, bolas, passivas, relíquias, regiões, melhorias permanentes e novas possibilidades de build.

## 2. Identidade

Em vez de fantasia medieval genérica, uma versão **estilizada e fantástica do Brasil**: Avenida Paulista, Rio de Janeiro, Cataratas do Iguaçu, Amazônia, Nordeste, Pantanal, Minas Gerais, litoral, cidades históricas, sertão, regiões urbanas e rurais. Não é documental: é um **Brasil fantástico, exagerado e estilizado**.

## 3. Pilares de design

1. **Física divertida** — ricochetes, colisões, combos, explosões, multiplicação, reações, destruição em cadeia.
2. **Builds diferentes** — personagem + bolas + passivas + relíquias produzem estilos distintos.
3. **Runs curtas** — 15–25 min (run completa); cada fase com ondas, eventos, elite, mini-chefes e chefe.
4. **Progressão permanente** — mesmo perdendo, o jogador sente que avançou.
5. **Identidade brasileira** — reconhecível sem texto: *"Isso é o Brasil."*

## 4. Loop principal

```
BASE → Escolher personagem → Escolher bolas iniciais → Entrar em uma região → Combater ondas
→ Coletar XP → Subir de nível → Escolher melhoria → Criar build → Evento / Elite → Chefe
→ Recompensas → Voltar para a base → Desbloquear conteúdo → Nova run
```

## 5. Gameplay

O personagem permanece na região inferior da arena; as bolas são lançadas automaticamente. O jogador controla **posição, direção (mira), escolha de upgrades, gerenciamento da build e habilidades especiais**. O objetivo é criar trajetórias eficientes.

## 6–7. Sistema e categorias de bolas

Atributos: dano, velocidade, tamanho, peso, duração, quantidade, ricochetes, piercing, chance crítica, efeito elemental, comportamento especial.

| Bola | Comportamento | Status no protótipo |
|---|---|---|
| Pedra | Básica, previsível | ✅ |
| Ferro | Pesada, alto dano, atravessa inimigos que mata | ✅ |
| Brasa (Fogo) | Queimadura; inimigo queimado que morre cria área de fogo | ✅ |
| Glacial (Gelo) | Lentidão; 3 acertos congelam | ✅ |
| Peste (Veneno) | DoT acumulativo; espalha ao morrer | ✅ |
| Arco (Elétrica) | Salta para 1 → 2 → 4 → 8 alvos | ✅ |
| Bumerangue | Ao tocar o topo, volta atravessando tudo | ✅ |
| Fantasma | Atravessa inimigos, ricocheteia só em paredes | ✅ |
| Clone | Ao matar, pode criar cópia temporária | ✅ |
| Parasita | Gruda e explode | ✅ |
| Gravidade | Campo que segura e machuca | ✅ |
| Espelho | Copia o último elemento que atingiu o alvo | ✅ |

## 8. Fusão de bolas

Duas bolas (nível 3+) geram uma nova. O jogador deve **descobrir** combinações.

| Fusão | Receita | Efeito |
|---|---|---|
| Termodinâmica | Fogo + Gelo | Explode em inimigos lentos/congelados |
| Plasma | Fogo + Elétrica | Cada salto elétrico causa explosão |
| Neurotóxica | Veneno + Elétrica | Veneno salta pelas descargas |
| Singularidade | Gelo + Gravidade | Campo que atrai e congela |

## 9. Personagens iniciais

| | Guardião | Caçadora | Alquimista |
|---|---|---|---|
| Arquétipo | Defesa + força + bolas pesadas | Velocidade + crítico + combo | Elementos + reações |
| Passiva | **Muralha** — quanto mais tempo a bola fica em campo, mais dano | **Caçada** — cada abate aumenta o crítico; some ao perder o combo | **Reação** — elementos diferentes no mesmo inimigo reagem |
| Habilidade | **Impacto** — bolas que voltam ao chão disparam onda de choque | **Rajada** — várias bolas pequenas em sequência | **Catalisador** — aumenta a chance de reação |
| Estilo | Poucas bolas, muito dano, alta resistência | Muitas bolas, alta velocidade, alto risco | Combinações, controle, dano elemental |

## 10. Passivas

Passivas **alteram a gameplay**, não só números: Ricochete, Execução, Último Suspiro, Multiplicação, Fúria, Colecionador, Alquimia (+ Força Bruta, Cadência, Impulso, Vitalidade, Ímã, Precisão, Calibre, Tabela no protótipo — 15 no total).

## 11. Relíquias

Modificadores globais: Ampulheta Quebrada, Olho do Caçador, Núcleo Instável, Bolsa do Mercador (+ Cafezinho Coado, Bilhete Único e a lendária Coração de Dragão no protótipo).

## 12. Raridade

| Raridade | Função |
|---|---|
| Comum | efeito básico |
| Incomum | modificador simples |
| Rara | dois modificadores |
| Épica | comportamento especial |
| Lendária | altera a mecânica (ex.: **Coração de Dragão** — tudo vira fogo, gelo bloqueado) |

## 13. Slots de bolas

Três slots: **principal, secundária, especial**. Exemplo — Build Caçadora: Elétrica + Bumerangue + Clone com Crítico, Ricochete, Multiplicação.

## 14. Arquétipos de build

| Build | Personagem | Peças |
|---|---|---|
| Metralhadora | Caçadora | bolas rápidas, elétrica, multiplicação, velocidade |
| Tanque | Guardião | ferro, pedra, gravidade, ricochete |
| Veneno | Alquimista | peste, parasita, clone, propagação |
| Crítico | Caçadora | bumerangue, espelho, crítico, combo |
| Reação | Alquimista | fogo, gelo, raio, reação |

## 15–22. Cenários brasileiros

Cada região: identidade visual, inimigos, obstáculos, música, eventos, mecânica ambiental e chefe.

| Fase | Região | Mecânica | Chefe | Teste do chefe |
|---|---|---|---|---|
| 1 | **São Paulo** (Av. Paulista, metrô, viadutos, chuva, letreiros) | **Trânsito** — veículos cruzam a arena | **O Arranha-Céu** (janelas = pontos fracos, elevadores, antenas, drones) | velocidade e precisão |
| 2 | Rio de Janeiro (Pão de Açúcar, Cristo, Copacabana) | **Ondas** alteram a parte inferior | O Gigante da Baía | controle de trajetória |
| 3 | Cataratas do Iguaçu | **Correnteza** altera trajetórias | Guardião das Cataratas | adaptação à física |
| 4 | Amazônia | **Vegetação** que cresce e bloqueia | A Matriarca da Floresta | controle de área |
| 5 | Nordeste (sertão + litoral) | **Calor / temperatura** | O Rei do Sertão | — |
| 6 | Pantanal | **Água variável** (sobe e desce) | A Serpente do Pantanal | — |
| 7 | Minas Gerais | **Mineração** — paredes destrutíveis com bônus | O Senhor da Mina | — |

## 23. Mapa do Brasil (árvore de progressão)

```
                 AMAZÔNIA
                    |
               NORDESTE
                    |
             CENTRO-OESTE
             /          \
        MINAS          PANTANAL
          |
      SÃO PAULO
       /      \
 RIO DE JANEIRO  CATARATAS
```

Não precisa seguir exatamente a geografia: o mapa funciona como árvore de progressão.

## 24. Eventos regionais

Feira (escolha entre 3 recompensas) · Mercador (compra/troca bolas) · Ruína (relíquia rara) · Desafio (abates em tempo limitado) · Tesouro (bola, passiva ou recurso).

## 25. Chefes

Chefes **testam a build**, não apenas possuem muito HP. Cada chefe tem mecânicas próprias.

## 26. Base / Acampamento

Oficina (bolas) · Laboratório (fusões) · Arsenal (personagens/atributos) · Mercado (troca de recursos) · Mapa (regiões) · Relicário (relíquias).

## 27–28. Progressão permanente e morte

Recursos: moedas, materiais, cristais, recursos regionais (São Paulo: **Sucata**; Amazônia: Essência; Minas: Minério; Nordeste: Relíquia).
Ao morrer, perde parte dos recursos temporários, mas mantém personagens, bolas, relíquias e melhorias. *"Perdi a run, mas minha próxima tentativa será melhor."*

## 29. Combos

10 abates → x2 · 25 → x3 · 50 → x4 · 100 → **Frenesi**.

## 30–32. Experiência, decisões e sinergia

Ao subir de nível: **escolha 1 de 3** (nova bola, upgrade, passiva, relíquia, atributo). As escolhas equilibram **poder imediato × sinergia × economia**. Itens possuem **tags** (ELEMENTAL, FOGO, ÁREA, DOT…) para que passivas interajam com categorias inteiras.

## 33. Exemplo de run

Alquimista → Brasa → Glacial → passiva Reação → Arco → descobre Vapor (Fogo+Gelo) → Sobrecarga (Gelo+Raio). A build começa simples e termina completamente diferente.

## 34–36. Arte, trilha e humor

Arte: ver [GDD-13](GDD-13-direcao-artistica-2.5D.md). Trilha por região (SP eletrônico/urbano; Rio percussão/samba/bossa reinterpretados; Nordeste ritmos regionais; Amazônia floresta + percussão; Cataratas épica com água).
Humor brasileiro sem virar paródia:
- Mercador: *"Preço bom eu não garanto. Mas barato também não."*
- NPC: *"Se essa bola explodir, a culpa não foi minha."*
- Chefe: *"Você realmente achou que isso aqui era visita turística?"*

## 37–38. Primeiro MVP

3 personagens · 10–12 bolas · 15 passivas · 5 relíquias · 1 região (**São Paulo**, Av. Paulista fantástica) · 1 chefe (**O Arranha-Céu**) · 5–8 inimigos · movimentação, colisão, bolas, dano, XP, level up, upgrades, chefe, morte e vitória.

## 39–40. Roadmap e ordem técnica

Ver [ROADMAP.md](ROADMAP.md).

## 41–42. Arquitetura de dados e tags

Elementos orientados a dados desde o começo — ver [GDD-15](GDD-15-arquitetura-tecnica.md) e a pasta [`data/`](../data).

## 43. Princípio de balanceamento

Evitar *"esta bola é simplesmente melhor"*. Buscar *"esta bola é melhor para determinada build"*. Ex.: Bola de Ferro é ótima para Guardião e contra Golens de Concreto, ruim para builds de velocidade.

## 44–45. Diferencial e visão final

**Física** (bolas e ricochetes) + **Roguelite** (runs e progressão) + **Builds** (sinergias e fusões) + **Brasil** (regiões, cultura, natureza e cidades).

## 46–49. Primeiro objetivo real e regra de ouro

> Criar **uma única fase em São Paulo que seja divertida por 10 minutos.**
>
> O jogo não deve depender da quantidade de conteúdo para ser divertido. A diversão vem da interação **bola + física + inimigo + upgrade + ambiente**. O conteúdo brasileiro é multiplicador da experiência, não substituto da gameplay.

## 47. Próximos documentos

| Doc | Tema | Estado |
|---|---|---|
| GDD-01 | Documento geral | este arquivo |
| GDD-02 | Personagens | [`data/characters.json`](../data/characters.json) |
| GDD-03 | Catálogo de bolas | [`data/balls.json`](../data/balls.json) |
| GDD-04 | Passivas | [`data/passives.json`](../data/passives.json) |
| GDD-05 | Fusão | `componentes` em `balls.json` |
| GDD-06 | Relíquias | [`data/relics.json`](../data/relics.json) |
| GDD-07 | Inimigos | [`data/enemies.json`](../data/enemies.json) |
| GDD-08 | Chefes | `scripts/run/boss.gd` |
| GDD-09 | Mapa e regiões | [`data/regions.json`](../data/regions.json) |
| GDD-10/11/12 | Progressão, base, economia | `scripts/autoload/save_data.gd` |
| GDD-13 | Direção artística 2.5D | [GDD-13](GDD-13-direcao-artistica-2.5D.md) |
| GDD-14 | Áudio | pendente |
| GDD-15 | Arquitetura técnica | [GDD-15](GDD-15-arquitetura-tecnica.md) |
| GDD-16 | Roadmap | [ROADMAP](ROADMAP.md) |
| — | Catálogo de assets | [ASSETS](ASSETS.md) |

## 50. Frase-conceito

> Um roguelite brasileiro de ação onde bolas mágicas atravessam cidades, florestas e paisagens do Brasil em batalhas caóticas, enquanto você cria builds absurdas a cada partida.
>
> **Quebre. Ricocheteie. Evolua. Conquiste o Brasil.**
