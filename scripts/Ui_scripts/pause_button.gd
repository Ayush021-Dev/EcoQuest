extends CanvasLayer

@onready var pause_button = $Control/PauseButton
@onready var pause_canvas = $Control/PauseCanvas  # TextureRect
@onready var resume_button = $Control/PauseCanvas/ResumeButton
@onready var main_menu_button = $Control/PauseCanvas/MainMenuButton

@onready var pause_click_sound = $Control/PauseButton/ClickSound
@onready var resume_click_sound = $Control/PauseCanvas/ResumeButton/ClickSound
@onready var main_menu_click_sound = $Control/PauseCanvas/MainMenuButton/ClickSound

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS

	pause_canvas.visible = false

	# Connect pause button signals
	pause_button.pressed.connect(_on_pause_pressed)
	pause_button.mouse_entered.connect(_on_pause_button_mouse_entered)
	pause_button.mouse_exited.connect(_on_pause_button_mouse_exited)

	# Connect resume button signals
	resume_button.pressed.connect(_on_resume_pressed)
	resume_button.mouse_entered.connect(_on_resume_button_mouse_entered)
	resume_button.mouse_exited.connect(_on_resume_button_mouse_exited)

	# Connect main menu button signals
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	main_menu_button.mouse_entered.connect(_on_main_menu_button_mouse_entered)
	main_menu_button.mouse_exited.connect(_on_main_menu_button_mouse_exited)

	pause_button.visible = true

# Pause button hover handlers
func _on_pause_button_mouse_entered():
	pause_button.modulate = Color(0.6, 0.6, 0.6)

func _on_pause_button_mouse_exited():
	pause_button.modulate = Color(1, 1, 1)

# Resume button hover handlers
func _on_resume_button_mouse_entered():
	resume_button.modulate = Color(0.6, 0.6, 0.6)

func _on_resume_button_mouse_exited():
	resume_button.modulate = Color(1, 1, 1)

# Main menu button hover handlers
func _on_main_menu_button_mouse_entered():
	main_menu_button.modulate = Color(0.6, 0.6, 0.6)

func _on_main_menu_button_mouse_exited():
	main_menu_button.modulate = Color(1, 1, 1)

# Button pressed handlers with click sounds
func _on_pause_pressed():
	if pause_click_sound:
		pause_click_sound.play()
	pause_canvas.visible = true
	get_tree().paused = true

func _on_resume_pressed():
	if resume_click_sound:
		resume_click_sound.play()
	print("Resume button pressed!")
	pause_canvas.visible = false
	get_tree().paused = false

func _on_main_menu_pressed():
	if main_menu_click_sound:
		main_menu_click_sound.play()
	print("Main menu button pressed!")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI_Scene/start.tscn")
