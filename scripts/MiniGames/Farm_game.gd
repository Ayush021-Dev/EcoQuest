extends Node2D  # Attached to FarmController

@onready var area = $Area2D
@onready var interact_label = $InteractLabel
@onready var tilemap_layer = $FarmGame  # TileMapLayer node for farm, replace with actual farm TileMapLayer node name

var can_interact = false
var player = null

func _ready():
	interact_label.hide()
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		print("Warning: No player found in Player group")

func _process(_delta):
	if interact_label.visible and player:
		# Position label above player's head in world coordinates for farm game
		interact_label.global_position = player.global_position + Vector2(-140, -70)

func _on_area_body_entered(body):
	if body == player:
		can_interact = true
		_set_brightness(1.5)
		interact_label.show()

func _on_area_body_exited(body):
	if body == player:
		can_interact = false
		_set_brightness(1.0)
		interact_label.hide()

func _set_brightness(value: float):
	var material = tilemap_layer.material
	if material and material is ShaderMaterial:
		material.set_shader_parameter("brightness", value)

func _input(event):
	if can_interact and event.is_action_pressed("interact"):
		# Save player position or state if needed before changing scene
		AvatarManager.entering_level()
		get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/FarmLevels.tscn")
