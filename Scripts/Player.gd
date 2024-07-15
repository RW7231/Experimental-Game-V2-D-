extends Node2D

var currentPosition = [2, 2]

var map

var health = 10.0
var maxHealth = 10.0
var attack = 1.0
var defense = 1.0
var AC = 10
var attackBonus = 3
var souls = 0

# this is a placeholder for now, higher values means slower player
var speed = 5

var validAction

var dead = false

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
	
	var baseData = {"health": health, "position": currentPosition}
	
	var saveData = JSON.stringify(baseData)
	
	var file = FileAccess.open("res://save.json", FileAccess.WRITE)
	
	file.store_line(saveData)
	
	file.close()
		
		
func Load():
	var file = FileAccess.open("res://save.json", FileAccess.READ)
	
	if file == null:
		Save()
		return null
	
	var content = JSON.parse_string(file.get_as_text())
	
	health = content["health"]
	currentPosition = content["position"]
	
	self.position = Vector2(16 * currentPosition[0], 16 * currentPosition[1])
	
	file.close()
	return content
	
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
	
	var damage = (amount * (amount/defense))
	
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
		
