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
## Ters yöne basınca uygulanan hızlanma (büyük = anında dönüş, Celeste hissi)
@export var turn_acceleration: float = 3200.0
## Zıplarken ters yöne basılıysa hızı anında o yöne çevir (true = çok keskin dönüş)
@export var flip_speed_on_jump: bool = true
## flip_speed_on_jump açıkken çevrilen hızın max_speed'e oranı (1.0 = tam hız)
@export_range(0.0, 1.0) var flip_speed_ratio: float = 1.0

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
@export var max_jumps: int = 2

@export_group("Yerçekimi")
## Normal yerçekimi
@export var gravity: float = 1100.0
## Düşerken uygulanan ekstra çarpan (daha "ağır" düşüş hissi verir)
@export var fall_gravity_multiplier: float = 1.5
## Maksimum düşme hızı
@export var max_fall_speed: float = 700.0

@export_group("Yere İniş")
## true: yere değince yatay hız sıfırlanır (kayma olmaz)
## false: hız korunur, normal sürtünmeyle yavaşlar (Celeste hissi)
@export var reset_slide_on_land: bool = false
## true: tuşa basıyor olsan bile iner inmez hız sıfırlanır
## false: sadece tuşu bırakmışsan sıfırlanır (koşarken akıcılık bozulmaz)
@export var reset_even_when_holding: bool = false

# =====================================================
#  İÇ DEĞİŞKENLER (genelde dokunmana gerek yok)
# =====================================================

var coyote_timer: float = 0.0       # Kenardan düştükten sonra kalan "bonus" süre
var jump_buffer_timer: float = 0.0  # Zıplama tuşuna basıldıktan sonra kalan süre
var jumps_left: int = 0             # Kalan zıplama hakkı
var can_cut_jump: bool = false      # Bu zıplama tuş bırakılınca kısalabilir mi?


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()  # Bu karedeki başlangıç durumu
	# kralinyo sağ sol yaparken dönerken

	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal(delta)
	move_and_slide()  # Hareketi uygular ve çarpışmaları halleder

	# Havadan yere yeni indiysek
	if is_on_floor() and not was_on_floor:
		_on_landed()

# -----------------------------------------------------
#  Yere iniş anında bir kez çalışır
# -----------------------------------------------------
func _on_landed() -> void:
	if not reset_slide_on_land:
		return

	var direction := Input.get_axis("sola", "saga")
	# Tuş bırakılmışsa (veya ayar açıksa) kaymayı sıfırla
	if direction == 0.0 or reset_even_when_holding:
		velocity.x = 0.0


# -----------------------------------------------------
#  Sayaçlar: coyote time ve jump buffer
# -----------------------------------------------------
func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time   # Yerdeyken sayaç sürekli dolu
		jumps_left = max_jumps       # Yere değince zıplama hakkı yenilenir
	else:
		coyote_timer -= delta        # Havadayken sayaç azalır
		# Zıplamadan kenardan düştüysek ve coyote süresi bittiyse
		# yerden zıplama hakkını say (yoksa havada fazladan zıplama bedava olur)
		if coyote_timer <= 0.0 and jumps_left == max_jumps:
			jumps_left = max_jumps - 1

	jump_buffer_timer -= delta

	if Input.is_action_just_pressed("zipla"):
		jump_buffer_timer = jump_buffer_time  # Tuşa basıldığını hatırla
	if Input.is_action_just_pressed("saga"):
		$Sprite2D.flip_h = false
	if Input.is_action_just_pressed("sola"):
		$Sprite2D.flip_h = true

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

		# Yerden zıplamada kısaltma açık, havada (double jump) KAPALI
		# Yani havada tuşa kısa bassan bile tam yükseklikte zıplar
		can_cut_jump = can_ground_jump

		# Celeste hissi: bir yöne giderken zıplama anında ters yöne basılıysa
		# hızı anında o yöne çevir (iniş momentumu seni ters yöne taşımasın)
		if flip_speed_on_jump:
			var dir := Input.get_axis("sola", "saga")
			if dir != 0.0 and signf(velocity.x) == -dir:
				velocity.x = dir * max_speed * flip_speed_ratio

	# Tuşu erken bırakınca zıplamayı kes (sadece yerden yapılan zıplamada)
	if Input.is_action_just_released("zipla") and velocity.y < 0 and can_cut_jump:
		velocity.y *= jump_cut


# -----------------------------------------------------
#  Sağ / sol hareket
# -----------------------------------------------------
func _handle_horizontal(delta: float) -> void:
	# -1 (sol), 0 (yok), 1 (sağ)
	var direction := Input.get_axis("sola", "saga")

	# Havadaysak kontrol gücü azalır
	var control := 1.0 if is_on_floor() else air_control

	if direction != 0.0:
		# Ters yöne basıyorsak daha güçlü hızlanma kullan (keskin dönüş)
		var accel := acceleration
		if signf(velocity.x) == -direction:
			accel = turn_acceleration

		# Tuşa basılıyor: hedef hıza doğru hızlan
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * control * delta)
	else:
		# Tuş yok: sürtünmeyle yavaşla
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


#bunu ben yazdım
