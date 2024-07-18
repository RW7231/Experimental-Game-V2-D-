extends Node2D

var currentPosition = [2, 2]

var map

var level = 1
var vigor = 10
var str = 10
var dex = 10
var intelligence = 10
var faith = 10

var strBonus
var dexBonus
var intBonus
var faithBonus

var health
var maxHealth

var attack
var defense
var AC
var attackBonus
var souls = 0

# this is a placeholder for now, higher values means slower player
var speed

var validAction

var dead = false
var recalcHealth = false

func _ready():		
	Load()
	healthBarChange()

# get_parent is a bad function that barely works half the time
# I have to run it in _process to ensure that it actually gets the map	
func _process(_delta):
	if map == null:
		map = self.get_parent()
	else:
		set_process(false)
		
func Save():
	
	if dead:
		return
	
	var baseData = {"health": health, "position": currentPosition, "stats": [vigor, str, dex, intelligence, faith]}
	
	var saveData = JSON.stringify(baseData)
	
	var file = FileAccess.open("res://save.json", FileAccess.WRITE)
	
	file.store_line(saveData)
	
	file.close()
		
		
func Load():
	var file = FileAccess.open("res://save.json", FileAccess.READ)
	
	if file == null:
		Save()
		recalcHealth = true
		playerSetup()
		return null
	
	var content = JSON.parse_string(file.get_as_text())
	
	health = content["health"]
	currentPosition = content["position"]
	var stats = content["stats"]
	
	vigor = stats[0]
	str = stats[1]
	dex = stats[2]
	intelligence = stats[3]
	faith = stats[4]
	
	self.position = Vector2(16 * currentPosition[0], 16 * currentPosition[1])
	
	file.close()
	playerSetup()
	return content
	
func playerSetup():
	# determine health, it is a complex polynomial problem
	# it focuses on the player being able to have more health early to a softcap of 40
	maxHealth = (level*2) + 100
	for i in vigor:
		maxHealth += 25 - (pow((i-40), 2)/150)
	
	maxHealth = int(maxHealth)
	
	if recalcHealth:
		health = maxHealth
		recalcHealth = false
	
	# the player's bonuses are based on stats
	# these bonuses will scale from 0 to 1, reaching 0.8 at about 40 and 1 at 100
	strBonus = (log(str)/log(10))/2
	dexBonus = (log(dex)/log(10))/2
	intBonus = (log(intelligence)/log(10))/2
	faithBonus = (log(faith)/log(10))/2
	
	# this will be the attack for the player's fists since no weapons exist
	attack = int(10 + (10*strBonus) + (10*strBonus))
	
	attackBonus = int(str/10 + dex/10)
	
	defense = 3 * str
	
	AC = 10 + int(dex/10)
	
	speed = 5 - int(dex/10)
	
	if speed < 1:
		speed = 1
	
func eraseSave():
	DirAccess.remove_absolute("res://save.json")
	DirAccess.remove_absolute("res://mapData.json")
	map.noSaveAllowed()
	
	
		
func setStartPos(value):
	currentPosition = [value, value]
	self.position = Vector2(value * 16, value * 16)
	Save()
	
func getPosition():
	return currentPosition
	
func takeDamage(amount, bonus):
	if (((randi() % 20) + 1) + bonus) < AC:
		print("An Enemy tried to attack you but missed")
		return
	
	var damage = int(amount * (amount/defense))
	
	health -= damage
	healthBarChange()
	print("You have been hit for ", damage)
	
	Save()
	
	if health <= 0:
		eraseSave()
		print("GAME OVER")
		dead = true
		
func healthBarChange():
	var healthbar = get_node("CanvasLayer/HealthBar")
	healthbar.value = health*10/maxHealth
	
	
func gainSouls(amount):
	souls += amount
	
func loseSouls(amount):
	souls -= amount

# we want to handle player movement in the grid system, 
func _input(event):
	
	# if the player is dead, no more inputs are done
	if dead:
		return
	
	# if a valid action is taken take a number of turns equal to speed
	validAction = false
	
	# check the player direction, if the position is valid, move the player there
	if event.is_action_pressed("Up"):
		var desiredPos = [currentPosition[0], currentPosition[1]-1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(0, -16)
			validAction = true
			Save()
		
	if event.is_action_pressed("Down"):
		var desiredPos = [currentPosition[0], currentPosition[1]+1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(0, 16)
			validAction = true
			Save()
		
	if event.is_action_pressed("Left"):
		var desiredPos = [currentPosition[0]-1, currentPosition[1]]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(-16, 0)
			validAction = true
			Save()
		
		
	if event.is_action_pressed("Right"):
		var desiredPos = [currentPosition[0] + 1, currentPosition[1]]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(16, 0)
			validAction = true
			Save()
			
	if event.is_action_pressed("UpLeft"):
		var desiredPos = [currentPosition[0]-1, currentPosition[1]-1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(-16, -16)
			validAction = true
			Save()
			
	if event.is_action_pressed("UpRight"):
		var desiredPos = [currentPosition[0]+1, currentPosition[1]-1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(16, -16)
			validAction = true
			Save()
			
	if event.is_action_pressed("DownLeft"):
		var desiredPos = [currentPosition[0]-1, currentPosition[1]+1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(-16, 16)
			validAction = true
			Save()
			
	if event.is_action_pressed("DownRight"):
		var desiredPos = [currentPosition[0]+1, currentPosition[1]+1]
		
		# check to see if there is an enemy here, if so attack without moving
		var possibleFoe = map.isFoeHere(desiredPos)
		if possibleFoe != null:
			map.attackFoe(possibleFoe)
			validAction = true
			Save()
		
		elif map.checkPos(desiredPos):
			currentPosition = desiredPos
			self.position += Vector2(16, 16)
			validAction = true
			Save()
	
	# the only exception is the "stay" move which only takes 1 turn		
	if event.is_action_pressed("Stay"):
		map.turn()
		map.checkForExit(currentPosition)
	
	# when a valid action is detected, do a number of turns	
	if validAction:
		for i in range(0, speed):
			map.turn()
		
