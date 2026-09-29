extends Node2D

func _ready() -> void:
	if GameState.has_respawn_point:
		$Player.global_position = GameState.respawn_point
	else:
		$Player.global_position = $PlayerStart.global_position
	$Player.health_changed.connect($HUD.update_health)
	$HUD.update_health($Player.current_health, $Player.max_health) 
	$Player.died.connect(_on_player_died)

func _on_player_died() -> void:
	GameState.clear_unbanked_on_death()
	await get_tree().create_timer(1.0).timeout
	SceneManager.show_game_over()
