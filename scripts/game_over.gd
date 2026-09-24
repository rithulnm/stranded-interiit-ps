extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/ButtonContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/ButtonContainer/QuitToMenuButton.pressed.connect(_on_quit_pressed)

func _on_retry_pressed() -> void:
	get_tree().paused = false
	queue_free()
	SceneManager.restart_level()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	queue_free()
	SceneManager.go_to_main_menu()
