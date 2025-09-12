extends Node2D

@export var city_map_path := "res://scenes/Maps/city_map.tscn"
@export var trigger_x_position := 3764.0
var player : Node = null
var has_triggered := false

@onready var progress_bar = $ProgressBar
@onready var loading_label = $ProgressBar/Label

func _ready():
	var players = get_tree().get_nodes_in_group("Player")  
	if players.size() > 0:
		player = players[0]
		print("Player node found: ", player.name)
	else:
		push_warning("Player node not found in group 'player'")

func _process(_delta):
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("Player node found late: ", player.name)
		else:
			return

	print("Player position: ", player.global_position)

	if has_triggered:
		return

	if player.global_position.x >= trigger_x_position:
		has_triggered = true
		print("Player reached trigger x position, starting loading...")
		start_city_map_loading()

func start_city_map_loading():
	# Attempt to get progress bar and label fresh references
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
		get_tree().change_scene_to_packed(loaded_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error: Failed to load scene")
		if loading_label:
			loading_label.text = "Loading failed!"
