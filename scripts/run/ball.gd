class_name Ball
extends Node3D
## Uma bola em campo. Estado mecânico em 2D (pos/dir); o Node3D é só a representação.

const TRAIL_LEN := 6

var data: Dictionary          # stats calculados por RunBuild.ball_stats()
var id := ""
var pos := Vector2.ZERO
var dir := Vector2.UP
var speed := 15.0
var radius := 0.22
var damage := 10.0
var crit := 0.05
var ricochetes_left := 5
var pierce_left := 0
var elements: Array = []
var behavior := "basico"
var level := 1
var tags: Array = []

var age := 0.0
var bounces := 0              # ricochetes totais (paredes + inimigos) — passiva Ricochete
var returning := false
var dead := false
var is_clone := false
var lifetime := 25.0          # segurança: se ficar presa, volta sozinha
var bag_id := ""             # "" = bola temporária (clone, rajada…); senão volta para a bolsa
var suspiro_done := false
var last_hit_id := 0
var last_hit_time := -1.0
var hit_ids: Dictionary = {}  # para bolas que atravessam (fantasma/bumerangue de volta)
var marked_first := false     # Olho do Caçador
var attached: Node = null     # Parasita
var attach_timer := 0.0
var attach_offset := Vector2.ZERO
var color := Color.WHITE
var stone_mult := 3.0        # Paralelepípedo
var hits := 0
var dribbles := 0
var spawn_cd := 0.0          # Pipoca

var _core: MeshInstance3D
var _trail: Array = []
var _trail_points: Array = []
var _trail_timer := 0.0


func setup(stats: Dictionary, start: Vector2, direction: Vector2) -> void:
	data = stats
	id = stats["id"]
	pos = start
	dir = direction.normalized()
	speed = stats["velocidade"]
	radius = 0.24 * stats["tamanho"]
	damage = stats["dano"]
	crit = stats["critico"]
	ricochetes_left = stats["ricochetes"]
	pierce_left = stats["piercing"]
	elements = stats["elementos"].duplicate()
	behavior = stats["comportamento"]
	level = stats["nivel"]
	tags = stats["tags"]
	color = stats["cor"]
	_build_visual()
	_sync()


func _build_visual() -> void:
	var emission := 2.2 if elements.size() > 0 or behavior in ["fantasma", "gravidade", "singularidade", "espelho"] else 0.6
	_core = Models.sphere(self, 1.0, color, Vector3.ZERO, emission, true)
	_core.scale = Vector3.ONE * radius
	if behavior == "fantasma":
		_core.material_override = Models.fade_mat(Color(color, 0.55), 2.0)
	elif behavior == "espelho":
		var m := StandardMaterial3D.new()
		m.metallic = 1.0
		m.roughness = 0.05
		m.albedo_color = color
		m.next_pass = Models.outline_mat()
		_core.material_override = m
	if elements.size() > 1:
		# Fusões: anel orbital com a cor do segundo elemento.
		var ring := Models.torus(self, 0.9, 1.15, GameData.ELEMENT_COLORS.get(elements[1], color), Vector3.ZERO, 3.0)
		ring.scale = Vector3.ONE * radius * 1.2
		ring.name = "Anel"
	for i in TRAIL_LEN:
		var t := Models._add(null, Models._mesh("sphere", 1.0), Models.mat(color, 1.5, false, true), Vector3.ZERO)
		t.top_level = true
		t.visible = false
		var s := radius * (0.8 - i * 0.11)
		t.scale = Vector3.ONE * maxf(s, 0.03)
		add_child(t)
		_trail.append(t)


func set_returning(on: bool) -> void:
	returning = on
	if on and _core and behavior != "bumerangue":
		_core.scale = Vector3.ONE * radius * 0.7


func _sync() -> void:
	position = Vector3(pos.x, 0.45, -pos.y)


func visual_update(delta: float) -> void:
	_sync()
	if _core:
		_core.rotation.x += delta * speed * 0.8
	var ring := get_node_or_null("Anel")
	if ring:
		ring.rotation.z += delta * 6.0
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.025
		_trail_points.push_front(global_position)
		if _trail_points.size() > TRAIL_LEN:
			_trail_points.resize(TRAIL_LEN)
	for i in _trail.size():
		var t: MeshInstance3D = _trail[i]
		if i < _trail_points.size():
			t.visible = true
			t.global_position = _trail_points[i]
		else:
			t.visible = false
