extends Node2D

@export var previous_scene_path := "res://scenes/Maps/main.tscn"  # Path to previous scene
@export var trigger_x_position := -1492.0  # Example trigger X for going back

var player: Node = null
var has_triggered := false
var is_loading := false

@onready var progress_bar = $ProgressBar
@onready var loading_label = $ProgressBar/Label
@onready var pause_menu = $PauseMenu  # Adjust path if different
@onready var bg_audio = $BG  # Background music AudioStreamPlayer node

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Player node not found in group 'player'")
	
	# Connect pause menu signals
	if pause_menu:
		pause_menu.connect("game_paused", Callable(self, "_on_game_paused"))
		pause_menu.connect("game_resumed", Callable(self, "_on_game_resumed"))
	
	# Start background music playing and looping manually
	if bg_audio:
		bg_audio.play()
		bg_audio.connect("finished", Callable(self, "_on_bg_audio_finished"))

func _process(_delta):
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return
	
	# Disable player movement while loading
	if is_loading and player:
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(false)
		return
	
	if has_triggered:
		return
	
	if player.global_position.x <= trigger_x_position:  # Trigger when player reaches lower x position to go back
		has_triggered = true
		print("Player reached trigger x position, loading previous scene...")
		start_previous_scene_loading()

func start_previous_scene_loading():
	is_loading = true
	progress_bar.visible = true
	loading_label.visible = true
	progress_bar.value = 0
	loading_label.text = "Loading... 0%"
	
	ResourceLoader.load_threaded_request(previous_scene_path)
	check_loading_progress()

func check_loading_progress():
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(previous_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Error: Invalid resource path")
		is_loading = false
		return
	
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var percent = progress[0] * 100
		if progress_bar:
			progress_bar.value = percent
		if loading_label:
			loading_label.text = "Loading... %d%%" % percent
		await get_tree().process_frame
		check_loading_progress()
	
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		if progress_bar:
			progress_bar.value = 100
		if loading_label:
			loading_label.text = "Loading... 100%"
		await get_tree().create_timer(0.5).timeout
		var loaded_scene = ResourceLoader.load_threaded_get(previous_scene_path)
		get_tree().change_scene_to_packed(loaded_scene)
		is_loading = false
	
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error: Failed to load previous scene")
		if loading_label:
			loading_label.text = "Loading failed!"
		is_loading = false

func _on_bg_audio_finished():
	if bg_audio and not get_tree().paused:
		bg_audio.play()

func _on_game_paused():
	if bg_audio:
		bg_audio.stream_paused = true

func _on_game_resumed():
	if bg_audio:
		bg_audio.stream_paused = false
