extends Node2D
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound

var questions = [
	{
		"q": "What is the biggest rainforest in the world?",
		"opts": ["Amazon", "Congo", "Daintree", "Sundarbans"],
		"correct": 0,
		"feedback": [
			"Correct! The Amazon is the largest.", 
			"No, it's the Amazon.", 
			"No, it's the Amazon.", 
			"No, it's the Amazon."
		]
	},
	{
		"q": "What do trees absorb from the atmosphere?",
		"opts": ["Oxygen", "CO2", "Nitrogen", "Helium"],
		"correct": 1,
		"feedback": [
			"No, that's not right.", 
			"Correct! Trees absorb carbon dioxide.",
			"No, that's not right.",
			"No, that's not right."
		]
	}
]

var current = 0

@onready var close_button = $CloseButton
@onready var question_label = $Question
var buttons = []
var feedback_label
var next_button

func _ready():
	buttons = [
		$Question.get_node("1"),
		$Question.get_node("2"),
		$Question.get_node("3"),
		$Question.get_node("4")
	]
	feedback_label = $Question.get_node("Feedback")
	next_button = $Question.get_node("Next")

	# Connect sounds and handlers only once for Next and Close buttons
	if not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)
	if not next_button.pressed.is_connected(_play_click_sound):
		next_button.pressed.connect(_play_click_sound)
	if not next_button.mouse_entered.is_connected(_play_hover_sound):
		next_button.mouse_entered.connect(_play_hover_sound)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not close_button.pressed.is_connected(_play_click_sound):
		close_button.pressed.connect(_play_click_sound)
	if not close_button.mouse_entered.is_connected(_play_hover_sound):
		close_button.mouse_entered.connect(_play_hover_sound)

	# For option buttons: connect handlers and sounds only once
	for i in range(buttons.size()):
		if not buttons[i].pressed.is_connected(_play_click_sound):
			buttons[i].pressed.connect(_play_click_sound)
		if not buttons[i].mouse_entered.is_connected(_play_hover_sound):
			buttons[i].mouse_entered.connect(_play_hover_sound)
		# Option pressed handler uses a lambda, so must always connect anew
		buttons[i].pressed.connect(func():
			_on_option_pressed(i)
		)

	load_question()

func load_question():
	var q_data = questions[current]
	question_label.text = q_data["q"]
	for i in range(buttons.size()):
		buttons[i].get_node("Label").text = q_data["opts"][i]
		buttons[i].disabled = false
		buttons[i].visible = true
		buttons[i].modulate = Color(1, 1, 1)  # Normal color
	feedback_label.text = ""
	feedback_label.visible = true
	next_button.visible = false

func _on_option_pressed(idx):
	var q_data = questions[current]
	for b in buttons:
		b.disabled = true
	buttons[q_data["correct"]].modulate = Color(0.6, 1.0, 0.6)
	if idx != q_data["correct"]:
		buttons[idx].modulate = Color(1.0, 0.6, 0.6)
	feedback_label.text = q_data["feedback"][idx]
	next_button.visible = true

func _on_next_pressed():
	current += 1
	if current < questions.size():
		load_question()
	else:
		show_quiz_end()

func show_quiz_end():
	question_label.text = "Quiz finished!"
	for b in buttons:
		b.hide()
	feedback_label.hide()
	next_button.hide()

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
