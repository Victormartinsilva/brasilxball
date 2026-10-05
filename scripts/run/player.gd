class_name Player
extends Node3D
## O personagem na base da arena. Move só no eixo X (2D), mira com o mouse ou automaticamente.

const Y := 0.35
const LIMIT := 5.55

var char_data: Dictionary
var pos := Vector2(0, Y)
var move_speed := 6.0
var aim_dir := Vector2.UP
var target_x := 0.0          # usado por toque/clique
var use_target := false
var hurt_flash := 0.0

var _model: Node3D
var _aim_dots: Array = []
var _walk := 0.0
var _last_x := 0.0


func setup(character: Dictionary) -> void:
	char_data = character
	move_speed = float(character["velocidade"])
	_model = Models.build_character(character["id"])
	add_child(_model)
	var shadow := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.45
	cm.height = 0.01
	shadow.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0, 0, 0, 0.4)
	shadow.mesh = cm
	shadow.material_override = sm
	shadow.position.y = 0.03
	add_child(shadow)
	# Linha de mira pontilhada (previsão do primeiro trecho).
	for i in 9:
		var d := Models.sphere(null, 0.055, Color("#fff3d6"), Vector3.ZERO, 1.5, false)
		d.top_level = true
		add_child(d)
		_aim_dots.append(d)
	_sync()


func move(axis: float, delta: float) -> void:
	if use_target and absf(axis) < 0.01:
		var diff := target_x - pos.x
		axis = clampf(diff * 3.0, -1.0, 1.0) if absf(diff) > 0.05 else 0.0
	pos.x = clampf(pos.x + axis * move_speed * delta, -LIMIT, LIMIT)
	_sync()


func _sync() -> void:
	position = Vector3(pos.x, 0.0, -pos.y)


func animate(delta: float) -> void:
	var moved := absf(pos.x - _last_x) > 0.0001
	_last_x = pos.x
	if moved:
		_walk += delta * 14.0
	_model.position.y = absf(sin(_walk)) * 0.08 if moved else lerpf(_model.position.y, 0.0, 0.3)
	_model.rotation.y = lerp_angle(_model.rotation.y, atan2(-aim_dir.x, aim_dir.y) * 0.6, 0.25)
	hurt_flash = maxf(0.0, hurt_flash - delta * 3.0)
	_model.visible = not (hurt_flash > 0.0 and int(hurt_flash * 20.0) % 2 == 0)
	# Pontos da mira com ricochete nas paredes laterais.
	var p := pos + Vector2(0, 0.6)
	var d := aim_dir
	for i in _aim_dots.size():
		p += d * 1.05
		if p.x > 5.8 or p.x < -5.8:
			d.x = -d.x
			p.x = clampf(p.x, -5.8, 5.8)
		var dot: MeshInstance3D = _aim_dots[i]
		dot.global_position = Vector3(p.x, 0.25, -p.y)
		dot.scale = Vector3.ONE * (1.0 - i * 0.08)
