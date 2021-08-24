extends KinematicBody2D

enum pet_states {
	FOLLOWING,
	TRACKING,
	ATTACKING,
	IDLE,
	TELEPORTING
}
var DISTANCE_THRESHOLD: = 35.0
export var max_speed: = 300.0
export var slow_radius: = 100.0
var attack_range = 35.0
var _velocity: = Vector2.ZERO
#scene variables
onready var player = get_parent().get_node("Player")
onready var anim_player = $AnimationPlayer

var state = pet_states.TELEPORTING
#see if i can change this per pet type
#coupled with player
onready var enemies = player.enemiesWithinRadius

var target_global

func _init(_DISTANCE_THRESHOLD = 35.0,  _slow_radius = 100.0, _max_speed = 300.0, _attack_range = 35.0).():
	DISTANCE_THRESHOLD = _DISTANCE_THRESHOLD
	slow_radius = _slow_radius
	max_speed = _max_speed
	attack_range = _attack_range
	
func _process(_delta):
	#toggle attacking
	if(Input.is_action_just_pressed("ui_charge_pet") && state != pet_states.TELEPORTING):
		if state == pet_states.FOLLOWING || state == pet_states.IDLE && enemies.size() > 0:
			state = pet_states.TRACKING
		else:
			state = pet_states.FOLLOWING
			
func _physics_process(_delta):
	match state:
		pet_states.TELEPORTING:
			pass
		pet_states.FOLLOWING:
			max_speed  = 300
			target_global = player
			if global_position.distance_to(target_global.position) < DISTANCE_THRESHOLD:
				state = pet_states.IDLE
				return
			move_to_target_global()
		pet_states.IDLE:
			max_speed  = 300
			target_global = player
			if global_position.distance_to(target_global.position) > DISTANCE_THRESHOLD:
				state = pet_states.FOLLOWING
				return
			if anim_player.current_animation != '' :
				anim_player.seek(0, true)
				anim_player.stop()
		pet_states.TRACKING:
			max_speed  = 300
			if enemies.size() <= 0:
				state = pet_states.FOLLOWING
				return
			var closestEnemy = get_closest_enemy()
			if !is_instance_valid(closestEnemy) || closestEnemy.isDead:
				state = pet_states.FOLLOWING
				return
			target_global = closestEnemy
			if global_position.distance_to(target_global.position) < attack_range:
				state = pet_states.ATTACKING
			else:
				move_to_target_global()

func get_closest_enemy():
	var closest_enemy
	#get first alive enemy as closest
	for enemy in enemies:
		if !enemy.isDead:
			closest_enemy = enemy
			break
	#if none are alive return
	if closest_enemy == null:
		return null
	#otherwise search for closest
	for enemy in enemies:
		if enemy.global_position.distance_to(global_position) < closest_enemy.position.distance_to(global_position) && !enemy.isDead:
			closest_enemy = enemy
	return closest_enemy
	
func move_to_target_global():
	_velocity = Steering.arrive_to(
		_velocity,
		global_position,
		target_global.position,
		max_speed,
		slow_radius
	)
	if _velocity.x > 0 :
		anim_player.play("move_right")
	else:
		anim_player.play("move_left")
	_velocity = move_and_slide(_velocity)
