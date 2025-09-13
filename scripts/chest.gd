extends Node2D

@export var min_coin_value: int = 30
@export var max_coin_value: int = 40

var player_in_range: bool = false
var player_ref = null
var is_opened: bool = false
var coin_scene = preload("res://scenes/Coin.tscn")

@onready var animated_sprite := $AnimatedSprite2D
@onready var area := $AnimatedSprite2D/Area2D
@onready var prompt_label := $PromptLabel
@onready var coin_spawn_point := $CoinSpawnPoint

func _ready():
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	else:
		push_error("Area2D node not found!")
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	if prompt_label:
		prompt_label.visible = false
	
	# If no spawn point is set, use chest position
	if not coin_spawn_point:
		var spawn_point = Node2D.new()
		spawn_point.name = "CoinSpawnPoint"
		spawn_point.position = Vector2(0, -80)  # Higher above chest
		add_child(spawn_point)
		coin_spawn_point = spawn_point

func _on_body_entered(body):
	if body.is_in_group("Player") and not is_opened:
		player_in_range = true
		player_ref = body
		if animated_sprite:
			animated_sprite.play("found")
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if not is_opened and animated_sprite:
			animated_sprite.play("idle")
		if prompt_label:
			prompt_label.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not is_opened:
		open_chest()

func open_chest():
	if not is_opened:
		is_opened = true
		
		# Play chest opening animation
		if animated_sprite:
			animated_sprite.play("opened")
		
		# Hide prompt
		if prompt_label:
			prompt_label.visible = false
		
		# Disable area monitoring
		area.set_deferred("monitoring", false)
		
		# Spawn single coin
		spawn_coin()
		
		print("Chest opened!")

func spawn_coin():
	# Generate random coin value
	var coin_value = randi_range(min_coin_value, max_coin_value)
	
	print("Spawning coin with value: ", coin_value)
	
	# Create coin instance
	var coin = coin_scene.instantiate()
	
	if not coin:
		print("ERROR: Failed to instantiate coin scene!")
		return
	
	# Set coin value
	if coin.has_method("set_coin_value"):
		coin.set_coin_value(coin_value)
	else:
		print("ERROR: Coin doesn't have set_coin_value method!")
		return
	
	# Position coin at spawn point
	coin.global_position = coin_spawn_point.global_position
	
	# Add to scene
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(coin)
	else:
		get_parent().add_child(coin)
	
	# Connect to coin collection signal
	if coin.has_signal("coin_collected"):
		coin.coin_collected.connect(_on_coin_collected)
	
	print("Coin spawned at position: ", coin.global_position)

func _on_coin_collected(value: int):
	print("Coin worth ", value, " collected from this chest!")
