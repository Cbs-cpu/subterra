extends Node
## Cooperativo online (ENet), hasta 4 jugadores. El anfitrión es autoritativo: simula el mundo,
## recibe la entrada de los clientes y les envía instantáneas del estado a 20 Hz. Los clientes
## generan el mismo mapa por semilla y solo reciben lo dinámico (entidades, inventario propio).

signal start_game(config: Dictionary)
signal lobby_changed

const MAX_PLAYERS := 4
const SNAP_RATE := 1.0 / 20.0

var mode := "off"               # off, host, client
var lobby := {}                 # peer_id -> config del héroe
var status := ""
var snap_t := 0.0
var model_t := 0.0
var input_acc: InputState
var run_ref: Node
var last_snap := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func(): status = "No se pudo conectar"; leave())
	multiplayer.server_disconnected.connect(_on_server_gone)


func is_online() -> bool:
	return mode != "off"


func is_host() -> bool:
	return mode == "host"


func is_client() -> bool:
	return mode == "client"


func status_text() -> String:
	return status


func lobby_list() -> Array:
	var out := []
	var keys := lobby.keys()
	keys.sort()
	for k in keys:
		out.append(lobby[k])
	return out


# --- Sala -----------------------------------------------------------------------------------

func host(port: int, cfg: Dictionary) -> void:
	leave()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		status = "No se pudo crear la partida (puerto %d ocupado)" % port
		return
	multiplayer.multiplayer_peer = p
	mode = "host"
	cfg = cfg.duplicate(true)
	cfg["peer"] = 1
	lobby = {1: cfg}
	status = "Esperando jugadores en el puerto %d..." % port
	lobby_changed.emit()


func join(ip: String, port: int, cfg: Dictionary) -> void:
	leave()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, port)
	if err != OK:
		status = "Dirección no válida"
		return
	multiplayer.multiplayer_peer = p
	mode = "client"
	status = "Conectando con %s..." % ip
	set_meta("my_cfg", cfg.duplicate(true))


func leave() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = "off"
	lobby = {}
	run_ref = null


func _on_connected() -> void:
	status = "Conectado. Esperando a que el anfitrión empiece."
	_register.rpc_id(1, get_meta("my_cfg", {}))


func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if is_host():
		lobby.erase(id)
		_lobby.rpc(lobby)
		lobby_changed.emit()
		if run_ref and run_ref.world:
			for h in run_ref.world.players:
				if h.peer_id == id:
					h.downed = true
					run_ref.notify("%s se ha desconectado" % h.model.name, Color("#ffb0a0"))


func _on_server_gone() -> void:
	status = "El anfitrión se ha desconectado"
	var r := run_ref
	leave()
	if r and is_instance_valid(r):
		r.ui.quit_to_menu.emit()


@rpc("any_peer", "reliable")
func _register(cfg: Dictionary) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if lobby.size() >= MAX_PLAYERS:
		return
	cfg["peer"] = id
	lobby[id] = cfg
	_lobby.rpc(lobby)
	lobby_changed.emit()


@rpc("authority", "reliable")
func _lobby(l: Dictionary) -> void:
	lobby = l
	lobby_changed.emit()


func start(seed_value: int, madman: bool) -> void:
	if not is_host():
		return
	var heroes := []
	var keys := lobby.keys()
	keys.sort()
	for k in keys:
		heroes.append(lobby[k])
	var config := {"seed": seed_value, "madman": madman, "heroes": heroes}
	for k in keys:
		if k != 1:
			var c := config.duplicate(true)
			c["local_peer"] = k
			_start.rpc_id(k, c)
	var mine := config.duplicate(true)
	mine["local_peer"] = 1
	start_game.emit(mine)


@rpc("authority", "reliable")
func _start(config: Dictionary) -> void:
	start_game.emit(config)


# --- Durante la partida -------------------------------------------------------------------------

func on_world_changed(run: Node) -> void:
	run_ref = run
	if is_host():
		_world.rpc(run.state, run.biome if run.state == "district" else run.next_biome, run.district)


@rpc("authority", "reliable")
func _world(state: String, biome: String, district: int) -> void:
	if run_ref == null or not is_instance_valid(run_ref):
		return
	if run_ref.world and run_ref.state == state and run_ref.district == district and \
			(run_ref.biome == biome or run_ref.next_biome == biome):
		return
	run_ref.district = district
	if state == "town":
		run_ref.enter_town(biome)
	else:
		run_ref.enter_district(biome)


func after_tick(w: Node) -> void:
	if not is_online():
		return
	var dt := 1.0 / 60.0
	if is_host():
		snap_t += dt
		if snap_t >= SNAP_RATE:
			snap_t = 0.0
			_snap.rpc(_make_snapshot(w))
		model_t += dt
		if model_t >= 0.25:
			model_t = 0.0
			for h in w.players:
				if h.peer_id != 1 and multiplayer.get_peers().has(h.peer_id):
					_model.rpc_id(h.peer_id, h.model.to_data())
	else:
		var inp := InputState.from_local(w.mouse_world(), run_ref.ui.blocks_game_input())
		if input_acc == null:
			input_acc = inp
		else:
			inp.merge_edges(input_acc)
			input_acc = inp
		snap_t += dt
		if snap_t >= 1.0 / 30.0:
			snap_t = 0.0
			_net_input.rpc_id(1, input_acc.to_dict())
			input_acc = null


@rpc("any_peer", "reliable")
func _net_input(d: Dictionary) -> void:
	if not is_host() or run_ref == null:
		return
	var id := multiplayer.get_remote_sender_id()
	var inp := InputState.from_dict(d)
	var prev = run_ref.remote_inputs.get(id)
	if prev != null:
		inp.merge_edges(prev)
	run_ref.remote_inputs[id] = inp


@rpc("authority", "reliable")
func _model(d: Dictionary) -> void:
	if run_ref == null or not run_ref.models.has(run_ref.local_peer):
		return
	run_ref.models[run_ref.local_peer].from_data(d)


func send_action(a: Dictionary) -> void:
	_action.rpc_id(1, a)


@rpc("any_peer", "reliable")
func _action(a: Dictionary) -> void:
	if not is_host() or run_ref == null or run_ref.world == null:
		return
	var id := multiplayer.get_remote_sender_id()
	for h in run_ref.world.players:
		if h.peer_id == id:
			var msg := InvOps.apply(run_ref, h.model, a, h)
			if msg != "":
				_say.rpc_id(id, msg)
			_model.rpc_id(id, h.model.to_data())


@rpc("authority", "reliable")
func _say(msg: String) -> void:
	if run_ref:
		run_ref.ui.say(msg)


func send_skill_offer(h: Node) -> void:
	_skill_offer.rpc_id(h.peer_id)


@rpc("authority", "reliable")
func _skill_offer() -> void:
	var h = run_ref.ui.local_hero() if run_ref else null
	if h:
		run_ref.ui.open_skill_pick(h)


func send_open_npc(h: Node, npc: Node) -> void:
	_open_npc.rpc_id(h.peer_id, npc.net_id)


@rpc("authority", "reliable")
func _open_npc(npc_id: int) -> void:
	if run_ref == null or run_ref.world == null:
		return
	for n in run_ref.world.npcs:
		if n.net_id == npc_id:
			run_ref.ui.open_npc(n, run_ref.ui.local_hero())


func send_notify(text: String, col: Color) -> void:
	if is_host():
		_notify.rpc(text, col.to_html())


@rpc("authority", "reliable")
func _notify(text: String, col: String) -> void:
	if run_ref:
		run_ref.ui.notify(text, Color(col))


func send_end(result: Dictionary) -> void:
	if is_host():
		_end.rpc(result)


@rpc("authority", "reliable")
func _end(result: Dictionary) -> void:
	if run_ref and not run_ref.finished:
		run_ref.finished = true
		run_ref.ended.emit(result)


# --- Instantáneas -----------------------------------------------------------------------------

func _make_snapshot(w: Node) -> Dictionary:
	var ps := []
	for h in w.players:
		var held = h.model.inv.held()
		ps.append([h.peer_id, h.position.x, h.position.y, h.vel.x, h.vel.y, h.facing, h.on_floor, h.attack_t, h.attack_len,
			h.dash_t, h.hurt_t, h.downed, h.invuln, h.aim_angle, h.model.hp, "" if held == null else held["id"], h.flash_t])
	var es := []
	for e in w.enemies:
		es.append([e.net_id, e.id, e.position.x, e.position.y, e.facing, e.state, e.attacking, e.concealed, e.hp, e.max_hp,
			e.flash_t, e.vel.x, e.vel.y])
	var prs := []
	for p in w.projectiles:
		prs.append([p.net_id, p.kind, p.position.x, p.position.y, p.vel.x, p.vel.y, p.pal])
	var pks := []
	for p in w.pickups:
		pks.append([p.net_id, p.kind, p.position.x, p.position.y, p.stack.get("id", "") if p.kind == "item" else "", p.value])
	var nodes := []
	for n in w.nodes:
		nodes.append([n.net_id, n.open, n.shake_t])
	var hz := []
	for h2 in w.hazards:
		hz.append([h2.net_id, h2.position.x, h2.position.y])
	var sm := []
	for s in w.summons:
		sm.append([s.net_id, s.kind, s.position.x, s.position.y])
	return {"p": ps, "e": es, "pr": prs, "pk": pks, "n": nodes, "hz": hz, "sm": sm, "t": w.time_in,
		"boss": w.boss_node.net_id if w.boss_node != null and is_instance_valid(w.boss_node) else -1}


@rpc("authority", "unreliable_ordered")
func _snap(s: Dictionary) -> void:
	last_snap = s


## Aplica la última instantánea al mundo del cliente (se llama cada tick de física).
func apply_snapshot(w: Node, dt: float) -> void:
	var s := last_snap
	if s.is_empty():
		return
	w.time_in = s["t"]
	for row in s["p"]:
		for h in w.players:
			if h.peer_id == int(row[0]):
				_lerp_to(h, Vector2(row[1], row[2]))
				h.vel = Vector2(row[3], row[4])
				h.facing = int(row[5])
				h.on_floor = row[6]
				h.attack_t = row[7]
				h.attack_len = maxf(0.01, row[8])
				h.dash_t = row[9]
				h.hurt_t = row[10]
				h.downed = row[11]
				h.invuln = row[12]
				h.aim_angle = row[13]
				h.model.hp = int(row[14])
				h.set_meta("held", row[15])
				h.flash_t = row[16]
				h.anim_t += dt
				if absf(h.vel.x) > 5.0 and h.on_floor:
					h.run_dist += absf(h.vel.x) * dt
				h.companion_t += dt
				h.queue_redraw()
	_sync_list(w, w.enemies, s["e"], func(row):
		var e := Enemy.new()
		e.position = Vector2(row[2], row[3])
		e.setup_enemy(w, row[1], w.district, false)
		e.net_id = int(row[0])
		w.layer_actors.add_child(e)
		return e,
		func(e, row):
			_lerp_to(e, Vector2(row[2], row[3]))
			e.facing = int(row[4])
			e.state = row[5]
			e.attacking = row[6]
			e.concealed = row[7]
			e.hp = row[8]
			e.max_hp = row[9]
			e.flash_t = row[10]
			e.vel = Vector2(row[11], row[12])
			e.anim_t += dt
			e.queue_redraw())
	_sync_list(w, w.projectiles, s["pr"], func(row):
		var p := Projectile.new()
		p.setup(w, {"kind": row[1], "pos": Vector2(row[2], row[3]), "vel": Vector2(row[4], row[5]), "pal": row[6]})
		p.net_id = int(row[0])
		w.layer_front.add_child(p)
		return p,
		func(p, row):
			p.position = p.position.lerp(Vector2(row[2], row[3]), 0.5) + Vector2(row[4], row[5]) * dt
			p.vel = Vector2(row[4], row[5])
			p.t += dt
			p.trail_t += dt
			if p.trail_t > 0.025 and p.glow.a > 0.0:
				p.trail_t = 0.0
				p.trail.push_front(p.global_position)
				if p.trail.size() > 10:
					p.trail.pop_back()
			p.queue_redraw())
	_sync_list(w, w.pickups, s["pk"], func(row):
		var p := Pickup.new()
		p.world = w
		p.kind = row[1]
		p.position = Vector2(row[2], row[3])
		p.stack = {"id": row[4], "n": 1} if row[1] == "item" else {}
		p.value = int(row[5])
		p.net_id = int(row[0])
		w.layer_mid.add_child(p)
		return p,
		func(p, row):
			_lerp_to(p, Vector2(row[2], row[3]))
			p.t += dt
			p.queue_redraw())
	var node_state := {}
	for row in s["n"]:
		node_state[int(row[0])] = row
	for n in w.nodes:
		if not node_state.has(n.net_id):
			if not n.dead:
				n.dead = true
				n.visible = false
		else:
			var row: Array = node_state[n.net_id]
			n.open = row[1]
			n.shake_t = row[2]
			n.t += dt
			n.queue_redraw()
	var hz := {}
	for row in s["hz"]:
		hz[int(row[0])] = row
	for h2 in w.hazards:
		if hz.has(h2.net_id):
			h2.position = h2.position.lerp(Vector2(hz[h2.net_id][1], hz[h2.net_id][2]), 0.5)
			h2.t += dt
			h2.queue_redraw()
		else:
			h2.visible = false
	_sync_list(w, w.summons, s["sm"], func(row):
		var sm := Summon.new()
		sm.world = w
		sm.kind = row[1]
		sm.position = Vector2(row[2], row[3])
		sm.net_id = int(row[0])
		w.layer_front.add_child(sm)
		return sm,
		func(sm, row):
			sm.position = Vector2(row[2], row[3])
			sm.t += dt
			sm.queue_redraw())
	w.boss_node = null
	for e in w.enemies:
		if e.net_id == int(s["boss"]):
			w.boss_node = e
	for n in w.npcs:
		n.t += dt
		n.queue_redraw()


func _lerp_to(n: Node2D, target: Vector2) -> void:
	if n.position.distance_to(target) > 64.0:
		n.position = target
		n.reset_physics_interpolation()
	else:
		n.position = n.position.lerp(target, 0.4)


func _sync_list(w: Node, list: Array, rows: Array, make: Callable, update: Callable) -> void:
	var by_id := {}
	for e in list:
		by_id[e.net_id] = e
	var seen := {}
	for row in rows:
		var id := int(row[0])
		seen[id] = true
		var e = by_id.get(id)
		if e == null:
			e = make.call(row)
			list.append(e)
		update.call(e, row)
	for i in range(list.size() - 1, -1, -1):
		if not seen.has(list[i].net_id):
			list[i].queue_free()
			list.remove_at(i)
