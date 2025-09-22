extends Node2D

# Game settings
var score = 0
var wind_speed = 120.0
var max_seeds_on_screen = 4
var current_seeds = []
var seed_types = [1, 2, 3]

# Wind control
var wind_direction = Vector2.ZERO

# Game boundaries
var boundary_left = 22.0
var boundary_right = 1130.0
var boundary_top = 30.0
var boundary_bottom = 634.0

# Soil areas
var soil_areas = []

# Scene node references
@onready var pits_node = $Pits
@onready var bushes_container = $Bushes
@onready var instructions_panel = $InstructionsPanel
@onready var instructions_label = $InstructionsPanel/InstructionsLabel
@onready var game_timer = $GameTimer
@onready var bg_music = $BG

var game_started = false

func _ready():
	instructions_panel.visible = true
	show_instructions_text()
	game_started = false
	game_timer.stop()

	if not game_timer.is_connected("timeout", Callable(self, "_on_Timer_timeout")):
		game_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))

	print("=== REFORESTATION GAME STARTED ===")

func show_instructions_text():
	instructions_label.text = "🌱 Welcome to Reforestation!\n\n"
	instructions_label.text += "Seed dispersal helps plants spread and grow. Matching seeds to the correct soil type is vital for healthy plants.\n\n"
	instructions_label.text += "In this level, there are three soils:\n- Black Soil which supports cotton seed\n- Red Soil which supports jowar seed\n- Sandy Soil which supports carrot seed\n\n"
	instructions_label.text += "You control the wind with arrow keys. Use wind direction to move seeds into the right soil.\n"
	instructions_label.text += "Correct matches give +10 points, wrong matches -5 points.\n\n"
	instructions_label.text += "Click/tap anywhere to begin!"

func _input(event):
	if not game_started and (event is InputEventMouseButton or event is InputEventScreenTouch):
		instructions_panel.visible = false
		game_started = true
		start_game()
		bg_music.play()
func start_game():
	setup_game()
	spawn_initial_seeds()
	game_timer.start()

func _process(delta):
	if not game_started:
		return
	handle_wind_input()
	move_seeds_with_wind(delta)
	check_seed_count()

func _on_Timer_timeout():
	game_over()

func game_over() -> void:
	game_started = false
	game_timer.stop()

	# Remove all seeds from scene
	for seed in current_seeds:
		if is_instance_valid(seed):
			seed.queue_free()
	current_seeds.clear()

	update_carbon_footprint()
	LevelCompletionManager.mark_level_completed("reforestation_level2")
	show_final_score()
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func update_carbon_footprint():
	if score > 25:
		var reduce_amount = score - 25
		CarbonFootprintManager.reduce_footprint(reduce_amount)
		print("Carbon footprint reduced by ", reduce_amount)
	else:
		var increase_amount = 25 - score
		CarbonFootprintManager.add_footprint(increase_amount)
		print("Carbon footprint increased by ", increase_amount)


func show_final_score():
	instructions_panel.visible = true
	instructions_label.text = "Your final score: " + str(score) + "\n"
	
	# Hide all children except InstructionsLabel to hide seed images
	for child in instructions_panel.get_children():
		if child != instructions_label:
			child.visible = false

# Wind control
func handle_wind_input():
	wind_direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		wind_direction.x = -1
	if Input.is_action_pressed("ui_right"):
		wind_direction.x = 1
	if Input.is_action_pressed("ui_up"):
		wind_direction.y = -1
	if Input.is_action_pressed("ui_down"):
		wind_direction.y = 1
	
	wind_direction = wind_direction.normalized()

func move_seeds_with_wind(delta):
	if wind_direction == Vector2.ZERO:
		return
	
	for game_seed in current_seeds:
		if is_instance_valid(game_seed):
			move_single_seed(game_seed, delta)

func move_single_seed(game_seed, delta):
	var current_pos = game_seed.position
	var intended_move = wind_direction * wind_speed * delta
	var new_position = current_pos + intended_move
	
	if can_seed_move_to(game_seed, new_position):
		game_seed.position = new_position
	else:
		var x_only_pos = Vector2(current_pos.x + intended_move.x, current_pos.y)
		if can_seed_move_to(game_seed, x_only_pos):
			game_seed.position = x_only_pos
		else:
			var y_only_pos = Vector2(current_pos.x, current_pos.y + intended_move.y)
			if can_seed_move_to(game_seed, y_only_pos):
				game_seed.position = y_only_pos

func can_seed_move_to(_game_seed, new_pos) -> bool:
	if new_pos.x < boundary_left or new_pos.x > boundary_right:
		return false
	if new_pos.y < boundary_top or new_pos.y > boundary_bottom:
		return false
	
	for bush in bushes_container.get_children():
		var bush_collision_radius = 30.0
		var distance = bush.global_position.distance_to(new_pos)
		if distance < bush_collision_radius:
			return false
	
	return true

func setup_game():
	soil_areas.clear()
	for child in pits_node.get_children():
		if child.has_method("get_soil_type"):
			soil_areas.append(child)
			print("Found soil area: ", child.name)
	
	print("Using boundaries - Left:", boundary_left, " Right:", boundary_right, " Top:", boundary_top, " Bottom:", boundary_bottom)
	print("Found ", bushes_container.get_child_count(), " bushes in the scene")

func spawn_initial_seeds():
	for i in range(max_seeds_on_screen):
		spawn_random_seed()

func spawn_random_seed():
	if current_seeds.size() >= max_seeds_on_screen:
		return
	
	var seed_type = seed_types[randi() % seed_types.size()]
	var spawn_pos = get_random_spawn_position()
	
	if spawn_pos != Vector2.ZERO:
		create_seed(seed_type, spawn_pos)

func get_random_spawn_position() -> Vector2:
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		var random_x = randf_range(boundary_left + 50, boundary_right - 50)
		var random_y = randf_range(boundary_top + 50, boundary_bottom - 50)
		var test_pos = Vector2(random_x, random_y)
		
		if is_position_free(test_pos):
			return test_pos
		
		attempts += 1
	
	return Vector2(200, 200)

func is_position_free(pos) -> bool:
	for soil in soil_areas:
		var soil_rect = Rect2(soil.position - Vector2(50, 50), Vector2(100, 100))
		if soil_rect.has_point(pos):
			return false
	
	for bush in bushes_container.get_children():
		var bush_collision_radius = 30.0
		var distance = bush.global_position.distance_to(pos)
		if distance < bush_collision_radius:
			return false
	
	return true

func create_seed(seed_type, spawn_position):
	var game_seed = Area2D.new()
	game_seed.name = "Seed_" + str(seed_type)
	
	var sprite = Sprite2D.new()
	match seed_type:
		1:
			sprite.texture = load("res://assets/characters/seed1.png")
		2:
			sprite.texture = load("res://assets/characters/seed2.png")
		3:
			sprite.texture = load("res://assets/characters/seed3.png")
	sprite.scale = Vector2(2, 2)
	game_seed.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	game_seed.add_child(collision)
	
	game_seed.position = spawn_position
	game_seed.set_meta("seed_type", seed_type)
	game_seed.area_entered.connect(_on_seed_touched_area.bind(game_seed))
	
	add_child(game_seed)
	current_seeds.append(game_seed)
	
	print("Spawned seed type ", seed_type, " at ", spawn_position)

func _on_seed_touched_area(area, game_seed):
	var soil_type = get_soil_type_from_area(area)
	if soil_type > 0:
		handle_seed_soil_collision(game_seed, soil_type)

func get_soil_type_from_area(area) -> int:
	if area.has_method("get_soil_type"):
		return area.get_soil_type()
	if area.name == "Pit1":
		return 1
	elif area.name == "Pit2":
		return 2
	elif area.name == "Pit3":
		return 3
	return 0

func handle_seed_soil_collision(game_seed, soil_type):
	var seed_type = game_seed.get_meta("seed_type")
	var is_correct = (seed_type == soil_type)
	if is_correct:
		score += 10
		show_feedback(game_seed.position, "+10", Color.GREEN)
	else:
		score -= 5
		show_feedback(game_seed.position, "-5", Color.RED)
	print("Current Score: ", score)
	remove_seed(game_seed)
	get_tree().create_timer(0.5).timeout.connect(spawn_random_seed)

func remove_seed(game_seed):
	if game_seed in current_seeds:
		current_seeds.erase(game_seed)
	if is_instance_valid(game_seed):
		game_seed.queue_free()

func check_seed_count():
	for i in range(current_seeds.size() - 1, -1, -1):
		if not is_instance_valid(current_seeds[i]):
			current_seeds.remove_at(i)
	while current_seeds.size() < max_seeds_on_screen:
		spawn_random_seed()

func show_feedback(feedback_position, text, _color):
	print("Feedback at ", feedback_position, ": ", text)
