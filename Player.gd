extends KinematicBody2D

export var walk_velocity = 3.0
export var player_id = 0

onready var animation_tree = $AnimationTree

# start facing down
var current_direction = Vector2(0.0, -1.0)

func _process(delta):
	var direction = Vector2(0.0, 0.0)
	
	if Input.is_action_pressed("left_%d" % player_id):
		direction.x -= 1.0
	if Input.is_action_pressed("right_%d" % player_id):
		direction.x += 1.0
	if Input.is_action_pressed("up_%d" % player_id):
		direction.y -= 1.0
	if Input.is_action_pressed("down_%d" % player_id):
		direction.y += 1.0
	
	current_direction = direction.normalized()
	
	animation_tree["parameters/blend_position"] = current_direction

func _physics_process(delta):
	move_and_slide(current_direction * walk_velocity)

