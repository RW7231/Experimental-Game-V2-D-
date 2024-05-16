extends Node2D

# we will use the gridobject to represent an overworld and a playerobject for the player
var GridObject = preload("res://Prefabs/grid_placeholder.tscn")
var PlayerObject = preload("res://Prefabs/player.tscn")
var WallObject = preload("res://Prefabs/wall.tscn")

var size = 5

var worldGrid

var player

var Gridmin = 0
var Gridmax = 64

var playerpos = [2, 2]

# we can use a 2d array to create a digital representation of the world map
func make2dArray():
	# start with an empty array, and make it 2d
	var temp = []
	for i in size:
		temp.append([])
		for j in size:
			temp[i].append(null)
	return temp
	
func fillWorld():
	# we can then fill the array with the world grid
	for i in size:
		for j in size:
			
			# initialize the gridpiece
			var gridpiece
			
			# generate a random number between 0 and 99
			# if it is less than 10, generate a wall, otherwise generate a blank space
			if (randi() % 100) < 10:
				gridpiece = WallObject.instantiate()
				worldGrid[i][j] = 1
				#var string = "Wall on %d %d"
				#var fullString = string % [i, j]
				#print(fullString)
				
			else:
				gridpiece = GridObject.instantiate()
				worldGrid[i][j] = 0
				
			# from there, change its position in the world.
			# grid pieces are 16x16 pixels in size, multiply i and j by that
			gridpiece.position = Vector2(i*16, j*16)
			
			# add this gridpiece to the scene and array
			add_child(gridpiece)
	

# we want to handle player movement in the grid system, 
# this way we can prevent movement with obstacles
func _input(event):
	if event.is_action_pressed("Up"):
		# we want to check that the player is within the grid and that the position is not already filled
		if player.position.y > Gridmin and worldGrid[playerpos[0]][playerpos[1] - 1] != 1:
			player.position += Vector2(0, -16)
			playerpos = [playerpos[0], playerpos[1] - 1]
		
	if event.is_action_pressed("Down"):
		if player.position.y < Gridmax and worldGrid[playerpos[0]][playerpos[1] + 1] != 1:
			player.position += Vector2(0, 16)
			playerpos = [playerpos[0], playerpos[1] + 1]
		
	if event.is_action_pressed("Left"):
		if player.position.x > Gridmin and worldGrid[playerpos[0] - 1][playerpos[1]] != 1:
			player.position += Vector2(-16, 0)
			playerpos = [playerpos[0] - 1, playerpos[1]]
		
	if event.is_action_pressed("Right"):
		if player.position.x < Gridmax and worldGrid[playerpos[0] + 1][playerpos[1]] != 1:
			player.position += Vector2(16, 0)
			playerpos = [playerpos[0] + 1, playerpos[1]]


# Called when the node enters the scene tree for the first time.
func _ready():
	# consistent generation
	seed(3)
	worldGrid = make2dArray()
	fillWorld()
	player = PlayerObject.instantiate()
	player.position = Vector2(32, 32)
	add_child(player)
	

