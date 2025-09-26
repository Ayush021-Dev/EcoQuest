extends Node2D

@onready var gripper = $Gripper
@onready var water_tilemap = $Water
@onready var garbage_container = $GarbageContainer
@onready var dustbin_area = $DustbinArea

# Preload the garbage scene - Update this path to match your file location
@export var garbage_scene: PackedScene = preload("res://scenes/Garbage.tscn")
var garbage_types = ["cokezero", "sprite", "can", "bottle"]
var total_garbage_count = 10  # Adjust as needed
var current_garbage_count = 0
var score = 0

# UI elements (optional - add Label node for score display)
@onready var score_label = get_node_or_null("ScoreLabel")

func _ready():
	# Load garbage scene if not assigned
	if not garbage_scene:
		garbage_scene = load("res://scenes/Garbage.tscn")
		if not garbage_scene:
			print("Failed to load Garbage.tscn - check file path!")
			return
	
	# Connect input events
	set_process_input(true)
	
	# Spawn initial garbage
	spawn_garbage()
	
	# Connect gripper signals
	if gripper.has_signal("garbage_collected"):
		gripper.connect("garbage_collected", _on_garbage_collected)
	
	# Update score display
	update_score_display()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		gripper.on_mouse_click()

func spawn_garbage():
	# Check if garbage_scene is properly loaded
	if not garbage_scene:
		print("Error: Garbage scene not loaded!")
		return
	
	# Get water tilemap bounds
	var used_rect = water_tilemap.get_used_rect()
	var tile_size = water_tilemap.tile_set.tile_size
	
	var min_x = used_rect.position.x * tile_size.x
	var max_x = (used_rect.position.x + used_rect.size.x) * tile_size.x - 160  # Reduced by 160
	var min_y = used_rect.position.y * tile_size.y
	var max_y = (used_rect.position.y + used_rect.size.y) * tile_size.y - 25   # Reduced by 25
	
	print("Garbage spawning range:")
	print("X: ", min_x, " to ", max_x)
	print("Y: ", min_y, " to ", max_y)
	
	for i in range(total_garbage_count):
		var garbage_instance = garbage_scene.instantiate()
		
		# Use the adjusted ranges
		var random_x = randf_range(min_x, max_x)
		var random_y = randf_range(min_y, max_y)
		
		garbage_instance.position = Vector2(random_x, random_y)
		
		# Set random garbage type
		var random_type = garbage_types[randi() % garbage_types.size()]
		garbage_instance.set_garbage_type(random_type)
		
		add_child(garbage_instance)

func _on_garbage_collected():
	score += 10  # Add points for successful collection
	print("Score: ", score)
	update_score_display()
	
	# Count remaining garbage
	var remaining_garbage = get_tree().get_nodes_in_group("garbage").size()
	current_garbage_count = remaining_garbage
	
	if current_garbage_count <= 0:
		print("Level Complete! Final Score: ", score)
		# Add level completion logic here

# Add this new function to handle missed garbage from gripper
func respawn_missed_garbage(garbage_type: String):
	print("Respawning missed garbage of type: ", garbage_type)
	var new_garbage = garbage_scene.instantiate()
	
	# Get random position in water area
	var used_rect = water_tilemap.get_used_rect()
	var tile_size = water_tilemap.tile_set.tile_size
	
	var random_x = randf_range(used_rect.position.x * tile_size.x, 
							  (used_rect.position.x + used_rect.size.x) * tile_size.x)
	var random_y = randf_range(used_rect.position.y * tile_size.y, 
							  (used_rect.position.y + used_rect.size.y) * tile_size.y)
	
	new_garbage.position = Vector2(random_x, random_y)
	new_garbage.set_garbage_type(garbage_type)
	add_child(new_garbage)
	print("New garbage spawned at: ", new_garbage.position)

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(score)
	
	# Count remaining garbage
	var remaining_garbage = get_tree().get_nodes_in_group("garbage").size()
	current_garbage_count = remaining_garbage
