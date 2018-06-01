extends KinematicBody2D

enum FighterState {
	standing,
	blockinghigh,
	blockinghigh2standing,
	blockinglow,
	blockinglow2standing,
	jumping,
	falling,
	falling2standing,
}

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

var input = FighterInput.new()
var state = FighterState.standing
var velocity = Vector2(0.0, 0.0)

const gravity = 500
const jump_strength = 240

const ground_vector = Vector2(0.0, -1.0)

func _process(delta):
	# Set inputs
	self.input.up = Input.is_action_pressed("ui_up")
	self.input.down = Input.is_action_pressed("ui_down")
	self.input.left = Input.is_action_pressed("ui_left")
	self.input.right = Input.is_action_pressed("ui_right")
	
	self.input.block = Input.is_action_pressed("player_1_block")
	self.input.attack = Input.is_action_pressed("player_1_attack")
	self.input.attack_alt = Input.is_action_pressed("player_1_attack_alt")
	
	# Update current state
	match state:
		standing: self.state_standing(delta)
		blockinghigh: self.state_blockinghigh(delta)
		blockinghigh2standing: self.state_blockinghigh2standing(delta)
		blockinglow: self.state_blockinglow(delta)
		blockinglow2standing: self.state_blockinglow2standing(delta)
		jumping: self.state_jumping(delta)
		falling: self.state_falling(delta)
		falling2standing: self.state_falling2standing(delta)
	
	# Update position
	self.velocity = self.move_and_slide(self.velocity, self.ground_vector)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		standing: self.pre_standing()
		blockinghigh: self.pre_blockinghigh()
		blockinghigh2standing: self.pre_blockinghigh2standing()
		blockinglow: self.pre_blockinglow()
		blockinglow2standing: self.pre_blockinglow2standing()
		jumping: self.pre_jumping()
		falling: self.pre_falling()
		falling2standing: self.pre_falling2standing()

func pre_standing():
	$AnimationPlayer.play("1a - Standing")
	
func state_standing(delta):
	if self.input.block:
		self.set_state(FighterState.blockinglow if self.input.down else FighterState.blockinghigh)
	elif self.input.up:
		self.set_state(FighterState.jumping)

func pre_blockinghigh():
	$AnimationPlayer.play("4b - Blocking High")
	
func state_blockinghigh(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if self.input.down:
				self.set_state(FighterState.blockinglow)
		else:
			self.set_state(FighterState.blockinghigh2standing)

func pre_blockinghigh2standing():
	$AnimationPlayer.play_backwards("4b - Blocking High")

func state_blockinghigh2standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing if not self.input.block else FighterState.blockinghigh)

func pre_blockinglow():
	$AnimationPlayer.play("4a - Blocking Low")
	
func state_blockinglow(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if not self.input.down:
				self.set_state(FighterState.blockinghigh)
		else:
			self.set_state(FighterState.blockinglow2standing)

func pre_blockinglow2standing():
	$AnimationPlayer.play_backwards("4a - Blocking Low")

func state_blockinglow2standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing if not self.input.block else FighterState.blockinghigh)

func pre_jumping():
	self.velocity.y = -self.jump_strength
	$AnimationPlayer.play("2a - Jumping")

func state_jumping(delta):
	self.velocity.y += self.gravity * delta
	if self.velocity.y > 0:
		self.set_state(falling)

func pre_falling():
	$AnimationPlayer.play("3a - Falling")

func state_falling(delta):
	if self.is_on_floor():
		self.set_state(FighterState.falling2standing)
	else:
		self.velocity.y += self.gravity * delta

func pre_falling2standing():
	$AnimationPlayer.play("3b - Falling Recovery")

func state_falling2standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing)