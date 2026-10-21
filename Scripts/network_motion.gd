extends RefCounted

# İki ağ güncellemesi arasındaki hareketi her görüntü karesinde çizer.
# Saatler eşit olmak zorunda değil; paketin bu bilgisayara geliş zamanı kullanılır.
const BUFFER_SECONDS: float = 0.067
const TELEPORT_DISTANCE: float = 256.0
const MAX_SAMPLES: int = 32
var samples: Array[Dictionary] = []

func clear() -> void:
	samples.clear()

func push(time: float, pos: Vector2, angle: float) -> void:
	if not samples.is_empty():
		var last: Dictionary = samples.back()
		if time <= float(last.time):
			return
		if pos.distance_to(last.position) > TELEPORT_DISTANCE:
			clear()
	samples.append({"time": time, "position": pos, "angle": angle})
	if samples.size() > MAX_SAMPLES:
		samples.pop_front()

func sample(now: float) -> Dictionary:
	if samples.is_empty():
		return {}
	var render_time := now - BUFFER_SECONDS
	while samples.size() > 2 and float(samples[1].time) <= render_time:
		samples.pop_front()
	if samples.size() == 1 or render_time <= float(samples[0].time):
		return samples[0]
	var first: Dictionary = samples[0]
	var second: Dictionary = samples[1]
	var weight := clampf((render_time - float(first.time)) / (float(second.time) - float(first.time)), 0.0, 1.0)
	return {
		"position": (first.position as Vector2).lerp(second.position, weight),
		"angle": lerp_angle(float(first.angle), float(second.angle), weight),
	}
