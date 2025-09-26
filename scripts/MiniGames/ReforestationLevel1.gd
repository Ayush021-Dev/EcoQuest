extends Node2D

@export var garbage_scene: PackedScene = preload("res://scenes/Garbage.tscn")
var garbage_types = ["cokezero", "sprite", "can", "bottle"]
var total_garbage_count = 10
var current_garbage_count = 0
var score = 0

@onready var gripper = $Gripper
@onready var water_tilemap = $Water
@onready var garbage_container = $GarbageContainer
@onready var dustbin_area = $DustbinArea
@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var score_label = get_node_or_null("ScoreLabel")
@onready var bg_music = $BG
@onready var game_timer = $Timer

func _ready():
	# Connect signals safely
	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	if not close_button.is_connected("pressed", Callable(self, "_play_click_sound")):
		close_button.connect("pressed", Callable(self, "_play_click_sound"))
	if not close_button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
		close_button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	if gripper.has_signal("garbage_collected") and not gripper.is_connected("garbage_collected", Callable(self, "_on_garbage_collected")):
		gripper.connect("garbage_collected", Callable(self, "_on_garbage_collected"))

	if bg_music.playing:
		bg_music.stop()

	spawn_garbage()
	update_score_display()

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
	print("Score: ", score)
	update_score_display()
	var remaining_garbage = get_tree().get_nodes_in_group("garbage").size()
	current_garbage_count = remaining_garbage
	if current_garbage_count <= 0:
		print("Level Complete! Final Score: ", score)
		game_timer.stop()

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

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(score)
	var remaining_garbage = get_tree().get_nodes_in_group("garbage").size()
	current_garbage_count = remaining_garbage

func _on_game_timer_timeout():
	print("Game timer ended.")

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
