extends RigidBody3D

var shoot = false
const DAMAGE = 50
const SPEED = 3

func _ready():
	set_as_top_level(true)
	
func _physics_process(delta):
	if shoot:
		apply_central_impulse(-transform.basis.z * SPEED)

func _on_area_3d_body_entered(body):
	if body is Character:
		body.take_damage()
		queue_free()
	else:
		queue_free()
