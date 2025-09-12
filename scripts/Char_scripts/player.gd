extends CharacterBody2D

@export var speed := 230
var last_direction := "down"
var half_extent = Vector2(16, 16)
var center_offset = Vector2(0, 15)

@onready var walking_sound = $WalkingSound

func can_move_to(dir: Vector2, delta: float) -> bool:
	if dir == Vector2.ZERO:
		return false
	var tilemap = get_parent().get_node("Roads")
	var next_pos = global_position + dir * speed * delta
	for offset in [
		Vector2(0, 0),
		Vector2(-half_extent.x, -half_extent.y),
		Vector2(half_extent.x, -half_extent.y),
		Vector2(-half_extent.x, half_extent.y),
		Vector2(half_extent.x, half_extent.y)
	]:
		var check_pos = next_pos + offset + center_offset
		var local_pos = tilemap.to_local(check_pos)
		var cell = tilemap.local_to_map(local_pos)
		var cell_data = tilemap.get_cell_tile_data(cell)
		if not (cell_data and (cell_data.get_terrain()== 0 or cell_data.get_terrain()== 1)):
			return false

	return true

func _physics_process(delta):
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1

	input_dir = input_dir.normalized()
	var move_dir = Vector2.ZERO

	if can_move_to(input_dir, delta):
		move_dir = input_dir
	else:
		# Try axis separately (sliding)
		if input_dir.x != 0 and can_move_to(Vector2(input_dir.x, 0), delta):
			move_dir.x = input_dir.x
		if input_dir.y != 0 and can_move_to(Vector2(0, input_dir.y), delta):
			move_dir.y = input_dir.y

	if move_dir != Vector2.ZERO:
		velocity = move_dir * speed
		move_and_slide()

		# Play walking sound if not playing
		if not walking_sound.playing:
			walking_sound.play()

		# Animations
		if move_dir.x > 0:
			$AnimatedSprite2D.play("walk_right")
			last_direction = "right"
		elif move_dir.x < 0:
			$AnimatedSprite2D.play("walk_left")
			last_direction = "left"
		elif move_dir.y > 0:
			$AnimatedSprite2D.play("walk_down")
			last_direction = "down"
		elif move_dir.y < 0:
			$AnimatedSprite2D.play("walk_up")
			last_direction = "up"
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle_" + last_direction)

		# Stop walking sound when idle
		if walking_sound.playing:
			walking_sound.stop()
