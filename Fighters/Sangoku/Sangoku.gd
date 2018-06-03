extends KinematicBody2D

enum FighterState {
	standing,
	crouching,
	crouching_to_standing,
	turning,
	walking,
	blockinghigh,
	blockinghigh_to_standing,
	blockinglow,
	blockinglow_to_standing,
	jumping,
	falling,
	jumping2,
	falling2,
	falling_to_standing,
}

enum FighterDirection {
	left = -1,
	right = 1
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
	
	var taunt1 = false
	var taunt2 = false

var input = FighterInput.new()
var state = FighterState.falling2
var velocity = Vector2(0, 0)
var grounded = false
var direction = FighterDirection.left

const gravity = 1200
const jump_strength = 600
const jump2_strength = 560

const walk_speed = 260
const walk_acceleration = 420
const walk_deceleration = 620

const ground_vector = Vector2(0, -1)

func _physics_process(delta):
	# Set inputs
	self.input.up = Input.is_action_pressed("player_1_up")
	self.input.down = Input.is_action_pressed("player_1_down")
	self.input.left = Input.is_action_pressed("player_1_left")
	self.input.right = Input.is_action_pressed("player_1_right")
	
	self.input.jump = Input.is_action_just_pressed("player_1_jump") or Input.is_action_just_pressed("player_1_up")
	self.input.block = Input.is_action_pressed("player_1_block")
	self.input.attack = Input.is_action_pressed("player_1_attack")
	self.input.attack_alt = Input.is_action_pressed("player_1_attack_alt")
	
	self.input.taunt1 = Input.is_action_pressed("player_1_taunt1")
	self.input.taunt2 = Input.is_action_pressed("player_1_taunt2")
	
	# Set grounded
	self.grounded = self.test_move(self.transform, Vector2(0, 1))
	
	# Update current state
	match state:
		FighterState.standing: self.state_standing(delta)
		FighterState.crouching: self.state_crouching(delta)
		FighterState.crouching_to_standing: self.state_crouching_to_standing(delta)
		FighterState.turning: self.state_turning(delta)
		FighterState.walking: self.state_walking(delta)
		FighterState.blockinghigh: self.state_blockinghigh(delta)
		FighterState.blockinghigh_to_standing: self.state_blockinghigh_to_standing(delta)
		FighterState.blockinglow: self.state_blockinglow(delta)
		FighterState.blockinglow_to_standing: self.state_blockinglow_to_standing(delta)
		FighterState.jumping: self.state_jumping(delta)
		FighterState.falling: self.state_falling(delta)
		FighterState.jumping2: self.state_jumping2(delta)
		FighterState.falling2: self.state_falling2(delta)
		FighterState.falling_to_standing: self.state_falling_to_standing(delta)
	
	# Update position
	self.velocity = self.move_and_slide(self.velocity, self.ground_vector)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		FighterState.standing: self.pre_standing()
		FighterState.crouching: self.pre_crouching()
		FighterState.crouching_to_standing: self.pre_crouching_to_standing()
		FighterState.turning: self.pre_turning()
		FighterState.walking: self.pre_walking()
		FighterState.blockinghigh: self.pre_blockinghigh()
		FighterState.blockinghigh_to_standing: self.pre_blockinghigh_to_standing()
		FighterState.blockinglow: self.pre_blockinglow()
		FighterState.blockinglow_to_standing: self.pre_blockinglow_to_standing()
		FighterState.jumping: self.pre_jumping()
		FighterState.falling: self.pre_falling()
		FighterState.jumping2: self.pre_jumping2()
		FighterState.falling2: self.pre_falling2()
		FighterState.falling_to_standing: self.pre_falling_to_standing()

func handle_falling(delta):
	if not grounded:
		self.set_state(FighterState.falling)

func accelerate_horizontal(delta, restrict_direction = false):
	if self.input.left and not self.input.right and (not restrict_direction or self.direction == FighterDirection.left):
		self.velocity.x = clamp(self.velocity.x - self.walk_acceleration * delta, -self.walk_speed, self.walk_speed)
	elif self.input.right and not self.input.left and (not restrict_direction or self.direction == FighterDirection.right):
		self.velocity.x = clamp(self.velocity.x + self.walk_acceleration * delta, -self.walk_speed, self.walk_speed)

func decelerate_horizontal(delta, force = false):
	var modifier = 1 if not force else 2
	if self.velocity.x < 0 and (force or (not self.input.left or self.input.right)):
		self.velocity.x = clamp(self.velocity.x + self.walk_deceleration * modifier * delta, -self.walk_speed, 0)
	elif self.velocity.x > 0 and (force or (not self.input.right or self.input.left)):
		self.velocity.x = clamp(self.velocity.x - self.walk_deceleration * modifier * delta, 0, self.walk_speed)

func accelerate_vertical(delta):
	self.velocity.y += self.gravity * delta

func pre_standing():
	$AnimationPlayer.play("1a - Standing")

func state_standing(delta):
	self.handle_falling(delta)
	self.decelerate_horizontal(delta)
	if ((self.direction == FighterDirection.left and self.input.right and not self.input.left) or
		(self.direction == FighterDirection.right and self.input.left and not self.input.right)):
		self.set_state(FighterState.turning)
	elif (self.input.left and not self.input.right) or (self.input.right and not self.input.left):
		self.set_state(FighterState.walking)
	elif self.input.block and self.velocity.x == 0:
		self.set_state(FighterState.blockinglow if self.input.down else FighterState.blockinghigh)
	elif self.input.down:
		self.set_state(FighterState.crouching)
	elif self.input.jump and self.grounded:
		self.set_state(FighterState.jumping)

func pre_crouching():
	$AnimationPlayer.play("6a - Crouching")

func state_crouching(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			self.set_state(FighterState.blockinglow)
		elif not self.input.down:
			self.set_state(FighterState.crouching_to_standing)

func pre_crouching_to_standing():
	$AnimationPlayer.play_backwards("6a - Crouching")

func state_crouching_to_standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing)

func pre_turning():
	$Timer.set_wait_time(0.1)
	$Timer.start()

func state_turning(delta):
	if $Timer.is_stopped():
		$Flip.scale.x = self.direction
		self.direction *= -1
		self.set_state(FighterState.standing)

func pre_walking():
	$AnimationPlayer.play("5a - Walking")

func state_walking(delta):
	self.handle_falling(delta)
	self.accelerate_horizontal(delta, true)
	self.decelerate_horizontal(delta)
	if self.input.jump and self.grounded:
		self.set_state(FighterState.jumping)
	elif self.velocity.x == 0:
		self.set_state(FighterState.standing)

func pre_blockinghigh():
	$AnimationPlayer.play("4b - Blocking High")

func state_blockinghigh(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if self.input.down:
				self.set_state(FighterState.blockinglow)
		else:
			self.set_state(FighterState.blockinghigh_to_standing)

func pre_blockinghigh_to_standing():
	$AnimationPlayer.play_backwards("4b - Blocking High")

func state_blockinghigh_to_standing(delta):
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
			self.set_state(FighterState.blockinglow_to_standing)

func pre_blockinglow_to_standing():
	$AnimationPlayer.play_backwards("4a - Blocking Low")

func state_blockinglow_to_standing(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing if not self.input.block else FighterState.blockinghigh)

func pre_jumping():
	self.velocity.y = -self.jump_strength
	$AnimationPlayer.play("2a - Jumping")

func state_jumping(delta):
	self.accelerate_vertical(delta)
	self.accelerate_horizontal(delta)
	self.decelerate_horizontal(delta)
	if self.velocity.y > 0:
		self.set_state(FighterState.falling)

func pre_falling():
	$AnimationPlayer.play("3a - Falling")

func state_falling(delta):
	if self.is_on_floor():
		self.set_state(FighterState.falling_to_standing)
	elif self.input.jump:
		self.set_state(FighterState.jumping2)
	else:
		self.accelerate_vertical(delta)
		self.accelerate_horizontal(delta)
		self.decelerate_horizontal(delta)

func pre_jumping2():
	self.velocity.y = -self.jump2_strength
	$AnimationPlayer.play("2a - Jumping")

func state_jumping2(delta):
	self.accelerate_vertical(delta)
	self.accelerate_horizontal(delta)
	self.decelerate_horizontal(delta)
	if self.velocity.y > 0:
		self.set_state(FighterState.falling2)

func pre_falling2():
	$AnimationPlayer.play("3a - Falling")

func state_falling2(delta):
	if self.is_on_floor():
		self.set_state(FighterState.falling_to_standing)
	else:
		self.accelerate_vertical(delta)
		self.accelerate_horizontal(delta)
		self.decelerate_horizontal(delta)

func pre_falling_to_standing():
	$AnimationPlayer.play("3b - Falling Recovery")

func state_falling_to_standing(delta):
	self.decelerate_horizontal(delta, true)
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.standing)