extends Area2D

@export var level_name: String = "level_1"
@export var scan_range: float = 60.0
@export var scan_speed: float = 1.2

@onready var scan_bar: Node2D = $ScanBar if has_node("ScanBar") else null
@onready var pad: AnimatedSprite2D = $Pad if has_node("Pad") else null
@onready var ambient_particles: GPUParticles2D = $AmbientParticles if has_node("AmbientParticles") else null
@onready var activate_particles: GPUParticles2D = $ActivateParticles if has_node("ActivateParticles") else null
@onready var bank_particles: GPUParticles2D = $BankParticles if has_node("BankParticles") else null

var _scan_tween: Tween = null
var player_in_zone: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if pad:
		pad.play("idle")
	if ambient_particles:
		ambient_particles.emitting = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.in_bottling_point = true
		GameState.current_bottling_level = level_name
		GameState.current_bottling_point = self
		GameState.respawn_point = global_position
		GameState.has_respawn_point = true
		GameState.bottling_state_changed.emit(true)

		player_in_zone = body
		if body.has_method("set_invulnerable"):
			body.set_invulnerable(true)
		if body.has_method("set_can_shoot"):
			body.set_can_shoot(false)
		_start_scan()

		if pad:
			pad.play("activate")
			if not pad.animation_finished.is_connected(_on_activate_finished):
				pad.animation_finished.connect(_on_activate_finished, CONNECT_ONE_SHOT)
		if activate_particles:
			activate_particles.restart()
			activate_particles.emitting = true


func _on_activate_finished() -> void:
	if pad and player_in_zone:
		pad.play("active_loop")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.in_bottling_point = false
		GameState.current_bottling_level = ""
		GameState.current_bottling_point = null
		GameState.bottling_state_changed.emit(false)

		if body.has_method("set_invulnerable"):
			body.set_invulnerable(false)
		if body.has_method("set_can_shoot"):
			body.set_can_shoot(true)
		player_in_zone = null
		_stop_scan()

		if pad:
			pad.play("deactivate")


func _start_scan() -> void:
	if not scan_bar:
		return
	scan_bar.visible = true
	var base_y: float = scan_bar.position.y
	_scan_tween = create_tween().set_loops()
	_scan_tween.tween_property(scan_bar, "position:y", base_y - scan_range, scan_speed).set_trans(Tween.TRANS_SINE)
	_scan_tween.tween_property(scan_bar, "position:y", base_y + scan_range, scan_speed).set_trans(Tween.TRANS_SINE)


func _stop_scan() -> void:
	if _scan_tween:
		_scan_tween.kill()
	if scan_bar:
		scan_bar.visible = false


func do_bank() -> void:
	GameState.bank(level_name)
	_flash()
	if pad:
		pad.play("bank_confirm")
	if bank_particles:
		bank_particles.restart()
		bank_particles.emitting = true


func _flash() -> void:
	if not has_node("Sprite2D"):
		return
	var sprite: Sprite2D = $Sprite2D
	var original: Color = sprite.modulate
	sprite.modulate = Color(3, 3, 3)
	var t := create_tween()
	t.tween_property(sprite, "modulate", original, 0.3)
