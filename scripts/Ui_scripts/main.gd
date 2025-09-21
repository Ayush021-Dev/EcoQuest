extends Node2D

@export var city_map_path := "res://scenes/Maps/city_map.tscn"
@export var trigger_x_position := 3764.0

var player : Node = null
var has_triggered := false
var is_loading := false

@onready var progress_bar = $ProgressBar
@onready var loading_label = $ProgressBar/Label
@onready var pause_menu = $PauseMenu  # Adjust node path if different
@onready var bg_audio = $BG         

func _ready():
	await get_tree().process_frame
	
	# UPDATED: Use the new position restoration system
	AvatarManager.returned_to_main()
	
	var players = get_tree().get_nodes_in_group("Player")  
	
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Player node not found in group 'Player'")

	# Connect PauseMenu signals for pause/resume
	if pause_menu:
		pause_menu.connect("game_paused", Callable(self, "_on_game_paused"))
		pause_menu.connect("game_resumed", Callable(self, "_on_game_resumed"))

	# Start playing bg_audio and connect to finished signal for manual looping
	if bg_audio:
		bg_audio.play()
		bg_audio.connect("finished", Callable(self, "_on_bg_audio_finished"))
		
func change_scene_with_save(target_scene_path: String) -> void:
	AvatarManager.auto_save_main_player_position()
	get_tree().change_scene_to_file(target_scene_path)

func _on_bg_audio_finished():
	# When BG music finishes playing, replay it to create a loop
	if bg_audio and not get_tree().paused:
		bg_audio.play()

func _process(_delta):
	if player == null:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player = players[0]
		else:
			return

	if is_loading and player:
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(false)
		return

	if has_triggered:
		return

	if player.global_position.x >= trigger_x_position:
		has_triggered = true
		print("Player reached trigger x position, starting loading...")
		start_city_map_loading()

# UPDATED: When entering reforestation zone
func enter_reforestation_zone():
	AvatarManager.entering_level()  # Use the new function
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

# UPDATED: When entering lake zone  
func enter_lake_zone():
	AvatarManager.entering_level()  # Use the new function
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func start_city_map_loading():
	is_loading = true
	progress_bar = get_tree().current_scene.get_node_or_null("ProgressBar")
	loading_label = get_tree().current_scene.get_node_or_null("ProgressBar/Label")

	if progress_bar:
		print("ProgressBar node found!")
		progress_bar.visible = true
		progress_bar.value = 0
	else:
		print("ProgressBar node NOT found!")

	if loading_label:
		print("LoadingLabel node found!")
		loading_label.visible = true
		loading_label.text = "Loading... 0%"
	else:
		print("LoadingLabel node NOT found!")

	ResourceLoader.load_threaded_request(city_map_path)
	check_city_map_loading_progress()

func check_city_map_loading_progress() -> void:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(city_map_path, progress)
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
		check_city_map_loading_progress()
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		if progress_bar:
			progress_bar.value = 100
		if loading_label:
			loading_label.text = "Loading... 100%"
		await get_tree().create_timer(0.5).timeout
		var loaded_scene = ResourceLoader.load_threaded_get(city_map_path)
		AvatarManager.auto_save_main_player_position()  # Save current player position first
		get_tree().change_scene_to_packed(loaded_scene)
		is_loading = false
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error: Failed to load scene")
		if loading_label:
			loading_label.text = "Loading failed!"
		is_loading = false

# Pause BG music on game pause
func _on_game_paused():
	if bg_audio:
		bg_audio.stream_paused = true  # Pause playback preserving position

func _on_game_resumed():
	if bg_audio:
		bg_audio.stream_paused = false  # Resume playback from paused position
