extends Area2D

# Sahne yapısı:
# Bullet (Area2D)  <- bu script burada
# ├── Sprite2D
# └── CollisionShape2D

# =====================================================
#  AYARLAR
# =====================================================

## Mermi hızı (piksel/saniye)
@export var speed: float = 700.0
## Mermi kaç saniye sonra kendiliğinden yok olsun
@export var lifetime: float = 2.0
## Çarptığı şeye verdiği hasar
@export var damage: int = 1

# =====================================================
#  İÇ DEĞİŞKENLER
# =====================================================

var direction: Vector2 = Vector2.RIGHT  # Silah tarafından atanır
var age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Düz çizgide ilerle
	global_position += direction * speed * delta

	# Süresi dolunca yok ol
	age += delta
	if age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Kendi karakterine çarpıp yok olmasın
	if body.is_in_group("player"):
		return

	# Çarptığı şeyde take_damage(miktar) fonksiyonu varsa hasar ver
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
