extends MeshInstance3D

@export var resource_mesh: MeshInstance3D
@export var resource_collision: CollisionShape3D

@onready var weapon_mesh = $"."
@onready var collision_shape_3d = $Hitbox/CollisionShape3D

func _ready():
	if resource_mesh && resource_collision:
		weapon_mesh = resource_mesh
		collision_shape_3d = resource_collision
		
func _on_hitbox_body_entered(body):
	if body is Character:
		body.take_damage()
