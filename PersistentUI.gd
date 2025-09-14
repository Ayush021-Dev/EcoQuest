extends CanvasLayer

var coin_label: Label
var coin_container: Control

func _ready():
	# Set this CanvasLayer to be on top of everything
	layer = 100
	
	# Create the coin display
	create_coin_display()
	
	# Connect to AvatarManager signals
	if AvatarManager.coins_changed.is_connected(_on_coins_changed):
		AvatarManager.coins_changed.disconnect(_on_coins_changed)
	AvatarManager.coins_changed.connect(_on_coins_changed)
	
	# Initial display
	update_coin_display()

func create_coin_display():
	# Create main container
	coin_container = Control.new()
	coin_container.name = "CoinContainer"
	coin_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coin_container.position = Vector2(-140, 03)
	add_child(coin_container)
	
	# Use set_deferred to avoid the warning
	coin_container.set_deferred("size", Vector2(140, 40))
	
	# Create background (optional)
	var background = TextureRect.new()
	background.texture = load("res://assets/items/chessboard2.png")  # Adjust path as needed
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coin_container.add_child(background)
	
	# Set background size after adding to parent
	background.set_deferred("size", Vector2(140, 40))
	
	# Create coin label
	coin_label = Label.new()
	coin_label.text = "EcoCoins: 0"
	coin_label.add_theme_font_size_override("font_size", 18)
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	coin_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_container.add_child(coin_label)

func update_coin_display():
	if coin_label:
		coin_label.text = "EcoCoins: " + str(AvatarManager.get_coins())

func _on_coins_changed(coin_difference: int):
	update_coin_display()
	animate_coin_change()
	
	# Show floating text for the coin gain
	if coin_difference > 0:
		show_floating_coins(coin_difference)

func animate_coin_change():
	if coin_container:
		var tween = create_tween()
		tween.tween_property(coin_container, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(coin_container, "scale", Vector2(1.0, 1.0), 0.1)
		
		# Optional: Flash effect
		var flash_tween = create_tween()
		flash_tween.tween_property(coin_label, "modulate", Color.YELLOW, 0.1)
		flash_tween.tween_property(coin_label, "modulate", Color.WHITE, 0.2)

func show_floating_coins(amount: int):
	# Create floating label
	var floating_label = Label.new()
	floating_label.text = "+" + str(amount)
	floating_label.add_theme_font_size_override("font_size", 24)
	floating_label.add_theme_color_override("font_color", Color.GREEN)
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position it below the coin display
	floating_label.position = Vector2(
		coin_container.position.x + 20,  # Center it under the coin display
		coin_container.position.y + 50   # Below the coin display
	)
	floating_label.size = Vector2(100, 30)
	
	# Add to the scene
	add_child(floating_label)
	
	# Animate the floating text
	var tween = create_tween()
	
	# Move up and fade out
	tween.parallel().tween_property(floating_label, "position:y", 
		floating_label.position.y - 60, 1.5)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(floating_label, "scale", Vector2(1.2, 1.2), 0.3)
	
	# Remove the label when animation is done
	await tween.finished
	floating_label.queue_free()

func show_coin_display():
	if coin_container:
		coin_container.visible = true

func hide_coin_display():
	if coin_container:
		coin_container.visible = false

# Fixed function name to avoid shadowing warning
func set_coin_display_visibility(iss_visible: bool):
	if coin_container:
		coin_container.visible = iss_visible
