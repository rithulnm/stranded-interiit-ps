extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var is_final := SceneManager.current_level >= SceneManager.LEVELS.size() - 1
	if is_final:
		$Panel/ButtonContainer/TitleLabel.text = "YOU ESCAPED!\nBubbles: %d" % GameState.bubbles
		$Panel/ButtonContainer/NextLevelButton.hide()
	else:
		$Panel/ButtonContainer/TitleLabel.text = "LEVEL COMPLETE\nBubbles: %d" % GameState.bubbles
	$Panel/ButtonContainer/NextLevelButton.pressed.connect(_on_next_level_pressed)
	$Panel/ButtonContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/ButtonContainer/QuitToMenuButton.pressed.connect(_on_quit_pressed)

func _on_next_level_pressed() -> void:
	queue_free()
	SceneManager.go_to_next_level()

func _on_retry_pressed() -> void:
	queue_free()
	SceneManager.restart_level()

func _on_quit_pressed() -> void:
	queue_free()
	SceneManager.go_to_main_menu()
