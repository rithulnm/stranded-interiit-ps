extends Node

signal unbanked_changed(amount: int)
signal wallet_changed(amount: int)
signal bottling_state_changed(active: bool)
signal upgrade_bought(item: String)


var unbanked: int = 0      # carried bubbles — lost on death
var wallet: int = 0        # spendable, safe — only the shop touches this

var bonus_health: int = 0
var bonus_damage: int = 0
var bonus_speed: float = 0.0
var times_bought := {"health": 0, "damage": 0, "speed": 0}

const BASE_COSTS := {"health": 10, "damage": 15, "speed": 12}

var in_bottling_point: bool = false
var current_bottling_level: String = ""
var current_bottling_point: Node2D = null
#checkpint stuff
var respawn_point: Vector2 = Vector2.ZERO
var has_respawn_point: bool = false


func cost_of(item: String) -> int:
	return BASE_COSTS[item] + 5 * times_bought[item]

func buy(item: String) -> bool:
	if not spend_wallet(cost_of(item)):
		return false
	times_bought[item] += 1
	match item:
		"health": bonus_health += 25
		"damage": bonus_damage += 5
		"speed": bonus_speed += 60.0
	upgrade_bought.emit(item)
	return true

var total_banked: int = 0  

func lifetime_banked() -> int:
	return total_banked

func bank(_level_name: String) -> void:
	wallet += unbanked
	total_banked += unbanked
	unbanked = 0
	unbanked_changed.emit(unbanked)
	wallet_changed.emit(wallet)

func bank_would_improve(_level_name: String) -> bool:
	return unbanked > 0

func add_bubbles(n: int) -> void:
	unbanked += n
	unbanked_changed.emit(unbanked)

func spend_wallet(n: int) -> bool:
	if wallet < n:
		return false
	wallet -= n
	wallet_changed.emit(wallet)
	return true

func spill_unbanked() -> int:
	if unbanked <= 0:
		return 0
	var amount: int = max(1, int(round(unbanked * 0.25)))
	amount = min(amount, unbanked)
	unbanked -= amount
	unbanked_changed.emit(unbanked)
	return amount

func clear_unbanked_on_death() -> void:
	unbanked = 0
	unbanked_changed.emit(unbanked)
	
func reset() -> void:
	unbanked = 0
	wallet = 0
	total_banked = 0
	times_bought = {"health": 0, "damage": 0, "speed": 0}
	bonus_health = 0
	bonus_damage = 0
	bonus_speed = 0.0
	respawn_point = Vector2.ZERO
	has_respawn_point = false
	unbanked_changed.emit(unbanked)
	wallet_changed.emit(wallet)
	
func clear_level_respawn() -> void:
	respawn_point = Vector2.ZERO
	has_respawn_point = false
