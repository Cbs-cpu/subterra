class_name Fireflies
extends Node2D
## Motas de luz que flotan por todo el distrito, como en el original (no se oscurecen).

var world: Node
var motes: Array = []
var t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var n := int(world.map_w_px * world.map_h_px / 9000.0)
	for i in clampi(n, 30, 400):
		motes.append({"p": Vector2(rng.randf() * world.map_w_px, rng.randf() * world.map_h_px),
			"ph": rng.randf() * TAU, "sp": rng.randf_range(0.3, 1.0)})


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var col: Color = Color(BiomeLook.BG.get("pueblo" if world.is_town else world.biome, BiomeLook.BG["bosque"])[4])
	var cam: Vector2 = world.camera.get_screen_center_position()
	var view := Rect2(cam - Vector2(180, 110), Vector2(360, 220))
	for m in motes:
		var p: Vector2 = m["p"] + Vector2(sin(t * m["sp"] + m["ph"]) * 10.0, cos(t * m["sp"] * 0.7 + m["ph"]) * 8.0)
		if not view.has_point(p):
			continue
		var a := 0.45 + 0.45 * sin(t * 2.0 * m["sp"] + m["ph"])
		draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(col.r, col.g, col.b, a))
