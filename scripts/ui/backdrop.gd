class_name Backdrop
extends Node3D
## Fundo vivo dos menus: a maquete da Paulista com câmera orbitando e os três heróis na faixa de pedestres.

var _cam: Camera3D
var _t := 0.0


func _ready() -> void:
	add_child(DioramaSaoPaulo.new())
	var ids := ["guardiao", "cacadora", "alquimista"]
	for i in ids.size():
		var m := Models.character_visual(GameData.characters[ids[i]])
		m.position = Vector3(-1.6 + i * 1.6, 0, 0.4)
		add_child(m)
	# Alguns inimigos parados ao fundo, como uma "foto" da batalha.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var models := ["pombo", "drone", "robo", "concreto", "pombo", "drone"]
	for i in 14:
		var id: String = models[rng.randi() % models.size()]
		var data: Dictionary = GameData.enemies.get(id, GameData.enemies["pombo"])
		var e := Models.enemy_visual(data, Color(data["cor"]), int(data.get("largura", 1)))
		e.position = Vector3(rng.randi_range(-5, 5), 0, -rng.randi_range(12, 22))
		add_child(e)
	_cam = Camera3D.new()
	_cam.fov = 45.0
	add_child(_cam)
	_cam.current = true
	_update_cam()


func _process(delta: float) -> void:
	_t += delta
	_update_cam()


func _update_cam() -> void:
	var a := sin(_t * 0.12) * 0.55
	var target := Vector3(0, 1.5, -9.0)
	_cam.position = target + Vector3(sin(a) * 15.0, 9.5 + sin(_t * 0.2) * 0.8, cos(a) * 15.0)
	_cam.look_at(target, Vector3.UP)
