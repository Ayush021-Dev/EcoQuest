extends Node2D
@onready var game_timer: Timer = $Timer
@onready var result_label: Label = $ResultLabel 
@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
# Sediment spot management
var sediment_spots = []
var active_spots = []
var inactive_spots = []
var max_active_spots = 3
var bubbles_escaped_count = 0
var spots_cleaned_count = 0
var level_id: String = "lake_level3"
# Rubbing/cleaning variables  
var rubs_needed = 25
var current_rubs = {}  # Dictionary to track rubs per spot

# Mouse dragging variables
var is_dragging = false
var current_spot_being_rubbed = null
var last_mouse_position = Vector2()
var drag_threshold = 10.0  # Minimum distance to count as a rub
var accumulated_drag_distance = 0.0

# Bubble spawning and management
var bubble_template  # Reference to your existing bubble node
var active_bubbles = []  # Track all floating bubbles
var bubble_pop_y_position = 195  # Y position where bubbles pop (adjust based on your scene)

# Instruction UI variables
@export var instruction_panel_path : NodePath = "Panel"  # Path to instruction Panel node
var instructions_visible = true

func _ready():
	$Panel.visible = true
	set_process(false)

	setup_bubble_template()
	setup_sediment_spots()

	if $BG.playing:
		$BG.stop()
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not close_button.pressed.is_connected(_play_click_sound):
		close_button.pressed.connect(_play_click_sound)
	if not close_button.mouse_entered.is_connected(_play_hover_sound):
		close_button.mouse_entered.connect(_play_hover_sound)
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))



func _input(event):
	if instructions_visible and event.is_pressed():
		# On first click, hide instructions and start game
		$Panel.visible = false
		instructions_visible = false
		set_process(true)  # Enable _process and game logic
		activate_random_spots()
		
		# Start background music + countdown timer
		$BG.play()
		game_timer.start()
		return

	
	# Only handle dragging if game started
	if not instructions_visible:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					start_dragging(event.global_position)
				else:
					stop_dragging()
		elif event is InputEventMouseMotion and is_dragging:
			handle_drag_motion(event.global_position)

func start_dragging(mouse_pos):
	is_dragging = true
	last_mouse_position = mouse_pos
	accumulated_drag_distance = 0.0
	
	current_spot_being_rubbed = get_spot_at_position_precise(mouse_pos)
	if current_spot_being_rubbed:
		print("Started rubbing: ", current_spot_being_rubbed.name)
	else:
		print("No spot found at click position")
		is_dragging = false


func stop_dragging():
	is_dragging = false
	current_spot_being_rubbed = null
	accumulated_drag_distance = 0.0
	print("Stopped dragging")

func handle_drag_motion(mouse_pos):
	if current_spot_being_rubbed:
		var distance_moved = last_mouse_position.distance_to(mouse_pos)
		accumulated_drag_distance += distance_moved
		
		if accumulated_drag_distance >= drag_threshold:
			rub_spot(current_spot_being_rubbed)
			accumulated_drag_distance = 0.0
	
	last_mouse_position = mouse_pos

func get_spot_at_position_precise(pos):
	# Check which spot (if any) is at the given position using exact collision detection
	for spot in active_spots:
		
		var collision_shape = spot.get_node("CollisionShape2D")
		if not collision_shape:
			continue
			
		if collision_shape.disabled:
			continue
			
		var shape = collision_shape.shape
		if not shape:
			continue
		
		# Convert global position to spot's local space
		var local_pos = spot.to_local(pos)
		
		# Check if position is within the exact shape
		if shape is RectangleShape2D:
			var rect = Rect2(-shape.size/2, shape.size)
			if rect.has_point(local_pos):
				return spot
		elif shape is CircleShape2D:
			if local_pos.length() <= shape.radius:
				return spot
		elif shape is CapsuleShape2D:
			# For capsule shape, check if point is within the capsule
			# Capsule is basically a rectangle with rounded ends (circles)
			var half_height = shape.height / 2.0
			var radius = shape.radius
			
			# Check if point is within the cylindrical (rectangular) part
			if abs(local_pos.x) <= radius and abs(local_pos.y) <= half_height - radius:
				return spot
			# Check if point is within the top or bottom circular caps
			elif abs(local_pos.y) > half_height - radius:
				var cap_center_y = sign(local_pos.y) * (half_height - radius)
				var distance_to_cap = Vector2(local_pos.x, local_pos.y - cap_center_y).length()
				if distance_to_cap <= radius:
					return spot
		else:
			print("Unknown shape type for ", spot.name, ": ", shape)
	
	print("No spot found at position: ", pos)
	return null

func setup_bubble_template():
	# Get your existing bubble node - adjust the path to match your scene structure
	bubble_template = get_node("Bubbles")  # Update this to match your bubble node name
	
	# Hide the original bubble (we'll duplicate it for spawning)
	if bubble_template:
		bubble_template.visible = false

func setup_sediment_spots():
	# Get all sediment spots
	for i in range(1, 9):  # SedimentSpot1 to SedimentSpot8
		var spot = get_node("SedimentSpot" + str(i))
		sediment_spots.append(spot)
		inactive_spots.append(spot)
		current_rubs[spot] = 0
		
		# Setup bubble timer
		var timer = spot.get_node("Timer")  # Changed from "BubbleTimer" to "Timer"
		timer.timeout.connect(_on_bubble_timer_timeout.bind(spot))
		timer.wait_time = randf_range(1.5, 3.0)  # Random bubble spawn time
		
		# Initially hide spot
		spot.visible = false
		spot.get_node("CollisionShape2D").disabled = true

func activate_random_spots():
	# Make sure we have 3 active spots
	while active_spots.size() < max_active_spots and inactive_spots.size() > 0:
		var random_spot = inactive_spots.pick_random()
		activate_spot(random_spot)

func activate_spot(spot):
	if spot in inactive_spots:
		inactive_spots.erase(spot)
		active_spots.append(spot)
		
		# Make spot visible and interactive
		spot.visible = true
		var collision_shape = spot.get_node("CollisionShape2D")
		collision_shape.disabled = false
		
		# Start bubble generation
		spot.get_node("Timer").start()
		

func deactivate_spot(spot):
	if spot in active_spots:
		active_spots.erase(spot)
		inactive_spots.append(spot)
		
		# Hide and disable spot
		spot.visible = false
		spot.get_node("CollisionShape2D").disabled = true
		
		# Stop bubble generation
		spot.get_node("Timer").stop()
		
		# Reset rub count
		current_rubs[spot] = 0
		

func rub_spot(spot):
	if spot not in active_spots:
		return
		
	current_rubs[spot] += 1
	
	# Visual feedback for rubbing
	create_rub_effect(spot)
	
	# Check if spot is cleaned
	if current_rubs[spot] >= rubs_needed:
		clean_spot(spot)

func clean_spot(spot):
	print("Cleaned spot: ", spot.name)
	spots_cleaned_count += 1
	CarbonFootprintManager.reduce_footprint(15)
	
	if current_spot_being_rubbed == spot:
		current_spot_being_rubbed = null
		accumulated_drag_distance = 0.0
	
	deactivate_spot(spot)
	activate_random_spots()
	
	print("Spots cleaned: ", spots_cleaned_count)

func end_game():
	LevelCompletionManager.mark_level_completed(level_id)

	if $BG.playing:
		$BG.stop()

	# Hide all sediment spots
	for spot in active_spots:
		spot.visible = false
		spot.get_node("CollisionShape2D").disabled = true
		spot.get_node("Timer").stop()

	active_spots.clear()
	inactive_spots.clear()

	# Remove all bubbles instantly
	for bubble in active_bubbles:
		if is_instance_valid(bubble):
			bubble.queue_free()
	active_bubbles.clear()

	# Show results on the ResultLabel
	result_label.text = "Game Over\nBubbles Escaped: " + str(bubbles_escaped_count) + "\nSpots Cleaned: " + str(spots_cleaned_count) + "\nFootprint Change: " + str(bubbles_escaped_count * 5 - spots_cleaned_count * 15)
	result_label.visible = true

	# Stop game inputs and processing
	set_process(false)

	# Wait for 3 seconds then change scene
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func _on_game_timer_timeout():
	end_game()


func create_rub_effect(spot):
	# Simple visual feedback using ColorRect
	var color_rect = spot.get_node("ColorRect")
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate", Color.WHITE * 0.5, 0.1)
	tween.tween_property(color_rect, "modulate", Color.WHITE, 0.1)

func _on_bubble_timer_timeout(spot):
	if spot in active_spots:
		spawn_bubble(spot.global_position)
		
		# Reset timer with random interval
		spot.get_node("Timer").wait_time = randf_range(1.5, 3.0)
		spot.get_node("Timer").start()

func spawn_bubble(pos):
	# Create bubble by duplicating your existing bubble node
	if bubble_template:
		var bubble = bubble_template.duplicate()
		add_child(bubble)  # Add to lake scene
		bubble.global_position = pos
		bubble.visible = true  # Make it visible
		
		# Add to active bubbles list
		active_bubbles.append(bubble)
		
		# Start floating animation
		start_bubble_floating(bubble)
		
		print("Spawned bubble at: ", pos)

func start_bubble_floating(bubble):
	# Play floating animation
	if bubble.has_method("play"):
		bubble.play("floating")
	
	# Create floating movement with jiggle effect
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens at once
	
	# Upward movement
	var target_y = bubble_pop_y_position
	var float_duration = randf_range(3.0, 5.0)  # Random float time
	tween.tween_property(bubble, "global_position:y", target_y, float_duration)
	
	# Jiggle effect (side to side movement)
	create_bubble_jiggle(bubble, float_duration)
	
	# When bubble reaches pop position, make it pop
	tween.tween_callback(pop_bubble.bind(bubble)).set_delay(float_duration)

func create_bubble_jiggle(bubble, duration):
	# Create continuous jiggle movement
	var jiggle_tween = create_tween()
	jiggle_tween.set_loops()  # Infinite loop
	
	var original_x = bubble.global_position.x
	var jiggle_range = 20  # How far left/right to jiggle
	
	# Jiggle left and right
	jiggle_tween.tween_property(bubble, "global_position:x", original_x + jiggle_range, 0.8)
	jiggle_tween.tween_property(bubble, "global_position:x", original_x - jiggle_range, 0.8)
	jiggle_tween.tween_property(bubble, "global_position:x", original_x, 0.8)
	
	# Stop jiggle when bubble should pop
	get_tree().create_timer(duration).timeout.connect(jiggle_tween.kill)

func pop_bubble(bubble):
	if bubble and is_instance_valid(bubble):
		active_bubbles.erase(bubble)
		
		bubbles_escaped_count += 1
		CarbonFootprintManager.add_footprint(5)
		
		if bubble.has_method("play"):
			bubble.play("click")
			
		get_tree().create_timer(0.5).timeout.connect(bubble.queue_free)
		print("Bubble escaped! Total:", bubbles_escaped_count)
		
func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func _play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func _play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()
