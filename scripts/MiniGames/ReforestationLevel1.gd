extends Node2D

@export var insect_scenes : Array[PackedScene]

@onready var insect_container = $InsectContainer
@onready var tree_health_bar = $TreeHealth
@onready var insect_spawn_timer = $InsectSpawnTimer
@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var health_change_label = $TreeHealth/HealthChangeLabel
@onready var game_timer = $GameTimer  # Timer node set for 120 seconds
@onready var game_over_panel = $GameOver
@onready var game_over_label = $GameOver/Label
@onready var instructions_panel = $Panel  # Added for instructions panel
@onready var bg_sound=$BG
var tree_health = 100
var cockroaches_killed: int = 0
var butterflies_killed: int = 0
var beetles_killed: int = 0
var initial_tree_health: int = 100
var level_id: String = "reforestation_level1"

func _ready():
	insect_scenes = [
		preload("res://scenes/Insects/Cockroach.tscn"),
		preload("res://scenes/Insects/Butterfly.tscn"),
		preload("res://scenes/Insects/Beetles.tscn"),
		preload("res://scenes/Insects/Ants.tscn"),
	]

	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not close_button.pressed.is_connected(_play_click_sound):
		close_button.pressed.connect(_play_click_sound)
	if not close_button.mouse_entered.is_connected(_play_hover_sound):
		close_button.mouse_entered.connect(_play_hover_sound)

	insect_spawn_timer.connect("timeout", Callable(self, "_on_InsectSpawnTimer_timeout"))
	game_timer.connect("timeout", Callable(self, "_on_game_timer_timeout"))
	
	# Do NOT start timers here. Wait for player to click instructions panel.
	insect_spawn_timer.stop()
	game_timer.stop()

	tree_health_bar.min_value = 0
	tree_health_bar.max_value = 100
	tree_health_bar.value = tree_health
	health_change_label.visible = false
	
	instructions_panel.visible = true  # Show instructions when ready

# Called when player clicks anywhere on the instructions panel to start the game
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		instructions_panel.hide()
		start_game()
		bg_sound.play()
		

func start_game():
	insect_spawn_timer.start()
	game_timer.start()

func spawn_insect():
	var insect_scene = insect_scenes[randi() % insect_scenes.size()]
	var insect = insect_scene.instantiate()
	insect.speed = randf_range(100, 250)
	
	var min_y = 460
	var max_y = 620
	
	var spawn_y = randf_range(min_y, max_y)
	
	insect.position = Vector2(900, spawn_y)
	insect.fixed_y = spawn_y
	insect.direction = Vector2(-1, 0)

	insect.main = self
	
	insect_container.add_child(insect)

func _on_InsectSpawnTimer_timeout():
	spawn_insect()

func reduce_tree_health(amount):
	tree_health = clamp(tree_health - amount, 0, 100)
	tree_health_bar.value = tree_health
	show_health_change(-amount)
	
	# Each health point lost increases carbon footprint
	CarbonFootprintManager.add_footprint(amount)
	
	if tree_health <= 0:
		game_over()

func on_insect_killed(insect_type: String):
	match insect_type.to_lower():
		"cockroach":
			cockroaches_killed += 1
			# Killing cockroaches reduces footprint (good action)
			CarbonFootprintManager.reduce_footprint(2)
		"butterfly":
			butterflies_killed += 1
			# Killing butterflies increases footprint (bad action)
			CarbonFootprintManager.add_footprint(5)
		"beetles":
			beetles_killed += 1
			# Killing beetles increases footprint (bad action)
			CarbonFootprintManager.add_footprint(3)
			
func increase_tree_health(amount):
	tree_health = clamp(tree_health + amount, 0, 100)
	tree_health_bar.value = tree_health
	show_health_change(amount)

func _on_game_timer_timeout():
	if tree_health >= 80:
		await show_game_won()
	else:
		await game_over()

func show_game_won() -> void:
	# Calculate final footprint bonus/penalty
	calculate_final_footprint_score()
	
	# Mark level as completed
	LevelCompletionManager.mark_level_completed(level_id)
	
	# Better win message
	game_over_label.text = "Great Job! You Saved the Tree! 🌳\nThe forest is safe thanks to you!"
	game_over_label.modulate = Color(0, 1, 0)  # green
	game_over_panel.visible = true
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func game_over() -> void:
	# Penalty for losing the level
	CarbonFootprintManager.add_footprint(100)
	
	game_over_label.text = "Game Over, try again"
	game_over_label.modulate = Color(1, 0, 0)  # red
	game_over_panel.visible = true
	get_tree().paused = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func calculate_final_footprint_score():
	var health_lost = initial_tree_health - tree_health
	
	# Bonus for winning with high health
	if tree_health >= 80:
		CarbonFootprintManager.reduce_footprint(50)
	
	print("Level 1 Final Stats:")
	print("Cockroaches killed: ", cockroaches_killed, " (footprint reduced by ", cockroaches_killed * 2, ")")
	print("Butterflies killed: ", butterflies_killed, " (footprint increased by ", butterflies_killed * 5, ")")
	print("Beetles killed: ", beetles_killed, " (footprint increased by ", beetles_killed * 3, ")")
	print("Health lost: ", health_lost, " (footprint increased by ", health_lost, ")")
	print("Win bonus: -50 footprint")

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

func show_health_change(amount):
	health_change_label.text = ("+" if amount > 0 else "") + str(amount) + " points"
	health_change_label.modulate = Color(0, 0.5, 0) if amount > 0 else Color(0.5, 0, 0)
	health_change_label.modulate.a = 1.0
	health_change_label.show()

	var tween = create_tween()
	tween.tween_property(health_change_label, "modulate:a", 0, 1.0)
	tween.connect("finished", Callable(self, "_on_health_change_fade_finished"))

func _on_health_change_fade_finished():
	health_change_label.hide()
