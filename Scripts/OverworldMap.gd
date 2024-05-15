extends Node2D

# we will use the gridobject to represent an overworld and a playerobject for the player
var GridObject = preload("res://Prefabs/grid_placeholder.tscn")
var PlayerObject = preload("res://Prefabs/player.tscn")

var size = 5

var worldGrid

var player

var Gridmin = 0
var Gridmax = 64

# we can use a 2d array to create a digital representation of the world map
func make2dArray():
	# start with an empty array, and make it 2d
	var temp = []
	for i in size:
		temp.append([])
		for j in size:
			temp[i].append(null)
	
	# we can then fill the array with the world grid
	for i in size:
		for j in size:
			# to actually place the grid object in the world, instantiate it
			var gridpiece = GridObject.instantiate()
			# from there, change its position in the world.
			# grid pieces are 16x16 pixels in size, multiply i and j by that
			gridpiece.position = Vector2(i*16, j*16)
			
			# add this gridpiece to the scene and array
			add_child(gridpiece)
			temp[i][j] = gridpiece
	return temp
	

# we want to handle player movement in the grid system, 
# this way we can prevent movement with obstacles
func _input(event):
	if event.is_action_pressed("Up"):
		if player.position.y > Gridmin:
			player.position += Vector2(0, -16)
		
	if event.is_action_pressed("Down"):
		if player.position.y < Gridmax:
			player.position += Vector2(0, 16)
		
	if event.is_action_pressed("Left"):
		if player.position.x > Gridmin:
			player.position += Vector2(-16, 0)
		
	if event.is_action_pressed("Right"):
		if player.position.x < Gridmax:
			player.position += Vector2(16, 0)


# Called when the node enters the scene tree for the first time.
func _ready():
	worldGrid = make2dArray()
	player = PlayerObject.instantiate()
	player.position = Vector2(32, 32)
	add_child(player)
	

