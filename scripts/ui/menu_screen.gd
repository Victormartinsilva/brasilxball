class_name MenuScreen
extends CanvasLayer
## Tela de título. Mobile-first: coluna centralizada e botões grandes; no PC a coluna fica à esquerda.

signal play_pressed

var _root: Control
var _col: VBoxContainer
var _help: Control
var _title: Label
var _sub: Label


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UIKit.theme()
	add_child(_root)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)

	_col = UIKit.vbox(14)
	_root.add_child(_col)
	_title = UIKit.label("BALL\nx BRASIL", 92, UIKit.GOLD, 16)
	_col.add_child(_title)
	_sub = UIKit.label("Quebre. Ricocheteie. Evolua.\nConquiste o Brasil.", 24, UIKit.CREAM, 5)
	_col.add_child(_sub)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	_col.add_child(spacer)
	var play := UIKit.button("JOGAR", func(): play_pressed.emit(), 34)
	play.custom_minimum_size.y = 84
	_col.add_child(play)
	_col.add_child(UIKit.button("Como jogar", func(): _help.visible = true, 22))
	var som := UIKit.button("", func(): pass, 22)
	som.text = "Som: LIGADO" if Sfx.enabled() else "Som: DESLIGADO"
	som.pressed.connect(func():
		Sfx.toggle()
		som.text = "Som: LIGADO" if Sfx.enabled() else "Som: DESLIGADO"
	)
	_col.add_child(som)
	if OS.has_feature("web") and GameData.is_mobile():
		_col.add_child(UIKit.button("Tela cheia", _fullscreen, 22))

	var ver := UIKit.label("Protótipo v0.2 — Vertical slice: São Paulo", 15, UIKit.MUTED, 3)
	UIKit.place(ver, Vector2(0, 1), Vector2(20, -36))
	_root.add_child(ver)

	_build_help()
	_root.resized.connect(_layout)
	_layout()


func _layout() -> void:
	var s := _root.size
	var portrait := s.x < s.y
	var w := minf(s.x - 48.0, 560.0)
	if portrait:
		UIKit.place(_col, Vector2(0.5, 0.5), Vector2(-w * 0.5, 40), Vector2(w, 0))
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		UIKit.place(_col, Vector2(0, 0.5), Vector2(64, 0), Vector2(520, 0))
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _build_help() -> void:
	_help = Control.new()
	_help.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help.visible = false
	_root.add_child(_help)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_help.add_child(center)
	var p := UIKit.panel()
	center.add_child(p)
	var hv := UIKit.vbox(10)
	hv.custom_minimum_size.x = minf(560.0, get_viewport().get_visible_rect().size.x - 60.0)
	p.add_child(hv)
	hv.add_child(UIKit.label("COMO JOGAR", 30, UIKit.GOLD, 6))
	for line in [
		"As bolas são disparadas sozinhas e ricocheteiam nas paredes e nos inimigos.",
		"Não deixe os inimigos chegarem à faixa de pedestres!",
		"Colete gemas para subir de nível e escolher 1 de 3 melhorias.",
		"Duas bolas no nível 3 podem virar uma FUSÃO.",
		"",
		"CELULAR: arraste o dedo em qualquer lugar da tela para mover.",
		"A mira é automática; toque em \"Mira\" para mirar com o dedo.",
		"Toque no orbe (canto inferior direito) para a habilidade.",
		"",
		"PC: A / D ou setas para mover, mouse para mirar, Espaço para a habilidade.",
	]:
		hv.add_child(UIKit.wrap_label(line, 18))
	hv.add_child(UIKit.button("Entendi", func(): _help.visible = false, 24))
