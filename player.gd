extends CharacterBody2D
@export var speed := 100
var last_direction := "down"

func _physics_process(_delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	direction = direction.normalized()

	var tilemap = get_parent().get_node("TileMapLayer")
	var next_position = global_position + direction * speed * _delta

	# Size of your collision rectangle (adjust if different)
	var half_extent = Vector2(16, 16)  # For a 32x32 box; change as needed

	var offsets = [
		Vector2(0, 0),                        # center
		Vector2(-half_extent.x, -half_extent.y),  # top-left
		Vector2(half_extent.x, -half_extent.y),   # top-right
		Vector2(-half_extent.x, half_extent.y),   # bottom-left
		Vector2(half_extent.x, half_extent.y)     # bottom-right
	]

	var can_move = true
	for offset in offsets:
		var check_pos = next_position + offset
		var local_pos = tilemap.to_local(check_pos)
		var cell = tilemap.local_to_map(local_pos)
		var cell_data = tilemap.get_cell_tile_data(cell)
		if not (cell_data and cell_data.get_terrain() == 0):
			can_move = false
			break

	if direction != Vector2.ZERO and can_move:
		velocity = direction * speed
		move_and_slide()
		# Play walk animation based on direction
		if direction.x > 0:
			$AnimatedSprite2D.play("walk_right")
			last_direction = "right"
		elif direction.x < 0:
			$AnimatedSprite2D.play("walk_left")
			last_direction = "left"
		elif direction.y > 0:
			$AnimatedSprite2D.play("walk_down")
			last_direction = "down"
		elif direction.y < 0:
			$AnimatedSprite2D.play("walk_up")
			last_direction = "up"
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle_" + last_direction)
