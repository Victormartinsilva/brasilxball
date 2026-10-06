extends Node
## Carrega todo o conteúdo orientado a dados (data/*.json) e registra os controles.
## Adicionar uma bola, passiva ou inimigo novo = editar o JSON, não o código.

const RARITY_ORDER := ["comum", "incomum", "rara", "epica", "lendaria"]
const RARITY_NAMES := {
	"comum": "Comum", "incomum": "Incomum", "rara": "Rara", "epica": "Épica", "lendaria": "Lendária",
}
const RARITY_COLORS := {
	"comum": Color("#c9c2b3"), "incomum": Color("#5fe0a0"), "rara": Color("#4fa8ff"),
	"epica": Color("#c46bff"), "lendaria": Color("#ffb02e"),
}
const ELEMENT_COLORS := {
	"fogo": Color("#ff7a1f"), "gelo": Color("#7fe3ff"), "veneno": Color("#7bd94a"), "raio": Color("#ffe14a"),
}
const ELEMENT_NAMES := {"fogo": "Fogo", "gelo": "Gelo", "veneno": "Veneno", "raio": "Raio"}

var balls: Dictionary = {}
var enemies: Dictionary = {}
var passives: Dictionary = {}
var relics: Dictionary = {}
var characters: Dictionary = {}
var regions: Dictionary = {}
var character_order: Array = []
var region_order: Array = []
var fusion_ids: Array = []


func _ready() -> void:
	balls = _load_indexed("res://data/balls.json")
	enemies = _load_indexed("res://data/enemies.json")
	passives = _load_indexed("res://data/passives.json")
	relics = _load_indexed("res://data/relics.json")
	characters = _load_indexed("res://data/characters.json", character_order)
	regions = _load_indexed("res://data/regions.json", region_order)
	for id in balls:
		if balls[id].has("componentes"):
			fusion_ids.append(id)
	_setup_input()
	get_tree().root.size_changed.connect(_adapt_orientation)
	_adapt_orientation()
	if is_mobile():
		# GPU de celular + tela de alta densidade: renderiza o 3D em resolução menor.
		get_tree().root.scaling_3d_scale = 0.7
		get_tree().root.msaa_3d = Viewport.MSAA_DISABLED


## Celular em pé: a UI passa a ser desenhada numa base 540x960 para não ficar minúscula.
func _adapt_orientation() -> void:
	var root := get_tree().root
	var s := root.size
	if s.y <= 0:
		return
	var portrait := float(s.x) / float(s.y) < 0.9
	root.content_scale_size = Vector2i(540, 960) if portrait else Vector2i(1280, 720)


## Celular/tablet (navegador ou nativo). Usado para controles, qualidade gráfica e layout.
func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile") \
		or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())


func is_portrait() -> bool:
	var s := get_tree().root.size
	return s.y > 0 and float(s.x) / float(s.y) < 0.9


func _load_indexed(path: String, order: Array = []) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Não foi possível abrir %s" % path)
		return out
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("JSON inválido em %s" % path)
		return out
	for item in parsed:
		out[item["id"]] = item
		order.append(item["id"])
	return out


func is_fusion(ball_id: String) -> bool:
	return balls.get(ball_id, {}).has("componentes")


func rarity_color(r: String) -> Color:
	return RARITY_COLORS.get(r, Color.WHITE)


func color_of(item: Dictionary, fallback := Color.WHITE) -> Color:
	if item.has("cor"):
		return Color(item["cor"])
	return fallback


func passive_text(id: String, level: int) -> String:
	var p: Dictionary = passives[id]
	var vals: Array = p["valores"]
	var v = vals[clampi(level - 1, 0, vals.size() - 1)]
	return String(p["descricao"]).replace("{v}", str(v))


func passive_value(id: String, level: int) -> float:
	if level <= 0:
		return 0.0
	var vals: Array = passives[id]["valores"]
	return float(vals[clampi(level - 1, 0, vals.size() - 1)])


func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("ability", [KEY_SPACE, KEY_E])
	_add_keys("pause", [KEY_ESCAPE, KEY_P])
	_add_keys("speed_toggle", [KEY_TAB])
	_add_keys("pick_1", [KEY_1])
	_add_keys("pick_2", [KEY_2])
	_add_keys("pick_3", [KEY_3])
	_add_keys("pick_4", [KEY_4])
	if not InputMap.has_action("ability_mouse"):
		InputMap.add_action("ability_mouse")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("ability_mouse", mb)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
