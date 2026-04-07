extends CharacterBody2D
class_name Player
# Параметры игрока
@export_group("Camera sync")
@export var camera_sync: Camera2D
@export var should_camera_sync: bool = true
@export_group("")


@export var speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity: float = 900.0
@export var max_health: int = 3
@export var knockback_force: float = 300.0
signal points_scored(points: int)
@export_group("Stoping enemies")
@export var min_stomp_degree=35
@export var max_stomp_degree=145
@export var stomp_y_velocity=-150
@export_group("")
@onready var animated_sprite_2d = $AnimatedSprite2D as AnimatedSprite2D
@onready var area2d=$Area2D
enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

const PIPE_ENTER_THRESHOLD=10
const POINTS_LABEL_SCENE = preload("res://scene/points.tscn")

# Player state flags
var is_dead = false
var is_on_path = false
var health: int = max_health
var player_mode = PlayerMode.SMALL

func _ready():
	if SceneData.return_point != null && SceneData.return_point != Vector2.ZERO:
		global_position = SceneData.return_point
func _physics_process(delta) :
	var camera_left_bound = camera_sync.global_position.x - camera_sync.get_viewport_rect().size.x / 2 / camera_sync.zoom.x
	# Гравитация
	velocity.y += gravity * delta
	
	if global_position.x < camera_left_bound + 8 && sign(velocity.x) == -1:
		velocity = Vector2.ZERO
		return
	# Управление движением
	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	# Прыжок
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -jump_force

	# Применение движения
	move_and_slide()
	var collision=get_last_slide_collision()
	if collision != null:
		handle_movement_collision(collision)
	# Проверка на смерть
	if health <= 0:
		queue_free()  # Удаляем игрока
		get_tree().change_scene_to_file("res://MainMenu.tscn")  # Возврат в меню

# Функция для получения урона
func take_damage(damage: int, enemy_position: Vector2):
	health -= damage
	# Отбрасывание игрока
	var knockback_direction = (global_position - enemy_position).normalized()
	velocity = knockback_direction * knockback_force

func _process(delta):
	if global_position.x > camera_sync.global_position.x && should_camera_sync:
		camera_sync.global_position.x = global_position.x
		
	
# Функция для сбора монеток


func handle_flower_collision(area:Node2D):
	set_physics_process(true)
	var animation_name=" mash small " if player_mode==PlayerMode.SMALL	else "big mash"
	animated_sprite_2d.play("small to big")
	

func handle_shroom_collision(area:Node2D):
	var i=0
	while i<1:
		if player_mode == PlayerMode.SMALL:
			set_physics_process(true)
			animated_sprite_2d.play("small")	
			#spawn_point_lapel(area)
			
			i+=1
			break
		area.queue_free()

func handle_enemy_collision(enemy: Enemy):
	if enemy == null:
		return
	var level_manager=get_tree().get_first_node_in_group("level_manager")
	var angle_of_collision=rad_to_deg(position.angle_to_point(enemy.position))
	
	if angle_of_collision > min_stomp_degree && max_stomp_degree > angle_of_collision:
		enemy.die()
		on_enemy_stomped()
		spawn_point_lapel(enemy)
	else :
		die()
func _on_area_2d_area_entered(area: Area2D):
	if area is Enemy:
		handle_enemy_collision(area)
	
	if area is Shroom:
		
		handle_shroom_collision(area)
	
	if area  is ShotingFlower:
		handle_flower_collision(area)
		area.queue_free()
		
		

func spawn_point_lapel(enemy):
	var points_label= POINTS_LABEL_SCENE.instantiate()
	points_label.position=enemy.position+Vector2(-20,-20)
	get_tree().root.add_child(points_label)
	points_scored.emit(10)
	print("10")

func on_enemy_stomped():
	velocity.y=stomp_y_velocity
func on_shroom_stoped():
	velocity.y=stomp_y_velocity
	
func die():
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("death")
		area2d.set_collision_layer_value(1,false)
		area2d.set_collision_mask_value(3,false)
		set_collision_layer_value(1,false)
		set_collision_mask_value(3,false)
		set_physics_process(false)
		var death_tween=get_tree().create_tween()
		death_tween.tween_property(self,"position",position+Vector2(0,-48), .5)
		death_tween.chain().tween_property(self,"position",position+Vector2(0,256),1)
		death_tween.tween_callback(func ():get_tree().reload_current_scene())
		
	else:
		print("big to small")
		
		
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body is Block):
		print ("block")

func handle_movement_collision(collision:KinematicCollision2D):
	if collision.get_collider() is Block:
		var collision_angle=rad_to_deg(collision.get_angle())
		if roundf(collision_angle)==180:
			(collision.get_collider() as Block).bump(player_mode)
	if collision.get_collider()is Pipe:
		
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 0 && Input.is_action_just_pressed("ui_down") && absf(collision.get_collider().position.x - position.x < PIPE_ENTER_THRESHOLD && collision.get_collider().is_traversable):
			print("go down")
			handle_pipe_collision()
			
#
func handle_pipe_collision():
	set_physics_process(false)
	var pipe_tween=get_tree().create_tween()
	pipe_tween.tween_property(self,"position",position+Vector2(0,32),1)
	pipe_tween.tween_callback(switch_to_underground)


func switch_to_underground():
	var level_manager=get_tree().get_first_node_in_group("level_manager")
	SceneData.player_mode=player_mode
	SceneData.coins=level_manager.coins
	SceneData.points=level_manager.points
	get_tree().change_scene_to_file("res://scene/underground.tscn")
	
	
	

	
	
	
	
	
func handle_pipe_connector_entrance_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(32, 0), 1)
	pipe_tween.tween_callback(switch_to_main)
func switch_to_main():
	var level_manager=get_tree().get_first_node_in_group("level_manager")
	SceneData.player_mode=player_mode
	SceneData.coins=level_manager.coins
	SceneData.points=level_manager.points
	get_tree().change_scene_to_file("res://main.tscn")
