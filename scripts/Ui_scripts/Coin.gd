extends RigidBody2D

@export var coin_value: int = 100
@export var collection_delay: float = 0.5
@export var float_height: float = 20.0  # How high the coin floats up
@export var float_duration: float = 1.0  # How long the float animation takes

var can_be_collected: bool = false
var is_collected: bool = false
var original_position: Vector2

@onready var animated_sprite := $AnimatedSprite2D
@onready var area := $Area2D
@onready var collision_shape := $Area2D/CollisionShape2D
#@onready var value_label := $ValueLabel

signal coin_collected(value: int)

func _ready():
	
	original_position = global_position
	
	
	visible = true
	modulate = Color.WHITE
	scale = Vector2(1, 1)
	
	# Disable physics initially - we want to control the movement
	freeze = true
	
	# Connect area signals for mouse interaction
	if area:
		area.input_event.connect(_on_area_input_event)
		#area.mouse_entered.connect(_on_mouse_entered)
		#area.mouse_exited.connect(_on_mouse_exited)
		
	else:
		print("ERROR: Area2D not found!")
	
	# Set up collision shapes
	setup_collision_shapes()
	
	# Set up visual state
	if animated_sprite:
		animated_sprite.play("Spin")
		
	else:
		print("ERROR: AnimatedSprite2D not found!")
	
	#if value_label:
		#value_label.text = str(coin_value)
		#value_label.visible = false
		#print("ValueLabel set to: ", coin_value)
	#else:
		#print("WARNING: ValueLabel not found")
	
	# Start the float animation
	start_float_animation()
	
	# Start collection timer
	await get_tree().create_timer(collection_delay).timeout
	can_be_collected = true
	print("Coin can now be collected")

func setup_collision_shapes():
	# Set up area collision shape for mouse detection
	if collision_shape:
		if not collision_shape.shape:
			var area_shape = CircleShape2D.new()
			area_shape.radius = 16
			collision_shape.shape = area_shape
		print("Area collision shape set up")
	else:
		print("ERROR: Area CollisionShape2D not found!")

func start_float_animation():
	# Create a gentle floating animation
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	
	# Float up
	tween.tween_property(self, "global_position:y", 
		original_position.y - float_height, float_duration)
	tween.tween_property(self, "global_position:y", 
		original_position.y, float_duration)

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_be_collected and not is_collected:
			print("Coin clicked - collecting!")
			collect_coin()

#func _on_mouse_entered():
	#if can_be_collected and not is_collected:
		#print("Mouse entered coin area")
		#if animated_sprite:
			#animated_sprite.scale = Vector2(1.2, 1.2)
		#if value_label:
			#value_label.visible = true

#func _on_mouse_exited():
	#if not is_collected:
		#print("Mouse exited coin area")
		#if animated_sprite:
			#animated_sprite.scale = Vector2(1.0, 1.0)
		#if value_label:
			#value_label.visible = false

func collect_coin():
	if is_collected:
		return
	
	print("Collecting coin with value: ", coin_value)
	is_collected = true
	can_be_collected = false
	
	
	play_collection_sound()
	
	
	if AvatarManager and AvatarManager.has_method("add_coins"):
		AvatarManager.add_coins(coin_value)
		
	else:
		print("WARNING: AvatarManager not found or doesn't have add_coins method")
	
	# Emit signal
	coin_collected.emit(coin_value)
	
	# Animate coin disappearing
	animate_collection()

func play_collection_sound():
	$AudioStreamPlayer2D.play()

func animate_collection():
	
	var existing_tweens = get_tree().get_nodes_in_group("tween")
	for tween_node in existing_tweens:
		if is_instance_valid(tween_node) and tween_node.get_parent() == self:
			tween_node.kill()
	
	
	if area:
		area.set_deferred("monitoring", false)
	
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(2.0, 2.0), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "global_position:y", global_position.y - 50, 0.3)
	
	await tween.finished
	queue_free()

func set_coin_value(value: int):
	coin_value = value
	#if value_label:
		#value_label.text = str(coin_value)
	print("Coin value set to: ", value)
