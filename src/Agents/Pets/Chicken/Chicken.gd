extends "res://src/common/Pet.gd"

var flamethrower = preload("./Flamethrower.tscn")
onready var fire_start = $FireStart
var flame_instance
var flaming = false
signal removed_pet
signal tele_in

func _init().():
	DISTANCE_THRESHOLD = 35.0
	slow_radius = 100.0
	max_speed = 300.0
	attack_range = 35.0
	
func _process(_delta):
	if state != pet_states.ATTACKING:
			remove_flame()
			
func _physics_process(_delta):
	match state:
		pet_states.ATTACKING:
			max_speed  = 100
			if target_global.isDead:
				remove_flame()
				state = pet_states.FOLLOWING
				return
			if global_position.distance_to(target_global.position) > DISTANCE_THRESHOLD:
				remove_flame()
				state = pet_states.TRACKING
				return
			if !flaming:
				flame_instance = flamethrower.instance()
				flame_instance.position = Vector2.ZERO
				flame_instance.rotation_degrees = rad2deg((target_global.position - get_global_position()).normalized().angle())
				fire_start.add_child(flame_instance)
				flaming = true
			#otherwise if it is flaming adjust rotation in case imp moves position
			elif flaming:
				flame_instance.rotation_degrees = rad2deg((target_global.position - get_global_position()).normalized().angle())

func remove_flame():
	if flame_instance != null && flaming:
		flame_instance.queue_free()
		flaming = false

func tele_finished():
	state = pet_states.FOLLOWING
	emit_signal("tele_in")

func tele_out_start():
	state = pet_states.TELEPORTING
	print(anim_player.get_current_animation_position())
	
func tele_out_finished():
	#emit signal to player
	print("removing")
	emit_signal("removed_pet")
	queue_free()
