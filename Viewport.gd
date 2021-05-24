extends Viewport

export var single_camera_max_separation: int = 100.0
export var camera_smooth_split_distance: int = 50.0

onready var player1 = $"Level/YSort/Player1"
onready var player1_camera = $Camera2D

onready var player2 = $"Level/YSort/Player2"
onready var player2_camera = $"../Viewport2/Camera2D"

onready var render_mesh = $"../SplitRenderMesh"

func _ready():
	$"../Viewport2".world_2d = self.world_2d

func _process(delta):
	# get the line between the two players
	var line = player2.position - player1.position

	# compute the distance
	var separation = line.length()
	
	# the separation scale above the single camera distance from 0 to 1
	# 0 if less than single_camera_max_separation, 1 if >= single_camera_max_separation+camera_smooth_split_distance
	var after_separation_ratio = min(1.0, max(0.0, (separation - single_camera_max_separation) / camera_smooth_split_distance))

	# compute the perpendicular line, and invert Y too
	var perp_line = Vector2(line.y, line.x).normalized()

	# set the shader parameters
	render_mesh.material.set_shader_param("line_slope", perp_line)
	render_mesh.material.set_shader_param("separation", separation)
	render_mesh.material.set_shader_param("single_camera_max_separation", single_camera_max_separation)
	render_mesh.material.set_shader_param("camera_smooth_split_distance", camera_smooth_split_distance)

	# interpolate from single_camera_max_separation to single_camera_max_separation+camera_smooth_split_distance
	# from center of the two players to directly on the player
	
	# player 1 camera
	player1_camera.global_position = player1.global_position + (1 - after_separation_ratio) * (player2.global_position - player1.global_position) * 0.5
	
	# player2 2 camera
	player2_camera.global_position = player2.global_position + (1 - after_separation_ratio) * (player1.global_position - player2.global_position) * 0.5

