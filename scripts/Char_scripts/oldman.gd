extends CharacterBody2D

# Original dialogues for before completion
@export var initial_dialogues := [
	"Hi young fella, I am the guardian of this forest.",
	"This area was once a lush forest with plenty of life.",
	"But deforestation has taken its toll, harming the environment.",
	"You must play the games ahead to restore balance and regrow trees.",
	"Good luck! The future of this forest depends on you."
]

# New dialogues for after completion
@export var completion_dialogues := [
	"Incredible work, young guardian! You have shown true wisdom.",
	"Your brilliance and dedication have brought life back to this forest.",
	"The trees whisper songs of gratitude for your efforts.",
	"Your love for nature has restored the balance we desperately needed.",
	"Please accept these eco coins as a token of appreciation for your environmental heroism!"
]

# Position settings
@export var initial_position := Vector2(-159.0, 261.0)
@export var completion_position := Vector2(218.0, 386.0)
@export var coin_reward_value := 100  # Eco coins to give as reward

var current_dialogues: Array
var player_in_range: bool = false
var player_ref = null
var dialogue_index: int = 0
var dialogue_active: bool = false
var typing = false
var has_given_reward: bool = false

@onready var area := $Area2D
@onready var prompt_label := $TalkPrompt
@onready var dialogue_box := $TextureRect
@onready var dialogue_label := $TextureRect/Label
@onready var animated_sprite := $AnimatedSprite2D

# Preload coin scene
@export var coin_scene: PackedScene  # Assign this in the inspector

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	prompt_label.visible = false
	dialogue_box.visible = false
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()
	
	# Check completion status and set up accordingly
	check_and_setup_npc()

func check_and_setup_npc():
	if all_reforestation_levels_completed():
		setup_for_completion()
	else:
		setup_for_initial_state()

func all_reforestation_levels_completed() -> bool:
	var level_ids = [
		"reforestation_level1",
		"reforestation_level2", 
		"reforestation_level3",
		"reforestation_level4"
	]
	
	for id in level_ids:
		if not LevelCompletionManager.is_level_completed(id):
			return false
	return true

func setup_for_initial_state():
	current_dialogues = initial_dialogues
	global_position = initial_position

func setup_for_completion():
	current_dialogues = completion_dialogues
	global_position = completion_position

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body
		prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		prompt_label.visible = false
		if dialogue_active:
			end_dialogue()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialogue_active:
			start_dialogue()
		elif not typing:
			advance_dialogue()

func start_dialogue():
	dialogue_active = true
	dialogue_index = 0
	prompt_label.visible = false
	dialogue_box.visible = true
	animated_sprite.animation = "old_man talk"
	animated_sprite.play()
	_start_typing(current_dialogues[dialogue_index])
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(false)

func advance_dialogue():
	dialogue_index += 1
	if dialogue_index < current_dialogues.size():
		_start_typing(current_dialogues[dialogue_index])
	else:
		# If this is completion dialogue and we haven't given reward yet
		if all_reforestation_levels_completed() and not has_given_reward:
			give_coin_reward()
			# After giving reward, disappear instead of ending dialogue normally
			disappear_after_reward()
		else:
			end_dialogue()

func give_coin_reward():
	has_given_reward = true
	
	# Add coins directly to player's account
	if AvatarManager and AvatarManager.has_method("add_coins"):
		AvatarManager.add_coins(coin_reward_value)
	
	# If you have a coin scene, spawn some visual coins
	if coin_scene:
		spawn_reward_coins()

func spawn_reward_coins():
	# Spawn 3-5 coins around the old man for visual effect
	var num_coins = randi_range(3, 5)
	
	for i in num_coins:
		var coin_instance = coin_scene.instantiate()
		get_parent().add_child(coin_instance)
		
		# Position coins in a semi-circle around the old man
		var angle = (PI / (num_coins - 1)) * i - PI/2
		var spawn_distance = 50.0
		var coin_pos = global_position + Vector2(
			cos(angle) * spawn_distance,
			sin(angle) * spawn_distance + 30  # Slight offset upward
		)
		
		coin_instance.global_position = coin_pos
		
		# Set coin value (divide total reward among coins)
		if coin_instance.has_method("set_coin_value"):
			coin_instance.set_coin_value(coin_reward_value / num_coins)

func end_dialogue():
	dialogue_active = false
	dialogue_box.visible = false
	prompt_label.visible = true
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)

func disappear_after_reward():
	dialogue_active = false
	dialogue_box.visible = false
	
	# Re-enable player movement
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)
	
	# Play disappearing animation
	animated_sprite.animation = "old_man idle"
	animated_sprite.play()
	
	# Create disappearing effect
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens to run simultaneously
	
	# Fade out effect
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	
	# Scale down effect
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 2.0)
	
	# Float upward effect
	tween.tween_property(self, "global_position:y", global_position.y - 100, 2.0)
	
	# Wait for animation to complete, then remove the NPC
	await tween.finished
	
	# Disable collision detection
	if area:
		area.set_deferred("monitoring", false)
	
	# Hide the NPC completely
	visible = false
	
	# Optionally, you can queue_free() to completely remove it
	# queue_free()

# Alternative function if you want instant disappearance
func disappear_instantly():
	dialogue_active = false
	dialogue_box.visible = false
	
	# Re-enable player movement
	if player_ref and player_ref.has_method("set_movement_enabled"):
		player_ref.set_movement_enabled(true)
	
	# Disable collision detection
	if area:
		area.set_deferred("monitoring", false)
	
	# Hide or remove the NPC
	visible = false
	# Or completely remove: queue_free()

func _start_typing(text):
	typing = true
	dialogue_label.text = ""
	_type_text(text)

func _type_text(text) -> void:
	for c in text:
		dialogue_label.text += c
		await get_tree().create_timer(0.05).timeout
	typing = false

# Call this function when you want to update the NPC state
# (e.g., from the reforestation game controller)
func update_npc_state():
	check_and_setup_npc()
