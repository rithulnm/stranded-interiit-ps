extends ProgressBar

func _on_player_health_changed(current: int, max: int) -> void:
	value = current
	max_value = max
