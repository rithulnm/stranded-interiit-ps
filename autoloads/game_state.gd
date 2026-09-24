extends Node

signal bubbles_changed(amount: int)

var bubbles: int = 0
signal upgrade_bought(item: String)

var bonus_health: int = 0
var bonus_damage: int = 0
var bonus_speed: float = 0.0
var times_bought := {"health": 0, "damage": 0, "speed": 0}

const BASE_COSTS := {"health": 10, "damage": 15, "speed": 12}


func cost_of(item: String) -> int:
	return BASE_COSTS[item] + 5 * times_bought[item]   # gets pricier each buy

func buy(item: String) -> bool:
	if not spend(cost_of(item)):
		return false
	times_bought[item] += 1
	match item:
		"health": bonus_health += 25
		"damage": bonus_damage += 5
		"speed": bonus_speed += 60.0
	upgrade_bought.emit(item)
	return true

var checkpoint := {}

func save_checkpoint() -> void:
	checkpoint = {
		"bubbles": bubbles,
		"bonus_health": bonus_health,
		"bonus_damage": bonus_damage,
		"bonus_speed": bonus_speed,
		"times_bought": times_bought.duplicate(),
	}

func restore_checkpoint() -> void:
	if checkpoint.is_empty():
		reset()
		return
	bubbles = checkpoint["bubbles"]
	bonus_health = checkpoint["bonus_health"]
	bonus_damage = checkpoint["bonus_damage"]
	bonus_speed = checkpoint["bonus_speed"]
	times_bought = checkpoint["times_bought"].duplicate()
	bubbles_changed.emit(bubbles)
	
func add_bubbles(n: int) -> void:
	bubbles += n
	bubbles_changed.emit(bubbles)

func spend(n: int) -> bool:
	if bubbles < n:
		return false
	bubbles -= n
	bubbles_changed.emit(bubbles)
	return true

func reset() -> void:
	checkpoint = {}
	bubbles = 0
	bubbles_changed.emit(bubbles)
	bonus_health = 0
	bonus_damage = 0
	bonus_speed = 0.0
	times_bought = {"health": 0, "damage": 0, "speed": 0}
