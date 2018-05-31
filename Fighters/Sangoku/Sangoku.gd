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
	Standing,
	
	Standing_To_BlockMedium,
	BlockMedium_To_Standing
}

var input = FighterInput.new()
var state = FighterState.Standing

func _process(delta):
	input.up = Input.is_action_pressed("ui_up")
	input.down = Input.is_action_pressed("ui_down")
	input.left = Input.is_action_pressed("ui_left")
	input.right = Input.is_action_pressed("ui_right")
	
	if self.state == FighterState.Standing:
		if input.down:
			self.set_state(FighterState.Standing_To_BlockMedium)
	elif self.state == FighterState.Standing_To_BlockMedium:
		if not input.down and not $AnimationPlayer.is_playing():
			self.set_state(FighterState.BlockMedium_To_Standing)
	elif self.state == FighterState.BlockMedium_To_Standing:
		if not $AnimationPlayer.is_playing():
			self.set_state(FighterState.Standing)

func set_state(state, prevState = self.state):
	if state == FighterState.Standing:
		$AnimationPlayer.play("Standing")
	if state == FighterState.Standing_To_BlockMedium:
		$AnimationPlayer.play("BlockMedium")
	if state == FighterState.BlockMedium_To_Standing:
		$AnimationPlayer.play_backwards("BlockMedium")
	self.state = state