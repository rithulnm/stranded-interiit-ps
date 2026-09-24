extends Node2D

func _ready() -> void:
	#$Player.health_changed.connect($HUD.update_health)
	$Player.died.connect(_on_player_died)
	#$HUD.update_health($Player.current_health, $Player.max_health)  # initial fill

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	SceneManager.show_game_over()
	
