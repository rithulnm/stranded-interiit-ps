extends Node


const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const PAUSE_MENU := "res://scenes/ui/pause_menu.tscn"
const GAME_OVER := "res://scenes/ui/game_over.tscn"
const LEVEL_COMPLETE := "res://scenes/ui/level_complete.tscn"
const LEVEL_1 := "res://scenes/levels/level_1.tscn"

var pause_menu_instance: CanvasLayer = null
var is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # so this node still runs while paused

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	get_tree().paused = true
	var pause_scene = load(PAUSE_MENU) as PackedScene
	pause_menu_instance = pause_scene.instantiate()
	pause_menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(pause_menu_instance)

func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	get_tree().paused = false
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null

# --- Scene transitions ---
func go_to_main_menu() -> void:
	_clear_pause_state()
	get_tree().change_scene_to_file(MAIN_MENU)

func start_game() -> void:
	_clear_pause_state()
	get_tree().change_scene_to_file(LEVEL_1)

func restart_level() -> void:
	_clear_pause_state()
	get_tree().reload_current_scene()

func show_game_over() -> void:
	get_tree().paused = true
	var scene = load(GAME_OVER) as PackedScene
	var instance = scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(instance)

func show_level_complete() -> void:
	get_tree().paused = true
	var scene = load(LEVEL_COMPLETE) as PackedScene
	var instance = scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(instance)

func _clear_pause_state() -> void:
	is_paused = false
	get_tree().paused = false
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
