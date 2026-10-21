extends Camera2D
@export_group("Kamera Ayarları")
@export var strength = 0.2
@export var maxmesafe = 100.0
@export var smoothing = 8.0

func _process(delta):
	var aralık = get_global_mouse_position() - get_parent().global_position
	var target = (aralık * strength).limit_length(maxmesafe)
	offset = offset.lerp(target, smoothing * delta)

# get_parent().global_position üstündeki node un pozisyonunu alıyo
# lerp() >>>> (50, 
