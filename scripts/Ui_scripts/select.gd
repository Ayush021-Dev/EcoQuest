extends Control

var current_display_index = 0  # Which avatar we're currently viewing

@onready var avatar_display = $PauseCanvas/AvatarSelectionPanel/CurrentAvatarDisplay
@onready var left_button = $PauseCanvas/AvatarSelectionPanel/Left
@onready var right_button = $PauseCanvas/AvatarSelectionPanel/Right
@onready var avatar_name_label = $PauseCanvas/AvatarSelectionPanel/AvatarNameLabel
@onready var status_label = $PauseCanvas/AvatarSelectionPanel/Status
@onready var select_button = $PauseCanvas/AvatarSelectionPanel/SelectButton
@onready var coin_display = $PauseCanvas/AvatarSelectionPanel/CoinDisplay

func _ready():
	# Connect existing buttons
	if not left_button.pressed.is_connected(_on_left_button_pressed):
		left_button.pressed.connect(_on_left_button_pressed)
	if not right_button.pressed.is_connected(_on_right_button_pressed):
		right_button.pressed.connect(_on_right_button_pressed)
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
	
	# Connect to AvatarManager signals for real-time updates
	if not AvatarManager.coins_changed.is_connected(_on_coins_changed):
		AvatarManager.coins_changed.connect(_on_coins_changed)
	if not AvatarManager.avatar_changed.is_connected(_on_avatar_changed):
		AvatarManager.avatar_changed.connect(_on_avatar_changed)
	
	current_display_index = AvatarManager.current_avatar_index
	update_avatar_display()
	update_coin_display()

func update_avatar_display():
	var avatar_data = AvatarManager.get_avatar(current_display_index)
	if avatar_data:
		# Load and display avatar sprite
		var sprite_frames = load(avatar_data["sprite_frames_path"])
		avatar_display.sprite_frames = sprite_frames
		avatar_display.play("idle_down")
		
		# Update avatar name
		avatar_name_label.text = avatar_data["name"]
		
		# Update status and button based on avatar state
		if avatar_data["unlocked"]:
			if current_display_index == AvatarManager.current_avatar_index:
				# Currently selected avatar
				status_label.text = "SELECTED"
				status_label.modulate = Color.CYAN
				select_button.text = "SELECTED"
				select_button.disabled = true
			else:
				# Unlocked but not selected
				status_label.text = "UNLOCKED"
				status_label.modulate = Color.GREEN
				select_button.text = "SELECT"
				select_button.disabled = false
			
			avatar_display.modulate = Color.WHITE
		else:
			# Locked avatar - show price and buy option
			status_label.text = "LOCKED" 
			status_label.modulate = Color.RED
			avatar_display.modulate = Color.GRAY
			
			# Update button for buying
			select_button.text = "BUY (" + str(avatar_data["price"]) + ")"
			
			# Enable/disable buy button based on available coins
			if AvatarManager.get_coins() >= avatar_data["price"]:
				select_button.disabled = false
				select_button.modulate = Color.WHITE
			else:
				select_button.disabled = true
				select_button.modulate = Color.GRAY
		
		# Update navigation buttons
		left_button.disabled = (current_display_index <= 0)
		right_button.disabled = (current_display_index >= AvatarManager.get_avatar_count() - 1)

func update_coin_display():
	if coin_display:
		coin_display.text = "Coins: " + str(AvatarManager.get_coins())

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
	if not avatar_data:
		return
	
	if avatar_data["unlocked"]:
		# Select the avatar
		if current_display_index != AvatarManager.current_avatar_index:
			if AvatarManager.change_avatar(current_display_index):
				#show_message("Selected: " + avatar_data["name"], Color.GREEN)
				update_avatar_display()  # Refresh to show "SELECTED" state
			else:
				show_message("Failed to select avatar", Color.RED)
	else:
		# Try to buy the avatar
		var price = avatar_data["price"]
		if AvatarManager.get_coins() >= price:
			if AvatarManager.buy_avatar(current_display_index):
				#show_message("Purchased: " + avatar_data["name"], Color.GREEN)
				update_avatar_display()  # Refresh to show unlocked state
				update_coin_display()    # Update coin display
			else:
				show_message("Purchase failed", Color.RED)
		else:
			var needed = price - AvatarManager.get_coins()
			show_message("Need " + str(needed) + " more coins", Color.ORANGE)

func show_message(text: String, color: Color = Color.WHITE):
	# Create a temporary message that appears above the status label
	var message_label = Label.new()
	message_label.text = text
	message_label.modulate = color
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Position it above the status label
	var panel = $PauseCanvas/AvatarSelectionPanel
	panel.add_child(message_label)
	message_label.position = status_label.position + Vector2(0, -30)
	
	# Animate the message
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 2.0)
	await tween.finished
	message_label.queue_free()
	
	print(text)  # Also print to console

func _on_coins_changed(_new_amount: int):
	update_coin_display()
	update_avatar_display()  # Refresh to update buy button states

func _on_avatar_changed(_new_index: int):
	update_avatar_display()  # Refresh to update selection states
