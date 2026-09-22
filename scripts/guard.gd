extends CharacterBody2D

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 150.0
@export var gravity: float = 1500.0
@export var contact_damage: int = 15
@export var patrol_distance: float = 100.0

enum State { PATROL, CHASE, RETURN }
var state: State = State.PATROL
var direction: float = 1.0
var start_position: Vector2
var player_ref: Node2D = null

func _ready() -> void:
	start_position = global_position

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
			$WallCheck.target_position = Vector2(35  * direction, 0)
			$WallCheck.force_raycast_update()
			if not $LedgeCheck.is_colliding() or $WallCheck.is_colliding():
				direction *= -1
			$Sprite2D.flip_h = direction < 0

		State.CHASE:
			if player_ref:
				var dir_to_player = sign(player_ref.global_position.x - global_position.x)
				velocity.x = dir_to_player * chase_speed
				$Sprite2D.flip_h = dir_to_player < 0

		State.RETURN:
			var dir_to_start = sign(start_position.x - global_position.x)
			velocity.x = dir_to_start * patrol_speed
			$Sprite2D.flip_h = dir_to_start < 0
			if abs(global_position.x - start_position.x) < 5:
				state = State.PATROL
				direction = 1.0

	move_and_slide()

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		state = State.CHASE

func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null
		state = State.RETURN

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
