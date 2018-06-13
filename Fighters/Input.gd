var player_index = 0

var up = false
var down = false
var left = false
var right = false

var jump = false
var jump_held = false

var grab = false
var block = false
var attack = false
var attack_alt = false

var taunt1 = false
var taunt2 = false
	
var debug_input = false

func _init(player_index):
	self.player_index = player_index

func update_input():
	self.up = Input.is_action_pressed("player_" + str(self.player_index) + "_up")
	self.down = Input.is_action_pressed("player_" + str(self.player_index) + "_down")
	self.left = Input.is_action_pressed("player_" + str(self.player_index) + "_left")
	self.right = Input.is_action_pressed("player_" + str(self.player_index) + "_right")
	
	self.jump = Input.is_action_just_pressed("player_" + str(self.player_index) + "_jump") or \
		Input.is_action_just_pressed("player_" + str(self.player_index) + "_up") # TODO: disable tap-to-jump
	self.jump_held = Input.is_action_pressed("player_" + str(self.player_index) + "_jump") or \
		Input.is_action_pressed("player_" + str(self.player_index) + "_up") # TODO: disable tap-to-jump
	
	self.block = Input.is_action_pressed("player_" + str(self.player_index) + "_block")
	self.attack = Input.is_action_pressed("player_" + str(self.player_index) + "_attack")
	self.attack_alt = Input.is_action_pressed("player_" + str(self.player_index) + "_attack_alt")
	
	self.taunt1 = Input.is_action_pressed("player_" + str(self.player_index) + "_taunt1")
	self.taunt2 = Input.is_action_pressed("player_" + str(self.player_index) + "_taunt2")
	
	self.debug_input = Input.is_action_pressed("player_" + str(self.player_index) + "_debug")