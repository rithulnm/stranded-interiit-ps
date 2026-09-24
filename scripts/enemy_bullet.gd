extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var lifetime: float = 4.0

func setup(dir: Vector2, spd: float, dmg: int, size: float, color: Color) -> void:
	velocity = dir * spd
	damage = dmg
	scale = Vector2.ONE * size
	modulate = color

func _ready() -> void:
	rotation = velocity.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("guard"):
		queue_free()
