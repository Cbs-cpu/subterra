extends Node
## Cooperativo online (provisional: modo un jugador).

func is_online() -> bool:
	return false


func is_client() -> bool:
	return false


func after_tick(_w) -> void:
	pass


func on_world_changed(_run) -> void:
	pass


func send_skill_offer(_h) -> void:
	pass


func send_open_npc(_h, _n) -> void:
	pass


func send_notify(_t, _c) -> void:
	pass


func send_end(_r) -> void:
	pass


func send_action(_a) -> void:
	pass


signal start_game(config: Dictionary)


func host(_port: int, _cfg: Dictionary) -> void:
	pass


func join(_ip: String, _port: int, _cfg: Dictionary) -> void:
	pass


func is_host() -> bool:
	return false


func start(_seed: int, _madman: bool) -> void:
	pass


func leave() -> void:
	pass


func status_text() -> String:
	return ""


func lobby_list() -> Array:
	return []
