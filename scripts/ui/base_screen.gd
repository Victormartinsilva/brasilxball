class_name BaseScreen
extends CanvasLayer
## O Acampamento: Expedição (mapa + personagem), Oficina, Laboratório, Arsenal, Relicário e Registros.

signal start_run(char_id: String, region_id: String)
signal back

var _root: Control
var _sucata: Label
var _tabs: TabContainer
var _selected_char := "guardiao"
var _selected_region := "sao_paulo"
var _char_cards: Dictionary = {}
var _map: Control
var _region_info: Label
var _char_detail: VBoxContainer


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UIKit.theme()
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12 if GameData.is_portrait() else 24)
	_root.add_child(margin)
	var v := UIKit.vbox(10)
	margin.add_child(v)

	var top := UIKit.hbox(16)
	v.add_child(top)
	top.add_child(UIKit.button("< Menu", func(): back.emit(), 16))
	top.add_child(UIKit.label("ACAMPAMENTO", 24 if GameData.is_portrait() else 34, UIKit.GOLD, 8))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_sucata = UIKit.label("", 26, UIKit.GOLD, 6)
	top.add_child(_sucata)

	_tabs = TabContainer.new()
	_tabs.clip_tabs = true  # no celular as abas rolam em vez de alargar a tela
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_tabs)
	_tabs.add_theme_font_size_override("font_size", 15 if GameData.is_portrait() else 17)
	_build_expedition()
	_build_map()
	_build_workshop()
	_build_lab()
	_build_arsenal()
	_build_reliquary()
	_build_records()
	_refresh()


func _refresh() -> void:
	_sucata.text = "Sucata: %d" % Save.sucata()


func _rebuild_tab(index: int) -> void:
	var current := _tabs.current_tab
	var old := _tabs.get_child(index)
	var builders := [_build_expedition, _build_map, _build_workshop, _build_lab, _build_arsenal, _build_reliquary, _build_records]
	_tabs.remove_child(old)
	old.queue_free()
	builders[index].call()
	_tabs.move_child(_tabs.get_child(_tabs.get_child_count() - 1), index)
	_tabs.current_tab = current
	_refresh()


func _scroll_tab(title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(sc)
	var v := UIKit.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


# ---------------------------------------------------------------- JOGAR (personagem + início)

func _build_expedition() -> void:
	var v := UIKit.vbox(12)
	v.name = "Jogar"
	_tabs.add_child(v)
	var reg: Dictionary = GameData.regions[_selected_region]
	var region_btn := UIKit.button("Região: %s  (ver mapa)" % reg["nome"], func(): _tabs.current_tab = 1, 18)
	v.add_child(region_btn)
	v.add_child(UIKit.label("ESCOLHA SEU PERSONAGEM", 22, UIKit.GOLD, 4))
	var chips := UIKit.hbox(10)
	v.add_child(chips)
	_char_cards.clear()
	for cid in GameData.character_order:
		var card := _character_chip(GameData.characters[cid])
		chips.add_child(card)
		_char_cards[cid] = card
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_char_detail = UIKit.vbox(6)
	_char_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_char_detail)
	var go := UIKit.button("INICIAR RUN", func(): start_run.emit(_selected_char, _selected_region), 32)
	go.custom_minimum_size.y = 88
	v.add_child(go)
	_select_char(_selected_char)


## Ficha compacta e grande para o dedo: ícone + nome + arquétipo.
func _character_chip(c: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 150
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_char(c["id"]))
	var v := UIKit.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var ic := CenterContainer.new()
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(UIKit.portrait(c, 96.0))
	v.add_child(ic)
	var n := UIKit.label(c["nome"], 18, UIKit.CREAM, 5)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	return card


func _fill_detail(c: Dictionary) -> void:
	for ch in _char_detail.get_children():
		ch.queue_free()
	var ball: Dictionary = GameData.balls[c["bola_inicial"]]
	var big := CenterContainer.new()
	big.add_child(UIKit.portrait(c, 220.0))
	_char_detail.add_child(big)
	_char_detail.add_child(UIKit.wrap_label("%s — %s" % [c["nome"], c["arquetipo"]], 21, Color(c["cor"]).lightened(0.3)))
	_char_detail.add_child(UIKit.wrap_label("Vida %d  •  Velocidade %.1f  •  Bola inicial: %s" % [int(c["vida"]), float(c["velocidade"]), ball["nome"]], 17))
	_char_detail.add_child(UIKit.label("Passiva — " + String(c["passiva"]["nome"]), 19, UIKit.GOLD, 3))
	_char_detail.add_child(UIKit.wrap_label(c["passiva"]["descricao"], 17))
	_char_detail.add_child(UIKit.label("Habilidade — " + String(c["habilidade"]["nome"]), 19, UIKit.TEAL, 3))
	_char_detail.add_child(UIKit.wrap_label(c["habilidade"]["descricao"], 17))
	_char_detail.add_child(UIKit.wrap_label(c["estilo"], 17, UIKit.MUTED))


func _select_char(cid: String) -> void:
	_selected_char = cid
	for id in _char_cards:
		var card: PanelContainer = _char_cards[id]
		var on: bool = id == cid
		var col := Color(GameData.characters[id]["cor"])
		card.add_theme_stylebox_override("panel", UIKit.box(Color("#241a12") if on else Color("#17110c"), col if on else Color(col, 0.3), 4 if on else 1, 10, 10))
	_fill_detail(GameData.characters[cid])


# ---------------------------------------------------------------- MAPA

func _build_map() -> void:
	var map_panel := UIKit.panel(Color("#16241a"), Color("#3d8048"))
	map_panel.name = "Mapa"
	_tabs.add_child(map_panel)
	var mv := UIKit.vbox(6)
	map_panel.add_child(mv)
	mv.add_child(UIKit.label("MAPA DO BRASIL", 22, UIKit.GOLD, 4))
	_map = Control.new()
	_map.custom_minimum_size = Vector2(300, 300)
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_map_input)
	mv.add_child(_map)
	_region_info = UIKit.wrap_label("", 17)
	mv.add_child(_region_info)
	_update_region_info()


func _map_points() -> Dictionary:
	var pts := {}
	var s := _map.size
	for rid in GameData.region_order:
		var m: Dictionary = GameData.regions[rid]["mapa"]
		pts[rid] = Vector2(float(m["x"]) * s.x, float(m["y"]) * s.y)
	return pts


func _draw_map() -> void:
	var s := _map.size
	# Silhueta estilizada do Brasil.
	var outline := PackedVector2Array()
	var shape := [Vector2(0.30, 0.10), Vector2(0.55, 0.06), Vector2(0.70, 0.15), Vector2(0.92, 0.27), Vector2(0.95, 0.36),
		Vector2(0.86, 0.50), Vector2(0.80, 0.70), Vector2(0.68, 0.84), Vector2(0.52, 0.97), Vector2(0.40, 0.88),
		Vector2(0.44, 0.76), Vector2(0.30, 0.62), Vector2(0.18, 0.52), Vector2(0.06, 0.40), Vector2(0.10, 0.22)]
	for p in shape:
		outline.append(Vector2(p.x * s.x, p.y * s.y))
	_map.draw_colored_polygon(outline, Color("#2f6b3a"))
	outline.append(outline[0])
	_map.draw_polyline(outline, UIKit.INK, 3.0)
	var pts := _map_points()
	var links := [["amazonia", "nordeste"], ["nordeste", "minas"], ["amazonia", "pantanal"], ["pantanal", "minas"],
		["minas", "sao_paulo"], ["sao_paulo", "rio"], ["sao_paulo", "iguacu"]]
	for l in links:
		if pts.has(l[0]) and pts.has(l[1]):
			_map.draw_line(pts[l[0]], pts[l[1]], Color(UIKit.GOLD, 0.5), 3.0)
	var font := ThemeDB.fallback_font
	for rid in pts:
		var reg: Dictionary = GameData.regions[rid]
		var playable: bool = reg.get("jogavel", false)
		var p: Vector2 = pts[rid]
		var r := 13.0 if rid == _selected_region else 9.0
		_map.draw_circle(p, r + 3, UIKit.INK)
		_map.draw_circle(p, r, UIKit.GOLD if playable else Color("#6b6158"))
		var nm: String = reg["nome"]
		_map.draw_string_outline(font, p + Vector2(-60, -16), nm, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, 4, UIKit.INK)
		_map.draw_string(font, p + Vector2(-60, -16), nm, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, UIKit.CREAM if playable else UIKit.MUTED)


func _map_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	var pts := _map_points()
	for rid in pts:
		if ev.position.distance_to(pts[rid]) < 22.0:
			if GameData.regions[rid].get("jogavel", false):
				_selected_region = rid
			_update_region_info(rid)
			_map.queue_redraw()
			return


func _update_region_info(rid := "") -> void:
	if rid == "":
		rid = _selected_region
	var reg: Dictionary = GameData.regions[rid]
	var txt := "%s — %s\nRecurso regional: %s" % [reg["nome"], reg.get("subtitulo", ""), reg.get("recurso", "-")]
	if reg.get("jogavel", false):
		txt += "\nChefe: %s" % reg["chefe"]["nome"]
	else:
		txt += "\n(Em breve — próximas regiões do roadmap)"
	_region_info.text = txt


# ---------------------------------------------------------------- OFICINA (bolas)

func _build_workshop() -> void:
	var v := _scroll_tab("Oficina")
	v.add_child(UIKit.label("Bolas descobertas entram no sorteio das runs.", 16, UIKit.MUTED, 2))
	var grid := GridContainer.new()
	grid.columns = 1 if GameData.is_portrait() else 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for bid in GameData.balls:
		if GameData.is_fusion(bid):
			continue
		var b: Dictionary = GameData.balls[bid]
		var owned := Save.has_ball(bid)
		var row := _item_row(Color(b["cor"]), b["nome"], "%s  •  %s" % [GameData.RARITY_NAMES[b["raridade"]], " · ".join(b["tags"])], b["descricao"])
		if owned:
			row.add_child(UIKit.label("Desbloqueada", 15, UIKit.TEAL, 3))
		else:
			var cost := int(b["custo"])
			var on_buy := func():
				if Save.unlock("bolas", bid, cost):
					_rebuild_tab(2)
			var btn := UIKit.button("Fabricar (%d)" % cost, on_buy, 15)
			btn.disabled = Save.sucata() < cost
			row.add_child(btn)
		grid.add_child(row)


func _item_row(color: Color, title: String, sub: String, desc: String) -> HBoxContainer:
	var row := UIKit.hbox(10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(UIKit.icon(color, title.substr(0, 1), 46.0))
	var tv := UIKit.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tv)
	tv.add_child(UIKit.label(title, 18, UIKit.CREAM, 4))
	tv.add_child(UIKit.wrap_label(sub, 13, UIKit.MUTED))
	var d := UIKit.wrap_label(desc, 13)
	d.custom_minimum_size.x = 200
	tv.add_child(d)
	return row


# ---------------------------------------------------------------- LABORATÓRIO (fusões)

func _build_lab() -> void:
	var v := _scroll_tab("Panela")
	v.add_child(UIKit.label("PANELA DE PRESSÃO", 22, UIKit.GOLD, 4))
	v.add_child(UIKit.wrap_label("Receitas: tenha as duas bolas no nível %d na mesma run e a receita aparece no level up." % RunBuild.FUSION_MIN_LEVEL, 16, UIKit.MUTED))
	for fid in GameData.fusion_ids:
		var f: Dictionary = GameData.balls[fid]
		var known: bool = Save.has_fusion(fid)
		var alts: Array = []
		for pair in GameData.recipes(fid):
			alts.append(" + ".join(pair.map(func(id): return String(GameData.balls[id]["nome"]))))
		var row := _item_row(Color(f["cor"]), f["nome"], GameData.RARITY_NAMES[f["raridade"]] + "  •  " + "  ou  ".join(alts), f["descricao"])
		v.add_child(row)
		if known:
			row.add_child(UIKit.label("Pronta", 15, UIKit.TEAL, 3))
		else:
			var cost: int = Save.FUSION_COSTS.get(fid, 100)
			var on_buy := func():
				if Save.unlock("fusoes", fid, cost):
					_rebuild_tab(3)
			var btn := UIKit.button("Aprender (%d)" % cost, on_buy, 15)
			btn.disabled = Save.sucata() < cost
			row.add_child(btn)


# ---------------------------------------------------------------- ARSENAL

func _build_arsenal() -> void:
	var v := _scroll_tab("Arsenal")
	v.add_child(UIKit.label("Melhorias permanentes para todos os personagens.", 16, UIKit.MUTED, 2))
	for uid in Save.UPGRADES:
		var u: Dictionary = Save.UPGRADES[uid]
		var lv := Save.upgrade_level(uid)
		var mx := int(u["max"])
		var row := _item_row(UIKit.GOLD, u["nome"], "Nível %d / %d" % [lv, mx], u["descricao"])
		v.add_child(row)
		if lv >= mx:
			row.add_child(UIKit.label("Máximo", 15, UIKit.TEAL, 3))
		else:
			var cost := Save.upgrade_cost(uid)
			var on_buy := func():
				if Save.buy_upgrade(uid):
					_rebuild_tab(4)
			var btn := UIKit.button("Melhorar (%d)" % cost, on_buy, 15)
			btn.disabled = Save.sucata() < cost
			row.add_child(btn)


# ---------------------------------------------------------------- RELICÁRIO

func _build_reliquary() -> void:
	var v := _scroll_tab("Relíquias")
	v.add_child(UIKit.label("Relíquias liberadas aparecem nas Feiras durante a run.", 16, UIKit.MUTED, 2))
	for rid in GameData.relics:
		var r: Dictionary = GameData.relics[rid]
		var legendary: bool = r["raridade"] == "lendaria"
		var discovered: bool = not legendary or Save.data["descobertas"].has(rid)
		var title: String = r["nome"] if discovered else "???"
		var desc: String = r["descricao"] if discovered else "Derrote um chefe para descobrir esta relíquia."
		var row := _item_row(Color(r["cor"]) if discovered else Color("#444"), title, GameData.RARITY_NAMES[r["raridade"]], desc)
		v.add_child(row)
		if Save.has_relic(rid):
			row.add_child(UIKit.label("No relicário", 15, UIKit.TEAL, 3))
		elif discovered:
			var cost := int(r["custo"])
			var on_buy := func():
				if Save.unlock("reliquias", rid, cost):
					_rebuild_tab(5)
			var btn := UIKit.button("Resgatar (%d)" % cost, on_buy, 15)
			btn.disabled = Save.sucata() < cost
			row.add_child(btn)


# ---------------------------------------------------------------- REGISTROS

func _build_records() -> void:
	var v := _scroll_tab("Registros")
	var s: Dictionary = Save.data["stats"]
	var lines := [
		"Runs jogadas: %d" % int(s["runs"]),
		"Vitórias: %d" % int(s["vitorias"]),
		"Inimigos derrotados: %d" % int(s["abates"]),
		"Melhor combo: %d" % int(s["melhor_combo"]),
		"Melhor tempo contra o chefe: %s" % (UIKit.format_time(float(s["melhor_tempo"])) if float(s["melhor_tempo"]) > 0.0 else "-"),
	]
	for l in lines:
		v.add_child(UIKit.label(l, 20, UIKit.CREAM, 4))
	var reacts: Array = Save.data["descobertas"].filter(func(x): return String(x).begins_with("reacao_"))
	v.add_child(UIKit.label("Reações descobertas: %d / %d" % [reacts.size(), Run.REACTIONS.size()], 20, UIKit.GOLD, 4))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	v.add_child(spacer)
	var on_reset := func():
		Save.reset()
		_rebuild_tab(6)
	var reset := UIKit.button("Apagar progresso", on_reset, 14)
	reset.custom_minimum_size.x = 220
	v.add_child(reset)
