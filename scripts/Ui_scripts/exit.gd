extends TextureButton

@onready var hover_sound = get_tree().current_scene.find_child("HoverSound", true, false)
@onready var click_sound = get_tree().current_scene.find_child("ClickSound", true, false)

func _on_mouse_entered() -> void:
	modulate = Color(0.6, 0.6, 0.6) # This TextureButton darkens
	if hover_sound:
		hover_sound.play()
		
func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1) # Reset to normal
	

func _on_pressed() -> void:
	if click_sound:
		click_sound.play()
	get_tree().quit()
