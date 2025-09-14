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
@onready var audio_player := $CoinSound

signal coin_collected(value: int)

func _ready():
	original_position = global_position
	visible = true
	modulate = Color.WHITE
	scale = Vector2(1, 1)
	freeze = true

	if area:
		area.input_event.connect(_on_area_input_event)
	else:
		print("ERROR: Area2D not found!")

	setup_collision_shapes()

	if animated_sprite:
		animated_sprite.play("Spin2")
	else:
		print("ERROR: AnimatedSprite2D not found!")

	start_float_animation()
	await get_tree().create_timer(collection_delay).timeout
	can_be_collected = true
	print("Coin can now be collected")

func setup_collision_shapes():
	if collision_shape:
		if not collision_shape.shape:
			var area_shape = CircleShape2D.new()
			area_shape.radius = 16
			collision_shape.shape = area_shape
		print("Area collision shape set up")
	else:
		print("ERROR: Area CollisionShape2D not found!")

func start_float_animation():
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(self, "global_position:y",
		original_position.y - float_height, float_duration)
	tween.tween_property(self, "global_position:y",
		original_position.y, float_duration)

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_be_collected and not is_collected:
			print("Coin clicked - collecting!")
			collect_coin()

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

	coin_collected.emit(coin_value)
	animate_collection()

func play_collection_sound():
	audio_player.play()

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

	# Wait for the audio to finish before freeing
	if audio_player.playing:
		await audio_player.finished

	queue_free()

func set_coin_value(value: int):
	coin_value = value
	print("Coin value set to: ", value)
