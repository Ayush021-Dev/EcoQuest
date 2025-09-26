extends Sprite2D

signal garbage_collected

enum State {
	MOVING_HORIZONTAL,
	MOVING_DOWN,
	MOVING_UP
}

var current_state = State.MOVING_HORIZONTAL
var move_speed = 500.0
var vertical_speed = 300.0
var direction = 1  # 1 for right, -1 for left

# Movement boundaries (adjust these based on your level)
var left_boundary = 80.0
var right_boundary = 1085.0
var top_position = 33.0  # Y position where gripper moves horizontally
var carrying_garbage = null
var original_garbage_data = {}  # Store original garbage info for respawning

# References to areas
@onready var level = get_parent()
var dustbin_area: Area2D

func _ready():
	# Set initial position
	position.y = top_position
	
	# Find the dustbin area
	dustbin_area = level.get_node("DustbinArea")

func _process(delta):
	match current_state:
		State.MOVING_HORIZONTAL:
			move_horizontal(delta)
		State.MOVING_DOWN:
			move_down(delta)
		State.MOVING_UP:
			move_up(delta)
	
	# If carrying garbage, make it follow the gripper
	if carrying_garbage:
		carrying_garbage.global_position = global_position + Vector2(0, 40)

func move_horizontal(delta):
	position.x += move_speed * direction * delta
	
	# Bounce at boundaries
	if position.x >= right_boundary:
		direction = -1
	elif position.x <= left_boundary:
		direction = 1

func move_down(delta):
	position.y += vertical_speed * delta
	
	# Check for collision with garbage or ground
	check_for_garbage()
	if carrying_garbage != null:
		current_state = State.MOVING_UP
		direction=1
		return
	# Stop at water bottom or if we hit something
	if position.y >= 550: 
		current_state = State.MOVING_UP

func move_up(delta):
	position.y -= vertical_speed * delta
	
	# Return to top position
	if position.y <= top_position:
		position.y = top_position
		current_state = State.MOVING_HORIZONTAL

func on_mouse_click():
	if current_state == State.MOVING_HORIZONTAL:
		if carrying_garbage == null:
			# Go down to pick up garbage
			current_state = State.MOVING_DOWN
		else:
			# Drop the garbage at current position
			drop_garbage_here()

func check_for_garbage():
	# Get all garbage nodes in the scene
	var garbage_nodes = get_tree().get_nodes_in_group("garbage")
	
	for garbage in garbage_nodes:
		if garbage and is_instance_valid(garbage):
			var distance = position.distance_to(garbage.global_position)
			if distance < 25:  # Pickup range
				carry_garbage(garbage)
				break

func carry_garbage(garbage):
	if carrying_garbage == null:
		carrying_garbage = garbage
		# Store original data for potential respawning
		original_garbage_data = {
			"type": garbage.garbage_type,
			"scene": level.garbage_scene
		}
		# Remove garbage from collision detection while being carried
		garbage.set_collision_enabled(false)
		

func drop_garbage_here():
	if carrying_garbage:
		# Start the falling animation
		carrying_garbage.start_falling()
		# Connect to the garbage's signals
		if not carrying_garbage.is_connected("garbage_hit_dustbin", _on_garbage_hit_dustbin):
			carrying_garbage.connect("garbage_hit_dustbin", _on_garbage_hit_dustbin)
		if not carrying_garbage.is_connected("garbage_missed_dustbin", _on_garbage_missed_dustbin):
			carrying_garbage.connect("garbage_missed_dustbin", _on_garbage_missed_dustbin)
		
		# Release the garbage
		carrying_garbage = null
		original_garbage_data.clear()

func _on_garbage_hit_dustbin():
	
	garbage_collected.emit()

func _on_garbage_missed_dustbin(garbage_node):
	
	var garbage_type_to_respawn = original_garbage_data.get("type", "cokezero")
	
	# Remove the missed garbage
	if garbage_node and is_instance_valid(garbage_node):
		garbage_node.queue_free()
	
	# Call the main level's respawn function
	level.respawn_missed_garbage(garbage_type_to_respawn)
	
	# Clear the data
	original_garbage_data.clear()

func respawn_garbage():
	if original_garbage_data.has("scene") and original_garbage_data.has("type"):
		
		var new_garbage = original_garbage_data.scene.instantiate()
		
		# Get random position in water area
		var water_tilemap = level.get_node("Water")
		var used_rect = water_tilemap.get_used_rect()
		var tile_size = water_tilemap.tile_set.tile_size
		
		var random_x = randf_range(used_rect.position.x * tile_size.x, 
								  (used_rect.position.x + used_rect.size.x) * tile_size.x)
		var random_y = randf_range(used_rect.position.y * tile_size.y, 
								  (used_rect.position.y + used_rect.size.y) * tile_size.y)
		
		new_garbage.position = Vector2(random_x, random_y)
		new_garbage.set_garbage_type(original_garbage_data.type)
		
		level.add_child(new_garbage)
		
	else:
		print("Error: Missing original garbage data for respawning")
