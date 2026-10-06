class_name Hud
extends CanvasLayer
## HUD inspirado nas referências: espada de vida + orbe de habilidade à esquerda,
## trilha de progresso com caveiras à direita, botões de velocidade no topo.

const SPEEDS := [1.0, 1.5, 2.0]
const RITMOS := ["Xote", "Forró", "Frevo"]  # velocidade do jogo = ritmo

var run: Run
var _root: Control
var _draw_layer: Control
var _timer_label: Label
var _combo_label: Label
var _sucata_label: Label
var _level_label: Label
var _top_left: VBoxContainer
var _top_center: VBoxContainer
var _top_right: HBoxContainer
var _bottom: VBoxContainer
var _speed_button: Button
var _ability_button: Button
var _aim_button: Button
var _kick_button: Button
var _bag_label: Label
var _kick_shown := true
var _aim_auto_shown := true
var _slots_box: HBoxContainer
var _passives_box: HBoxContainer
var _banner: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_time := 0.0
var _toast_box: VBoxContainer
var _flash: ColorRect
var _pause_panel: Control
var _speed_index := 0
var _build_signature := ""


func setup(the_run: Run) -> void:
	run = the_run
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UIKit.theme()
	add_child(_root)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.8, 0.05, 0.02, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_draw_layer = Control.new()
	_draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_layer.draw.connect(_draw_gauges)
	_root.add_child(_draw_layer)

	_top_left = UIKit.vbox(0)
	_root.add_child(_top_left)
	_sucata_label = UIKit.label("Sucata 0", 24, UIKit.GOLD)
	_top_left.add_child(_sucata_label)
	_level_label = UIKit.label("Nv 1", 22)
	_top_left.add_child(_level_label)

	_top_center = UIKit.vbox(0)
	_root.add_child(_top_center)
	_timer_label = UIKit.label("00:00", 30)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_center.add_child(_timer_label)
	_combo_label = UIKit.label("", 28, UIKit.GOLD, 8)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_center.add_child(_combo_label)

	# Topo direito: velocidade (um botão que alterna) + pausa — alvos grandes para o dedo.
	_top_right = UIKit.hbox(8)
	_root.add_child(_top_right)
	_speed_button = UIKit.button(">", cycle_speed, 22)
	_speed_button.custom_minimum_size = Vector2(96, 64)
	_speed_button.focus_mode = Control.FOCUS_NONE
	_top_right.add_child(_speed_button)
	var pb := UIKit.button("II", toggle_pause, 22)
	pb.custom_minimum_size = Vector2(64, 64)
	pb.focus_mode = Control.FOCUS_NONE
	_top_right.add_child(pb)

	# Botão de habilidade (orbe) — no polegar direito no celular.
	_ability_button = Button.new()
	_ability_button.flat = true
	_ability_button.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		_ability_button.add_theme_stylebox_override(st, empty)
	_ability_button.pressed.connect(func(): run.use_ability())
	_root.add_child(_ability_button)

	_aim_button = UIKit.button("", _toggle_aim, 16)
	_aim_button.focus_mode = Control.FOCUS_NONE
	_aim_button.custom_minimum_size = Vector2(128, 52)
	_root.add_child(_aim_button)

	_kick_button = UIKit.button("", func(): run.toggle_kick(), 16)
	_kick_button.focus_mode = Control.FOCUS_NONE
	_kick_button.custom_minimum_size = Vector2(128, 52)
	_root.add_child(_kick_button)

	_bottom = UIKit.vbox(6)
	_root.add_child(_bottom)
	_bag_label = UIKit.label("", 17, UIKit.CREAM, 4)
	_bottom.add_child(_bag_label)
	_passives_box = UIKit.hbox(4)
	_bottom.add_child(_passives_box)
	_slots_box = UIKit.hbox(8)
	_bottom.add_child(_slots_box)

	_banner = UIKit.vbox(0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_banner)
	_banner_title = UIKit.label("", 46, UIKit.GOLD, 12)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_title)
	_banner_sub = UIKit.label("", 22, UIKit.CREAM, 6)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_sub)
	_banner.modulate.a = 0.0

	_toast_box = UIKit.vbox(2)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	_root.add_child(_toast_box)

	_build_pause()
	_set_speed(0)
	_root.resized.connect(_layout)
	_layout()


func is_portrait() -> bool:
	return _root.size.x < _root.size.y


## Posiciona tudo conforme a orientação. Retrato (celular) é o layout principal.
func _layout() -> void:
	var portrait := is_portrait()
	UIKit.place(_top_left, Vector2(0, 0), Vector2(18, 12))
	UIKit.place(_top_center, Vector2(0.5, 0), Vector2(-110, 8), Vector2(220, 0))
	UIKit.place(_top_right, Vector2(1, 0), Vector2(-180, 12), Vector2(168, 64))
	var w := minf(660.0, _root.size.x - 32.0)
	if portrait:
		UIKit.place(_ability_button, Vector2(1, 1), Vector2(-136, -196), Vector2(120, 120))
		UIKit.place(_aim_button, Vector2(1, 1), Vector2(-140, -258), Vector2(128, 52))
		UIKit.place(_kick_button, Vector2(1, 1), Vector2(-140, -318), Vector2(128, 52))
		UIKit.place(_bottom, Vector2(0, 1), Vector2(12, -176), Vector2(0, 140))
		UIKit.place(_banner, Vector2(0.5, 0.5), Vector2(-w * 0.5, -220), Vector2(w, 0))
		UIKit.place(_toast_box, Vector2(0.5, 1), Vector2(-w * 0.5, -270), Vector2(w, 0))
	else:
		UIKit.place(_ability_button, Vector2(0, 1), Vector2(10, -200), Vector2(128, 128))
		UIKit.place(_aim_button, Vector2(0, 0), Vector2(16, 76), Vector2(128, 44))
		UIKit.place(_kick_button, Vector2(0, 0), Vector2(16, 132), Vector2(128, 44))
		UIKit.place(_bottom, Vector2(0, 1), Vector2(150, -166), Vector2(0, 136))
		UIKit.place(_banner, Vector2(0.5, 0.5), Vector2(-450, -190), Vector2(900, 0))
		UIKit.place(_toast_box, Vector2(0.5, 1), Vector2(-350, -160), Vector2(700, 0))
	_refresh_aim_label()


func _toggle_aim() -> void:
	run.auto_aim = not run.auto_aim
	_refresh_aim_label()


func _refresh_aim_label() -> void:
	_aim_button.text = "Mira: AUTO" if run.auto_aim else "Mira: LIVRE"
	_kick_button.text = "Chute: AUTO" if run.auto_kick else "Chute: PARADO"


func _process(delta: float) -> void:
	if run == null:
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	_timer_label.text = UIKit.format_time(run.time)
	_sucata_label.text = "Sucata %d" % run.sucata_run
	_level_label.text = "Nv %d" % run.level
	if run.combo >= 5:
		var tag := run.combo_label()
		_combo_label.text = "COMBO %d %s" % [run.combo, tag]
		_combo_label.modulate.a = clampf(run.combo_timer / 1.0, 0.3, 1.0)
	else:
		_combo_label.text = ""
	_flash.color.a = maxf(0.0, _flash.color.a - real_delta * 1.6)
	if _banner_time > 0.0:
		_banner_time -= real_delta
		_banner.modulate.a = clampf(_banner_time * 2.0, 0.0, 1.0)
	if _aim_auto_shown != run.auto_aim or _kick_shown != run.auto_kick:
		_aim_auto_shown = run.auto_aim
		_kick_shown = run.auto_kick
		_refresh_aim_label()
	var in_bag := run.bag.size()
	_bag_label.text = "Bolsa %d / %d" % [in_bag, run.bag_total()]
	_bag_label.modulate = Color("#ff6b3d") if in_bag == 0 else Color.WHITE
	_refresh_build()
	_draw_layer.queue_redraw()


func _refresh_build() -> void:
	var sig := str(run.build.slots.map(func(s): return "%s%d" % [s["id"], s["level"]])) + str(run.build.passives) + str(run.build.relics)
	if sig == _build_signature:
		return
	_build_signature = sig
	for c in _slots_box.get_children():
		c.queue_free()
	for c in _passives_box.get_children():
		c.queue_free()
	for s in run.build.slots:
		var b: Dictionary = GameData.balls[s["id"]]
		var ic := UIKit.icon(Color(b["cor"]), String(b["nome"]).substr(0, 1), 56.0, int(s["level"]))
		ic.tooltip_text = b["nome"]
		_slots_box.add_child(ic)
	for i in range(run.build.slots.size(), RunBuild.MAX_SLOTS):
		var empty := UIKit.icon(Color("#2a2420"), "+", 56.0)
		_slots_box.add_child(empty)
	for pid in run.build.passives:
		var p: Dictionary = GameData.passives[pid]
		_passives_box.add_child(UIKit.icon(Color(p["cor"]), String(p["nome"]).substr(0, 1), 34.0, int(run.build.passives[pid])))
		if _passives_box.get_child_count() >= 6:
			break
	for rid in run.build.relics:
		var r: Dictionary = GameData.relics[rid]
		_passives_box.add_child(UIKit.icon(Color(r["cor"]), "R", 34.0))


func _draw_gauges() -> void:
	var c := _draw_layer
	var size := c.size
	var portrait := is_portrait()
	var font := ThemeDB.fallback_font
	var ratio := clampf(run.hp / run.max_hp, 0.0, 1.0)
	var hp_color := Color("#c2412d").lerp(Color("#ff6b3d"), 0.5 + sin(Time.get_ticks_msec() / 300.0) * 0.2)
	var hp_text := "%d / %d" % [ceili(run.hp), ceili(run.max_hp)]
	if portrait:
		# ---------- Espada de vida horizontal (abaixo do topo)
		var y := 98.0
		var x0 := 52.0
		var x1 := size.x * 0.64
		var blade := PackedVector2Array([Vector2(x0, y - 13), Vector2(x1 - 26, y - 13), Vector2(x1, y), Vector2(x1 - 26, y + 13), Vector2(x0, y + 13)])
		c.draw_colored_polygon(blade, Color("#2a1d14"))
		if ratio > 0.0:
			c.draw_rect(Rect2(x0, y - 10, (x1 - 26 - x0) * ratio, 20), hp_color)
		c.draw_polyline(blade + PackedVector2Array([blade[0]]), UIKit.INK, 3.0)
		c.draw_rect(Rect2(x0 - 12, y - 30, 12, 60), Color("#8a5a3a"))
		c.draw_rect(Rect2(x0 - 12, y - 30, 12, 60), UIKit.INK, false, 2.0)
		c.draw_rect(Rect2(18, y - 7, x0 - 30, 14), Color("#5a3a22"))
		c.draw_circle(Vector2(18, y), 10, Color("#c2412d"))
		_text(c, font, Vector2(x0, y + 7), hp_text, x1 - x0 - 26, 17)
	else:
		# ---------- Espada de vida vertical (esquerda)
		var top := 120.0
		var bottom := size.y - 230.0
		var x := 74.0
		var blade := PackedVector2Array([Vector2(x - 14, bottom), Vector2(x - 14, top + 30), Vector2(x, top), Vector2(x + 14, top + 30), Vector2(x + 14, bottom)])
		c.draw_colored_polygon(blade, Color("#2a1d14"))
		var fill_top := lerpf(bottom, top + 30, ratio)
		if ratio > 0.0:
			c.draw_rect(Rect2(x - 11, fill_top, 22, bottom - fill_top), hp_color)
		c.draw_polyline(blade + PackedVector2Array([blade[0]]), UIKit.INK, 3.0)
		c.draw_rect(Rect2(x - 34, bottom, 68, 12), Color("#8a5a3a"))
		c.draw_rect(Rect2(x - 34, bottom, 68, 12), UIKit.INK, false, 2.0)
		_text(c, font, Vector2(x - 50, top - 10), "%d" % ceili(run.hp), 100, 20)
	# ---------- Orbe de habilidade (centrado no botão tocável)
	var r := _ability_button.get_rect()
	var orb := r.get_center()
	var rad := r.size.x * 0.42
	var ab: Dictionary = run.character["habilidade"]
	var is_ready := run.ability_cd <= 0.0
	var base_color := Color(run.character["cor"])
	c.draw_circle(orb, rad + 5, UIKit.INK)
	c.draw_circle(orb, rad, Color("#8a5a3a"))
	c.draw_circle(orb, rad * 0.8, base_color if is_ready else base_color.darkened(0.6))
	if run.ability_time > 0.0:
		c.draw_arc(orb, rad * 0.92, 0, TAU, 40, Color("#fff3c4"), 4.0)
	if not is_ready:
		var frac := run.ability_cd / float(ab["recarga"])
		c.draw_arc(orb, rad * 0.7, -PI / 2, -PI / 2 + TAU * (1.0 - frac), 32, UIKit.GOLD, 6.0)
		_text(c, font, orb + Vector2(-30, 10), "%d" % ceili(run.ability_cd), 60, 28)
	else:
		c.draw_circle(orb + Vector2(-rad * 0.3, -rad * 0.3), rad * 0.2, Color(1, 1, 1, 0.4))
	var hint := String(ab["nome"]) if portrait else String(ab["nome"]) + " [Espaço]"
	_text(c, font, orb + Vector2(-80, rad + 24), hint, 160, 15)
	# ---------- Trilha de progresso com caveiras (direita)
	var rx := size.x - 30.0
	var rtop := 170.0 if portrait else 110.0
	var rbot := size.y - (320.0 if portrait else 110.0)
	c.draw_rect(Rect2(rx - 8, rtop, 16, rbot - rtop), Color("#2a1d14"))
	var boss_t := float(run.region["tempo_chefe"])
	var prog := clampf(run.time / boss_t, 0.0, 1.0)
	c.draw_rect(Rect2(rx - 5, lerpf(rbot, rtop, prog), 10, (rbot - rtop) * prog), Color("#8a5a3a").lerp(UIKit.GOLD, prog))
	c.draw_rect(Rect2(rx - 8, rtop, 16, rbot - rtop), UIKit.INK, false, 2.0)
	for t in run.region.get("eventos_feira", []):
		var fy := lerpf(rbot, rtop, float(t) / boss_t)
		_draw_skull(c, Vector2(rx, fy), 10.0, UIKit.TEAL if run.time < float(t) else Color("#555"))
	_draw_skull(c, Vector2(rx, rtop - 16), 15.0, Color("#ff3d1f") if not run.boss_spawned else UIKit.GOLD)
	# ---------- Barra de XP (base, largura total)
	var xp_ratio := clampf(run.xp / run.xp_next, 0.0, 1.0)
	var bar := Rect2(16, size.y - 26, size.x - 32, 14)
	c.draw_rect(bar, Color(UIKit.INK, 0.85))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * xp_ratio, bar.size.y)), Color("#5fe0a0"))
	c.draw_rect(bar, UIKit.INK, false, 2.0)
	# ---------- Vida do chefe
	if run.boss and not run.boss.dead and run.boss_spawned:
		var bw := minf(620.0, size.x - (80.0 if portrait else 400.0))
		var br := Rect2(size.x * 0.5 - bw * 0.5, 150.0 if portrait else 122.0, bw, 18)
		c.draw_rect(br, Color(UIKit.INK, 0.9))
		c.draw_rect(Rect2(br.position, Vector2(bw * run.boss.hp_ratio(), 18)), Color("#c2412d"))
		c.draw_rect(br, UIKit.GOLD, false, 2.0)
		_text(c, font, br.position + Vector2(0, -6), "%s  —  %d" % [run.region["chefe"]["nome"], ceili(run.boss.hp)], bw, 16)


func _text(c: Control, font: Font, p: Vector2, txt: String, w: float, fs: int) -> void:
	c.draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 5, UIKit.INK)
	c.draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, UIKit.CREAM)


func _draw_skull(c: Control, p: Vector2, r: float, color: Color) -> void:
	c.draw_circle(p, r + 2, UIKit.INK)
	c.draw_circle(p, r, color)
	c.draw_rect(Rect2(p.x - r * 0.55, p.y + r * 0.4, r * 1.1, r * 0.7), color)
	c.draw_circle(p + Vector2(-r * 0.38, -r * 0.05), r * 0.27, UIKit.INK)
	c.draw_circle(p + Vector2(r * 0.38, -r * 0.05), r * 0.27, UIKit.INK)


func banner(title: String, sub: String, duration := 2.0) -> void:
	_banner_title.text = title
	_banner_sub.text = sub
	_banner_time = duration
	_banner.modulate.a = 1.0


func toast(msg: String) -> void:
	var l := UIKit.label(msg, 20, UIKit.CREAM, 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_box.add_child(l)
	while _toast_box.get_child_count() > 4:
		var old := _toast_box.get_child(0)
		_toast_box.remove_child(old)
		old.queue_free()
	var tw := l.create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func flash_damage() -> void:
	_flash.color.a = 0.35


func _set_speed(i: int) -> void:
	_speed_index = i
	if not run.game_over:
		Engine.time_scale = SPEEDS[i]
	_speed_button.text = RITMOS[i]


func cycle_speed() -> void:
	_set_speed((_speed_index + 1) % SPEEDS.size())


# ---------------------------------------------------------------- pausa

func _build_pause() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.visible = false
	_root.add_child(_pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(center)
	var p := UIKit.panel()
	center.add_child(p)
	var v := UIKit.vbox(12)
	p.add_child(v)
	var t := UIKit.label("PAUSA", 40, UIKit.GOLD, 8)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var help := UIKit.wrap_label(
		"Celular: arraste o dedo em qualquer lugar para mover. Toque no orbe para a habilidade.\nPC: A / D ou setas para mover, mouse para mirar, Espaço para a habilidade, T para a mira automática, Tab para a velocidade.", 17, UIKit.MUTED)
	help.custom_minimum_size.x = minf(440.0, _root.size.x - 80.0)
	v.add_child(help)
	v.add_child(UIKit.button("Continuar", toggle_pause, 26, 320))
	var som := UIKit.button("", func(): pass, 20, 320)
	som.text = "Som: LIGADO" if Sfx.enabled() else "Som: DESLIGADO"
	som.pressed.connect(func():
		Sfx.toggle()
		som.text = "Som: LIGADO" if Sfx.enabled() else "Som: DESLIGADO"
	)
	v.add_child(som)
	v.add_child(UIKit.button("Abandonar run", _abandon, 20, 320))


func toggle_pause() -> void:
	if run.game_over or run.levelup.is_open():
		return
	var p := not get_tree().paused
	get_tree().paused = p
	_pause_panel.visible = p


func _abandon() -> void:
	_pause_panel.visible = false
	get_tree().paused = false
	run.damage_player(99999.0)
