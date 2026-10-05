class_name FxLayer
extends Node3D
## Efeitos visuais leves (sem física): faíscas, explosões, números de dano, raios, avisos.
## Tudo em coordenadas 2D do jogo convertidas para o plano 3D.

const MAX_NUMBERS := 45
const MAX_SPARKS := 260

var _sparks: Array = []    # {node, vel, life, max}
var _fades: Array = []     # {node, mat, life, max, grow, color}
var _numbers: Array = []   # {node, life}
var _spark_mesh: SphereMesh


func _ready() -> void:
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.06
	_spark_mesh.height = 0.12
	_spark_mesh.radial_segments = 6
	_spark_mesh.rings = 3


static func to3(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


func sparks(at: Vector2, color: Color, count := 6, power := 4.0, h := 0.5) -> void:
	if _sparks.size() > MAX_SPARKS:
		count = mini(count, 2)
	for i in count:
		var n := MeshInstance3D.new()
		n.mesh = _spark_mesh
		n.material_override = Models.mat(color, 3.0, false, true)
		n.position = to3(at, h)
		add_child(n)
		var v := Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1)).normalized() * power * randf_range(0.5, 1.2)
		var life := randf_range(0.25, 0.5)
		_sparks.append({"node": n, "vel": v, "life": life, "max": life})


func ring(at: Vector2, radius: float, color: Color, duration := 0.35, h := 0.2) -> void:
	var n := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.82
	tm.outer_radius = 1.0
	tm.rings = 28
	tm.ring_segments = 4
	n.mesh = tm
	var m := Models.fade_mat(color, 3.0)
	n.material_override = m
	n.position = to3(at, h)
	n.scale = Vector3.ONE * 0.1
	add_child(n)
	_fades.append({"node": n, "mat": m, "life": duration, "max": duration, "grow": radius, "color": color})


func explosion(at: Vector2, radius: float, color: Color) -> void:
	ring(at, radius, color, 0.35)
	var n := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 14
	sm.rings = 7
	n.mesh = sm
	var m := Models.fade_mat(Color(color, 0.7), 2.5)
	n.material_override = m
	n.position = to3(at, 0.4)
	n.scale = Vector3.ONE * 0.1
	add_child(n)
	_fades.append({"node": n, "mat": m, "life": 0.28, "max": 0.28, "grow": radius * 0.85, "color": Color(color, 0.7)})
	sparks(at, color, 10, 6.0)


func column(x: float, from_y: float, to_y: float, color: Color) -> void:
	var n := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.6, absf(to_y - from_y))
	n.mesh = bm
	var m := Models.fade_mat(Color(color, 0.6), 3.0)
	n.material_override = m
	n.position = Vector3(x, 0.3, -(from_y + to_y) * 0.5)
	add_child(n)
	_fades.append({"node": n, "mat": m, "life": 0.4, "max": 0.4, "grow": 0.0, "color": Color(color, 0.6)})


func bolt(a: Vector2, b: Vector2, color: Color) -> void:
	# Raio em zigue-zague: 3 segmentos.
	var pts: Array = [a]
	for i in range(1, 3):
		var t := i / 3.0
		var p := a.lerp(b, t) + Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		pts.append(p)
	pts.append(b)
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var seg_len := p0.distance_to(p1)
		if seg_len < 0.01:
			continue
		var n := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, 0.07, seg_len)
		n.mesh = bm
		var m := Models.fade_mat(color, 4.0)
		n.material_override = m
		var mid := (p0 + p1) * 0.5
		n.position = to3(mid, 0.6)
		add_child(n)
		n.look_at(to3(p1, 0.6), Vector3.UP)
		_fades.append({"node": n, "mat": m, "life": 0.16, "max": 0.16, "grow": 0.0, "color": color})


func warning(at: Vector2, radius: float, duration: float) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.02
	n.mesh = cm
	n.material_override = Models.fade_mat(Color(1.0, 0.2, 0.1, 0.45), 2.0)
	n.position = to3(at, 0.04)
	add_child(n)
	return n


func number(at: Vector2, amount: float, crit: bool, color := Color(1.0, 0.95, 0.84)) -> void:
	if _numbers.size() >= MAX_NUMBERS:
		if not crit:
			return
		var old: Dictionary = _numbers.pop_front()
		old["node"].queue_free()
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006 if crit else 0.0045
	l.font_size = 64
	l.outline_size = 16
	l.text = str(int(round(amount))) + ("!" if crit else "")
	l.modulate = Color("#ffe14a") if crit else color
	l.outline_modulate = Color("#120d08")
	l.render_priority = 10
	l.outline_render_priority = 9
	l.position = to3(at + Vector2(randf_range(-0.25, 0.25), 0), 1.2)
	add_child(l)
	_numbers.append({"node": l, "life": 0.7})


func text(at: Vector2, msg: String, color: Color, size := 0.008) -> void:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = size
	l.font_size = 64
	l.outline_size = 18
	l.text = msg
	l.modulate = color
	l.outline_modulate = Color("#120d08")
	l.render_priority = 11
	l.outline_render_priority = 10
	l.position = to3(at, 1.8)
	add_child(l)
	_numbers.append({"node": l, "life": 1.0})


func _process(delta: float) -> void:
	var i := _sparks.size() - 1
	while i >= 0:
		var s: Dictionary = _sparks[i]
		s["life"] -= delta
		var n: MeshInstance3D = s["node"]
		if s["life"] <= 0.0:
			n.queue_free()
			_sparks.remove_at(i)
		else:
			s["vel"] += Vector3(0, -14.0, 0) * delta
			n.position += s["vel"] * delta
			n.scale = Vector3.ONE * (s["life"] / s["max"])
		i -= 1
	i = _fades.size() - 1
	while i >= 0:
		var f: Dictionary = _fades[i]
		f["life"] -= delta
		var n: MeshInstance3D = f["node"]
		if f["life"] <= 0.0:
			n.queue_free()
			_fades.remove_at(i)
		else:
			var t: float = 1.0 - f["life"] / f["max"]
			if f["grow"] > 0.0:
				n.scale = Vector3.ONE * lerpf(0.2, f["grow"], ease(t, 0.4))
			var c: Color = f["color"]
			f["mat"].albedo_color = Color(c, c.a * (1.0 - t))
		i -= 1
	i = _numbers.size() - 1
	while i >= 0:
		var d: Dictionary = _numbers[i]
		d["life"] -= delta
		var l: Label3D = d["node"]
		if d["life"] <= 0.0:
			l.queue_free()
			_numbers.remove_at(i)
		else:
			l.position.y += delta * 1.6
			l.modulate.a = clampf(d["life"] * 3.0, 0.0, 1.0)
			l.outline_modulate.a = l.modulate.a
		i -= 1
