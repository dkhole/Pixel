extends "res://src/common/Enemy.gd"

enum mushroom_states{
	ATTACK_COOLDOWN = 5,
}

func _init().():
	DISTANCE_THRESHOLD = 30.0
	SEARCH_RANGE = 210.0
	slow_radius = 20.0
	max_speed = 250.0
	
var random_point
export var bite_cooldown = 1.0
onready var sprite = $Sprite
onready var stats = $Stats
onready var healthbar = $HealthDisplay
onready var hitbox = $Hitbox
onready var hurtbox = $Hurtbox/CollisionShape2D
var burning = false
var damage_per_second = 0

func _physics_process(delta):
	if burning:
		stats.health -= damage_per_second * delta
		healthbar.update_healthbar(stats.health)
	match state:
		enemy_states.IDLE:
			#search for player
			if global_position.distance_to(target_global_position) < SEARCH_RANGE:
				state = enemy_states.FOLLOW
			else:
				anim_player.play("idling")
		enemy_states.ATTACK:
			if player.isDead:
				state = enemy_states.RETURN
			elif global_position.distance_to(target_global_position) >= DISTANCE_THRESHOLD:
				state = enemy_states.FOLLOW
			elif global_position.distance_to(target_global_position) < DISTANCE_THRESHOLD:
				anim_player.play("biting")
				state = mushroom_states.ATTACK_COOLDOWN
		mushroom_states.ATTACK_COOLDOWN:
			if !isDead:
				state = enemy_states.DEAD
				
			yield(get_tree().create_timer(bite_cooldown), "timeout")
			state = enemy_states.RETURN

func _finished_biting_anim():
	anim_player.play("idling")
#	#at end of idling animation ~3seconds pick random point and travel to it
#	var randX = start_pos.x + randi() % 100
#	var randY = start_pos.y + randi() % 100
#	random_point = Vector2(randX, randY)

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
		hitbox.get_node("CollisionShape2D").disabled = true
		hurtbox.disabled = true
		
