extends CanvasLayer

func _ready() -> void:
	$Panel/ButtonContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/ButtonContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/ButtonContainer/QuitToMenuButton.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	SceneManager.resume_game()

func _on_restart_pressed() -> void:
	SceneManager.restart_level()

func _on_quit_pressed() -> void:
	SceneManager.go_to_main_menu()
