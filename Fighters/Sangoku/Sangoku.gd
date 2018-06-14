extends "../Fighter.gd"

const gravity = 1500
const fall_max_speed = 1400

const jump_strength = 530
const double_jump_strength = 500

const walk_max_speed = 260
const walk_acceleration = 420
const walk_deceleration = 620

const run_max_speed = 480
const run_acceleration = 920
const run_deceleration = 1020

const air_max_speed = 260
const air_acceleration = 600
const air_deceleration = 900

func _physics_process(delta):
	self.udpate_input(delta)
	self.update_state(delta)
	self.update_velocity()

func update_state(delta):
	match self.state:
		# Move
		FighterState.stand: self.state_stand(delta)
		FighterState.crouch: self.state_crouch(delta)
		FighterState.crouch_to_stand: self.state_crouch_to_stand(delta)
		FighterState.walk: self.state_walk(delta)
		FighterState.walk_wall: self.state_walk_wall(delta)
		FighterState.walk_turn_around: self.state_walk_turn_around(delta)
		FighterState.run: self.state_run(delta)
		FighterState.run_wall: self.state_run_wall(delta)
		FighterState.run_turn_around: self.state_run_turn_around(delta)
		FighterState.jump: self.state_jump(delta)
		FighterState.fall: self.state_fall(delta)
		FighterState.fall_through : self.state_fall_through(delta)
		FighterState.fall_to_stand: self.state_fall_to_stand(delta)
		# Block
		FighterState.block_high: self.state_block_high(delta)
		FighterState.block_high_to_stand: self.state_block_high_to_stand(delta)
		FighterState.block_low: self.state_block_low(delta)
		FighterState.block_low_to_stand: self.state_block_low_to_stand(delta)
		# Ground attacks
		FighterState.neutral_attack: self.state_neutral_attack(delta)
		# Hit / Hurt
		FighterState.flinch: self.state_flinch(delta)
		FighterState.flinch_slide: self.state_flinch_slide(delta)
		FighterState.flinch_tumble: self.state_flinch_tumble(delta)
		FighterState.flinch_tumble_bounce: self.state_flinch_tumble_bounce(delta)
		FighterState.flinch_recover: self.state_flinch_recover(delta)

func set_state(state, prev_state = self.state):
	self.state = state
	match state:
		# Move
		FighterState.stand: self.pre_stand()
		FighterState.crouch: self.pre_crouch()
		FighterState.crouch_to_stand: self.pre_crouch_to_stand()
		FighterState.walk: self.pre_walk()
		FighterState.walk_wall: self.pre_walk_wall()
		FighterState.walk_turn_around: self.pre_walk_turn_around()
		FighterState.run: self.pre_run()
		FighterState.run_wall: self.pre_run_wall()
		FighterState.run_turn_around: self.pre_run_turn_around()
		FighterState.jump: self.pre_jump()
		FighterState.fall: self.pre_fall()
		FighterState.fall_through : self.pre_fall_through()
		FighterState.fall_to_stand: self.pre_fall_to_stand()
		# Block
		FighterState.block_high: self.pre_block_high()
		FighterState.block_high_to_stand: self.pre_block_high_to_stand()
		FighterState.block_low: self.pre_block_low()
		FighterState.block_low_to_stand: self.pre_block_low_to_stand()
		# Ground attacks
		FighterState.neutral_attack: self.pre_neutral_attack()
		# Hit / Hurt
		FighterState.flinch: self.pre_flinch()
		FighterState.flinch_slide: self.pre_flinch_slide()
		FighterState.flinch_tumble: self.pre_flinch_tumble()
		FighterState.flinch_tumble_bounce: self.pre_flinch_tumble_bounce()
		FighterState.flinch_recover: self.pre_flinch_recover()

########
# Move #
########

func pre_stand():
	self.jumps = 2
	$AnimationPlayer.play("1a - Stand")

func state_stand(delta):
	if not self.is_on_floor():
		self.jumps = 1
		self.set_state(FighterState.fall)
	elif self.input.down:
		self.set_state(FighterState.fall_through if self.is_on_one_way_platform() else FighterState.crouch)
	elif self.input.jump:
		self.set_state(FighterState.jump)
	elif self.input.block:
		self.set_state(FighterState.block_low if self.input.down else FighterState.block_high)
	elif self.input_direction != FighterDirection.none:
		if self.input.run:
			self.set_state(FighterState.run if self.direction == self.input_direction else FighterState.run_turn_around)
		else:
			self.set_state(FighterState.walk if self.direction == self.input_direction else FighterState.walk_turn_around)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, walk_deceleration * 2)

func pre_crouch():
	$AnimationPlayer.play("6a - Crouch")

func state_crouch(delta):
	if not self.is_on_floor():
		self.jumps = 1
		self.set_state(FighterState.fall)
	if not $AnimationPlayer.is_playing():
		if not self.input.down:
			self.set_state(FighterState.crouch_to_stand)
		elif self.input.block:
			self.set_state(FighterState.block_low)

func pre_crouch_to_stand():
	$AnimationPlayer.play_backwards("6a - Crouch")

func state_crouch_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)

func pre_walk():
	$AnimationPlayer.play("5a - Walk")

func state_walk(delta):
	if not self.is_on_floor():
		self.jumps = 1
		self.set_state(FighterState.fall)
	elif self.is_on_wall():
		self.set_state(FighterState.walk_wall)
	elif self.input.jump and self.jumps > 0:
		self.set_state(FighterState.jump)
	elif self.input.down and self.is_on_floor() and self.is_on_one_way_platform():
		self.set_state(FighterState.fall_through)
	elif self.input.run:
		self.set_state(FighterState.run)
	else:
		self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.direction, walk_acceleration, walk_deceleration, walk_max_speed)
		if self.get_velocity_direction() == FighterDirection.none:
			self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_walk_wall():
	$AnimationPlayer.play("9b - Run Wall")

func state_walk_wall(delta):
	if not self.is_on_floor():
		self.set_state(FighterState.fall)
	elif not self.is_on_wall():
		self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_walk_turn_around():
	$FrameTimer.wait_for(5)

func state_walk_turn_around(delta):
	if $FrameTimer.is_stopped():
		self.change_direction(-self.direction)
		self.set_state(FighterState.stand)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, walk_deceleration)

func pre_run():
	$AnimationPlayer.play("9a - Run")

func state_run(delta):
	if not self.is_on_floor():
		self.jumps = 1
		self.set_state(FighterState.fall)
	elif self.is_on_wall():
		self.set_state(FighterState.run_wall)
	elif self.input.jump and self.jumps > 0:
		self.set_state(FighterState.jump)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.direction, run_acceleration, run_deceleration, run_max_speed)
	if self.get_velocity_direction() == FighterDirection.none:
		self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_run_wall():
	self.set_state(FighterState.walk_wall)

func state_run_wall(delta):
	pass

func pre_run_turn_around():
	self.pre_walk_turn_around()

func state_run_turn_around(delta):
	self.state_walk_turn_around(delta)

func pre_jump():
	self.jumps -= 1
	self.velocity = Vector2(self.velocity.x, -jump_strength if self.jumps > 0 else -double_jump_strength)
	$FrameTimer.wait_for(15)
	$AnimationPlayer.play("2a - Jump")

func state_jump(delta):
	if self.velocity.y > -0:
		self.set_state(FighterState.fall)
	elif $FrameTimer.is_stopped() and self.input.jump and self.jumps > 0:
		if self.input_direction != self.direction:
			self.velocity = Vector2(0, self.velocity.y)
		self.set_state(FighterState.jump)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.input_direction, air_acceleration, air_deceleration, air_max_speed)
	if not self.input.jump_held or $FrameTimer.after_frame(5): # ignore gravity for 5 frames if jump is held
		self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_fall():
	self.velocity = Vector2(self.velocity.x, 0)
	$AnimationPlayer.play("3a - Fall")

func state_fall(delta):
	if self.is_on_floor():
		self.set_state(FighterState.fall_to_stand)
	elif self.input.jump and self.jumps > 0:
		if self.input_direction != self.direction:
			self.velocity = Vector2(0, self.velocity.y)
		self.set_state(FighterState.jump)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.input_direction, air_acceleration, air_deceleration, air_max_speed)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_fall_through():
	self.jumps = 1
	self.position = Vector2(self.position.x, self.position.y + 1)

func state_fall_through(delta):
	self.set_state(FighterState.fall)

func pre_fall_to_stand():
	$AnimationPlayer.play("3b - Fall Recovery")

func state_fall_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, walk_deceleration * 2)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

#########
# Block #
#########

func pre_block_high():
	$AnimationPlayer.play("4b - Block High")
 
func state_block_high(delta):
	if not $AnimationPlayer.is_playing():
		if not self.input.block:
			self.set_state(FighterState.block_high_to_stand)
		elif self.input.down:
			self.set_state(FighterState.block_low)

func pre_block_high_to_stand():
	$AnimationPlayer.play_backwards("4b - Block High")
 
func state_block_high_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		self.set_state(FighterState.stand if not self.input.block else FighterState.block_high)
 
func pre_block_low():
	$AnimationPlayer.play("4a - Block Low")
 
func state_block_low(delta):
	if not $AnimationPlayer.is_playing():
		if not self.input.block:
			self.set_state(FighterState.block_low_to_stand)
		elif not self.input.down:
			self.set_state(FighterState.block_high)
 
func pre_block_low_to_stand():
	$AnimationPlayer.play_backwards("4a - Block Low")
 
func state_block_low_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		if self.input.block:
			self.set_state(FighterState.block_low if self.input.down else FighterState.block_high)
		else:
			self.set_state(FighterState.stand)

##################
# Ground attacks #
##################

func pre_neutral_attack():
	pass

func state_neutral_attack(delta):
	pass

##########
# Flinch #
##########

func pre_flinch():
	pass

func state_flinch(delta):
	pass

func pre_flinch_slide():
	pass

func state_flinch_slide(delta):
	pass

func pre_flinch_tumble():
	pass

func state_flinch_tumble(delta):
	pass

func pre_flinch_tumble_bounce():
	pass

func state_flinch_tumble_bounce(delta):
	pass

func pre_flinch_recover():
	pass

func state_flinch_recover(delta):
	pass