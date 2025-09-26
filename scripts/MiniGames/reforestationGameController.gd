extends Node2D

# Inventory item constants
const ITEM_SEED = "seed"
const ITEM_WATER = "water"
const ITEM_SUN = "sun"
const ITEM_PESTICIDE = "pesticide"

@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var panel = $Panel
@onready var bg_music = $BG
@onready var win_panel = $WinPanel
@onready var win_label = $WinPanel/WinLabel

const STAGE_REQUIREMENTS = {
	0: {"water": 2, "sun": 2, "pesticide": 1},  # Seed to Seedling
	1: {"water": 3, "sun": 3, "pesticide": 1},  # Seedling to Young Plant
	2: {"water": 4, "sun": 5, "pesticide": 2}   # Young Plant to Full Tree
}

var selected_item : Variant = null

var seed_planted : bool = false
var water_amount : int = 0
var sun_amount : int = 0
var pesticide_amount : int = 0
var current_growth_stage : int = 0
const MAX_GROWTH_STAGE = 3
var has_won = false
var soil_plot : Area2D = null
var seed_sprite : Sprite2D = null
var error_label : Label = null
var inventory_buttons : Dictionary = {}
var reset_button : TextureButton = null

var is_game_paused = true

func _ready() -> void:
	soil_plot = get_node_or_null("Environment/Soil/SoilPlot")
	if soil_plot:
		seed_sprite = soil_plot.get_node_or_null("SeedSprite")
	error_label = get_node_or_null("ErrorLabel")

	inventory_buttons = {
		ITEM_SEED: get_node_or_null("InventoryPanel/SeedButton"),
		ITEM_WATER: get_node_or_null("InventoryPanel/WaterButton"),
		ITEM_SUN: get_node_or_null("InventoryPanel/SunButton"),
		ITEM_PESTICIDE: get_node_or_null("InventoryPanel/PesticideButton")
	}

	if panel:
		panel.visible = true
		panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	get_tree().paused = true
	is_game_paused = true
	
	if panel and not panel.is_connected("gui_input", Callable(self, "_on_panel_gui_input")):
		panel.connect("gui_input", Callable(self, "_on_panel_gui_input"))

	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.connect("pressed", Callable(self, "_on_close_pressed"))
	if not close_button.is_connected("pressed", Callable(self, "_play_click_sound")):
		close_button.connect("pressed", Callable(self, "_play_click_sound"))
	if not close_button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
		close_button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	reset_button = get_node_or_null("ResetButton")
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
		if not reset_button.is_connected("pressed", Callable(self, "_play_click_sound")):
			reset_button.connect("pressed", Callable(self, "_play_click_sound"))
		if not reset_button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
			reset_button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	for item in inventory_buttons.keys():
		var button = inventory_buttons[item]
		if button:
			button.pressed.connect(_on_inventory_item_pressed.bind(item))
			if not button.is_connected("pressed", Callable(self, "_play_click_sound")):
				button.connect("pressed", Callable(self, "_play_click_sound"))
			if not button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
				button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	if soil_plot:
		soil_plot.input_event.connect(_on_soil_plot_input)

	if win_panel:
		win_panel.visible = false

	reset()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and is_game_paused:
		panel.visible = false
		get_tree().paused = false
		set_process(true)
		is_game_paused = false
		if bg_music and not bg_music.playing:
			bg_music.play()
		_play_click_sound()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				reset()
				_play_click_sound()
				if error_label:
					error_label.text = "Game reset with R key!"
			KEY_1:
				selected_item = ITEM_SEED
				update_button_glow()
				_play_click_sound()
				if error_label:
					error_label.text = "Selected: Seed (Key 1)"
			KEY_2:
				selected_item = ITEM_WATER
				update_button_glow()
				_play_click_sound()
				if error_label:
					error_label.text = "Selected: Water (Key 2)"
			KEY_3:
				selected_item = ITEM_SUN
				update_button_glow()
				_play_click_sound()
				if error_label:
					error_label.text = "Selected: Sun (Key 3)"
			KEY_4:
				selected_item = ITEM_PESTICIDE
				update_button_glow()
				_play_click_sound()
				if error_label:
					error_label.text = "Selected: Pesticide (Key 4)"

func reset() -> void:
	selected_item = null
	seed_planted = false
	water_amount = 0
	sun_amount = 0
	pesticide_amount = 0
	current_growth_stage = 0
	if seed_sprite:
		seed_sprite.visible = false
	if error_label:
		error_label.text = ""
	update_button_glow()
	update_growth_visual()
	if win_panel:
		win_panel.visible = false

func _on_inventory_item_pressed(item: String) -> void:
	selected_item = item
	update_button_glow()
	if error_label:
		error_label.text = "Selected: %s" % item.capitalize()

func update_button_glow() -> void:
	for item in inventory_buttons.keys():
		var button = inventory_buttons[item]
		if button:
			button.modulate = Color.WHITE
	if selected_item and inventory_buttons.has(selected_item):
		var selected_button = inventory_buttons[selected_item]
		if selected_button:
			selected_button.modulate = Color(1.3, 1.3, 0.8, 1.0)

func get_current_requirements() -> Dictionary:
	return STAGE_REQUIREMENTS.get(current_growth_stage, {"water": 0, "sun": 0, "pesticide": 0})

func _on_reset_button_pressed() -> void:
	reset()
	if error_label:
		error_label.text = "Game reset! Plant a new seed."

func _on_soil_plot_input(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_click_sound()
		if selected_item == ITEM_SEED:
			if seed_planted:
				show_error("Seed already planted.")
			else:
				plant_seed()
		elif seed_planted:
			if selected_item == ITEM_WATER:
				apply_water()
			elif selected_item == ITEM_SUN:
				apply_sun()
			elif selected_item == ITEM_PESTICIDE:
				apply_pesticide()
			else:
				show_error("Select a valid item to apply.")
		else:
			show_error("Plant seed first.")

func plant_seed() -> void:
	seed_planted = true
	if seed_sprite:
		seed_sprite.visible = true
	water_amount = 0
	sun_amount = 0
	pesticide_amount = 0
	current_growth_stage = 0
	update_growth_visual()
	var requirements = get_current_requirements()
	if error_label:
		error_label.text = "Seed planted! Need: %d water, %d sun, %d pesticide" % [requirements.water, requirements.sun, requirements.pesticide]

func apply_water() -> void:
	water_amount += 1
	validate_and_grow()

func apply_sun() -> void:
	sun_amount += 1
	validate_and_grow()

func apply_pesticide() -> void:
	pesticide_amount += 1
	validate_and_grow()

func validate_and_grow() -> void:
	var requirements = get_current_requirements()
	if water_amount > requirements.water:
		show_error("Too much water! Max needed: %d" % requirements.water)
		return
	if sun_amount > requirements.sun:
		show_error("Too much sun! Max needed: %d" % requirements.sun)
		return
	if pesticide_amount > requirements.pesticide:
		show_error("Too much pesticide! Max needed: %d" % requirements.pesticide)
		return
	if water_amount == requirements.water and sun_amount == requirements.sun and pesticide_amount == requirements.pesticide:
		grow_plant()
	else:
		var remaining_water = requirements.water - water_amount
		var remaining_sun = requirements.sun - sun_amount  
		var remaining_pesticide = requirements.pesticide - pesticide_amount
		if error_label:
			error_label.text = "Stage %d - Still need: %d water, %d sun, %d pesticide" % [current_growth_stage + 1, remaining_water, remaining_sun, remaining_pesticide]

func grow_plant() -> void:
	if current_growth_stage < MAX_GROWTH_STAGE:
		current_growth_stage += 1
		update_growth_visual()
		_play_click_sound()
		if current_growth_stage == MAX_GROWTH_STAGE:
				
				if not has_won:
					has_won = true
					game_won()
		if error_label:
			if current_growth_stage == MAX_GROWTH_STAGE:
				error_label.text = "Plant fully grown! 🌳"
				if not has_won:
					has_won = true
					game_won()
			else:
				var next_requirements = get_current_requirements()
				error_label.text = "Grew to stage %d! Next: %d water, %d sun, %d pesticide" % [current_growth_stage, next_requirements.water, next_requirements.sun, next_requirements.pesticide]
		water_amount = 0
		sun_amount = 0
		pesticide_amount = 0
	elif current_growth_stage == MAX_GROWTH_STAGE and not has_won:
		if error_label:
			error_label.text = "Plant fully grown! 🌳"
		has_won = true
		game_won()
	else:
		if error_label:
			error_label.text = "Plant fully grown! 🌳"

func update_growth_visual() -> void:
	if not seed_sprite:
		return
	match current_growth_stage:
		0:
			seed_sprite.texture = preload("res://assets/items/Trees/Seed.png")
			seed_sprite.scale = Vector2(1.0, 1.0)
		1:
			seed_sprite.texture = preload("res://assets/items/Trees/Seedling.png")
			seed_sprite.scale = Vector2(1.0, 1.0)
		2:
			seed_sprite.texture = preload("res://assets/items/Trees/wild_plant_grow_12.png")
			seed_sprite.scale = Vector2(5.0, 5.0)
		3:
			seed_sprite.texture = preload("res://assets/items/Trees/Glondo_Game_Tree_Sprites_Tree_2.png")
			seed_sprite.scale = Vector2(1.0, 1.0)

func show_error(msg: String) -> void:
	if error_label:
		error_label.text = "[ERROR] " + msg

func game_won():
	set_process(false)
	if win_panel:
		win_panel.visible = true
	if win_label:
		win_label.text = " GAME WON! \nCongratulations, you reforested the plot!"
		
	LevelCompletionManager.mark_level_completed("reforestation_level3")
	if bg_music and bg_music.playing:
		bg_music.stop()
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func _play_click_sound():
	if click_sound and click_sound.playing:
		click_sound.stop()
	if click_sound:
		click_sound.play()

func _play_hover_sound():
	if hover_sound and hover_sound.playing:
		hover_sound.stop()
	if hover_sound:
		hover_sound.play()
