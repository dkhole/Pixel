extends KinematicBody2D

enum enemy_states{
	IDLE,
	FOLLOW,
	RETURN,
	ATTACK,
	DEAD
}

export var DISTANCE_THRESHOLD: = 200.0
export var SEARCH_RANGE = 300.0
export var slow_radius: = 250.0
export var max_speed: = 70.0

#coupled with pet
export var isDead: = false;

export var gettingHurt: = false

var _velocity: = Vector2.ZERO
var state = enemy_states.IDLE
var target_global_position: Vector2
var start_pos: Vector2
#projectile variables
onready var player = get_parent().get_node("Player")
onready var anim_player = $AnimationPlayer
onready var status_player = $StatusPlayer

func _init(_DISTANCE_THRESHOLD = 200.0, _SEARCH_RANGE = 300.0, _slow_radius = 250.0, _max_speed = 70.0).():
	DISTANCE_THRESHOLD = _DISTANCE_THRESHOLD
	SEARCH_RANGE = _SEARCH_RANGE
	slow_radius = _slow_radius
	max_speed = _max_speed

func _ready():
	start_pos = global_position

func _process(_delta):
	if player != null:
		target_global_position = player.global_position
	else:
		return
	match state:
		enemy_states.FOLLOW:
			if global_position.distance_to(target_global_position) > SEARCH_RANGE:
				state = enemy_states.RETURN
			elif global_position.distance_to(target_global_position) < DISTANCE_THRESHOLD:
				state = enemy_states.ATTACK
			else:
				#steer to target if its not within the distance threshold
				_move_to_target(player.global_position, slow_radius)
		enemy_states.RETURN:
			if global_position.distance_to(start_pos) < 1:
				state = enemy_states.IDLE
			elif global_position.distance_to(target_global_position) < SEARCH_RANGE:
				state = enemy_states.FOLLOW
			else:
				_move_to_target(start_pos, 0)
		enemy_states.DEAD:
			pass
	
func _move_to_target(target, slow_rad):
	_velocity = Steering.arrive_to(
		_velocity,
		global_position,
		target,
		max_speed,
		slow_rad
	)
	if _velocity.x > 0 :
		anim_player.play("run_right")
	else:
		anim_player.play("run_left")
	_velocity = move_and_slide(_velocity)
