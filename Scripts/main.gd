extends Node2D

const PORT := 7777
const STATE_INTERVAL: float = 1.0 / 30.0
const NetworkMotion = preload("res://Scripts/network_motion.gd")
var remote_motion := NetworkMotion.new()
var sprite_origin := Vector2.ZERO
var guest_id: int = 0
var playing := false
var connecting := false
var connect_time := 0.0
var send_time := 0.0
var local_player: CharacterBody2D
var guest: CharacterBody2D
var camera: Camera2D
var menu: PanelContainer
var address: LineEdit
var status: Label
var hud: Label
var session_note := ""
var health_label: Label
var shot_sequence: int = 0
var predicted_shots: Dictionary = {}

func _ready() -> void:
	# Hareketi oyuncunun fizik adımından sonra, sabit aralıklarla gönder.
	process_physics_priority = 100
	sprite_origin = $player/Sprite2D.position
	# Both peers use identical node paths for RPCs and player references.
	guest = $player.duplicate()
	guest.name = "guest"
	guest.position = Vector2(650, 338)
	guest.get_node("Camera2D").enabled = false
	add_child(guest)
	guest.get_node("Sprite2D").modulate = Color(0.4, 0.75, 1.0)
	guest.visible = false
	guest.collision_layer = 0
	$player.collision_layer = 4
	camera = $player/Camera2D
	var bounds: Rect2 = $Arkaplan.get_global_transform() * $Arkaplan.get_rect()
	camera.limit_left = ceili(bounds.position.x)
	camera.limit_top = ceili(bounds.position.y)
	camera.limit_right = floori(bounds.end.x)
	camera.limit_bottom = floori(bounds.end.y)
	_fit_camera_to_map()
	get_viewport().size_changed.connect(_fit_camera_to_map)
	camera.reset_smoothing()
	_build_ui()
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): _leave("Bağlanılamadı. IP, UDP 7777 ve güvenlik duvarını kontrol et."))
	multiplayer.server_disconnected.connect(func(): _leave("Odayı kuran oyuncu ayrıldı."))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$crosshair.hide()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	menu = PanelContainer.new()
	menu.custom_minimum_size = Vector2(580, 360)
	center.add_child(menu)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	menu.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "SİLAHA SOKAN • 2 OYUNCU"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	address = LineEdit.new()
	address.placeholder_text = "Odayı kuran kişinin IP adresi"
	address.text = "127.0.0.1"
	box.add_child(address)
	for item in [["Oda kur", host_game], ["IP ile katıl", join_game], ["Tek başına dene", solo_game], ["Bağlantıyı kes / Menü", func(): _leave("Bağlantı kapatıldı.")]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(item[1])
		box.add_child(button)
	status = Label.new()
	status.text = "İnternet: UDP 7777 portunu yönlendir veya ortak VPN ağı kullan.\nAynı bilgisayarda test: 127.0.0.1\nHareket: A/D • Zıpla: Space • Silah: 1/2 • Ateş: Sol tık\nEsc: Menü / Oyuna dön"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)

func host_game() -> void:
	_leave("")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 1)
	if error != OK:
		status.text = "Oda açılamadı: " + error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	_start($player)
	session_note = "Oda açık • UDP 7777 • Arkadaşın bekleniyor"

func join_game() -> void:
	var ip := address.text.strip_edges()
	_leave("")
	if ip.is_empty():
		status.text = "Odayı kuran kişinin IP adresini yaz."
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, PORT)
	if error != OK:
		status.text = "Bağlantı başlatılamadı: " + error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	connecting = true
	connect_time = 0.0
	status.text = "Bağlanılıyor: " + ip + ":7777"

func solo_game() -> void:
	_leave("")
	_start($player)
	session_note = "Tek oyuncu"

func _start(player: CharacterBody2D) -> void:
	_reset_remote_motion()
	send_time = 0.0
	playing = true
	connecting = false
	local_player = player
	$player.local_control = player == $player
	guest.local_control = player == guest
	camera.reparent(local_player, false)
	camera.position = Vector2.ZERO
	camera.enabled = true
	camera.make_current()
	camera.reset_smoothing()
	menu.hide()
	$crosshair.show()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

func _connected() -> void:
	# Client explicitly signals readiness before the host sends setup RPCs.
	client_ready.rpc_id(1)

func _peer_connected(_id: int) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func client_ready() -> void:
	if not multiplayer.is_server() or guest_id != 0:
		return
	guest_id = multiplayer.get_remote_sender_id()
	_reset_remote_motion()
	guest.visible = true
	guest.collision_layer = 4
	guest.position = Vector2(650, 338)
	guest.health = 100
	guest.score = 0
	setup_guest.rpc_id(guest_id, guest_id)
	sync_health.rpc($player.health, guest.health, $player.score, guest.score)
	session_note = "Arkadaşın bağlandı • 2/2 oyuncu"

@rpc("authority", "call_remote", "reliable")
func setup_guest(id: int) -> void:
	guest_id = id
	guest.visible = true
	guest.collision_layer = 4
	_start(guest)
	session_note = "Odaya bağlandın • 2/2 oyuncu"

func _peer_disconnected(id: int) -> void:
	if multiplayer.is_server() and id == guest_id:
		_reset_remote_motion()
		guest_id = 0
		guest.hide()
		guest.collision_layer = 0
		session_note = "Arkadaşın ayrıldı • Yeniden katılabilir"

func _leave(message: String) -> void:
	predicted_shots.clear()
	shot_sequence = 0
	_reset_remote_motion()
	playing = false
	connecting = false
	$player.local_control = false
	guest.local_control = false
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	guest_id = 0
	guest.hide()
	guest.collision_layer = 0
	for player in [$player, guest]:
		player.velocity = Vector2.ZERO
		player.health = 100
		player.score = 0
		player.get_node("silaheksen").select_weapon(0)
	$player.position = Vector2(404, 338)
	guest.position = Vector2(650, 338)
	for child in get_children():
		if child is Area2D:
			child.queue_free()
	menu.show()
	status.text = message
	hud.text = ""
	$crosshair.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	# Yanıt gelmese bile ömrü dolan görsel mermileri listede tutma.
	for shot_id in predicted_shots.keys():
		var alive := false
		for bullet in predicted_shots[shot_id]:
			if is_instance_valid(bullet):
				alive = true
		if not alive:
			predicted_shots.erase(shot_id)
	if connecting:
		connect_time += delta
		if connect_time > 12.0:
			_leave("Bağlantı zaman aşımına uğradı. IP / UDP 7777 / VPN ayarını kontrol et.")
	if not playing:
		return
	_render_remote_player()
	hud.text = "%s\nCan: %d • Skor: %d - %d • 1: Pistol / 2: Pompalı • Esc: Menü" % [session_note, local_player.health, $player.score, guest.score]

func _physics_process(delta: float) -> void:
	if not playing:
		return
	send_time += delta
	if send_time < STATE_INTERVAL:
		return
	# Kalan süreyi koru; FPS değişince ağ güncelleme hızı değişmesin.
	send_time = fmod(send_time, STATE_INTERVAL)
	var axis = local_player.get_node("silaheksen")
	if multiplayer.is_server():
		if guest_id != 0:
			host_state.rpc(local_player.position, local_player.velocity, axis.rotation, axis.selected_weapon, local_player.get_node("Sprite2D").flip_h)
	else:
		client_state.rpc_id(1, local_player.position, local_player.velocity, axis.rotation, axis.selected_weapon, local_player.get_node("Sprite2D").flip_h)

func _apply_state(player: CharacterBody2D, pos: Vector2, vel: Vector2, angle: float, weapon: int, flip: bool) -> void:
	if not pos.is_finite() or not vel.is_finite() or not is_finite(angle) or weapon < 0 or weapon > 1:
		return
	player.position = pos
	player.velocity = vel
	remote_motion.push(Time.get_ticks_usec() / 1000000.0, pos, angle)
	player.get_node("silaheksen").select_weapon(weapon)
	player.get_node("Sprite2D").flip_h = flip
	_render_remote_player()

func _render_remote_player() -> void:
	if not playing or guest_id == 0:
		return
	var state: Dictionary = remote_motion.sample(Time.get_ticks_usec() / 1000000.0)
	if state.is_empty():
		return
	var remote_player = guest if multiplayer.is_server() else $player
	# Çarpışma gövdesi son gerçek konumda kalır; yalnızca görüntüyü yumuşat.
	var visual_offset: Vector2 = state.position - remote_player.position
	remote_player.get_node("Sprite2D").position = sprite_origin + visual_offset
	remote_player.get_node("silaheksen").position = visual_offset
	remote_player.get_node("silaheksen").rotation = state.angle

func _reset_remote_motion() -> void:
	remote_motion.clear()
	for player in [$player, guest]:
		player.get_node("Sprite2D").position = sprite_origin
		player.get_node("silaheksen").position = Vector2.ZERO

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func client_state(pos: Vector2, vel: Vector2, angle: float, weapon: int, flip: bool) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == guest_id:
		_apply_state(guest, pos, vel, angle, weapon, flip)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func host_state(pos: Vector2, vel: Vector2, angle: float, weapon: int, flip: bool) -> void:
	_apply_state($player, pos, vel, angle, weapon, flip)

func request_fire() -> void:
	if not playing or menu.visible:
		return
	var axis = local_player.get_node("silaheksen")
	if multiplayer.is_server():
		_server_fire(0, axis.rotation, axis.selected_weapon)
	else:
		var weapon = axis.weapons[axis.selected_weapon]
		if weapon.cooldown > 0.0:
			return
		shot_sequence += 1
		# Görseli hemen başlat; hasarı hâlâ yalnızca sunucu hesaplar.
		predicted_shots[shot_sequence] = weapon.shoot()
		fire_request.rpc_id(1, axis.rotation, axis.selected_weapon, shot_sequence, local_player.position)

@rpc("any_peer", "call_remote", "reliable")
func fire_request(angle: float, weapon: int, shot_id: int, origin: Vector2) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == guest_id:
		if shot_id <= 0 or not origin.is_finite():
			return
		_server_fire(1, angle, weapon, shot_id, origin)

func _server_fire(slot: int, angle: float, weapon: int, shot_id: int = 0, origin: Vector2 = Vector2.INF) -> void:
	if not is_finite(angle) or weapon < 0 or weapon > 1:
		if slot == 1:
			reject_shot.rpc_id(guest_id, shot_id)
		return
	var player = $player if slot == 0 else guest
	var axis = player.get_node("silaheksen")
	if axis.weapons[weapon].cooldown > 0.0:
		if slot == 1:
			reject_shot.rpc_id(guest_id, shot_id)
		return
	var shot_origin: Vector2 = player.position if slot == 0 else origin
	if guest_id != 0:
		show_shot.rpc(slot, shot_origin, angle, weapon, shot_id)
	else:
		show_shot(slot, player.position, angle, weapon)

@rpc("authority", "call_remote", "reliable")
func reject_shot(shot_id: int) -> void:
	for bullet in predicted_shots.get(shot_id, []):
		if is_instance_valid(bullet):
			bullet.queue_free()
	predicted_shots.erase(shot_id)

@rpc("authority", "call_local", "reliable")
func show_shot(slot: int, pos: Vector2, angle: float, weapon: int, shot_id: int = 0) -> void:
	if not multiplayer.is_server() and slot == 1 and shot_id > 0:
		# Onay gecikse veya görsel çoktan silinse de aynı atışı tekrar oluşturma.
		predicted_shots.erase(shot_id)
		return
	var player = $player if slot == 0 else guest
	var axis = player.get_node("silaheksen")
	# Use the host's shot origin even when a movement packet arrives later.
	var old_position: Vector2 = player.position
	var old_angle: float = axis.rotation
	var old_weapon: int = axis.selected_weapon
	var old_axis_position: Vector2 = axis.position
	player.position = pos
	# Yumuşatılmış görüntü ofseti, sunucudaki gerçek namlu konumunu değiştirmesin.
	axis.position = Vector2.ZERO
	axis.rotation = angle
	axis.select_weapon(weapon)
	axis.weapons[weapon].shoot()
	player.position = old_position
	axis.position = old_axis_position
	axis.rotation = old_angle
	if player == local_player:
		axis.select_weapon(old_weapon)

func damage_player(target: Object, shooter: Object, amount: int) -> void:
	if not playing or not multiplayer.is_server() or target not in [$player, guest] or target == shooter:
		return
	var hit_slot := 0 if target == $player else 1
	if guest_id != 0:
		show_hit_feedback.rpc(hit_slot)
	else:
		show_hit_feedback(hit_slot)
	target.health = maxi(0, target.health - amount)
	if target.health == 0:
		if shooter in [$player, guest]:
			shooter.score += 1
		if guest_id != 0:
			respawn.rpc(hit_slot)
		else:
			respawn(hit_slot)
	if guest_id != 0:
		sync_health.rpc($player.health, guest.health, $player.score, guest.score)

@rpc("authority", "call_local", "reliable")
func show_hit_feedback(slot: int) -> void:
	var player = $player if slot == 0 else guest
	player.show_hit_feedback()

@rpc("authority", "call_local", "reliable")
func respawn(slot: int) -> void:
	_reset_remote_motion()
	var player = $player if slot == 0 else guest
	player.position = Vector2(404, 338) if slot == 0 else Vector2(650, 338)
	player.velocity = Vector2.ZERO
	player.health = 100
	player.jump_count = 0
	player.buffercounter = 0.0

@rpc("authority", "call_remote", "reliable")
func sync_health(host_health: int, guest_health: int, host_score: int, guest_score: int) -> void:
	$player.health = host_health
	guest.health = guest_health
	$player.score = host_score
	guest.score = guest_score

func _fit_camera_to_map() -> void:
	var map_size := Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top)
	var viewport_size := get_viewport_rect().size
	var zoom_level := maxf(2.96, maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
	camera.zoom = Vector2.ONE * zoom_level

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and playing:
		menu.visible = not menu.visible
		local_player.local_control = not menu.visible
		$crosshair.visible = not menu.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu.visible else Input.MOUSE_MODE_CONFINED_HIDDEN
