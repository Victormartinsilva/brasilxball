extends Node
## Progressão permanente (meta). Salvo em user:// — no navegador vira IndexedDB.

const PATH := "user://ballxbrasil_save.json"
const VERSION := 1

## Arsenal: os 6 ATRIBUTOS do GDD (Grota Funda) + extras. id -> {nome, grupo, max, custo, descricao}
## Dica para o jogador: "Na dúvida, invista em Raça + Torcida."
const UPGRADES := {
	"folego": {"nome": "Fôlego", "grupo": "atributo", "max": 5, "custo": 25, "descricao": "Vida: +12 de vida máxima por nível."},
	"raca": {"nome": "Raça", "grupo": "atributo", "max": 5, "custo": 30, "descricao": "Dano base: +6% por nível."},
	"torcida": {"nome": "Torcida", "grupo": "atributo", "max": 5, "custo": 30, "descricao": "Bolinhas de Gude: +10% de dano por nível e +1 bolinha inicial a cada 2 níveis."},
	"ginga": {"nome": "Ginga", "grupo": "atributo", "max": 5, "custo": 30, "descricao": "Velocidade: +4% da bola e do movimento por nível."},
	"malandragem": {"nome": "Malandragem", "grupo": "atributo", "max": 5, "custo": 30, "descricao": "Crítico e chute: +2% de crítico e +5% de cadência por nível."},
	"sabedoria": {"nome": "Sabedoria", "grupo": "atributo", "max": 5, "custo": 35, "descricao": "Área e status: +8% de área de efeito e de dano de Ardência/Peçonha por nível."},
	"ima": {"nome": "Imã de Sucata", "grupo": "extra", "max": 3, "custo": 20, "descricao": "+25% de alcance de coleta por nível."},
	"sorte": {"nome": "Patuá", "grupo": "extra", "max": 3, "custo": 40, "descricao": "+1 \"Tirar na Sorte\" grátis por run, por nível."},
	"banco": {"nome": "Casa da Rezadeira", "grupo": "extra", "max": 3, "custo": 45, "descricao": "+1 \"Mandar pro Banco\" por run: tira uma opção do sorteio de vez."},
}
const OLD_UPGRADE_KEYS := {"vida": "folego", "dano": "raca", "cadencia": "malandragem"}

## Fusões liberadas no Laboratório. As duas primeiras já vêm liberadas.
const FUSION_COSTS := {
	"termodinamica": 0, "plasma": 0, "bomba_sao_joao": 0,
	"neurotoxica": 80, "minuano": 70, "fumace": 70, "peixeira": 70,
	"cristo_redentor": 120, "singularidade": 120,
}

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	var balls: Array = []
	for id in GameData.balls:
		if GameData.balls[id].get("inicial", false):
			balls.append(id)
	var relics: Array = []
	for id in GameData.relics:
		if GameData.relics[id].get("inicial", false):
			relics.append(id)
	var fusions: Array = []
	for id in FUSION_COSTS:
		if FUSION_COSTS[id] == 0:
			fusions.append(id)
	return {
		"versao": VERSION,
		"sucata": 0,
		"upgrades": {},
		"bolas": balls,
		"fusoes": fusions,
		"reliquias": relics,
		"descobertas": [],
		"regioes": ["sao_paulo"],
		"stats": {"runs": 0, "vitorias": 0, "abates": 0, "melhor_tempo": 0.0, "melhor_combo": 0, "chefes": 0},
		"opcoes": {"volume": 0.8, "tremor": true},
	}


func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_merge(data, parsed)
	_migrate()


## Conteúdo novo marcado como inicial entra em saves antigos sem apagar o progresso.
func _migrate() -> void:
	var fresh := default_data()
	for key in ["bolas", "reliquias", "fusoes"]:
		for id in fresh[key]:
			if not data[key].has(id):
				data[key].append(id)
	# Melhorias antigas viram atributos (Couraça → Fôlego, Afiação → Raça, Engrenagem → Malandragem).
	var ups: Dictionary = data["upgrades"]
	for old in OLD_UPGRADE_KEYS:
		if ups.has(old):
			var new_key: String = OLD_UPGRADE_KEYS[old]
			ups[new_key] = maxi(int(ups.get(new_key, 0)), int(ups[old]))
			ups.erase(old)


func _merge(base: Dictionary, incoming: Dictionary) -> void:
	for k in incoming:
		if base.has(k) and typeof(base[k]) == TYPE_DICTIONARY and typeof(incoming[k]) == TYPE_DICTIONARY:
			_merge(base[k], incoming[k])
		else:
			base[k] = incoming[k]


func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


func reset() -> void:
	data = default_data()
	save_game()


func sucata() -> int:
	return int(data["sucata"])


func add_sucata(amount: int) -> void:
	data["sucata"] = sucata() + amount


func spend(amount: int) -> bool:
	if sucata() < amount:
		return false
	data["sucata"] = sucata() - amount
	save_game()
	return true


func upgrade_level(id: String) -> int:
	return int(data["upgrades"].get(id, 0))


func upgrade_cost(id: String) -> int:
	var u: Dictionary = UPGRADES[id]
	return int(u["custo"]) * (upgrade_level(id) + 1)


func buy_upgrade(id: String) -> bool:
	if upgrade_level(id) >= int(UPGRADES[id]["max"]):
		return false
	if not spend(upgrade_cost(id)):
		return false
	data["upgrades"][id] = upgrade_level(id) + 1
	save_game()
	return true


func has_ball(id: String) -> bool:
	return data["bolas"].has(id)


func has_fusion(id: String) -> bool:
	return data["fusoes"].has(id)


func has_relic(id: String) -> bool:
	return data["reliquias"].has(id)


func unlock(list_key: String, id: String, cost: int) -> bool:
	if data[list_key].has(id):
		return false
	if not spend(cost):
		return false
	data[list_key].append(id)
	save_game()
	return true


func discover(id: String) -> void:
	if not data["descobertas"].has(id):
		data["descobertas"].append(id)


func record_run(result: Dictionary) -> void:
	var s: Dictionary = data["stats"]
	s["runs"] = int(s["runs"]) + 1
	s["abates"] = int(s["abates"]) + int(result.get("abates", 0))
	s["melhor_combo"] = maxi(int(s["melhor_combo"]), int(result.get("melhor_combo", 0)))
	if result.get("vitoria", false):
		s["vitorias"] = int(s["vitorias"]) + 1
		s["chefes"] = int(s["chefes"]) + 1
		var t := float(result.get("tempo", 0.0))
		if float(s["melhor_tempo"]) <= 0.0 or t < float(s["melhor_tempo"]):
			s["melhor_tempo"] = t
		# Vencer o primeiro chefe revela a relíquia lendária no Relicário.
		discover("coracao_dragao")
	add_sucata(int(result.get("sucata", 0)))
	for id in result.get("descobertas", []):
		discover(id)
	save_game()
