extends VBoxContainer

var vigor
var strength
var dex
var intelligence
var faith

var pressed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	vigor = get_node("VigorLevel")
	strength = get_node("StrLevel")
	dex = get_node("DexLevel")
	intelligence = get_node("IntLevel")
	faith = get_node("FaithLevel")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player = self.get_parent().get_parent()
	
	if vigor.button_pressed:
		if pressed:
			return
		pressed = true
		player.gainLevel(1)
		return
		
	if strength.button_pressed:
		if pressed:
			return
		pressed = true
		player.gainLevel(2)
		return
		
	if dex.button_pressed:
		if pressed:
			return
		pressed = true
		player.gainLevel(3)
		return
	
	if intelligence.button_pressed:
		if pressed:
			return
		pressed = true
		player.gainLevel(4)
		return
	
	if faith.button_pressed:
		if pressed:
			return
		pressed = true
		player.gainLevel(5)
		return
	
	pressed = false
		
