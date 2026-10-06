# Roadmap (GDD-16)

Legenda: ✅ feito no protótipo · 🟡 parcial · ⏳ pendente

## Fase 1 — Protótipo ("provar que jogar é divertido")

- ✅ Personagem e movimentação (teclado, mouse, toque)
- ✅ Bola, física própria 2D com *substeps*, colisão círculo × retângulo
- ✅ Inimigos em grade que descem, bloqueio por coluna
- ✅ Dano, destruição, números de dano, *hit punch*
- ✅ XP (gemas), level up, escolha 1 de 3

## Fase 2 — Sistema de builds

- ✅ 12 bolas + 4 fusões (16 no total) — `data/balls.json`
- ✅ 15 passivas com níveis — `data/passives.json`
- ✅ Raridades (comum → lendária)
- ✅ 3 slots de bola
- ✅ Tags e sinergias (pesada × concreto, elemental × alquimia…)
- ✅ 6 reações elementais
- ✅ 7 relíquias (inclui lendária Coração de Dragão)

## Fase 3 — Personagens

- ✅ Guardião (Muralha + Impacto)
- ✅ Caçadora (Caçada + Rajada)
- ✅ Alquimista (Reação + Catalisador)

## Fase 4 — Primeira região: São Paulo

- ✅ Diorama da Avenida Paulista (procedural)
- ✅ 5 inimigos + variante elite
- ✅ Mecânica de trânsito (veículos bloqueiam bolas)
- ✅ Evento Feira da Paulista (escolha de relíquias)
- ✅ Chefe O Arranha-Céu (pontos fracos, 2 fases, estilhaços, invocações)
- ✅ Música e efeitos sonoros (provisórios, sintetizados — `tools/gerar_audio.py`)
- ⏳ Cenário "quebrando" ao longo da run

## Fase 5 — Progressão

- ✅ Acampamento: Oficina, Laboratório, Arsenal, Relicário, Registros
- ✅ Sucata como recurso; derrota mantém 60%
- ✅ Save local (IndexedDB no navegador)
- ✅ Mapa do Brasil (árvore de progressão; demais regiões "em breve")
- ⏳ Mercado (troca de recursos)

## Fase 6 — Conteúdo (Grota Funda)

- ✅ Bioma 1: Mata Atlântica — cenário, 5 tropas, Cipós, chefe A Mula sem Cabeça
- ⏳ Cerrado · Caatinga · Pantanal · Pampa · Amazônia (fase final, Mapinguari)

- ⏳ Rio de Janeiro (Ondas) · Cataratas (Correnteza) · Amazônia (Vegetação) · Nordeste (Calor) · Pantanal (Água variável) · Minas (Mineração)

## Fase 7 — Polimento

- ⏳ Assets definitivos ([ASSETS.md](ASSETS.md))
- 🟡 Áudio (provisório pronto; falta o definitivo)
- ⏳ Partículas e pós-processamento
- ⏳ Balanceamento com jogadores reais
- ⏳ Ranking via API na Vercel

## Ordem técnica (seção 40 do GDD)

`Player → Movimento → Bola → Física → Inimigos → Dano → XP → Level Up → Upgrades → Builds → Personagens → Chefes → Fases → Meta → Base → Conteúdo → Polimento`

Itens 1–15 estão implementados no protótipo; 16–17 são as próximas frentes.

## Métricas do autoteste (bot com escolhas aleatórias, todo o conteúdo liberado)

| Personagem | Resultado | Duração | Luta do chefe | Nível | Abates |
|---|---|---|---|---|---|
| Guardião | derrota (no chefe) | 5:25 | 25 s | 15 | 647 |
| Caçadora | vitória | 5:38 | 38 s | 15 | 665 |
| Alquimista | derrota (no chefe) | 6:09 | 69 s | 16 | 642 |

O bot sempre escolhe a primeira carta e não usa a mira manual — jogadores humanos devem ir melhor. HP do chefe, velocidade de descida e escala de vida estão em `data/regions.json` para ajuste fino.

Meta de design: run de SP com 6–8 min; luta de chefe entre 40 s e 90 s para um jogador humano.
