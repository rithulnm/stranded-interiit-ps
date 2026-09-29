extends Area2D

@export var value: int = 1
@export var expires := false
@export var lifetime := 3.0

var velocity: Vector2 = Vector2.ZERO

const SPAWN_COLLISION_DELAY := 0.4
const FADE_TIME := 1.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if expires:
		_setup_spill()
	else:
		_bob_tween()

func _physics_process(delta: float) -> void:
	if expires:
		position += velocity * delta
		velocity = velocity.lerp(Vector2.ZERO, delta * 2.0)

func _setup_spill() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	get_tree().create_timer(SPAWN_COLLISION_DELAY).timeout.connect(func():
		set_deferred("monitoring", true)
		set_deferred("monitorable", true)
	)
	var fade_start: float = max(lifetime - FADE_TIME, 0.0)
	get_tree().create_timer(fade_start).timeout.connect(_start_fade)

func _start_fade() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	t.tween_callback(queue_free)

func _bob_tween() -> void:
	var t := create_tween().set_loops()
	t.tween_property($Sprite2D, "position:y", -6.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)
	t.tween_property($Sprite2D, "position:y", 6.0, 0.6).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.add_bubbles(value)
		queue_free()
