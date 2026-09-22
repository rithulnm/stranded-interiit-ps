extends Control

func _ready() -> void:
	$ButtonContainer/PlayButton.pressed.connect(_on_play_pressed)
	$ButtonContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	SceneManager.start_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
