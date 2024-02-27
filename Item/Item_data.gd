extends Resource
class_name ItemData

@export var name: String = ""
@export var stackable: bool = false
@export var texture: AtlasTexture
@export_multiline var description: String = ""

func use(target) -> void:
	pass
