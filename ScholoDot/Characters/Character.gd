extends RigidBody3D
class_name Character

@export var health:int = 5

func take_damage():
	health -= 1
	print(health)
	
func _process(_delta):
	if health <= 0:
		queue_free()

func _on_body_entered(body):
	pass
