class_name BossMula
extends BossBase
## CHEFE DA MATA ATLÂNTICA — A Mula sem Cabeça.
## Padrão (GDD-17): atravessa a tela em linha reta e quebra o ritmo das tabelinhas.
##   1. Ronda no alto da grota.
##   2. Aviso: a fileira por onde ela vai passar acende (tropel!).
##   3. Galope: cruza a arena naquela fileira, rebatendo bolas, pisoteando tropas e deixando rastro de fogo.
##   4. Tonta: para do outro lado e recebe DANO EM DOBRO — é a janela para acertar.
## Fase 2 (metade da vida): galopa mais rápido e às vezes mira a faixa do jogador — desvie andando para frente/trás.

enum State { RONDA, AVISO, GALOPE, TONTA, VOLTA }

const TOP_Y := 15.5
const CHARGE_X := 9.5
const TRAIL_LIFE := 3.0

var state := State.RONDA
var _timer := 2.5
var _dir := 1.0
var _row := 10.0
var _warn: MeshInstance3D
var _trail: Array = []      # {node, mat, x, y, life}
var _trail_drop := 0.0
var _mula: Node3D
var _pace_dir := 1.0


func setup_boss(boss_info: Dictionary, the_run: Node, hp_value: float) -> void:
	super.setup_boss(boss_info, the_run, hp_value)
	id = boss_info["id"]
	data = {"id": id, "nome": boss_info["nome"], "modelo": "mula", "cor": "#3b2416", "comportamento": "chefe"}
	behavior = "chefe"
	half = Vector2(1.7, 0.65)
	arrive_y = TOP_Y
	pos = Vector2(0, 24.0)
	_mula = Models.build_mula()
	_mula.scale = Vector3.ONE * 0.9
	add_child(_mula)
	_model = _mula
	sync_visual()


func auto_target_point() -> Vector2:
	return pos


func damage_multiplier_at(_contact: Vector2) -> float:
	match state:
		State.TONTA:
			return 2.5
		State.GALOPE:
			return 1.0
	return 0.8


func animate(delta: float) -> void:
	_anim += delta
	_punch = maxf(0.0, _punch - delta * 6.0)
	var running := state == State.GALOPE or state == State.VOLTA
	var speed := 16.0 if running else 4.0
	for c in _mula.get_children():
		if c.name.begins_with("Perna"):
			var side := 1.0 if c.position.z > 0.0 else -1.0
			var front := 1.0 if c.position.x > 0.0 else -1.0
			c.rotation.z = sin(_anim * speed + side * front * 1.6) * (0.6 if running else 0.15)
	var fire := _mula.get_node_or_null("Fogo")
	if fire:
		fire.scale = Vector3.ONE * (1.0 + sin(_anim * 23.0) * 0.12 + _punch * 0.2)
		fire.rotation.y += delta * 6.0
	_mula.position.y = absf(sin(_anim * speed * 0.5)) * (0.25 if running else 0.05)
	if state == State.TONTA:
		_mula.rotation.x = sin(_anim * 9.0) * 0.08  # cambaleando
	else:
		_mula.rotation.x = 0.0
	_mula.rotation.y = 0.0 if _dir > 0.0 else PI
	_update_trail(delta)


func boss_update(delta: float) -> void:
	if intro:
		pos.y = move_toward(pos.y, arrive_y, delta * 5.0)
		sync_visual()
		if is_equal_approx(pos.y, arrive_y):
			intro = false
		return
	if phase == 1 and hp < max_hp * 0.5:
		phase = 2
		run.on_boss_phase(2)
	_timer -= delta
	match state:
		State.RONDA:
			pos.x += _pace_dir * delta * 2.2
			if absf(pos.x) > 4.0:
				_pace_dir = -signf(pos.x)
			_dir = _pace_dir
			if _timer <= 0.0:
				_start_warning()
		State.AVISO:
			if _warn:
				_warn.scale.y = 1.0 + sin(_anim * 25.0) * 0.3
			if _timer <= 0.0:
				_start_charge()
		State.GALOPE:
			pos.x += _dir * delta * (15.0 if phase == 1 else 19.0)
			_charge_effects(delta)
			if (_dir > 0.0 and pos.x >= 4.6) or (_dir < 0.0 and pos.x <= -4.6):
				state = State.TONTA
				_timer = 2.4
				run.fx.text(pos + Vector2(0, 1.2), "TONTA! DANO EM DOBRO", Color("#ffe14a"), 0.007)
				Sfx.play("explosao", 0.05)
				run.shake(0.25)
		State.TONTA:
			if _timer <= 0.0:
				state = State.VOLTA
				if phase == 2:
					run.boss_summon(pos.y + 1.0)
		State.VOLTA:
			var target := Vector2(clampf(pos.x, -4.0, 4.0), TOP_Y)
			pos = pos.move_toward(target, delta * 9.0)
			if pos.distance_to(target) < 0.05:
				state = State.RONDA
				_timer = 2.6 if phase == 1 else 1.6
	sync_visual()


func _start_warning() -> void:
	state = State.AVISO
	_timer = 1.15
	if phase == 2 and randf() < 0.5:
		_row = clampf(run.player.pos.y + 0.4, 1.4, 4.4)  # mira a faixa do jogador
	else:
		_row = randf_range(5.5, 12.5)
	_dir = 1.0 if randf() < 0.5 else -1.0
	# Some do alto e reaparece fora da tela, na ponta da fileira.
	pos = Vector2(-CHARGE_X * _dir, _row)
	_warn = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12.0, 0.08, 1.2)
	_warn.mesh = bm
	_warn.material_override = Models.fade_mat(Color(1.0, 0.25, 0.05, 0.45), 2.5)
	_warn.position = Vector3(0, 0.05, -_row)
	run.fx.add_child(_warn)
	run.hud.toast("Tropel na mata! Saia da fileira acesa!")
	Sfx.play("aviso", 0.0)


func _start_charge() -> void:
	state = State.GALOPE
	if _warn:
		_warn.queue_free()
		_warn = null
	Sfx.play("chefe", 0.1, -4.0)
	run.shake(0.15)


func _charge_effects(delta: float) -> void:
	# Pisoteia as tropas no caminho (quebra a formação) e atropela o jogador.
	for e: Enemy in run.enemies:
		if e == self or e.dead or e.is_boss:
			continue
		if absf(e.pos.y - pos.y) < e.half.y + half.y and absf(e.pos.x - pos.x) < e.half.x + half.x:
			e.dead = true
			run.fx.sparks(e.pos, Color("#ff9f2e"), 6, 5.0)
	var p: Vector2 = run.player.pos
	if absf(p.y - pos.y) < half.y + 0.4 and absf(p.x - pos.x) < half.x + 0.3:
		if not has_meta("hit_player"):
			set_meta("hit_player", true)
			run.damage_player(16.0, "chefe")
			run.fx.explosion(p, 1.2, Color("#ff3d1f"))
	else:
		remove_meta("hit_player")
	# Rastro de fogo.
	_trail_drop -= delta
	if _trail_drop <= 0.0 and absf(pos.x) < 6.0:
		_trail_drop = 0.08
		var n := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.35
		cm.height = 0.8
		n.mesh = cm
		var m := Models.fade_mat(Color(1.0, 0.45, 0.1, 0.85), 4.0)
		n.material_override = m
		n.position = Vector3(pos.x - _dir * 1.5, 0.4, -pos.y)
		run.fx.add_child(n)
		_trail.append({"node": n, "mat": m, "x": pos.x - _dir * 1.5, "y": pos.y, "life": TRAIL_LIFE})


func _update_trail(delta: float) -> void:
	var i := _trail.size() - 1
	var p: Vector2 = run.player.pos if run else Vector2.ZERO
	while i >= 0:
		var t: Dictionary = _trail[i]
		t["life"] -= delta
		var n: MeshInstance3D = t["node"]
		var k: float = t["life"] / TRAIL_LIFE
		n.scale = Vector3(1.0, 0.6 + 0.5 * k + sin(_anim * 20.0 + i) * 0.1, 1.0)
		t["mat"].albedo_color.a = 0.85 * k
		# Fogo queima quem pisar (inclusive tropas) — ajuda e atrapalha.
		if run and absf(p.x - t["x"]) < 0.45 and absf(p.y - t["y"]) < 0.6:
			run.damage_player(6.0 * delta, "chefe")
		if run and int(_anim * 4.0) % 2 == 0:
			for e: Enemy in run.enemies:
				if not e.dead and not e.is_boss and absf(e.pos.x - t["x"]) < 0.6 and absf(e.pos.y - t["y"]) < 0.7:
					e.burn_time = 3.0
					e.burn_dps = maxf(e.burn_dps, 8.0)
		if t["life"] <= 0.0:
			n.queue_free()
			_trail.remove_at(i)
		i -= 1
