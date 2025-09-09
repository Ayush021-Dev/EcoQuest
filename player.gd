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

	# Reference the TileMapLayer node
	var tilemap = get_parent().get_node("TileMapLayer")
	var next_position = global_position + direction * speed * _delta
	var local_pos = tilemap.to_local(next_position)
	var cell = tilemap.local_to_map(local_pos)
	var cell_data = tilemap.get_cell_tile_data(cell)
	var can_move = false

	if cell_data:
		var terrain_info = cell_data.get_terrain()
		if terrain_info == 0:  # 0 = Terrain 0, as set up in your tileset
			can_move = true


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
