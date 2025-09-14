extends Control
@onready var start_bgm = $StartBGM

func _ready():
	start_bgm.play()
	start_bgm.connect("finished", Callable(self, "_on_start_bgm_finished"))

func _on_start_bgm_finished():
	start_bgm.play()
