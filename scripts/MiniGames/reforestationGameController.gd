extends Node

var correct_orders = [
["Aquatic Plants", "Snail", "Frog", "Snake", "Crocodile"],
["Insects", "Chick", "Pig", "Bear", "Tiger"],
["Phytoplankton", "Krill", "Walrus", "Polar Bear", "Orca"],
["Fruit", "Parrot", "Snake", "Jaguar", "Anaconda"],
["Grain", "Chicken", "Rat", "Dog", "Fox"]
]

var matched_sequences = []
var player_selection = []

@onready var grid = get_parent().get_node("GridContainer")
@onready var label = get_parent().get_node("UI/Label")
@onready var rect = get_parent().get_node("UI/ColorRect")
@onready var close_button = get_parent().get_node("CloseButton")
@onready var click_sound = get_parent().get_node("ClickSound")
@onready var hover_sound = get_parent().get_node("HoverSound")

func _ready():
	label.hide()
	player_selection.clear()
	matched_sequences.clear()
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not close_button.pressed.is_connected(_play_click_sound):
		close_button.pressed.connect(_play_click_sound)
	if not close_button.mouse_entered.is_connected(_play_hover_sound):
		close_button.mouse_entered.connect(_play_hover_sound)
	for button in grid.get_children():
		button.custom_minimum_size = Vector2(100, 100)
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.pressed.connect(Callable(self, "_on_tile_pressed").bind(button.name))
		button.modulate = Color(1, 1, 1, 1)

func _on_tile_pressed(tile_name):
	if tile_name in player_selection:
		return
	player_selection.append(tile_name)
	var button = _get_button_by_name(tile_name)
	if button:
		button.modulate = Color(0.4, 0.4, 0.4, 1)
		click_sound.play()  # Visual feedback on select

	var seq_length = correct_orders[0].size()
	if player_selection.size() == seq_length:
		var player_str = []
		for s in player_selection:
			player_str.append(str(s))
		
		var matched_index = -1
		for i in range(correct_orders.size()):
			if i in matched_sequences:
				continue
			var correct_str = []
			for c in correct_orders[i]:
				correct_str.append(str(c))
			if player_str == correct_str:
				matched_index = i
				break

		if matched_index != -1:
			matched_sequences.append(matched_index)
			_blackout_sequence(matched_index)
			_mark_buttons(true)
			player_selection.clear()
			if matched_sequences.size() == correct_orders.size():
				await _win_game()
		else:
			_mark_buttons(false)
			await _show_try_again()
			_reset_selection()

func _blackout_sequence(index):
	for tile_name in correct_orders[index]:
		var button = _get_button_by_name(tile_name)
		if button:
			button.modulate = Color(0, 0, 0, 1)  # Blackout

func _mark_buttons(correct: bool):
	var color = Color(0, 1, 0, 1) if correct else Color(1, 0, 0, 1)
	for tile_name in player_selection:
		var button = _get_button_by_name(tile_name)
		if button:
			button.modulate = color

func _win_game():
	label.text = "Good job!"
	label.visible = true
	label.show()
	rect.visible=true
	rect.show()
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func _show_try_again():
	label.text = "Try Again!"
	label.visible = true
	rect.visible=true
	rect.show()
	label.show()
	await _shake_grid()

func _reset_selection():
	player_selection.clear()
	for button in grid.get_children():
		button.modulate = Color(1, 1, 1, 1)
	label.hide()
	rect.visible=false
	rect.hide()

func _shake_grid():
	var original_pos = grid.position
	var shake_amount = 10
	var shakes = 6
	for i in range(shakes):
		var offset = shake_amount if i % 2 == 0 else -shake_amount
		grid.position.x = original_pos.x + offset
		await get_tree().create_timer(0.05).timeout
	grid.position = original_pos

func _get_button_by_name(tile_name: String) -> TextureButton:
	for button in grid.get_children():
		if button.name == tile_name:
			return button
	return null

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
