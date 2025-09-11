extends CharacterBody2D

@onready var animated_sprite = $sheep
@onready var timer = $Timer

# Cow behavior states
enum CowState { WALKING, EATING, IDLE }
var current_state = CowState.WALKING

# Movement variables
var speed = 50.0
var current_waypoint_index = 0

# Direction tracking
enum Direction { DOWN, LEFT, RIGHT, UP }
var current_direction = Direction.DOWN

# Manual waypoints - ADD YOUR POINTS HERE
var waypoints = [
	Vector2(-492.0, 436.0),   # Point 1 - grass area
	Vector2(-492.0,671.0 ),   # Point 2 - grass area  
	Vector2(-77.0, 1027.0),   # Point 3 - grass area
	Vector2(-205.0, 1311.0),   # Point 4 - grass area
	#Vector2(750, 350),   # Point 5 - grass area
	#Vector2(450, 500),   # Point 6 - grass area
	# Add more waypoints as needed
]

func _ready():
	# Set up the timer
	timer.timeout.connect(_on_timer_timeout)
	
	# Start walking to first waypoint
	if waypoints.size() > 0:
		change_state(CowState.WALKING)
	else:
		print("No waypoints defined!")

func _physics_process(_delta):
	match current_state:
		CowState.WALKING:
			walk_to_current_waypoint(_delta)
		CowState.EATING:
			# Cow stays in place while eating
			velocity = Vector2.ZERO
		CowState.IDLE:
			# Cow pauses briefly
			velocity = Vector2.ZERO
	
	move_and_slide()

func walk_to_current_waypoint(_delta):
	if waypoints.size() == 0:
		return
		
	var target = waypoints[current_waypoint_index]
	var direction_vector = (target - global_position).normalized()
	velocity = direction_vector * speed
	
	# Update cow direction and animation
	update_direction(direction_vector)
	
	# Check if reached current waypoint
	if global_position.distance_to(target) < 30:
		# Arrived at waypoint, start eating
		change_state(CowState.EATING)

func update_direction(dir_vector: Vector2):
	var old_direction = current_direction
	
	# Determine primary direction based on movement vector
	if abs(dir_vector.x) > abs(dir_vector.y):
		# Moving more horizontally
		if dir_vector.x > 0:
			current_direction = Direction.RIGHT
		else:
			current_direction = Direction.LEFT
	else:
		# Moving more vertically
		if dir_vector.y > 0:
			current_direction = Direction.DOWN
		else:
			current_direction = Direction.UP
	
	# Update animation if direction changed
	if old_direction != current_direction and current_state == CowState.WALKING:
		play_current_animation()

func move_to_next_waypoint():
	# Move to next waypoint (loop back to start when reaching end)
	current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func change_state(new_state: CowState):
	current_state = new_state
	
	match current_state:
		CowState.WALKING:
			play_current_animation()
		CowState.EATING:
			play_eating_animation()
			# Random eating time between 2-5 seconds
			var eating_time = randf_range(2.0, 5.0)
			timer.wait_time = eating_time
			timer.start()
		CowState.IDLE:
			# Use first frame of current walk direction for idle
			play_idle_animation()
			# Short idle time
			timer.wait_time = randf_range(0.5, 1.5)
			timer.start()

func play_current_animation():
	match current_direction:
		Direction.DOWN:
			animated_sprite.play("walk_down")
		Direction.LEFT:
			animated_sprite.play("walk_left")
		Direction.RIGHT:
			animated_sprite.play("walk_right")
		Direction.UP:
			animated_sprite.play("walk_up")

func play_eating_animation():
	match current_direction:
		Direction.DOWN:
			animated_sprite.play("eat_down")
		Direction.LEFT:
			animated_sprite.play("eat_left")
		Direction.RIGHT:
			animated_sprite.play("eat_right")
		Direction.UP:
			animated_sprite.play("eat_up")

func play_idle_animation():
	# Play first frame of walk animation for idle pose
	play_current_animation()
	animated_sprite.pause()
	animated_sprite.frame = 0

func _on_timer_timeout():
	match current_state:
		CowState.EATING:
			# Finished eating, rest briefly then move to next waypoint
			change_state(CowState.IDLE)
		CowState.IDLE:
			# Finished resting, move to next waypoint
			move_to_next_waypoint()
			change_state(CowState.WALKING)
