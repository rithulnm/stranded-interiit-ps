extends Button

@export var item: String = "health"
@export var label_text: String = "HP"

func _ready() -> void:
	pressed.connect(func(): GameState.buy(item))
	GameState.bubbles_changed.connect(func(_n): _refresh())
	GameState.upgrade_bought.connect(func(_i): _refresh())
	_refresh()

func _refresh() -> void:
	var c := GameState.cost_of(item)
	text = "%s\n%d" % [label_text, c]
	disabled = GameState.bubbles < c
