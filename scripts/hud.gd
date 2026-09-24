extends CanvasLayer

@onready var health_bar = $MarginContainer/HBoxContainer/VBoxContainer/HealthBar
@onready var ammo_label = $MarginContainer/HBoxContainer/VBoxContainer/AmmoLabel
@onready var bubble_label = $MarginContainer/HBoxContainer/VBoxContainer/BubbleLabel

func _ready() -> void:
	$MarginContainer/HBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	GameState.bubbles_changed.connect(_on_bubbles_changed)
	_on_bubbles_changed(GameState.bubbles)
	_connect_player.call_deferred()

func _connect_player() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p:
		p.health_changed.connect(update_health)
		update_health(p.current_health, p.max_health)

func _on_pause_pressed() -> void:
	SceneManager.pause_game()

func _on_bubbles_changed(n: int) -> void:
	bubble_label.text = "Bubbles: %d" % n

func update_health(current: float, max_hp: float) -> void:
	print("hud update_health: ", current, "/", max_hp)
	health_bar.max_value = max_hp
	health_bar.value = current

func update_ammo(count: int) -> void:
	ammo_label.text = "AMMO: %d" % count
