class_name BossBase
extends Enemy
## Base dos chefes: cada bioma tem um chefe do folclore (ou da cidade) com padrão próprio.
## O Run conversa com qualquer chefe só por estes métodos.

var run: Node                 # referência ao Run (para atacar, invocar, ler o jogador)
var phase := 1
var intro := true
var arrive_y := 15.0          # linha onde o chefe "pousa" ao entrar


func setup_boss(_info: Dictionary, the_run: Node, hp_value: float) -> void:
	run = the_run
	is_boss = true
	max_hp = hp_value
	hp = max_hp
	xp = 60
	contact_damage = 999.0
	_status = MeshInstance3D.new()
	_status_mat = Models.fade_mat(Color.WHITE, 1.0)
	add_child(_status)
	_status.visible = false
	_label = Label3D.new()
	_label.visible = false
	add_child(_label)


## Lógica por quadro (ataques, fases, movimento).
func boss_update(_delta: float) -> void:
	pass


## Multiplicador de dano conforme o ponto de contato (pontos fracos, atordoamento…).
func damage_multiplier_at(_contact: Vector2) -> float:
	return 1.0


## Para onde a mira automática aponta.
func auto_target_point() -> Vector2:
	return pos


## Inimigos acima desta linha são esmagados quando o chefe chega.
func crush_line() -> float:
	return arrive_y - half.y - 0.8


func sync_visual() -> void:
	position = Vector3(pos.x, 0.0, -pos.y)
