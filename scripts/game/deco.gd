class_name Deco
extends Node2D
## Decoración de fondo que se mece un poco (plantas y enredaderas).

var kind := "planta"
var h := 32
var v := 0
var biome := "bosque"
var t := 0.0


func setup(w: Node, d: Dictionary) -> void:
	kind = d["kind"]
	position = d["pos"]
	h = d.get("h", 32)
	v = d.get("v", 0)
	biome = w.biome
	t = v * 1.3
	modulate = Color(0.95, 0.95, 1.0)


func _process(dt: float) -> void:
	t += dt
	if int(t * 4.0) != int((t - dt) * 4.0):
		queue_redraw()


func _draw() -> void:
	var sway := roundf(sin(t * 1.2) * 1.0)
	if kind == "planta":
		draw_set_transform(Vector2(sway * 0.0, 0), 0.0, Vector2.ONE)
		draw_texture(Art.plant(biome, h, v), Vector2(-8 + sway, -h))
	else:
		draw_texture(Art.vine(biome, h, v), Vector2(-4 + sway, 0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
