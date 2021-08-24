extends Area2D

var dir
var speed: = 150
export var accel: = 20

var explosion = preload("./proj_hit.tscn")
var explosion_instance

#travel in the direction of player
func _ready():
	if get_parent().get_node("Player") != null:
		var playerPosition = get_parent().get_node("Player").position
		dir = playerPosition - get_global_position()
	$AnimationPlayer.play("shooting")

func _process(delta):
	#speed += accel
	translate(dir.normalized() * delta * speed)
	
func _on_Timer_timeout():
	queue_free()

#review
func _on_Hitbox_body_entered(_body):
		#play an exploding animation
	explosion_instance = explosion.instance()
	explosion_instance.position = get_global_position()
	explosion_instance.emitting = true
	get_parent().add_child(explosion_instance)
	queue_free()

func _on_Hitbox_area_entered(_area):
			#play an exploding animation
	explosion_instance = explosion.instance()
	explosion_instance.position = get_global_position()
	explosion_instance.emitting = true
	get_parent().add_child(explosion_instance)
	queue_free()
