extends "res://scripts/guard_bots/guard_base.gd"

enum State { PATROL, DEPLETE, REFILL }

@export var bullet_scene: PackedScene
@export var patrol_speed: float = 50.0
@export var bullet_speed: float = 350.0
@export var bullet_damage: int = 10
@export var aim_offset: Vector2 = Vector2(0, -20)
@export var min_shot_gap: float = 0.25

@export var ideal_distance: float = 250.0
@export var distance_deadzone: float = 40.0   # no movement within ±this of ideal_distance
@export var approach_speed: float = 40.0      # separate from patrol_speed, usually slower/more deliberate

@export var shadow_max_distance: float = 400.0
@export var shadow_min_scale: float = 0.3
@export var shadow_max_alpha: float = 0.5
@export var shadow_min_alpha: float = 0.1
@export var direction_flip_cooldown: float = 0.3
var _direction_flip_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite2D

const FIRE_FRAMES := [1, 2, 3]

var state: State = State.PATROL
var direction: float = 1.0
var _last_shot_time: float = -999.0


func _on_setup() -> void:
	$Shadow.top_level = true
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)



func _update_behavior(delta: float) -> void:
	update_shadow()
	if _direction_flip_timer > 0.0:
		_direction_flip_timer -= delta

	match state:
		State.PATROL:
			velocity.x = direction * patrol_speed
			$WallCheck.target_position = Vector2(35 * direction, 0)
			$WallCheck.force_raycast_update()
			$LedgeCheck.target_position = Vector2(20 * direction, 37)
			$LedgeCheck.force_raycast_update()
			if _direction_flip_timer <= 0.0 and ($WallCheck.is_colliding() or not $LedgeCheck.is_colliding()):
				direction *= -1
				_direction_flip_timer = direction_flip_cooldown
			sprite.flip_h = direction > 0
			if player_ref and _has_line_of_sight():
				_start_deplete()

		State.DEPLETE:
			_approach_player()

		State.REFILL:
			velocity.x = 0


func _approach_player() -> void:
	if not player_ref:
		velocity.x = 0
		return

	var dx: float = player_ref.global_position.x - global_position.x
	$WallCheck.target_position = Vector2(35 * signf(dx), 0)
	$WallCheck.force_raycast_update()
	if $WallCheck.is_colliding():
		velocity.x = 0
		return
	var dist: float = absf(dx)
	sprite.flip_h = dx > 0   # <-- was dx < 0, the opposite of the rule above

	if dist > ideal_distance + distance_deadzone:
		velocity.x = signf(dx) * approach_speed
	elif dist < ideal_distance - distance_deadzone:
		velocity.x = -signf(dx) * approach_speed
	else:
		velocity.x = 0


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


func _has_line_of_sight() -> bool:
	$SightRay.target_position = $SightRay.to_local(player_ref.global_position + aim_offset)
	$SightRay.force_raycast_update()
	return not $SightRay.is_colliding()


func _start_deplete() -> void:
	state = State.DEPLETE
	sprite.flip_h = player_ref.global_position.x > global_position.x
	sprite.frame = 0
	sprite.play("deplete")


func _on_frame_changed() -> void:
	if sprite.animation == "deplete" and sprite.frame in FIRE_FRAMES:
		_fire()


func _on_animation_finished() -> void:
	if sprite.animation == "deplete":
		_start_refill()
	elif sprite.animation == "refill":
		state = State.PATROL
		sprite.play("idle")


func _start_refill() -> void:
	state = State.REFILL
	sprite.frame = 0
	sprite.play("refill")


func _fire() -> void:
	if not player_ref:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_shot_time < min_shot_gap:
		return
	_last_shot_time = now
	var facing := -1.0 if sprite.flip_h else 1.0
	var local_offset: Vector2 = $MuzzlePoint.position
	var origin := global_position + Vector2(local_offset.x * facing, local_offset.y)
	var dir := (player_ref.global_position + aim_offset - origin).normalized()
	var b = bullet_scene.instantiate()
	b.setup(dir, bullet_speed, bullet_damage, 1.0, Color.WHITE)
	get_tree().current_scene.add_child(b)
	b.global_position = origin


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null
		if state != State.PATROL:
			state = State.PATROL
			sprite.play("idle")
