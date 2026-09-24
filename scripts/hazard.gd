extends Area2D

@export var damage: int = 10            # damage per tick
@export var tick_time: float = 0.5      # seconds between ticks

var bodies_inside: Array[Node2D] = []
var timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		bodies_inside.append(body)
		_hurt(body)          # instant hit on contact
		timer = tick_time    # then wait one full tick

func _on_body_exited(body: Node2D) -> void:
	bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
	if bodies_inside.is_empty():
		return
	timer -= delta
	if timer <= 0.0:
		timer = tick_time
		for b in bodies_inside:
			_hurt(b)

func _hurt(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
