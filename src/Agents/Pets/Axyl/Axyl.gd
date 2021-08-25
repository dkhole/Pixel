extends "res://src/common/Pet.gd"

var bubbles = preload("./Bubbles.tscn")
onready var bubbles_start = $BubbleStart
var bubbles_instance
var isBubble = false
signal removed_pet
signal tele_in

func _init().():
	DISTANCE_THRESHOLD = 35.0
	slow_radius = 100.0
	max_speed = 300.0
	attack_range = 35.0
	
func _process(_delta):
	if state != pet_states.ATTACKING:
			remove_bubbles()
			
func _physics_process(_delta):
	match state:
		pet_states.ATTACKING:
			max_speed  = 100
			if target_global.isDead:
				remove_bubbles()
				state = pet_states.FOLLOWING
				return
			if global_position.distance_to(target_global.position) > DISTANCE_THRESHOLD:
				remove_bubbles()
				state = pet_states.TRACKING
				return
			if !isBubble:
				bubbles_instance = bubbles.instance()
				bubbles_instance.position = Vector2.ZERO
				bubbles_instance.rotation_degrees = rad2deg((target_global.position - get_global_position()).normalized().angle())
				bubbles_start.add_child(bubbles_instance)
				isBubble = true
			#otherwise if it is flaming adjust rotation in case imp moves position
			elif isBubble:
				bubbles_instance.rotation_degrees = rad2deg((target_global.position - get_global_position()).normalized().angle())

func remove_bubbles():
	if bubbles_instance != null && isBubble:
		bubbles_instance.queue_free()
		isBubble = false
		
func tele_finished():
	state = pet_states.FOLLOWING
	emit_signal("tele_in")

func tele_out_start():
	state = pet_states.TELEPORTING
	
func tele_out_finished():
	#emit signal to player
	emit_signal("removed_pet")
	queue_free()
