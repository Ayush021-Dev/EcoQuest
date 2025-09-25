extends Node2D
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var instructions_panel = $Panel  # Instructions panel

var questions = [
  {
	"q": "What is the primary purpose of crop rotation?",
	"opts": ["Increase soil fertility", "Water conservation", "Prevent pests", "All of the above"],
	"correct": 3,
	"feedback": [
	  "Not quite. Crop rotation helps fertility but also more.", 
	  "Water conservation is a benefit but not main goal alone.", 
	  "Pest prevention is part of it but incomplete.", 
	  "Correct! Crop rotation improves soil, water, and pest control."
	]
  },
  {
	"q": "Which of the following is a nitrogen-fixing crop?",
	"opts": ["Rice", "Soybean", "Corn", "Wheat"],
	"correct": 1,
	"feedback": [
	  "No, rice is not nitrogen-fixing.", 
	  "Correct! Soybean enriches soil with nitrogen.", 
	  "No, corn is not nitrogen-fixing.", 
	  "No, wheat is not nitrogen-fixing."
	]
  },
  {
	"q": "What role do bees play in farming?",
	"opts": ["Pest control", "Pollination", "Provide honey only", "Weed removal"],
	"correct": 1,
	"feedback": [
	  "No, bees pollinate rather than control pests.", 
	  "Correct! Bees are essential pollinators for crops.", 
	  "Honey is a product but pollination is key role.", 
	  "No, bees do not remove weeds."
	]
  },
  {
	"q": "Which farming practice helps reduce soil erosion?",
	"opts": ["Monoculture", "No-till farming", "Overgrazing", "Deforestation"],
	"correct": 1,
	"feedback": [
	  "No, monoculture can increase erosion.", 
	  "Correct! No-till farming protects soil structure.", 
	  "No, overgrazing causes erosion.", 
	  "No, deforestation is destructive."
	]
  },
  {
	"q": "Which machinery is commonly used for planting crops?",
	"opts": ["Harvester", "Tractor", "Seeder", "Sprayer"],
	"correct": 2,
	"feedback": [
	  "No, harvesters are for harvesting crops.", 
	  "Tractors provide power but don’t plant.", 
	  "Correct! Seeders are used to plant crops.", 
	  "No, sprayers apply pesticides."
	]
  }
]

var current = 0
@onready var close_button = $CloseButton
@onready var question_label = $Question
@onready var bg_music = $BG

var buttons = []
var feedback_label
var next_button
var correct_answers: int = 0
var wrong_answers: int = 0
var level_id: String = "farm_level4"

func _ready():
	# Show instructions panel initially
	instructions_panel.visible = true

	buttons = [
		$Question.get_node("1"),
		$Question.get_node("2"),
		$Question.get_node("3"),
		$Question.get_node("4")
	]
	feedback_label = $Question.get_node("Feedback")
	next_button = $Question.get_node("Next")

	for b in buttons:
		b.disabled = true
		b.visible = false
	next_button.disabled = true
	next_button.visible = false

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

	for button in buttons:
		if not button.pressed.is_connected(_play_click_sound):
			button.pressed.connect(_play_click_sound)
		button.pressed.connect(func(_btn=button):
			var idx = buttons.find(_btn)
			_on_option_pressed(idx)
		)
		button.mouse_entered.connect(func(_btn=button):
			_play_hover_sound()
		)

	if LevelCompletionManager.is_level_completed(level_id):
		show_already_completed()
		return

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		instructions_panel.hide()
		start_quiz()
		bg_music.play()

func start_quiz():
	for b in buttons:
		b.disabled = false
		b.visible = true
	next_button.disabled = false
	next_button.visible = false  # Next shown after answering

	current = 0
	load_question()

func load_question():
	var q_data = questions[current]
	question_label.text = q_data["q"]
	for i in range(buttons.size()):
		buttons[i].get_node("Label").text = q_data["opts"][i]
		buttons[i].disabled = false
		buttons[i].visible = true
		buttons[i].modulate = Color(1, 1, 1)
	feedback_label.text = ""
	feedback_label.visible = true
	next_button.visible = false

func _on_option_pressed(idx):
	var q_data = questions[current]
	for b in buttons:
		b.disabled = true
	buttons[q_data["correct"]].modulate = Color(0.6, 1.0, 0.6)

	if idx == q_data["correct"]:
		correct_answers += 1
		CarbonFootprintManager.reduce_footprint(10)
		print("Correct answer! Footprint reduced by 10")
	else:
		wrong_answers += 1
		CarbonFootprintManager.add_footprint(5)
		print("Wrong answer! Footprint increased by 5")
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
	calculate_final_quiz_score()

	LevelCompletionManager.mark_level_completed(level_id)

	question_label.text = "Quiz Completed!\nCorrect: " + str(correct_answers) + "/" + str(questions.size())
	for b in buttons:
		b.hide()
	feedback_label.text = "Great job learning about farming!"
	feedback_label.visible = true
	next_button.hide()

	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/FarmLevels.tscn")

func calculate_final_quiz_score():
	CarbonFootprintManager.reduce_footprint(20)

	var accuracy = float(correct_answers) / float(questions.size())
	if accuracy >= 0.8:
		CarbonFootprintManager.reduce_footprint(30)
		print("High accuracy bonus: -30 footprint")
	elif accuracy >= 0.6:
		CarbonFootprintManager.reduce_footprint(15)
		print("Good accuracy bonus: -15 footprint")

	print("Quiz Final Stats:")
	print("Correct answers: ", correct_answers, " (footprint reduced by ", correct_answers * 10, ")")
	print("Wrong answers: ", wrong_answers, " (footprint increased by ", wrong_answers * 5, ")")
	print("Completion bonus: -20 footprint")
	print("Final accuracy: ", accuracy * 100, "%")

func show_already_completed():
	question_label.text = "Level Already Completed!"
	for b in buttons:
		b.hide()
	feedback_label.text = "You have already finished this quiz!"
	feedback_label.modulate = Color(0, 0.8, 1)
	feedback_label.visible = true
	next_button.hide()

	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/FarmLevels.tscn")

func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/FarmLevels.tscn")

func _play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func _play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()
