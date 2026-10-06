# GDD-18 — Mecânica central: checklist Grota Funda × protótipo

Referências: [GDD-17 Grota Funda](GDD-17-grota-funda.md) (proposta de premissa) e [GDD-03 Catálogo de bolas brasileiras](GDD-03-catalogo-bolas-brasileiras.md).
Legenda: ✅ implementado · 🟡 parcial · ⏳ pendente · ❓ decisão em aberto

## 1. O campo

| Regra | Estado | Onde |
|---|---|---|
| Tela vertical (corredor) | ✅ retrato 540×960 é o layout principal | `game_data.gd` `_adapt_orientation` |
| Inimigos surgem no topo e descem em fileiras | ✅ | `run.gd` `_spawn_row` |
| Personagem anda na faixa de defesa (X **e** Y) | ✅ faixa y 0,35–3,2 | `player.gd` |
| Paredes laterais e teto rebatem | ✅ | `_ball_walls` |
| Câmera fixa | ✅ (só recua na entrada do chefe) | |
| Modificador de campo por bioma | 🟡 São Paulo tem trânsito; biomas ⏳ | `_update_traffic` |

## 2. Ciclo de vida da bola

| Regra | Estado | Detalhe |
|---|---|---|
| Chute no ângulo da mira, automático enquanto há bola na bolsa | ✅ | `_fire` — 1 chute a cada 0,22s ÷ cadência |
| Viagem em linha reta, ricochete em inimigos e paredes | ✅ | física própria com *substeps* |
| Uma bola acerta dezenas de vezes | ✅ | a bola **não** volta mais ao esgotar ricochetes |
| Só volta à bolsa ao descer até a linha de baixo | ✅ | `_ball_returned` |
| **Matar no peito**: pegar no ar = recarga imediata | ✅ | raio de 0,9 ao redor do personagem, só bolas descendo |
| Número de bolas limitado (tensão de ficar desarmado) | ✅ | HUD mostra "Bolsa X / Y" (fica vermelho em 0) |
| Dentes-de-leite (bolinhas da Torcida) | ✅ "Bolinhas de Gude": Guardião 3, Alquimista 4, Caçadora 6 | `characters.json` → `torcida` |

## 3. Habilidade do jogador

| Regra | Estado |
|---|---|
| Tabelinha: mirar na brecha prende a bola atrás da linha | ✅ emerge da física (e não há mais retorno forçado) |
| Chutar deixa o personagem mais lento | ✅ 60% da velocidade (Caçadora ignora — equivalente ao "Capoeirista") |
| Desligar o chute para correr | ✅ botão "Chute: AUTO/PARADO" e tecla Q |
| Projéteis inimigos destrutíveis pelas bolas | ✅ |
| Corpo a corpo com aviso de olho gordo 👁 | ✅ olho sobre o inimigo, golpe após 0,9s se você continuar perto |
| Invasão: inimigo atravessa a linha e entra na vila | ✅ |

## 4. Tipos de bola × física

| Tipo GDD | No jogo |
|---|---|
| Comum | Bolinha de Gude |
| Perfurante (só rebate nas paredes) | Corpo-Seco, Saci, Fumacê |
| Status por toque | Pimenta (Ardência), Jararaca (Peçonha), Geada, Onça (Arranhão) |
| Área / choque | Zabumba, Trovoada, Pororoca, Cachoeira, Bomba de São João |
| Some ao bater (mistura fraca de propósito) | Mau-Olhado — volta à bolsa no primeiro acerto |

## 5. Progressão na partida

| Regra | Estado |
|---|---|
| Escolha 1 de 3 ao subir de nível | ✅ |
| Receitas (bolas nível 3) na "Panela de Pressão", com receitas alternativas | ✅ 9 receitas |
| **Tirar na Sorte** com custo crescente | ✅ grátis com Patuás do Arsenal, depois 5, 10, 15… de sucata |
| Patuá com Benzer / Misturar / Encantar | ❓ conflita com o glossário do GDD-03 (Repique / Mistura / Receita) |
| Mandar pro Banco (banir opção) | ⏳ |
| Chefe do folclore | ❓ hoje o chefe é O Arranha-Céu (São Paulo) |

## 6. Fora da partida

| Regra | Estado |
|---|---|
| Morrer não é derrota total | ✅ mantém 60% da sucata |
| A Vila / Mutirão (pinball) / Causos / Mandioca-Madeira-Barro | ❓ hoje é o Acampamento com Sucata |
| 6 atributos (Fôlego, Raça, Torcida, Ginga, Malandragem, Sabedoria) | 🟡 Torcida existe; os demais ⏳ |

## Decisões em aberto (precisam de Victor e Isa)

1. **Premissa:** "Ball x Brasil" com São Paulo/Arranha-Céu **ou** "Grota Funda" com biomas e chefes do folclore? (Dá para ter os dois: Grota como campanha principal e cidades como fases bônus.)
2. **Glossário:** Repique/Mistura/Receita (GDD-03) **ou** Patuá com Benzer/Misturar/Encantar?
3. **Base:** manter o Acampamento ou migrar para a Vila com Mutirão?
4. **Nível máximo da bola:** GDD-03 diz 1–3; o protótipo usa 1–5 (receita exige nível 3).
5. **Folclore ambíguo:** Curupira e Iara como aliados/guardiões, não monstros (sugestão do próprio GDD).
