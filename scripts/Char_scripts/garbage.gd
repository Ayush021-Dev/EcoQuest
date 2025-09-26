extends Node2D

signal garbage_hit_dustbin
signal garbage_missed_dustbin(garbage_node)

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var garbage_type: String = "cokezero"
var is_falling: bool = false
var fall_speed: float = 200.0
var ground_y: float = 500.0  # Adjust based on your level

func _ready():
	# Add to garbage group for easy reference
	add_to_group("garbage")
	
	# Set the initial animation
	if animated_sprite:
		set_garbage_type(garbage_type)
	
	# Since your scene structure doesn't have Area2D, we'll handle collision differently
	# The collision detection will be done by the gripper and dustbin area

func _process(delta):
	if is_falling:
		position.y += fall_speed * delta
		
		# Get the dustbin area and check if garbage position overlaps with it
		var level = get_tree().current_scene
		var dustbin_area = level.get_node_or_null("DustbinArea")
		
		if dustbin_area:
			print("Garbage falling at position: ", global_position)
			
			if dustbin_area.has_node("CollisionShape2D"):
				var collision_shape_2d = dustbin_area.get_node("CollisionShape2D")
				var shape = collision_shape_2d.shape
				var dustbin_global_pos = dustbin_area.global_position + collision_shape_2d.position
				
				print("Dustbin area position: ", dustbin_global_pos)
				
				if shape is RectangleShape2D:
					var rect = shape as RectangleShape2D
					var dustbin_rect = Rect2(
						dustbin_global_pos - rect.size / 2,
						rect.size
					)
					
					print("Dustbin rect: ", dustbin_rect)
					print("Checking if ", global_position, " is in ", dustbin_rect)
					
					# Check if garbage position is within dustbin area
					if dustbin_rect.has_point(global_position):
						print("HIT DUSTBIN!")
						# Hit the dustbin!
						is_falling = false
						garbage_hit_dustbin.emit()
						queue_free()
						return
		
		# Check if hit ground
		if position.y >= ground_y:
			print("Hit ground - missed dustbin")
			# Missed the dustbin
			is_falling = false
			garbage_missed_dustbin.emit(self)

func set_garbage_type(type: String):
	garbage_type = type
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(type):
			animated_sprite.play(type)
		else:
			print("Warning: Animation '" + type + "' not found in AnimatedSprite2D")

func set_collision_enabled(enabled: bool):
	if collision_shape:
		collision_shape.disabled = not enabled

func start_falling():
	is_falling = true
	set_collision_enabled(true)
