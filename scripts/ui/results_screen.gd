class_name ResultsScreen
extends CanvasLayer
## Fim de run: "perdi a run, mas minha próxima tentativa será melhor."

signal done

var _result: Dictionary


func setup(result: Dictionary) -> void:
	_result = result


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UIKit.theme()
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.03, 0.02, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := UIKit.panel()
	center.add_child(p)
	var v := UIKit.vbox(10)
	v.custom_minimum_size.x = minf(560.0, get_viewport().get_visible_rect().size.x - 60.0)
	p.add_child(v)

	var win: bool = _result.get("vitoria", false)
	var title := UIKit.label("VITÓRIA!" if win else "FIM DA RUN", 52, UIKit.GOLD if win else UIKit.RED, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var quote := "São Paulo agradece. O trânsito, nem tanto." if win else "Perdi a run, mas a próxima tentativa vai ser melhor."
	var q := UIKit.label(quote, 18, UIKit.CREAM, 4)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	v.add_child(grid)
	var ch: Dictionary = GameData.characters.get(_result.get("personagem", ""), {})
	var rows := [
		["Personagem", ch.get("nome", "-")],
		["Tempo", UIKit.format_time(float(_result.get("tempo", 0.0)))],
		["Nível", str(_result.get("nivel", 1))],
		["Abates", str(_result.get("abates", 0))],
		["Melhor combo", str(_result.get("melhor_combo", 0))],
		["Reações elementais", str(_result.get("reacoes", 0))],
	]
	for r in rows:
		grid.add_child(UIKit.label(r[0], 18, UIKit.MUTED, 3))
		grid.add_child(UIKit.label(r[1], 18, UIKit.CREAM, 3))

	v.add_child(UIKit.label("Build final", 20, UIKit.GOLD, 4))
	var build_row := UIKit.hbox(6)
	v.add_child(build_row)
	for s in _result.get("bolas", []):
		var b: Dictionary = GameData.balls[s["id"]]
		build_row.add_child(UIKit.icon(Color(b["cor"]), String(b["nome"]).substr(0, 1), 46.0, int(s["nivel"])))
	var passives: Dictionary = _result.get("passivas", {})
	for pid in passives:
		var pd: Dictionary = GameData.passives[pid]
		build_row.add_child(UIKit.icon(Color(pd["cor"]), String(pd["nome"]).substr(0, 1), 34.0, int(passives[pid])))
	for rid in _result.get("reliquias", []):
		build_row.add_child(UIKit.icon(Color(GameData.relics[rid]["cor"]), "R", 34.0))

	var reward := UIKit.label("+%d de Sucata" % int(_result.get("sucata", 0)), 30, UIKit.GOLD, 8)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(reward)
	if not win:
		var note := UIKit.label("(derrota: você manteve 60% da sucata da run)", 14, UIKit.MUTED, 2)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(note)
	v.add_child(UIKit.button("Voltar ao Acampamento", func(): done.emit(), 22))
