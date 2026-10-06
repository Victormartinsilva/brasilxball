class_name Run
extends Node3D
## Uma run completa. REGRA TÉCNICA: 2.5D visualmente, 2D mecanicamente.
## Toda a física acontece em Vector2 (x = horizontal, y = profundidade da arena).
## O Node3D de cada entidade só espelha a posição: Vector3(x, altura, -y).

signal finished(result: Dictionary)

const ARENA_W := 6.0
const TOP := 18.0
const SPAWN_Y := 17.4
const COLS := 11
const ENEMY_LINE := 0.9
const MAX_BALLS := 150
const KICK_INTERVAL := 0.22   # intervalo entre chutes com a bolsa cheia
const CATCH_RADIUS := 0.9     # "matar no peito"
const BABY_ID := "__gude"      # bolinhas de gude da Torcida (dentes-de-leite)
const COMBO_TIERS := [[100, "FRENESI", 1.5, 40], [50, "x4", 1.3, 20], [25, "x3", 1.2, 10], [10, "x2", 1.1, 5]]
const REACTIONS := {
	"fogo+gelo": {"nome": "VAPOR", "cor": "#ffd0f0"},
	"fogo+raio": {"nome": "PLASMA", "cor": "#ff5af0"},
	"raio+veneno": {"nome": "NEUROTÓXICA", "cor": "#b4ff3a"},
	"gelo+raio": {"nome": "SOBRECARGA", "cor": "#7fe3ff"},
	"fogo+veneno": {"nome": "COMBUSTÃO", "cor": "#ff9f2e"},
	"gelo+veneno": {"nome": "CRISTAL TÓXICO", "cor": "#5fe0a0"},
}

var region: Dictionary
var character: Dictionary
var build: RunBuild
var rng := RandomNumberGenerator.new()
var autoplay := false   # usado pelos testes automatizados

var player: Player
var camera: Camera3D
var fx: FxLayer
var diorama: Node3D
var hud: Hud
var levelup: LevelUpUI
var balls_root: Node3D
var enemies_root: Node3D
var misc_root: Node3D

var balls: Array = []
var enemies: Array = []
var gems: Array = []         # {node, pos, value}
var projectiles: Array = []  # {node, pos, vel, dmg}
var shards: Array = []       # {warn, pos, timer}
var fields: Array = []       # {node, pos, radius, timer, dps, freeze, tick}
var cars: Array = []         # {node, pos, half, vel}
var boss: BossArranhaCeu

var time := 0.0
var hp := 100.0
var max_hp := 100.0
var level := 1
var xp := 0.0
var xp_next := 10.0
var kills := 0
var combo := 0
var combo_timer := 0.0
var best_combo := 0
var combo_tier_reached := 0
var sucata_run := 0
var pending_levelups := 0
var ability_cd := 0.0
var ability_time := 0.0
var boss_spawned := false
var game_over := false
var feira_done: Array = []
var traffic_timer := 6.0
var multiplicacao_count := 0
var reactions_count := 0
var descobertas: Array = []
var damage_log: Dictionary = {}   # métricas de balanceamento
var damage_taken: Dictionary = {}
var boss_time := 0.0
var _tiers_paid: Array = []
var auto_aim := true
var aim_point := Vector2(0, 10)
var mouse_held := false
var touch_mode := false
var _touch_start_ground := Vector2.ZERO
var _touch_start_player := Vector2.ZERO

var _row_progress := 0.0
var _shake := 0.0
var _cam_base: Transform3D
var _cam_offset := Vector3.ZERO
var _cam_offset_target := Vector3.ZERO
var _rajada_queue := 0
var _rajada_timer := 0.0
var _gem_mesh: Mesh
var _acai_hits := 0
var leapers: Array = []      # tropas que chegaram ao fim e estão pulando no jogador

# Bolsa: as bolas são LIMITADAS. Só voltam quando descem até a linha de baixo ou são pegas no peito.
var bag: Array = []
var auto_kick := true
var kick_timer := 0.0
var catches := 0
var rerolls_paid := 0
var babies := 0              # Bolinhas de Gude ganhas (1 por nível): o arsenal só cresce


func setup(char_id: String, region_id: String) -> void:
	character = GameData.characters[char_id]
	region = GameData.regions[region_id]


func _ready() -> void:
	rng.randomize()
	touch_mode = GameData.is_mobile()
	build = RunBuild.new(character)
	max_hp = float(character["vida"]) + build.max_hp_bonus()
	hp = max_hp
	xp_next = _xp_needed(1)

	diorama = DioramaSaoPaulo.new()
	add_child(diorama)
	misc_root = Node3D.new()
	add_child(misc_root)
	enemies_root = Node3D.new()
	add_child(enemies_root)
	balls_root = Node3D.new()
	add_child(balls_root)
	fx = FxLayer.new()
	add_child(fx)

	player = Player.new()
	add_child(player)
	player.setup(character)

	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()

	var gm := PrismMesh.new()
	gm.size = Vector3(0.26, 0.34, 0.26)
	_gem_mesh = gm

	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	levelup = LevelUpUI.new()
	add_child(levelup)
	levelup.chosen.connect(_on_offer_chosen)

	_sync_bag()
	for i in 4:
		_spawn_row(SPAWN_Y - i * 1.0, 0.0)
	hud.banner(region["nome"].to_upper(), region.get("subtitulo", ""), 2.5)


func _on_resize() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.y <= 0:
		return
	if vp.x / vp.y < 0.9:
		# Retrato (celular): câmera mais vertical para a arena ocupar a tela.
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = 50.0
		camera.position = Vector3(0, 18.5, 2.6)
		camera.look_at(Vector3(0, 0, -7.9), Vector3.UP)
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = 42.0
		camera.position = Vector3(0, 16.0, 7.4)
		camera.look_at(Vector3(0, 0, -7.6), Vector3.UP)
	_cam_base = camera.transform


# =================================================================== LOOP

func _process(delta: float) -> void:
	if game_over:
		return
	time += delta
	_update_aim(delta)
	_update_spawning(delta)
	_update_traffic(delta)
	_update_fields(delta)
	_fire(delta)
	_update_balls(delta)
	_update_enemies(delta)
	_update_leapers(delta)
	_update_projectiles(delta)
	_update_shards(delta)
	_update_gems(delta)
	_update_combo(delta)
	_update_ability(delta)
	_update_camera(delta)
	_cleanup()
	_check_events()
	if pending_levelups > 0 and not levelup.is_open() and not game_over:
		_open_levelup()


func _unhandled_input(event: InputEvent) -> void:
	# ---- Toque (celular): arrastar em qualquer lugar move o personagem de forma relativa,
	# assim o dedo não cobre o boneco. A mira fica automática (ou segue o dedo em "Mira LIVRE").
	if event is InputEventScreenTouch:
		touch_mode = true
		if event.index == 0:
			if event.pressed:
				_touch_start_ground = _screen_to_ground(event.position)
				_touch_start_player = player.pos
				player.target_x = player.pos.x
				player.target_y = player.pos.y
				player.use_target = true
			else:
				player.use_target = false
		return
	if event is InputEventScreenDrag:
		touch_mode = true
		if event.index == 0:
			var g := _screen_to_ground(event.position)
			var t := _touch_start_player + (g - _touch_start_ground) * 1.35
			player.target_x = clampf(t.x, -Player.LIMIT, Player.LIMIT)
			player.target_y = clampf(t.y, Player.Y, Player.Y_MAX)
			player.use_target = true
			if not auto_aim:
				aim_point = g
		return
	if touch_mode and (event is InputEventMouseMotion or event is InputEventMouseButton):
		return  # eventos de mouse emulados a partir do toque
	if event is InputEventMouseMotion:
		auto_aim = false
		aim_point = _screen_to_ground(event.position)
		if mouse_held:
			player.target_x = aim_point.x
			player.target_y = clampf(aim_point.y, Player.Y, Player.Y_MAX)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_held = event.pressed
		player.use_target = event.pressed
		auto_aim = false
		aim_point = _screen_to_ground(event.position)
		player.target_x = aim_point.x
		player.target_y = clampf(aim_point.y, Player.Y, Player.Y_MAX)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_T:
		auto_aim = not auto_aim
		hud.toast("Mira automática: " + ("LIGADA" if auto_aim else "DESLIGADA"))
	if event.is_action_pressed("ability") or event.is_action_pressed("ability_mouse"):
		use_ability()
	if event.is_action_pressed("pause") and not levelup.is_open():
		hud.toggle_pause()
	if event.is_action_pressed("speed_toggle"):
		hud.cycle_speed()
	if event.is_action_pressed("kick_toggle"):
		toggle_kick()


func _screen_to_ground(sp: Vector2) -> Vector2:
	var from := camera.project_ray_origin(sp)
	var dir := camera.project_ray_normal(sp)
	if absf(dir.y) < 0.0001:
		return aim_point
	var t := (0.45 - from.y) / dir.y
	var hit := from + dir * t
	return Vector2(hit.x, -hit.z)


func _update_aim(delta: float) -> void:
	var axis := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_down", "move_up"))
	if autoplay:
		axis = _autoplay_axis()
	# Chutar deixa o personagem mais lento — às vezes vale parar de chutar para correr.
	player.speed_mult = 0.6 if (auto_kick and bag.size() > 0 and character["id"] != "cacadora") else 1.0
	player.move(axis, delta)
	var target := aim_point
	if auto_aim or autoplay:
		target = _auto_target()
	var d := target - (player.pos + Vector2(0, 0.6))
	if d.length() < 0.1:
		d = Vector2.UP
	d = d.normalized()
	if d.y < 0.22:
		d.y = 0.22
		d = d.normalized()
	player.aim_dir = d
	player.animate(delta)


func _auto_target() -> Vector2:
	# Mira no inimigo mais próximo da base (a maior ameaça); chefe tem prioridade nas janelas.
	if boss and not boss.dead and not boss.intro and boss.open_windows.size() > 0:
		var wx: float = BossArranhaCeu.WINDOW_X[boss.open_windows[0]]
		return Vector2(boss.pos.x + wx, boss.pos.y - boss.half.y)
	var best: Enemy = null
	for e: Enemy in enemies:
		if e.dead:
			continue
		if best == null or e.pos.y < best.pos.y:
			best = e
	if best:
		return best.pos
	return Vector2(player.pos.x, 10)


func _autoplay_axis() -> Vector2:
	# IA simples para testes: foge de estilhaços, tenta matar no peito, senão encara a ameaça.
	for s in shards:
		if absf(s["pos"].x - player.pos.x) < 1.2:
			return Vector2(1.0 if s["pos"].x < player.pos.x else -1.0, 0)
	for b: Ball in balls:
		if b.bag_id != "" and not b.dead and b.dir.y < 0.0 and b.pos.y < 4.0:
			return (b.pos - player.pos).normalized()
	var goal := 0.0
	var best_y := 999.0
	for e: Enemy in enemies:
		if not e.dead and e.pos.y < best_y:
			best_y = e.pos.y
			goal = e.pos.x
	return Vector2(clampf((goal - player.pos.x) * 0.5, -1.0, 1.0), -1.0)


# =================================================================== SPAWN

func difficulty() -> float:
	return clampf(time / float(region["tempo_chefe"]), 0.0, 1.0)


func _descend_speed() -> float:
	var v: Array = region["velocidade_descida"]
	var s := lerpf(v[0], v[1], difficulty())
	if boss_spawned:
		s *= 0.5
	return s


func _hp_scale() -> float:
	var e: Array = region["escala_hp"]
	var s := lerpf(e[0], e[1], difficulty())
	if time > float(region["tempo_chefe"]):
		s *= 1.0 + (time - float(region["tempo_chefe"])) / 90.0
	return s


func _current_pool() -> Dictionary:
	var pool: Dictionary = {}
	for f in region["fases"]:
		if time >= float(f["t"]):
			pool = f["pool"]
	return pool


func _pick_weighted(pool: Dictionary, max_width := 99) -> String:
	var total := 0.0
	for k in pool:
		if int(GameData.enemies[k].get("largura", 1)) <= max_width:
			total += float(pool[k])
	var r := rng.randf() * total
	for k in pool:
		if int(GameData.enemies[k].get("largura", 1)) > max_width:
			continue
		r -= float(pool[k])
		if r <= 0.0:
			return k
	return "pombo"


func _update_spawning(delta: float) -> void:
	_row_progress += _descend_speed() * delta
	if _row_progress >= 1.0:
		_row_progress -= 1.0
		_advance_step()  # as tropas continuam andando durante o chefe
		if not boss_spawned:
			_spawn_row(SPAWN_Y, difficulty())
	if not boss_spawned and time >= float(region["tempo_chefe"]):
		_start_boss()


## As tropas andam pela GRADE: todas pulam uma casa para frente ao mesmo tempo.
## Quem estiver bloqueado (inimigo parado na casa da frente) espera; lentos andam um passo sim, outro não.
func _advance_step() -> void:
	var order: Array = enemies.filter(func(x): return not x.dead and not x.is_boss)
	order.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for e: Enemy in order:
		if e.frozen_time > 0.0 or e.gravity_slow > 0.5:
			continue
		if e.chill_time > 0.0 or e.slow_time > 0.0:
			e.skip_step = not e.skip_step
			if e.skip_step:
				continue
		var target := e.hop_to - 1.0 if e.hop_t < 1.0 else e.pos.y - 1.0
		var blocked := false
		for o: Enemy in order:
			if o == e or o.dead:
				continue
			var oy := o.hop_to if o.hop_t < 1.0 else o.pos.y
			if absf(o.pos.x - e.pos.x) < o.half.x + e.half.x - 0.05 and absf(oy - target) < 0.5:
				blocked = true
				break
		if blocked:
			continue
		e.hop_from = e.pos.y
		e.hop_to = target
		e.hop_t = 0.0


func _spawn_row(y: float, d: float, pool_override: Dictionary = {}) -> void:
	var p: Array = region["preenchimento"]
	var fill := lerpf(p[0], p[1], d)
	var pool := pool_override if not pool_override.is_empty() else _current_pool()
	var col := 0
	while col < COLS:
		if rng.randf() > fill:
			col += 1
			continue
		var eid := _pick_weighted(pool, COLS - col)
		var w := int(GameData.enemies[eid].get("largura", 1))
		var cx := -5.0 + col + (w - 1) * 0.5
		if _occupied(Vector2(cx, y), w * 0.5):
			col += w
			continue
		var elite := time > 90.0 and rng.randf() < float(region["chance_elite"])
		spawn_enemy(eid, Vector2(cx, y), elite)
		col += w


func _occupied(at: Vector2, half_w: float) -> bool:
	for e: Enemy in enemies:
		if e.dead:
			continue
		if absf(e.pos.x - at.x) < e.half.x + half_w - 0.1 and absf(e.pos.y - at.y) < e.half.y + 0.5:
			return true
	return false


func spawn_enemy(eid: String, at: Vector2, elite := false) -> Enemy:
	var e := Enemy.new()
	enemies_root.add_child(e)
	e.setup(GameData.enemies[eid], at, _hp_scale(), elite)
	enemies.append(e)
	return e


# =================================================================== DISPARO

func _fire(delta: float) -> void:
	kick_timer -= delta
	if auto_kick and kick_timer <= 0.0 and bag.size() > 0 and balls.size() < MAX_BALLS:
		kick_timer = KICK_INTERVAL / build.fire_rate_mult()
		var id: String = bag.pop_front()
		var b := spawn_ball(_bag_stats(id), player.pos + Vector2(0, 0.5), player.aim_dir.rotated(rng.randf_range(-0.03, 0.03)))
		if b:
			b.bag_id = id
		else:
			bag.push_front(id)
	if _rajada_queue > 0:
		_rajada_timer -= delta
		if _rajada_timer <= 0.0:
			_rajada_timer = 1.2 / 14.0
			var i := 14 - _rajada_queue
			_rajada_queue -= 1
			var stats := build.ball_stats(build.slots[0]["id"], build.slots[0]["level"])
			stats["tamanho"] *= 0.7
			stats["dano"] *= 0.6
			stats["ricochetes"] = 3
			var ang := lerpf(-0.6, 0.6, i / 13.0)
			spawn_ball(stats, player.pos + Vector2(0, 0.6), player.aim_dir.rotated(ang))


## Stats da bola que sai da bolsa (bola especial do slot ou bolinha de gude da Torcida).
func _bag_stats(id: String) -> Dictionary:
	if id == BABY_ID:
		var s := build.ball_stats("pedra", 1)
		s["nome"] = "Bolinha de Gude"
		s["tamanho"] *= 0.72
		s["dano"] *= 0.4 + 0.04 * float(character.get("torcida", 4))  # Torcida fortalece as bolinhas
		s["cor"] = Color("#9fd8ff")
		return s
	var i := build.slot_index(id)
	return build.ball_stats(id, int(build.slots[i]["level"]) if i >= 0 else 1)


## Reconcilia a bolsa com a build: novas bolas entram, bolas fundidas saem.
func _sync_bag() -> void:
	var desired := {BABY_ID: babies}
	for s in build.slots:
		desired[s["id"]] = int(build.ball_stats(s["id"], s["level"])["quantidade"])
	var owned := {}
	for id in bag:
		owned[id] = int(owned.get(id, 0)) + 1
	for b: Ball in balls:
		if b.bag_id != "" and not b.dead:
			owned[b.bag_id] = int(owned.get(b.bag_id, 0)) + 1
	for id in owned:
		var extra: int = int(owned[id]) - int(desired.get(id, 0))
		while extra > 0 and bag.has(id):
			bag.erase(id)
			extra -= 1
		for b: Ball in balls:
			if extra <= 0:
				break
			if b.bag_id == id:
				b.bag_id = ""  # vira temporária e some quando descer
				extra -= 1
	for id in desired:
		for k in int(desired[id]) - int(owned.get(id, 0)):
			bag.push_front(id)  # bola nova sai no próximo chute


func bag_total() -> int:
	var n := bag.size()
	for b: Ball in balls:
		if b.bag_id != "" and not b.dead:
			n += 1
	return n


func toggle_kick() -> void:
	auto_kick = not auto_kick
	hud.toast("Chute automático " + ("LIGADO" if auto_kick else "DESLIGADO — correndo mais rápido"))


func reroll_cost() -> int:
	return 5 * (rerolls_paid + 1)


func spawn_ball(stats: Dictionary, at: Vector2, dir: Vector2, clone := false) -> Ball:
	if balls.size() >= MAX_BALLS:
		return null
	var b := Ball.new()
	balls_root.add_child(b)
	b.setup(stats, at, dir)
	b.is_clone = clone
	if clone:
		b.lifetime = 3.0
	balls.append(b)
	return b


# =================================================================== BOLAS

func _update_balls(delta: float) -> void:
	var smult := build.ball_speed_mult()
	var i := 0
	while i < balls.size():
		var b: Ball = balls[i]
		if not b.dead:
			_step_ball(b, delta, smult)
		if not b.dead:
			b.visual_update(delta)
		i += 1


func _step_ball(b: Ball, delta: float, smult: float) -> void:
	b.age += delta
	b.spawn_cd -= delta
	if b.rolling:
		var home := player.pos + Vector2(0, -0.1)
		var to_home := home - b.pos
		var step := 12.0 * delta
		if to_home.length() <= maxf(step, 0.45):
			_ball_returned(b)
		else:
			b.pos += to_home.normalized() * step
		return
	if b.attached != null:
		_update_parasite(b, delta)
		return
	if b.age > b.lifetime and not b.returning:
		if b.bag_id == "":
			b.dead = true
			return
		_start_return(b, false)
	for f in fields:
		var to_c: Vector2 = f["pos"] - b.pos
		var dist := to_c.length()
		if dist < f["radius"] and dist > 0.2 and not b.returning:
			b.dir = (b.dir + to_c / dist * delta * 2.2).normalized()
	var spd := b.speed * smult
	if b.returning and b.behavior != "bumerangue":
		spd *= 1.5
	var total := spd * delta
	var steps := maxi(1, ceili(total / 0.16))
	var step_len := total / steps
	for s in steps:
		if b.returning:
			var home := Vector2(player.pos.x, -1.0)
			b.dir = b.dir.lerp((home - b.pos).normalized(), 0.25).normalized()
		b.pos += b.dir * step_len
		_ball_walls(b)
		if b.dead:
			return
		# Matar no peito: pegar a bola descendo antes de cair = recarga imediata.
		if b.bag_id != "" and b.dir.y < 0.0 and b.age > 0.35 and b.pos.y < player.pos.y + 1.3 \
				and b.pos.distance_to(player.pos + Vector2(0, 0.4)) < CATCH_RADIUS:
			catches += 1
			fx.sparks(b.pos, Color("#fff3c4"), 5, 3.0)
			if catches % 6 == 1:
				fx.text(player.pos + Vector2(0, 1.4), "MATOU NO PEITO!", Color("#5fe0a0"), 0.006)
			_ball_returned(b)
			return
		if b.returning:
			if b.behavior == "bumerangue":
				_ball_enemies(b, true)
			continue
		_ball_cars(b)
		_ball_enemies(b, false)
		if b.dead or b.attached != null:
			return


func _ball_walls(b: Ball) -> void:
	if b.pos.x < -ARENA_W + b.radius:
		b.pos.x = -ARENA_W + b.radius
		b.dir.x = absf(b.dir.x)
		_on_bounce(b)
	elif b.pos.x > ARENA_W - b.radius:
		b.pos.x = ARENA_W - b.radius
		b.dir.x = -absf(b.dir.x)
		_on_bounce(b)
	if b.pos.y > TOP - b.radius:
		b.pos.y = TOP - b.radius
		b.dir.y = -absf(b.dir.y)
		_on_bounce(b)
		if b.behavior == "bumerangue" and not b.returning:
			b.hit_ids.clear()
			_start_return(b, false)
	if b.pos.y < -0.4:
		_ball_hit_ground(b)


func _on_bounce(b: Ball) -> void:
	b.bounces += 1
	if absf(b.dir.y) < 0.2:
		b.dir.y = 0.2 * (1.0 if b.dir.y >= 0.0 else -1.0)
	b.dir = b.dir.rotated(rng.randf_range(-0.035, 0.035)).normalized()


## A bola NÃO volta ao esgotar os ricochetes (ela só volta descendo). "Último Suspiro" explode uma vez.
func _ricochetes_spent(b: Ball) -> void:
	if b.suspiro_done or build.passive("ultimo_suspiro") <= 0:
		return
	b.suspiro_done = true
	aoe(b.pos, 1.3, b.damage * build.pval("ultimo_suspiro") / 100.0, b.color, null, false)


func _start_return(b: Ball, explode := true) -> void:
	if b.returning:
		return
	if explode and build.passive("ultimo_suspiro") > 0:
		aoe(b.pos, 1.3, b.damage * build.pval("ultimo_suspiro") / 100.0, b.color, null, false)
	b.set_returning(true)


func _ball_returned(b: Ball) -> void:
	if b.dead:
		return
	b.dead = true
	if b.bag_id != "":
		bag.append(b.bag_id)


## A bola tocou o fundo: as da bolsa nunca se perdem — rolam pelo chão de volta até o jogador.
func _ball_hit_ground(b: Ball) -> void:
	if b.rolling:
		return
	if b.bag_id == "":
		b.dead = true  # temporárias (clones, rajada, pipoca) somem
	else:
		b.rolling = true
		b.returning = true
		b.pos.y = -0.35
	if character["id"] == "guardiao" and ability_time > 0.0:
		var dmg := 22.0 * build.damage_mult() * (1.0 + level * 0.06)
		fx.column(b.pos.x, 0.5, TOP, Color("#e8b04a"))
		for e: Enemy in enemies:
			if not e.dead and absf(e.pos.x - b.pos.x) < e.half.x + 0.5:
				deal_damage(e, dmg, false, Color("#e8b04a"))
		shake(0.15)


func _ball_cars(b: Ball) -> void:
	for c in cars:
		var cp: Vector2 = c["pos"]
		var ch: Vector2 = c["half"]
		var closest := Vector2(clampf(b.pos.x, cp.x - ch.x, cp.x + ch.x), clampf(b.pos.y, cp.y - ch.y, cp.y + ch.y))
		var diff := b.pos - closest
		if diff.length_squared() > b.radius * b.radius:
			continue
		var n := diff.normalized() if diff.length_squared() > 0.000001 else Vector2(0, -1 if b.dir.y > 0 else 1)
		b.pos = closest + n * (b.radius + 0.02)
		if b.dir.dot(n) < 0.0:
			b.dir = b.dir - 2.0 * b.dir.dot(n) * n
		_on_bounce(b)
		fx.sparks(b.pos, Color("#fff3c4"), 3, 3.0)
		return


func _ball_enemies(b: Ball, passive_only: bool) -> void:
	for e: Enemy in enemies:
		if e.dead:
			continue
		var dx := b.pos.x - e.pos.x
		var dy := b.pos.y - e.pos.y
		if absf(dx) > e.half.x + b.radius or absf(dy) > e.half.y + b.radius:
			continue
		var closest := Vector2(clampf(b.pos.x, e.pos.x - e.half.x, e.pos.x + e.half.x), clampf(b.pos.y, e.pos.y - e.half.y, e.pos.y + e.half.y))
		var diff := b.pos - closest
		var d2 := diff.length_squared()
		if d2 > b.radius * b.radius:
			continue
		var eid := e.get_instance_id()
		var n: Vector2
		if d2 < 0.000001:
			var px := e.half.x + b.radius - absf(dx)
			var py := e.half.y + b.radius - absf(dy)
			if px < py:
				n = Vector2(1.0 if dx >= 0.0 else -1.0, 0.0)
			else:
				n = Vector2(0.0, 1.0 if dy >= 0.0 else -1.0)
		else:
			n = diff / sqrt(d2)

		var ghost := passive_only or b.behavior in ["fantasma", "saci", "fumace"] or b.pierce_left > 0
		if ghost:
			if b.hit_ids.has(eid):
				continue
			b.hit_ids[eid] = true
			ball_hit(b, e, closest)
			if b.dead:
				return
			if passive_only:
				continue
			if b.behavior in ["fantasma", "saci", "fumace"]:
				b.ricochetes_left -= 1
				if b.ricochetes_left <= 0:
					_ricochetes_spent(b)
			else:
				b.pierce_left -= 1
			continue

		if eid == b.last_hit_id and b.age - b.last_hit_time < 0.1:
			b.pos = closest + n * (b.radius + 0.01)
			continue
		b.last_hit_id = eid
		b.last_hit_time = b.age
		var passed := ball_hit(b, e, closest)
		if b.dead:
			return
		if b.behavior == "parasita" and not e.dead and not e.is_boss:
			b.attached = e
			b.attach_timer = 1.4
			b.attach_offset = b.pos - e.pos
			return
		if passed:
			continue
		b.pos = closest + n * (b.radius + 0.01)
		if b.dir.dot(n) < 0.0:
			b.dir = b.dir - 2.0 * b.dir.dot(n) * n
		_on_bounce(b)
		b.ricochetes_left -= 1
		if b.ricochetes_left <= 0:
			_ricochetes_spent(b)
		return


func _update_parasite(b: Ball, delta: float) -> void:
	var host = b.attached
	var alive: bool = is_instance_valid(host) and not host.dead
	if alive:
		b.pos = host.pos + b.attach_offset
		b.attach_timer -= delta
	if not alive or b.attach_timer <= 0.0:
		b.attached = null
		aoe(b.pos, 1.5 + b.level * 0.1, b.damage * 2.5, b.color)
		shake(0.08)
		_start_return(b, false)


# =================================================================== DANO

## Retorna true se a bola deve atravessar (sem quicar).
func ball_hit(b: Ball, e: Enemy, contact: Vector2) -> bool:
	var dmg := b.damage
	if character["id"] == "guardiao":
		dmg *= 1.0 + minf(b.age * 0.2, 1.5)  # Muralha
	if build.passive("ricochete") > 0:
		dmg *= 1.0 + minf(b.bounces * build.pval("ricochete") / 100.0, 0.8)
	if e.behavior == "concreto":
		dmg *= 1.5 if b.tags.has("pesada") else 0.6
	if e.is_boss:
		var m := boss.damage_multiplier_at(contact)
		dmg *= m
		if m > 2.0:
			fx.sparks(contact, Color("#ffe14a"), 8, 5.0)
			if rng.randf() < 0.25:
				fx.text(contact, "PONTO FRACO!", Color("#ffe14a"), 0.006)
	if build.has_relic("olho_cacador"):
		if e.marked:
			dmg *= 2.0
			e.marked = false
		elif not b.marked_first:
			b.marked_first = true
			e.marked = true
	match b.behavior:
		"saci":
			dmg *= 0.75
		"mau_olhado":
			dmg *= 3.0
		"paralelepipedo":
			dmg *= b.stone_mult
			b.stone_mult = maxf(0.5, b.stone_mult * 0.6)
		"futebol":
			dmg *= 1.0 + 0.15 * b.dribbles
	if e.scratch_stacks > 0:
		dmg += e.scratch_stacks * 1.6 * _hp_scale_soft()  # Arranhão: todo golpe dói mais
	b.hits += 1
	var elements: Array = b.elements
	if b.behavior == "espelho":
		if e.last_element != "":
			elements = [e.last_element]
		else:
			dmg *= 1.2
	if character["id"] == "alquimista" and ability_time > 0.0:
		elements = elements.duplicate()
		var all := ["fogo", "gelo", "veneno", "raio"]
		elements.append(all[rng.randi() % all.size()])
	var crit := rng.randf() < b.crit
	var elemental := elements.size() > 0
	fx.sparks(contact, b.color, 3, 3.0)
	deal_damage(e, dmg, crit, b.color, b, elemental)
	if not e.dead or e.is_boss:
		apply_elements(e, elements, dmg, b.level, b)
	match b.behavior:
		"termodinamica":
			if e.chill_time > 0.0 or e.frozen_time > 0.0:
				aoe(e.pos, 1.6, dmg * 1.5, b.color, null, true)
		"gravidade", "singularidade":
			_spawn_field(contact, b)
		"plasma", "neurotoxica":
			pass  # tratados pelo raio
		_:
			if _brazil_behavior(b, e, dmg):
				return true
	if b.behavior == "pesada" and e.dead and not e.is_boss:
		return true
	return false


func _hp_scale_soft() -> float:
	return sqrt(_hp_scale())


## Comportamentos do catálogo brasileiro (docs/GDD-03). Retorna true se a bola deve atravessar.
func _brazil_behavior(b: Ball, e: Enemy, dmg: float) -> bool:
	match b.behavior:
		"onca":
			if not e.dead:
				e.scratch_stacks = mini(e.scratch_stacks + 2, 8)
		"peixeira":
			if not e.dead:
				e.scratch_stacks = mini(e.scratch_stacks + 3, 15)
				if e.scratch_stacks >= 12:
					e.scratch_stacks = 0
					fx.text(e.pos, "PEIXEIRA!", Color("#f3e3c3"), 0.006)
					deal_damage(e, e.hp * (0.05 if e.is_boss else 0.2), true, b.color)
		"pipoca":
			if b.spawn_cd <= 0.0:
				b.spawn_cd = 3.0
				var gude := build.ball_stats("pedra", 1)
				gude["tamanho"] *= 0.7
				gude["dano"] *= 0.6 * (1.0 + 0.25 * (b.level - 1))
				gude["ricochetes"] = 3
				for i in rng.randi_range(2, 4):
					spawn_ball(gude, e.pos + Vector2(0, -0.6), Vector2(rng.randf_range(-1, 1), rng.randf_range(-1.0, -0.2)).normalized(), true)
				fx.sparks(e.pos, Color("#fff3c4"), 8, 4.0)
		"zabumba":
			aoe(e.pos, 1.5, dmg * 0.6, b.color, e, false)
		"pororoca":
			_hit_line(e, true, false, dmg * 0.8, b.color)
		"cachoeira":
			_hit_line(e, false, true, dmg * 0.8, b.color)
		"cristo":
			_hit_line(e, true, true, dmg, b.color)
		"mau_olhado":
			fx.sparks(e.pos, b.color, 10, 5.0)
			_ball_returned(b)  # se desfaz ao acertar e volta direto para a bolsa
		"saci":
			e.slow_time = 5.0
		"fumace":
			fx.ring(e.pos, 2.0, b.color)
			for o: Enemy in enemies:
				if not o.dead and o.pos.distance_to(e.pos) <= 2.0:
					o.poison_stacks = mini(o.poison_stacks + 3, 14)
					o.poison_time = 4.0
					o.poison_dps_per_stack = maxf(o.poison_dps_per_stack, dmg * 0.12)
		"minuano":
			fx.ring(e.pos, 2.0, Color("#cfeeff"))
			for o: Enemy in enemies:
				if not o.dead and not o.is_boss and o.pos.distance_to(e.pos) <= 2.0:
					o.frozen_time = maxf(o.frozen_time, 0.8 + 0.1 * b.level)
		"bomba":
			aoe(e.pos, 2.0, dmg * 2.0, Color("#ff9f2e"), e, true)
			shake(0.12)
		"acai":
			_acai_hits += 1
			if _acai_hits >= 10:
				_acai_hits = 0
				heal(3.0)
				fx.text(player.pos + Vector2(0, 1), "+3", Color("#b46bff"), 0.006)
		"morcego":
			if rng.randf() < 0.05:
				heal(2.0)
				fx.text(player.pos + Vector2(0, 1), "+2", Color("#ff6b8a"), 0.006)
		"futebol":
			if not e.dead and not e.is_boss and rng.randf() < 0.25:
				b.dribbles += 1
				if rng.randf() < 0.4:
					fx.text(e.pos, "DRIBLE!", Color("#f3f3ee"), 0.006)
				return true
	return false


## Pororoca (linha), Cachoeira (coluna) e Cristo Redentor (as duas).
func _hit_line(e: Enemy, row: bool, col: bool, dmg: float, color: Color) -> void:
	if row:
		fx.row(e.pos.y, color)
	if col:
		fx.column(e.pos.x, 0.5, TOP, color)
	for o: Enemy in enemies.duplicate():
		if o == e or o.dead:
			continue
		var in_row := row and absf(o.pos.y - e.pos.y) < 0.55
		var in_col := col and absf(o.pos.x - e.pos.x) < o.half.x + 0.3
		if in_row or in_col:
			deal_damage(o, dmg, false, color)


func deal_damage(e: Enemy, amount: float, crit := false, color := Color(1.0, 0.95, 0.84), source: Ball = null, elemental := false, show := true) -> float:
	if e.dead:
		return 0.0
	var dmg := amount
	if crit:
		dmg *= 2.0
	dmg *= combo_damage_mult()
	if build.passive("furia") > 0:
		dmg *= 1.0 + (1.0 - hp / max_hp) * build.pval("furia") / 100.0
	if build.passive("execucao") > 0 and e.hp_ratio() < 0.25:
		dmg *= 1.0 + build.pval("execucao") / 100.0
	if elemental:
		dmg *= 1.0 + build.alquimia_bonus
	if e.frozen_time > 0.0:
		dmg *= 1.2
	if e.is_boss and source == null:
		dmg *= 0.3  # chefe resiste a dano em área/DOT: o teste dele é PRECISÃO
	if e.armor_hits > 0:
		e.armor_hits -= 1
		dmg *= 0.5
		fx.sparks(e.pos, Color("#c0c6cc"), 4, 3.0)
	e.hp -= dmg
	e.punch()
	var bucket := "chefe" if e.is_boss else "inimigos"
	damage_log[bucket] = float(damage_log.get(bucket, 0.0)) + dmg
	if e.is_boss:
		boss._punch = minf(1.0, boss._punch + 0.15)
	if show:
		fx.number(e.pos + Vector2(0, 0.2), dmg, crit, color.lightened(0.4))
	if e.hp <= 0.0:
		_kill(e, source)
	return dmg


func aoe(center: Vector2, radius: float, dmg: float, color: Color, exclude: Enemy = null, elemental := true) -> void:
	fx.explosion(center, radius, color)
	for e: Enemy in enemies.duplicate():
		if e.dead or e == exclude:
			continue
		var closest := Vector2(clampf(center.x, e.pos.x - e.half.x, e.pos.x + e.half.x), clampf(center.y, e.pos.y - e.half.y, e.pos.y + e.half.y))
		if closest.distance_to(center) <= radius:
			deal_damage(e, dmg, false, color, null, elemental)


func apply_elements(e: Enemy, elements: Array, base_dmg: float, lvl: int, b: Ball = null) -> void:
	for el in elements:
		if el == "gelo" and build.has_relic("coracao_dragao"):
			continue
		if e.dead and not e.is_boss:
			return
		_try_reaction(e, el, base_dmg)
		match el:
			"fogo":
				e.burn_time = 3.0
				e.burn_dps = maxf(e.burn_dps if e.burn_time > 0.0 else 0.0, base_dmg * 0.35)
			"gelo":
				e.chill_time = 2.5
				e.chill_stacks += 1
				if e.chill_stacks >= 3 and not e.is_boss:
					e.chill_stacks = 0
					e.frozen_time = 1.2 + 0.15 * lvl
					fx.sparks(e.pos, Color("#bff4ff"), 6, 3.0)
			"veneno":
				e.poison_stacks = mini(e.poison_stacks + 1, 5 + lvl * 2)
				e.poison_time = 4.0
				e.poison_dps_per_stack = maxf(e.poison_dps_per_stack, base_dmg * 0.12)
			"raio":
				var hops: int = [1, 2, 4, 6, 8][clampi(lvl - 1, 0, 4)]
				if b and b.behavior in ["plasma", "neurotoxica"]:
					hops = 2 + lvl
				chain_lightning(e, hops, base_dmg * 0.7, b)
		e.last_element = el
		e.recent[el] = 3.0


func chain_lightning(from: Enemy, hops: int, dmg: float, b: Ball) -> void:
	var hit: Dictionary = {from.get_instance_id(): true}
	var current := from
	var color: Color = GameData.ELEMENT_COLORS["raio"]
	for i in hops:
		var best: Enemy = null
		var best_d := 3.6
		for e: Enemy in enemies:
			if e.dead or hit.has(e.get_instance_id()):
				continue
			var d := e.pos.distance_to(current.pos)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			return
		hit[best.get_instance_id()] = true
		fx.bolt(current.pos, best.pos, color)
		var from_pos := current.pos
		var poison := current.poison_stacks
		deal_damage(best, dmg, false, color, b, true)
		if b and b.behavior == "plasma":
			aoe(best.pos, 1.0, dmg * 0.6, Color("#ff5af0"), null, true)
			if not best.dead:
				best.burn_time = 3.0
				best.burn_dps = maxf(best.burn_dps, dmg * 0.3)
		elif b and b.behavior == "neurotoxica" and not best.dead:
			best.poison_stacks = mini(best.poison_stacks + maxi(1, poison), 12)
			best.poison_time = 4.0
			best.poison_dps_per_stack = maxf(best.poison_dps_per_stack, dmg * 0.15)
		if best.dead:
			continue
		best.last_element = "raio"
		best.recent["raio"] = 3.0
		current = best
		if from_pos == current.pos:
			return


func _try_reaction(e: Enemy, el: String, base_dmg: float) -> void:
	var chance := 0.0
	if character["id"] == "alquimista":
		chance = 0.6
	if build.has_relic("nucleo_instavel"):
		chance = maxf(chance, 0.25)
	if character["id"] == "alquimista" and ability_time > 0.0:
		chance = 1.0
	if chance <= 0.0:
		return
	for other in e.recent.keys():
		if other == el or float(e.recent[other]) <= 0.0:
			continue
		if rng.randf() > chance:
			return
		e.recent.erase(other)
		_reaction(e, other, el, base_dmg)
		if build.has_relic("nucleo_instavel") and rng.randf() < 0.3:
			_reaction(e, other, el, base_dmg * 0.6)
		return


func _reaction(e: Enemy, a: String, b: String, base: float) -> void:
	var pair := [a, b]
	pair.sort()
	var key := "%s+%s" % pair
	if not REACTIONS.has(key):
		return
	var info: Dictionary = REACTIONS[key]
	var color := Color(info["cor"])
	var mult := 1.0
	if character["id"] == "alquimista" and ability_time > 0.0:
		mult = 1.6
	reactions_count += 1
	if build.passive("alquimia") > 0:
		build.alquimia_bonus = minf(0.6, build.alquimia_bonus + build.pval("alquimia") / 100.0)
	if not descobertas.has("reacao_" + key):
		descobertas.append("reacao_" + key)
	fx.text(e.pos + Vector2(0, 0.6), info["nome"] + "!", color, 0.007)
	var at := e.pos
	match key:
		"fogo+gelo":
			e.chill_time = 0.0
			aoe(at, 1.7, base * 2.0 * mult, color)
		"fogo+raio":
			aoe(at, 2.1, base * 1.6 * mult, color)
			shake(0.06)
		"raio+veneno":
			var spread := 0
			for o: Enemy in enemies:
				if o.dead or o == e or o.pos.distance_to(at) > 3.0 or spread >= 4:
					continue
				o.poison_stacks = mini(o.poison_stacks + maxi(2, e.poison_stacks), 14)
				o.poison_time = 4.0
				o.poison_dps_per_stack = maxf(o.poison_dps_per_stack, base * 0.15)
				fx.bolt(at, o.pos, color)
				spread += 1
			deal_damage(e, base * 1.2 * mult, false, color, null, true)
		"gelo+raio":
			if not e.is_boss:
				e.frozen_time = 1.5
			deal_damage(e, base * 1.8 * mult, false, color, null, true)
		"fogo+veneno":
			var burst := base * (1.0 + e.poison_stacks * 0.6) * mult
			e.poison_stacks = 0
			aoe(at, 1.3, burst, color)
		"gelo+veneno":
			aoe(at, 1.4, base * 1.4 * mult, color)
			for o: Enemy in enemies:
				if not o.dead and o.pos.distance_to(at) < 1.6:
					o.chill_time = 2.5


func _kill(e: Enemy, source: Ball = null) -> void:
	if e.dead:
		return
	e.dead = true
	e.hp = 0.0
	if e.is_boss:
		_boss_defeated()
		return
	kills += 1
	combo += 1
	combo_timer = 2.5
	best_combo = maxi(best_combo, combo)
	_check_combo_tier()
	if character["id"] == "cacadora":
		build.cacada_bonus = minf(0.45, build.cacada_bonus + 0.015)
	_drop_gem(e.pos, e.xp)
	if rng.randf() < 0.06:
		sucata_run += 1
	if e.is_elite:
		sucata_run += 5
		heal(10.0)
		fx.text(e.pos, "ELITE!", Color("#ffb02e"))
	fx.sparks(e.pos, Color(e.data["cor"]).lightened(0.3), 7, 4.5)
	# Efeitos de morte por tipo/estado.
	if e.behavior == "explosivo":
		aoe(e.pos, 1.7, 26.0 * _hp_scale(), Color("#ff7a1f"), e, false)
		shake(0.1)
	if e.burn_time > 0.0 and e.burn_dps > 0.0:
		var fire: Color = GameData.ELEMENT_COLORS["fogo"]
		fx.ring(e.pos, 1.2, fire)
		for o: Enemy in enemies:
			if not o.dead and o.pos.distance_to(e.pos) < 1.4:
				o.burn_time = 3.0
				o.burn_dps = maxf(o.burn_dps, e.burn_dps * 0.7)
	if e.poison_stacks > 0:
		var n := 0
		for o: Enemy in enemies:
			if not o.dead and o != e and o.pos.distance_to(e.pos) < 1.9 and n < 3:
				o.poison_stacks = mini(o.poison_stacks + maxi(1, e.poison_stacks / 2), 14)
				o.poison_time = 4.0
				o.poison_dps_per_stack = maxf(o.poison_dps_per_stack, e.poison_dps_per_stack)
				n += 1
	if source and source.behavior == "clone" and not source.is_clone and rng.randf() < 0.3 + 0.05 * source.level:
		var stats := source.data.duplicate()
		spawn_ball(stats, e.pos, Vector2(rng.randf_range(-1, 1), 1).normalized(), true)
	if build.passive("multiplicacao") > 0:
		multiplicacao_count += 1
		if multiplicacao_count >= int(build.pval("multiplicacao")):
			multiplicacao_count = 0
			var s: Dictionary = build.slots[rng.randi() % build.slots.size()]
			spawn_ball(build.ball_stats(s["id"], s["level"]), player.pos + Vector2(0, 0.6), player.aim_dir.rotated(rng.randf_range(-0.3, 0.3)))


func _update_enemies(delta: float) -> void:
	for e: Enemy in enemies:
		if e.dead:
			continue
		_tick_status(e, delta)
		if e.dead:
			continue
		if e.is_boss:
			boss_time += delta
			boss.boss_update(delta)
			boss.animate(delta)
			continue
		if e.behavior == "atirador" and e.frozen_time <= 0.0 and e.pos.y < 15.0:
			e.shoot_timer -= delta
			if e.shoot_timer <= 0.0:
				e.shoot_timer = rng.randf_range(4.5, 7.5)
				_enemy_shoot(e)
		_update_melee(e, delta)
		if e.dead:
			continue
		if e.hop_t >= 1.0 and e.pos.y - e.half.y <= ENEMY_LINE:
			# Chegou ao fim do mapa: pula no jogador e explode.
			e.dead = true
			e.leaping = true
			e.leap_from = e.pos
			e.leap_t = 0.0
			e.show_eye(false)
			leapers.append(e)
			continue
		e.sync_visual()
		e.animate(delta)
		e.update_status_visual()


const CONTACT_FUSE := 3.5   # segundos encostado numa peça até ela se auto-explodir em você

## Contato: se o jogador fica encostado numa peça, ela mostra o olho gordo 👁 enchendo
## e, depois de ~3,5s, se auto-explode sobre ele. Sair de perto esvazia o pavio.
func _update_melee(e: Enemy, delta: float) -> void:
	var d := player.pos - e.pos
	var touching := absf(d.x) < e.half.x + 0.55 and absf(d.y) < e.half.y + 0.6
	if touching and e.frozen_time <= 0.0:
		e.contact_time += delta
	else:
		e.contact_time = maxf(0.0, e.contact_time - delta * 1.5)
	e.show_eye(e.contact_time > 0.15, e.contact_time / CONTACT_FUSE)
	if e.contact_time >= CONTACT_FUSE:
		e.dead = true
		e.show_eye(false)
		fx.explosion(e.pos, 1.3, Color("#ff3d1f"))
		hud.toast("A peça explodiu em você!")
		damage_player(e.contact_damage, "contato")


## Pulo final: arco até a posição atual do jogador e explosão (dano garantido).
func _update_leapers(delta: float) -> void:
	var i := leapers.size() - 1
	while i >= 0:
		var e: Enemy = leapers[i]
		e.leap_t += delta / 0.5
		var t := minf(e.leap_t, 1.0)
		var p := e.leap_from.lerp(player.pos, t)
		e.position = Vector3(p.x, sin(t * PI) * 2.0, -p.y)
		e.rotation.x = t * TAU * 0.5
		if e.leap_t >= 1.0:
			fx.explosion(player.pos, 1.2, Color("#ff3d1f"))
			hud.toast("Invadiram a vila!")
			damage_player(e.contact_damage, "invasao")
			e.queue_free()
			leapers.remove_at(i)
		i -= 1


func _tick_status(e: Enemy, delta: float) -> void:
	var dot := 0.0
	if e.burn_time > 0.0:
		e.burn_time -= delta
		dot += e.burn_dps * delta
		if e.burn_time <= 0.0:
			e.burn_dps = 0.0
	if e.poison_time > 0.0:
		e.poison_time -= delta
		dot += e.poison_stacks * e.poison_dps_per_stack * delta
		if e.poison_time <= 0.0:
			e.poison_stacks = 0
	if e.chill_time > 0.0:
		e.chill_time -= delta
		if e.chill_time <= 0.0:
			e.chill_stacks = 0
	if e.frozen_time > 0.0:
		e.frozen_time -= delta
	if e.slow_time > 0.0:
		e.slow_time -= delta
	for k in e.recent.keys():
		e.recent[k] = float(e.recent[k]) - delta
		if float(e.recent[k]) <= 0.0:
			e.recent.erase(k)
	e.gravity_slow = 0.0
	if dot > 0.0:
		var c: Color = GameData.ELEMENT_COLORS["fogo"] if e.burn_time > 0.0 else GameData.ELEMENT_COLORS["veneno"]
		deal_damage(e, dot, false, c, null, true, false)


func _enemy_shoot(e: Enemy) -> void:
	var node := Models.box(misc_root, Vector3(0.26, 0.22, 0.26), Color("#c9a26a"), Vector3.ZERO, 0.0)
	Models.sphere(node, 0.06, Color("#ff2d2d"), Vector3(0, 0.15, 0), 4.0, false)
	var target := Vector2(player.pos.x + rng.randf_range(-0.8, 0.8), 0.0)
	var vel := (target - e.pos).normalized() * 4.2
	projectiles.append({"node": node, "pos": e.pos, "vel": vel, "dmg": 5.0})


func _update_projectiles(delta: float) -> void:
	var i := projectiles.size() - 1
	while i >= 0:
		var p: Dictionary = projectiles[i]
		p["pos"] += p["vel"] * delta
		var node: Node3D = p["node"]
		node.position = FxLayer.to3(p["pos"], 0.5)
		node.rotation.y += delta * 5.0
		var hit_player: bool = p["pos"].distance_to(player.pos) < 0.6
		if hit_player:
			damage_player(p["dmg"], "projetil")
			fx.explosion(p["pos"], 0.7, Color("#ff9f2e"))
		# Bolas destroem pacotes no caminho.
		var shot := false
		if not hit_player:
			for b: Ball in balls:
				if not b.dead and b.pos.distance_to(p["pos"]) < b.radius + 0.2:
					shot = true
					fx.sparks(p["pos"], Color("#c9a26a"), 5, 3.0)
					break
		if hit_player or shot or p["pos"].y < -1.0:
			node.queue_free()
			projectiles.remove_at(i)
		i -= 1


# =================================================================== CAMPOS / TRÂNSITO

func _spawn_field(at: Vector2, b: Ball) -> void:
	if fields.size() >= 4:
		var old: Dictionary = fields.pop_front()
		old["node"].queue_free()
	var freeze := b.behavior == "singularidade"
	var node := Node3D.new()
	misc_root.add_child(node)
	node.position = FxLayer.to3(at, 0.3)
	var radius := 1.9 + b.level * 0.2
	var t := Models.torus(node, 0.85, 1.0, b.color, Vector3.ZERO, 3.0)
	t.scale = Vector3.ONE * radius
	Models.sphere(node, 0.35, Color("#120d1f"), Vector3(0, 0.2, 0), 0.0, true)
	fields.append({"node": node, "pos": at, "radius": radius, "timer": 2.0 + 0.3 * b.level,
		"dps": b.damage * 0.6, "freeze": freeze, "tick": 0.0, "color": b.color})


func _update_fields(delta: float) -> void:
	var i := fields.size() - 1
	while i >= 0:
		var f: Dictionary = fields[i]
		f["timer"] -= delta
		f["tick"] -= delta
		var node: Node3D = f["node"]
		node.rotation.y += delta * 4.0
		var tick: bool = f["tick"] <= 0.0
		if tick:
			f["tick"] = 0.5
		for e: Enemy in enemies:
			if e.dead or e.pos.distance_to(f["pos"]) > f["radius"]:
				continue
			e.gravity_slow = 0.9 if f["freeze"] else 0.75
			if tick:
				deal_damage(e, f["dps"] * 0.5, false, f["color"], null, false)
				if f["freeze"] and not e.dead:
					apply_elements(e, ["gelo"], f["dps"], 1)
		if f["timer"] <= 0.0:
			node.queue_free()
			fields.remove_at(i)
		i -= 1


func _update_traffic(delta: float) -> void:
	var tr: Dictionary = region.get("transito", {})
	if not tr.is_empty() and time > float(tr["inicio"]):
		traffic_timer -= delta
		if traffic_timer <= 0.0:
			var iv: Array = tr["intervalo"]
			traffic_timer = lerpf(iv[0], iv[1], difficulty()) * (0.6 if boss and boss.phase == 2 else 1.0)
			_spawn_car(float(tr["faixa_y"]))
	var i := cars.size() - 1
	while i >= 0:
		var c: Dictionary = cars[i]
		c["pos"] += c["vel"] * delta
		var node: Node3D = c["node"]
		node.position = FxLayer.to3(c["pos"], 0.0)
		if absf(c["pos"].x) > 11.0:
			node.queue_free()
			cars.remove_at(i)
		i -= 1


func _spawn_car(lane_y: float) -> void:
	var kinds := ["taxi", "onibus", "carro"]
	var kind: String = kinds[rng.randi() % kinds.size()]
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	var node := Models.build_vehicle(kind)
	misc_root.add_child(node)
	node.rotation_degrees.y = 0.0 if dir > 0 else 180.0
	var half := Vector2(1.7 if kind == "onibus" else 0.8, 0.45)
	var start := Vector2(-10.5 * dir, lane_y)
	node.position = FxLayer.to3(start)
	cars.append({"node": node, "pos": start, "half": half, "vel": Vector2(dir * (5.5 if kind == "onibus" else 8.0), 0)})
	hud.toast("BI-BI! Trânsito na Paulista!" if kind != "onibus" else "Ônibus passando — segura a bola!")


# =================================================================== GEMAS / XP

func _drop_gem(at: Vector2, value: int) -> void:
	var node := MeshInstance3D.new()
	node.mesh = _gem_mesh
	var c := Color("#5fe0a0") if value < 4 else Color("#4fa8ff")
	if value >= 10:
		c = Color("#ffb02e")
	node.material_override = Models.mat(c, 2.0, true)
	misc_root.add_child(node)
	node.position = FxLayer.to3(at, 0.35)
	gems.append({"node": node, "pos": at, "value": value})


func _update_gems(delta: float) -> void:
	var radius := build.pickup_radius()
	var i := gems.size() - 1
	while i >= 0:
		var g: Dictionary = gems[i]
		var to_p: Vector2 = player.pos - g["pos"]
		var dist := to_p.length()
		if dist < radius or g["pos"].y < 1.8:
			g["pos"] += to_p.normalized() * 15.0 * delta
		else:
			g["pos"] += Vector2(0, -1.4) * delta
		var node: Node3D = g["node"]
		node.position = FxLayer.to3(g["pos"], 0.35 + sin(time * 6.0 + i) * 0.08)
		node.rotation.y += delta * 3.0
		if dist < 0.55:
			add_xp(float(g["value"]))
			if build.passive("colecionador") > 0:
				build.colecionador_bonus = minf(0.4, build.colecionador_bonus + build.pval("colecionador") / 100.0)
				build.colecionador_timer = 4.0
			node.queue_free()
			gems.remove_at(i)
		i -= 1
	if build.colecionador_timer > 0.0:
		build.colecionador_timer -= delta
		if build.colecionador_timer <= 0.0:
			build.colecionador_bonus = 0.0


func _xp_needed(l: int) -> float:
	return 6.0 + 4.0 * l + 0.6 * l * l


func add_xp(v: float) -> void:
	xp += v * build.xp_mult()
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = _xp_needed(level)
		pending_levelups += 1
		babies += 1  # a cada nível chega mais uma Bolinha de Gude
		_sync_bag()


func _open_levelup() -> void:
	pending_levelups -= 1
	var offers := build.generate_offers(rng)
	levelup.open_choice("SUBIU DE NÍVEL!", "Nível %d — escolha 1" % level, offers, build, "levelup")


func _on_offer_chosen(offer: Dictionary, context: String) -> void:
	if offer["tipo"] == "cura":
		heal(30.0)
	else:
		var before := max_hp
		build.apply_offer(offer)
		if offer["tipo"] == "passiva" and offer["id"] == "vitalidade":
			max_hp = float(character["vida"]) + build.max_hp_bonus()
			heal(max_hp - before)
		if offer["tipo"] == "fusao":
			hud.banner("RECEITA!", "Panela de Pressão: " + String(offer["nome"]), 2.2)
			fx.explosion(player.pos + Vector2(0, 1.0), 2.0, offer["cor"])
			if not descobertas.has(offer["id"]):
				descobertas.append(offer["id"])
	_sync_bag()
	if context == "feira":
		hud.toast("\"Preço bom eu não garanto. Mas barato também não.\"")


# =================================================================== EVENTOS / CHEFE

func _check_events() -> void:
	for t in region.get("eventos_feira", []):
		if time >= float(t) and not feira_done.has(t) and not boss_spawned and not levelup.is_open():
			feira_done.append(t)
			var offers := build.relic_offers(rng, 3)
			if offers.is_empty():
				continue
			offers.append({"tipo": "cura", "id": "cura", "nome": "Pastel de Feira", "descricao": "Recupera 30 de vida. Com caldo de cana.",
				"raridade": "comum", "cor": Color("#e8b04a"), "nivel": 0, "tags": []})
			levelup.open_choice("FEIRA DA PAULISTA", "Um mercador oferece relíquias. Escolha uma.", offers, build, "feira")
			return


func _start_boss() -> void:
	boss_spawned = true
	var info: Dictionary = region["chefe"]
	boss = BossArranhaCeu.new()
	enemies_root.add_child(boss)
	boss.setup_boss(info, self, float(info["hp"]))
	enemies.append(boss)
	# A chegada do prédio esmaga quem estiver no caminho (vira XP).
	for e: Enemy in enemies:
		if not e.dead and not e.is_boss and e.pos.y > boss._arrive_y - boss.half.y - 0.8:
			_kill(e)
	hud.banner(String(info["nome"]).to_upper(), "\"%s\"" % info["fala"], 3.5)
	_cam_offset_target = Vector3(0, 2.5, 2.0)
	shake(0.4)
	get_tree().create_timer(3.5, false).timeout.connect(func(): _cam_offset_target = Vector3(0, 0.8, 0.6))


func on_boss_phase(p: int) -> void:
	hud.banner("FASE %d" % p, "Hora do rush! O prédio ficou nervoso.", 2.0)
	shake(0.3)


func boss_summon(y: float) -> void:
	# Alinha à grade de casas.
	var row := SPAWN_Y - roundf(SPAWN_Y - clampf(y, 5.0, 14.0))
	_spawn_row(row, 0.6, {"drone": 2, "pombo": 3})


func boss_glass_rain(count: int) -> void:
	for i in count:
		var x := player.pos.x if i == 0 else clampf(player.pos.x + rng.randf_range(-3.5, 3.5), -5.5, 5.5)
		var at := Vector2(x, player.pos.y)
		var warn := fx.warning(at, 0.85, 1.3)
		shards.append({"warn": warn, "pos": at, "timer": 1.3 + i * 0.12})


func _update_shards(delta: float) -> void:
	var i := shards.size() - 1
	while i >= 0:
		var s: Dictionary = shards[i]
		s["timer"] -= delta
		var w: MeshInstance3D = s["warn"]
		w.scale = Vector3.ONE * (1.0 + sin(time * 20.0) * 0.06)
		if s["timer"] <= 0.0:
			fx.explosion(s["pos"], 0.9, Color("#cfe6ff"))
			if absf(player.pos.x - s["pos"].x) < 0.85:
				damage_player(12.0, "vidraca")
			w.queue_free()
			shards.remove_at(i)
		i -= 1


func _boss_defeated() -> void:
	hud.banner("VITÓRIA!", "O Arranha-Céu desabou. São Paulo respira.", 3.0)
	for k in 6:
		fx.explosion(boss.pos + Vector2(rng.randf_range(-4, 4), rng.randf_range(-1, 1)), 2.5, Color("#ff9f2e"))
	shake(0.8)
	Engine.time_scale = 0.35
	boss.visible = false
	game_over = true
	get_tree().create_timer(1.6, true, false, true).timeout.connect(func(): _finish(true))


# =================================================================== JOGADOR

func damage_player(amount: float, src := "outro") -> void:
	if game_over:
		return
	damage_taken[src] = float(damage_taken.get(src, 0.0)) + amount
	hp -= amount
	player.hurt_flash = 1.0
	hud.flash_damage()
	shake(0.25)
	if hp <= 0.0:
		hp = 0.0
		hud.banner("DERROTA", "Perdi a run... mas a próxima vai ser melhor.", 3.0)
		game_over = true
		Engine.time_scale = 0.4
		get_tree().create_timer(1.4, true, false, true).timeout.connect(func(): _finish(false))


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func use_ability() -> void:
	if ability_cd > 0.0 or game_over or get_tree().paused:
		return
	var ab: Dictionary = character["habilidade"]
	ability_cd = float(ab["recarga"])
	ability_time = float(ab["duracao"])
	hud.toast(String(ab["nome"]).to_upper() + "!")
	match ab["id"]:
		"rajada":
			_rajada_queue = 14
			_rajada_timer = 0.0
		"impacto":
			fx.ring(player.pos, 2.5, Color("#e8b04a"))
			shake(0.2)
		"catalisador":
			fx.ring(player.pos, 2.5, Color("#3fb8a5"))


func _update_ability(delta: float) -> void:
	ability_cd = maxf(0.0, ability_cd - delta)
	ability_time = maxf(0.0, ability_time - delta)
	if autoplay and ability_cd <= 0.0:
		use_ability()


# =================================================================== COMBO

func _update_combo(delta: float) -> void:
	if combo <= 0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo = 0
		combo_tier_reached = 0
		build.cacada_bonus = 0.0


func _check_combo_tier() -> void:
	for t in COMBO_TIERS:
		if combo >= int(t[0]):
			if int(t[0]) > combo_tier_reached:
				combo_tier_reached = int(t[0])
				if not _tiers_paid.has(t[0]):
					_tiers_paid.append(t[0])
					sucata_run += int(t[3])
					hud.toast("COMBO %s!  +%d sucata" % [t[1], t[3]])
				else:
					hud.toast("COMBO %s!" % t[1])
			return


func combo_label() -> String:
	for t in COMBO_TIERS:
		if combo >= int(t[0]):
			return t[1]
	return ""


func combo_damage_mult() -> float:
	for t in COMBO_TIERS:
		if combo >= int(t[0]):
			return float(t[2])
	return 1.0


# =================================================================== CÂMERA

func shake(amount: float) -> void:
	if not bool(Save.data["opcoes"].get("tremor", true)):
		return
	_shake = minf(1.0, _shake + amount)


func _update_camera(delta: float) -> void:
	_shake = maxf(0.0, _shake - delta * 2.2)
	_cam_offset = _cam_offset.lerp(_cam_offset_target, minf(1.0, delta * 2.0))
	var t := _cam_base
	t.origin += _cam_offset
	if _shake > 0.0:
		var s := _shake * _shake * 0.5
		t.origin += Vector3(rng.randf_range(-s, s), rng.randf_range(-s, s), rng.randf_range(-s, s) * 0.5)
	camera.transform = t


func _cleanup() -> void:
	var i := balls.size() - 1
	while i >= 0:
		if balls[i].dead:
			balls[i].queue_free()
			balls.remove_at(i)
		i -= 1
	i = enemies.size() - 1
	while i >= 0:
		var e: Enemy = enemies[i]
		if e.dead and not e.is_boss:
			if not e.leaping:
				e.queue_free()
			enemies.remove_at(i)
		i -= 1


func _finish(victory: bool) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var sucata := sucata_run + kills / 10 + level * 2
	if victory:
		sucata += 60
	else:
		sucata = int(sucata * 0.6)  # perde parte dos recursos temporários
	var slots_desc: Array = []
	for s in build.slots:
		slots_desc.append({"id": s["id"], "nivel": s["level"]})
	var result := {
		"vitoria": victory,
		"tempo": time,
		"abates": kills,
		"nivel": level,
		"melhor_combo": best_combo,
		"reacoes": reactions_count,
		"sucata": sucata,
		"personagem": character["id"],
		"regiao": region["id"],
		"bolas": slots_desc,
		"passivas": build.passives.duplicate(),
		"reliquias": build.relics.duplicate(),
		"descobertas": descobertas,
		"dano": damage_log,
		"dano_recebido": damage_taken,
		"tempo_chefe": boss_time,
	}
	finished.emit(result)
