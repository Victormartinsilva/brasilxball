# Bolas – Temática Brasileira

Documento de design com sugestões de bolas para um jogo com a mesma mecânica de *Ball X Pit* (bolas que quicam, sobem de nível de 1 a 3, evoluem e se fundem), reambientado no folclore, na fauna, na cultura e no cotidiano do Brasil.

> Os números são pontos de partida para balanceamento, inspirados nos valores de referência. Ajuste após os testes.

---

## 1. Glossário de mecânicas (renomeadas)

| Mecânica original | Nome sugerido | Ideia |
|---|---|---|
| Baby Ball | **Bolinha de Gude** | Bolinha comum, sem efeito, dano base. Escala com o atributo *Liderança* → **Malandragem** |
| Special Ball | **Bola Especial** | Tem habilidade própria, nível 1–3 |
| Fission (subir de nível) | **Repique** | Pegar outra cópia da mesma bola para subir de nível |
| Fusion Reactor | **Panela de Pressão** | Onde as bolas de nível 3 são evoluídas ou fundidas |
| Evolution | **Receita** | Combinação específica que gera uma bola nova com nome próprio |
| Fusion | **Mistura** | Une duas bolas sem receita: soma os efeitos (ex.: *Onça × Geada*) |
| Encyclopedia | **Almanaque** | Catálogo de bolas descobertas |

### Status de efeito

| Status | Origem temática | Efeito |
|---|---|---|
| **Arranhão** (sangramento) | Garras da onça | Dano extra por acúmulo quando atingido por qualquer bola |
| **Ardência** (queimadura) | Pimenta | Dano por segundo por acúmulo |
| **Peçonha** (veneno) | Cobras | Dano por segundo, dura mais que Ardência |
| **Congelado** | Geada do Sul | Parado; recebe +25% de dano |
| **Encantado** | Iara / Boto | Inimigo vira aliado temporário |
| **Ofuscado** | Vaga-lume / Sol | 50% de chance de errar ataques |
| **Mau-olhado** (maldição) | Crendice popular | Após X acertos, sofre um dano grande |
| **Virose** (doença) | Gíria para qualquer mal-estar | Dano por segundo que se espalha para vizinhos |
| **Zica** (radiação) | Gíria para azar | Cada acúmulo aumenta o dano recebido em 10% |

---

## 2. Bolas Base (18 + 2 pós-lançamento)

| # | Nome | Referência original | Descrição | Personagem inicial sugerido |
|---|---|---|---|---|
| 1 | **Onça-Pintada** | Bleed | Aplica 2 acúmulos de Arranhão. Inimigos arranhados sofrem 1 de dano por acúmulo ao serem atingidos (máx. 8). | O Vaqueiro |
| 2 | **Saúva** | Brood Mother | 25% de chance de gerar uma Bolinha de Gude a cada acerto. | A Formigueira |
| 3 | **Pimenta Malagueta** | Burn | 1 acúmulo de Ardência por 3s (máx. 3). 4–8 de dano por acúmulo/s. | A Baiana do Acarajé |
| 4 | **Maniva** | Cell | Ao acertar, brota um clone (até 2 vezes), como rama de mandioca. | — |
| 5 | **Iara** | Charm | 4% de chance de Encantar por 5s. Encantados sobem o campo e atacam outros inimigos. | — |
| 6 | **Mau-Olhado** | Dark | Causa 3x de dano mas se destrói ao acertar. Recarga de 3s. | A Benzedeira |
| 7 | **Zabumba** | Earthquake | Batida de forró: 5–13 de dano em área 3x3. | O Sanfoneiro |
| 8 | **Pipoca** | Egg Sac | Estoura em 2–4 Bolinhas de Gude ao acertar. Recarga de 3s. | O Pipoqueiro |
| 9 | **Geada** | Freeze | 4% de chance de Congelar por 5s. Congelados recebem +25% de dano. | O Gaúcho |
| 10 | **Corpo-Seco** | Ghost | Atravessa inimigos. | A Alma Penada |
| 11 | **Tatu-Bola** | Iron | Dano dobrado, mas 40% mais lento. | O Mineiro, O Estrategista |
| 12 | **Pororoca** | Laser (H) | Onda que causa 9–18 de dano em toda a linha. | — |
| 13 | **Cachoeira** | Laser (V) | Queda d'água que causa 9–18 de dano em toda a coluna. | O Engenheiro |
| 14 | **Vaga-lume** | Light | Ofusca por 3s (50% de chance de errar ataques). | O Astrônomo |
| 15 | **Trovoada** | Lightning | Raio de 1–20 de dano em até 3 inimigos próximos. | O Malabarista de Farol |
| 16 | **Jararaca** | Poison | 1 acúmulo de Peçonha (máx. 5), 6s, 1–4 de dano por acúmulo/s. | O Seringueiro |
| 17 | **Morcego** | Vampire | 4,5% de chance de curar 1 de vida por acerto. | O Gastão |
| 18 | **Saci** | Wind | Redemoinho: atravessa inimigos e os desacelera em 30% por 5s, mas causa 25% menos dano. | O Moleque de Rua |
| P1 | **Paralelepípedo** | Stone | Começa com 300% de dano e perde 40% a cada acerto (mín. 50%). | O Calceteiro |
| P2 | **Cuca** | Time | Ao acertar, cria uma zona de "nana neném" por 20s que adormece (congela) quem estiver dentro. | — |

---

## 3. Receitas (Evoluções)

| Nome | Referência | Receita | Descrição |
|---|---|---|---|
| **Curupira** | Assassin | Tatu-Bola + Corpo-Seco · Tatu-Bola + Mau-Olhado | Com os pés virados, atravessa a frente dos inimigos mas não as costas. Golpes pelas costas causam +30% de dano. |
| **Briga de Torcida** | Berserk | Iara + Onça · Iara + Pimenta | 30% de chance de deixar o inimigo "esquentado" por 6s; ele causa 15–24 de dano por segundo aos vizinhos. |
| **Boca de Lobo** | Black Hole | Mau-Olhado + Sol do Sertão | O bueiro engole o primeiro inimigo que não seja chefe e some. Recarga de 7s. |
| **Minuano** | Blizzard | Geada + Saci · Geada + Trovoada | Vento gelado: congela tudo num raio de 2 por 0,8s, causando 1–50 de dano. |
| **Bomba de São João** | Bomb | Pimenta + Tatu-Bola | Explode ao acertar: 150–300 de dano em área. Recarga de 3s. |
| **Clarão** | Flash | Trovoada + Vaga-lume | Ao acertar, causa 1–3 de dano em todos os inimigos da tela e ofusca por 2s. |
| **Pisca-Pisca de Natal** | Flicker | Vaga-lume + Mau-Olhado | Causa 1–7 de dano em todos da tela a cada 1,4s. |
| **Frente Fria** | Freeze Ray | Geada + Pororoca · Geada + Cachoeira | Dispara um raio frio de 20–50 de dano no trajeto, com 10% de chance de congelar por 10s. |
| **Caipirinha** | Frozen Flame | Pimenta + Geada | Gelo e cachaça: 1 acúmulo de "Ardência Gelada" por 20s (máx. 4), 8–12 de dano por acúmulo/s; o alvo recebe +25% de dano. |
| **Granizo** | Glacier | Geada + Zabumba | Solta pedras de gelo que causam 15–30 e congelam por 2s. Também causa 6–12 a vizinhos. |
| **Peixeira** | Hemorrhage | Onça + Tatu-Bola | 3 acúmulos de Arranhão. Com 12+ acúmulos, consome tudo e tira 20% da vida atual. |
| **Cristo Redentor** | Holy Laser | Pororoca + Cachoeira | De braços abertos: 24–36 de dano em toda a linha **e** coluna. |
| **Boto-Cor-de-Rosa** | Incubus | Iara + Mau-Olhado | 4% de chance de Encantar por 9s. Encantados lançam Mau-olhado nos vizinhos (100–200 após 5 acertos). |
| **Fogueira de São João** | Inferno | Pimenta + Saci | 1 acúmulo de Ardência por segundo em todos num raio de 2 (6s, 3–7 por acúmulo/s). |
| **Farol da Barra** | Laser Beam | Vaga-lume + Pororoca/Cachoeira | Facho de luz de 30–42 de dano que ofusca por 8s. |
| **Piranha** | Leech | Saúva + Onça | Prende uma piranha no inimigo, que aplica 2 acúmulos de Arranhão por segundo (máx. 24). |
| **Para-raios** | Lightning Rod | Trovoada + Tatu-Bola | Crava um para-raios no inimigo: a cada 3s cai um raio de 1–30 em até 8 próximos. |
| **Simpatia de Santo Antônio** | Lovestruck | Iara + Vaga-lume · Iara + Trovoada | Inimigos "apaixonados" por 20s; ao atacar, têm 50% de chance de te curar em 5. |
| **Cupinzeiro** | Maggot | Saúva + Maniva | Infesta o inimigo; ao morrer, ele estoura em 1–2 Bolinhas de Gude. |
| **Mula Sem Cabeça** | Magma | Pimenta + Zabumba | Deixa rastro de fogo: quem pisa sofre 15–30 e ganha Ardência. Também causa 6–12 a vizinhos. |
| **Muriçoca Rainha** | Mosquito King | Morcego + Saúva | A cada acerto gera uma muriçoca que ataca um inimigo aleatório (80–120). Se matar, rouba 1 de vida. |
| **Nuvem de Muriçoca** | Mosquito Swarm | Morcego + Pipoca | Estoura em 3–6 muriçocas (80–120 cada, roubam vida ao matar). |
| **Fumacê** | Noxious | Jararaca + Saci · Mau-Olhado + Saci | O carro do fumacê passou: atravessa e aplica 3 acúmulos de Peçonha num raio de 2. |
| **Rojão Atômico** | Nuclear Bomb | Bomba de São João + Jararaca | 300–500 de dano em área e 1 acúmulo permanente de Zica em todos (máx. 5). Recarga de 3s. |
| **Mata Atlântica** | Overgrowth | Zabumba + Maniva | 1 acúmulo de cipó; ao chegar a 3, a mata fecha: 150–200 de dano em área 3x3. |
| **Pisadeira** | Phantom | Mau-Olhado + Corpo-Seco | Lança Mau-olhado: o inimigo sofre 100–200 após ser atingido 5 vezes. |
| **Raio de Angra** | Radiation Beam | Pororoca/Cachoeira + Jararaca/Maniva | Feixe de 24–48 que aplica Zica (máx. 5, dura 15s). |
| **Lobisomem** | Sacrifice | Onça + Mau-Olhado | Sétimo filho em noite de lua cheia: 4 acúmulos de Arranhão (máx. 15) + Mau-olhado (50–100 após 5 acertos). |
| **Poeira do Sertão** | Sandstorm | Zabumba + Saci | Atravessa inimigos envolta em poeira: 10–20 de dano por segundo e ofusca vizinhos por 3s. |
| **Anhangá** | Satan | Boto-Cor-de-Rosa + Boiúna | Enquanto ativo, aplica Ardência em todos por segundo (máx. 5, 10–20 por acúmulo/s) e os deixa "esquentados". |
| **Bodoque** | Shotgun | Tatu-Bola + Pipoca | Ao bater na parede, dispara 3–7 bolinhas de ferro a 200% de velocidade, que somem ao acertar algo. |
| **Chupa-Cabra** | Soul Sucker | Morcego + Corpo-Seco | Atravessa e suga: 30% de chance de roubar 1 de vida e reduzir o ataque do inimigo em 20% (1 vez por inimigo). |
| **Armadeira Rainha** | Spider Queen | Saúva + Pipoca | 25% de chance de gerar uma Pipoca a cada acerto. |
| **Temporal de Verão** | Storm | Trovoada + Saci | Solta raios de 1–40 nos inimigos próximos a cada segundo. |
| **Boiúna** | Succubus | Iara + Morcego | A Cobra Grande: 4% de chance de Encantar por 9s; cura 1 ao acertar um encantado. |
| **Sol do Sertão** | Sun | Pimenta + Vaga-lume | Ofusca todos na tela e aplica 1 acúmulo de Ardência por segundo (máx. 5, 6–12 por acúmulo/s). |
| **Mangue** | Swamp | Jararaca + Zabumba | Deixa poças de lama: 15–30 de dano, lentidão de 50% por 7s e Peçonha (máx. 8). |
| **Barão Morcego** | Vampire Lord | Morcego + Onça · Morcego + Mau-Olhado | 3 acúmulos de Arranhão; ao acertar um inimigo com 10+ acúmulos, consome tudo e cura 1. |
| **Virose** | Virus | Jararaca + Corpo-Seco · Jararaca + Maniva | Aplica Virose (máx. 8, 6s, 3–6 por acúmulo/s); 15% de chance por segundo de passar para os vizinhos. |
| **Saco de Pipoca Família** | Voluptuous Egg Sac | Pipoca + Maniva | Estoura em 2–3 Pipocas. Recarga de 3s. |
| **Neblina da Serra** | Wraith | Geada + Corpo-Seco | Congela por 0,8s todo inimigo que atravessa. |
| **Noite de Lua Cheia** ⭐ | Nosferatu | Barão Morcego + Armadeira Rainha + Muriçoca Rainha | A cada quique solta um morcego (132–176 de dano) que vira um Barão Morcego. |

---

## 4. Bolas pós-lançamento (receitas extras)

| Nome | Referência | Receita | Descrição |
|---|---|---|---|
| **Boitatá** | Banished Flame | Mau-Olhado + Pimenta | Cobra de fogo: Fogo-Fátuo por 2s (máx. 6), 1–30 por acúmulo/s; ao apagar, causa 1–100. |
| **Procissão das Almas** | Banshee | Pisadeira + Neblina da Serra | Ao ser lançada, lança Mau-olhado em todos (150–300 após 6 acertos). |
| **Fogo de Monturo** | Brimstone | Pimenta + Paralelepípedo/Jararaca | Ardência e Peçonha por segundo num raio de 2 (máx. 4). |
| **Pedrada** | Catapult | Paralelepípedo + Pipoca | Lança 3–5 pedrinhas a cada 1,5s, que somem ao acertar algo. |
| **Água Mole** | Erosion | Cuca + Saci | "Tanto bate até que fura": atravessa e causa +3% da vida atual do inimigo. |
| **Réveillon de Copacabana** | Fireworks | Pimenta + Pipoca | Estoura em 3–6 fogos que buscam alvos (20–30 de dano + Ardência). |
| **Saudade** | Heart Swallower | Onça + Corpo-Seco | Aperta o coração: 40% de chance de roubar 1 de vida e reduzir o ataque em 20%. |
| **Ladeira Abaixo** | Landslide | Paralelepípedo + Zabumba | Desce a ladeira e some: 20–30 de dano por segundo num raio de 2 por 5s. |
| **Esmerilhadeira** | Laser Cutter | Trilho do Bonde + Pororoca/Cachoeira | Emite faísca contínua à frente: 100–150 de dano por segundo. |
| **Velha da Foice** | Reaper | Chupa-Cabra + Saudade | 10% de chance de matar no impacto e curar 5. |
| **Bodoque de Mira** | Sniper | Bodoque + Curupira | Perfura e, ao bater na parede, solta 3–7 bolinhas perfurantes. |
| **Trilho do Bonde** | Steel | Tatu-Bola + Paralelepípedo | Começa com dano dobrado e 50% mais lenta; ganha +10% de dano por acerto (máx. 300%). |
| **Bomba-Relógio Junina** | Time Bomb | Cuca + Bomba de São João | Joga uma bomba a cada poucos segundos que explode com atraso (80–120). |
| **Feriado Nacional** | Timestop | Cuca + Geada | Tudo para por 5s e a bola some. Recarga de 30s. |
| **Coral-Verdadeira** | Venom | Jararaca + Geada | Aplica Peçonha que desacelera (máx. 8, 3–6 por acúmulo/s). |
| **Sumiço** | Warp | Cuca + Vaga-lume | Some e reaparece num ponto aleatório após cada acerto, ganhando +5% de velocidade. |
| **Cruzeiro do Sul** | X Ray | Cristo Redentor + Farol da Barra | Dispara um raio em forma de X (50–75 de dano + Zica). |

---

## 5. Ideias novas (sem equivalente no jogo de referência)

| Nome | Tipo | Descrição | Possíveis receitas |
|---|---|---|---|
| **Bola de Futebol** | Base | **Drible:** 20% de chance de desviar do inimigo atingido e seguir para o próximo, acumulando +15% de dano por drible. | + Saci → **Pedalada** (dribla e desacelera) · + Tatu-Bola → **Chute de Bico** |
| **Capoeira** | Base | **Ginga:** muda levemente de ângulo a cada quique, buscando o inimigo mais próximo. | + Zabumba → **Meia-Lua de Compasso** (golpe em arco) |
| **Berimbau** | Base | A cada 4 acertos, toca um "toque" que dá +10% de velocidade a todas as bolas por 5s. | + Capoeira → **Roda de Capoeira** (aura que acelera bolas próximas) |
| **Frevo** | Base | Sombrinha: rebate projéteis inimigos que estiverem no caminho. | + Saci → **Galo da Madrugada** (gera um tornado de sombrinhas) |
| **Açaí** | Base | A cada 10 acertos, cura 2 de vida. Sustentação lenta e constante. | + Morcego → **Açaí com Guaraná** (cura e acelera) |
| **Carnaval** | Evolução | Bola de Futebol + Pipoca + Berimbau | Bloco de rua: gera 1 Bolinha de Gude a cada quique enquanto o Berimbau está ativo. |
| **Mapinguari** ⭐ | Evolução lendária | Lobisomem + Mata Atlântica + Curupira | Guardião da floresta: o fedor causa Ofuscado + Peçonha em toda a tela e cada acerto derruba árvores (dano em área 3x3). |

---

## 6. Sugestões de personagens

| Personagem | Bola inicial | Atributo-chave | Gancho |
|---|---|---|---|
| O Vaqueiro | Onça-Pintada | Força | Sangramento em pilha |
| A Baiana do Acarajé | Pimenta Malagueta | Dano ao longo do tempo | Build de Ardência |
| O Gaúcho | Geada | Controle | Congela e quebra |
| A Benzedeira | Mau-Olhado | Risco/recompensa | Começa com pouca vida e muito dano |
| O Pipoqueiro | Pipoca | Malandragem | Exército de Bolinhas de Gude |
| O Moleque de Rua | Saci | Agilidade | Bolas atravessam, mas causam menos dano |
| O Calceteiro | Paralelepípedo | Peso | Começa **sem** Bolinhas de Gude (como The Makeshift Sisyphus) |

---

## 7. Notas de design

- **Legibilidade visual:** cada bola precisa de uma cor e uma silhueta fáceis de reconhecer (ex.: Onça = amarelo com pintas, Geada = azul-claro, Jararaca = verde-escuro com escamas, Saci = vermelho com redemoinho).
- **Receitas intuitivas:** prefira combinações que contem uma piada ou uma história (Pimenta + Geada = Caipirinha; Pororoca + Cachoeira = Cristo Redentor). Isso ajuda o jogador a "descobrir" sozinho.
- **Cuidado cultural:** evitei referências a religiões de matriz africana e a tragédias reais (enchentes, deslizamentos com vítimas, acidentes radiológicos). Vale manter essa linha nos próximos conteúdos.
- **Regionalidade:** dá para organizar os mapas por bioma (Amazônia, Sertão, Pampa, Pantanal, Mata Atlântica, Cidade Grande) e fazer cada um oferecer com mais frequência as bolas da sua região.
