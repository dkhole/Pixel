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
var curr_pets = pet.EMPTY
var swapping_pets = false
var tele_out = false

signal remove_pet

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
		swapping_pets = true
		if curr_pets + 1 > pets.size() - 1:
			curr_pets = pets[0]
		else:
			curr_pets = pets[curr_pets + 1]
		match curr_pets:
			#first so we dont have to remove anything
			pet.AXYL:
				add_pet(axyl)
			#for the rest we remove current pet as add pet gets called after teleport animation is complete
			pet.CHICKEN:
				remove_pet()
			pet.EMPTY:
				remove_pet()

func finished_tele_in():
	swapping_pets = false
	
func finished_tele_out():
	#add pet
	match curr_pets:
		pet.CHICKEN:
			add_pet(chicken)
		pet.EMPTY:
			swapping_pets = false

func remove_pet():
	emit_signal("remove_pet")

func add_pet(pet):
	var pet_instance = pet.instance()
	pet_instance.position = Vector2(get_global_position().x + 15, get_global_position().y)
	pet_instance.connect("tele_in", self, "finished_tele_in")
	pet_instance.connect("removed_pet", self, "finished_tele_out")
	get_parent().add_child(pet_instance)

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
