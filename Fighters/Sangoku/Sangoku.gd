extends KinematicBody2D

enum FighterState {
	# Move
	stand,
	crouch,
	crouch_to_stand,
	turn_around,
	walk,
	jump,
	fall,
	double_jump,
	double_fall,
	fall_to_stand,
	# Block
	block_high,
	block_high_to_stand,
	block_low,
	block_low_to_stand,
	# Ground attacks
	dash_attack,
	neutral_attack,
	# Tilt attacks
	up_tilt,
	down_tilt,
	forward_tilt,
	# Smash attacks
	up_smash,
	down_smash,
	forward_smash,
	# Aerial attacks
	up_aerial,
	down_aerial,
	back_aerial,
	grab_aerial,
	forward_aerial,
	neutral_aerial,
	# Throws
	grab,
	throw,
	# Specials
	up_special,
	down_special,
	side_special,
	neutral_special
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
var state = FighterState.double_fall
var velocity = Vector2(0, 0)
var grounded = false
var direction = FighterDirection.left

const gravity = 1200
const fall_speed = 1400
const jump_strength = 600
const double_jump_strength = 560

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
		# Move
		FighterState.stand: self.state_stand(delta)
		FighterState.crouch: self.state_crouch(delta)
		FighterState.crouch_to_stand: self.state_crouch_to_stand(delta)
		FighterState.turn_around: self.state_turn_around(delta)
		FighterState.walk: self.state_walk(delta)
		FighterState.jump: self.state_jump(delta)
		FighterState.fall: self.state_fall(delta)
		FighterState.double_jump: self.state_double_jump(delta)
		FighterState.double_fall: self.state_double_fall(delta)
		FighterState.fall_to_stand: self.state_fall_to_stand(delta)
		# Block
		FighterState.block_high: self.state_block_high(delta)
		FighterState.block_high_to_stand: self.state_block_high_to_stand(delta)
		FighterState.block_low: self.state_block_low(delta)
		FighterState.block_low_to_stand: self.state_block_low_to_stand(delta)
		# Ground attacks
		FighterState.neutral_attack: self.state_neutral_attack(delta)
	
	# Update position
	self.velocity = self.move_and_slide(self.velocity, self.ground_vector)
	
	# TODO: Remove wrapping
	self.position.x = fposmod(self.position.x, 1280)
	self.position.y = fposmod(self.position.y, 720)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		# Move
		FighterState.stand: self.pre_stand()
		FighterState.crouch: self.pre_crouch()
		FighterState.crouch_to_stand: self.pre_crouch_to_stand()
		FighterState.turn_around: self.pre_turn_around()
		FighterState.walk: self.pre_walk()
		FighterState.jump: self.pre_jump()
		FighterState.fall: self.pre_fall()
		FighterState.double_jump: self.pre_double_jump()
		FighterState.double_fall: self.pre_double_fall()
		FighterState.fall_to_stand: self.pre_fall_to_stand()
		# Block
		FighterState.block_high: self.pre_block_high()
		FighterState.block_high_to_stand: self.pre_block_high_to_stand()
		FighterState.block_low: self.pre_block_low()
		FighterState.block_low_to_stand: self.pre_block_low_to_stand()
		# Ground attacks
		FighterState.neutral_attack: self.pre_neutral_attack()

func handle_fall(delta):
	if not grounded:
		self.set_state(FighterState.fall)

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
	self.velocity.y = min(self.velocity.y + self.gravity * delta, fall_speed)

func pre_stand():
	$AnimationPlayer.play("1a - Stand")

# Move

func state_stand(delta):
	self.handle_fall(delta)
	self.decelerate_horizontal(delta)
	if ((self.direction == FighterDirection.left and self.input.right and not self.input.left) or
		(self.direction == FighterDirection.right and self.input.left and not self.input.right)):
		self.set_state(FighterState.turn_around)
	elif (self.input.left and not self.input.right) or (self.input.right and not self.input.left):
		self.set_state(FighterState.walk)
	elif self.input.block and self.velocity.x == 0:
		self.set_state(FighterState.block_low if self.input.down else FighterState.block_high)
	elif self.input.down and self.velocity.x == 0:
		self.set_state(FighterState.crouch)
	elif self.input.attack and self.velocity.x == 0:
		self.set_state(FighterState.neutral_attack)
	elif self.input.jump and self.grounded:
		self.set_state(FighterState.jump)

func pre_crouch():
	$AnimationPlayer.play("6a - Crouch")

func state_crouch(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			self.set_state(FighterState.block_low)
		elif not self.input.down:
			self.set_state(FighterState.crouch_to_stand)

func pre_crouch_to_stand():
	$AnimationPlayer.play_backwards("6a - Crouch")

func state_crouch_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)

func pre_turn_around():
	$Timer.set_wait_time(0.1)
	$Timer.start()

func state_turn_around(delta):
	if $Timer.is_stopped():
		$Flip.scale.x = self.direction
		self.direction *= -1
		self.set_state(FighterState.stand)

func pre_walk():
	$AnimationPlayer.play("5a - Walk")

func state_walk(delta):
	self.handle_fall(delta)
	self.accelerate_horizontal(delta, true)
	self.decelerate_horizontal(delta)
	if self.input.jump and self.grounded:
		self.set_state(FighterState.jump)
	elif self.velocity.x == 0:
		self.set_state(FighterState.stand)

func pre_jump():
	self.velocity.y = -self.jump_strength
	$AnimationPlayer.play("2a - Jump")

func state_jump(delta):
	self.accelerate_vertical(delta)
	self.accelerate_horizontal(delta)
	self.decelerate_horizontal(delta)
	if self.velocity.y > 0:
		self.set_state(FighterState.fall)

func pre_fall():
	$AnimationPlayer.play("3a - Fall")

func state_fall(delta):
	if self.is_on_floor():
		self.set_state(FighterState.fall_to_stand)
	elif self.input.jump:
		self.set_state(FighterState.double_jump)
	else:
		self.accelerate_vertical(delta)
		self.accelerate_horizontal(delta)
		self.decelerate_horizontal(delta)

func pre_double_jump():
	self.velocity.y = -self.double_jump_strength
	$AnimationPlayer.play("2a - Jump")

func state_double_jump(delta):
	self.accelerate_vertical(delta)
	self.accelerate_horizontal(delta)
	self.decelerate_horizontal(delta)
	if self.velocity.y > 0:
		self.set_state(FighterState.double_fall)

func pre_double_fall():
	$AnimationPlayer.play("3a - Fall")

func state_double_fall(delta):
	if self.is_on_floor():
		self.set_state(FighterState.fall_to_stand)
	else:
		self.accelerate_vertical(delta)
		self.accelerate_horizontal(delta)
		self.decelerate_horizontal(delta)

func pre_fall_to_stand():
	$AnimationPlayer.play("3b - Fall Recovery")

func state_fall_to_stand(delta):
	self.decelerate_horizontal(delta, true)
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)

# Block

func pre_block_high():
	$AnimationPlayer.play("4b - Block High")

func state_block_high(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if self.input.down:
				self.set_state(FighterState.block_low)
		else:
			self.set_state(FighterState.block_high_to_stand)

func pre_block_high_to_stand():
	$AnimationPlayer.play_backwards("4b - Block High")

func state_block_high_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand if not self.input.block else FighterState.block_high)

func pre_block_low():
	$AnimationPlayer.play("4a - Block Low")

func state_block_low(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			if not self.input.down:
				self.set_state(FighterState.block_high)
		else:
			self.set_state(FighterState.block_low_to_stand)

func pre_block_low_to_stand():
	$AnimationPlayer.play_backwards("4a - Block Low")

func state_block_low_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand if not self.input.block else FighterState.block_high)

# Ground attacks

func pre_neutral_attack():
	$AnimationPlayer.play("7a - Ground neutral")

func state_neutral_attack(delta):
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation_position >= 0.1 and $AnimationPlayer.current_animation_position <= 0.2:
		$AnimationPlayer.set_speed_scale(0.3)
	else:
		$AnimationPlayer.set_speed_scale(1)
	if not $AnimationPlayer.is_playing():
		if self.input.attack:
			self.set_state(FighterState.neutral_attack)
		else:
			self.set_state(FighterState.stand)