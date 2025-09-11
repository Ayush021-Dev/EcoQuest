extends CanvasLayer

@onready var pause_button = $Control/PauseButton
@onready var pause_canvas = $Control/PauseCanvas  # This is now a TextureRect
@onready var resume_button = $Control/PauseCanvas/ResumeButton
@onready var main_menu_button = $Control/PauseCanvas/MainMenuButton

func _ready():
	# Set process mode for all nodes that need to work when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initially hide the pause menu
	pause_canvas.visible = false
	
	# Connect button signals
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Make sure the pause button is always visible
	pause_button.visible = true

func _on_pause_pressed():
	# Show pause menu and pause the game
	pause_canvas.visible = true
	get_tree().paused = true

func _on_resume_pressed():
	print("Resume button pressed!")  # Debug line
	pause_canvas.visible = false
	get_tree().paused = false

func _on_main_menu_pressed():
	print("Main menu button pressed!")  # Debug line
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI_Scene/start.tscn")
