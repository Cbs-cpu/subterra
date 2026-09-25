class_name InputState
extends RefCounted
## Intenciones de un jugador en un tick. Sale del teclado/ratón/mando (local) o de la red
## (remoto). El resto del juego solo lee esto: jugador local y remoto usan el mismo código.

var move := Vector2.ZERO
var jump := false
var jump_pressed := false
var dash := 0
var use := false
var use_pressed := false
var interact := false
var aim := Vector2.ZERO        # posición del mundo a la que apunta
var hotbar := -1
var skill := -1
var drop := false
var down_pressed := false


## Lee la entrada local. ui_open bloquea las acciones de juego (sigue permitiendo moverse).
static func from_local(world_aim: Vector2, ui_open: bool) -> InputState:
	var s := InputState.new()
	s.move = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	s.jump = Input.is_action_pressed("jump")
	s.jump_pressed = Input.is_action_just_pressed("jump")
	s.down_pressed = Input.is_action_just_pressed("down")
	if Input.is_action_just_pressed("dash_l"):
		s.dash = -1
	elif Input.is_action_just_pressed("dash_r"):
		s.dash = 1
	s.aim = world_aim
	if not ui_open:
		s.use = Input.is_action_pressed("use")
		s.use_pressed = Input.is_action_just_pressed("use")
		s.interact = Input.is_action_just_pressed("interact")
		for i in 3:
			if Input.is_action_just_pressed("skill%d" % (i + 1)):
				s.skill = i
		s.drop = Input.is_action_just_pressed("drop")
	for i in Inventory.HOTBAR:
		if Input.is_action_just_pressed("hot%d" % (i + 1)):
			s.hotbar = i
	return s


func to_dict() -> Dictionary:
	return {"m": [move.x, move.y], "j": jump, "jp": jump_pressed, "d": dash, "u": use, "up": use_pressed,
		"i": interact, "a": [aim.x, aim.y], "h": hotbar, "s": skill, "dr": drop, "dp": down_pressed}


static func from_dict(d: Dictionary) -> InputState:
	var s := InputState.new()
	s.move = Vector2(d["m"][0], d["m"][1])
	s.jump = d["j"]
	s.jump_pressed = d["jp"]
	s.dash = d["d"]
	s.use = d["u"]
	s.use_pressed = d["up"]
	s.interact = d["i"]
	s.aim = Vector2(d["a"][0], d["a"][1])
	s.hotbar = d["h"]
	s.skill = d["s"]
	s.drop = d["dr"]
	s.down_pressed = d["dp"]
	return s


## Acumula pulsaciones (para la red, que envía a menos frecuencia que la física).
func merge_edges(o: InputState) -> void:
	jump_pressed = jump_pressed or o.jump_pressed
	use_pressed = use_pressed or o.use_pressed
	interact = interact or o.interact
	drop = drop or o.drop
	down_pressed = down_pressed or o.down_pressed
	if o.dash != 0:
		dash = o.dash
	if o.hotbar >= 0:
		hotbar = o.hotbar
	if o.skill >= 0:
		skill = o.skill
