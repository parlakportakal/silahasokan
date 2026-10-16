extends Sprite2D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	#hidden yazınca gizliyo confined yazınca ekrandan kaçmasını engelliyo

func _process(_delta):
	global_position = get_global_mouse_position()
#utanç verici şekilde fazla kolaymış boşa uğraşmışım
