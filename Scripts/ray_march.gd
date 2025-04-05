extends Node3D
@onready var quad: MeshInstance3D = $MeshInstance3D

var material: Material
@export_range(0.0, 1.0, 0.01, "slider") var smoothness: float = 0.5
@export var sphere_position: Vector3 = Vector3(0., 0.2, -5);
@export var box_position: Vector3 = Vector3(0., -0.2, -5);
@export_range(-1.0, 1.0, 0.01, "slider") var sphere_ypos: float = 0.0;

func _ready() -> void:
	material = quad.mesh.surface_get_material(0)
	material.set_shader_parameter("sphere_position", sphere_position)
	material.set_shader_parameter("box_position", box_position)
func _process(delta: float) -> void:
	material.set_shader_parameter("smoothness", smoothness)
	material.set_shader_parameter("sphere_ypos", sphere_ypos)
