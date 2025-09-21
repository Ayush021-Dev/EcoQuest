extends CanvasLayer

var footprint_label: Label
var footprint_container: Control

func _ready():
	# Set this CanvasLayer to be on top of everything (same layer as coins)
	layer = 100
	
	# Create the carbon footprint display
	create_footprint_display()
	
	# Connect to CarbonFootprintManager signals
	if CarbonFootprintManager.footprint_changed.is_connected(_on_footprint_changed):
		CarbonFootprintManager.footprint_changed.disconnect(_on_footprint_changed)
	CarbonFootprintManager.footprint_changed.connect(_on_footprint_changed)
	
	# Initial display
	update_footprint_display()

func create_footprint_display():
	# Create main container
	footprint_container = Control.new()
	footprint_container.name = "FootprintContainer"
	footprint_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	
	# Get screen width to center horizontally
	var screen_size = get_viewport().get_visible_rect().size
	footprint_container.position = Vector2((screen_size.x / 2) - 90, 0)  # Center it in top-middle
	add_child(footprint_container)
	
	# Use set_deferred to avoid the warning - made wider to fit the text
	footprint_container.set_deferred("size", Vector2(180, 40))
	
	# Create background (same as coins)
	var background = TextureRect.new()
	background.texture = load("res://assets/items/chessboard2.png")  # Same as coins
	background.expand = true
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footprint_container.add_child(background)
	
	# Set background size after adding to parent - made wider
	background.set_deferred("size", Vector2(180, 40))
	
	# Create footprint label with emojis - reduced font size to fit better
	footprint_label = Label.new()
	footprint_label.text = "Carbon 👣: 1000"
	footprint_label.add_theme_font_size_override("font_size", 16)
	footprint_label.add_theme_color_override("font_color", Color.WHITE)
	footprint_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footprint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footprint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footprint_container.add_child(footprint_label)

func update_footprint_display():
	if footprint_label:
		var current_footprint = CarbonFootprintManager.get_footprint()
		footprint_label.text = "Carbon 👣: " + str(current_footprint)
		
		# Update color based on footprint level
		var footprint_color = CarbonFootprintManager.get_footprint_color()
		footprint_label.add_theme_color_override("font_color", footprint_color)

func _on_footprint_changed(footprint_difference: int):
	update_footprint_display()
	animate_footprint_change(footprint_difference)
	
	# Show floating text for the footprint change
	show_floating_footprint(footprint_difference)

func animate_footprint_change(footprint_difference: int):
	if footprint_container:
		var tween = create_tween()
		tween.tween_property(footprint_container, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(footprint_container, "scale", Vector2(1.0, 1.0), 0.1)
		
		# Flash effect based on whether footprint increased or decreased
		var flash_tween = create_tween()
		if footprint_difference < 0:  # Footprint reduced (good)
			flash_tween.tween_property(footprint_label, "modulate", Color.GREEN, 0.1)
		else:  # Footprint increased (bad)
			flash_tween.tween_property(footprint_label, "modulate", Color.RED, 0.1)
		
		flash_tween.tween_property(footprint_label, "modulate", Color.WHITE, 0.2)

func show_floating_footprint(amount: int):
	# Create floating label
	var floating_label = Label.new()
	
	# Format text based on positive/negative change
	if amount > 0:
		floating_label.text = "+" + str(amount)  # Increased footprint (bad)
		floating_label.add_theme_color_override("font_color", Color.RED)
	else:
		floating_label.text = str(amount)  # Decreased footprint (good) - already has minus sign
		floating_label.add_theme_color_override("font_color", Color.GREEN)
	
	floating_label.add_theme_font_size_override("font_size", 24)
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position it below the footprint display
	floating_label.position = Vector2(
		footprint_container.position.x + 20,  # Center it under the footprint display
		footprint_container.position.y + 50   # Below the footprint display
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

func show_footprint_display():
	if footprint_container:
		footprint_container.visible = true

func hide_footprint_display():
	if footprint_container:
		footprint_container.visible = false

func set_footprint_display_visibility(_is_visible: bool):
	if footprint_container:
		footprint_container.visible = _is_visible

# Get current footprint status message for tooltips or info
func get_status_message() -> String:
	var status = CarbonFootprintManager.get_footprint_status()
	match status:
		"excellent":
			return "Excellent! You're an eco-champion! 🌱"
		"average":
			return "Not bad, but room for improvement! 🌿"
		"high":
			return "Consider making eco-friendly choices! 🌍"
		_:
			return ""
