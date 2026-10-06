extends Node
## Som do jogo: efeitos com limite de repetição (ricochetes não viram ruído) e música em loop.
## Os arquivos ficam em assets/audio (gerados por tools/gerar_audio.py — troque pelo áudio final com o mesmo nome).

const POOL := 12
const MIN_GAP := {"dano": 0.3, "ricochete": 0.05, "acerto": 0.035, "abate": 0.04, "gema": 0.05, "chute": 0.06, "explosao": 0.08}
const VOLUME_DB := {"musica_forro": -9.0, "ricochete": -10.0, "acerto": -8.0, "gema": -10.0, "abate": -6.0, "chute": -6.0}

var _players: Array = []
var _next := 0
var _streams: Dictionary = {}
var _last: Dictionary = {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	apply_volume()


func _stream(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	var path := "res://assets/audio/%s.wav" % name
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[name] = s
	return s


func play(name: String, pitch_jitter := 0.08, volume_db := 0.0) -> void:
	if not enabled():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -10.0)) < float(MIN_GAP.get(name, 0.0)):
		return
	_last[name] = now
	var s := _stream(name)
	if s == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.volume_db = float(VOLUME_DB.get(name, 0.0)) + volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func music(name := "musica_forro") -> void:
	var s := _stream(name)
	if s == null:
		return
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 2  # 16 bits mono
	if _music.stream == s and _music.playing:
		return
	_music.stream = s
	_music.volume_db = float(VOLUME_DB.get(name, 0.0))
	if enabled():
		_music.play()


func enabled() -> bool:
	return bool(Save.data["opcoes"].get("som", true))


func toggle() -> void:
	Save.data["opcoes"]["som"] = not enabled()
	Save.save_game()
	apply_volume()


func apply_volume() -> void:
	var vol := float(Save.data["opcoes"].get("volume", 0.8))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.001)))
	AudioServer.set_bus_mute(0, not enabled())
	if enabled() and _music.stream and not _music.playing:
		_music.play()
