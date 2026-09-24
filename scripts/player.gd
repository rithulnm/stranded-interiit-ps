extends CharacterBody2D

signal health_changed(current: int, max: int)
signal died

@export var walk_speed: float = 400.0
@export var sprint_speed: float = 650.0
@export var sprint_ramp_time: float = 1.0
@export var jump_velocity: float = -600.0
@export var gravity: float = 1500.0
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15
@export var acceleration: float = 1500.0
@export var friction: float = 1500.0
@export var bullet_scene: PackedScene
@export var max_health: int = 100

# --- Shadow settings ---
@export var shadow_max_distance: float = 400.0
@export var shadow_min_scale: float = 0.3
@export var shadow_max_alpha: float = 0.5
@export var shadow_min_alpha: float = 0.1

var base_walk: float
var base_sprint: float
var base_max_health: int
var current_health: int = max_health
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 0.0
var jumps_used: int = 0
var max_jumps: int = 2
var is_shooting: bool = false

var hold_time: float = 0.0
var anim_state: String = "idle"   # idle, run_start, run_loop, run_stop
var air_phase: String = ""        # "", squash, extrude, fall, land
var was_on_floor: bool = true

func _ready() -> void:
	add_to_group("player")
	base_walk = walk_speed
	base_sprint = sprint_speed
	base_max_health = max_health
	GameState.upgrade_bought.connect(_on_upgrade_bought)
	apply_upgrades()
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	$Sprite2D.animation_finished.connect(_on_animation_finished)
	$Sprite2D.play("idle")
	$Shadow.top_level = true# safety net in case it wasn't set in the editor
	$GroundRay.collide_with_areas = false
	$GroundRay.collide_with_bodies = true  
	$GroundRay.hit_from_inside = true
	GameState.add_bubbles(50)
	
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
	else:
		if direction != 0:
			hold_time = min(hold_time + delta, sprint_ramp_time)
		else:
			hold_time = 0.0

		var target_speed = lerp(walk_speed, sprint_speed, hold_time / sprint_ramp_time)

		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
			$Sprite2D.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			jumps_used = 0

		# Jump / Double Jump — same animation sequence for both, for now
		if Input.is_action_just_pressed("jump") and jumps_used < max_jumps:
			velocity.y = jump_velocity
			jumps_used += 1
			is_shooting = false
			air_phase = "squash"
			$Sprite2D.play("jump_squash")

		if Input.is_action_just_pressed("dash") and not is_dashing:
			var dash_dir = direction if direction != 0 else (1.0 if not flip_h() else -1.0)
			start_dash(dash_dir)

		if Input.is_action_just_pressed("shoot"):
			shoot()

	move_and_slide()
	update_animation(direction)
	update_shadow()

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

func update_animation(direction: float) -> void:
	if is_shooting:
		return
	is_shooting = false
		
	var speed_ratio = hold_time / sprint_ramp_time
	$Sprite2D.speed_scale = lerp(1.0, 1.6, speed_ratio)

	if is_dashing:
		return

	# --- AIRBORNE ---
	if not is_on_floor():
		was_on_floor = false

		match air_phase:
			"squash":
				# let the anticipation squash play out fully before moving to extrude
				return
			"extrude":
				if velocity.y > 0:
					air_phase = "fall"
					$Sprite2D.play("jump_fall")
			"fall":
				pass  # already falling, keep holding last fall frame
			_:
				# airborne with no phase set (e.g. walked off a ledge) — go straight to fall
				air_phase = "fall"
				$Sprite2D.play("jump_fall")
		return

	# --- GROUNDED ---
	# Safety net: grounded but still flagged mid-air (missed transition) — force landing now
	if air_phase != "" and air_phase != "land":
		was_on_floor = true
		air_phase = "land"
		$Sprite2D.play("jump_land")
		return

	if not was_on_floor:
		was_on_floor = true
		air_phase = "land"
		$Sprite2D.play("jump_land")
		return

	if air_phase == "land":
		return  # wait for jump_land to finish

	if direction != 0:
		if anim_state == "idle" or anim_state == "run_stop":
			anim_state = "run_start"
			$Sprite2D.play("run_start")
	else:
		if anim_state == "run_loop" or anim_state == "run_start":
			anim_state = "run_stop"
			$Sprite2D.speed_scale = 1.0
			$Sprite2D.play("run_stop")

func _on_animation_finished() -> void:
	if $Sprite2D.animation == "shoot":
		is_shooting = false
	
		if is_on_floor():
			# let update_animation pick run_start / idle on the next frame
			air_phase = ""
			was_on_floor = true
			anim_state = "idle"
			$Sprite2D.play("idle")
		else:
			# back to the right air pose
			was_on_floor = false
			if velocity.y < 0:
				air_phase = "extrude"
				$Sprite2D.play("jump_extrude")
			else:
				air_phase = "fall"
				$Sprite2D.play("jump_fall")
		return
		
	# Jump squash finished -> move into extrude (holds its last frame once done, until falling starts)
	if $Sprite2D.animation == "jump_squash":
		air_phase = "extrude"
		$Sprite2D.play("jump_extrude")
		return

	if $Sprite2D.animation == "jump_land":
		air_phase = ""
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0:
			anim_state = "run_start"
			$Sprite2D.play("run_start")
		else:
			anim_state = "idle"
			$Sprite2D.play("idle")
		return

	if anim_state == "run_start":
		anim_state = "run_loop"
		$Sprite2D.play("run_loop")
	elif anim_state == "run_stop":
		anim_state = "idle"
		$Sprite2D.play("idle")

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
	
	is_shooting = true
	$Sprite2D.speed_scale = 1.0
	$Sprite2D.stop()
	$Sprite2D.frame = 0   # restart from the top if you spam shoot
	$Sprite2D.play("shoot")

func take_damage(amount: int) -> void:
	print("player take_damage: ", amount)
	if current_health <= 0:
		return   # already dead, ignore further hits
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	_hit_flash()
	if current_health <= 0:
		died.emit()

func _hit_flash() -> void:
	$Sprite2D.modulate = Color(1, 0.3, 0.3)   # red tint
	var t := create_tween()
	t.tween_property($Sprite2D, "modulate", Color.WHITE, 0.2)

func apply_upgrades() -> void:
	walk_speed = base_walk + GameState.bonus_speed
	sprint_speed = base_sprint + GameState.bonus_speed
	max_health = base_max_health + GameState.bonus_health

func _on_upgrade_bought(item: String) -> void:
	apply_upgrades()
	if item == "health":
		current_health = min(current_health + 25, max_health)
	health_changed.emit(current_health, max_health)
