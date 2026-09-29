extends Area2D

@export var hits_to_explode := 3
@export var blast_radius := 150.0
@export var bubble_scene: PackedScene
@export var gas_zone_scene: PackedScene
@export var spill_bubble_count := 6
@export var gas_duration := 3.0

@export var shadow_max_distance: float = 400.0
@export var shadow_min_scale: float = 0.3
@export var shadow_max_alpha: float = 0.5
@export var shadow_min_alpha: float = 0.1

var hits := 0
var exploded := false

@onready var blast_indicator: Node2D = $BlastVisual if has_node("BlastVisual") else null
@onready var sprite: AnimatedSprite2D = $Sprite2D


func _ready() -> void:
	if blast_indicator:
		blast_indicator.visible = false
		blast_indicator.modulate.a = 0.0
	sprite.play("idle")
	if has_node("Shadow"):
		$Shadow.top_level = true
		update_shadow()

func update_shadow() -> void:
	if not has_node("GroundRay"):
		return
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


func on_hit() -> void:
	if exploded:
		return
	hits += 1
	_squash_flash()
	sprite.play("hit%d" % hits)
	if hits == 1 and blast_indicator:
		_reveal_blast_indicator()
	if blast_indicator and hits > 0:
		_pulse_blast_indicator()
	if hits >= hits_to_explode:
		_explode()

var _pulse_tween: Tween = null

func _reveal_blast_indicator() -> void:
	blast_indicator.visible = true
	blast_indicator.modulate.a = 0.0

func _pulse_blast_indicator() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	var pulse_speed: float = lerp(1.2, 0.4, float(hits) / hits_to_explode)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(blast_indicator, "modulate:a", 0.6, pulse_speed)
	_pulse_tween.tween_property(blast_indicator, "modulate:a", 0.25, pulse_speed)
	
func _squash_flash() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.2, 0.8), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.08)
	sprite.modulate = Color(3, 3, 3)
	var t2 := create_tween()
	t2.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _explode() -> void:
	exploded = true
	if _pulse_tween:
		_pulse_tween.kill()
	if has_node("Shadow"):
		$Shadow.visible = false
	if has_node("ExplosionParticles"):
		$ExplosionParticles.reparent(get_tree().current_scene)
		$ExplosionParticles.emitting = true
	_screen_flash()
	_camera_shake()

	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= blast_radius:
		if player.has_method("take_damage"):
			player.take_damage(9999)
	else:
		call_deferred("_scatter_bubbles")
		call_deferred("_spawn_gas_zone")
	call_deferred("queue_free")


func _screen_flash() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.7, 0.95, 0.5)   # soft magenta flash, matches your danger palette
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(flash)
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.25)
	t.tween_callback(flash.queue_free)


func _camera_shake() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var original_offset: Vector2 = cam.offset
	var t := create_tween()
	for i in 6:
		var shake_amt := 12.0 * (1.0 - float(i) / 6.0)
		t.tween_property(cam, "offset", original_offset + Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt)), 0.03)
	t.tween_property(cam, "offset", original_offset, 0.03)


func _scatter_bubbles() -> void:
	if not bubble_scene:
		return
	for i in spill_bubble_count:
		var b = bubble_scene.instantiate()
		b.expires = true
		get_tree().current_scene.add_child(b)
		var offset := Vector2(randf_range(-blast_radius, blast_radius), randf_range(-blast_radius, blast_radius))
		b.global_position = global_position + offset
		var dir := offset.normalized() if offset.length() > 0 else Vector2.UP
		b.velocity = dir * randf_range(100.0, 200.0)


func _spawn_gas_zone() -> void:
	if not gas_zone_scene:
		return
	var gas = gas_zone_scene.instantiate()
	get_tree().current_scene.add_child(gas)
	gas.scale = Vector2.ONE * (blast_radius / 80.0)
	gas.global_position = global_position
	get_tree().create_timer(gas_duration).timeout.connect(func():
		if is_instance_valid(gas):
			gas.queue_free()
	)
	
