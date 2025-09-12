extends Control

var current_display_index = 0  # Which avatar we're currently viewing

@onready var avatar_display = $PauseCanvas/AvatarSelectionPanel/CurrentAvatarDisplay
@onready var left_button = $PauseCanvas/AvatarSelectionPanel/Left
@onready var right_button = $PauseCanvas/AvatarSelectionPanel/Right
@onready var avatar_name_label = $PauseCanvas/AvatarSelectionPanel/AvatarNameLabel
@onready var status_label = $PauseCanvas/AvatarSelectionPanel/Status
@onready var select_button = $PauseCanvas/AvatarSelectionPanel/SelectButton

func _ready():
	if not left_button.pressed.is_connected(_on_left_button_pressed):
		left_button.pressed.connect(_on_left_button_pressed)
	if not right_button.pressed.is_connected(_on_right_button_pressed):
		right_button.pressed.connect(_on_right_button_pressed)
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
	current_display_index = AvatarManager.current_avatar_index
	update_avatar_display()

func update_avatar_display():
	var avatar_data = AvatarManager.get_avatar(current_display_index)
	if avatar_data:
		var sprite_frames = load(avatar_data["sprite_frames_path"])
		avatar_display.sprite_frames = sprite_frames
		avatar_display.play("idle_down")
		avatar_name_label.text = avatar_data["name"]
		if avatar_data["unlocked"]:
			status_label.text = "UNLOCKED"
			status_label.modulate = Color.GREEN
			avatar_display.modulate = Color.WHITE
			select_button.disabled = false
		else:
			status_label.text = "LOCKED"
			status_label.modulate = Color.RED
			avatar_display.modulate = Color.GRAY
			select_button.disabled = true
		left_button.disabled = (current_display_index <= 0)
		right_button.disabled = (current_display_index >= AvatarManager.get_avatar_count() - 1)

func _on_left_button_pressed():
	if current_display_index > 0:
		current_display_index -= 1
		update_avatar_display()

func _on_right_button_pressed():
	if current_display_index < AvatarManager.get_avatar_count() - 1:
		current_display_index += 1
		update_avatar_display()

func _on_select_button_pressed():
	var avatar_data = AvatarManager.get_avatar(current_display_index)
	if avatar_data and avatar_data["unlocked"]:
		if AvatarManager.change_avatar(current_display_index):
			print("Selected avatar: ", avatar_data["name"])
		else:
			print("Failed to change avatar")
	else:
		print("Avatar is locked!")
