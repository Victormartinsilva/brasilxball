class_name DioramaMataAtlantica
extends Node3D
## A boca da Grota Funda: corredor de terra entre paredões de pedra, mata fechada dos dois lados,
## cachoeira no fundo, névoa e vaga-lumes. Na base da tela fica a cerca da vila que o jogador defende.
## Só visual. Nada aqui participa da física do jogo.

const ARENA_W := 6.0
const ARENA_TOP := 18.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _water: Array = []
var _sway: Array = []


func _ready() -> void:
	_rng.seed = 1500  # o ano em que tudo isso aqui já era mata
	_build_environment()
	_build_ground()
	_build_walls()
	_build_forest()
	_build_waterfall()
	_build_village_edge()
	_build_particles()


func _process(delta: float) -> void:
	_time += delta
	for i in _water.size():
		var m: StandardMaterial3D = _water[i]
		m.uv1_offset.y = -_time * (1.6 + i * 0.3)
	for i in _sway.size():
		var n: Node3D = _sway[i]
		n.rotation.z = sin(_time * 0.8 + i * 1.7) * 0.04


func _build_environment() -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#3d6b5a")
	sky_mat.sky_horizon_color = Color("#d9b878")
	sky_mat.ground_horizon_color = Color("#2f4a32")
	sky_mat.ground_bottom_color = Color("#14201a")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9fc79a")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("#b9d6b0")
	env.fog_density = 0.0035
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe6b0")
	sun.light_energy = 1.35
	sun.rotation_degrees = Vector3(-62, 25, 0)
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#6ad0a0")
	fill.light_energy = 0.3
	fill.rotation_degrees = Vector3(-25, 160, 0)
	add_child(fill)


func _noise_tex(size: int, base: Color, spots: Array, grid := 0) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var n := _rng.randf_range(-0.035, 0.035)
			var c := Color(base.r + n, base.g + n, base.b + n)
			if grid > 0 and (x % grid == 0 or y % grid == 0):
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	for sp in spots:
		for k in int(sp[1]):
			var cx := _rng.randi() % size
			var cy := _rng.randi() % size
			var r := _rng.randi_range(1, int(sp[2]))
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if dx * dx + dy * dy <= r * r:
						img.set_pixel((cx + dx + size) % size, (cy + dy + size) % size, sp[0])
	return ImageTexture.create_from_image(img)


func _build_ground() -> void:
	# Chão de terra batida com pedrinhas e folhas; grade sutil para ler as "casas".
	var tex := _noise_tex(256, Color("#6b5236"), [[Color("#8a8070"), 60, 3], [Color("#4f6b2f"), 90, 2], [Color("#a5743a"), 50, 2]], 64)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(ARENA_W * 2.0 / 4.0, (ARENA_TOP + 4.0) / 4.0, 1.0)
	m.roughness = 0.95
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ARENA_W * 2.0, ARENA_TOP + 4.0)
	plane.mesh = pm
	plane.material_override = m
	plane.position = Vector3(0, 0, -(ARENA_TOP + 4.0) * 0.5 + 2.0)
	add_child(plane)
	# Filete d'água descendo pelo meio da grota (só enfeite).
	var stream := MeshInstance3D.new()
	var sm := PlaneMesh.new()
	sm.size = Vector2(0.5, ARENA_TOP + 2.0)
	stream.mesh = sm
	var wm := StandardMaterial3D.new()
	wm.albedo_texture = _noise_tex(64, Color("#5aa6c9"), [[Color("#d6f2ff"), 30, 1]])
	wm.uv1_scale = Vector3(1, 6, 1)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.albedo_color = Color(1, 1, 1, 0.55)
	wm.emission_enabled = true
	wm.emission = Color("#3f8fd8")
	wm.emission_energy_multiplier = 0.25
	stream.material_override = wm
	stream.position = Vector3(0.2, 0.012, -(ARENA_TOP + 2.0) * 0.5 + 1.0)
	add_child(stream)
	_water.append(wm)
	# Folhas caídas e pedras soltas.
	for i in 26:
		var leaf := Models.box(self, Vector3(0.22, 0.02, 0.12), [Color("#4f8a3a"), Color("#c9a23a"), Color("#8a4a2a")][i % 3],
			Vector3(_rng.randf_range(-5.6, 5.6), 0.02, -_rng.randf_range(0.5, 17)), 0.0, false)
		leaf.rotation_degrees.y = _rng.randf_range(0, 180)
	# Base de terra escura além de tudo.
	var base := MeshInstance3D.new()
	var bm := PlaneMesh.new()
	bm.size = Vector2(120, 120)
	base.mesh = bm
	base.material_override = Models.mat(Color("#1d2a1c"), 0.0, false)
	base.position = Vector3(0, -0.05, -20)
	add_child(base)


func _build_walls() -> void:
	# Paredões da grota: blocos de pedra com musgo, samambaias e bromélias nos degraus.
	var rocks := [Color("#7b7468"), Color("#8a8275"), Color("#6a645b")]
	for sx in [-1, 1]:
		var z := 4.0
		while z > -40.0:
			var h := _rng.randf_range(1.2, 3.4)
			var d := _rng.randf_range(1.6, 3.0)
			var w := _rng.randf_range(1.4, 2.6)
			var x: float = sx * (ARENA_W + 0.3 + w * 0.5)
			Models.box(self, Vector3(w, h, d), rocks[_rng.randi() % rocks.size()], Vector3(x, h * 0.5, z - d * 0.5))
			Models.box(self, Vector3(w * 0.9, 0.18, d * 0.85), Color("#4c7a3a"), Vector3(x, h + 0.05, z - d * 0.5), 0.0, false)
			# Camada de cima, recuada (o paredão sobe em degraus).
			var h2 := _rng.randf_range(2.0, 5.0)
			Models.box(self, Vector3(w, h2, d), rocks[_rng.randi() % rocks.size()].darkened(0.1), Vector3(x + sx * w, h2 * 0.5, z - d * 0.5))
			if _rng.randf() < 0.7:
				_fern(Vector3(x - sx * w * 0.2, h + 0.1, z - d * 0.5))
			if _rng.randf() < 0.45:
				_bromelia(Vector3(x + sx * w * 0.2, h + 0.1, z - d * 0.3))
			z -= d + _rng.randf_range(0.0, 0.3)


func _fern(at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	for k in 5:
		var leaf := Models.box(root, Vector3(0.12, 0.04, 0.8), Color("#3d8048").lightened(_rng.randf_range(0, 0.15)), Vector3(0, 0.15, 0.3))
		leaf.rotation_degrees = Vector3(-25, k * 72.0, 0)
		leaf.position = Vector3(sin(deg_to_rad(k * 72.0)) * 0.3, 0.15, cos(deg_to_rad(k * 72.0)) * 0.3)
	_sway.append(root)


func _bromelia(at: Vector3) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	for k in 6:
		var leaf := Models.cylinder(root, 0.0, 0.08, 0.6, Color("#5f9a3a"), Vector3.ZERO)
		leaf.rotation_degrees = Vector3(35, k * 60.0, 0)
		leaf.position = Vector3(sin(deg_to_rad(k * 60.0)) * 0.12, 0.2, cos(deg_to_rad(k * 60.0)) * 0.12)
	Models.cylinder(root, 0.0, 0.12, 0.45, Color("#e0322b"), Vector3(0, 0.35, 0), 1.0)  # flor vermelha


func _build_forest() -> void:
	# Jequitibás, palmitos e quaresmeiras (roxas) acima dos paredões.
	var greens := [Color("#2f6b3a"), Color("#3d8048"), Color("#25553a"), Color("#4f8a3a")]
	for sx in [-1, 1]:
		var z := 3.0
		while z > -46.0:
			var tree := Node3D.new()
			tree.position = Vector3(sx * _rng.randf_range(ARENA_W + 4.5, ARENA_W + 12.0), 0, z)
			add_child(tree)
			var h := _rng.randf_range(6.0, 13.0)
			Models.cylinder(tree, 0.25, 0.45, h, Color("#4a3020"), Vector3(0, h * 0.5, 0))
			var roxa := _rng.randf() < 0.18
			var c: Color = Color("#8e4fb0") if roxa else greens[_rng.randi() % greens.size()]
			for k in 3:
				var crown := Models.sphere(tree, _rng.randf_range(1.4, 2.4), c.lightened(k * 0.04),
					Vector3(_rng.randf_range(-0.9, 0.9), h + _rng.randf_range(-0.6, 0.8), _rng.randf_range(-0.9, 0.9)))
				crown.scale = Vector3(1.0, 0.75, 1.0)
			if _rng.randf() < 0.35:  # cipó pendurado
				Models.cylinder(tree, 0.03, 0.03, h * 0.6, Color("#3d6b2a"), Vector3(-sx * 1.2, h * 0.65, 0))
			z -= _rng.randf_range(2.8, 4.5)
	# Palmeiras-juçara mais perto, quebrando a linha.
	for i in 8:
		var sx := -1 if i % 2 == 0 else 1
		var p := Node3D.new()
		p.position = Vector3(sx * _rng.randf_range(ARENA_W + 2.5, ARENA_W + 4.0), 2.0, -_rng.randf_range(0, 30))
		add_child(p)
		Models.cylinder(p, 0.08, 0.12, 5.0, Color("#8a7a5a"), Vector3(0, 2.5, 0))
		for k in 7:
			var frond := Models.box(p, Vector3(0.18, 0.03, 1.7), Color("#3d8048"), Vector3(0, 5.0, 0))
			frond.rotation_degrees = Vector3(-30, k * (360.0 / 7.0), 0)
		_sway.append(p)


func _build_waterfall() -> void:
	# Cachoeira no fundo da grota (o lugar de onde as assombrações descem).
	var z := -ARENA_TOP - 6.0
	Models.box(self, Vector3(22, 14, 3), Color("#6a645b"), Vector3(0, 7, z - 1.5))
	Models.box(self, Vector3(22, 0.6, 3.4), Color("#4c7a3a"), Vector3(0, 14.2, z - 1.5), 0.0, false)
	for k in 3:
		var fall := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.2 - k * 0.5, 13.5)
		pm.orientation = PlaneMesh.FACE_Z
		fall.mesh = pm
		var m := StandardMaterial3D.new()
		m.albedo_texture = _noise_tex(64, Color("#bfe6ff"), [[Color("#ffffff"), 80, 1], [Color("#7fb8e0"), 40, 2]])
		m.uv1_scale = Vector3(1, 3, 1)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1, 1, 1, 0.8 - k * 0.15)
		m.emission_enabled = true
		m.emission = Color("#9fd8ff")
		m.emission_energy_multiplier = 0.5
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fall.material_override = m
		fall.position = Vector3(-3.5 + k * 4.0, 6.75, z + 0.05)
		add_child(fall)
		_water.append(m)
	# Poço de pedra e espuma onde a água cai.
	var pool := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 6.0
	cm.bottom_radius = 6.0
	cm.height = 0.05
	pool.mesh = cm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color("#3f8fd8")
	pmat.metallic = 0.3
	pmat.roughness = 0.1
	pool.material_override = pmat
	pool.scale = Vector3(1.6, 1, 0.5)
	pool.position = Vector3(0, 0.03, z + 2.0)
	add_child(pool)


func _build_village_edge() -> void:
	# A "linha da vila": cerca de bambu e pedras. Cruzou aqui, invadiu a vila.
	for i in 25:
		var x := -6.0 + i * 0.5
		Models.cylinder(self, 0.06, 0.07, 0.7 + (i % 2) * 0.12, Color("#b59a5a"), Vector3(x, 0.35, 0.95))
	Models.box(self, Vector3(12.2, 0.07, 0.07), Color("#8a6a3a"), Vector3(0, 0.45, 0.95))
	Models.box(self, Vector3(12.2, 0.07, 0.07), Color("#8a6a3a"), Vector3(0, 0.25, 0.95))
	# Telhados de sapê da vila no primeiro plano.
	for sx in [-1, 1]:
		for k in 2:
			var hut := Node3D.new()
			hut.position = Vector3(sx * (8.0 + k * 2.6), 0, 1.4 + k * 1.2)
			hut.scale = Vector3.ONE * 0.8
			add_child(hut)
			Models.box(hut, Vector3(2.2, 1.2, 1.8), Color("#c9a26a"), Vector3(0, 0.6, 0))
			var roof := Models.cylinder(hut, 0.0, 1.7, 1.2, Color("#b5893a"), Vector3(0, 1.75, 0))
			roof.scale = Vector3(1.0, 1.0, 0.85)
			Models.box(hut, Vector3(0.45, 0.7, 0.05), Color("#3b2416"), Vector3(0, 0.35, -0.92))


func _build_particles() -> void:
	# Vaga-lumes (enfeite) e névoa baixa.
	var ff := CPUParticles3D.new()
	ff.amount = 40 if GameData.is_mobile() else 70
	ff.lifetime = 4.0
	ff.preprocess = 4.0
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(10, 2, 14)
	ff.position = Vector3(0, 2.5, -10)
	ff.direction = Vector3(0, 1, 0)
	ff.spread = 180.0
	ff.gravity = Vector3.ZERO
	ff.initial_velocity_min = 0.1
	ff.initial_velocity_max = 0.4
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.material = Models.mat(Color("#e8ff7a"), 5.0, false, true)
	ff.mesh = dot
	add_child(ff)
	var mist := CPUParticles3D.new()
	mist.amount = 6
	mist.lifetime = 8.0
	mist.preprocess = 8.0
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(9, 0.3, 12)
	mist.position = Vector3(0, 0.6, -12)
	mist.direction = Vector3(1, 0, 0)
	mist.spread = 20.0
	mist.gravity = Vector3.ZERO
	mist.initial_velocity_min = 0.2
	mist.initial_velocity_max = 0.5
	var puff := SphereMesh.new()
	puff.radius = 1.6
	puff.height = 1.2
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(0.9, 1.0, 0.92, 0.05)
	puff.material = pm
	mist.mesh = puff
	add_child(mist)
