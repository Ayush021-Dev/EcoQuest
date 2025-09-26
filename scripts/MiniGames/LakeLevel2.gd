extends Node2D

const FISH_SMALL = "minnow"
const FISH_MEDIUM = "perch"
const FISH_BIG = "bass"
var fish_types = [FISH_SMALL, FISH_MEDIUM, FISH_BIG]

@onready var panel = $Panel
@onready var bg_music = $BG
@onready var close_button = $CloseButton
@onready var click_sound = $ClickSound
@onready var hover_sound = $HoverSound
@onready var win_panel = $WinPanel
@onready var win_label = $WinPanel/WinLabel
@onready var fish_container = $FishContainer
@onready var fish_button_small = $FishButtonSmall
@onready var fish_button_medium = $FishButtonMedium
@onready var fish_button_big = $FishButtonBig
@onready var score_label = $ScoreLabel
@export var fish_scene: PackedScene = preload("res://scenes/Fish.tscn")

var fish_counts = {
	FISH_SMALL: 0,
	FISH_MEDIUM: 0,
	FISH_BIG: 0
}
var game_running = false
var game_completed = false
var score = 0
var has_won = false

func _ready():
	panel.visible = false
	win_panel.visible = false
	set_process(false)
	get_tree().paused = true
	game_running = false
	has_won = false
	score = 0
	update_score_display()

	# Connect signals for panel and close button
	if not panel.is_connected("gui_input", Callable(self, "_on_panel_gui_input")):
		panel.connect("gui_input", Callable(self, "_on_panel_gui_input"))

	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.connect("pressed", Callable(self, "_on_close_pressed"))

	if not close_button.is_connected("pressed", Callable(self, "_play_click_sound")):
		close_button.connect("pressed", Callable(self, "_play_click_sound"))

	if not close_button.is_connected("mouse_entered", Callable(self, "_play_hover_sound")):
		close_button.connect("mouse_entered", Callable(self, "_play_hover_sound"))

	# Connect fish buttons signals with parameter using Callable and bind()
	fish_button_small.connect("pressed", Callable(self, "_on_fish_button_pressed").bind(FISH_SMALL))
	fish_button_medium.connect("pressed", Callable(self, "_on_fish_button_pressed").bind(FISH_MEDIUM))
	fish_button_big.connect("pressed", Callable(self, "_on_fish_button_pressed").bind(FISH_BIG))

	# Connect sounds for fish buttons
	for btn in [fish_button_small, fish_button_medium, fish_button_big]:
		btn.pressed.connect(Callable(self, "_play_click_sound"))
		btn.mouse_entered.connect(Callable(self, "_play_hover_sound"))

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not game_running:
		panel.visible = false
		get_tree().paused = false
		set_process(true)
		game_running = true
		if bg_music and not bg_music.playing:
			bg_music.play()
		_play_click_sound()

func _on_fish_button_pressed(fish_type: String):
	if not game_running or game_completed:
		return
	fish_counts[fish_type] += 1
	spawn_fish(fish_type)
	update_ecosystem()
	update_score_display()

func spawn_fish(fish_type: String):
	var fish = fish_scene.instantiate()
	match fish_type:
		"minnow":
			fish.get_node("AnimatedSprite2D").play("small")
		"perch":
			fish.get_node("AnimatedSprite2D").play("medium")
		"bass":
			fish.get_node("AnimatedSprite2D").play("big")
	fish_container.add_child(fish)

func update_ecosystem():
	# Big eats Medium
	if fish_counts[FISH_MEDIUM] > 0 and fish_counts[FISH_BIG] > 0:
		if fish_counts[FISH_MEDIUM] < fish_counts[FISH_BIG] * 2:
			var eaten = min(fish_counts[FISH_MEDIUM], fish_counts[FISH_BIG])
			fish_counts[FISH_MEDIUM] -= eaten
			score += eaten * 5
	# Medium eats Small
	if fish_counts[FISH_SMALL] > 0 and fish_counts[FISH_MEDIUM] > 0:
		if fish_counts[FISH_SMALL] < fish_counts[FISH_MEDIUM] * 2:
			var eaten = min(fish_counts[FISH_SMALL], fish_counts[FISH_MEDIUM])
			fish_counts[FISH_SMALL] -= eaten
			score += eaten * 2
	# Win/loss condition
	if fish_counts[FISH_SMALL] <= 0 or fish_counts[FISH_MEDIUM] <= 0 or fish_counts[FISH_BIG] <= 0:
		end_game(false)
	elif check_balanced() and not has_won:
		end_game(true)

func check_balanced() -> bool:
	var vals = [fish_counts[FISH_SMALL], fish_counts[FISH_MEDIUM], fish_counts[FISH_BIG]]
	var biggest = max(vals)
	var smallest = min(vals)
	return biggest > 0 and smallest > 0 and biggest - smallest <= 1

func end_game(won: bool):
	game_completed = true
	has_won = won
	set_process(false)
	win_panel.visible = true
	if win_label:
		if won:
			win_label.text = "🎉 GAME WON! 🎉\nEcosystem Balanced!\nScore: " + str(score)
			LevelCompletionManager.mark_level_completed("lake_level2")
		else:
			win_label.text = "😢 Ecosystem Collapsed!\nTry again."
	if bg_music and bg_music.playing:
		bg_music.stop()
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(score)
		# Optionally show fish counts
		# score_label.text += "\nMinnow: %d  Perch: %d  Bass: %d" % [fish_counts[FISH_SMALL], fish_counts[FISH_MEDIUM], fish_counts[FISH_BIG]]

func _on_close_pressed():
	get_tree().change_scene_to_file("res://scenes/Mini_games_level_Screens/LakeLevels.tscn")

func _play_click_sound():
	if click_sound.playing:
		click_sound.stop()
	click_sound.play()

func _play_hover_sound():
	if hover_sound.playing:
		hover_sound.stop()
	hover_sound.play()
