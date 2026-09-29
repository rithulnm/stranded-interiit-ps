extends Button

@export var item: String = "health"
@export var label_text: String = "HP"

func _ready() -> void:
	pressed.connect(_on_pressed)
	GameState.wallet_changed.connect(func(_n): _refresh())
	GameState.upgrade_bought.connect(func(_i): _refresh())
	GameState.bottling_state_changed.connect(func(_a): _refresh())
	_refresh()

func _on_pressed() -> void:
	if not GameState.in_bottling_point:
		return
	GameState.buy(item)

func _refresh() -> void:
	var c := GameState.cost_of(item)
	text = "%s\n%d" % [label_text, c]
	disabled = not GameState.in_bottling_point or GameState.wallet < c
