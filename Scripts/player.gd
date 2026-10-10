extends CharacterBody2D

# =====================================================
#  AYARLAR (Inspector'dan da değiştirebilirsin)
# =====================================================

@export_group("Yatay Hareket")
## Maksimum yürüme hızı (piksel/saniye)
@export var max_speed: float = 220.0
## Hızlanma: ne kadar hızlı max hıza ulaşır (büyük = daha sert/çabuk)
@export var acceleration: float = 1400.0
## Yerde sürtünme: tuşu bırakınca ne kadar çabuk durur (büyük = hemen durur)
@export var friction: float = 1800.0
## Havada kontrol: havadayken yön değiştirme gücü (0-1 arası çarpan)
@export_range(0.0, 1.0) var air_control: float = 0.6

@export_group("Zıplama")
## Zıplama gücü (yukarı yöndeki ilk hız)
@export var jump_velocity: float = -420.0
## Tuşu erken bırakınca zıplamanın kesilme oranı (küçük = daha kısa zıplama)
@export_range(0.0, 1.0) var jump_cut: float = 0.4
## Yerden düştükten sonra hâlâ zıplayabileceğin süre (saniye)
@export var coyote_time: float = 0.1
## Yere değmeden hemen önce basılan zıplama tuşunu hatırlama süresi (saniye)
@export var jump_buffer_time: float = 0.1
## Toplam zıplama sayısı (1 = normal, 2 = çift zıplama)
@export var max_jumps: int = 1

@export_group("Yerçekimi")
## Normal yerçekimi
@export var gravity: float = 1100.0
## Düşerken uygulanan ekstra çarpan (daha "ağır" düşüş hissi verir)
@export var fall_gravity_multiplier: float = 1.5
## Maksimum düşme hızı
@export var max_fall_speed: float = 700.0

# =====================================================
#  İÇ DEĞİŞKENLER (genelde dokunmana gerek yok)
# =====================================================

var coyote_timer: float = 0.0       # Kenardan düştükten sonra kalan "bonus" süre
var jump_buffer_timer: float = 0.0  # Zıplama tuşuna basıldıktan sonra kalan süre
var jumps_left: int = 0             # Kalan zıplama hakkı


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal(delta)
	move_and_slide()  # Hareketi uygular ve çarpışmaları halleder


# -----------------------------------------------------
#  Sayaçlar: coyote time ve jump buffer
# -----------------------------------------------------
func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time   # Yerdeyken sayaç sürekli dolu
		jumps_left = max_jumps       # Yere değince zıplama hakkı yenilenir
	else:
		coyote_timer -= delta        # Havadayken sayaç azalır

	jump_buffer_timer -= delta

	if Input.is_action_just_pressed("zipla"):
		jump_buffer_timer = jump_buffer_time  # Tuşa basıldığını hatırla


# -----------------------------------------------------
#  Yerçekimi
# -----------------------------------------------------
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var g := gravity
	# Aşağı düşüyorsak yerçekimini artır (daha tok bir düşüş)
	if velocity.y > 0:
		g *= fall_gravity_multiplier

	velocity.y = min(velocity.y + g * delta, max_fall_speed)


# -----------------------------------------------------
#  Zıplama
# -----------------------------------------------------
func _handle_jump() -> void:
	# Zıplama koşulu: tuşa yakın zamanda basıldı VE (yerdeyiz / coyote süresi var / hakkımız var)
	var can_ground_jump := coyote_timer > 0.0
	var can_air_jump := not can_ground_jump and jumps_left > 0 and max_jumps > 1

	if jump_buffer_timer > 0.0 and (can_ground_jump or can_air_jump):
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jumps_left -= 1

	# Değişken zıplama yüksekliği: tuşu erken bırakırsan zıplama kısalır
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut


# -----------------------------------------------------
#  Sağ / sol hareket
# -----------------------------------------------------
func _handle_horizontal(delta: float) -> void:
	# -1 (sol), 0 (yok), 1 (sağ)
	var direction := Input.get_axis("move_left", "move_right")

	# Havadaysak kontrol gücü azalır
	var control := 1.0 if is_on_floor() else air_control

	if direction != 0.0:
		# Tuşa basılıyor: hedef hıza doğru hızlan
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * control * delta)
	else:
		# Tuş yok: sürtünmeyle yavaşla
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)
