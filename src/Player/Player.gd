extends KinematicBody2D

enum {
	MOVE,
	DAMAGED,
	DEAD
}

enum pet{
	EMPTY,
	AXYL,
	CHICKEN
}

var pets = [pet.EMPTY, pet.AXYL, pet.CHICKEN]

var cherryDie = preload("res://Assets/CherryMoves.png")
#pets
var axyl = preload("res://src/Agents/Pets/Axyl/Axyl.tscn")
var chicken = preload("res://src/Agents/Pets/Chicken/Chicken.tscn")

var axyl_instance;
var chicken_instance;

var currVelocity = Vector2.ZERO
export (int) var ACCELERATION = 2000
export (int) var MAX_SPEED = 150
export (int) var FRICTION = 2000

onready var health_bar = $HealthDisplay
onready var stats = $Stats
onready var anim_player = $AnimationPlayer
onready var status_player = $StatusPlayer
onready var sprite = $MoveSprite
onready var status_sprite = $StatusSprite
onready var findRad = $FindRadius/Collision

export var recievingDamage: = false
export var enemiesWithinRadius: = []
export var respawn_point: = Vector2(520, 136)
export var isDead: = false

var knockback_vector = Vector2.ZERO
var state = MOVE
var curr_pet = pet.EMPTY
var curr_pets = pets[0]
var swapping_pets = false

func _ready():
	findRad.shape.radius = 100

func _physics_process(delta):
	match state:
		MOVE:
			get_input_move(delta)
		DEAD:
			return
		DAMAGED:
			knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 2000 * delta)
			knockback_vector = move_and_slide(knockback_vector)
			get_input_move(delta)

func _input(event):
	if event.is_action_pressed("ui_change_pet") && !swapping_pets:
		#instead should store pets in datastruct
		match curr_pet:
			pet.EMPTY:
				swapping_pets = true
				add_axyl()
			pet.AXYL:
				swapping_pets = true
				remove_pet(axyl_instance)
			pet.CHICKEN:
				swapping_pets = true
				remove_pet(chicken_instance)

func finished_tele_in():
	swapping_pets = false
	print("fyck")

func remove_pet(remove):
	#remove
	remove.get_node("AnimationPlayer").stop(true)  # restart = true is the default, so you can also omit it
	print(remove.get_node("AnimationPlayer").play("tele_out"))
	remove.get_node("AnimationPlayer").play("tele_out")
	print(remove.get_node("AnimationPlayer").current_animation)
	print(remove)

func add_axyl():
	axyl_instance = axyl.instance()
	axyl_instance.position = get_global_position()
	axyl_instance.connect("tele_in", self, "finished_tele_in")
	axyl_instance.connect("removed_axyl", self, "add_chicken")
	get_parent().add_child(axyl_instance)
	curr_pet = pet.AXYL

func add_chicken():
	chicken_instance = chicken.instance()
	chicken_instance.position = get_global_position()
	chicken_instance.connect("tele_in", self, "finished_tele_in")
	chicken_instance.connect("removed_chicken", self, "add_axyl")
	get_parent().add_child(chicken_instance)
	curr_pet = pet.CHICKEN

func get_input_move(delta):
	var axis = get_input_axis()
	#if user is moving apply velocity otherwise apply deceleration
	if axis != Vector2.ZERO:
		#calc and apply velocity
		apply_animation(axis)
		apply_movement(axis, delta)
	else:
		apply_friction(delta)
		#prevent error from showing
		if anim_player.current_animation != '' :
			anim_player.seek(0, true)
			anim_player.stop(true)
	currVelocity = move_and_slide(currVelocity)

func apply_animation(axis):
	if axis.y > 0:
		anim_player.set_current_animation("walk_straight")
	elif axis.y < 0:
		anim_player.set_current_animation("walk_back")
	elif axis.x > 0:
		anim_player.set_current_animation("walk_right")
	elif axis.x < 0:
		anim_player.set_current_animation("walk_left")
	
func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	axis.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return axis.normalized()

func apply_movement(axis, delta):
	currVelocity = currVelocity.move_toward(axis * MAX_SPEED, ACCELERATION * delta)

func apply_friction(delta):
	currVelocity = currVelocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _on_FindRadius_body_entered(body):
	enemiesWithinRadius.append(body)

func _on_FindRadius_body_exited(body):
	enemiesWithinRadius.erase(body)

func _on_Hurtbox_area_entered(area):
	if state == MOVE:
		#knockback_timer.start()
		knockback_vector = (global_position - area.global_position) * area.knockback_force
		stats.health -= area.damage
		health_bar.update_healthbar(stats.health)
		if stats.health <= 0:
			state = DEAD
		else:
			state = DAMAGED
			status_player.play("damaged")

func finished_recieving_damage():
	state = MOVE

func _on_Stats_no_health():
	if state != DEAD:
		isDead = true
		anim_player.stop()
		sprite.visible = false
		status_sprite.visible = true
		status_player.play("dying")
		yield(get_tree().create_timer(3), "timeout")
		stats.health = 100
		status_player.stop()
		sprite.visible = true
		status_sprite.visible = false
		position = respawn_point
		isDead = false
		state = MOVE

func _on_KnockbackTimer_timeout():
	knockback_vector = Vector2.ZERO
