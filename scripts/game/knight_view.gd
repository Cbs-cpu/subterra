class_name KnightView
extends Node
## El caballero jugable: modelo 3D (assets/models/caballero/caballero.glb, hecho en Blender a
## partir del concepto; scripts en art_src/caballero/scripts) renderizado en vivo a pixel art.
##
## Dos SubViewports: uno 3D con el modelo, su AnimationPlayer y la física de telas
## (SpringBoneSimulator3D para capa, capucha, pelaje, penacho y faldar) y otro 2D que le pone
## el contorno negro de 1 px. `texture` es el resultado; el héroe lo dibuja con los pies en
## `FEET` y lo voltea según hacia dónde mire.
##
## El cuerpo 3D se desplaza de verdad en su mundo siguiendo la velocidad del héroe (siempre
## "hacia delante", porque el volteo se hace en 2D): así la capa ondea al correr, sube al
## caer y se balancea al frenar sin animarla a mano.

const SCENE := preload("res://assets/models/caballero/caballero.glb")
const TOON := preload("res://shaders/knight_toon.gdshader")
const OUTLINE := preload("res://shaders/pixel_outline.gdshader")

const HEIGHT_M := 1.9
const HEIGHT_PX := 30.0
const PPM := HEIGHT_PX / HEIGHT_M
const SIZE := Vector2i(64, 48)
## Píxel de los pies (centro) dentro de la textura.
const FEET := Vector2i(32, 43)
## Giro del modelo: mira a la derecha de la pantalla con 3/4 hacia la cámara.
const YAW_DEG := 62.0
## Inclinación de la cámara hacia abajo: deja ver hombros y manto de pelaje.
const PITCH_DEG := 12.0
## Cuánto del movimiento 2D notan las telas (1 = la velocidad real a escala); el vertical menos.
const MOTION := Vector2(0.16, 0.08)
## Lado de la textura suavizada con la que se colorea (manchas planas legibles a 30 px).
const FLAT_TEX := 128
const REBASE := 400.0

## Cadenas de física: [hueso raíz, hueso final, rigidez, arrastre, gravedad, radio].
const CHAINS := [
	["Cape0_0", "Cape0_4", 1.6, 0.55, 2.4, 0.05], ["Cape1_0", "Cape1_4", 1.6, 0.55, 2.4, 0.05],
	["Cape2_0", "Cape2_4", 1.6, 0.55, 2.4, 0.05], ["Cape3_0", "Cape3_4", 1.6, 0.55, 2.4, 0.05],
	["Cape4_0", "Cape4_4", 1.6, 0.55, 2.4, 0.05], ["Cape5_0", "Cape5_4", 1.6, 0.55, 2.4, 0.05],
	["Cape6_0", "Cape6_4", 1.6, 0.55, 2.4, 0.05],
	["Hood1", "Hood2", 1.6, 0.4, 0.6, 0.05],
	["Plume1", "Plume3", 1.4, 0.3, 0.4, 0.03],
	["FurBack", "FurBack", 3.0, 0.5, 0.3, 0.06],
	["LeftFurFront", "LeftFurFront", 3.0, 0.5, 0.3, 0.05], ["RightFurFront", "RightFurFront", 3.0, 0.5, 0.3, 0.05],
	["LeftFurShoulder", "LeftFurShoulder", 3.5, 0.5, 0.2, 0.05], ["RightFurShoulder", "RightFurShoulder", 3.5, 0.5, 0.2, 0.05],
	["LeftSkirtF1", "LeftSkirtF2", 2.2, 0.45, 0.6, 0.04], ["RightSkirtF1", "RightSkirtF2", 2.2, 0.45, 0.6, 0.04],
	["LeftSkirtS1", "LeftSkirtS2", 2.2, 0.45, 0.6, 0.04], ["RightSkirtS1", "RightSkirtS2", 2.2, 0.45, 0.6, 0.04],
	["LeftSkirtB1", "LeftSkirtB2", 2.2, 0.45, 0.6, 0.04], ["RightSkirtB1", "RightSkirtB2", 2.2, 0.45, 0.6, 0.04],
	["LoinF1", "LoinF2", 1.6, 0.4, 0.7, 0.04],
]
## Cápsulas contra las que chocan las telas: [hueso, radio, alto].
const COLLIDERS := [
	["Hips", 0.17, 0.5], ["Spine", 0.16, 0.45], ["Chest", 0.17, 0.45], ["UpperChest", 0.17, 0.45],
	["LeftUpperLeg", 0.09, 0.55], ["RightUpperLeg", 0.09, 0.55],
	["LeftLowerLeg", 0.08, 0.5], ["RightLowerLeg", 0.08, 0.5], ["Head", 0.14, 0.32],
]

static var _flat_cache: Texture2D

var texture: Texture2D
var _vp3: SubViewport
var _vp2: SubViewport
var _body: Node3D
var _cam: Camera3D
var _skel: Skeleton3D
var _ap: AnimationPlayer
var _springs: SpringBoneSimulator3D
var _hand := -1
var _head := -1
var _anim := ""


func _ready() -> void:
	_vp3 = SubViewport.new()
	_vp3.size = SIZE
	_vp3.transparent_bg = true
	_vp3.own_world_3d = true
	_vp3.msaa_3d = Viewport.MSAA_DISABLED
	_vp3.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_vp3.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp3)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6a6880")
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	_vp3.add_child(we)
	# Luz principal cálida desde delante-arriba y contraluz fría por detrás.
	var key := DirectionalLight3D.new()
	key.light_color = Color("#fff0dc")
	key.light_energy = 1.6
	key.rotation_degrees = Vector3(-38, 30, 0)
	_vp3.add_child(key)
	var back := DirectionalLight3D.new()
	back.light_color = Color("#9fb6ff")
	back.light_energy = 1.1
	back.rotation_degrees = Vector3(-15, 160, 0)
	_vp3.add_child(back)

	_body = Node3D.new()
	_vp3.add_child(_body)
	var model: Node3D = SCENE.instantiate()
	model.rotation_degrees.y = YAW_DEG
	_body.add_child(model)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.size = SIZE.y / PPM
	_cam.rotation_degrees.x = -PITCH_DEG
	# Centro de la imagen: los pies quedan FEET.y - SIZE.y/2 px por debajo, medidos en el eje
	# vertical de la propia cámara (inclinada).
	var up := _cam.transform.basis.y
	var center := up * float(FEET.y - SIZE.y / 2) / PPM + Vector3(float(SIZE.x / 2 - FEET.x) / PPM, 0, 0)
	_cam.position = center + _cam.transform.basis.z * 10.0
	_cam.near = 0.1
	_cam.far = 30.0
	_body.add_child(_cam)
	_cam.current = true

	_skel = model.find_child("Skeleton3D", true, false)
	_ap = model.find_child("AnimationPlayer", true, false)
	_ap.speed_scale = 0.0
	var mi: MeshInstance3D = _skel.find_child("Caballero", true, false)
	var src := mi.get_active_material(0) as BaseMaterial3D
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	if src:
		mat.set_shader_parameter("albedo_tex", _flat(src.albedo_texture))
		mat.set_shader_parameter("detail_tex", src.albedo_texture)
	mi.material_override = mat
	_hand = _skel.find_bone("RightMiddleProximal")
	_head = _skel.find_bone("Head")
	_build_springs()

	_vp2 = SubViewport.new()
	_vp2.size = SIZE
	_vp2.transparent_bg = true
	_vp2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp2)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = _vp3.get_texture()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var om := ShaderMaterial.new()
	om.shader = OUTLINE
	spr.material = om
	_vp2.add_child(spr)
	texture = _vp2.get_texture()
	set_pose("idle", 0.0)


## Textura de color reducida a FLAT_TEX px (compartida entre todos los caballeros).
static func _flat(tex: Texture2D) -> Texture2D:
	if _flat_cache == null and tex:
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(FLAT_TEX, FLAT_TEX, Image.INTERPOLATE_LANCZOS)
		_flat_cache = ImageTexture.create_from_image(img)
	return _flat_cache


func _build_springs() -> void:
	_springs = SpringBoneSimulator3D.new()
	_skel.add_child(_springs)
	for c in COLLIDERS:
		var cap := SpringBoneCollisionCapsule3D.new()
		cap.bone_name = c[0]
		cap.radius = c[1]
		cap.height = c[2]
		# La cápsula va a lo largo del hueso (eje Y local), centrada en su mitad.
		cap.position_offset = Vector3(0, c[2] * 0.35, 0)
		_springs.add_child(cap)
	_springs.setting_count = CHAINS.size()
	for i in CHAINS.size():
		var ch: Array = CHAINS[i]
		_springs.set_root_bone_name(i, ch[0])
		_springs.set_end_bone_name(i, ch[1])
		_springs.set_extend_end_bone(i, true)
		_springs.set_end_bone_length(i, 0.12)
		_springs.set_stiffness(i, ch[2])
		_springs.set_drag(i, ch[3])
		_springs.set_gravity(i, ch[4])
		_springs.set_radius(i, ch[5])
		_springs.set_enable_all_child_collisions(i, true)


## Pone la animación `anim` en el instante `t` (s). Las telas siguen simulándose encima.
func set_pose(anim: String, t: float) -> void:
	if _ap == null:
		return
	if not _ap.has_animation(anim):
		anim = "idle"
	if anim != _anim:
		_ap.play(anim)
		_anim = anim
	_ap.seek(clampf(t, 0.0, _ap.current_animation_length), true)


## Mueve el cuerpo 3D con la velocidad del héroe (px/s) para que las telas reaccionen.
## `facing` hace que el avance sea siempre "hacia delante", como en el dibujo volteado.
func move(vel: Vector2, facing: int, dt: float) -> void:
	if _body == null:
		return
	_body.position += Vector3(vel.x * facing * MOTION.x, -vel.y * MOTION.y, 0.0) / PPM * dt
	if absf(_body.position.x) > REBASE or absf(_body.position.y) > REBASE:
		_body.position = Vector3.ZERO
		_springs.reset()


## Viento o empujón sobre las telas (m/s², en el espacio del modelo mirando a la derecha).
func push(force: Vector3) -> void:
	if _springs:
		_springs.external_force = force


func _bone_px(bone: int, local := Vector3.ZERO) -> Vector2:
	if bone < 0 or _cam == null:
		return Vector2.ZERO
	var p := _skel.global_transform * (_skel.get_bone_global_pose(bone) * local)
	return _cam.unproject_position(p) - Vector2(FEET)


## Mano derecha (empuña el objeto) en píxeles respecto a los pies, mirando a la derecha.
func hand_pos() -> Vector2:
	return _bone_px(_hand)


## Coronilla del yelmo en píxeles respecto a los pies, mirando a la derecha.
func head_top() -> Vector2:
	return _bone_px(_head, Vector3(0, 0.27, 0))
