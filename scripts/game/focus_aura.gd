class_name FocusAura
extends Node2D
## Aura dorada sobre lo que el jugador local tiene "a un clic": aquello con lo que puede
## interactuar (tecla de interactuar) o el recurso que su herramienta puede recoger.
##
## Hay dos capas: la de detrás (`front = false`) dibuja un halo suave y pone al sprite un
## contorno dorado que late (shaders/focus_outline.gdshader); la de delante (`front = true`)
## dibuja esquinas doradas alrededor del objeto, un brillo en el suelo y chispas, que se ven
## aunque el objeto sea grande y opaco (una tienda, una puerta).

const OUTLINE := preload("res://shaders/focus_outline.gdshader")

var targets: Array = []
var front := false
var t := 0.0
var _mat: ShaderMaterial
var _sparks: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = OUTLINE
	_rng.randomize()


## Cambia los objetos enfocados (pone y quita el contorno).
func set_targets(list: Array) -> void:
	if not front:
		for n in targets:
			if is_instance_valid(n) and not list.has(n):
				_unmark(n)
		for n in list:
			if not targets.has(n):
				_mark(n)
	targets = list.duplicate()


func _mark(n: Node) -> void:
	if n is CanvasItem and n.material == null:
		n.material = _mat
		n.set_meta("focus_outline", true)


func _unmark(n: Node) -> void:
	if n.has_meta("focus_outline"):
		n.material = null
		n.remove_meta("focus_outline")


func _process(dt: float) -> void:
	t += dt
	targets = targets.filter(func(n): return is_instance_valid(n) and not n.get("dead"))
	# Chispas doradas que suben desde la base de cada objetivo (en la capa de delante).
	for n in targets if front else []:
		if _rng.randf() < dt * 7.0:
			var r: Rect2 = n.rect()
			_sparks.append({"p": Vector2(_rng.randf_range(r.position.x, r.end.x), r.end.y - _rng.randf_range(0, r.size.y * 0.5)),
				"v": Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-22, -12)), "life": _rng.randf_range(0.6, 1.1), "max": 1.0})
	for s in _sparks:
		s["life"] -= dt
		s["p"] += s["v"] * dt
	_sparks = _sparks.filter(func(s): return s["life"] > 0.0)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.75 + 0.25 * sin(t * 5.0)
	if not front:
		for n in targets:
			var r: Rect2 = n.rect()
			var c := r.get_center()
			var rad := maxf(r.size.x, r.size.y) * 0.75 + 6.0
			draw_texture_rect(UiKit.soft(), Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), false, Color(1.0, 0.82, 0.3, 0.30 * pulse))
		return
	for n in targets:
		var r: Rect2 = n.rect()
		# Brillo en el suelo, bajo el objeto.
		draw_texture_rect(UiKit.soft(), Rect2(Vector2(r.position.x - 6, r.end.y - 3), Vector2(r.size.x + 12, 6)), false, Color(1.0, 0.86, 0.35, 0.55 * pulse))
		# Esquinas doradas que respiran hacia fuera.
		var g := r.grow(2.0 + roundf(sin(t * 5.0) + 1.0))
		var arm := clampf(minf(g.size.x, g.size.y) * 0.3, 3.0, 6.0)
		var col := Color(1.0, 0.86, 0.3, 0.95)
		var shade := Color(0.25, 0.15, 0.0, 0.7)
		for corner in [[g.position, Vector2(1, 1)], [Vector2(g.end.x, g.position.y), Vector2(-1, 1)],
				[Vector2(g.position.x, g.end.y), Vector2(1, -1)], [g.end, Vector2(-1, -1)]]:
			var p: Vector2 = corner[0].round()
			var d: Vector2 = corner[1]
			var ox := p.x if d.x > 0 else p.x - arm
			var oy := p.y if d.y > 0 else p.y - 1
			# Sombra de un píxel y trazo dorado de un píxel de grosor.
			draw_rect(Rect2(ox + 1, oy + 1, arm, 1), shade)
			draw_rect(Rect2(p.x + (1 if d.x > 0 else 0) - (0 if d.x > 0 else 1), (p.y if d.y > 0 else p.y - arm) + 1, 1, arm), shade)
			draw_rect(Rect2(ox, oy, arm, 1), col)
			draw_rect(Rect2(p.x if d.x > 0 else p.x - 1, p.y if d.y > 0 else p.y - arm, 1, arm), col)
	for s in _sparks:
		var a: float = clampf(s["life"] * 1.5, 0.0, 1.0)
		draw_rect(Rect2(s["p"].round(), Vector2(1, 1)), Color(1.0, 0.9, 0.45, a))
