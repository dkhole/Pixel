extends "res://src/common/Enemy.gd"

var projectile = preload("./Projectile.tscn")

onready var healthbar = $HealthDisplay
onready var stats = $Stats

var can_fire = true
var burning = false
var damage_per_second = 0.0
export var fire_rate: = 0.1


func _init().():
	DISTANCE_THRESHOLD = 200.0
	SEARCH_RANGE = 300.0
	slow_radius = 250.0
	max_speed = 70.0

func _process(delta):
	if burning:
		stats.health -= damage_per_second * delta
		healthbar.update_healthbar(stats.health)
	match state:
		enemy_states.IDLE:
			#search for player
			if global_position.distance_to(target_global_position) < SEARCH_RANGE:
				anim_player.playback_speed = 2.5
				state = enemy_states.FOLLOW
			else:
				anim_player.playback_speed = 1.0
				anim_player.play("idling")
		enemy_states.ATTACK:
			if player.isDead:
				state = enemy_states.RETURN
			elif global_position.distance_to(target_global_position) > DISTANCE_THRESHOLD:
				state = enemy_states.FOLLOW
			else:
				if can_fire:
					anim_player.play("shoot_proj")
					
func _finished_shoot_anim():
	_shoot_proj()
	
func _finished_shoot_damaged_anim():
	_shoot_proj()
	
func _shoot_proj():
	var projectile_instance = projectile.instance()
	projectile_instance.position = get_global_position()
	projectile_instance.rotation_degrees = rad2deg((target_global_position - get_global_position()).normalized().angle())
	get_parent().add_child(projectile_instance)
	can_fire = false
	yield(get_tree().create_timer(fire_rate), "timeout")
	can_fire = true

func _on_Hurtbox_area_entered(area):
		status_player.play("recieving_damage")
		burning = true
		damage_per_second = area.damage

func _on_Hurtbox_area_exited(_area):
	burning = false
	damage_per_second = 0
	if status_player.current_animation != '' :
			status_player.seek(0, true)
			status_player.stop(true)

func _on_Stats_no_health():
	if state != enemy_states.DEAD:
		anim_player.play("dying")
		state = enemy_states.DEAD
		#coupled with pet
		isDead = true
