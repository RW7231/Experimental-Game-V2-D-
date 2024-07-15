extends Node2D

# we will use the gridobject to represent an overworld and a playerobject for the player
var GridObject = preload("res://Prefabs/grid_placeholder.tscn")
var PlayerObject = preload("res://Prefabs/player.tscn")
var WallObject = preload("res://Prefabs/wall.tscn")
var EnemyObject = preload("res://Prefabs/enemy.tscn")
var StairObject = preload("res://Prefabs/stair_placeholder.tscn")

var size = 15

var worldGrid = []

# this variable stores the actual tiles used in the game map
var tileGrid = []

var player

var playerpos = [2, 2]

var pathFound

var knownValidPositions

var enemies = []

var difficulty = 0

var exit

# we can use a 2d array to create a digital representation of the world map
func make2dArray():
	# start with an empty array, and make it 2d
	var temp = []
	for i in size:
		temp.append([])
		for j in size:
			temp[i].append(null)
			
	for i in size:
		for j in size:
			temp[i][j] = 0
	
	return temp
	
func fillWorld():
	
	# we can then fill the array with the world grid
	for i in size:
		for j in size:
			
			var gridpiece
			var foe
			
			# is this not the player's position?
			if i != playerpos[0] or j != playerpos[1]:
			
				# generate a random number between 0 and 99
				# if it is less than 50, generate a wall, otherwise generate a blank space
				# additionally we shoud prevent a wall from spawning on a player, that would be weird
				if (randi() % 100) < 50 and worldGrid[i][j] == 0:
					gridpiece = WallObject.instantiate()
					tileGrid[i][j] = gridpiece
					worldGrid[i][j] = 1
			
				# wall failed to generate, create a floor object instead	
				else:
					gridpiece = GridObject.instantiate()
					tileGrid[i][j] = gridpiece
					worldGrid[i][j] = 0
				
					# roll a chance to spawn an enemy as well
					if (randi() % 100) < 5:
						foe = EnemyObject.instantiate()
						foe.position = Vector2(i * 16, j * 16)
						add_child(foe)
						enemies.append(foe)
						foe.setGridLocation([i,j])
			
			# this is the player's spot, put down a floor	
			else:
				gridpiece = GridObject.instantiate()
				tileGrid[i][j] = gridpiece
				worldGrid[i][j] = 0
				
			# from there, change its position in the world.
			# grid pieces are 16x16 pixels in size, multiply i and j by that
			gridpiece.position = Vector2(i*16, j*16)
			
				# add this gridpiece to the scene and array
			add_child(gridpiece)
			
	# once the basic map has been generated, correct any mistakes
	checkMap()
	
	# place an exit so the player can go to next level
	placeExit()
					

func checkMap():
	# one more thing, fix up the map
	# it isn't very fun when a player gets softlocked because the walls spawned in all directions around them
	# in the off chance a part of the map gets blocked off, I want to recover
	
	knownValidPositions = []
	
	# for each grid object...
	for i in size:
		for j in size:
			# check to see if it is a floor
			if worldGrid[i][j] == 0:
				# start by assuming no path exists for each grid object
				pathFound = false
				# try to find a path
				findPath([i, j], player.getPosition(), [])
				# if no path was found then fix the map
				if not pathFound:
					fixMap([i, j], player.getPosition())
					

func placeExit():
	var placement = knownValidPositions[randi() % knownValidPositions.size()]
	exit = StairObject.instantiate()
	exit.position = Vector2(placement[0] * 16, placement[1] * 16)
	self.add_child(exit)
	tileGrid[placement[0]][placement[1]].queue_free()
	tileGrid[placement[0]][placement[1]] = exit
	
	worldGrid[placement[0]][placement[1]] = 2

# this functionality will come soon, but should be simple
# just go from player position to the blocked off part of the map, deleting any walls in the way	
func fixMap(location, ppos):
	print("Location ", location[0], ", ", location[1], " is invalid and must be fixed")
	
	if location[0] < ppos[0]:
		for i in range(location[0], ppos[0]):
			var newFloor = GridObject.instantiate()
			newFloor.position = Vector2(i*16, ppos[1]*16)
			self.add_child(newFloor)
			tileGrid[i][ppos[1]].queue_free()
			tileGrid[i][ppos[1]] = newFloor
			worldGrid[i][ppos[1]] = 0
	else:
		for i in range(ppos[0], location[0]):
			var newFloor = GridObject.instantiate()
			newFloor.position = Vector2(i*16, ppos[1]*16)
			self.add_child(newFloor)
			tileGrid[i][ppos[1]].queue_free()
			tileGrid[i][ppos[1]] = newFloor
			worldGrid[i][ppos[1]] = 0
			
	if location[1] < ppos[1]:
		for i in range(location[1], ppos[1]):
			var newFloor = GridObject.instantiate()
			newFloor.position = Vector2(location[0]*16, i*16)
			self.add_child(newFloor)
			tileGrid[location[0]][i].queue_free()
			tileGrid[location[0]][i] = newFloor
			worldGrid[location[0]][i] = 0
	else:
		for i in range(ppos[1], location[1]):
			var newFloor = GridObject.instantiate()
			newFloor.position = Vector2(location[0]*16, i*16)
			self.add_child(newFloor)
			tileGrid[location[0]][i].queue_free()
			tileGrid[location[0]][i] = newFloor
			worldGrid[location[0]][i] = 0
			
	
	

# find the path to a specific location
func findPath(location, curpos, visited):
	
	# consult the memoized table first, if it is there then the path is already valid
	if knownValidPositions.has([location[0], location[1]]):
		print("This position is a known valid ", location[0], ", ", location[1])
		pathFound = true
		return visited
	
	# start by adding the current position to our visited array and memoized table
	visited.append(curpos)
	knownValidPositions.append(curpos)
	
	# if the current position matches our desired position, congrats, a path has been found!
	if curpos.hash() == location.hash():
		print("Valid path has been found for ", location[0], ", ", location[1])
		pathFound = true
		return visited
	
	# we must now check each direction around current position not in visited
	
	# start with an empty array, we will fill it with this position's neighbors provided they have not been visited
	var dirstoVisit = []
	
	# check all 8 directions around this grid location
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i != 0 or j != 0:
				# check to make sure this direction is in our world
				if curpos[0]+i >= 0 and curpos[0]+i <= size-1 and curpos[1]+j >= 0 and curpos[1]+j <= size-1:
					# if it is, check to see if it is a blank space (a floor space) or an enemy and has not already been visited
					if worldGrid[curpos[0]+i][curpos[1]+j] == 0 and not visited.has([curpos[0]+i, curpos[1]+j]):
						# if all checks pass, add it to places to visit
						dirstoVisit.append([curpos[0]+i, curpos[1]+j])
	
	
	# if directions have been found, recursively call this function using each direction as a new curpos
	# update visited each loop	
	for direction in dirstoVisit:
		if not pathFound:
			var newVisited = findPath(location, direction, visited)
			
			for entry in newVisited:
				if not visited.has(entry):
					visited.append(entry)
	
	# once each direction has been checked, return visited	
	return visited
		

# give enemies the ability to find the player
func isPlayerHere(location):
	if location[0] == player.getPosition()[0] and location[1] == player.getPosition()[1]:
		return true
	
	return false
	

# let player identify enemies
func isFoeHere(location):
	for enemy in enemies:
		if enemy.getGridLocation()[0] == location[0] and enemy.getGridLocation()[1] == location[1]:
			return enemy
	
	return null
	
func checkForExit(location):
	if worldGrid[location[0]][location[1]] == 2:
		generateNewMap()
		
	
# monster attacks player
func attackPlayer(monster):
	player.takeDamage(monster.attack, monster.attackBonus)

# player attacks monster	
func attackFoe(monster):
	monster.takeDamage(player.attack, player.attackBonus)
	
func destroyFoe(monster):
	player.gainSouls(monster.soulValue)
	enemies.erase(monster)
			

# let player make requests to move, check if it is valid
func checkPos(desiredPos):
	# if the position goes outside of the grid, refuse it
	if desiredPos[0] < 0 or desiredPos[0] >= size or desiredPos[1] < 0 or desiredPos[1] >= size:
		return false
	
	# if the position is not a blank space (enemy, wall, etc) deny it
	return (worldGrid[desiredPos[0]][desiredPos[1]] == 0 or worldGrid[desiredPos[0]][desiredPos[1]] == 2)

# the player has taken an action, now every other entity can have a turn	
func turn():
	for enemy in enemies:
		enemy.turn()
	
	# roll a chance to spawn an enemy as well, 1% per turn
	# also, prevent spawns if number of enemies exceeds map size/2
	if (randi() % 100) < 1 and enemies.size() < size/2:
		print("Enemy Spawned")
		var foe = EnemyObject.instantiate()
		var posx
		var posy
		var invalid = true
		
		while invalid:
			posx = randi() % size
			posy = randi() % size
			if worldGrid[posx][posy] == 0:
				invalid = false
			
		foe.position = Vector2(posx * 16, posy * 16)
		add_child(foe)
		enemies.append(foe)
		foe.setGridLocation([posx, posy])
		
		

func getSize():
	return size
	
func generateNewMap():
	
	# start difficulty at 1 and increase for each new level
	difficulty += 1
	
	# every time new level is generated, randomly determine size
	size = randi_range(10, 20)
	
	# clear out all children currently in the map node
	for child in self.get_children():
		child.queue_free()
	
	# clear out the arrays so we can start over	
	worldGrid.clear()
	tileGrid.clear()
	enemies.clear()
	
	# generate 2d arrays for the "physical" world and the data world	
	worldGrid = make2dArray()
	tileGrid = make2dArray()
	
	# spawn the player and put them into the game once the map is generated
	player = PlayerObject.instantiate()
	self.add_child(player)
	
	player.setStartPos(size/2)
	
	playerpos = player.getPosition()
	player.position = Vector2(16 * playerpos[0], 16 * playerpos[1])
	
	fillWorld()
	
	saveMapData()
	
func saveMapData():
	var baseData = {"worldGrid": worldGrid, "difficulty": difficulty}
	
	var saveData = JSON.new().stringify(baseData)
	
	var file = FileAccess.open("res://mapData.json", FileAccess.WRITE)
	
	file.store_line(saveData)
	
	file.close()
		
		
func loadMapData():
	var file = FileAccess.open("res://mapData.json", FileAccess.READ)
	
	if file == null:
		generateNewMap()
		return
	
	var content = JSON.new().parse_string(file.get_as_text())
	
	worldGrid = content["worldGrid"]
	difficulty = content["difficulty"]
	
	size = worldGrid.size()
	
	tileGrid = make2dArray()
	
	var wall
	var floor
	var exit
	
	for i in size:
		for j in size:
			if worldGrid[i][j] == 1:
				wall = WallObject.instantiate()
				wall.position = Vector2(i*16, j*16)
				tileGrid[i][j] = wall
				self.add_child(wall)
			elif worldGrid[i][j] == 2:
				exit = StairObject.instantiate()
				exit.position = Vector2(i*16, j*16)
				tileGrid[i][j] = exit
				self.add_child(exit)
			else:
				floor = GridObject.instantiate()
				floor.position = Vector2(i*16, j*16)
				tileGrid[i][j] = floor
				self.add_child(floor)
				
	player = PlayerObject.instantiate()
	
	self.add_child(player)
				
	playerpos = player.getPosition()
	player.position = Vector2(16 * playerpos[0], 16 * playerpos[1])
	
	file.close()
	
func newPlayer():
	player.setStartPos(size/2)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	loadMapData()
	

