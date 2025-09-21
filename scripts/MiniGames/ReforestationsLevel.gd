extends Node2D

@onready var audio_player = $LevelClick
@onready var levels_container = $Levels
@onready var hover_audio_player = $LevelHover
@onready var close_button = $CloseButton
@onready var progress_bar = $ProgressBar
@onready var loading_label = $ProgressBar/Label

var level_scenes = [
	"res://scenes/Mini_games_level_Screens/ReforestationLevel1.tscn",
	"res://scenes/Mini_games_level_Screens/ReforestationLevel2.tscn",
	"res://scenes/Mini_games_level_Screens/ReforestationLevel3.tscn",
	"res://scenes/Mini_games_level_Screens/ReforestationLevel4.tscn"
]

# Level completion IDs - match these with your level scripts
var level_completion_ids = [
	"reforestation_level1",
	"reforestation_level2", 
	"reforestation_level3",
	"reforestation_level4"
]

var player = null

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		print("Player node found:", player.name)
	else:
		print("Warning: No player found in Player group")
	
	# Connect all level buttons automatically
	close_button.pressed.connect(_play_click_sound)
	close_button.mouse_entered.connect(_play_hover_sound)
	close_button.pressed.connect(_on_close_pressed)
	
	for i in range(levels_container.get_child_count()):
		var button = levels_container.get_child(i)
		button.mouse_entered.connect(_play_hover_sound)
		
		# Check if level is completed before connecting pressed signal
		if i < level_completion_ids.size() and LevelCompletionManager.is_level_completed(level_completion_ids[i]):
			make_button_completed(button, "Level " + str(i + 1) + " - Completed! ✅")
		else:
			# Normal button setup for uncompleted levels
			button.pressed.connect(_play_click_sound)
			button.pressed.connect(_on_level_pressed.bind(i))

func make_button_completed(button: TextureButton, completed_text: String):
	if button:
		# Make button non-clickable
		button.disabled = true
		
		# Visual feedback - make it look completed
		button.modulate = Color(0.7, 1.0, 0.7)  # Light green tint
		
		button.tooltip_text = completed_text

func _play_click_sound():
	audio_player.play()

func _play_hover_sound():
	hover_audio_player.play()

# UPDATED: Save player position before entering level
func _on_level_pressed(level_index: int):
	# Double-check that level isn't completed (safety check)
	if level_index < level_completion_ids.size():
		if LevelCompletionManager.is_level_completed(level_completion_ids[level_index]):
			print("Level", level_index + 1, "is already completed!")
			return
	
	if level_index < level_scenes.size():
		# ADDED: Save player position before entering level
		AvatarManager.entering_level()
		get_tree().change_scene_to_file(level_scenes[level_index])
		
func _on_close_pressed():
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
	
	ResourceLoader.load_threaded_request("res://scenes/Maps/main.tscn")
	_check_loading_progress()

func _check_loading_progress() -> void:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status("res://scenes/Maps/main.tscn", progress)
	
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Error: Invalid resource path")
		return
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var percent = progress[0] * 100
		if progress_bar:
			progress_bar.value = percent
		if loading_label:
			loading_label.text = "Loading... %d%%" % percent
		await get_tree().process_frame
		_check_loading_progress()
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		if progress_bar:
			progress_bar.value = 100
		if loading_label:
			loading_label.text = "Loading... 100%"
		await get_tree().create_timer(0.5).timeout
		var loaded_scene = ResourceLoader.load_threaded_get("res://scenes/Maps/main.tscn")
		get_tree().change_scene_to_packed(loaded_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		if loading_label:
			loading_label.text = "Loading failed!"
