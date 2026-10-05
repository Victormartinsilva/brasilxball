class_name MenuScreen
extends CanvasLayer
## Tela de título.

signal play_pressed

var _help: Control


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UIKit.theme()
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var col := UIKit.vbox(10)
	UIKit.place(col, Vector2(0, 0.5), Vector2(64, 0), Vector2(520, 0))
	root.add_child(col)
	var t1 := UIKit.label("BALL", 92, UIKit.GOLD, 16)
	col.add_child(t1)
	var t2 := UIKit.label("x BRASIL", 64, UIKit.CREAM, 14)
	col.add_child(t2)
	col.add_child(UIKit.label("Quebre. Ricocheteie. Evolua. Conquiste o Brasil.", 20, UIKit.CREAM, 5))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	col.add_child(spacer)
	col.add_child(UIKit.button("JOGAR", func(): play_pressed.emit(), 28, 300))
	col.add_child(UIKit.button("Como jogar", func(): _help.visible = not _help.visible, 20, 300))
	var ver := UIKit.label("Protótipo v0.1 — Vertical slice: São Paulo", 14, UIKit.MUTED, 3)
	UIKit.place(ver, Vector2(0, 1), Vector2(20, -34))
	root.add_child(ver)

	_help = UIKit.panel()
	UIKit.place(_help, Vector2(1, 0.5), Vector2(-520, -220), Vector2(470, 0))
	_help.visible = false
	root.add_child(_help)
	var hv := UIKit.vbox(8)
	_help.add_child(hv)
	hv.add_child(UIKit.label("COMO JOGAR", 26, UIKit.GOLD, 6))
	for line in [
		"As bolas são disparadas automaticamente na direção da mira.",
		"Elas ricocheteiam nas paredes e nos inimigos e voltam para você.",
		"Não deixe os inimigos chegarem à faixa de pedestres!",
		"Colete gemas para subir de nível e escolher 1 de 3 melhorias.",
		"Duas bolas no nível 3 podem virar uma FUSÃO.",
		"",
		"A / D ou setas: mover   •   Mouse: mirar",
		"Clique e segure: andar até o cursor (toque no celular)",
		"Espaço / botão direito: habilidade   •   T: mira automática",
		"Tab ou botões > >> >>>: velocidade   •   Esc: pausa",
	]:
		hv.add_child(UIKit.wrap_label(line, 16))
