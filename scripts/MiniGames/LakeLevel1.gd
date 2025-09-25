extends Node2D

@export var garbage_scene: PackedScene = preload("res://scenes/Garbage.tscn")
@export var spawn_area: Rect2 = Rect2(165, 150, 800, 400)  # Adjust spawn area to your map

@export var move_speed = 200.0
@export var down_speed = 300.0
@export var up_speed = 300.0

@export var gripper_left_limit: float = 85.0
@export var gripper_right_limit: float = 1020.0
@export var gripper_top_y: float = 60.0
@export var gripper_bottom_y: float = 625.0

@onready var gripper = $Gripper
@onready var garbage_container = $GarbageContainer
@onready var dustbin_area = $DustbinArea

var direction = 1
var is_moving = true
var is_down = false
var is_up = false
var grabbed_garbage = null

func _ready():
	gripper.position.x = gripper_left_limit
	_create_gripper_visual()
	_spawn_garbage_batch(5)

func _process(delta):
	
	if is_moving:
		_move_horizontal(delta)
	elif is_down:
		_move_down(delta)
	elif is_up:
		_move_up(delta)


func _move_horizontal(delta):
	gripper.position.x += direction * move_speed * delta
	if gripper.position.x > gripper_right_limit:
		gripper.position.x = gripper_right_limit
		direction = -1
	elif gripper.position.x < gripper_left_limit:
		gripper.position.x = gripper_left_limit
		direction = 1

func _move_down(delta):
	gripper.position.y += down_speed * delta
	if gripper.position.y > gripper_bottom_y:
		gripper.position.y = gripper_bottom_y
	_check_grab_garbage()
	if gripper.position.y >= gripper_bottom_y:
		is_down = false
		is_up = true

func _move_up(delta):
	gripper.position.y -= up_speed * delta
	if gripper.position.y < gripper_top_y:
		gripper.position.y = gripper_top_y
	if gripper.position.y <= gripper_top_y:
		is_up = false
		is_moving = true

func _check_grab_garbage():
	if grabbed_garbage:
		return
	for garbage in garbage_container.get_children():
		if _aabb_intersects(gripper, garbage):
			grabbed_garbage = garbage
			garbage_container.remove_child(garbage)
			gripper.add_child(garbage)
			grabbed_garbage.position = Vector2(0, 20)
			grabbed_garbage.scale = Vector2(1, 1)
			grabbed_garbage.rotation = 0
			grabbed_garbage.set_physics_process(false)
			print("Grabbed garbage:", grabbed_garbage.name)
			return

# Adjusted grab box, shifted slightly right to match claws visually
func _aabb_intersects(node_a, node_b) -> bool:
	var a_pos = node_a.global_position
	var b_pos = node_b.global_position
	var grab_offset = Vector2(10, 0)
	var a_rect = Rect2(a_pos + grab_offset - Vector2(10, 15), Vector2(20, 30))
	var b_rect = Rect2(b_pos - Vector2(15, 15), Vector2(30, 30))
	return a_rect.intersects(b_rect)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if is_moving:
			is_moving = false
			is_down = true
		elif grabbed_garbage:
			_drop_garbage()

func _drop_garbage():
	if dustbin_area.get_overlapping_bodies().has(grabbed_garbage) or dustbin_area.get_overlapping_areas().has(grabbed_garbage):
		print("Garbage dropped inside dustbin! Well done!")
		grabbed_garbage.queue_free()
	else:
		print("Dropped outside dustbin, try again.")
		if grabbed_garbage and grabbed_garbage.get_parent() == gripper:
			gripper.remove_child(grabbed_garbage)
			garbage_container.add_child(grabbed_garbage)
			grabbed_garbage.position = gripper.global_position + Vector2(0, 20)
			grabbed_garbage.set_physics_process(true)
	grabbed_garbage = null
	is_moving = true

func _create_gripper_visual():
	if gripper.get_child_count() == 0:
		var claw_left = ColorRect.new()
		claw_left.color = Color(1, 0.85, 0.2)
		claw_left.size = Vector2(10, 30)
		claw_left.position = Vector2(-15, 0)
		gripper.add_child(claw_left)
		
		var claw_right = ColorRect.new()
		claw_right.color = Color(1, 0.85, 0.2)
		claw_right.size = Vector2(10, 30)
		claw_right.position = Vector2(15, 0)
		gripper.add_child(claw_right)

# Debug draw the grab zone rectangle
func _draw():
	var grab_offset = Vector2(10, 0)
	var box_pos = grab_offset - Vector2(10, 15)
	var box_size = Vector2(20, 30)
	draw_rect(Rect2(box_pos, box_size), Color(1, 0, 0, 0.4), false)

func _spawn_garbage_batch(count):
	for i in range(count):
		_spawn_garbage()

func _spawn_garbage():
	var garbage_instance = garbage_scene.instantiate()
	var pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	garbage_instance.position = pos
	garbage_container.add_child(garbage_instance)
