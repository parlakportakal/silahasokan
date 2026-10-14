extends Node2D

@export_group("Ateş")
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2
@export var automatic: bool = false
@export var spread_degrees: float = 0.0

@export_group("Tepme")
@export var recoil_angle_degrees: float = 25.0
@export var recoil_kick_time: float = 0.04
@export var recoil_recover_time: float = 0.15
## Tepmede silahın geriye kayma mesafesi (piksel, 0 = kapalı)
@export var kickback_distance: float = 4.0
## Ateş edince karakterin geriye itilme gücü (hız, 0 = kapalı)
@export var player_knockback: float = 150.0
## Havadayken geri tepme çarpanı (1 = aynı, 2 = havada iki kat güçlü)
@export var air_knockback_multiplier: float = 1.0

# =====================================================
#  İÇ DEĞİŞKENLER (genelde dokunmana gerek yok)
# =====================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = get_node_or_null("Muzzle")

var recoil: float = 0.0            # 0 = normal, 1 = tepmenin en uç noktası (tween bunu değiştirir)
var facing: int = 1                # Karakterin baktığı yön: 1 = sağ, -1 = sol
var aim_angle: float = 0.0         # Ateş açısı (sağ = 0, sol = PI; tepme hariç)
var cooldown_timer: float = 0.0    # Bir sonraki atışa kalan süre
var recoil_tween: Tween
var sprite_rest_position: Vector2  # Sprite'ın normal konumu
var gun_rest_position: Vector2     # Silahın sağa bakarkenki konumu (el pozisyonu)


func _ready() -> void:
	sprite_rest_position = sprite.position
	gun_rest_position = position

	if muzzle == null:
		push_warning("Gun altında 'Muzzle' adında bir Marker2D bulunamadı! Mermi silahın merkezinden çıkacak.")
	if bullet_scene == null:
		push_warning("Gun'ın Inspector'ındaki 'Bullet Scene' boş! bullet.tscn'i sürükle.")


func _process(delta: float) -> void:
	cooldown_timer -= delta
	_update_facing()
	_apply_recoil_visuals()

	# Sol tık ("shoot" action'ı)
	var wants_to_shoot := Input.is_action_pressed("shoot") if automatic else Input.is_action_just_pressed("shoot")
	if wants_to_shoot and cooldown_timer <= 0.0:
		_shoot()


# -----------------------------------------------------
#  Karakterin baktığı yöne göre silahı çevir
# -----------------------------------------------------
func _update_facing() -> void:
	# Tuşa basıldığı AN yönü değiştir (hareket etmeni beklemez, son basılan tuş kazanır)
	if Input.is_action_just_pressed("sola"):
		facing = -1
	elif Input.is_action_just_pressed("saga"):
		facing = 1
	# Bir tuş bırakılınca hâlâ basılı olan diğer tuşun yönüne dön
	elif Input.is_action_just_released("sola") and Input.is_action_pressed("saga"):
		facing = 1
	elif Input.is_action_just_released("saga") and Input.is_action_pressed("sola"):
		facing = -1

	# Sağa bakıyorsa açı 0, sola bakıyorsa 180 derece
	aim_angle = 0.0 if facing == 1 else PI
	# Sola bakıyorsa silah ters durmasın diye Y ekseninde çevir
	scale.y = float(facing)
	# Silahı karakterin diğer eline taşı (X konumunu aynala)
	position.x = gun_rest_position.x * facing


# -----------------------------------------------------
#  Tepme görüntüsü: rotasyon + geri kayma
# -----------------------------------------------------
func _apply_recoil_visuals() -> void:
	# Sağa bakarken namlu yukarı = negatif açı, sola bakarken tersi
	var kick_direction := -scale.y
	global_rotation = aim_angle + deg_to_rad(recoil_angle_degrees) * recoil * kick_direction
	sprite.position = sprite_rest_position + Vector2(-kickback_distance * recoil, 0.0)


# -----------------------------------------------------
#  Ateş etme
# -----------------------------------------------------
func _shoot() -> void:
	cooldown_timer = fire_rate

	if bullet_scene:
		# Sapma varsa nişan açısına rastgele ekle
		var angle := aim_angle + deg_to_rad(randf_range(-spread_degrees, spread_degrees))
		var direction := Vector2.RIGHT.rotated(angle)

		var bullet := bullet_scene.instantiate()
		# Mermiyi sahneye ekle (karakterin çocuğu yapma, yoksa karakterle birlikte hareket eder)
		get_tree().current_scene.add_child(bullet)
		# Muzzle varsa namlu ucundan, yoksa silahın merkezinden çıkar
		bullet.global_position = muzzle.global_position if muzzle else global_position
		bullet.rotation = angle
		bullet.direction = direction

	_play_recoil()
	_push_player_back()


# -----------------------------------------------------
#  Karakteri baktığı yönün tersine it
# -----------------------------------------------------
func _push_player_back() -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or player_knockback == 0.0:
		return

	var force := player_knockback
	if not body.is_on_floor():
		force *= air_knockback_multiplier

	# Sağa bakıyorsa sola, sola bakıyorsa sağa it
	body.velocity.x -= facing * force


# -----------------------------------------------------
#  Tepme animasyonu: hızlıca kalk, yavaşça geri dön
# -----------------------------------------------------
func _play_recoil() -> void:
	if recoil_tween:
		recoil_tween.kill()  # Seri atışta önceki animasyonu iptal et

	recoil_tween = create_tween()
	# 1) Hızlıca tepme noktasına çık
	recoil_tween.tween_property(self, "recoil", 1.0, recoil_kick_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 2) Yavaşça normale dön
	recoil_tween.tween_property(self, "recoil", 0.0, recoil_recover_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
