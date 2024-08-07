extends Node2D

var levelUpMenu = load("res://Prefabs/levelup_menu.tscn")

var currentPosition = [2, 2]

var map

# player base stats
var level = 1
var vigor = 10
var strength = 10
var dex = 10
var intelligence = 10
var faith = 10

# player attack bonuses
var strBonus
var dexBonus
var intBonus
var faithBonus

# player health
var health
var maxHealth

# extra player stats
var attack
var defense
var AC
var attackBonus
var souls = 0
var requiredSouls = 0

# this is a placeholder for now, higher values means slower player
var speed

var validAction

var dead = false
var recalcHealth = false
var menuOpen = false

func _ready():		
	Load()
	healthBarChange()
	changeSouls()

# get_parent is a bad function that barely works half the time
# I have to run it in _process to ensure that it actually gets the map	
func _process(_delta):
	if map == null:
		map = self.get_parent()
	else:
		set_process(false)
		
func Save():
	
	# this is a little catch to ensure that once the player is dead, their save stays deleted
	if dead:
		return
	
	# we want to save the player's current health, their position in the map, their stats, and their soul count
	var baseData = {"health": health, "position": currentPosition, "level": level, "stats": [vigor, strength, dex, intelligence, faith], "souls": souls}
	
	# convert this into a valid JSON object and save
	var saveData = JSON.stringify(baseData)
	
	var file = FileAccess.open("res://save.json", FileAccess.WRITE)
	
	file.store_line(saveData)
	
	file.close()
		
		
func Load():
	var file = FileAccess.open("res://save.json", FileAccess.READ)
	
	if file == null:
		# if there is no save then we must make one
		Save()
		recalcHealth = true
		playerSetup()
		return null
	
	var content = JSON.parse_string(file.get_as_text())
	
	health = content["health"]
	currentPosition = content["position"]
	var stats = content["stats"]
	souls = content["souls"]
	level = content["level"]
	
	vigor = stats[0]
	strength = stats[1]
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
	
	# if there is a need to recalculate health either through a level up or new save, set health to maxHealth
	if recalcHealth:
		health = maxHealth
		recalcHealth = false
	
	# the player's bonuses are based on stats
	# these bonuses will scale from 0 to 1, reaching 0.8 at about 40 and 1 at 100
	strBonus = (log(strength)/log(10))/2
	dexBonus = (log(dex)/log(10))/2
	intBonus = (log(intelligence)/log(10))/2
	faithBonus = (log(faith)/log(10))/2
	
	# this will be the attack for the player's fists since no weapons exist
	attack = int(10 + (10*strBonus) + (10*strBonus))
	
	# this increases the player's chance to hit, every 10 levels in str or dex increases this by 1
	attackBonus = int(strength/10 + dex/10)
	
	defense = 3 * strength
	
	# very similar to DND, increase AC with dexterity
	AC = 10 + int(dex/10)
	
	# at 40 dex or higher the player will always move at their top speed
	speed = 5 - int(dex/10)
	
	if speed < 1:
		speed = 1
		
	requiredSouls = int((pow(level, 3)/50) + (3 * pow(level, 2)) + (50 * level))
	Save()

# when the player dies, erase save and map data	
func eraseSave():
	DirAccess.remove_absolute("res://save.json")
	DirAccess.remove_absolute("res://mapData.json")
	map.noSaveAllowed()
	
	
# when a map is created, we must set the player's starting position		
func setStartPos(value):
	currentPosition = [value, value]
	self.position = Vector2(value * 16, value * 16)
	Save()

# return the player's current position	
func getPosition():
	return currentPosition

# when a monster attacks, roll to see if the player is hit first, then take damage	
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

# change the healthbar		
func healthBarChange():
	var healthbar = get_node("CanvasLayer/HealthBar")
	healthbar.value = health*100/maxHealth
	
func changeSouls():
	var soulCounter = get_node("CanvasLayer/Soul Counter")
	soulCounter.text = str(souls)
	
	
func gainSouls(amount):
	souls += amount
	changeSouls()
	
func loseSouls(amount):
	souls -= amount
	changeSouls()
	
func soulCheck():
	return souls >= requiredSouls
	
func bonfire():
	if map.checkForBonfire(currentPosition):
		health = maxHealth
		menuOpen = true
		var canvas = get_node("CanvasLayer")
		var levelUp = levelUpMenu.instantiate()
		canvas.add_child(levelUp)
		
		updateCost()
		
		healthBarChange()
		
func updateCost():
	var menuCost = get_node("CanvasLayer/LevelupMenu/SoulCost")
	menuCost.text = str("Cost to level up: ", requiredSouls)
		
func gainLevel(stat):
	if not soulCheck():
		return
		
	level += 1
	
	match stat:
		1:
			vigor += 1
			recalcHealth = true
		2:
			strength += 1
		3:
			dex += 1
		4:
			intelligence += 1
		5:
			faith += 1
	
	loseSouls(requiredSouls)
	playerSetup()
	updateCost()
		

# we want to handle player movement in the grid system, 
func _input(event):
	
	# if the player is dead or a menu is open, no more inputs are done
	if dead or menuOpen:
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
		bonfire()
		map.checkForExit(currentPosition)
	
	# when a valid action is detected, do a number of turns	
	if validAction:
		for i in range(0, speed):
			map.turn()
		
