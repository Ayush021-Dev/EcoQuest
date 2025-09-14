extends Control

var current_display_index = 0
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
	if not AvatarManager.coins_changed.is_connected(_on_coins_changed):
		AvatarManager.coins_changed.connect(_on_coins_changed)
	if not AvatarManager.avatar_changed.is_connected(_on_avatar_changed):
		AvatarManager.avatar_changed.connect(_on_avatar_changed)
	if not AvatarManager.avatar_unlocked.is_connected(_on_avatar_unlocked):
		AvatarManager.avatar_unlocked.connect(_on_avatar_unlocked)

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
			if current_display_index == AvatarManager.current_avatar_index:
				status_label.text = "SELECTED"
				status_label.modulate = Color.CYAN
				select_button.text = "SELECTED"
				select_button.disabled = true
			else:
				status_label.text = "UNLOCKED"
				status_label.modulate = Color.GREEN
				select_button.text = "SELECT"
				select_button.disabled = false
			avatar_display.modulate = Color.WHITE
		else:
			status_label.text = "LOCKED"
			status_label.modulate = Color.RED
			avatar_display.modulate = Color.GRAY
			select_button.text = "BUY (" + str(avatar_data["price"]) + ")"
			if AvatarManager.get_coins() >= avatar_data["price"]:
				select_button.disabled = false
				select_button.modulate = Color.WHITE
			else:
				select_button.disabled = true
				select_button.modulate = Color.GRAY

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
	AvatarManager.play_select_click()
	
	var avatar_data = AvatarManager.get_avatar(current_display_index)
	if not avatar_data:
		return

	if avatar_data["unlocked"]:
		if current_display_index != AvatarManager.current_avatar_index:
			if AvatarManager.change_avatar(current_display_index):
				update_avatar_display()
			else:
				show_message("Failed to select avatar", Color.RED)
	else:
		var price = avatar_data["price"]
		if AvatarManager.get_coins() >= price:
			if AvatarManager.buy_avatar(current_display_index):
				update_avatar_display()
			else:
				show_message("Purchase failed", Color.RED)
		else:
			var needed = price - AvatarManager.get_coins()
			show_message("Need " + str(needed) + " more coins", Color.ORANGE)

func show_message(text: String, color: Color = Color.WHITE):
	var message_label = Label.new()
	message_label.text = text
	message_label.modulate = color
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var panel = $PauseCanvas/AvatarSelectionPanel
	panel.add_child(message_label)
	message_label.position = status_label.position + Vector2(0, -30)
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 2.0)
	await tween.finished
	message_label.queue_free()
	print(text)

func _on_coins_changed(_new_amount: int):
	update_avatar_display()

func _on_avatar_changed(_new_index: int):
	update_avatar_display()

func _on_avatar_unlocked(index):
	if index == current_display_index:
		AvatarManager.play_select_unlock()
