extends CanvasLayer

@onready var health_bar = $MarginContainer/HBoxContainer/VBoxContainer/HealthBar
@onready var ammo_label = $MarginContainer/HBoxContainer/VBoxContainer/AmmoLabel
@onready var bubble_label = $MarginContainer/HBoxContainer/VBoxContainer/BubbleLabel
@onready var wallet_label = $MarginContainer/HBoxContainer/VBoxContainer/WalletLabel
@onready var bank_button = $MarginContainer/HBoxContainer/VBoxContainer/BankButton

func _ready() -> void:
	$MarginContainer/HBoxContainer/PauseButton.pressed.connect(_on_pause_pressed)
	GameState.unbanked_changed.connect(_on_unbanked_changed)
	GameState.wallet_changed.connect(_on_wallet_changed)
	GameState.bottling_state_changed.connect(_on_bottling_state_changed)
	_on_unbanked_changed(GameState.unbanked)
	_on_wallet_changed(GameState.wallet)
	_on_bottling_state_changed(GameState.in_bottling_point)

	bank_button.pressed.connect(_on_bank_pressed)

func _on_pause_pressed() -> void:
	SceneManager.pause_game()

func _on_unbanked_changed(n: int) -> void:
	bubble_label.text = "Bubbles: %d" % n
	_refresh_bank_button()

func _on_wallet_changed(n: int) -> void:
	wallet_label.text = "Wallet: %d" % n

func _on_bottling_state_changed(active: bool) -> void:
	bank_button.visible = active
	_refresh_bank_button()

func _refresh_bank_button() -> void:
	if not GameState.in_bottling_point:
		return
	bank_button.disabled = not GameState.bank_would_improve(GameState.current_bottling_level)

func _on_bank_pressed() -> void:
	if GameState.current_bottling_point:
		GameState.current_bottling_point.do_bank()

func update_health(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current

func update_ammo(count: int) -> void:
	ammo_label.text = "AMMO: %d" % count
