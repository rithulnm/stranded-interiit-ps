extends "res://scripts/guard_bots/guard_base.gd"

enum State { PATROL, ALERT, FIRE_COOLDOWN, CHARGE_WINDUP, CHARGING, RECOVER }

@export var bullet_scene: PackedScene
@export var patrol_speed: float = 45.0
@export var bullet_speed: float = 380.0
@export var bullet_damage: int = 12
@export var aim_offset: Vector2 = Vector2(0, -20)
@export var fire_cooldown_time: float = 1.4

@export var ideal_distance: float = 260.0
@export var distance_deadzone: float = 40.0
@export var approach_speed: float = 45.0

# --- charge-dash ---
@export var charge_trigger_distance: float = 130.0   # player gets THIS close -> charge instead of shoot
@export var charge_windup_time: float = 0.5
@export var charge_speed: float = 500.0
@export var charge_duration: float = 0.35
@export var charge_damage: int = 25
@export var recover_time: float = 0.8

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
var charge_dir: float = 1.0


func _on_setup() -> void:
	$Shadow.top_level = true
	sprite.play("idle")
	sprite.animation_finished.connect(_on_animation_finished)


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
				_enter_alert()

		State.ALERT, State.FIRE_COOLDOWN:
			_combat_behavior(delta)

		State.CHARGE_WINDUP:
			velocity.x = 0
			timer -= delta
			if timer <= 0:
				_start_charge()

		State.CHARGING:
			velocity.x = charge_dir * charge_speed
			timer -= delta
			$WallCheck.target_position = Vector2(35 * charge_dir, 0)
			$WallCheck.force_raycast_update()
			if timer <= 0 or $WallCheck.is_colliding():
				_start_recover()

		State.RECOVER:
			velocity.x = 0
			timer -= delta
			if timer <= 0:
				if player_ref:
					_enter_alert()
				else:
					state = State.PATROL
					sprite.play("idle")


func _combat_behavior(delta: float) -> void:
	if not player_ref:
		state = State.PATROL
		sprite.play("idle")
		return

	var dx: float = player_ref.global_position.x - global_position.x
	var dist: float = absf(dx)
	sprite.flip_h = dx > 0

	# too close -> charge instead of shoot
	if dist < charge_trigger_distance:
		_start_charge_windup(signf(dx))
		return

	$WallCheck.target_position = Vector2(35 * signf(dx), 0)
	$WallCheck.force_raycast_update()
	if dist > charge_trigger_distance and not $WallCheck.is_colliding():
		velocity.x = signf(dx) * approach_speed
	else:
		velocity.x = 0

	if state == State.ALERT:
		timer -= delta
		if timer <= 0:
			_fire()
			state = State.FIRE_COOLDOWN
			timer = fire_cooldown_time
	elif state == State.FIRE_COOLDOWN:
		timer -= delta
		if timer <= 0:
			state = State.ALERT
			timer = 0.4   # brief pause before next shot is allowed


func _enter_alert() -> void:
	state = State.ALERT
	timer = 0.4
	sprite.play("alert_transition")


func _on_animation_finished() -> void:
	if sprite.animation == "alert_transition":
		sprite.play("alert")


func _has_line_of_sight() -> bool:
	$SightRay.target_position = $SightRay.to_local(player_ref.global_position + aim_offset)
	$SightRay.force_raycast_update()
	return not $SightRay.is_colliding()


func _fire() -> void:
	if not player_ref:
		return
	$MuzzlePoint.modulate = Color(2, 2, 2)
	create_tween().tween_property($MuzzlePoint, "modulate", Color.WHITE, 0.1)
	var facing := -1.0 if sprite.flip_h else 1.0
	var local_offset: Vector2 = $MuzzlePoint.position
	var origin := global_position + Vector2(local_offset.x * facing, local_offset.y)
	var dir := (player_ref.global_position + aim_offset - origin).normalized()
	var b = bullet_scene.instantiate()
	b.setup(dir, bullet_speed, bullet_damage, 1.0, Color.WHITE)
	get_tree().current_scene.add_child(b)
	b.global_position = origin


func _start_charge_windup(dir: float) -> void:
	state = State.CHARGE_WINDUP
	charge_dir = dir
	timer = charge_windup_time
	sprite.modulate = Color(1.6, 0.6, 0.6)   # red pre-flash, distinct from firing flash
	create_tween().tween_property(sprite, "modulate", Color(2.2, 0.4, 0.4), charge_windup_time)


func _start_charge() -> void:
	state = State.CHARGING
	timer = charge_duration
	if player_ref:
		charge_dir = signf(player_ref.global_position.x - global_position.x)
	sprite.flip_h = charge_dir > 0


func _start_recover() -> void:
	state = State.RECOVER
	timer = recover_time
	sprite.modulate = Color.WHITE


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


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null
