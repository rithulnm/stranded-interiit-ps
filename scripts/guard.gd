extends CharacterBody2D

enum State { PATROL, WINDUP, COOLDOWN }
enum BulletType { STRAIGHT, HEAVY, SPREAD }

#Health Setup HAHAHAHAHAHAHA im batman
@export var max_health: int = 30
var health: int
var bubble_scene: PackedScene = preload("res://scenes/bubble.tscn") 
@export var drop_count: int = 3

@export var guard_color: Color = Color.WHITE
@export var bullet_type: BulletType = BulletType.STRAIGHT
@export var bullet_scene: PackedScene
@export var patrol_speed: float = 80.0
@export var gravity: float = 1500.0
@export var contact_damage: int = 15
@export var windup_time: float = 0.45
@export var cooldown_time: float = 1.3
@export var bullet_speed: float = 400.0
@export var bullet_damage: int = 10
@export var aim_offset: Vector2 = Vector2(0, -40)   # aim at player's body, not feet

var state: State = State.PATROL
var direction: float = 1.0
var timer: float = 0.0
var player_ref: Node2D = null

func _ready() -> void:
	add_to_group("guard")
	$Sprite2D.modulate = guard_color
	health = max_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

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
			if not player_ref:            # player left the zone, cancel
				_cancel_windup()
			else:
				$Sprite2D.flip_h = player_ref.global_position.x < global_position.x
				timer -= delta
				if timer <= 0:
					_fire()
					state = State.COOLDOWN
					timer = cooldown_time

		State.COOLDOWN:
			velocity.x = 0
			timer -= delta
			if timer <= 0:
				state = State.PATROL

	move_and_slide()

func _has_line_of_sight() -> bool:
	$SightRay.target_position = $SightRay.to_local(player_ref.global_position + aim_offset)
	$SightRay.force_raycast_update()
	return not $SightRay.is_colliding()

func _start_windup() -> void:
	state = State.WINDUP
	timer = windup_time
	# telegraph: flash toward white so the player sees the shot coming
	var t := create_tween()
	t.tween_property($Sprite2D, "modulate", Color.WHITE, windup_time)

func _cancel_windup() -> void:
	state = State.PATROL
	$Sprite2D.modulate = guard_color

func _fire() -> void:
	$Sprite2D.modulate = guard_color
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

func _spawn(pos: Vector2, dir: Vector2, spd: float, dmg: int, size: float) -> void:
	var b = bullet_scene.instantiate()
	b.setup(dir, spd, dmg, size, guard_color)
	get_tree().current_scene.add_child(b)
	b.global_position = pos

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int) -> void:
	health -= amount
	# hit flash
	var t := create_tween()
	$Sprite2D.modulate = Color(3, 3, 3)   # bright flash
	t.tween_property($Sprite2D, "modulate", guard_color, 0.12)
	if health <= 0:
		die()

func die() -> void:
	for i in drop_count:
		var b = bubble_scene.instantiate()
		b.position = position + Vector2(randf_range(-30, 30), -20)
		get_parent().call_deferred("add_child", b)
	queue_free()
