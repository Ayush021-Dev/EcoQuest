extends Node2D

@onready var audio_player = $LevelClick
@onready var levels_container = $Levels

var level_scenes = [
	"res://scenes/Level1.tscn",
	"res://scenes/Level2.tscn", 
	"res://scenes/Level3.tscn",
	"res://scenes/Level4.tscn"
]

func _ready():
	# Connect all level buttons automatically
	for i in range(levels_container.get_child_count()):
		var button = levels_container.get_child(i)
		button.pressed.connect(_play_click_sound)
		button.pressed.connect(_on_level_pressed.bind(i))

func _play_click_sound():
	audio_player.play()

func _on_level_pressed(level_index: int):
	if level_index < level_scenes.size():
		get_tree().change_scene_to_file(level_scenes[level_index])
