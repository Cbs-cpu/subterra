class_name Actor
extends Node2D
## Cuerpo con física de plataformas contra la rejilla de tiles (sin física de Godot).
## `position` = centro inferior (los pies). Se mueve en _physics_process del mundo, así la
## interpolación de física suaviza el render.

const GRAVITY := 980.0
const MAX_FALL := 430.0

var world: Node
var vel := Vector2.ZERO
var size := Vector2(10, 20)
var gravity_scale := 1.0
var use_gravity := true
var noclip := false
var on_floor := false
var on_wall := 0
var hit_ceiling := false
var drop_t := 0.0                 # atravesando plataformas hacia abajo
var facing := 1
var dead := false
var net_id := 0                   # identificador para la red
var flash_t := 0.0


func tick(_dt: float) -> void:
	pass


func rect() -> Rect2:
	return Rect2(position.x - size.x / 2.0, position.y - size.y, size.x, size.y)


func center() -> Vector2:
	return position - Vector2(0, size.y / 2.0)


## Integra gravedad y mueve con colisión.
func physics_move(dt: float) -> void:
	if use_gravity and not noclip:
		vel.y = min(vel.y + GRAVITY * gravity_scale * dt, MAX_FALL)
	if drop_t > 0.0:
		drop_t -= dt
	if noclip:
		position += vel * dt
		return
	var motion := vel * dt
	var steps := int(ceil(max(absf(motion.x), absf(motion.y)) / 6.0))
	steps = maxi(steps, 1)
	var part := motion / steps
	on_wall = 0
	hit_ceiling = false
	var was_floor := on_floor
	on_floor = false
	for _i in steps:
		_move_x(part.x)
		_move_y(part.y)
	# Apoyado exactamente sobre una superficie (p. ej. sin velocidad vertical durante el dash).
	if not on_floor and vel.y >= 0.0 and drop_t <= 0.0 and _floor_below(position + Vector2(0, 1)):
		on_floor = true
	# Pegado al suelo al bajar pendientes de 1 tile (evita "saltitos").
	if was_floor and not on_floor and vel.y >= 0.0 and drop_t <= 0.0:
		for k in range(1, 5):
			if _floor_below(position + Vector2(0, k)):
				position.y += k
				on_floor = true
				vel.y = 0.0
				break


func _move_x(dx: float) -> void:
	if dx == 0.0:
		return
	position.x += dx
	var r := rect()
	var t: int = world.T
	var y0 := floori(r.position.y / t)
	var y1 := floori((r.end.y - 0.01) / t)
	if dx > 0.0:
		var tx := floori((r.end.x - 0.01) / t)
		for ty in range(y0, y1 + 1):
			if world.tile(tx, ty) == 1:
				position.x = tx * t - size.x / 2.0
				on_wall = 1
				vel.x = min(vel.x, 0.0)
				return
	else:
		var tx2 := floori(r.position.x / t)
		for ty in range(y0, y1 + 1):
			if world.tile(tx2, ty) == 1:
				position.x = (tx2 + 1) * t + size.x / 2.0
				on_wall = -1
				vel.x = max(vel.x, 0.0)
				return


func _move_y(dy: float) -> void:
	if dy == 0.0:
		return
	var prev_bottom := position.y
	position.y += dy
	var r := rect()
	var t: int = world.T
	var x0 := floori(r.position.x / t)
	var x1 := floori((r.end.x - 0.01) / t)
	if dy > 0.0:
		var ty := floori((position.y - 0.01) / t)
		for tx in range(x0, x1 + 1):
			var m: int = world.tile(tx, ty)
			if m == 1 or (m == 2 and drop_t <= 0.0 and prev_bottom <= ty * t + 0.5):
				position.y = ty * t
				on_floor = true
				vel.y = 0.0
				return
	else:
		var ty2 := floori(r.position.y / t)
		for tx in range(x0, x1 + 1):
			if world.tile(tx, ty2) == 1:
				position.y = (ty2 + 1) * t + size.y
				hit_ceiling = true
				vel.y = 0.0
				return


func _floor_below(p: Vector2) -> bool:
	var t: int = world.T
	var ty := floori((p.y - 0.01) / t)
	var x0 := floori((p.x - size.x / 2.0) / t)
	var x1 := floori((p.x + size.x / 2.0 - 0.01) / t)
	for tx in range(x0, x1 + 1):
		var m: int = world.tile(tx, ty)
		if m == 1 or (m == 2 and drop_t <= 0.0):
			return true
	return false


func standing_on_oneway() -> bool:
	var t: int = world.T
	var ty := floori(position.y / t)
	var x0 := floori((position.x - size.x / 2.0) / t)
	var x1 := floori((position.x + size.x / 2.0 - 0.01) / t)
	for tx in range(x0, x1 + 1):
		if world.tile(tx, ty) == 1:
			return false
	for tx in range(x0, x1 + 1):
		if world.tile(tx, ty) == 2:
			return true
	return false


## Si quedó dentro de un sólido, lo saca hacia arriba.
func unstuck() -> void:
	for k in 40:
		if not _overlaps_solid():
			return
		position.y -= 4


func _overlaps_solid() -> bool:
	var r := rect()
	var t: int = world.T
	for ty in range(floori(r.position.y / t), floori((r.end.y - 0.01) / t) + 1):
		for tx in range(floori(r.position.x / t), floori((r.end.x - 0.01) / t) + 1):
			if world.tile(tx, ty) == 1:
				return true
	return false


func teleport(p: Vector2) -> void:
	position = p
	reset_physics_interpolation()
