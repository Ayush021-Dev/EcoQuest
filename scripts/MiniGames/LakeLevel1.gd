extends Node2D

@export var garbage_scene: PackedScene = preload("res://scenes/Garbage.tscn")
var garbage_types = ["cokezero", "sprite", "can", "bottle"]
var total_garbage_count = 10
var current_garbage_count = 0
var score = 0
var level_id: String = "lake_cleanup"

@onready var gripper = $Gripper
@onready var water_tilemap = $Water
@onready var garbage_container = $GarbageContainer
@onready var dustbin_area = $DustbinArea
@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var panel = $Panel
@onready var bg_music = $BG
@onready var win_label = get_node_or_null("WinLabel")

var is_game_paused = true
var game_completed = false

func _ready():
	# Initially show panel and pause the game
	panel.visible = true
	set_process(false)
	get_tree().paused = true
	is_game_paused = true
	
	# Hide win label initially
	if win_label:
		win_label.visible = false
	
	# IMPORTANT: Set process mode for panel to work when paused
	panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect signals safely with correct callable syntax
	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	if not close_button.is_connected("pressed", Callable(self, "_play_click_sound")):
		close_button.connect("pressed", Callable(self, "_play_click_sound"))
	if not close_button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
		close_button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	# Connect panel gui_input signal
	if not panel.is_connected("gui_input", Callable(self, "_on_panel_gui_input")):
		panel.connect("gui_input", Callable(self, "_on_panel_gui_input"))
		print("Panel gui_input signal connected successfully")

	# Connect gripper signals for both collection and miss events
	if gripper.has_signal("garbage_collected") and not gripper.is_connected("garbage_collected", Callable(self, "_on_garbage_collected")):
		gripper.connect("garbage_collected", Callable(self, "_on_garbage_collected"))
	
	if gripper.has_signal("garbage_missed") and not gripper.is_connected("garbage_missed", Callable(self, "_on_garbage_missed")):
		gripper.connect("garbage_missed", Callable(self, "_on_garbage_missed"))

	if bg_music.playing:
		bg_music.stop()

	# Spawn initial garbage but do not start gameplay logic yet
	spawn_garbage()
	

func _input(event):
	if not game_completed and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		gripper.on_mouse_click()

func _on_panel_gui_input(event: InputEvent) -> void:
	print("Panel received input: ", event)
	print("Event type: ", event.get_class())
	print("Game paused: ", is_game_paused)
	
	if event is InputEventMouseButton:
		print("Mouse button event - pressed: ", event.pressed, " button: ", event.button_index)
		
		if event.pressed and is_game_paused:
			print("Starting game from panel click!")
			panel.visible = false
			get_tree().paused = false
			set_process(true)
			is_game_paused = false
			if not bg_music.playing:
				bg_music.play()
			_play_click_sound()

func spawn_garbage():
	if not garbage_scene:
		print("Error: Garbage scene not loaded!")
		return
	var used_rect = water_tilemap.get_used_rect()
	var tile_size = water_tilemap.tile_set.tile_size
	var min_x = used_rect.position.x * tile_size.x
	var max_x = (used_rect.position.x + used_rect.size.x) * tile_size.x - 160
	var min_y = used_rect.position.y * tile_size.y
	var max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y - 25
	for i in range(total_garbage_count):
		var garbage_instance = garbage_scene.instantiate()
		var random_x = randf_range(min_x, max_x)
		var random_y = randf_range(min_y, max_y)
		garbage_instance.position = Vector2(random_x, random_y)
		var random_type = garbage_types[randi() % garbage_types.size()]
		garbage_instance.set_garbage_type(random_type)
		add_child(garbage_instance)

func _on_garbage_collected():
	score += 10
	CarbonFootprintManager.reduce_footprint(5)  # Reduce carbon footprint for collecting garbage
	print("Score: ", score, " | Carbon footprint reduced by 5")
	
	
	var remaining_garbage = get_tree().get_nodes_in_group("garbage").size()
	current_garbage_count = remaining_garbage
	
	if current_garbage_count <= 0:
		show_game_won()

func _on_garbage_missed():
	CarbonFootprintManager.add_footprint(10)  # Increase carbon footprint for missing garbage
	print("Garbage missed! Carbon footprint increased by 10")

func show_game_won():
	game_completed = true
	print("Level Complete! Final Score: ", score)
	
	# Mark level as completed
	LevelCompletionManager.mark_level_completed(level_id)
	
	# Additional carbon reduction bonus for completing the level
	CarbonFootprintManager.reduce_footprint(20)
	print("Level completion bonus: Carbon footprint reduced by 20")
	
	# Show win label
	if win_label:
		win_label.text = "🎉 GAME WON! 🎉\nLake Successfully Cleaned!\nFinal Score: " + str(score)
		win_label.visible = true
	
	# Stop background music
	if bg_music.playing:
		bg_music.stop()
	
	# Wait for 5 seconds then change scene
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func create_win_display():
	# This function is no longer needed since we use win_label
	pass

func respawn_missed_garbage(garbage_type: String):
	print("Respawning missed garbage of type: ", garbage_type)
	var new_garbage = garbage_scene.instantiate()
	var used_rect = water_tilemap.get_used_rect()
	var tile_size = water_tilemap.tile_set.tile_size
	var random_x = randf_range(used_rect.position.x * tile_size.x, (used_rect.position.x + used_rect.size.x) * tile_size.x)
	var random_y = randf_range(used_rect.position.y * tile_size.y, (used_rect.position.y + used_rect.size.y) * tile_size.y)
	new_garbage.position = Vector2(random_x, random_y)
	new_garbage.set_garbage_type(garbage_type)
	add_child(new_garbage)
	print("New garbage spawned at: ", new_garbage.position)


func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func _play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func _play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()
