class_name RunBuild
extends RefCounted
## A build da run: 3 slots de bola + passivas + relíquias. Calcula stats e gera as escolhas de level up.

const MAX_SLOTS := 3
const MAX_BALL_LEVEL := 5
const MAX_PASSIVES := 6
const FUSION_MIN_LEVEL := 3

var character: Dictionary
var slots: Array = []          # [{id, level, timer, queue, queue_timer}]
var passives: Dictionary = {}  # id -> nível
var relics: Array = []
var alquimia_bonus := 0.0      # acumulado pela passiva Alquimia
var colecionador_bonus := 0.0
var colecionador_timer := 0.0
var cacada_bonus := 0.0        # passiva da Caçadora
var rerolls := 0


func _init(char_data: Dictionary) -> void:
	character = char_data
	rerolls = Save.upgrade_level("sorte")
	add_ball(char_data["bola_inicial"])


# ------------------------------------------------------------------ consultas

func passive(id: String) -> int:
	return int(passives.get(id, 0))


func pval(id: String) -> float:
	return GameData.passive_value(id, passive(id))


func has_relic(id: String) -> bool:
	return relics.has(id)


func slot_index(ball_id: String) -> int:
	for i in slots.size():
		if slots[i]["id"] == ball_id:
			return i
	return -1


func damage_mult() -> float:
	var m := float(character["dano"])
	m *= 1.0 + pval("forca") / 100.0
	m *= 1.0 + Save.upgrade_level("dano") * 0.06
	if has_relic("ampulheta"):
		m *= 1.4
	if has_relic("coracao_dragao"):
		m *= 1.2
	return m


func fire_rate_mult() -> float:
	var m := float(character["cadencia"])
	m *= 1.0 + pval("cadencia") / 100.0
	m *= 1.0 + Save.upgrade_level("cadencia") * 0.05
	if has_relic("cafezinho"):
		m *= 1.25
	return m


func ball_speed_mult() -> float:
	var m := 1.0 + pval("impulso") / 100.0 + colecionador_bonus
	if has_relic("ampulheta"):
		m *= 0.75
	return m


func crit_bonus() -> float:
	return float(character["critico"]) + pval("precisao") / 100.0 + cacada_bonus


func size_mult() -> float:
	return 1.0 + pval("calibre") / 100.0


func extra_ricochetes() -> int:
	var r := int(pval("tabela"))
	if has_relic("bilhete_unico"):
		r += 2
	return r


func pickup_radius() -> float:
	return 1.6 * (1.0 + pval("ima") / 100.0 + Save.upgrade_level("ima") * 0.25)


func xp_mult() -> float:
	return 0.8 if has_relic("bolsa_mercador") else 1.0


func option_count() -> int:
	return 4 if has_relic("bolsa_mercador") else 3


func max_hp_bonus() -> float:
	return pval("vitalidade") + Save.upgrade_level("vida") * 12.0


## Stats finais de uma bola num slot.
func ball_stats(ball_id: String, level: int) -> Dictionary:
	var b: Dictionary = GameData.balls[ball_id]
	var elements: Array = b["elementos"].duplicate()
	if has_relic("coracao_dragao"):
		elements.erase("gelo")
		if not elements.has("fogo"):
			elements.push_front("fogo")
	var qty := int(b["quantidade"])
	if level >= 3:
		qty += 1
	if level >= 5:
		qty += 1
	return {
		"id": ball_id,
		"nome": b["nome"],
		"nivel": level,
		"dano": float(b["dano"]) * (1.0 + 0.3 * (level - 1)) * damage_mult(),
		"velocidade": float(b["velocidade"]),
		"tamanho": float(b["tamanho"]) * size_mult(),
		"ricochetes": int(b["ricochetes"]) + extra_ricochetes() + (1 if level >= 4 else 0),
		"piercing": int(b["piercing"]),
		"quantidade": qty,
		"cooldown": float(b["cooldown"]) * (1.0 - 0.06 * (level - 1)) / fire_rate_mult(),
		"critico": float(b["critico"]) + crit_bonus(),
		"elementos": elements,
		"comportamento": b["comportamento"],
		"tags": b["tags"],
		"cor": Color(b["cor"]),
	}


# ------------------------------------------------------------------ mudanças

func add_ball(ball_id: String) -> void:
	if slots.size() >= MAX_SLOTS:
		return
	slots.append({"id": ball_id, "level": 1, "timer": 0.3 + slots.size() * 0.25, "queue": 0, "queue_timer": 0.0})


func fuse(fusion_id: String) -> void:
	var comps: Array = GameData.balls[fusion_id]["componentes"]
	var ia := slot_index(comps[0])
	var ib := slot_index(comps[1])
	var lvl := maxi(slots[ia]["level"], slots[ib]["level"]) - 1
	slots[ia] = {"id": fusion_id, "level": clampi(lvl, 1, MAX_BALL_LEVEL), "timer": 0.2, "queue": 0, "queue_timer": 0.0}
	slots.remove_at(ib)


func can_fuse(fusion_id: String) -> bool:
	if not Save.has_fusion(fusion_id):
		return false
	var comps: Array = GameData.balls[fusion_id]["componentes"]
	for c in comps:
		var i := slot_index(c)
		if i < 0 or int(slots[i]["level"]) < FUSION_MIN_LEVEL:
			return false
	return true


func apply_offer(offer: Dictionary) -> void:
	match offer["tipo"]:
		"nova_bola":
			add_ball(offer["id"])
		"up_bola":
			var i := slot_index(offer["id"])
			if i >= 0:
				slots[i]["level"] = mini(int(slots[i]["level"]) + 1, MAX_BALL_LEVEL)
		"passiva":
			passives[offer["id"]] = passive(offer["id"]) + 1
		"fusao":
			fuse(offer["id"])
		"reliquia":
			relics.append(offer["id"])


# ------------------------------------------------------------------ ofertas (escolha 1 de 3)

func generate_offers(rng: RandomNumberGenerator, count := -1) -> Array:
	if count < 0:
		count = option_count()
	var pool: Array = []  # [offer, weight]
	# Fusões têm prioridade: são o "momento uau" da build.
	for fid in GameData.fusion_ids:
		if can_fuse(fid):
			pool.append([_offer("fusao", fid), 6.0])
	# Upgrades das bolas atuais.
	for s in slots:
		if int(s["level"]) < MAX_BALL_LEVEL:
			pool.append([_offer("up_bola", s["id"], int(s["level"]) + 1), 3.0])
	# Novas bolas (se há slot livre).
	if slots.size() < MAX_SLOTS:
		for bid in GameData.balls:
			if GameData.is_fusion(bid) or slot_index(bid) >= 0 or not Save.has_ball(bid):
				continue
			if has_relic("coracao_dragao") and GameData.balls[bid]["elementos"].has("gelo"):
				continue
			pool.append([_offer("nova_bola", bid), 2.2])
	# Passivas.
	for pid in GameData.passives:
		var lv := passive(pid)
		if lv >= int(GameData.passives[pid]["max"]):
			continue
		if lv == 0 and passives.size() >= MAX_PASSIVES:
			continue
		pool.append([_offer("passiva", pid, lv + 1), 1.6 if lv == 0 else 2.0])
	var chosen: Array = []
	while chosen.size() < count and pool.size() > 0:
		var total := 0.0
		for p in pool:
			total += p[1]
		var r := rng.randf() * total
		for i in pool.size():
			r -= pool[i][1]
			if r <= 0.0:
				chosen.append(pool[i][0])
				pool.remove_at(i)
				break
	if chosen.is_empty():
		chosen.append({"tipo": "cura", "id": "cura", "nome": "Pão de Queijo", "descricao": "Recupera 30 de vida.",
			"raridade": "comum", "cor": Color("#e8b04a"), "nivel": 0, "tags": []})
	return chosen


func relic_offers(rng: RandomNumberGenerator, count := 3) -> Array:
	var ids: Array = []
	for rid in GameData.relics:
		if Save.has_relic(rid) and not has_relic(rid):
			ids.append(rid)
	ids.shuffle()
	var out: Array = []
	for i in mini(count, ids.size()):
		out.append(_offer("reliquia", ids[i]))
	return out


func _offer(tipo: String, id: String, level := 1) -> Dictionary:
	var o := {"tipo": tipo, "id": id, "nivel": level}
	match tipo:
		"nova_bola", "up_bola", "fusao":
			var b: Dictionary = GameData.balls[id]
			o["nome"] = b["nome"]
			o["descricao"] = b["descricao"]
			o["raridade"] = b["raridade"]
			o["cor"] = Color(b["cor"])
			o["tags"] = b["tags"]
			if tipo == "up_bola":
				o["descricao"] = "+30%% dano%s%s" % [
					", +1 bola por disparo" if level == 3 or level == 5 else "",
					", +1 ricochete" if level == 4 else ""]
		"passiva":
			var p: Dictionary = GameData.passives[id]
			o["nome"] = p["nome"]
			o["descricao"] = GameData.passive_text(id, level)
			o["raridade"] = p["raridade"]
			o["cor"] = Color(p["cor"])
			o["tags"] = p["tags"]
		"reliquia":
			var r: Dictionary = GameData.relics[id]
			o["nome"] = r["nome"]
			o["descricao"] = r["descricao"]
			o["raridade"] = r["raridade"]
			o["cor"] = Color(r["cor"])
			o["tags"] = []
	return o
