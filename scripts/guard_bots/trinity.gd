extends "res://scripts/guard_bots/guard_base.gd"

enum State { PATROL, WINDUP, COOLDOWN }

@export var bullet_scene: PackedScene
@export var patrol_speed: float = 60.0
@export var hover_amplitude: float = 8.0
@export var hover_frequency: float = 1.4
@export var cooldown_time: float = 1.2
@export var bullet_speed: float = 350.0
@export var bullet_damage: int = 10
@export var aim_offset: Vector2 = Vector2(0, -20)
@export var shadow_max_distance: float = 400.0
@export var shadow_min_scale: float = 0.3
@export var shadow_max_alpha: float = 0.5
@export var shadow_min_alpha: float = 0.1
@export var direction_flip_cooldown: float = 0.3
var _direction_flip_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite2D

var state: State = State.PATROL
var direction: float = 1.0
var timer: float = 0.0
var base_y: float = 0.0
var hover_time: float = 0.0

func _on_setup() -> void:
	$Shadow.top_level = true
	base_y = position.y
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)


func update_shadow() -> void:
	$GroundRay.force_raycast_update()
	if $GroundRay.is_colliding():
		var hit_point: Vector2 = $GroundRay.get_collision_point()
		var distance: float = hit_point.y - global_position.y
		var t: float = clamp(distance / shadow_max_distance, 0.0, 1.0)

		$Shadow.global_position = Vector2(global_position.x, hit_point.y)
		$Shadow.scale = Vector2.ONE * lerp(1.0, shadow_min_scale, t)
		$Shadow.modulate.a = lerp(shadow_max_alpha, shadow_min_alpha, t)
		$Shadow.visible = true
	else:
		$Shadow.visible = false
		
func _apply_gravity(_delta: float) -> void:
	pass  # Henry hovers — no gravity at all

func _update_behavior(delta: float) -> void:
	update_shadow()
	if _direction_flip_timer > 0.0:
		_direction_flip_timer -= delta

	match state:
		State.PATROL:
			velocity.x = direction * patrol_speed
			sprite.flip_h = direction > 0
			if player_ref and _has_line_of_sight():
				_start_windup()

		State.WINDUP:
			velocity.x = 0
			if not player_ref:
				_cancel_windup()

		State.COOLDOWN:
			velocity.x = 0
			timer -= delta
			if timer <= 0:
				state = State.PATROL
				sprite.play("idle")

func _post_move(delta: float) -> void:
	hover_time += delta
	position.y = base_y + sin(hover_time * hover_frequency * TAU) * hover_amplitude

	if state == State.PATROL:
		if is_on_wall() and _direction_flip_timer <= 0.0:
			direction *= -1
			_direction_flip_timer = direction_flip_cooldown
		elif _direction_flip_timer <= 0.0 and not _has_ground_ahead():
			direction *= -1
			_direction_flip_timer = direction_flip_cooldown

func _has_ground_ahead() -> bool:
	$EdgeCheck.position = Vector2(30 * direction, 0)
	$EdgeCheck.target_position = Vector2(0, 200)
	$EdgeCheck.force_raycast_update()
	return $EdgeCheck.is_colliding()
		
func _has_line_of_sight() -> bool:
	$SightRay.target_position = $SightRay.to_local(player_ref.global_position + aim_offset)
	$SightRay.force_raycast_update()
	return not $SightRay.is_colliding()

func _start_windup() -> void:
	state = State.WINDUP
	sprite.flip_h = player_ref.global_position.x > global_position.x
	sprite.play("charge")

func _cancel_windup() -> void:
	state = State.PATROL
	sprite.play("idle")

func _on_animation_finished() -> void:
	if sprite.animation == "charge" and state == State.WINDUP:
		_fire()
		state = State.COOLDOWN
		timer = cooldown_time
		sprite.play("idle")

func _fire() -> void:
	if not player_ref:
		return
	var target_pos: Vector2 = player_ref.global_position + aim_offset

	var muzzles: Array[Marker2D] = [$MuzzlePoint1, $MuzzlePoint2, $MuzzlePoint3]
	for muzzle in muzzles:
		var origin: Vector2 = muzzle.global_position
		var dir := (target_pos - origin).normalized()
		var b = bullet_scene.instantiate()
		b.setup(dir, bullet_speed, bullet_damage, 1.0, Color.WHITE)
		get_tree().current_scene.add_child(b)
		b.global_position = origin
		await get_tree().create_timer(0.05).timeout
