class_name BossArranhaCeu
extends Enemy
## CHEFE DE SÃO PAULO — O Arranha-Céu.
## Teste de VELOCIDADE e PRECISÃO: só as janelas acesas da base (pontos fracos) recebem dano cheio.

const WINDOW_X := [-3.2, -1.6, 0.0, 1.6, 3.2]
const WINDOW_HALF := 0.6

var run: Node                 # referência ao Run (para invocar ataques)
var open_windows: Array = [1, 3]
var phase := 1
var intro := true
var _window_timer := 3.0
var _summon_timer := 6.0
var _shard_timer := 3.0
var _window_nodes: Array = []
var _building: Node3D
var _arrive_y := 13.6


func setup_boss(boss_info: Dictionary, the_run: Node, hp_value: float) -> void:
	run = the_run
	is_boss = true
	id = boss_info["id"]
	data = {"id": id, "nome": boss_info["nome"], "modelo": "arranha_ceu", "cor": "#4a5566", "comportamento": "chefe"}
	behavior = "chefe"
	max_hp = hp_value
	hp = max_hp
	xp = 60
	contact_damage = 999.0
	half = Vector2(4.0, 1.4)
	pos = Vector2(0, 26.0)
	_build_boss_visual()
	sync_visual()


func _build_boss_visual() -> void:
	_building = Models.build_skyscraper()
	_building.position = Vector3(0, 0, 0)
	add_child(_building)
	_model = _building
	# Janelas-ponto-fraco na base da fachada (voltadas para o jogador).
	for i in WINDOW_X.size():
		var w := Models.box(self, Vector3(1.2, 0.9, 0.12), Color("#ffd27a"), Vector3(WINDOW_X[i], 0.75, 1.58), 4.0, false)
		_window_nodes.append(w)
	_status = MeshInstance3D.new()
	_status_mat = Models.fade_mat(Color.WHITE, 1.0)
	add_child(_status)
	_status.visible = false
	_label = Label3D.new()
	_label.visible = false
	add_child(_label)
	_refresh_windows()


func sync_visual() -> void:
	position = Vector3(pos.x, 0.0, -pos.y)


func animate(delta: float) -> void:
	_anim += delta
	_punch = maxf(0.0, _punch - delta * 6.0)
	_building.position.x = sin(_anim * 40.0) * 0.06 * _punch
	var lamp := _building.get_node_or_null("Luz")
	if lamp:
		lamp.visible = fmod(_anim, 1.0) < 0.5
	for side in ["BracoE", "BracoD"]:
		var arm := _building.get_node_or_null(side)
		if arm:
			arm.rotation.x = sin(_anim * (1.2 if phase == 1 else 2.4) + (0.0 if side == "BracoE" else PI)) * 0.35


## Chamado pelo Run a cada frame. Retorna true enquanto está na entrada (intro).
func boss_update(delta: float) -> void:
	if intro:
		pos.y = move_toward(pos.y, _arrive_y, delta * 4.0)
		sync_visual()
		if is_equal_approx(pos.y, _arrive_y):
			intro = false
		return
	if phase == 1 and hp < max_hp * 0.5:
		phase = 2
		run.on_boss_phase(2)
	var speed_mult := 1.0 if phase == 1 else 1.6
	pos.y = maxf(pos.y - delta * 0.05 * move_factor(), 10.0)
	sync_visual()
	_window_timer -= delta * speed_mult
	if _window_timer <= 0.0:
		_window_timer = 2.8
		var options := [0, 1, 2, 3, 4]
		options.shuffle()
		open_windows = options.slice(0, 2 if phase == 1 else 1)
		_refresh_windows()
	_summon_timer -= delta * speed_mult
	if _summon_timer <= 0.0:
		_summon_timer = 9.0
		run.boss_summon(pos.y - half.y - 1.2)
	_shard_timer -= delta * speed_mult
	if _shard_timer <= 0.0:
		_shard_timer = 3.4
		run.boss_glass_rain(3 if phase == 1 else 5)


func _refresh_windows() -> void:
	for i in _window_nodes.size():
		var w: MeshInstance3D = _window_nodes[i]
		var open: bool = open_windows.has(i)
		w.material_override = Models.mat(Color("#ffe14a") if open else Color("#2a3448"), 5.0 if open else 0.0, false)
		w.scale = Vector3(1.0, 1.25 if open else 1.0, 1.0)


## Multiplicador de dano conforme o ponto de contato (precisão!).
func damage_multiplier_at(contact: Vector2) -> float:
	# Só a face de baixo (voltada ao jogador) tem janelas.
	if contact.y > pos.y - half.y + 0.25:
		return 0.35
	for i in open_windows:
		if absf(contact.x - (pos.x + WINDOW_X[i])) <= WINDOW_HALF:
			return 2.5
	return 0.5
