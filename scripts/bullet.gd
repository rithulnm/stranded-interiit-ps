extends Area2D

@export var speed: float = 700.0
@export var fall_gravity: float = 100.0
var direction: float = 1.0
var inherited_velocity: float = 0.0
var velocity: Vector2

func _ready() -> void:
	velocity = Vector2(direction * speed + inherited_velocity, 0)

func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
