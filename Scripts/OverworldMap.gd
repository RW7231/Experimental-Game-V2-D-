extends Node2D

# we will use the gridobject to represent an overworld and a playerobject for the player
var GridObject = preload("res://Prefabs/grid_placeholder.tscn")
var PlayerObject = preload("res://Prefabs/player.tscn")
var WallObject = preload("res://Prefabs/wall.tscn")
var EnemyObject = preload("res://Prefabs/enemy.tscn")

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
			
			# initialize enemies
			var foe
			
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
				
				if (randi() % 100) < 10:
					foe = EnemyObject.instantiate()
					foe.position = Vector2(i * 16, j * 16)
					worldGrid[i][j] = 2
					add_child(foe)
				
			# from there, change its position in the world.
			# grid pieces are 16x16 pixels in size, multiply i and j by that
			gridpiece.position = Vector2(i*16, j*16)
			
			# add this gridpiece to the scene and array
			add_child(gridpiece)

# let player make requests to move, check if it is valid
func checkPos(desiredPos):
	# if the position goes outside of the grid, refuse it
	if desiredPos[0] < 0 or desiredPos[0] >= size or desiredPos[1] < 0 or desiredPos[1] >= size:
		return false
	
	# if the position is not a blank space (enemy, wall, etc) deny it
	return worldGrid[desiredPos[0]][desiredPos[1]] == 0
			


# Called when the node enters the scene tree for the first time.
func _ready():
	# consistent generation
	seed(3)
	worldGrid = make2dArray()
	fillWorld()
	player = PlayerObject.instantiate()
	player.position = Vector2(32, 32)
	self.add_child(player)
	

