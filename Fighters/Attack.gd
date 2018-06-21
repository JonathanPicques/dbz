extends CollisionShape2D

export var id = 0
export var damage = 0.0
export var knockback_base = 0.0
export var knockback_angle = 0.0
export var knockback_scaling = 0.0

const knockback_unit = 33.333

func get_dealt_knockback(target):
	var percentage = self.damage + target.damage
	var target_weight = 200.0 / (target.weight + 100.0)
	return knockback_unit * ((((percentage / 10.0) + ((percentage * self.damage) / 20.0)) * target_weight * 1.4 + 18.0) * self.knockback_scaling) + self.knockback_base

func get_target_hitlag(target, knockback):
	return floor(knockback / 3.0 + 3.0)

func get_attacker_hitlag(target, knockback):
	return floor(knockback / 3.0 + 3.0)

func get_target_hitstun(target, knockback):
	return floor(knockback * 0.4)

func get_target_shieldstun(target, knockback):
	return floor((self.damage + 4.45) / 2.235)