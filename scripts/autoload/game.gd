extends Node
## Estado global: perfil (desbloqueos y estadísticas), ajustes, controles y guardado.

const PROFILE_PATH := "user://perfil.json"
const RUN_PATH := "user://partida.json"

var settings := {"sfx": 0.8, "music": 0.5, "shake": true, "fullscreen": false}
var owned := Progression.default_owned()
var global_stats := {"runs": 0, "wins": 0, "kills": 0, "golden_chests": 0, "deaths": 0, "best_district": 0}
var keybinds := {}
var recipes_known: Array = []

const ACTIONS := {
	"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S], "jump": [KEY_SPACE],
	"dash_l": [KEY_Q], "dash_r": [KEY_E], "interact": [KEY_F], "inventory": [KEY_R], "pause": [KEY_ESCAPE],
	"map": [KEY_TAB], "skill1": [KEY_Z], "skill2": [KEY_X], "skill3": [KEY_C], "drop": [KEY_G],
	"ui_ok": [KEY_ENTER],
}
const LABELS := {
	"left": "Izquierda", "right": "Derecha", "up": "Arriba", "down": "Abajo / bajar plataforma", "jump": "Saltar",
	"dash_l": "Dash izquierda", "dash_r": "Dash derecha", "interact": "Interactuar", "inventory": "Inventario",
	"map": "Mapa", "skill1": "Habilidad 1", "skill2": "Habilidad 2", "skill3": "Habilidad 3", "drop": "Tirar objeto",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()
	_setup_input()
	apply_settings()


func _setup_input() -> void:
	for a in ACTIONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.35)
		InputMap.action_erase_events(a)
		var keys: Array = keybinds.get(a, ACTIONS[a])
		for k in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = int(k)
			InputMap.action_add_event(a, ev)
	for i in 8:
		var a := "hot%d" % (i + 1)
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		InputMap.action_erase_events(a)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_1 + i
		InputMap.action_add_event(a, ev)
	if not InputMap.has_action("use"):
		InputMap.add_action("use")
	InputMap.action_erase_events("use")
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("use", mb)
	# Mando.
	_pad("jump", JOY_BUTTON_A)
	_pad("interact", JOY_BUTTON_Y)
	_pad("inventory", JOY_BUTTON_BACK)
	_pad("pause", JOY_BUTTON_START)
	_pad("dash_l", JOY_BUTTON_LEFT_SHOULDER)
	_pad("dash_r", JOY_BUTTON_RIGHT_SHOULDER)
	_pad("use", JOY_BUTTON_X)
	_pad("skill1", JOY_BUTTON_B)
	_axis("left", JOY_AXIS_LEFT_X, -1.0)
	_axis("right", JOY_AXIS_LEFT_X, 1.0)
	_axis("up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("down", JOY_AXIS_LEFT_Y, 1.0)


func _pad(a: String, b: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	InputMap.action_add_event(a, ev)


func _axis(a: String, axis: JoyAxis, v: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = v
	InputMap.action_add_event(a, ev)


func rebind(action: String, keycode: int) -> void:
	keybinds[action] = [keycode]
	_setup_input()
	save_profile()


func key_label(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
	return "-"


func apply_settings() -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "SFX")
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "Music")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(max(float(settings["sfx"]), 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(max(float(settings["music"]), 0.0001)))
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)


# --- Perfil -----------------------------------------------------------------------

func load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return
	settings.merge(d.get("settings", {}), true)
	var o: Dictionary = d.get("owned", {})
	for k in owned:
		for id in o.get(k, []):
			if not owned[k].has(id):
				owned[k].append(id)
	global_stats.merge(d.get("stats", {}), true)
	keybinds = d.get("keybinds", {})
	recipes_known = d.get("recipes", [])


func save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"settings": settings, "owned": owned, "stats": global_stats, "keybinds": keybinds, "recipes": recipes_known}))


func is_owned(kind: String, id: String) -> bool:
	return owned.get(kind, []).has(id)


func grant(unlocks: Array) -> void:
	for u in unlocks:
		if not owned[u["kind"]].has(u["id"]):
			owned[u["kind"]].append(u["id"])
	save_profile()


# --- Partida guardada -------------------------------------------------------------

func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)


func save_run(data: Dictionary) -> void:
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_run() -> Dictionary:
	if not has_saved_run():
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func clear_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))


func learn_recipe(a: String, b: String) -> void:
	var k := Recipes.key(a, b)
	if not recipes_known.has(k):
		recipes_known.append(k)


func known_recipes() -> Array:
	return recipes_known
