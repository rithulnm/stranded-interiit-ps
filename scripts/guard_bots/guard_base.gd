extends CharacterBody2D
class_name GuardBase

@export var max_health: int = 30
@export var drop_count: int = 3
@export var contact_damage: int = 15
@export var gravity: float = 1500.0
@export var guard_color: Color = Color.WHITE
@export var bubble_scene: PackedScene = preload("res://scenes/bubble.tscn")
@export var contact_damage_cooldown: float = 0.6

var _contact_cooldown_timer: float = 0.0
var health: int
var player_ref: Node2D = null

func _ready() -> void:
	add_to_group("guard")
	health = max_health
	if has_node("Sprite2D"):
		var sprite: CanvasItem = $Sprite2D
		sprite.modulate = guard_color
	_on_setup()

func _on_setup() -> void:
	pass  # override per drone for type-specific ready logic

func _physics_process(delta: float) -> void:
	if _contact_cooldown_timer > 0.0:
		_contact_cooldown_timer -= delta
	_apply_gravity(delta)
	_update_behavior(delta)
	move_and_slide()
	_post_move(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func _update_behavior(_delta: float) -> void:
	pass  # override — set velocity.x etc every frame

func _post_move(_delta: float) -> void:
	pass  # override for anything after collision resolution (e.g. hover bob)

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage") and _contact_cooldown_timer <= 0.0:
		body.take_damage(contact_damage)
		_contact_cooldown_timer = contact_damage_cooldown

func take_damage(amount: int) -> void:
	health -= amount
	_hit_flash()
	if health <= 0:
		die()

func _hit_flash() -> void:
	if not has_node("Sprite2D"):
		return
	var sprite: CanvasItem = $Sprite2D
	var original: Color = sprite.modulate
	sprite.modulate = Color(3, 3, 3)
	var t := create_tween()
	t.tween_property(sprite, "modulate", original, 0.12)

func die() -> void:
	for i in drop_count:
		var b = bubble_scene.instantiate()
		b.position = position + Vector2(randf_range(-30, 30), -20)
		get_parent().call_deferred("add_child", b)
	queue_free()
