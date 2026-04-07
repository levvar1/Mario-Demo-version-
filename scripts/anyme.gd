extends  Area2D

class_name Enemy

@export var x_speed=20
@export  var y_speed=100
const POINTS_LABEL_SCENE = preload("res://icon/10.png")
@onready var ray_cast_2d=$RayCast2D as RayCast2D
@onready var animated_sprite_2d=$AnimatedSprite2D as AnimatedSprite2D
func _process(delta):
	position.x-=delta*x_speed
	
	if !ray_cast_2d.is_colliding():
		position.y+=delta*y_speed
		
func die():
	x_speed=0
	y_speed=0
	
	animated_sprite_2d.play("died")

func die_from_hit():
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	animated_sprite_2d.play("died")
	rotation_degrees = 180
	x_speed = 0
	y_speed = 0
	
	var die_tween = get_tree().create_tween()
	die_tween.tween_property(self, "position", position + Vector2(0, -25), .2)
	die_tween.chain().tween_property(self, "position", position + Vector2(0, 500), 4)

	
