extends SceneTree
## Genera scenes/pj_rig.tscn: el personaje principal montado por piezas (cabeza, torso,
## manos y pies de assets/sprites/pj_partes) con un AnimationPlayer y sus animaciones
## (idle, run, jump, fall, attack, hurt, dash, down). La escena se puede abrir y retocar en
## el editor de Godot; si se regenera con este script se sobrescribe.
##
## Uso: godot --headless --path . -s res://tools/build_pj_rig.gd
##
## Coordenadas en píxeles del sprite, con el origen en el suelo entre los pies y mirando a
## la derecha. Cada pieza tiene su pivote (offset = -pivote, centered = false):
##   Torso  8x6  pivote en la cadera (abajo al centro), en (0, -2)
##   Cabeza 10x9 pivote en el cuello, en (0, -8)
##   Manos  4x4  pivote en el centro, flotando a los lados
##   Pies   5x4  pivote abajo, en el suelo

const PARTS := "res://assets/sprites/pj_partes/"
const OUT := "res://scenes/pj_rig.tscn"

## Orden de dibujo (de atrás hacia delante).
const ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]
const TEX := {"PieB": "pie", "PieF": "pie", "ManoB": "mano", "Torso": "torso", "Cabeza": "cabeza", "ManoF": "mano"}
const OFFSET := {"pie": Vector2(-2, -4), "mano": Vector2(-2, -2), "torso": Vector2(-4, -6), "cabeza": Vector2(-6, -8)}

## Pose de reposo: posición y giro de cada pieza, y escala del cuerpo entero (Root).
const REST := {
	"Root": {"p": Vector2(0, 0), "r": 0.0, "s": Vector2.ONE},
	"Torso": {"p": Vector2(0, -2), "r": 0.0},
	"Cabeza": {"p": Vector2(0, -8), "r": 0.0},
	"ManoF": {"p": Vector2(6, -4), "r": 0.0},
	"ManoB": {"p": Vector2(-6, -4), "r": 0.0},
	"PieF": {"p": Vector2(2, 0), "r": 0.0},
	"PieB": {"p": Vector2(-2, 0), "r": 0.0},
}

## Animaciones: [duración, bucle, [[tiempo, {pieza: cambios sobre REST}], ...]].
const ANIMS := {
	"idle": [1.2, true, [
		[0.0, {}],
		[0.6, {"Cabeza": {"p": Vector2(0, -7)}, "ManoF": {"p": Vector2(6, -3)}, "ManoB": {"p": Vector2(-6, -3)}}],
		[1.2, {}],
	]],
	"run": [0.48, true, [
		[0.0, {"Root": {"r": 0.08}, "PieF": {"p": Vector2(4, 0)}, "PieB": {"p": Vector2(-3, -1)},
			"ManoF": {"p": Vector2(4, -5)}, "ManoB": {"p": Vector2(-7, -4)}}],
		[0.12, {"Root": {"p": Vector2(0, -1), "r": 0.08}, "PieF": {"p": Vector2(1, 0)}, "PieB": {"p": Vector2(0, -2)},
			"ManoF": {"p": Vector2(5, -4)}, "ManoB": {"p": Vector2(-6, -4)}}],
		[0.24, {"Root": {"r": 0.08}, "PieF": {"p": Vector2(-3, -1)}, "PieB": {"p": Vector2(4, 0)},
			"ManoF": {"p": Vector2(7, -4)}, "ManoB": {"p": Vector2(-4, -5)}}],
		[0.36, {"Root": {"p": Vector2(0, -1), "r": 0.08}, "PieF": {"p": Vector2(0, -2)}, "PieB": {"p": Vector2(1, 0)},
			"ManoF": {"p": Vector2(6, -4)}, "ManoB": {"p": Vector2(-5, -4)}}],
		[0.48, {"Root": {"r": 0.08}, "PieF": {"p": Vector2(4, 0)}, "PieB": {"p": Vector2(-3, -1)},
			"ManoF": {"p": Vector2(4, -5)}, "ManoB": {"p": Vector2(-7, -4)}}],
	]],
	"jump": [0.3, false, [
		[0.0, {"Root": {"s": Vector2(0.88, 1.12)}, "ManoF": {"p": Vector2(6, -9)}, "ManoB": {"p": Vector2(-6, -9)},
			"PieF": {"p": Vector2(2, -1)}, "PieB": {"p": Vector2(-2, -2)}}],
		[0.3, {"ManoF": {"p": Vector2(6, -8)}, "ManoB": {"p": Vector2(-6, -8)}, "PieF": {"p": Vector2(2, -1)}, "PieB": {"p": Vector2(-2, -2)}}],
	]],
	"fall": [0.3, false, [
		[0.0, {"ManoF": {"p": Vector2(7, -8)}, "ManoB": {"p": Vector2(-7, -8)}, "PieF": {"p": Vector2(3, 0)}, "PieB": {"p": Vector2(-2, -1)}}],
		[0.3, {"ManoF": {"p": Vector2(7, -10)}, "ManoB": {"p": Vector2(-7, -10)}, "PieF": {"p": Vector2(3, 0)}, "PieB": {"p": Vector2(-3, -1)},
			"Root": {"s": Vector2(1.06, 0.95)}}],
	]],
	"attack": [0.3, false, [
		[0.0, {"Root": {"r": -0.1}, "Cabeza": {"r": -0.1}, "ManoF": {"p": Vector2(-3, -15)}}],
		[0.08, {"Root": {"r": -0.12}, "Cabeza": {"r": -0.12}, "ManoF": {"p": Vector2(2, -17)}}],
		[0.15, {"Root": {"r": 0.15}, "Cabeza": {"p": Vector2(1, -8), "r": 0.1}, "ManoF": {"p": Vector2(9, -9)}, "PieF": {"p": Vector2(3, 0)}}],
		[0.22, {"Root": {"r": 0.12}, "Cabeza": {"p": Vector2(1, -8), "r": 0.08}, "ManoF": {"p": Vector2(8, -4)}, "PieF": {"p": Vector2(3, 0)}}],
		[0.3, {}],
	]],
	"hurt": [0.25, false, [
		[0.0, {"Root": {"r": -0.3, "s": Vector2(1.1, 0.9)}, "Cabeza": {"r": -0.2}, "ManoF": {"p": Vector2(7, -8)}, "ManoB": {"p": Vector2(-8, -7)}}],
		[0.25, {"Root": {"r": -0.12}, "Cabeza": {"r": -0.08}, "ManoF": {"p": Vector2(7, -6)}, "ManoB": {"p": Vector2(-7, -6)}}],
	]],
	"dash": [0.25, true, [
		[0.0, {"Root": {"r": 0.25, "s": Vector2(1.1, 0.9)}, "Cabeza": {"p": Vector2(1, -8)}, "ManoF": {"p": Vector2(-2, -6)},
			"ManoB": {"p": Vector2(-8, -5)}, "PieF": {"p": Vector2(-1, -1)}, "PieB": {"p": Vector2(-4, 0)}}],
		[0.125, {"Root": {"r": 0.28, "s": Vector2(1.12, 0.88)}, "Cabeza": {"p": Vector2(1, -8)}, "ManoF": {"p": Vector2(-3, -6)},
			"ManoB": {"p": Vector2(-9, -5)}, "PieF": {"p": Vector2(-2, -1)}, "PieB": {"p": Vector2(-5, 0)}}],
		[0.25, {"Root": {"r": 0.25, "s": Vector2(1.1, 0.9)}, "Cabeza": {"p": Vector2(1, -8)}, "ManoF": {"p": Vector2(-2, -6)},
			"ManoB": {"p": Vector2(-8, -5)}, "PieF": {"p": Vector2(-1, -1)}, "PieB": {"p": Vector2(-4, 0)}}],
	]],
	"down": [0.1, false, [[0.0, {}], [0.1, {}]]],
}


func _init() -> void:
	var rig := Node2D.new()
	rig.name = "PjRig"
	var root := Node2D.new()
	root.name = "Root"
	rig.add_child(root)
	root.owner = rig
	for n in ORDER:
		var s := Sprite2D.new()
		s.name = n
		var kind: String = TEX[n]
		s.texture = load(PARTS + kind + ".png")
		s.centered = false
		s.offset = OFFSET[kind]
		s.position = REST[n]["p"]
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(s)
		s.owner = rig
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	rig.add_child(ap)
	ap.owner = rig
	var lib := AnimationLibrary.new()
	for anim_name in ANIMS:
		lib.add_animation(anim_name, _build(ANIMS[anim_name]))
	ap.add_animation_library("", lib)
	ap.autoplay = "idle"
	var ps := PackedScene.new()
	var err := ps.pack(rig)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes"))
		err = ResourceSaver.save(ps, OUT)
	print("pj_rig: ", error_string(err), " -> ", OUT, " (", ANIMS.size(), " animaciones)")
	rig.free()
	quit()


func _build(def: Array) -> Animation:
	var a := Animation.new()
	a.length = def[0]
	a.loop_mode = Animation.LOOP_LINEAR if def[1] else Animation.LOOP_NONE
	for node in REST:
		var path: String = "Root" if node == "Root" else "Root/" + node
		var props: Array = ["p", "r", "s"] if node == "Root" else ["p", "r"]
		for prop in props:
			var ti := a.add_track(Animation.TYPE_VALUE)
			a.track_set_path(ti, path + ":" + {"p": "position", "r": "rotation", "s": "scale"}[prop])
			a.value_track_set_update_mode(ti, Animation.UPDATE_CONTINUOUS)
			for key in def[2]:
				var over: Dictionary = key[1].get(node, {})
				a.track_insert_key(ti, key[0], over.get(prop, REST[node][prop]))
	return a
