class_name Models
## Fábrica de modelos 3D procedurais (placeholders estilizados).
## Tudo é feito de primitivas + contorno de "nanquim" para lembrar a arte de referência.
## Quando os assets definitivos (.glb) chegarem, basta trocar as funções build_* por cenas importadas.

static var _mats: Dictionary = {}
static var _outline: StandardMaterial3D
static var _meshes: Dictionary = {}


static func outline_mat() -> StandardMaterial3D:
	if _outline == null:
		_outline = StandardMaterial3D.new()
		_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline.albedo_color = Color("#120d08")
		_outline.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline.grow = true
		_outline.grow_amount = 0.035
	return _outline


static func mat(color: Color, emission := 0.0, outline := true, unshaded := false) -> StandardMaterial3D:
	var key := "%s|%.2f|%s|%s" % [color.to_html(), emission, outline, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if outline:
		m.next_pass = outline_mat()
	_mats[key] = m
	return m


## Material único (não compartilhado) com transparência — para efeitos que somem.
static func fade_mat(color: Color, emission := 1.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func _mesh(kind: String, a: float, b := 0.0, c := 0.0) -> Mesh:
	var key := "%s|%.3f|%.3f|%.3f" % [kind, a, b, c]
	if _meshes.has(key):
		return _meshes[key]
	var m: Mesh
	match kind:
		"box":
			var bm := BoxMesh.new()
			bm.size = Vector3(a, b, c)
			m = bm
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = a
			sm.height = a * 2.0
			sm.radial_segments = 12
			sm.rings = 6
			m = sm
		"cyl":
			var cm := CylinderMesh.new()
			cm.top_radius = a
			cm.bottom_radius = b
			cm.height = c
			cm.radial_segments = 10
			cm.rings = 1
			m = cm
		"capsule":
			var cp := CapsuleMesh.new()
			cp.radius = a
			cp.height = b
			cp.radial_segments = 10
			cp.rings = 4
			m = cp
		"torus":
			var tm := TorusMesh.new()
			tm.inner_radius = a
			tm.outer_radius = b
			tm.rings = 24
			tm.ring_segments = 6
			m = tm
		"plane":
			var pm := PlaneMesh.new()
			pm.size = Vector2(a, b)
			m = pm
	_meshes[key] = m
	return m


static func box(parent: Node3D, size: Vector3, color: Color, pos := Vector3.ZERO, emission := 0.0, outline := true) -> MeshInstance3D:
	return _add(parent, _mesh("box", size.x, size.y, size.z), mat(color, emission, outline), pos)


static func sphere(parent: Node3D, radius: float, color: Color, pos := Vector3.ZERO, emission := 0.0, outline := true) -> MeshInstance3D:
	return _add(parent, _mesh("sphere", radius), mat(color, emission, outline), pos)


static func cylinder(parent: Node3D, top_r: float, bottom_r: float, height: float, color: Color, pos := Vector3.ZERO, emission := 0.0, outline := true) -> MeshInstance3D:
	return _add(parent, _mesh("cyl", top_r, bottom_r, height), mat(color, emission, outline), pos)


static func capsule(parent: Node3D, radius: float, height: float, color: Color, pos := Vector3.ZERO, outline := true) -> MeshInstance3D:
	return _add(parent, _mesh("capsule", radius, height), mat(color, 0.0, outline), pos)


static func torus(parent: Node3D, inner: float, outer: float, color: Color, pos := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	return _add(parent, _mesh("torus", inner, outer), mat(color, emission, false), pos)


static func _add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent:
		parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- ARTE 2D (miniaturas)

## Sprite "miniatura" a partir de uma arte recortada (tools/recortar_arte.py).
## A arte já vem na vista 3/4 de cima, então fica de frente para a câmera (billboard).
## `width` é a largura em unidades de jogo; a base de calçada fica centrada na origem.
static func art_sprite(path: String, width: float) -> Sprite3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var s := Sprite3D.new()
	s.name = "Arte"
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.pixel_size = width / float(tex.get_width())
	s.offset = Vector2(0, tex.get_height() * 0.5 - tex.get_height() * 0.14)
	return s


## Visual de inimigo: usa a arte se existir; senão o modelo procedural provisório.
static func enemy_visual(data: Dictionary, color: Color, width: int) -> Node3D:
	var spr := art_sprite(String(data.get("arte", "")), float(width) * 1.4)
	if spr:
		var root := Node3D.new()
		root.add_child(spr)
		return root
	return build_enemy(data["modelo"], color, width)


## Visual do personagem na arena (arte "jogo") ou modelo procedural.
static func character_visual(char_data: Dictionary, width := 2.3) -> Node3D:
	var arte: Dictionary = char_data.get("arte", {})
	var spr := art_sprite(String(arte.get("jogo", "")), width)
	if spr:
		var root := Node3D.new()
		root.name = "Modelo"
		root.add_child(spr)
		return root
	return build_character(char_data["id"])


# ---------------------------------------------------------------- PERSONAGENS

static func build_character(id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Modelo"
	var skin := Color("#b07a52")
	match id:
		"guardiao":
			var metal := Color("#6f7a84")
			var couro := Color("#6b4128")
			capsule(root, 0.36, 1.0, metal, Vector3(0, 0.62, 0))
			box(root, Vector3(0.95, 0.28, 0.5), couro, Vector3(0, 0.95, 0))  # ombreiras
			sphere(root, 0.2, skin, Vector3(0, 1.28, 0))
			_hat(root, Color("#8a2c1d"), 1.42, 0.42)
			box(root, Vector3(0.12, 0.85, 0.75), Color("#9a6b33"), Vector3(-0.52, 0.65, -0.05))  # escudo
			box(root, Vector3(0.05, 0.6, 0.55), Color("#e8b04a"), Vector3(-0.59, 0.65, -0.05), 0.4, false)
			cylinder(root, 0.1, 0.1, 0.55, couro, Vector3(-0.18, 0.12, 0))
			cylinder(root, 0.1, 0.1, 0.55, couro, Vector3(0.18, 0.12, 0))
			cylinder(root, 0.07, 0.07, 0.9, Color("#3a3a3a"), Vector3(0.45, 0.85, -0.25)).rotation_degrees = Vector3(-70, 0, 0)
		"cacadora":
			var verde := Color("#2f7a4a")
			capsule(root, 0.24, 0.95, verde, Vector3(0, 0.62, 0))
			box(root, Vector3(0.5, 0.7, 0.12), Color("#1f4f31"), Vector3(0, 0.75, 0.2))  # capa
			sphere(root, 0.17, skin, Vector3(0, 1.22, 0))
			_hat(root, Color("#c2412d"), 1.35, 0.36)
			cylinder(root, 0.07, 0.07, 0.6, Color("#3b2416"), Vector3(-0.12, 0.15, 0))
			cylinder(root, 0.07, 0.07, 0.6, Color("#3b2416"), Vector3(0.12, 0.15, 0))
			var arma := cylinder(root, 0.04, 0.06, 1.2, Color("#5a3a22"), Vector3(0.32, 0.9, -0.35))
			arma.rotation_degrees = Vector3(-65, 0, -10)
			sphere(root, 0.07, Color("#ffe14a"), Vector3(0.36, 1.15, -0.85), 2.0, false)
		_:
			var roupa := Color("#3fb8a5")
			capsule(root, 0.26, 0.8, roupa, Vector3(0, 0.5, 0))
			box(root, Vector3(0.62, 0.72, 0.42), Color("#7a4b2a"), Vector3(0, 0.75, 0.32))  # mochila
			sphere(root, 0.09, Color("#ff7a1f"), Vector3(-0.22, 1.2, 0.36), 2.0)
			sphere(root, 0.09, Color("#7fe3ff"), Vector3(0.0, 1.22, 0.4), 2.0)
			sphere(root, 0.09, Color("#7bd94a"), Vector3(0.22, 1.2, 0.36), 2.0)
			cylinder(root, 0.03, 0.03, 0.5, Color("#c9b79c"), Vector3(0.28, 1.25, 0.3))
			sphere(root, 0.17, skin, Vector3(0, 1.02, 0))
			box(root, Vector3(0.3, 0.08, 0.06), Color("#e8b04a"), Vector3(0, 1.05, -0.15), 1.0)  # óculos
			_hat(root, Color("#5a2d6b"), 1.15, 0.3)
			cylinder(root, 0.07, 0.07, 0.4, Color("#3b2416"), Vector3(-0.12, 0.1, 0))
			cylinder(root, 0.07, 0.07, 0.4, Color("#3b2416"), Vector3(0.12, 0.1, 0))
	return root


static func _hat(root: Node3D, color: Color, y: float, brim: float) -> void:
	# Chapéu de aba larga — referência visual dos bandeirantes/cangaceiros das imagens.
	cylinder(root, brim, brim, 0.05, color, Vector3(0, y, 0))
	cylinder(root, brim * 0.45, brim * 0.55, 0.22, color, Vector3(0, y + 0.12, 0))


# ---------------------------------------------------------------- INIMIGOS

static func build_enemy(model: String, color: Color, width: int) -> Node3D:
	var root := Node3D.new()
	var dark := Color("#1d1a17")
	match model:
		"pombo":
			sphere(root, 0.28, color, Vector3(0, 0.45, 0))
			sphere(root, 0.16, color.lightened(0.15), Vector3(0, 0.72, -0.18))
			cylinder(root, 0.0, 0.06, 0.16, Color("#ff9f2e"), Vector3(0, 0.7, -0.36)).rotation_degrees = Vector3(-90, 0, 0)
			sphere(root, 0.04, Color("#ff3d1f"), Vector3(0.08, 0.78, -0.3), 2.0, false)
			sphere(root, 0.04, Color("#ff3d1f"), Vector3(-0.08, 0.78, -0.3), 2.0, false)
			var wl := box(root, Vector3(0.38, 0.05, 0.22), color.darkened(0.2), Vector3(-0.3, 0.5, 0))
			wl.name = "AsaE"
			var wr := box(root, Vector3(0.38, 0.05, 0.22), color.darkened(0.2), Vector3(0.3, 0.5, 0))
			wr.name = "AsaD"
			box(root, Vector3(0.12, 0.06, 0.12), Color("#b9a27a"), Vector3(0, 0.6, 0.1), 0.0, false)  # engrenagem
		"drone":
			box(root, Vector3(0.45, 0.16, 0.45), color, Vector3(0, 0.6, 0))
			sphere(root, 0.07, Color("#ff2d2d"), Vector3(0, 0.6, -0.24), 3.0, false)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					box(root, Vector3(0.3, 0.04, 0.05), dark, Vector3(sx * 0.25, 0.65, sz * 0.25)).rotation_degrees = Vector3(0, 45 * sx * sz, 0)
					var r := cylinder(root, 0.17, 0.17, 0.02, Color("#a7b1bc"), Vector3(sx * 0.36, 0.7, sz * 0.36), 0.0, false)
					r.name = "Rotor"
			box(root, Vector3(0.22, 0.18, 0.22), Color("#c9a26a"), Vector3(0, 0.42, 0))  # pacote
		"robo":
			box(root, Vector3(0.6, 0.55, 0.45), color, Vector3(0, 0.45, 0))
			box(root, Vector3(0.62, 0.1, 0.47), Color("#f3e3c3"), Vector3(0, 0.5, 0), 0.0, false)
			box(root, Vector3(0.4, 0.3, 0.35), Color("#3a3f47"), Vector3(0, 0.88, 0))
			sphere(root, 0.06, Color("#5ff0ff"), Vector3(-0.1, 0.9, -0.18), 3.0, false)
			sphere(root, 0.06, Color("#5ff0ff"), Vector3(0.1, 0.9, -0.18), 3.0, false)
			cylinder(root, 0.02, 0.02, 0.3, dark, Vector3(0.12, 1.15, 0))
			sphere(root, 0.05, Color("#ff2d2d"), Vector3(0.12, 1.3, 0), 3.0, false)
			cylinder(root, 0.1, 0.12, 0.25, dark, Vector3(-0.18, 0.08, 0))
			cylinder(root, 0.1, 0.12, 0.25, dark, Vector3(0.18, 0.08, 0))
		"fusca":
			var w := float(width) * 0.88
			box(root, Vector3(w, 0.35, 0.75), color, Vector3(0, 0.38, 0))
			var roof := sphere(root, 0.42, color.lightened(0.1), Vector3(0, 0.6, 0.02))
			roof.scale = Vector3(1.9, 0.75, 0.95)
			box(root, Vector3(w * 0.55, 0.2, 0.02), Color("#2a2140"), Vector3(0, 0.72, -0.36), 0.0, false)
			sphere(root, 0.1, Color("#ff3d1f"), Vector3(-w * 0.35, 0.42, -0.38), 4.0, false)
			sphere(root, 0.1, Color("#ff3d1f"), Vector3(w * 0.35, 0.42, -0.38), 4.0, false)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					var wh := cylinder(root, 0.16, 0.16, 0.12, dark, Vector3(sx * w * 0.32, 0.18, sz * 0.26))
					wh.rotation_degrees = Vector3(0, 0, 90)
		"concreto":
			box(root, Vector3(0.82, 0.7, 0.7), color, Vector3(0, 0.45, 0))
			box(root, Vector3(0.5, 0.35, 0.5), color.lightened(0.08), Vector3(0.05, 0.95, 0))
			box(root, Vector3(0.25, 0.5, 0.3), color.darkened(0.1), Vector3(-0.5, 0.45, 0))
			box(root, Vector3(0.25, 0.5, 0.3), color.darkened(0.1), Vector3(0.5, 0.45, 0))
			box(root, Vector3(0.84, 0.08, 0.72), Color("#4c7a3a"), Vector3(0, 0.82, 0), 0.0, false)  # musgo
			sphere(root, 0.06, Color("#ff9f2e"), Vector3(-0.1, 1.0, -0.26), 3.0, false)
			sphere(root, 0.06, Color("#ff9f2e"), Vector3(0.12, 1.0, -0.26), 3.0, false)
			box(root, Vector3(0.05, 0.4, 0.02), Color("#c9a26a"), Vector3(0.2, 0.5, -0.36), 0.0, false)  # vergalhão
		"vagalume":
			var body := sphere(root, 0.18, Color("#3b3020"), Vector3(0, 0.62, 0))
			body.scale = Vector3(1, 0.8, 1.4)
			sphere(root, 0.2, color, Vector3(0, 0.55, 0.22), 4.0, false)  # lanterninha
			var wl := box(root, Vector3(0.36, 0.03, 0.18), Color(1, 1, 1, 0.8), Vector3(-0.22, 0.72, -0.05), 0.0, false)
			wl.name = "AsaE"
			var wr := box(root, Vector3(0.36, 0.03, 0.18), Color(1, 1, 1, 0.8), Vector3(0.22, 0.72, -0.05), 0.0, false)
			wr.name = "AsaD"
			sphere(root, 0.05, Color("#ff9f2e"), Vector3(0.07, 0.68, -0.22), 2.0, false)
			sphere(root, 0.05, Color("#ff9f2e"), Vector3(-0.07, 0.68, -0.22), 2.0, false)
		"macaco":
			capsule(root, 0.24, 0.6, color, Vector3(0, 0.45, 0))
			sphere(root, 0.2, color, Vector3(0, 0.9, -0.05))
			sphere(root, 0.13, Color("#d9b48a"), Vector3(0, 0.86, -0.18))  # cara clara
			sphere(root, 0.05, Color("#120d08"), Vector3(0.06, 0.92, -0.27), 0.0, false)
			sphere(root, 0.05, Color("#120d08"), Vector3(-0.06, 0.92, -0.27), 0.0, false)
			box(root, Vector3(0.36, 0.1, 0.28), Color("#2a1d14"), Vector3(0, 1.08, 0))  # topete de prego
			var tail := cylinder(root, 0.04, 0.05, 0.7, color, Vector3(0, 0.45, 0.35))
			tail.rotation_degrees = Vector3(55, 0, 0)
			sphere(root, 0.12, Color("#c98a3a"), Vector3(0.28, 0.65, -0.15))  # coquinho
		"tatu":
			var shell := sphere(root, 0.42, color, Vector3(0, 0.35, 0))
			shell.scale = Vector3(1.0, 0.75, 1.25)
			for k in 4:
				box(root, Vector3(0.86, 0.05, 0.06), color.darkened(0.3), Vector3(0, 0.55 - absf(k - 1.5) * 0.05, -0.3 + k * 0.2), 0.0, false)
			sphere(root, 0.12, Color("#c9a882"), Vector3(0, 0.3, -0.5))
			cylinder(root, 0.0, 0.06, 0.2, Color("#c9a882"), Vector3(0, 0.3, -0.66)).rotation_degrees = Vector3(-90, 0, 0)
			sphere(root, 0.04, Color("#ff3d1f"), Vector3(0.06, 0.36, -0.58), 2.5, false)
		"cupinzeiro":
			var w2 := float(width) * 0.8
			for k in 3:
				var mound := sphere(root, 0.5 - k * 0.12, color.darkened(k * 0.08), Vector3((k - 1) * 0.42, 0.35 + (1 - absf(k - 1)) * 0.25, 0))
				mound.scale = Vector3(1.1, 1.4, 1.0)
			box(root, Vector3(w2, 0.18, 0.6), color.darkened(0.2), Vector3(0, 0.1, 0))
			for k in 4:
				sphere(root, 0.05, Color("#ffd23d"), Vector3(-0.6 + k * 0.4, 0.5 + (k % 2) * 0.3, -0.42), 3.0, false)
		"toco":
			cylinder(root, 0.36, 0.44, 0.85, color, Vector3(0, 0.42, 0))
			cylinder(root, 0.33, 0.33, 0.04, Color("#c9a26a"), Vector3(0, 0.86, 0), 0.0, false)  # anéis
			for sx in [-1, 1]:
				var root_b := box(root, Vector3(0.14, 0.12, 0.5), color.darkened(0.15), Vector3(sx * 0.35, 0.06, 0.1))
				root_b.rotation_degrees = Vector3(0, sx * 35, 0)
			box(root, Vector3(0.4, 0.08, 0.4), Color("#4c7a3a"), Vector3(0.05, 0.9, 0.05), 0.0, false)  # musgo
			sphere(root, 0.06, Color("#9dff6a"), Vector3(-0.12, 0.6, -0.36), 3.0, false)
			sphere(root, 0.06, Color("#9dff6a"), Vector3(0.12, 0.6, -0.36), 3.0, false)
		_:
			box(root, Vector3(0.7, 0.7, 0.7), color, Vector3(0, 0.4, 0))
	# Modelos são montados de "frente" para -Z; inimigos olham para o jogador (+Z).
	root.rotation_degrees.y = 180.0
	return root


## O chefe: um prédio vivo da Paulista.
static func build_skyscraper() -> Node3D:
	var root := Node3D.new()
	var facade := Color("#4a5566")
	box(root, Vector3(8.0, 7.5, 3.0), facade, Vector3(0, 3.75, 0))
	box(root, Vector3(6.0, 3.0, 2.4), facade.darkened(0.15), Vector3(0, 8.9, 0.1))
	box(root, Vector3(3.0, 1.6, 1.8), facade.darkened(0.25), Vector3(0, 11.1, 0.2))
	var antenna := cylinder(root, 0.05, 0.12, 3.0, Color("#c0c6cc"), Vector3(0, 13.3, 0.2))
	antenna.name = "Antena"
	var lamp := sphere(root, 0.18, Color("#ff2d2d"), Vector3(0, 14.8, 0.2), 6.0, false)
	lamp.name = "Luz"
	# Janelas da fachada (decorativas).
	for row in range(6):
		for col in range(7):
			if (row + col) % 3 == 0:
				continue
			box(root, Vector3(0.6, 0.55, 0.05), Color("#ffd27a"), Vector3(-3.3 + col * 1.1, 2.9 + row * 0.75, 1.52), 1.4, false)
	# "Olhos" e "boca" — o prédio acorda.
	var eye_l := box(root, Vector3(1.4, 0.7, 0.08), Color("#ff3d1f"), Vector3(-1.6, 6.8, 1.54), 4.0, false)
	eye_l.name = "OlhoE"
	var eye_r := box(root, Vector3(1.4, 0.7, 0.08), Color("#ff3d1f"), Vector3(1.6, 6.8, 1.54), 4.0, false)
	eye_r.name = "OlhoD"
	box(root, Vector3(3.6, 0.9, 0.08), Color("#1a1410"), Vector3(0, 1.0, 1.54), 0.0, false)  # garagem/boca
	# Braços mecânicos (guindastes).
	for sx in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "Braco" + ("E" if sx < 0 else "D")
		arm.position = Vector3(sx * 4.2, 5.5, 0.5)
		root.add_child(arm)
		box(arm, Vector3(0.45, 0.45, 3.2), Color("#e8b04a"), Vector3(0, 0, 1.4))
		box(arm, Vector3(0.8, 0.8, 0.8), Color("#3a3f47"), Vector3(0, 0, 3.1))
	return root


## Chefe da Mata Atlântica: a Mula sem Cabeça (fogo no lugar da cabeça). Frente para +Z? Não: corre de lado (eixo X).
static func build_mula() -> Node3D:
	var root := Node3D.new()
	var coat := Color("#3b2416")
	var body := capsule(root, 0.75, 3.0, coat, Vector3(0, 1.7, 0))
	body.rotation_degrees = Vector3(0, 0, 90)
	box(root, Vector3(1.3, 0.25, 1.4), Color("#7a2e1d"), Vector3(-0.1, 2.45, 0))  # sela
	box(root, Vector3(0.6, 0.15, 1.5), Color("#e8b04a"), Vector3(-0.1, 2.32, 0), 0.5, false)
	for lx in [-0.9, 0.9]:
		for lz in [-0.45, 0.45]:
			var leg := Node3D.new()
			leg.name = "Perna"
			leg.position = Vector3(lx, 1.2, lz)
			root.add_child(leg)
			cylinder(leg, 0.13, 0.16, 1.2, coat, Vector3(0, -0.6, 0))
			cylinder(leg, 0.18, 0.18, 0.12, Color("#c9a26a"), Vector3(0, -1.2, 0))  # ferradura
	var neck := cylinder(root, 0.35, 0.45, 0.9, coat, Vector3(1.75, 2.25, 0))
	neck.rotation_degrees = Vector3(0, 0, -40)
	# Fogo onde devia haver cabeça.
	var fire := Node3D.new()
	fire.name = "Fogo"
	fire.position = Vector3(2.15, 2.85, 0)
	root.add_child(fire)
	for k in 5:
		var f := cylinder(fire, 0.0, 0.32 - k * 0.04, 0.8 + k * 0.15, [Color("#ffe14a"), Color("#ff9f2e"), Color("#ff3d1f")][k % 3],
			Vector3(randf_range(-0.12, 0.12), 0.35 + k * 0.08, randf_range(-0.12, 0.12)), 4.0, false)
		f.name = "Chama%d" % k
	var tail := cylinder(root, 0.05, 0.14, 1.1, Color("#1d1110"), Vector3(-1.9, 1.7, 0))
	tail.rotation_degrees = Vector3(0, 0, -50)
	return root


# ---------------------------------------------------------------- VEÍCULOS DE FUNDO

static func build_vehicle(kind: String) -> Node3D:
	var root := Node3D.new()
	var dark := Color("#1d1a17")
	var vlen := 1.6
	match kind:
		"onibus":
			vlen = 3.4
			box(root, Vector3(vlen, 1.1, 1.0), Color("#c2412d"), Vector3(0, 0.75, 0))
			box(root, Vector3(vlen - 0.2, 0.35, 1.02), Color("#cfe6ff"), Vector3(0, 1.0, 0), 0.6, false)
			box(root, Vector3(vlen, 0.12, 1.02), Color("#f3e3c3"), Vector3(0, 0.45, 0), 0.0, false)
		"taxi":
			box(root, Vector3(vlen, 0.4, 0.8), Color("#f3f3ee"), Vector3(0, 0.4, 0))
			box(root, Vector3(1.0, 0.3, 0.7), Color("#f3f3ee"), Vector3(0, 0.75, 0))
			box(root, Vector3(0.4, 0.12, 0.2), Color("#ffd23d"), Vector3(0, 0.96, 0), 2.0, false)
		_:
			box(root, Vector3(vlen, 0.4, 0.8), Color("#2e6fd8"), Vector3(0, 0.4, 0))
			box(root, Vector3(0.9, 0.3, 0.7), Color("#2e6fd8"), Vector3(-0.1, 0.75, 0))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var wh := cylinder(root, 0.18, 0.18, 0.12, dark, Vector3(sx * (vlen * 0.5 - 0.35), 0.18, sz * 0.42))
			wh.rotation_degrees = Vector3(90, 0, 0)
	sphere(root, 0.08, Color("#fff3c4"), Vector3(vlen * 0.5, 0.45, -0.25), 4.0, false)
	sphere(root, 0.08, Color("#fff3c4"), Vector3(vlen * 0.5, 0.45, 0.25), 4.0, false)
	return root
