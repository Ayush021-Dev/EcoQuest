extends Node2D

@onready var audio_player = $LevelClick
@onready var levels_container = $Levels
@onready var hover_audio_player = $LevelHover 
@onready var close_button = $CloseButton
var loading_bar_scene = preload("res://scenes/UI_Scene/progress_bar.tscn")
var loading_bar_instance: Node = null
var progress_bar: ProgressBar = null
var loading_label: Label = null
var level_scenes = [
	"res://scenes/Level1.tscn",
	"res://scenes/Level2.tscn", 
	"res://scenes/Level3.tscn",
	"res://scenes/Mini_games_level_Screens/ReforestationLevel4.tscn"
]

func _ready():
	# Connect all level buttons automatically
	close_button.pressed.connect(_play_click_sound)
	close_button.mouse_entered.connect(_play_hover_sound)
	close_button.pressed.connect(_on_close_pressed)
	
	for i in range(levels_container.get_child_count()):
		var button = levels_container.get_child(i)
		button.pressed.connect(_play_click_sound)
		button.pressed.connect(_on_level_pressed.bind(i))
		button.mouse_entered.connect(_play_hover_sound)

func _play_click_sound():
	audio_player.play()
	
func _play_hover_sound():
	hover_audio_player.play()
	
func _on_level_pressed(level_index: int):
	if level_index < level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[level_index])
func _on_close_pressed():
	# Instantiate ProgressBar scene
	loading_bar_instance = loading_bar_scene.instantiate()
	add_child(loading_bar_instance)
	progress_bar = loading_bar_instance   # root node is ProgressBar
	loading_label = loading_bar_instance.get_node("Label")
	progress_bar.value = 0
	loading_label.text = "Loading... 0%"
	loading_bar_instance.visible = true
	ResourceLoader.load_threaded_request("res://scenes/Maps/main.tscn")
	_check_loading_progress()


func _check_loading_progress() -> void:
	var progress = []
	var status = ResourceLoader.load_threaded_get_status("res://scenes/Maps/main.tscn", progress)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
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
		if loading_bar_instance:
			loading_bar_instance.queue_free()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		if loading_label:
			loading_label.text = "Loading failed!"
		if loading_bar_instance:
			loading_bar_instance.queue_free()
