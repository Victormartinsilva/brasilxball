# Grota Funda — Documento de Game Design

Oct 5, 2026 · @Victor e Isa

## Visão geral

Grota Funda é um roguelite de ação em que o jogador chuta bolas que ricocheteiam sozinhas por um campo vertical para deter assombrações do folclore antes que cheguem à vila. Nome provisório.

| Item | Definição |
| --- | --- |
| Gênero | Quebra-blocos + roguelite de sobrevivência |
| Tema | Folclore e biomas brasileiros, futebol de várzea, cultura popular |
| Sessão | Uma descida por partida, 10 a 20 min |
| Orientação | Tela vertical (retrato) |
| Referência de gênero | Ball x Pit (Kenny Sun, 2025) |

**Premissa:** a bola sagrada da vila caiu na Grota Funda, uma fenda encantada que atravessa os biomas do Brasil. O herói desce, enfrenta os seres que guardam cada bioma e volta com recursos para reconstruir a comunidade. Morrer não é fim: cada descida deixa a vila mais forte.

**Pilares de design:**

1. **A física faz o trabalho, o jogador faz a escolha.** O chute é automático; a habilidade está no ângulo e na posição.
2. **Tabelinha é dano.** Ricochetes em cadeia são o principal multiplicador do jogo.
3. **Cada partida é uma combinação nova.** Bolas, misturas e passivas mudam o estilo de jogo.
4. **Brasilidade no sistema, não só na arte.** Os nomes das mecânicas vêm da cultura popular (tabelinha, matar no peito, mutirão, patuá).

## Campo de jogo

O campo é um corredor vertical com câmera fixa: inimigos descem do topo, o jogador defende a faixa de baixo e três lados rebatem as bolas.

| Zona | Posição (% da altura, de cima) | Função |
| --- | --- | --- |
| Teto | 0% | Rebate bolas; inimigos surgem logo abaixo |
| Área de avanço | 0–75% | Inimigos descem em fileiras; onde as tabelinhas acontecem |
| Faixa de defesa | 75–95% | Onde o personagem anda (livre em X e Y dentro da faixa) |
| Linha da vila | 95–100% | Bola que toca aqui volta para a bolsa; inimigo que toca causa dano |
| Paredes laterais | Bordas | Rebatem bolas; alguns biomas têm obstáculos fixos |

**Regras do campo:**

- A câmera não se move; a "descida" é representada pela troca de cenário entre ondas.
- Uma fase tem ondas de inimigos e termina com um chefe.
- Os biomas mudam o fundo, os inimigos e um modificador de campo. Exemplos: Pantanal com poças que desaceleram bolas; Caatinga com cactos que rebatem em ângulo aleatório.
- Ordem dos biomas: Mata Atlântica, Cerrado, Caatinga, Pantanal, Pampa, Amazônia.
