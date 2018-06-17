extends "../Fighter.gd"

const gravity = 1500
const fall_max_speed = 1400

const jump_strength = 460
const double_jump_strength = 460

const air_max_speed = 260
const run_max_speed = 480
const walk_max_speed = 260

const air_acceleration = 600
const run_acceleration = 920
const walk_acceleration = 520

const air_deceleration = 900
const run_deceleration = 1020
const walk_deceleration = 720
const block_deceleration = 720
const stand_deceleration = 720
const crouch_deceleration = 720

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
		FighterState.helpless: self.state_helpless(delta)
		# Block
		FighterState.block: self.state_block(delta)
		FighterState.block_to_stand: self.state_block_to_stand(delta)
		FighterState.block_roll: self.state_block_roll(delta)
		FighterState.block_spot_dodge: self.state_block_spot_dodge(delta)
		FighterState.block_airborne_dodge: self.state_block_airborne_dodge(delta)
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
	self.state_prev = prev_state
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
		FighterState.helpless: self.pre_helpless()
		# Block
		FighterState.block: self.pre_block()
		FighterState.block_to_stand: self.pre_block_to_stand()
		FighterState.block_roll: self.pre_block_roll()
		FighterState.block_spot_dodge: self.pre_block_spot_dodge()
		FighterState.block_airborne_dodge: self.pre_block_airborne_dodge()
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
	$AnimationPlayer.play("Stand")

func state_stand(delta):
	if not self.is_on_floor():
		self.jumps = 1
		return self.set_state(FighterState.fall)
	elif self.input.down:
		return self.set_state(FighterState.fall_through if self.is_on_one_way_platform() else FighterState.crouch)
	elif self.input.jump:
		return self.set_state(FighterState.jump)
	elif self.input.block:
		return self.set_state(FighterState.block_low if self.input.down else FighterState.block)
	elif self.input_direction != FighterDirection.none:
		if self.input.run:
			return self.set_state(FighterState.run if self.direction == self.input_direction else FighterState.run_turn_around)
		else:
			return self.set_state(FighterState.walk if self.direction == self.input_direction else FighterState.walk_turn_around)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, stand_deceleration)

func pre_crouch():
	$AnimationPlayer.play("Crouch")

func state_crouch(delta):
	if not self.is_on_floor():
		self.jumps = 1
		return self.set_state(FighterState.fall)
	if not $AnimationPlayer.is_playing():
		if not self.input.down:
			return self.set_state(FighterState.crouch_to_stand)
		elif self.input.block:
			return self.set_state(FighterState.block)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, crouch_deceleration)

func pre_crouch_to_stand():
	$AnimationPlayer.play_backwards("Crouch")

func state_crouch_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		return self.set_state(FighterState.stand)

func pre_walk():
	$AnimationPlayer.play("Walk")

func state_walk(delta):
	if not self.is_on_floor():
		self.jumps = 1
		return self.set_state(FighterState.fall)
	elif self.is_on_wall():
		return self.set_state(FighterState.walk_wall)
	elif self.input.jump and self.jumps > 0:
		return self.set_state(FighterState.jump)
	elif self.input.down and self.is_on_floor() and self.is_on_one_way_platform():
		return self.set_state(FighterState.fall_through)
	elif self.input.run:
		return self.set_state(FighterState.run)
	else:
		self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.direction, walk_acceleration, walk_deceleration, walk_max_speed)
		if self.get_velocity_direction() == FighterDirection.none:
			return self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_walk_wall():
	$AnimationPlayer.play("Run Wall")

func state_walk_wall(delta):
	if not self.is_on_floor():
		return self.set_state(FighterState.fall)
	elif not self.is_on_wall():
		return self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_walk_turn_around():
	$FrameTimer.wait_for(3)

func state_walk_turn_around(delta):
	if $FrameTimer.is_stopped():
		self.change_direction(-self.direction)
		return self.set_state(FighterState.stand)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, walk_deceleration)

func pre_run():
	$AnimationPlayer.play("Run")

func state_run(delta):
	if not self.is_on_floor():
		self.jumps = 1
		return self.set_state(FighterState.fall)
	elif self.is_on_wall():
		return self.set_state(FighterState.run_wall)
	elif self.input.jump and self.jumps > 0:
		return self.set_state(FighterState.jump)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.direction, run_acceleration, run_deceleration, run_max_speed)
	if self.get_velocity_direction() == FighterDirection.none:
		return self.set_state(FighterState.stand)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_run_wall():
	self.pre_walk_wall()

func state_run_wall(delta):
	self.state_walk_wall(delta)

func pre_run_turn_around():
	self.pre_walk_turn_around()

func state_run_turn_around(delta):
	self.state_walk_turn_around(delta)

func pre_jump():
	self.jumps -= 1
	self.velocity = Vector2(self.velocity.x, -jump_strength if self.jumps > 0 else -double_jump_strength)
	$FrameTimer.wait_for(15)
	$AnimationPlayer.play("Jump")

func state_jump(delta):
	if self.velocity.y > -0:
		return self.set_state(FighterState.fall)
	elif $FrameTimer.is_stopped() and self.input.jump and self.jumps > 0:
		if self.input_direction != self.direction and self.input_direction != self.velocity_direction:
			self.velocity = Vector2(0, self.velocity.y)
		return self.set_state(FighterState.jump)
	elif self.input.block:
		return self.set_state(FighterState.block_airborne_dodge)
		return
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.input_direction, air_acceleration, air_deceleration, air_max_speed)
	if not self.input.jump_held or $FrameTimer.after_frame(9): # ignore gravity for X frames if jump is held
		self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_fall():
	self.velocity = Vector2(self.velocity.x, 0)
	$AnimationPlayer.play("Fall")

func state_fall(delta):
	if self.is_on_floor():
		return self.set_state(FighterState.fall_to_stand)
	elif self.input.jump and self.jumps > 0:
		if self.input_direction != self.direction and self.input_direction != self.velocity_direction:
			self.velocity = Vector2(0, self.velocity.y)
		return self.set_state(FighterState.jump)
	elif self.input.block:
		return self.set_state(FighterState.block_airborne_dodge)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.input_direction, air_acceleration, air_deceleration, air_max_speed)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)
	self.set_collision_mask_bit(PhysicsLayer.one_way, not self.input.down)

func pre_fall_through():
	self.jumps = 1
	self.position = Vector2(self.position.x, self.position.y + 1)

func state_fall_through(delta):
	return self.set_state(FighterState.fall)

func pre_fall_to_stand():
	$AnimationPlayer.play("Fall Recovery")

func state_fall_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		return self.set_state(FighterState.stand)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, walk_deceleration * 2)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

func pre_helpless():
	$AnimationPlayer.play("Helpless")

func state_helpless(delta):
	if self.is_on_floor():
		$AnimationPlayer.stop()
		$Flip/Sprite.self_modulate = Color(1, 1, 1, 1)
		return self.set_state(FighterState.fall_to_stand)
	self.velocity = self.get_horizontal_input_movement(delta, self.velocity, self.input_direction, air_acceleration, air_deceleration, air_max_speed)
	self.velocity = self.get_vertical_acceleration(delta, self.velocity, gravity, fall_max_speed)

#########
# Block #
#########

func pre_block():
	$AnimationPlayer.play("Block")
 
func state_block(delta):
	if not $AnimationPlayer.is_playing():
		if self.input_direction != FighterDirection.none:
			return self.set_state(FighterState.block_roll)
		elif not self.input.block:
			return self.set_state(FighterState.block_to_stand)
		elif self.input.down_once:
			return self.set_state(FighterState.block_spot_dodge)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, block_deceleration)

func pre_block_to_stand():
	$AnimationPlayer.play_backwards("Block")
 
func state_block_to_stand(delta):
	if not $AnimationPlayer.is_playing():
		return self.set_state(FighterState.stand if not self.input.block else FighterState.block)
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, block_deceleration)

enum _block_roll_states { disappear = 0, teleport = 1, reappear = 2 }

var _block_roll_state = _block_roll_states.disappear
var _block_roll_direction = 0

func pre_block_roll():
	$AnimationPlayer.play("Block Roll")
	_block_roll_state = _block_roll_states.disappear
	_block_roll_direction = self.input_direction

func state_block_roll(delta):
	match _block_roll_state:
		_block_roll_states.disappear:
			if $Flip/Sprite.get_texture() == null:
				self.velocity = Vector2(self.velocity.x + _block_roll_direction * 2000, self.velocity.y)
				_block_roll_state = _block_roll_states.teleport
				$AnimationPlayer.play_backwards("Block Roll")
				if _block_roll_direction == self.direction:
					self.change_direction(-self.direction)
		_block_roll_states.teleport:
			if $Flip/Sprite.get_texture() != null:
				self.velocity = Vector2(0, self.velocity.y)
				_block_roll_state = _block_roll_states.reappear
		_block_roll_states.reappear:
			if not $AnimationPlayer.is_playing():
				return self.set_state(FighterState.stand if not self.input.block else FighterState.block)

func pre_block_spot_dodge():
	$FrameTimer.wait_for(12)
	$AnimationPlayer.play("Block Roll")
	_block_roll_state = _block_roll_states.disappear

func state_block_spot_dodge(delta):
	match _block_roll_state:
		_block_roll_states.disappear:
			if $FrameTimer.is_stopped():
				$FrameTimer.wait_for(12)
				$AnimationPlayer.play_backwards("Block Roll")
				_block_roll_state = _block_roll_states.reappear
		_block_roll_states.reappear:
			if $FrameTimer.is_stopped():
				return self.set_state(FighterState.stand if not self.input.block else FighterState.block)

func pre_block_airborne_dodge():
	$FrameTimer.wait_for(16)
	$AnimationPlayer.play("Block Roll")
	self.velocity = Vector2(1, 0.35) * 560
	self.set_collision_mask_bit(PhysicsLayer.one_way, true)

func state_block_airborne_dodge(delta):
	if $FrameTimer.is_stopped():
		if self.is_on_floor():
			self.velocity = self.velocity * 0.6
			return self.set_state(FighterState.stand)
		return self.set_state(FighterState.helpless)
	elif self.velocity.y > 0 and self.is_on_floor() and $AnimationPlayer.get_current_animation() != "Stand":
		$AnimationPlayer.play("Stand")
		self.velocity = self.velocity * 0.6
	self.velocity = self.get_horizontal_deceleration(delta, self.velocity, block_deceleration)

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