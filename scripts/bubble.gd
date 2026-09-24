extends Area2D

@export var value: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# gentle bob so it reads as a pickup
	var t := create_tween().set_loops()
	t.tween_property($Sprite2D, "position:y", -6.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)
	t.tween_property($Sprite2D, "position:y", 6.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.add_bubbles(value)
		queue_free()
