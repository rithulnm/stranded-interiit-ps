extends Area2D

var used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if used or not body.is_in_group("player"):
		return
	used = true
	SceneManager.call_deferred("show_level_complete")
