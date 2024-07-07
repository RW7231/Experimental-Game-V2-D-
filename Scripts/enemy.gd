extends Sprite2D

var health
var AC
var attack
var defense

# special stat that determines when an enemy can take an action
# if it hits 0 the enemy can move, otherwise they must wait
var speed

var gridLocation

func setGridLocation(location):
	gridLocation = location
	
func getGridLocation():
	return gridLocation

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 5
	AC = 10
	attack = 1
	defense = 1
	# determine an initial speed value, something between 1 to 20
	speed = (randi() % 20) + 1
	

func takeDamage(amount):
	health -= (amount * (amount/defense))
	
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
				
