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

var pathFound

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
	
	# fill the grid with 0s initially
	for i in size:
		for j in size:
			worldGrid[i][j] = 0
	
	# this represents the player
	worldGrid[2][2] = 3
	
	# we can then fill the array with the world grid
	for i in size:
		for j in size:
			
			# initialize the gridpiece this will either be an impassable wall or a floor
			var gridpiece
			
			# initialize enemies
			var foe
			
			# generate a random number between 0 and 99
			# if it is less than 10, generate a wall, otherwise generate a blank space
			# additionally we shoud prevent a wall from spawning on a player, that would be weird
			if (randi() % 100) < 10 and worldGrid[i][j] == 0:
				gridpiece = WallObject.instantiate()
				worldGrid[i][j] = 1
			
			# wall failed to generate, create a floor object instead	
			else:
				gridpiece = GridObject.instantiate()
				worldGrid[i][j] = 0
				
				# roll a chance to spawn an enemy as well
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
	
	# one more thing, fix up the map
	# it isn't very fun when a player gets softlocked because the walls spawned in all directions around them
	# in the off chance a part of the map gets blocked off, I want to recover
	# WIP for now
	
	# for each grid object...
	for i in size:
		for j in size:
			# check to see if it is a floor or is occupied by an enemy
			if worldGrid[i][j] == 0 or worldGrid[i][j] == 2:
				# start by assuming no path exists for each grid object
				pathFound = false
				# try to find a path
				findPath([i, j], [2,2], [])
				# if no path was found then fix the map
				if not pathFound:
					fixMap([i, j], [2, 2])

# this functionality will come soon, but should be simple
# just go from player position to the blocked off part of the map, deleting any walls in the way	
func fixMap(location, playerpos):
	pass
			
	
	

# find the path to a specific location
func findPath(location, curpos, visited):
	
	# start by adding the current position to our visited array
	visited.append(curpos)
	
	# if the current position matches our desired position, congrats, a path has been found!
	if curpos.hash() == location.hash():
		print("Valid path has been found!")
		pathFound = true
		return visited
	
	# we must now check each direction around current position not in visited
	
	# start with an empty array, we will fill it with this position's neighbors provided they have not been visited
	var dirstoVisit = []
	
	# check all 8 directions around this grid location
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i != 0 and j != 0:
				# check to make sure this direction is in our world
				if location[0]+i >= 0 and location[0]+i <= size-1 and location[1]+j >= 0 and location[1]+j <= size-1:
					# if it is, check to see if it is a blank space (a floor space) or an enemy and has not already been visited
					if (worldGrid[location[0]+i][location[1]+j] == 0 or worldGrid[location[0]+i][location[1]+j] == 2) and not visited.has([location[0]+i, location[1]+j]):
						# if all checks pass, add it to places to visit
						dirstoVisit.append([location[0]+i, location[1]+j])
	
	
	# if directions have been found, recursively call this function using each direction as a new curpos
	# update visited each loop	
	for direction in dirstoVisit:
		visited = findPath(location, direction, visited)
	
	# once each direction has been checked, return visited	
	return visited
		
	
	
			

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
	

