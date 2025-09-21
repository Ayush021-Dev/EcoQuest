extends Area2D

@export var is_harmful = false
@export var speed = 200
var direction = Vector2.ZERO
@export var fixed_y = 300

@export var main: Node  # Reference to main node (ReforestationLevel1)

var collided = false  # To prevent multiple collision triggers

func _ready():
	$Insect.play("left")  # AnimatedSprite2D node named "Insect"
	$Insect.scale = Vector2(2, 2)
	connect("area_entered", Callable(self, "_on_area_entered"))



func _process(delta):
	position.x += direction.x * speed * delta
	position.y = fixed_y
	
	# Free when out of screen on left side
	if position.x < -100:
		queue_free()

func _on_area_entered(area):
	print("Collided with area:", area.name)
	if collided:
		return
	collided = true
	
	if area.name == "TreeArea":
		if is_harmful:
			
			if main:
				main.reduce_tree_health(10)
		else:
			
			if main:
				main.reduce_tree_health(-5)
		queue_free()

@warning_ignore("unused_parameter")
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if is_harmful:
			if main:
				main.reduce_tree_health(-3)
				main.on_insect_killed("beetles")  # ADD THIS LINE
		else:
			if main:
				main.reduce_tree_health(10)
				main.on_insect_killed("beetles")  # ADD THIS LINE
		start_drop_animation()

func start_drop_animation():
	# Stop insect movement during drop
	speed = 0
	set_process(false)

	var tween = create_tween()
	
	# Animate vertical position to fall down (e.g., y = 800) over 1 second
	tween.tween_property(self, "position:y", 800, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Fade out AnimatedSprite2D named 'Insect' alpha over 1 second
	tween.tween_property($Insect, "modulate:a", 0, 1.0)
	
	# When animation finishes, free the insect
	tween.connect("finished", Callable(self, "_on_drop_animation_finished"))

func _on_drop_animation_finished():
	queue_free()
