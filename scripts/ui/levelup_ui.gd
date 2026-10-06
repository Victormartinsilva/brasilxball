class_name LevelUpUI
extends CanvasLayer
## "Escolha 1 de 3": cartas de upgrade, passiva, fusão ou relíquia. Pausa o jogo enquanto aberta.

signal chosen(offer: Dictionary, context: String)

const TYPE_NAMES := {
	"nova_bola": "NOVA BOLA", "up_bola": "MELHORIA", "passiva": "PASSIVA",
	"fusao": "FUSÃO", "reliquia": "RELÍQUIA", "cura": "CURA",
}

var _root: Control
var _title: Label
var _subtitle: Label
var _cards: BoxContainer
var _reroll: Button
var _offers: Array = []
var _context := ""
var _build: RunBuild
var _open := false
var _opened_at := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UIKit.theme()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var v := UIKit.vbox(14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	_title = UIKit.label("", 46, UIKit.GOLD, 10)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_subtitle = UIKit.label("", 20, UIKit.CREAM, 4)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_subtitle)
	_cards = BoxContainer.new()
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_cards)
	var foot := UIKit.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(foot)
	_reroll = UIKit.button("Rerrolar", _do_reroll, 18, 200)
	foot.add_child(_reroll)


func is_open() -> bool:
	return _open


func open_choice(title: String, subtitle: String, offers: Array, build: RunBuild, context: String) -> void:
	_open = true
	_offers = offers
	_context = context
	_build = build
	_title.text = title
	_subtitle.text = subtitle
	_opened_at = Time.get_ticks_msec()
	_rebuild_cards()
	_root.visible = true
	get_tree().paused = true
	# Testes automatizados escolhem sozinhos.
	var run := get_parent() as Run
	if run and run.autoplay:
		_pick.call_deferred(0)


func _rebuild_cards() -> void:
	for c in _cards.get_children():
		c.queue_free()
	var vp := get_viewport().get_visible_rect().size
	var portrait := vp.x < vp.y
	_cards.vertical = portrait
	_title.add_theme_font_size_override("font_size", 36 if portrait else 46)
	for i in _offers.size():
		if portrait:
			_cards.add_child(_make_row_card(_offers[i], i, minf(680.0, vp.x - 24.0)))
		else:
			var card_w := clampf((vp.x - 120.0) / maxf(1.0, _offers.size()) - 16.0, 170.0, 260.0)
			_cards.add_child(_make_card(_offers[i], i, card_w))
	_reroll.visible = _context == "levelup" and _build.rerolls > 0
	_reroll.text = "Rerrolar (%d)" % _build.rerolls


func _card_shell(o: Dictionary, index: int, size: Vector2) -> PanelContainer:
	var rc := GameData.rarity_color(o.get("raridade", "comum"))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.box(Color("#1f1812"), rc, 3, 10, 14))
	card.custom_minimum_size = size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(ev: InputEvent):
		# Escolhe ao SOLTAR, e só se o toque começou nesta carta (evita escolher sem querer
		# quando o dedo ainda estava arrastando o personagem no momento em que a tela abriu).
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				card.set_meta("down", true)
			elif card.get_meta("down", false):
				_pick(index))
	card.mouse_entered.connect(func(): card.modulate = Color(1.15, 1.12, 1.05))
	card.mouse_exited.connect(func(): card.modulate = Color.WHITE)
	return card


func _level_text(o: Dictionary) -> String:
	var t: String = GameData.RARITY_NAMES.get(o.get("raridade", "comum"), "")
	match o["tipo"]:
		"up_bola":
			t += "  •  Nv %d → %d" % [int(o["nivel"]) - 1, int(o["nivel"])]
		"passiva":
			t += "  •  Nv %d" % int(o["nivel"])
	return t


## Celular em pé: carta larga (ícone à esquerda, texto à direita), uma embaixo da outra.
func _make_row_card(o: Dictionary, index: int, w: float) -> Control:
	var rc := GameData.rarity_color(o.get("raridade", "comum"))
	var card := _card_shell(o, index, Vector2(w, 140))
	var h := UIKit.hbox(14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(84, 0)
	h.add_child(icon_box)
	icon_box.add_child(UIKit.icon(o.get("cor", Color.WHITE), String(o["nome"]).substr(0, 1), 72.0))
	var v := UIKit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UIKit.label(TYPE_NAMES.get(o["tipo"], "") + "  ·  " + _level_text(o), 15, rc, 3))
	v.add_child(UIKit.label(o["nome"], 26, UIKit.CREAM, 5))
	var desc := UIKit.wrap_label(o.get("descricao", ""), 17, UIKit.CREAM)
	desc.custom_minimum_size.x = w - 140.0
	v.add_child(desc)
	return card


func _make_card(o: Dictionary, index: int, w: float) -> Control:
	var rc := GameData.rarity_color(o.get("raridade", "comum"))
	var card := _card_shell(o, index, Vector2(w, 340))
	var v := UIKit.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var head := UIKit.hbox(6)
	v.add_child(head)
	var tag := UIKit.label("[%d] %s" % [index + 1, TYPE_NAMES.get(o["tipo"], "")], 14, rc, 3)
	head.add_child(tag)
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(0, 86)
	v.add_child(icon_box)
	icon_box.add_child(UIKit.icon(o.get("cor", Color.WHITE), String(o["nome"]).substr(0, 1), 74.0))
	var title_l := UIKit.label(o["nome"], 22, UIKit.CREAM, 5)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title_l)
	var lv := UIKit.label(_level_text(o), 14, rc, 3)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lv)
	var desc := UIKit.wrap_label(o.get("descricao", ""), 15, UIKit.CREAM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var tags: Array = o.get("tags", [])
	if tags.size() > 0:
		var t := UIKit.label(" · ".join(tags.map(func(x): return String(x).to_upper())), 12, UIKit.MUTED, 2)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
	return card


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	for i in 4:
		if event.is_action_pressed("pick_%d" % (i + 1)) and i < _offers.size():
			_pick(i)
			get_viewport().set_input_as_handled()
			return


func _pick(index: int) -> void:
	if not _open or index >= _offers.size():
		return
	# Evita clique acidental no instante em que a tela abre.
	if Time.get_ticks_msec() - _opened_at < 400 and not (get_parent() as Run).autoplay:
		return
	var offer: Dictionary = _offers[index]
	_open = false
	_root.visible = false
	get_tree().paused = false
	chosen.emit(offer, _context)


func _do_reroll() -> void:
	if _build.rerolls <= 0:
		return
	_build.rerolls -= 1
	var run := get_parent() as Run
	_offers = _build.generate_offers(run.rng)
	_rebuild_cards()
