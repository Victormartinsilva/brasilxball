extends Node
## Fluxo do jogo: Menu → Acampamento → Run → Resultado → Acampamento.
## Argumentos de linha de comando (após "--"):
##   --autotest [personagem] [segundos]  roda uma run automática e encerra (usado no CI).

var _screen: Node
var _backdrop: Node3D
var _autotest := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--autotest"):
		_start_autotest(args)
		return
	if _start_from_url():
		return
	goto_menu()


## Atalhos de QA na versão web: ?teste=chefe&personagem=cacadora  |  ?teste=nivel
func _start_from_url() -> bool:
	if not OS.has_feature("web"):
		return false
	var query = JavaScriptBridge.eval("window.location.search", true)
	if typeof(query) != TYPE_STRING or query == "":
		return false
	var params := {}
	for pair in String(query).trim_prefix("?").split("&"):
		var kv := pair.split("=")
		if kv.size() == 2:
			params[kv[0]] = kv[1]
	if not params.has("teste"):
		return false
	var char_id: String = params.get("personagem", "alquimista")
	if not GameData.characters.has(char_id):
		char_id = "alquimista"
	start_run(char_id, "sao_paulo")
	var run := _screen as Run
	match params["teste"]:
		"chefe":
			run.time = float(run.region["tempo_chefe"]) - 3.0
			run.feira_done = run.region.get("eventos_feira", []).duplicate()
			for i in 12:
				run.add_xp(run.xp_next)
		"nivel":
			run.add_xp(run.xp_next)
		"feira":
			run.time = float(run.region["eventos_feira"][0]) - 1.0
	return true


func _clear() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if _screen:
		_screen.queue_free()
		_screen = null


func _ensure_backdrop() -> void:
	if _backdrop == null:
		_backdrop = Backdrop.new()
		add_child(_backdrop)


func _drop_backdrop() -> void:
	if _backdrop:
		_backdrop.queue_free()
		_backdrop = null


func goto_menu() -> void:
	_ensure_backdrop()
	_clear()
	var m := MenuScreen.new()
	m.play_pressed.connect(func(): goto_base())
	add_child(m)
	_screen = m


func goto_base() -> void:
	_ensure_backdrop()
	_clear()
	var b := BaseScreen.new()
	b.start_run.connect(start_run)
	b.back.connect(goto_menu)
	add_child(b)
	_screen = b


func start_run(char_id: String, region_id: String) -> void:
	_clear()
	_drop_backdrop()
	var r := Run.new()
	r.setup(char_id, region_id)
	r.autoplay = _autotest
	r.finished.connect(_on_run_finished)
	add_child(r)
	_screen = r


func _on_run_finished(result: Dictionary) -> void:
	if _autotest:
		print("AUTOTEST_RESULT ", JSON.stringify(result))
		get_tree().quit(0)
		return
	Save.record_run(result)
	_clear()
	_ensure_backdrop()
	var res := ResultsScreen.new()
	res.setup(result)
	res.done.connect(goto_base)
	add_child(res)
	_screen = res


func _start_autotest(args: PackedStringArray) -> void:
	_autotest = true
	var i := args.find("--autotest")
	var char_id := "alquimista"
	var limit := 420.0
	if args.size() > i + 1 and GameData.characters.has(args[i + 1]):
		char_id = args[i + 1]
	if args.size() > i + 2:
		limit = float(args[i + 2])
	# Libera todo o conteúdo para o teste exercitar o máximo de sistemas.
	for id in GameData.balls:
		if not Save.data["bolas"].has(id):
			Save.data["bolas"].append(id)
	for id in Save.FUSION_COSTS:
		if not Save.data["fusoes"].has(id):
			Save.data["fusoes"].append(id)
	for id in GameData.relics:
		if not Save.data["reliquias"].has(id):
			Save.data["reliquias"].append(id)
	start_run(char_id, "sao_paulo")
	var run := _screen as Run
	# Timeout de segurança (em tempo real).
	get_tree().create_timer(limit, true, false, true).timeout.connect(func():
		print("AUTOTEST_TIMEOUT tempo=%.1f nivel=%d abates=%d hp=%.0f chefe=%s" % [run.time, run.level, run.kills, run.hp, run.boss_spawned])
		get_tree().quit(0))
