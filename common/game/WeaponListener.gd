extends Node2D
signal single_attack
signal auto_attack

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_child_count() > 0:
		connect_weapons()

func update_weapon(weapon: Node2D):
	$Weapon.replace_by(weapon)
	weapon.set_name("Weapon")
	connect_weapons()

func connect_weapons():
	$Weapon.connect("single_attack", self, "single_attack")
	$Weapon.connect("auto_attack", self, "auto_attack")

func single_attack():
	emit_signal("single_attack")

func auto_attack(start : bool):
	emit_signal("auto_attack", start)
