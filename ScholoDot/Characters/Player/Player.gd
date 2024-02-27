extends CharacterBody3D

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip

@onready var neck = $Neck
@onready var head = $Neck/Head
@onready var eyes = $Neck/Head/Eyes
@onready var muzzle = $Neck/Head/Muzzle
@onready var camera = $Neck/Head/Eyes/Camera3D
@onready var animation_player = $Neck/Head/Eyes/AnimationPlayer

@onready var crouching_collision = $CrouchingCollision
@onready var standing_collision = $StandingCollision

@onready var crouch_ray = $CrouchRay
@onready var interact_ray = $Neck/Head/Eyes/Camera3D/InteractRay
@onready var aim_ray = $Neck/Head/Eyes/Camera3D/AimRay

@onready var hand = $Neck/Head/Eyes/Camera3D/Hand
@onready var weapon_pivot = $Neck/Head/Eyes/Camera3D/WeaponPivot

const Arrow = preload("res://Weapon/arrow.tscn")
var arrow
var picked_object
var pull_power: int = 4
var keyStrength = 0

#Stats
var health: int = 5
var strength: int = 5

#Movement
var current_speed = 5.0
const walking_speed = 5.0
const sprint_speed = 10.0
const crouch_speed = 3.0

const jump_velocity = 4.5
var last_velocity = Vector3.ZERO
var direction = Vector3.ZERO
var crouch_depth = -1.0

var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

const mouse_sensitivity = 0.2
var lerp_speed = 10.0
var air_lerp_speed = 3.0
var free_look_tilt = 5.0

#Slide
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

#Head Bob
const head_bob_sprint_speed = 22.0
const head_bob_walk_speed = 14.0
const head_bob_crouch_speed = 10.0

const head_bob_sprint_intensity = 0.2
const head_bob_walk_intensity = 0.1
const head_bob_crouch_intensity = 0.05

var head_bob_vector = Vector2.ZERO
var head_bob_index = 0.0
var head_bob_current_intensity = 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

signal toggle_inventory()
	
func interact() -> void:
	if !picked_object:
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider.get_collision_layer() == 5:
				collider.player_interact()
			elif collider is RigidBody3D:
				picked_object = collider
	else:
		picked_object = null
		
func heal(heal_value: int) -> void:
	health += heal_value
	print(health)
	
func get_drop_position() -> Vector3:
	var direction = -camera.global_transform.basis.z * 2
	return camera.global_position + direction
	
func _ready():
	PlayerManager.player = self
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-110), deg_to_rad(110))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	#Quit for testing
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("Inventory") && is_on_floor():
		toggle_inventory.emit()
		
	if Input.is_action_just_pressed("Interact"):
		interact()
	
	if Input.is_action_just_pressed("UseRight"):
		var direction = -camera.global_transform.basis.z * 2
		
		#Projectile test
		if !picked_object && !weapon_pivot.get_children():
			arrow = Arrow.instantiate()
			
			muzzle.add_child(arrow)
			arrow.shoot = true
		elif picked_object:
			picked_object.apply_central_impulse(direction * strength)
			picked_object = null
		elif !picked_object:
			animation_player.play("melee_attack")
	
	#Spell test
	if Input.is_action_just_pressed("UseLeft"):
		if aim_ray.is_colliding() && !picked_object:
			if aim_ray.get_collider().is_in_group("Floor"):
				var spell_obj = CSGBox3D.new()

				print(aim_ray.get_collision_point())
				add_child(spell_obj)
				#spell_obj.global_transform.origin = camera.global_transform.origin + direction
				spell_obj.global_transform.origin = aim_ray.get_collision_point()
				spell_obj.reparent(self.get_parent())

func _physics_process(delta):
	#Hold key test
	if Input.is_action_pressed("UseLeft"):
		keyStrength += delta
	if Input.is_action_just_released("UseLeft"):
		print(keyStrength)
		keyStrength = 0
		
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	
	if picked_object:
		var a = picked_object.global_transform.origin
		var b = hand.global_transform.origin
		picked_object.set_linear_velocity((b - a) * pull_power)
		
	if Input.is_action_pressed("Crouch") || sliding:
		current_speed = lerp(current_speed, crouch_speed, delta * lerp_speed)
		head.position.y = lerp(head.position.y, crouch_depth, delta * lerp_speed)
		crouching_collision.disabled = false
		standing_collision.disabled = true
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			
		walking = false
		sprinting = false
		crouching = true
	elif !crouch_ray.is_colliding():
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		crouching_collision.disabled = true
		standing_collision.disabled = false
		
		if Input.is_action_pressed("Sprint"):
			current_speed = lerp(current_speed, sprint_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
	
	if Input.is_action_pressed("FreeLook") || sliding:
		free_looking = true
		
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta * lerp_speed)
		
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
	
	#Head Bob
	if sprinting:
		head_bob_current_intensity = head_bob_sprint_intensity
		head_bob_index += head_bob_sprint_speed * delta
	elif walking:
		head_bob_current_intensity = head_bob_walk_intensity
		head_bob_index += head_bob_walk_speed * delta
	elif crouching:
		head_bob_current_intensity = head_bob_crouch_intensity
		head_bob_index += head_bob_crouch_speed * delta
		
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bob_vector.y = sin(head_bob_index)
		head_bob_vector.x = sin(head_bob_index / 2.0) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bob_vector.y * (head_bob_current_intensity / 2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bob_vector.x * head_bob_current_intensity, delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0 * (head_bob_current_intensity / 2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0 * head_bob_current_intensity, delta * lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("jump")

	#Landing
	if is_on_floor() && last_velocity.y < 0.0:
		animation_player.play("landing")
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
		
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	last_velocity = velocity
	
	move_and_slide()

func _on_animation_player_animation_finished(anim_name):
	if weapon_pivot.get_children():
		if anim_name == "melee_attack" || anim_name == "landing":
			animation_player.play("idle")
