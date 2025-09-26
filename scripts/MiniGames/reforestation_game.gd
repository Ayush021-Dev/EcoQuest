extends Node2D
@onready var area = $Area2D
@onready var interact_label = $InteractLabel
@onready var reforestation_tilemap_layer = $reforestationGame
@onready var after_game_tilemap_layer = $afterGame
var can_interact = false
var player = null
@export var glow_duration: float = 1.0

func _ready():
	interact_label.hide()
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		var saved_pos = AvatarManager.get_player_position(get_tree().current_scene.name)
		if saved_pos != Vector2.ZERO:
			player.position = saved_pos
	else:
		print("Warning: No player found in Player group")
	check_completion()

func _process(_delta):
	if interact_label.visible and player:
		interact_label.global_position = player.global_position + Vector2(-140, -70)

func _on_area_body_entered(body):
	if body == player and not after_game_tilemap_layer.visible:
		can_interact = true
		_set_brightness(1.5)
		interact_label.show()

func _on_area_body_exited(body):
	if body == player:
		can_interact = false
		_set_brightness(1.0)
		interact_label.hide()

func _set_brightness(value: float):
	var material = reforestation_tilemap_layer.material
	if material and material is ShaderMaterial:
		material.set_shader_parameter("brightness", value)

func _input(event):
	if can_interact and event.is_action_pressed("interact"):
		if player != null:
			AvatarManager.save_player_position(get_tree().current_scene.name, player.position)
		get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/ReforestationLevels.tscn")

func check_completion():
	if all_levels_completed_and_locked():
		finish_reforestation()

func all_levels_completed_and_locked() -> bool:
	var all_completed = true
	var level_ids = [
		"reforestation_level1",
		"reforestation_level2",
		"reforestation_level3",
		"reforestation_level4"
	]
	for id in level_ids:
		if not LevelCompletionManager.is_level_completed(id):
			all_completed = false
			break
	return all_completed

func finish_reforestation():
	reforestation_tilemap_layer.visible = false
	after_game_tilemap_layer.visible = true
	_disable_interaction()
	_set_aftergame_brightness(2.0)
	await get_tree().create_timer(glow_duration).timeout
	_set_aftergame_brightness(1.0)
	
	# Notify the old man NPC to update its state
	notify_old_man_npc()

func notify_old_man_npc():
	# Find the old man NPC in the scene and update its state
	var old_man = get_node_or_null("../OldManNPC")  # Adjust path as needed
	if not old_man:
		# Try different possible paths
		old_man = get_parent().get_node_or_null("OldManNPC")
	if not old_man:
		# Search in the entire scene
		var nodes = get_tree().get_nodes_in_group("oldman_npc")  # Add the old man to this group
		if nodes.size() > 0:
			old_man = nodes[0]
	
	if old_man and old_man.has_method("update_npc_state"):
		old_man.update_npc_state()
		print("Old man NPC state updated!")
	else:
		print("Warning: Old man NPC not found or doesn't have update_npc_state method")

func _set_aftergame_brightness(value: float):
	var material = after_game_tilemap_layer.material
	if material and material is ShaderMaterial:
		material.set_shader_parameter("brightness", value)

func _disable_interaction():
	can_interact = false
	interact_label.hide()
	area.set_deferred("monitoring", false)
