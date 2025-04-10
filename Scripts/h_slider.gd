extends HSlider
@onready var rayMarch: Node3D = $".."

func _ready() -> void:
	pass

func _on_value_changed(value: float) -> void:
	rayMarch.smoothness = value
