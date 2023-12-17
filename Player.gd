extends CharacterBody3D

@export var walk_max_speed = 1
@export var sprint_max_speed = 5
@export var acceleration = 4
@export var friction = 69
@export var jump_impulse = 8
@export var gravity = -40

@export var mouse_sensitvity = .1
@export var controller_sensitivity = 3

#@export var push = 1

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var anim= $Head/AnimationPlayer
@onready var feet= $Footsteps

var foot_noise
var foot_pitch

#Viewport options
@export var default_fov: float = 60

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## Begin calculating and influencing the players statistics
var stats_yards: float = 0
@export var stats_max_stamina: float = 100
var stats_stamina: float = stats_max_stamina
@export var stats_max_fitness: float = 100
var stats_fitness: float = stats_max_fitness
var stats_stamina_regen: bool = true
var stats_fitness_regen: bool = true
func update_stats(delta):
	pos_delta = sqrt(
		pow(abs(get_position_delta().x), 2) +
		pow(abs(get_position_delta().z), 2)
	)
	stats_yards += pos_delta
	if stats_stamina_regen && (stats_stamina < stats_max_stamina):
		if !pos_delta:
			stats_stamina += (delta/10)*(stats_fitness*2)
		else:
			stats_stamina += (delta/10)*stats_fitness
	if stats_fitness_regen && (stats_fitness < stats_max_fitness):
		if !pos_delta:
			stats_fitness += (delta/2)
		else:
			stats_fitness += (delta)


func _unhandled_input(event):
	if event.is_action_pressed("click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if event.is_action_pressed("toggle_mouse_mode"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitvity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitvity))

var max_speed: float = 0
var pos_delta: float = 0
func _process(delta):
	pass

func _physics_process(delta):
	input_vector = get_input_vector()
	direction = get_direction(input_vector)
	apply_movement(direction, delta, max_speed)
	apply_friction(direction, delta)
	apply_gravity(delta)
	sprint()
	jump()
	apply_controller_rotation()
	head.rotation.x = clamp(head.rotation.x, -1, 1)
	move_and_slide()
	update_stats(delta)
	update_animations(delta)
	update_fov(pos_delta)
	#$Head/Camera.fov = lerpf(default_fov, default_fov-(pos_delta*100), 10)
	
	
	#for idx in get_slide_collision_count():
	#	var collision = get_slide_collision(idx)
	#	if collision.collider.is_in_group("bodies"):
	#		collision.collider.apply_central_impulse(-collision.normal * velocity.length() * push)

func update_fov(delta):
	camera.fov = lerp(camera.fov, default_fov-(pos_delta*100), .1)
	
	

func _play_footstep_audio():
	feet.play()

func update_animations(delta):
	#strafing
	var head_bounce = anim.get_animation("head_bounce")
	#var idx = head_bounce.find_track("/", 1)
	var vec: Vector3 = Vector3(0, (1-pos_delta), 0)
	if pos_delta:
		if is_on_floor():
			anim.play("head_bounce")
			anim.set_speed_scale(.5+(pos_delta*10))
			head_bounce.track_set_key_value(0, 1, vec)
	 		#foot_noise = 100*pos_delta
			#head_bounce.track_set_key_value(3, 0, foot_noise)
			#foot_pitch = 1+pos_delta
			#head_bounce.track_set_key_value(4, 0, foot_pitch)
	else:
		#$Head/AnimationPlayer.set_speed_scale(0.5)
		anim.play("RESET")
		#$Head/AnimationPlayer.anima

var input_vector: Vector3
func get_input_vector():
	input_vector = Vector3.ZERO
	input_vector.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))/4
	input_vector.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector

var direction: Vector3
func get_direction(input_vector):
	direction = Vector3.ZERO
	direction = (input_vector.x * transform.basis.x) + (input_vector.z * transform.basis.z)
	return direction

func apply_movement(direction, delta, max_speed):
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z

func apply_friction(direction, delta):
	if direction == Vector3.ZERO:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_impulse)

var snap_vector: Vector3 = Vector3.ZERO
func update_snap_vector():
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN

func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
	if Input.is_action_just_released("jump") and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 2

func sprint():
	if Input.get_action_strength("sprint") && (stats_stamina > 0) && (stats_fitness > 0):
		max_speed = sprint_max_speed
		stats_stamina -= pos_delta
		stats_fitness -= (pos_delta/2)
		stats_stamina_regen = false
		stats_fitness_regen = false
	else:
		max_speed = walk_max_speed
		stats_stamina_regen = true
		stats_fitness_regen = true

var axis_vector: Vector2 = Vector2.ZERO
func apply_controller_rotation():
	axis_vector = Vector2.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	if InputEventJoypadMotion:
		rotate_y(deg_to_rad(-axis_vector.x) * controller_sensitivity)
		head.rotate_x(deg_to_rad(-axis_vector.y) * controller_sensitivity)
		
	
func apply_head_sway(delta):
	pass
