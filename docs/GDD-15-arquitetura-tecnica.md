# GDD-15 — Arquitetura Técnica

## Visão geral

```
                    ┌──────────────────────┐
                    │        VERCEL        │
                    │ Landing page (site/) │
                    │ Jogo web (site/play) │
                    │ (futuro) ranking/API │
                    └──────────┬───────────┘
                               │ HTTPS (arquivos estáticos)
                    ┌──────────▼───────────┐
                    │        GODOT 4.3     │
                    │ Gameplay / física 2D │
                    │ Renderização 2.5D    │
                    │ Progressão + save    │
                    └──────────────────────┘
```

- **Godot** faz praticamente tudo: gameplay, física das bolas, colisões, inimigos, chefes, upgrades, partículas, câmera, save local.
- **Vercel** hospeda a landing page e o export Web do Godot (WebAssembly + WebGL 2). Futuramente: ranking, API de runs, wiki.
- Renderer **GL Compatibility** (único suportado no navegador). Export **sem threads** → não exige cabeçalhos COOP/COEP (estão no `vercel.json` mesmo assim, para o dia em que ativarmos threads).

## Separação de responsabilidades

```
                GAME
                 |
       ┌─────────┴─────────┐
   GAMEPLAY (2D)        VISUAL (3D/2.5D)
   Física / colisão     Cenário (diorama)
   Bolas / dano         Modelos / animação
   Inimigos / chefe     VFX / iluminação
   XP / build           Câmera
```

A física é **própria e determinística** (não usa o motor de física da Godot): círculo × retângulo com *substeps* (passo máx. 0,16 unidade), o que mantém os ricochetes previsíveis em qualquer velocidade de jogo (1x, 1.5x, 2x).

## Estrutura de pastas

```
project.godot            configuração (autoloads, renderer, janela)
export_presets.cfg       preset "Web"
data/                    TODO o conteúdo (JSON)
  balls.json             bolas + fusões (campo "componentes")
  enemies.json           inimigos
  passives.json          passivas (valores por nível)
  relics.json            relíquias
  characters.json        personagens (passiva, habilidade, atributos)
  regions.json           regiões (ondas, trânsito, chefe, posição no mapa)
scripts/
  autoload/game_data.gd  carrega os JSON, controles, orientação da tela
  autoload/save_data.gd  progressão permanente (user:// → IndexedDB no navegador)
  main.gd                fluxo Menu → Acampamento → Run → Resultado
  run/run.gd             loop da run: física, dano, elementos, reações, XP, combo, chefe
  run/run_build.gd       slots, passivas, relíquias, stats e geração de ofertas
  run/ball.gd            estado de uma bola + rastro
  run/enemy.gd           inimigo da grade + estados elementais
  run/boss.gd            O Arranha-Céu (pontos fracos, fases, ataques)
  run/player.gd          personagem + linha de mira
  run/fx.gd              faíscas, explosões, números, raios, avisos
  visual/models.gd       modelos procedurais (placeholders) + contorno nanquim
  visual/diorama_sao_paulo.gd  a Paulista em maquete
  ui/                    HUD, level up, menu, acampamento, resultados, kit de UI
site/                    landing page (Vercel); o jogo é exportado para site/play
docs/                    GDDs, referências, assets, roadmap
.github/workflows/       CI: teste automático + export web + deploy
```

## Modelo de dados (exemplo — bola)

```json
{
  "id": "brasa",
  "nome": "Brasa",
  "raridade": "incomum",
  "dano": 8, "velocidade": 15, "tamanho": 1.0, "ricochetes": 5, "piercing": 0,
  "quantidade": 1, "cooldown": 0.95, "critico": 0.05,
  "elementos": ["fogo"], "comportamento": "basico",
  "tags": ["elemental", "fogo", "area", "dot"],
  "cor": "#ff7a1f", "inicial": true, "custo": 0
}
```

- `elementos` dispara os efeitos (fogo = queimadura, gelo = lentidão/congelamento, veneno = DoT acumulativo, raio = corrente).
- `comportamento` seleciona a regra especial (`pesada`, `bumerangue`, `fantasma`, `clone`, `parasita`, `gravidade`, `espelho`, fusões).
- `tags` permitem passivas/inimigos interagirem por categoria (ex.: Golem de Concreto toma +50% de bolas `pesada`).
- **Fusão** = uma bola com `"componentes": ["brasa", "glacial"]`.

Adicionar conteúdo = editar JSON. Novas *regras* (comportamentos) exigem código em `run.gd`.

## Reações elementais

| Par | Reação | Efeito |
|---|---|---|
| fogo + gelo | Vapor | explosão em área (2x) |
| fogo + raio | Plasma | explosão maior (1,6x) |
| raio + veneno | Neurotóxica | espalha veneno para 4 vizinhos |
| gelo + raio | Sobrecarga | congela + 1,8x |
| fogo + veneno | Combustão | detona os acúmulos de veneno |
| gelo + veneno | Cristal tóxico | área + lentidão |

Alquimista: 60% de chance (100% com Catalisador). Outros personagens: 25% com a relíquia Núcleo Instável.

## Testes

- **Autoteste headless** (usado no CI): a IA joga uma run completa com todo o conteúdo liberado.
  ```bash
  godot --headless --fixed-fps 60 -- --autotest alquimista 400
  # imprime AUTOTEST_RESULT {json com vitória, tempo, nível, abates, dano por alvo...}
  ```
- **Atalhos de QA na web**: `?teste=chefe&personagem=cacadora`, `?teste=nivel`, `?teste=feira`.

## Deploy

1. Push → GitHub Actions baixa Godot 4.3 + templates, roda o autoteste com os 3 personagens, exporta para `site/play/`.
2. Na branch `main`, o workflow publica `site/` na branch **`deploy-web`**.
3. A Vercel (conectada ao repositório, *Production Branch* = `deploy-web`, sem build command) serve o site.
4. Alternativa: se os secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID` e `VERCEL_PROJECT_ID` existirem, o workflow também publica direto com `vercel deploy site --prod`.

Detalhes no [README](../README.md#deploy-na-vercel).
