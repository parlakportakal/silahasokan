extends Node2D

@onready var weapons: Array[Node2D] = [$pistol, $pompgun]
var selected_weapon: int = 0


func _ready() -> void:
	select_weapon(0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not get_parent().local_control:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		if event.keycode == KEY_1:
			select_weapon(0)
		elif event.keycode == KEY_2:
			select_weapon(1)


func select_weapon(index: int) -> void:
	selected_weapon = index
	for weapon_index in range(weapons.size()):
		weapons[weapon_index].visible = weapon_index == selected_weapon


func _process(_delta: float) -> void:
	if not get_parent().local_control:
		return
	# Dönüş merkezi oyuncuda kalır; uzaktaki silah bu merkez etrafında döner.
	if global_position.distance_squared_to(get_global_mouse_position()) > 0.001:
		look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("shoot"):
		get_tree().current_scene.request_fire()
