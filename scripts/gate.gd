extends Area2D

@export var required: int = 50
@export var toll_percent: float = 0.25   # fraction of wallet taken as toll
@export var toll_minimum: int = 4        # if 25% would round below this, this becomes the hard price
@export var push_back_distance: float = 60.0
@export var deny_flash_time: float = 1.0

@onready var blocker: StaticBody2D = $Blocker if has_node("Blocker") else null
@onready var label: Label = $GaugeLabel if has_node("GaugeLabel") else null

var opened := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_label()

func _process(_delta: float) -> void:
	if not opened:
		_update_label()

func _toll_cost() -> int:
	return max(int(round(GameState.wallet * toll_percent)), toll_minimum)

func _update_label() -> void:
	if label:
		label.text = "%d / %d  (toll %d)" % [GameState.lifetime_banked(), required, _toll_cost()]

func _on_body_entered(body: Node2D) -> void:
	if opened or not body.is_in_group("player"):
		return
	if GameState.lifetime_banked() < required:
		_deny(body, "ACCESS DENIED  %d / %d" % [GameState.lifetime_banked(), required])
		return
	var cost := _toll_cost()
	if GameState.wallet < cost:
		_deny(body, "NEED %d WALLET (have %d)" % [cost, GameState.wallet])
		return
	_open(cost)

func _open(cost: int) -> void:
	opened = true
	GameState.spend_wallet(cost)
	if blocker:
		blocker.set_deferred("collision_layer", 0)
		blocker.set_deferred("collision_mask", 0)
	if label:
		label.text = "OPEN"

func _deny(body: Node2D, message: String) -> void:
	var push_dir := (body.global_position - global_position).normalized()
	body.global_position += push_dir * push_back_distance
	if label:
		label.text = message
		await get_tree().create_timer(deny_flash_time).timeout
		if not opened:
			_update_label()
