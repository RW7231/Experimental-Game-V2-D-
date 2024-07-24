extends Sprite2D

func _input(event):
	var menu = self.get_parent()
	var player = menu.get_parent().get_parent()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			print("close clicked")
			player.menuOpen = false
			menu.queue_free()
