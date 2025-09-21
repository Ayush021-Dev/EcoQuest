extends Node2D

@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var instructions_panel = $Panel  # Add the instructions Panel node

var questions = [
  {
	"q": "What is the main purpose of conserving natural water bodies?",
	"opts": ["Drinking water security", "Urban expansion", "Industrial waste disposal", "Deforestation"],
	"correct": 0,
	"feedback": [
	  "Correct! Conservation ensures safe drinking water.", 
	  "No, that threatens water bodies.", 
	  "No, that pollutes water.", 
	  "No, that reduces rainfall recharge."
	]
  },
  {
	"q": "Which process helps replenish groundwater through lakes and ponds?",
	"opts": ["Infiltration", "Evaporation", "Condensation", "Erosion"],
	"correct": 0,
	"feedback": [
	  "Correct! Infiltration recharges groundwater.", 
	  "No, evaporation removes water.", 
	  "No, condensation forms clouds.", 
	  "No, erosion degrades land."
	]
  },
  {
	"q": "Which Indian river is known as the lifeline of Madhya Pradesh?",
	"opts": ["Narmada", "Ganga", "Yamuna", "Brahmaputra"],
	"correct": 0,
	"feedback": [
	  "Correct! Narmada is called the lifeline of MP.", 
	  "No, that’s for North India.", 
	  "No, that flows through Delhi.", 
	  "No, that flows in the northeast."
	]
  },
  {
	"q": "What is the main threat to freshwater lakes worldwide?",
	"opts": ["Plastic pollution", "Salinity increase", "Overfishing", "Urbanization"],
	"correct": 0,
	"feedback": [
	  "Correct! Plastic pollution is the top threat.", 
	  "No, salinity affects oceans more.", 
	  "No, overfishing impacts rivers and seas.", 
	  "No, urbanization is indirect but not the primary cause."
	]
  },
  {
	"q": "Which water body is the largest freshwater lake in the world by volume?",
	"opts": ["Lake Victoria", "Lake Superior", "Lake Baikal", "Caspian Sea"],
	"correct": 2,
	"feedback": [
	  "No, that’s Africa’s largest by area.", 
	  "No, that’s North America’s largest.", 
	  "Correct! Lake Baikal holds the most freshwater.", 
	  "No, Caspian is a saltwater lake."
	]
  },
  {
	"q": "What practice best prevents eutrophication in lakes?",
	"opts": ["Reducing fertilizer use", "Increasing sewage discharge", "Building concrete walls", "Adding fish farms"],
	"correct": 0,
	"feedback": [
	  "Correct! Reducing fertilizer prevents nutrient overload.", 
	  "No, sewage worsens it.", 
	  "No, walls don’t stop nutrients.", 
	  "No, fish farms may add waste."
	]
  },
  {
	"q": "Which Indian initiative focuses on cleaning and conserving the Ganga river?",
	"opts": ["Namami Gange", "Swachh Bharat", "Jal Jeevan Mission", "Smart Cities Mission"],
	"correct": 0,
	"feedback": [
	  "Correct! Namami Gange is for river Ganga.", 
	  "No, that’s about sanitation.", 
	  "No, that’s about rural water supply.", 
	  "No, that’s for cities."
	]
  },
  {
	"q": "What is the main ecological role of wetlands?",
	"opts": ["Natural water filters", "Industrial dumping grounds", "Dry land creators", "Road expansion areas"],
	"correct": 0,
	"feedback": [
	  "Correct! Wetlands filter pollutants and recharge water.", 
	  "No, dumping destroys wetlands.", 
	  "No, wetlands are not for drying land.", 
	  "No, roads threaten wetlands."
	]
  },
  {
	"q": "Which gas is reduced when water bodies are conserved and wetlands restored?",
	"opts": ["Carbon dioxide", "Oxygen", "Hydrogen", "Helium"],
	"correct": 0,
	"feedback": [
	  "Correct! Wetlands capture carbon dioxide.", 
	  "No, oxygen is released.", 
	  "No, hydrogen is irrelevant here.", 
	  "No, helium is not related."
	]
  },
  {
	"q": "Which Indian lake is famous for its floating islands called 'phumdis'?",
	"opts": ["Dal Lake", "Chilika Lake", "Loktak Lake", "Sambhar Lake"],
	"correct": 2,
	"feedback": [
	  "No, that’s in Kashmir.", 
	  "No, that’s in Odisha.", 
	  "Correct! Loktak Lake in Manipur has phumdis.", 
	  "No, Sambhar is a salt lake."
	]
  },
  {
	"q": "Which action directly conserves natural rivers?",
	"opts": ["Riverbank plantation", "Sand mining", "Dam construction without planning", "Plastic dumping"],
	"correct": 0,
	"feedback": [
	  "Correct! Planting trees stabilizes riverbanks.", 
	  "No, sand mining erodes rivers.", 
	  "No, unplanned dams harm ecosystems.", 
	  "No, dumping pollutes water."
	]
  },
  {
	"q": "Which global event raises awareness about water conservation?",
	"opts": ["World Water Day", "Earth Hour", "Ozone Day", "World Food Day"],
	"correct": 0,
	"feedback": [
	  "Correct! World Water Day is dedicated to water conservation.", 
	  "No, that’s about energy saving.", 
	  "No, that’s about ozone.", 
	  "No, that’s about food security."
	]
  },
  {
	"q": "Which factor worsens the shrinking of natural lakes?",
	"opts": ["Excessive groundwater pumping", "Rainwater harvesting", "Eco-tourism", "Organic farming"],
	"correct": 0,
	"feedback": [
	  "Correct! Over-pumping dries up lakes.", 
	  "No, harvesting helps conserve water.", 
	  "No, eco-tourism supports conservation.", 
	  "No, organic farming prevents pollution."
	]
  },
  {
	"q": "Which conservation method is effective for rain-fed ponds?",
	"opts": ["Desilting", "Overfishing", "Plastic lining", "Chemical spraying"],
	"correct": 0,
	"feedback": [
	  "Correct! Desilting restores pond depth.", 
	  "No, overfishing harms ecology.", 
	  "No, plastic pollutes ponds.", 
	  "No, chemicals destroy water life."
	]
  },
  {
	"q": "Which UN goal emphasizes clean water and sanitation?",
	"opts": ["SDG 6", "SDG 12", "SDG 4", "SDG 3"],
	"correct": 0,
	"feedback": [
	  "Correct! SDG 6 focuses on clean water and sanitation.", 
	  "No, SDG 12 is about consumption.", 
	  "No, SDG 4 is about education.", 
	  "No, SDG 3 is about health."
	]
  }
]
var current = 0
@onready var close_button = $CloseButton
@onready var question_label = $Question
var buttons = []
var feedback_label
var next_button
var level_id: String = "lake_level4"  # Added level id

func _ready():
	buttons = [
		$Question.get_node("1"),
		$Question.get_node("2"),
		$Question.get_node("3"),
		$Question.get_node("4")
	]
	feedback_label = $Question.get_node("Feedback")
	next_button = $Question.get_node("Next")

	# Disable quiz UI until start
	for b in buttons:
		b.disabled = true
		b.visible = false
	next_button.disabled = true
	next_button.visible = false
	
	# Connect signals
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
		button.pressed.connect(func(btn=button):
			var idx = buttons.find(btn)
			_on_option_pressed(idx)
		)
		button.mouse_entered.connect(func(_btn=button):
			_play_hover_sound()
		)
	
	# Show instructions panel visible initially
	instructions_panel.visible = true

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		instructions_panel.hide()
		start_quiz()

func start_quiz():
	for b in buttons:
		b.disabled = false
		b.visible = true
	next_button.disabled = false
	next_button.visible = false
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
	# Calculate final quiz bonus or penalties
	calculate_final_quiz_score()

	# Mark this level as completed
	LevelCompletionManager.mark_level_completed(level_id)

	question_label.text = "Quiz finished!"
	for b in buttons:
		b.hide()
	feedback_label.hide()
	next_button.hide()

func calculate_final_quiz_score():
	# Add scoring or footprint reduction logic here if needed
	pass
func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func _play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func _play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()
