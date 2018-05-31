extends KinematicBody2D

class FighterInput:
	var up = false
	var down = false
	var left = false
	var right = false
	
	var jump = false
	var grab = false
	var block = false
	var attack = false
	var attack_alt = false
	
	var taunt_1 = false
	var taunt_2 = false
	var taunt_3 = false
	var taunt_4 = false

enum FighterState {
	standing,
	blockinghigh,
	blockinghigh2standing,
	blockinglow,
	blockinglow2standing,
	jumping,
	jumping2standing
}

var input = FighterInput.new()
var state = FighterState.standing
var acc = 0.0
var origin = 0.0

func _process(delta):
	self.input.up = Input.is_action_pressed("ui_up")
	self.input.down = Input.is_action_pressed("ui_down")
	self.input.left = Input.is_action_pressed("ui_left")
	self.input.right = Input.is_action_pressed("ui_right")
	
	self.input.block = Input.is_action_pressed("player_1_block")
	self.input.attack = Input.is_action_pressed("player_1_attack")
	self.input.attack_alt = Input.is_action_pressed("player_1_attack_alt")
	
	match state:
		standing: self.state_standing(delta)
		blockinghigh: self.state_blockinghigh(delta)
		blockinghigh2standing: self.state_blockinghigh2standing(delta)
		blockinglow: self.state_blockinglow(delta)
		blockinglow2standing: self.state_blockinglow2standing(delta)
		jumping: self.state_jumping(delta)
		jumping2standing: self.state_jumping2standing(delta)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		standing: self.pre_standing()
		blockinghigh: self.pre_blockinghigh()
		blockinghigh2standing: self.pre_blockinghigh2standing()
		blockinglow: self.pre_blockinglow()
		blockinglow2standing: self.pre_blockinglow2standing()
		jumping: self.pre_jumping()
		jumping2standing: self.pre_jumping2standing()

func pre_standing():
	$AnimationPlayer.play("Standing")
	
func state_standing(delta):
	if self.input.block:
		self.set_state(FighterState.blockinglow if self.input.down else FighterState.blockinghigh)
	elif self.input.up:
		self.set_state(FighterState.jumping)

func pre_blockinghigh():
	$AnimationPlayer.play("BlockingHigh")
	
func state_blockinghigh(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if self.input.down:
				self.set_state(FighterState.blockinglow)
		else:
			self.set_state(FighterState.blockinghigh2standing)

func pre_blockinghigh2standing():
	$AnimationPlayer.play_backwards("BlockingHigh")

func state_blockinghigh2standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing if not self.input.block else FighterState.blockinghigh)

func pre_blockinglow():
	$AnimationPlayer.play("BlockingLow")
	
func state_blockinglow(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if not self.input.down:
				self.set_state(FighterState.blockinghigh)
		else:
			self.set_state(FighterState.blockinglow2standing)

func pre_blockinglow2standing():
	$AnimationPlayer.play_backwards("BlockingLow")
	
func state_blockinglow2standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing if not self.input.block else FighterState.blockinghigh)

func pre_jumping():
	self.acc = 0
	self.origin = self.position.y
	$AnimationPlayer.play("Jumping")
	
func state_jumping(delta):
	if self.position.y > self.origin:
		self.set_state(FighterState.jumping2standing)
		self.position = Vector2(self.position.x, self.origin)
	else:
		acc += 3 * delta
		self.move_and_slide(Vector2(0, -200 * cos(acc)))

func pre_jumping2standing():
	$AnimationPlayer.play_backwards("Jumping")
	
func state_jumping2standing(delta):
	if $AnimationPlayer.get_current_animation_position() <= 0.065:
		self.set_state(FighterState.standing)