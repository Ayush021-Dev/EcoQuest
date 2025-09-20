extends Node2D
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
var questions = [
  {
	"q": "What is the main goal of reforestation?",
	"opts": ["Restoring lost forests", "Building cities", "Expanding farmland", "Creating dams"],
	"correct": 0,
	"feedback": [
	  "Correct! Reforestation restores lost forests.", 
	  "No, that's urbanization.", 
	  "No, that's deforestation.", 
	  "No, that's unrelated to forests."
	]
  },
  {
	"q": "Which process involves planting trees in areas that previously had no forest cover?",
	"opts": ["Reforestation", "Afforestation", "Deforestation", "Desertification"],
	"correct": 1,
	"feedback": [
	  "Not quite. That's replanting lost forests.", 
	  "Correct! Afforestation creates new forests.", 
	  "No, that's removing trees.", 
	  "No, that's land degradation."
	]
  },
  {
	"q": "Which gas do trees absorb most during photosynthesis, helping fight climate change?",
	"opts": ["Oxygen", "Carbon dioxide", "Nitrogen", "Methane"],
	"correct": 1,
	"feedback": [
	  "No, oxygen is released.", 
	  "Correct! Trees absorb carbon dioxide.", 
	  "No, nitrogen is absorbed from soil.", 
	  "No, methane is not absorbed."
	]
  },
  {
	"q": "Which tree-planting initiative is one of the largest in India?",
	"opts": ["Chipko Movement", "Green India Mission", "Save Soil", "Jal Shakti Abhiyan"],
	"correct": 1,
	"feedback": [
	  "No, that's a protest movement.", 
	  "Correct! The Green India Mission is a reforestation program.", 
	  "No, that's about soil conservation.", 
	  "No, that's focused on water."
	]
  },
  {
	"q": "Which country started the 'Great Green Wall' project to combat desertification?",
	"opts": ["India", "China", "Brazil", "African nations"],
	"correct": 3,
	"feedback": [
	  "No, not India.", 
	  "No, not China.", 
	  "No, not Brazil.", 
	  "Correct! African nations started it."
	]
  },
  {
	"q": "What is the main difference between reforestation and afforestation?",
	"opts": ["Same process", "Reforestation restores, afforestation creates", "One removes trees", "One cuts grass"],
	"correct": 1,
	"feedback": [
	  "No, they are not the same.", 
	  "Correct! Reforestation restores, afforestation creates.", 
	  "No, that's deforestation.", 
	  "No, irrelevant to forests."
	]
  },
  {
	"q": "Which Indian state holds the record for planting millions of trees in a single day?",
	"opts": ["Kerala", "Madhya Pradesh", "Uttar Pradesh", "Rajasthan"],
	"correct": 2,
	"feedback": [
	  "No, not Kerala.", 
	  "Close, but not Madhya Pradesh.", 
	  "Correct! Uttar Pradesh holds the record.", 
	  "No, not Rajasthan."
	]
  },
  {
	"q": "Which of the following is a benefit of reforestation?",
	"opts": ["Soil erosion control", "Higher pollution", "Less biodiversity", "More floods"],
	"correct": 0,
	"feedback": [
	  "Correct! Reforestation prevents soil erosion.", 
	  "No, it reduces pollution.", 
	  "No, it increases biodiversity.", 
	  "No, it reduces flood risk."
	]
  },
  {
	"q": "Which tree is often called the 'lungs of the planet'?",
	"opts": ["Neem", "Banyan", "Rainforest trees", "Pine"],
	"correct": 2,
	"feedback": [
	  "No, not Neem.", 
	  "No, not Banyan.", 
	  "Correct! Rainforests are called Earth's lungs.", 
	  "No, not Pine."
	]
  },
  {
	"q": "What does deforestation directly lead to?",
	"opts": ["Cleaner air", "Loss of biodiversity", "More rainfall", "Stronger soil"],
	"correct": 1,
	"feedback": [
	  "No, it increases pollution.", 
	  "Correct! It causes biodiversity loss.", 
	  "No, rainfall decreases.", 
	  "No, soil gets weaker."
	]
  },
  {
	"q": "Which global day promotes tree planting and forest awareness?",
	"opts": ["World Water Day", "Earth Day", "World Forestry Day", "Ozone Day"],
	"correct": 2,
	"feedback": [
	  "No, that’s about water.", 
	  "No, Earth Day is broader.", 
	  "Correct! World Forestry Day promotes trees.", 
	  "No, that’s about ozone."
	]
  },
  {
	"q": "Which region is most affected by desertification where afforestation is critical?",
	"opts": ["Amazon", "Sahara", "Alps", "Andes"],
	"correct": 1,
	"feedback": [
	  "No, Amazon has rainforests.", 
	  "Correct! Sahara region faces desertification.", 
	  "No, Alps are mountain ranges.", 
	  "No, Andes are mountains."
	]
  },
  {
	"q": "Which practice helps forests grow back naturally without human intervention?",
	"opts": ["Afforestation", "Deforestation", "Natural regeneration", "Urbanization"],
	"correct": 2,
	"feedback": [
	  "No, that's artificial planting.", 
	  "No, that destroys forests.", 
	  "Correct! Natural regeneration restores forests.", 
	  "No, that removes green cover."
	]
  },
  {
	"q": "Which greenhouse gas is reduced the most by large-scale afforestation?",
	"opts": ["Oxygen", "Carbon dioxide", "Sulfur dioxide", "Nitrous oxide"],
	"correct": 1,
	"feedback": [
	  "No, oxygen is released, not reduced.", 
	  "Correct! CO₂ is absorbed by trees.", 
	  "No, sulfur dioxide is not the main target.", 
	  "No, nitrous oxide reduction is indirect."
	]
  },
  {
	"q": "Which UN program promotes forest conservation and reforestation globally?",
	"opts": ["UNESCO Heritage", "UNEP REDD+", "WHO Green", "UNICEF Trees"],
	"correct": 1,
	"feedback": [
	  "No, that’s for heritage.", 
	  "Correct! UNEP REDD+ promotes reforestation.", 
	  "No, WHO focuses on health.", 
	  "No, UNICEF focuses on children."
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

	# Connect Next and Close buttons signals only once
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

	# Connect option buttons with press, and add hover effect with inline lambdas for only hovered button
	for button in buttons:
		if not button.pressed.is_connected(_play_click_sound):
			button.pressed.connect(_play_click_sound)
		button.pressed.connect(func(_btn=button):
			# Find index of this button
			var idx = buttons.find(_btn)
			_on_option_pressed(idx)
		)
		# Connect mouse_entered with inline lambda to darken only hovered button and play hover sound
		button.mouse_entered.connect(func(_btn=button):
	
			_play_hover_sound()
		)
		

	load_question()

func load_question():
	var q_data = questions[current]
	question_label.text = q_data["q"]
	for i in range(buttons.size()):
		buttons[i].get_node("Label").text = q_data["opts"][i]
		buttons[i].disabled = false
		buttons[i].visible = true
		buttons[i].modulate = Color(1, 1, 1)  # reset to normal
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
