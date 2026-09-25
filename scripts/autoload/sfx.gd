extends Node
## Efectos de sonido sintetizados (sin archivos de audio).

const RATE := 22050
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		_players.append(p)
	var S := {
		"salto": [0.09, func(t): return _sq(t, lerpf(300, 600, t / 0.09)) * 0.2],
		"aterrizar": [0.06, func(t): return _noise() * 0.3 * (1.0 - t / 0.06)],
		"dash": [0.14, func(t): return _noise() * 0.3 * sin(t * 90.0) * (1.0 - t / 0.14)],
		"golpe_aire": [0.08, func(t): return _noise() * 0.18 * (1.0 - t / 0.08)],
		"impacto": [0.09, func(t): return (_noise() * 0.5 + _sq(t, 120) * 0.3) * (1.0 - t / 0.09)],
		"arco": [0.12, func(t): return _tri(t, lerpf(900, 200, t / 0.12)) * 0.3],
		"magia": [0.3, func(t): return _sq(t, 600 + sin(t * 60.0) * 200.0) * 0.15],
		"comer": [0.2, func(t): return _noise() * 0.25 * (1.0 if fmod(t, 0.07) < 0.035 else 0.0)],
		"beber": [0.25, func(t): return _tri(t, 300 + sin(t * 40.0) * 120.0) * 0.3],
		"tambor": [0.3, func(t): return sin(TAU * 80.0 * t) * 0.6 * (1.0 - t / 0.3)],
		"habilidad": [0.35, func(t): return _sq(t, [440.0, 660.0, 880.0][mini(2, int(t / 0.1))]) * 0.18],
		"dolor": [0.22, func(t): return _sq(t, lerpf(500, 120, t / 0.22)) * 0.3],
		"caer": [0.6, func(t): return _sq(t, lerpf(400, 60, t / 0.6)) * 0.3],
		"moneda": [0.12, func(t): return _sq(t, 988.0 if t < 0.05 else 1318.0) * 0.14],
		"xp": [0.06, func(t): return _tri(t, 1500.0 + t * 8000.0) * 0.15],
		"recoger": [0.1, func(t): return _sq(t, 660.0 if t < 0.05 else 990.0) * 0.14],
		"nivel": [0.6, func(t): return _sq(t, [523.0, 659.0, 784.0, 1046.0][mini(3, int(t / 0.15))]) * 0.18],
		"talar": [0.12, func(t): return (_noise() * 0.4 + sin(TAU * 140.0 * t) * 0.4) * (1.0 - t / 0.12)],
		"minar": [0.1, func(t): return (_noise() * 0.3 + _sq(t, 900) * 0.2) * (1.0 - t / 0.1)],
		"tink": [0.08, func(t): return _tri(t, 1800) * 0.3 * (1.0 - t / 0.08)],
		"hierba": [0.08, func(t): return _noise() * 0.2 * (1.0 - t / 0.08)],
		"cofre": [0.4, func(t): return _sq(t, [392.0, 523.0, 659.0, 784.0][mini(3, int(t / 0.1))]) * 0.16],
		"mimico": [0.3, func(t): return _sq(t, 110 + _noise() * 40.0) * 0.4],
		"embestida": [0.25, func(t): return _noise() * 0.3 * (1.0 - t / 0.25)],
		"golpe_suelo": [0.3, func(t): return (sin(TAU * lerpf(90, 40, t / 0.3) * t) * 0.7 + _noise() * 0.3) * (1.0 - t / 0.3)],
		"jefe_aviso": [0.5, func(t): return _sq(t, 110.0 + sin(t * 30.0) * 20.0) * 0.25],
		"jefe_muere": [1.2, func(t): return (_noise() * 0.5 + _sq(t, lerpf(200, 40, t / 1.2)) * 0.3) * (1.0 - t / 1.2)],
		"muerte_enemigo": [0.18, func(t): return _sq(t, lerpf(300, 80, t / 0.18)) * 0.2],
		"alarma": [0.8, func(t): return _sq(t, 880.0 if fmod(t, 0.2) < 0.1 else 660.0) * 0.18],
		"guardianes": [1.0, func(t): return (_sq(t, 55.0) * 0.4 + _noise() * 0.2) * (1.0 - t)],
		"puerta": [0.5, func(t): return _tri(t, 200 + t * 600.0) * 0.3 * (1.0 - t / 0.5)],
		"abrir": [0.06, func(t): return _sq(t, 700) * 0.1],
		"comprar": [0.2, func(t): return _sq(t, 1046.0 if t < 0.07 else 1568.0) * 0.14],
		"craftear": [0.25, func(t): return (_noise() * 0.2 + _sq(t, 520.0 if t < 0.1 else 780.0) * 0.14)],
		"equipar": [0.12, func(t): return _noise() * 0.2 + _tri(t, 400) * 0.1],
		"yunque": [0.35, func(t): return _tri(t, 1200) * 0.3 * (1.0 - t / 0.35)],
		"altar_bien": [0.8, func(t): return _tri(t, [523.0, 659.0, 784.0, 1046.0, 1318.0][mini(4, int(t / 0.15))]) * 0.3],
		"altar_mal": [0.6, func(t): return _sq(t, lerpf(300, 90, t / 0.6)) * 0.25],
		"hablar": [0.12, func(t): return _sq(t, 300 + sin(t * 100.0) * 100.0) * 0.1],
		"crujido": [0.2, func(t): return _noise() * 0.25],
		"menu": [0.04, func(t): return _sq(t, 1000) * 0.1],
		"victoria": [1.4, func(t): return _sq(t, [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0][mini(6, int(t / 0.2))]) * 0.2],
	}
	for k in S:
		_streams[k] = _gen(S[k][0], S[k][1])


func _sq(t: float, f: float) -> float:
	return 1.0 if fmod(t * f, 1.0) < 0.5 else -1.0


func _tri(t: float, f: float) -> float:
	var p := fmod(t * f, 1.0)
	return 4.0 * absf(p - 0.5) - 1.0


func _noise() -> float:
	return randf() * 2.0 - 1.0


func _gen(dur: float, fn: Callable) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var env := minf(t / 0.004, 1.0) * minf((dur - t) / 0.02, 1.0)
		var s: float = clampf(float(fn.call(t)) * env, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w


func play(name: String, pitch_var: float = 0.08, db: float = 0.0) -> void:
	if not _streams.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, 0)) < 30:
		return
	_last[name] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = db
	p.play()
