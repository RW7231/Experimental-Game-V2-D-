extends Node2D

var currentPosition = [2, 2]

var map

# get_parent is a bad function that barely works half the time
# I have to run it in _process to ensure that it actually gets the map	
func _process(delta):
	if map == null:
		map = self.get_parent()
	else:
		set_process(false)

# we want to handle player movement in the grid system, 
func _input(event):
	# check the player direction, if the position is valid, move the player there
	if event.is_action_pressed("Up"):
		var desiredPos = [currentPosition[0], currentPosition[1]-1]
		if map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(0, -16)
		
	if event.is_action_pressed("Down"):
		var desiredPos = [currentPosition[0], currentPosition[1]+1]
		if map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(0, 16)
		
	if event.is_action_pressed("Left"):
		var desiredPos = [currentPosition[0]-1, currentPosition[1]]
		if map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(-16, 0)
		
		
	if event.is_action_pressed("Right"):
		var desiredPos = [currentPosition[0] + 1, currentPosition[1]]
		if map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(16, 0)
		
