class_name DioramaSaoPaulo
extends Node3D
## "Brasil Fantástico em Miniatura": a Avenida Paulista como uma maquete viva.
## Camadas: fundo (skyline + MASP) → ambiente (calçadas, árvores, postes) → plano de jogo → primeiro plano (chuva).
## Só visual. Nada aqui participa da física do jogo.

const ARENA_W := 6.0
const ARENA_TOP := 18.0

var _rng := RandomNumberGenerator.new()
var _traffic: Array = []
var _neons: Array = []
var _time := 0.0
var rain: CPUParticles3D


func _ready() -> void:
	_rng.seed = 1554  # 25 de janeiro de 1554, fundação de São Paulo
	_build_environment()
	_build_ground()
	_build_sidewalks()
	_build_buildings()
	_build_masp()
	_build_props()
	_build_background_traffic()
	_build_rain()


func _process(delta: float) -> void:
	_time += delta
	for car in _traffic:
		var n: Node3D = car["node"]
		n.position.x += car["speed"] * delta
		if car["speed"] > 0.0 and n.position.x > 30.0:
			n.position.x = -30.0
		elif car["speed"] < 0.0 and n.position.x < -30.0:
			n.position.x = 30.0
	for i in _neons.size():
		var neon: MeshInstance3D = _neons[i]
		neon.visible = sin(_time * (1.5 + i * 0.37) + i) > -0.85


# ------------------------------------------------------------ ambiente

func _build_environment() -> void:
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#1c1838")
	sky_mat.sky_horizon_color = Color("#d9734a")
	sky_mat.ground_horizon_color = Color("#3a2a35")
	sky_mat.ground_bottom_color = Color("#141018")
	sky_mat.sun_angle_max = 30.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a86b8")
	env.ambient_light_energy = 1.05
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.fog_enabled = true
	env.fog_light_color = Color("#5b4a6b")
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffd2a8")
	sun.light_energy = 1.45
	sun.rotation_degrees = Vector3(-55, -35, 0)
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#6a7dff")
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-30, 150, 0)
	add_child(fill)


# ------------------------------------------------------------ chão

func _build_ground() -> void:
	# Asfalto da arena com grade sutil (ajuda a ler as "casas" dos inimigos).
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var n := _rng.randf_range(-0.02, 0.02)
			var c := Color(0.17 + n, 0.17 + n, 0.19 + n)
			if x % 64 == 0 or y % 64 == 0:
				c = c.lightened(0.07)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(ARENA_W * 2.0 / 4.0, (ARENA_TOP + 4.0) / 4.0, 1.0)
	m.roughness = 0.35
	m.metallic = 0.15
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ARENA_W * 2.0, ARENA_TOP + 4.0)
	plane.mesh = pm
	plane.material_override = m
	plane.position = Vector3(0, 0, -(ARENA_TOP + 4.0) * 0.5 + 2.0)
	add_child(plane)

	# Faixa central amarela tracejada.
	for i in range(11):
		Models.box(self, Vector3(0.12, 0.02, 0.9), Color("#e8b04a"), Vector3(0, 0.01, -2.5 - i * 1.6), 0.0, false)
	# Faixa de pedestres (zebra) — linha do jogador.
	for i in range(12):
		Models.box(self, Vector3(0.55, 0.02, 1.4), Color("#e9e4d8"), Vector3(-5.5 + i * 1.0, 0.012, 0.6), 0.0, false)
	# Poças d'água que refletem as luzes.
	for i in range(7):
		var puddle := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = _rng.randf_range(0.3, 0.6)
		cm.bottom_radius = cm.top_radius
		cm.height = 0.01
		puddle.mesh = cm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color("#46557a")
		pmat.metallic = 0.4
		pmat.roughness = 0.1
		pmat.emission_enabled = true
		pmat.emission = Color("#3dfff2") if i % 2 == 0 else Color("#ff3db4")
		pmat.emission_energy_multiplier = 0.25
		puddle.material_override = pmat
		puddle.scale = Vector3(1.6, 1, 1)
		puddle.position = Vector3(_rng.randf_range(-5, 5), 0.015, -_rng.randf_range(2, 16))
		add_child(puddle)

	# Chão escuro além de tudo (base da maquete).
	var base := MeshInstance3D.new()
	var bm := PlaneMesh.new()
	bm.size = Vector2(120, 120)
	base.mesh = bm
	base.material_override = Models.mat(Color("#1b1712"), 0.0, false)
	base.position = Vector3(0, -0.05, -20)
	add_child(base)


func _build_sidewalks() -> void:
	# Calçada em mosaico português preto e branco (ondas).
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var v := sin((x / 128.0) * TAU * 2.0 + sin((y / 128.0) * TAU) * 1.6)
			var c := Color("#e2ddd0") if v > 0.0 else Color("#24211d")
			if (x % 8 == 0) or (y % 8 == 0):
				c = c.darkened(0.25)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.33, 0.33, 0.33)
	m.roughness = 0.8
	for sx in [-1, 1]:
		var walk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.4, 0.3, 48)
		walk.mesh = bm
		walk.material_override = m
		walk.position = Vector3(sx * (ARENA_W + 1.85), 0.15, -18)
		add_child(walk)
		# Meio-fio: é a "parede" da arena.
		Models.box(self, Vector3(0.22, 0.38, 48), Color("#a9a294"), Vector3(sx * (ARENA_W + 0.11), 0.19, -18))
	# Calçada do primeiro plano (onde o jogador "pisa").
	var front := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(ARENA_W * 2.0, 0.3, 6.0)
	front.mesh = fm
	front.material_override = m
	front.position = Vector3(0, -0.14, 4.4)
	add_child(front)


func _window_material(tint: Color) -> StandardMaterial3D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var emi := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for wy in 4:
		for wx in 4:
			var lit := _rng.randf() < 0.35
			var glass := Color("#ffd27a") if lit else Color("#2a3448")
			for y in 16:
				for x in 16:
					var is_win := x >= 3 and x < 13 and y >= 3 and y < 12
					img.set_pixel(wx * 16 + x, wy * 16 + y, glass if is_win else Color(0.82, 0.8, 0.76))
					emi.set_pixel(wx * 16 + x, wy * 16 + y, glass if (is_win and lit) else Color.BLACK)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = tint
	m.emission_enabled = true
	m.emission_texture = ImageTexture.create_from_image(emi)
	m.emission_energy_multiplier = 1.6
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.22, 0.22, 0.22)
	m.roughness = 0.6
	m.next_pass = Models.outline_mat()
	return m


func _build_buildings() -> void:
	var tints := [Color("#8b8f99"), Color("#a89a86"), Color("#6f7f99"), Color("#9aa39a"), Color("#b5a58f"), Color("#5f6b80")]
	var mats: Array = []
	for t in tints:
		mats.append(_window_material(t))
	for sx in [-1, 1]:
		var z := 6.0
		while z > -46.0:
			var depth := _rng.randf_range(3.5, 6.5)
			var width := _rng.randf_range(4.0, 7.0)
			var height := _rng.randf_range(6.0, 20.0)
			if z > -2.0:
				height *= 0.55  # prédios do primeiro plano mais baixos para não cobrir o jogo
			var b := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(width, height, depth)
			b.mesh = bm
			b.material_override = mats[_rng.randi() % mats.size()]
			b.position = Vector3(sx * (ARENA_W + 3.6 + width * 0.5), height * 0.5, z - depth * 0.5)
			add_child(b)
			# Topo: caixas d'água, antenas, letreiros.
			if _rng.randf() < 0.6:
				Models.box(self, Vector3(1.2, 0.8, 1.2), Color("#5a6470"), b.position + Vector3(0, height * 0.5 + 0.4, 0))
			if _rng.randf() < 0.5:
				Models.cylinder(self, 0.03, 0.06, 2.5, Color("#c0c6cc"), b.position + Vector3(_rng.randf_range(-1, 1), height * 0.5 + 1.25, 0))
			if _rng.randf() < 0.45 and z < 0.0:
				var neon_colors := [Color("#ff3db4"), Color("#3dfff2"), Color("#ffe14a"), Color("#7a5cff")]
				var neon := Models.box(self, Vector3(0.12, 0.9, _rng.randf_range(1.6, 3.0)), neon_colors[_rng.randi() % 4],
					Vector3(sx * (ARENA_W + 3.55), _rng.randf_range(2.5, minf(height - 1.0, 8.0)), z - depth * 0.5), 5.0, false)
				_neons.append(neon)
			z -= depth + _rng.randf_range(0.2, 1.2)
	# Skyline do fundo — muitas torres finas e altas.
	for i in range(26):
		var h := _rng.randf_range(12.0, 34.0)
		var w := _rng.randf_range(2.5, 5.0)
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h, w)
		b.mesh = bm
		b.material_override = mats[_rng.randi() % mats.size()]
		b.position = Vector3(-34.0 + i * 2.7 + _rng.randf_range(-0.8, 0.8), h * 0.5, -46.0 - _rng.randf_range(0, 12))
		add_child(b)


func _build_masp() -> void:
	# MASP estilizado: o vão livre vermelho no fundo da avenida.
	var red := Color("#d62a1f")
	var root := Node3D.new()
	root.position = Vector3(0, 0, -ARENA_TOP - 7.0)
	add_child(root)
	for sx in [-1, 1]:
		Models.box(root, Vector3(1.2, 7.5, 1.2), red, Vector3(sx * 7.0, 3.75, 0))
		Models.box(root, Vector3(1.2, 7.5, 1.2), red, Vector3(sx * 7.0, 3.75, -5.0))
	Models.box(root, Vector3(15.4, 1.0, 1.2), red, Vector3(0, 7.9, 0))
	Models.box(root, Vector3(15.4, 1.0, 1.2), red, Vector3(0, 7.9, -5.0))
	Models.box(root, Vector3(13.4, 3.2, 5.8), Color("#30343c"), Vector3(0, 5.6, -2.5))
	for i in range(10):
		Models.box(root, Vector3(1.0, 1.6, 0.05), Color("#ffd27a"), Vector3(-5.6 + i * 1.25, 5.6, 0.45), 1.2, false)
	# Vão livre com feirinha (lonas coloridas).
	var lonas := [Color("#e8b04a"), Color("#2f7a4a"), Color("#c2412d"), Color("#2e6fd8")]
	for i in range(5):
		Models.box(root, Vector3(1.6, 0.1, 1.6), lonas[i % 4], Vector3(-4.4 + i * 2.2, 1.8, -2.5))
		Models.cylinder(root, 0.04, 0.04, 1.8, Color("#3b2416"), Vector3(-4.4 + i * 2.2, 0.9, -2.5))


func _build_props() -> void:
	# Árvores (ipês e sibipirunas) e postes ao longo da calçada.
	var leaf := [Color("#2f6b3a"), Color("#3d8048"), Color("#e8b04a"), Color("#b54fa0")]  # verde + ipê amarelo/roxo
	for sx in [-1, 1]:
		var z := 3.0
		while z > -40.0:
			var tree := Node3D.new()
			tree.position = Vector3(sx * (ARENA_W + 2.4 + _rng.randf_range(-0.3, 0.3)), 0.3, z)
			add_child(tree)
			Models.cylinder(tree, 0.1, 0.16, 1.8, Color("#4a3020"), Vector3(0, 0.9, 0))
			var c: Color = leaf[0] if _rng.randf() < 0.55 else leaf[_rng.randi() % leaf.size()]
			var crown := Models.sphere(tree, 0.9, c, Vector3(0, 2.2, 0))
			crown.scale = Vector3(1.0, 0.8, 1.0)
			Models.sphere(tree, 0.55, c.lightened(0.1), Vector3(0.4, 2.6, 0.2))
			z -= _rng.randf_range(4.0, 6.0)
		var lz := 1.0
		while lz > -40.0:
			var lamp := Node3D.new()
			lamp.position = Vector3(sx * (ARENA_W + 0.6), 0.3, lz)
			add_child(lamp)
			Models.cylinder(lamp, 0.05, 0.07, 3.0, Color("#2a2a2e"), Vector3(0, 1.5, 0))
			Models.box(lamp, Vector3(0.7, 0.08, 0.12), Color("#2a2a2e"), Vector3(-sx * 0.3, 3.0, 0))
			Models.sphere(lamp, 0.13, Color("#fff0b0"), Vector3(-sx * 0.6, 2.92, 0), 5.0, false)
			lz -= 7.0
	# Ponto de ônibus e banca de jornal no primeiro plano.
	Models.box(self, Vector3(2.2, 0.08, 1.0), Color("#2e6fd8"), Vector3(-8.0, 2.3, 1.5))
	Models.box(self, Vector3(0.08, 2.0, 1.0), Color("#cfe6ff"), Vector3(-9.0, 1.3, 1.5))
	Models.box(self, Vector3(1.4, 1.6, 1.0), Color("#2f7a4a"), Vector3(8.2, 1.1, 1.2))
	Models.box(self, Vector3(1.5, 0.12, 1.1), Color("#e8b04a"), Vector3(8.2, 1.95, 1.2))


func _build_background_traffic() -> void:
	# Avenida cruzando o fundo (só ambientação).
	var road := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(70, 0.05, 3.2)
	road.mesh = bm
	road.material_override = Models.mat(Color("#25252a"), 0.0, false)
	road.position = Vector3(0, 0.02, -ARENA_TOP - 2.6)
	add_child(road)
	var kinds := ["onibus", "taxi", "carro", "taxi", "carro"]
	for i in range(6):
		var car := Models.build_vehicle(kinds[i % kinds.size()])
		var dir := 1.0 if i % 2 == 0 else -1.0
		car.position = Vector3(_rng.randf_range(-30, 30), 0.0, -ARENA_TOP - (1.9 if dir > 0 else 3.3))
		car.rotation_degrees.y = 0.0 if dir > 0 else 180.0
		add_child(car)
		_traffic.append({"node": car, "speed": dir * _rng.randf_range(3.0, 6.0)})


func _build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 220 if GameData.is_mobile() else 500
	rain.lifetime = 0.9
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(16, 0.5, 20)
	rain.position = Vector3(0, 14, -8)
	rain.direction = Vector3(0.08, -1, 0)
	rain.spread = 2.0
	rain.gravity = Vector3(0, -12, 0)
	rain.initial_velocity_min = 16.0
	rain.initial_velocity_max = 20.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.02, 0.45, 0.02)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(0.7, 0.8, 1.0, 0.35)
	drop.material = dm
	rain.mesh = drop
	add_child(rain)
