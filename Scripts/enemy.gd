extends Sprite2D

var health
var AC
var attack
var defense
var attackBonus
var soulValue

# special stat that determines when an enemy can take an action
# if it hits 0 the enemy can move, otherwise they must wait
var speed

var gridLocation

func setGridLocation(location):
	gridLocation = location
	self.position = Vector2(16 * location[0], 16 * location[1])
	
func getGridLocation():
	return gridLocation
	
func getStats():
	return [health, AC, attack, defense, attackBonus, gridLocation, soulValue]

# when we take data from the map data, call this function for each spawned enemy	
func generateFromSave(stats):
	health = stats[0]
	AC = stats[1]
	attack = stats[2]
	defense = stats[3]
	attackBonus = stats[4]
	gridLocation = stats[5]
	soulValue = stats[6]
	
	self.position = Vector2(16 * gridLocation[0], 16 * gridLocation[1])

# Called when the node enters the scene tree for the first time.
func _ready():
	# as the player descends into the dungeon increase enemy difficulty
	# enemies have more health, do more danage and are more resilient
	var worldDif = self.get_parent().difficulty
	
	# gather the data of all enemies, data will be an array for each enemy
	# it contains the difficulty and the enemy's stats
	var EnemyData = FileAccess.open("res://EnemyData.json", FileAccess.READ)
	EnemyData = JSON.parse_string(EnemyData.get_as_text())
	
	var possibleEnemies = []
	
	# when an enemy is generated select its stats from the provided data
	# only an enemy with a difficulty rating lower or equal than the world difficulty can spawn
	for key in EnemyData:
		var enemy = EnemyData[key]
		if enemy[0] <= worldDif:
			possibleEnemies.append(enemy)
	
	# once we determine which enemies can spawn, select one of them for this enemy		
	var SelectedStats = possibleEnemies[randi() % possibleEnemies.size()]
	
	# we then assign the stats according to the enemy
	health = SelectedStats[1]
	AC = SelectedStats[2]
	attack = SelectedStats[3]
	defense = SelectedStats[4]
	attackBonus = SelectedStats[5]
	speed = (randi() % 20) + 1
	soulValue = SelectedStats[6]
	
	var texturePath = str("res://Assets/", SelectedStats[7])
	self.texture = load(texturePath)
	
	# old enemy generation method
	'''
	health = 5.0 * randi_range(worldDif/2 + 1, worldDif)
	AC = 10
	attack = 1.0 * randi_range(worldDif/2 + 1, worldDif)
	defense = 1.0 * randi_range(worldDif/2 + 1, worldDif)
	attackBonus = 3 + worldDif
	# determine an initial speed value, something between 1 to 20
	speed = (randi() % 20) + 1
	
	soulValue = 100 * worldDif
	'''
	

func takeDamage(amount, bonus):
	if (((randi() % 20) + 1) + bonus) < AC:
		print("You missed an enemy...")
		return
	
	var damage = int(amount * (amount/defense))
	
	health -= damage
	print("You attack an enemy and hit for ", damage)
	
	isAlive()

func isAlive():
	if health <= 0:
		var map = self.get_parent()
		map.destroyFoe(self)
		queue_free()

func turn():
	
	# if this entity's speed is greater than 0, no action is taken
	if speed > 0:
		speed -= 1
		return
	
	# otherwise, take an action
	var map = self.get_parent()
	
	var selectedLocation = false
	var desiredPos = gridLocation
	
	var validLocations = []
	
	# first we need to gather all potential locations the enemy can go to
	# this allows us to exclude any locations that are outside of the grid
	for i in range(-1, 2):
		for j in range(-1, 2):
			if gridLocation[0]+i >= 0 and gridLocation[0]+i <= map.getSize()-1 and gridLocation[1]+j >= 0 and gridLocation[1]+j <= map.getSize()-1:
				validLocations.append([gridLocation[0]+i, gridLocation[1]+j])
	
	# once we have valid locations, check to see if the player is in one of them
	for location in validLocations:
		# if the player is indeed in one of the locations, do not move and instead attack
		if map.isPlayerHere(location):
			selectedLocation = true
			map.attackPlayer(self)
	
	# now we need to help the enemy find a location to go. As of now they are blind and wander aimlessly			
	while not selectedLocation:
		
		# if there are no valid locations, just hold still this turn
		if validLocations.size() == 0:
			selectedLocation = true
			break
		
		# otherwise generate a random choice from our valid locations
		var randNum = randi() % validLocations.size()
		
		# check to see if there is not a wall or foe in this position already
		# if nothing is there, it's a valid position and we can go there
		if map.checkPos(validLocations[randNum]) and not map.isFoeHere(validLocations[randNum]):
			desiredPos = validLocations[randNum]
			selectedLocation = true
		
		# otherwise remove this position
		else:
			validLocations.remove_at(randNum)
	
	# finally, adjust the grid location and move this enemy
	gridLocation = desiredPos
	self.position = Vector2(16*gridLocation[0], 16*gridLocation[1])
	
	speed = (randi() % 20) + 1
				
