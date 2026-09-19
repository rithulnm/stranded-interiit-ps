extends CharacterBody2D

@export var speed: float = 400.0
@export var jump_velocity: float = -600.0
@export var gravity: float = 1500.0
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15
@export var acceleration: float = 1500.0
@export var friction: float = 1500.0

@export var bullet_scene: PackedScene

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 0.0
var jumps_used: int = 0
var max_jumps: int = 2

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
	else:
		# Horizontal movement
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
			$Sprite2D.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		# Gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			jumps_used = 0  # reset on landing

		# Jump / Double Jump
		if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
			velocity.y = jump_velocity
			jumps_used += 1

		# Dash
		if Input.is_action_just_pressed("dash") and not is_dashing:
			var dash_dir = direction if direction != 0 else (1.0 if not flip_h() else -1.0)
			start_dash(dash_dir)

		# Shoot
		if Input.is_action_just_pressed("shoot"):
			shoot()

	move_and_slide()

func start_dash(dir: float) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_direction = dir

func flip_h() -> bool:
	return $Sprite2D.flip_h if has_node("Sprite2D") else false

func shoot() -> void:
	var bullet = bullet_scene.instantiate()
	var dir = -1.0 if $Sprite2D.flip_h else 1.0
	bullet.direction = dir
	bullet.inherited_velocity = velocity.x
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $MuzzlePoint.global_position
