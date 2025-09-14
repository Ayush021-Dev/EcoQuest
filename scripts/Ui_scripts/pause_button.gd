extends CanvasLayer

@onready var pause_button = $Control/PauseButton
@onready var pause_canvas = $Control/PauseCanvas  # TextureRect
@onready var resume_button = $Control/PauseCanvas/ResumeButton
@onready var main_menu_button = $Control/PauseCanvas/MainMenuButton

signal game_paused
signal game_resumed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_canvas.visible = false
	
	pause_button.pressed.connect(_on_pause_pressed)
	pause_button.mouse_entered.connect(_on_pause_button_mouse_entered)
	pause_button.mouse_exited.connect(_on_pause_button_mouse_exited)

	resume_button.pressed.connect(_on_resume_pressed)
	resume_button.mouse_entered.connect(_on_resume_button_mouse_entered)
	resume_button.mouse_exited.connect(_on_resume_button_mouse_exited)

	main_menu_button.pressed.connect(_on_main_menu_pressed)
	main_menu_button.mouse_entered.connect(_on_main_menu_button_mouse_entered)
	main_menu_button.mouse_exited.connect(_on_main_menu_button_mouse_exited)

	pause_button.visible = true

func _on_pause_button_mouse_entered():
	pause_button.modulate = Color(0.6, 0.6, 0.6)

func _on_pause_button_mouse_exited():
	pause_button.modulate = Color(1, 1, 1)

func _on_resume_button_mouse_entered():
	resume_button.modulate = Color(0.6, 0.6, 0.6)

func _on_resume_button_mouse_exited():
	resume_button.modulate = Color(1, 1, 1)

func _on_main_menu_button_mouse_entered():
	main_menu_button.modulate = Color(0.6, 0.6, 0.6)

func _on_main_menu_button_mouse_exited():
	main_menu_button.modulate = Color(1, 1, 1)

func _on_pause_pressed():
	AvatarManager.play_pause_click()
	if pause_canvas.visible:
		pause_canvas.visible = false
		get_tree().paused = false
		emit_signal("game_resumed")
	else:
		pause_canvas.visible = true
		get_tree().paused = true
		emit_signal("game_paused")

func _on_resume_pressed():
	AvatarManager.play_resume_click()
	pause_canvas.visible = false
	get_tree().paused = false
	emit_signal("game_resumed")

func _on_main_menu_pressed():
	AvatarManager.play_main_menu_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI_Scene/start.tscn")
