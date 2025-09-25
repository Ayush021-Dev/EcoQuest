extends AnimatedSprite2D

var speed = 100        # Movement speed in pixels/second
var direction = 1      # 1 means moving right, -1 means left

func _process(delta):
	position.x += speed * direction * delta

	# Change direction if fish reaches scene edges (adjust these limits)
	if position.x > 1024:
		direction = -1
		flip_h = false # Flip sprite horizontally to face left
	elif position.x < 50:
		direction = 1
		flip_h = true # Face right
