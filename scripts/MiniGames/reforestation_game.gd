extends TileMap  # Attached to ReforestationController

@onready var area = $Area2D
@onready var interact_label = $InteractLabel
@onready var tilemap_layer = $reforestationGame  # TileMapLayer node

var can_interact = false
var player = null

func _ready():
	interact_label.hide()
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	player = get_tree().get_nodes_in_group("Player")[0]  # assuming player is in "Player" group

func _process(_delta):
	if interact_label.visible and player:
		# Position label above player's head in world coordinates
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
	@warning_ignore("shadowed_variable_base_class")
	var material = tilemap_layer.material
	if material and material is ShaderMaterial:
		material.set_shader_parameter("brightness", value)

func _input(event):
	if can_interact and event.is_action_pressed("interact"):
		get_tree().change_scene_to_file("res://path_to_minigame_scene.tscn")
