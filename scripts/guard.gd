extends "res://scripts/guard_bots/guard_base.gd"

enum State { PATROL, WINDUP, COOLDOWN }
enum BulletType { STRAIGHT, HEAVY, SPREAD, LASER }

@export var laser_telegraph_color: Color = Color(1, 0.3, 0.3, 0.35)
@export var laser_fire_color: Color = Color(1, 0.2, 0.2, 1.0)
@export var laser_width: float = 3.0
@export var laser_range: float = 2000.0

@export var bullet_type: BulletType = BulletType.STRAIGHT
@export var bullet_scene: PackedScene
@export var patrol_speed: float = 80.0
@export var windup_time: float = 0.45
@export var cooldown_time: float = 1.3
@export var bullet_speed: float = 400.0
@export var bullet_damage: int = 10
@export var aim_offset: Vector2 = Vector2(0, -40)

var state: State = State.PATROL
var direction: float = 1.0
var timer: float = 0.0
var laser_line: Line2D

func _on_setup() -> void:
	if bullet_type == BulletType.LASER:
		laser_line = Line2D.new()
		laser_line.width = laser_width
		laser_line.default_color = laser_telegraph_color
		laser_line.visible = false
		add_child(laser_line)

func _update_behavior(delta: float) -> void:
	match state:
		State.PATROL:
			velocity.x = direction * patrol_speed
			$LedgeCheck.target_position = Vector2(20 * direction, 37)
			$LedgeCheck.force_raycast_update()
			$WallCheck.target_position = Vector2(35 * direction, 0)
			$WallCheck.force_raycast_update()
			if not $LedgeCheck.is_colliding() or $WallCheck.is_colliding():
				direction *= -1
			$Sprite2D.flip_h = direction < 0
			if player_ref and _has_line_of_sight():
				_start_windup()

		State.WINDUP:
			velocity.x = 0
			if not player_ref:
				_cancel_windup()
			else:
				$Sprite2D.flip_h = player_ref.global_position.x > global_position.x
				timer -= delta
				if timer <= 0:
					_fire()
					state = State.COOLDOWN
					timer = cooldown_time
				elif bullet_type == BulletType.LASER:
					_update_laser_telegraph()

		State.COOLDOWN:
			velocity.x = 0
			timer -= delta
			if timer <= 0:
				state = State.PATROL

func _update_laser_telegraph() -> void:
	var facing := -1.0 if $Sprite2D.flip_h else 1.0
	var origin := global_position + Vector2(30 * facing, -10)
	var dir := (player_ref.global_position + aim_offset - origin).normalized()
	laser_line.points = PackedVector2Array([to_local(origin), to_local(origin + dir * laser_range)])
	laser_line.visible = true

func _has_line_of_sight() -> bool:
	$SightRay.target_position = $SightRay.to_local(player_ref.global_position + aim_offset)
	$SightRay.force_raycast_update()
	return not $SightRay.is_colliding()

func _start_windup() -> void:
	state = State.WINDUP
	timer = windup_time
	var t := create_tween()
	t.tween_property($Sprite2D, "modulate", Color.WHITE, windup_time)

func _cancel_windup() -> void:
	state = State.PATROL
	$Sprite2D.modulate = guard_color
	if laser_line:
		laser_line.visible = false

func _fire() -> void:
	$Sprite2D.modulate = guard_color
	if bullet_type == BulletType.LASER:
		_fire_laser()
		return
	var facing := -1.0 if $Sprite2D.flip_h else 1.0
	var origin := global_position + Vector2(30 * facing, -10)
	var dir := (player_ref.global_position + aim_offset - origin).normalized()
	match bullet_type:
		BulletType.STRAIGHT:
			_spawn(origin, dir, bullet_speed, bullet_damage, 1.0)
		BulletType.HEAVY:
			_spawn(origin, dir, bullet_speed * 0.55, bullet_damage * 2, 2.0)
		BulletType.SPREAD:
			for a in [-0.3, 0.0, 0.3]:
				_spawn(origin, dir.rotated(a), bullet_speed * 0.9, bullet_damage, 0.8)

func _fire_laser() -> void:
	var facing := -1.0 if $Sprite2D.flip_h else 1.0
	var origin := global_position + Vector2(30 * facing, -10)
	var dir := (player_ref.global_position + aim_offset - origin).normalized()

	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, origin + dir * laser_range)
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)

	var end_point := origin + dir * laser_range
	if result:
		end_point = result.position
		var body = result.collider
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(bullet_damage)

	laser_line.points = PackedVector2Array([to_local(origin), to_local(end_point)])
	laser_line.default_color = laser_fire_color
	laser_line.visible = true
	await get_tree().create_timer(0.08).timeout
	laser_line.visible = false
	laser_line.default_color = laser_telegraph_color

func _spawn(pos: Vector2, dir: Vector2, spd: float, dmg: int, size: float) -> void:
	var b = bullet_scene.instantiate()
	b.setup(dir, spd, dmg, size, guard_color)
	get_tree().current_scene.add_child(b)
	b.global_position = pos
