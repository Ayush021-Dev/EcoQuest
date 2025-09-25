extends TextureButton

@onready var progress_bar = get_tree().current_scene.find_child("ProgressBar", true, false)
@onready var loading_label = get_tree().current_scene.find_child("Label", true, false)
@onready var hover_sound = get_tree().current_scene.find_child("HoverSound", true, false)
@onready var click_sound = get_tree().current_scene.find_child("ClickSound", true, false)

func _on_mouse_entered() -> void:
	modulate = Color(0.6, 0.6, 0.6) # Darken button
	if hover_sound:
		hover_sound.play()

func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1) # Reset button color

func _on_pressed() -> void:
	if click_sound:
		click_sound.play()
	start_loading()

func start_loading():
	# Hide all buttons in the current scene
	hide_all_buttons()
	# Show loading UI
	progress_bar.visible = true
	loading_label.visible = true
	progress_bar.value = 0
	loading_label.text = "Loading... 0%"
	# Start threaded loading of scene
	ResourceLoader.load_threaded_request("res://scenes/Maps/main.tscn")
	# Begin tracking loading progress
	check_loading_progress()

func hide_all_buttons():
	# Find and hide all buttons
	var nodes = get_tree().current_scene.get_children()
	for node in nodes:
		if node is TextureButton or node is Button:
			node.visible = false

func check_loading_progress():
	var progress = []
	var status = ResourceLoader.load_threaded_get_status("res://scenes/Maps/main.tscn", progress)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Error: Invalid resource path")
		return
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var percent = progress[0] * 100
		progress_bar.value = percent
		loading_label.text = "Loading... %d%%" % percent
		await get_tree().process_frame
		check_loading_progress()
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		progress_bar.value = 100
		loading_label.text = "Loading... 100%"
		await get_tree().create_timer(0.5).timeout
		var loaded_scene = ResourceLoader.load_threaded_get("res://scenes/Maps/main.tscn")
		get_tree().change_scene_to_packed(loaded_scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error: Failed to load scene")
		loading_label.text = "Loading failed!"
