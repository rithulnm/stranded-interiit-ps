extends Area2D

@export var speed: float = 700.0

var direction: float = 1.0
var inherited_velocity: float = 0.0
var velocity: Vector2

func _ready() -> void:
	velocity = Vector2(direction * speed + inherited_velocity, 0)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation = velocity.angle()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("guard") and body.has_method("take_damage"):
		body.take_damage(10 + GameState.bonus_damage)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
