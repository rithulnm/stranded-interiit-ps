extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.global_position = get_node("../PlayerStart").global_position
		body.velocity = Vector2.ZERO
		body.current_health = body.max_health
		body.health_changed.emit(body.current_health, body.max_health)
