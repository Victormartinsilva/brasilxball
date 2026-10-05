class_name Enemy
extends Node3D
## Inimigo da grade. Hitbox 2D = retângulo (pos ± half). Estados elementais vivem aqui.

signal died(enemy: Enemy)

var data: Dictionary
var id := ""
var pos := Vector2.ZERO
var half := Vector2(0.42, 0.42)
var hp := 10.0
var max_hp := 10.0
var xp := 1
var contact_damage := 5.0
var behavior := "basico"
var is_elite := false
var is_boss := false
var dead := false
var armor_hits := 0

# Estados elementais
var burn_time := 0.0
var burn_dps := 0.0
var chill_time := 0.0
var chill_stacks := 0
var frozen_time := 0.0
var poison_time := 0.0
var poison_stacks := 0
var poison_dps_per_stack := 1.0
var marked := false
var last_element := ""
var recent: Dictionary = {}   # elemento -> tempo restante (para reações)
var gravity_slow := 0.0

var shoot_timer := 0.0
var _label: Label3D
var _model: Node3D
var _status: MeshInstance3D
var _status_mat: StandardMaterial3D
var _ice: MeshInstance3D
var _punch := 0.0
var _shown_hp := -1
var _anim := 0.0


func setup(enemy_data: Dictionary, at: Vector2, hp_scale: float, elite: bool) -> void:
	data = enemy_data
	id = enemy_data["id"]
	pos = at
	var w := int(enemy_data.get("largura", 1))
	half = Vector2(w * 0.5 - 0.06, 0.44)
	is_elite = elite
	max_hp = float(enemy_data["hp"]) * hp_scale * (4.0 if elite else 1.0)
	hp = max_hp
	xp = int(enemy_data["xp"]) * (5 if elite else 1)
	contact_damage = float(enemy_data["dano"]) * (1.5 if elite else 1.0)
	behavior = enemy_data["comportamento"]
	if behavior == "blindado":
		armor_hits = 1
	shoot_timer = randf_range(2.0, 6.0)
	_anim = randf() * TAU
	_build_visual()
	sync_visual()


func _build_visual() -> void:
	var color := Color(data["cor"])
	if is_elite:
		color = color.lerp(Color("#ffb02e"), 0.45)
	_model = Models.build_enemy(data["modelo"], color, int(data.get("largura", 1)))
	add_child(_model)
	if is_elite:
		_model.scale = Vector3.ONE * 1.12
		var crown := Models.cylinder(_model, 0.18, 0.22, 0.18, Color("#ffb02e"), Vector3(0, 1.35, 0), 2.0)
		crown.name = "Coroa"
	# Sombra "blob" — dá ancoragem ao chão no 2.5D.
	var shadow := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = half.x + 0.05
	cm.bottom_radius = half.x + 0.05
	cm.height = 0.01
	shadow.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0, 0, 0, 0.35)
	shadow.material_override = sm
	shadow.position.y = 0.02
	shadow.scale = Vector3(1, 1, 0.7)
	add_child(shadow)
	# Anel de status elemental.
	_status = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = half.x * 0.85
	tm.outer_radius = half.x + 0.08
	tm.rings = 20
	tm.ring_segments = 4
	_status.mesh = tm
	_status_mat = Models.fade_mat(Color(1, 1, 1, 0.8), 2.5)
	_status.material_override = _status_mat
	_status.position.y = 0.06
	_status.visible = false
	add_child(_status)
	# Número de vida (como nas referências).
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = false
	_label.pixel_size = 0.0045
	_label.font_size = 64
	_label.outline_size = 14
	_label.modulate = Color("#fff3d6")
	_label.outline_modulate = Color("#120d08")
	_label.position = Vector3(0, 1.45, 0)
	_label.render_priority = 5
	_label.outline_render_priority = 4
	add_child(_label)


func sync_visual() -> void:
	position = Vector3(pos.x, 0.0, -pos.y)
	var shown := int(ceil(hp))
	if shown != _shown_hp:
		_shown_hp = shown
		_label.text = str(shown)


func punch() -> void:
	_punch = 1.0


func animate(delta: float) -> void:
	_anim += delta
	_punch = maxf(0.0, _punch - delta * 7.0)
	var s := 1.0 + _punch * 0.18
	_model.scale = Vector3(s, 1.0 / s, s) * (1.12 if is_elite else 1.0)
	if frozen_time > 0.0:
		return
	match data["modelo"]:
		"pombo":
			var flap := sin(_anim * 14.0) * 0.6
			var wl := _model.get_node_or_null("AsaE")
			var wr := _model.get_node_or_null("AsaD")
			if wl:
				wl.rotation.z = flap
			if wr:
				wr.rotation.z = -flap
			_model.position.y = sin(_anim * 3.0) * 0.06
		"drone":
			_model.position.y = sin(_anim * 2.4) * 0.1 + 0.1
			for c in _model.get_children():
				if c.name.begins_with("Rotor"):
					c.rotation.y += delta * 30.0
		"robo":
			_model.rotation.y = sin(_anim * 2.0) * 0.12
		"fusca":
			_model.position.y = absf(sin(_anim * 9.0)) * 0.04
		"concreto":
			_model.rotation.z = sin(_anim * 1.3) * 0.05


func update_status_visual() -> void:
	var c := Color.TRANSPARENT
	if frozen_time > 0.0:
		c = Color("#bff4ff")
	elif burn_time > 0.0:
		c = GameData.ELEMENT_COLORS["fogo"]
	elif poison_time > 0.0:
		c = GameData.ELEMENT_COLORS["veneno"]
	elif chill_time > 0.0:
		c = GameData.ELEMENT_COLORS["gelo"]
	if marked:
		c = Color("#ffe14a")
	_status.visible = c.a > 0.0
	if _status.visible:
		_status_mat.albedo_color = Color(c, 0.85)
		_status_mat.emission = c
	if frozen_time > 0.0 and _ice == null:
		_ice = Models.box(self, Vector3(half.x * 2.1, 1.1, 0.9), Color.WHITE, Vector3(0, 0.55, 0), 0.0, false)
		_ice.material_override = Models.fade_mat(Color(0.75, 0.95, 1.0, 0.45), 0.8)
	elif frozen_time <= 0.0 and _ice != null:
		_ice.queue_free()
		_ice = null


## Multiplicador de movimento (lentidão, congelamento, campo de gravidade).
func move_factor() -> float:
	if frozen_time > 0.0:
		return 0.0
	var f := 1.0
	if chill_time > 0.0:
		f *= 0.55
	if gravity_slow > 0.0:
		f *= 1.0 - gravity_slow
	return f


func hp_ratio() -> float:
	return hp / max_hp
