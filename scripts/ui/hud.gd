class_name Hud
extends CanvasLayer
## HUD inspirado nas referências: espada de vida + orbe de habilidade à esquerda,
## trilha de progresso com caveiras à direita, botões de velocidade no topo.

const SPEEDS := [1.0, 1.5, 2.0]

var run: Run
var _root: Control
var _draw_layer: Control
var _timer_label: Label
var _combo_label: Label
var _sucata_label: Label
var _level_label: Label
var _slots_box: HBoxContainer
var _passives_box: HBoxContainer
var _banner: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_time := 0.0
var _toast_box: VBoxContainer
var _flash: ColorRect
var _pause_panel: Control
var _speed_buttons: Array = []
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

	# Topo esquerdo: sucata e nível.
	var tl := UIKit.vbox(2)
	UIKit.place(tl, Vector2(0, 0), Vector2(22, 14))
	_root.add_child(tl)
	_sucata_label = UIKit.label("Sucata 0", 22, UIKit.GOLD)
	tl.add_child(_sucata_label)
	_level_label = UIKit.label("Nv 1", 20)
	tl.add_child(_level_label)

	# Topo centro: tempo e combo.
	var tc := UIKit.vbox(0)
	UIKit.place(tc, Vector2(0.5, 0), Vector2(-160, 8), Vector2(320, 0))
	tc.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(tc)
	_timer_label = UIKit.label("00:00", 26)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_timer_label)
	_combo_label = UIKit.label("", 30, UIKit.GOLD, 8)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(_combo_label)

	# Topo direito: velocidade + pausa.
	var tr := UIKit.hbox(4)
	UIKit.place(tr, Vector2(1, 0), Vector2(-244, 12), Vector2(230, 40))
	_root.add_child(tr)
	for i in SPEEDS.size():
		var b := UIKit.button(">".repeat(i + 1), _set_speed.bind(i), 18)
		b.custom_minimum_size = Vector2(52, 40)
		b.focus_mode = Control.FOCUS_NONE
		tr.add_child(b)
		_speed_buttons.append(b)
	var pb := UIKit.button("II", toggle_pause, 18)
	pb.custom_minimum_size = Vector2(46, 40)
	pb.focus_mode = Control.FOCUS_NONE
	tr.add_child(pb)

	# Base: build (slots de bola + passivas + relíquias).
	var bottom := UIKit.hbox(14)
	UIKit.place(bottom, Vector2(0, 1), Vector2(140, -84), Vector2(0, 56))
	_root.add_child(bottom)
	_slots_box = UIKit.hbox(6)
	bottom.add_child(_slots_box)
	_passives_box = UIKit.hbox(4)
	bottom.add_child(_passives_box)

	# Banner central.
	_banner = UIKit.vbox(0)
	UIKit.place(_banner, Vector2(0.5, 0.5), Vector2(-450, -190), Vector2(900, 0))
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_banner)
	_banner_title = UIKit.label("", 54, UIKit.GOLD, 12)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	_banner_sub = UIKit.label("", 22, UIKit.CREAM, 6)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_child(_banner_sub)
	_banner.modulate.a = 0.0

	_toast_box = UIKit.vbox(2)
	UIKit.place(_toast_box, Vector2(0.5, 1), Vector2(-350, -150), Vector2(700, 0))
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	_root.add_child(_toast_box)

	_build_pause()
	_set_speed(0)


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
		var ic := UIKit.icon(Color(b["cor"]), String(b["nome"]).substr(0, 1), 52.0, int(s["level"]))
		ic.tooltip_text = b["nome"]
		_slots_box.add_child(ic)
	for i in range(run.build.slots.size(), RunBuild.MAX_SLOTS):
		var empty := UIKit.icon(Color("#2a2420"), "+", 52.0)
		_slots_box.add_child(empty)
	for pid in run.build.passives:
		var p: Dictionary = GameData.passives[pid]
		_passives_box.add_child(UIKit.icon(Color(p["cor"]), String(p["nome"]).substr(0, 1), 34.0, int(run.build.passives[pid])))
	for rid in run.build.relics:
		var r: Dictionary = GameData.relics[rid]
		_passives_box.add_child(UIKit.icon(Color(r["cor"]), "R", 34.0))


func _draw_gauges() -> void:
	var c := _draw_layer
	var size := c.size
	var font := ThemeDB.fallback_font
	# ---------- Espada de vida (esquerda)
	var top := 120.0
	var bottom := size.y - 200.0
	var x := 74.0
	var blade := PackedVector2Array([Vector2(x - 14, bottom), Vector2(x - 14, top + 30), Vector2(x, top), Vector2(x + 14, top + 30), Vector2(x + 14, bottom)])
	c.draw_colored_polygon(blade, Color("#2a1d14"))
	var ratio := clampf(run.hp / run.max_hp, 0.0, 1.0)
	var fill_top := lerpf(bottom, top + 30, ratio)
	if ratio > 0.0:
		c.draw_rect(Rect2(x - 11, fill_top, 22, bottom - fill_top), Color("#c2412d").lerp(Color("#ff6b3d"), 0.5 + sin(Time.get_ticks_msec() / 300.0) * 0.2))
	c.draw_polyline(blade + PackedVector2Array([blade[0]]), UIKit.INK, 3.0)
	c.draw_line(Vector2(x, top + 8), Vector2(x, bottom), Color(1, 1, 1, 0.12), 2.0)
	c.draw_rect(Rect2(x - 34, bottom, 68, 12), Color("#8a5a3a"))
	c.draw_rect(Rect2(x - 34, bottom, 68, 12), UIKit.INK, false, 2.0)
	var hp_text := "%d" % ceili(run.hp)
	c.draw_string_outline(font, Vector2(x - 30, top - 10), hp_text, HORIZONTAL_ALIGNMENT_CENTER, 60, 20, 5, UIKit.INK)
	c.draw_string(font, Vector2(x - 30, top - 10), hp_text, HORIZONTAL_ALIGNMENT_CENTER, 60, 20, UIKit.CREAM)
	# ---------- Orbe de habilidade
	var orb := Vector2(x, bottom + 62)
	var ab: Dictionary = run.character["habilidade"]
	var is_ready := run.ability_cd <= 0.0
	var orb_color := Color(run.character["cor"]) if is_ready else Color(run.character["cor"]).darkened(0.6)
	c.draw_circle(orb, 46, UIKit.INK)
	c.draw_circle(orb, 42, Color("#8a5a3a"))
	c.draw_circle(orb, 34, orb_color)
	if run.ability_time > 0.0:
		c.draw_arc(orb, 40, 0, TAU, 40, Color("#fff3c4"), 3.0)
	if not is_ready:
		var frac := run.ability_cd / float(ab["recarga"])
		c.draw_arc(orb, 30, -PI / 2, -PI / 2 + TAU * (1.0 - frac), 32, UIKit.GOLD, 5.0)
		var cd := "%d" % ceili(run.ability_cd)
		c.draw_string_outline(font, orb + Vector2(-20, 8), cd, HORIZONTAL_ALIGNMENT_CENTER, 40, 22, 5, UIKit.INK)
		c.draw_string(font, orb + Vector2(-20, 8), cd, HORIZONTAL_ALIGNMENT_CENTER, 40, 22, UIKit.CREAM)
	else:
		c.draw_circle(orb + Vector2(-10, -10), 9, Color(1, 1, 1, 0.4))
	for li in 2:
		var txt: String = String(ab["nome"]) if li == 0 else "[Espaço]"
		var tp := orb + Vector2(-60, 64 + li * 15)
		c.draw_string_outline(font, tp, txt, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, 4, UIKit.INK)
		c.draw_string(font, tp, txt, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, UIKit.CREAM if li == 0 else UIKit.MUTED)
	# ---------- Trilha de progresso com caveiras (direita)
	var rx := size.x - 46.0
	var rtop := 80.0
	var rbot := size.y - 110.0
	c.draw_rect(Rect2(rx - 9, rtop, 18, rbot - rtop), Color("#2a1d14"))
	var boss_t := float(run.region["tempo_chefe"])
	var prog := clampf(run.time / boss_t, 0.0, 1.0)
	c.draw_rect(Rect2(rx - 6, lerpf(rbot, rtop, prog), 12, (rbot - rtop) * prog), Color("#8a5a3a").lerp(UIKit.GOLD, prog))
	c.draw_rect(Rect2(rx - 9, rtop, 18, rbot - rtop), UIKit.INK, false, 2.0)
	for t in run.region.get("eventos_feira", []):
		var fy := lerpf(rbot, rtop, float(t) / boss_t)
		_draw_skull(c, Vector2(rx, fy), 11.0, UIKit.TEAL if run.time < float(t) else Color("#555"))
	_draw_skull(c, Vector2(rx, rtop - 18), 17.0, Color("#ff3d1f") if not run.boss_spawned else UIKit.GOLD)
	# ---------- Barra de XP (base)
	var xp_ratio := clampf(run.xp / run.xp_next, 0.0, 1.0)
	var bar := Rect2(140, size.y - 20, size.x - 280, 10)
	c.draw_rect(bar, Color(UIKit.INK, 0.85))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * xp_ratio, bar.size.y)), Color("#5fe0a0"))
	c.draw_rect(bar, UIKit.INK, false, 2.0)
	# ---------- Vida do chefe (topo)
	if run.boss and not run.boss.dead and run.boss_spawned:
		var bw := minf(620.0, size.x - 400.0)
		var br := Rect2(size.x * 0.5 - bw * 0.5, 122, bw, 18)
		c.draw_rect(br, Color(UIKit.INK, 0.9))
		c.draw_rect(Rect2(br.position, Vector2(bw * run.boss.hp_ratio(), 18)), Color("#c2412d"))
		c.draw_rect(br, UIKit.GOLD, false, 2.0)
		var bn := "%s  —  %d" % [run.region["chefe"]["nome"], ceili(run.boss.hp)]
		c.draw_string_outline(font, br.position + Vector2(0, -6), bn, HORIZONTAL_ALIGNMENT_CENTER, bw, 16, 4, UIKit.INK)
		c.draw_string(font, br.position + Vector2(0, -6), bn, HORIZONTAL_ALIGNMENT_CENTER, bw, 16, UIKit.CREAM)


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
	for j in _speed_buttons.size():
		var b: Button = _speed_buttons[j]
		b.modulate = Color.WHITE if j == i else Color(1, 1, 1, 0.45)


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
		"A / D ou setas: mover\nMouse: mirar  •  Clique e segure: mover até o cursor\nEspaço ou botão direito: habilidade\nT: mira automática  •  Tab: velocidade  •  1-4: escolher upgrade", 16, UIKit.MUTED)
	help.custom_minimum_size.x = 460
	v.add_child(help)
	v.add_child(UIKit.button("Continuar", toggle_pause, 22, 320))
	v.add_child(UIKit.button("Abandonar run", _abandon, 18, 320))


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
