extends Node
## Música chiptune generada por bioma: bajo, arpegio y melodía sobre una escala. Se sintetiza
## en un hilo para no congelar el juego y se guarda en caché.

const RATE := 16000
const MOODS := {
	"titulo": {"root": 57, "scale": [0, 2, 3, 5, 7, 8, 10], "bpm": 92, "seed": 11},
	"pueblo": {"root": 60, "scale": [0, 2, 4, 5, 7, 9, 11], "bpm": 100, "seed": 3},
	"bosque": {"root": 57, "scale": [0, 2, 3, 5, 7, 8, 10], "bpm": 116, "seed": 7},
	"cienaga": {"root": 55, "scale": [0, 1, 3, 5, 7, 8, 10], "bpm": 96, "seed": 21},
	"pradera": {"root": 62, "scale": [0, 2, 4, 7, 9], "bpm": 124, "seed": 5},
	"cavernas": {"root": 52, "scale": [0, 2, 3, 5, 7, 8, 11], "bpm": 88, "seed": 17},
	"tundra": {"root": 64, "scale": [0, 2, 3, 5, 7, 9, 10], "bpm": 104, "seed": 9},
	"mazmorra": {"root": 50, "scale": [0, 1, 4, 5, 7, 8, 10], "bpm": 108, "seed": 31},
	"volcan": {"root": 52, "scale": [0, 1, 3, 5, 6, 8, 10], "bpm": 132, "seed": 41},
	"cantera": {"root": 59, "scale": [0, 2, 4, 6, 7, 9, 11], "bpm": 112, "seed": 13},
	"crater": {"root": 54, "scale": [0, 2, 4, 6, 8, 10], "bpm": 100, "seed": 23},
	"nido": {"root": 48, "scale": [0, 1, 3, 4, 6, 7, 9], "bpm": 140, "seed": 51},
	"fin": {"root": 60, "scale": [0, 2, 4, 5, 7, 9, 11], "bpm": 80, "seed": 2},
}

var player: AudioStreamPlayer
var _cache := {}
var _current := ""
var _thread: Thread
var _pending := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	player.volume_db = -6.0
	add_child(player)


func play_biome(name: String) -> void:
	if name == _current or DisplayServer.get_name() == "headless":
		return
	_current = name
	if _cache.has(name):
		_start(name)
		return
	if _thread and _thread.is_alive():
		_pending = name
		return
	_thread = Thread.new()
	_thread.start(_build_threaded.bind(name))


func _build_threaded(name: String) -> void:
	var s := build(name)
	call_deferred("_built", name, s)


func _built(name: String, s: AudioStreamWAV) -> void:
	_cache[name] = s
	if _thread:
		_thread.wait_to_finish()
	if name == _current:
		_start(name)
	if _pending != "":
		var p := _pending
		_pending = ""
		_current = ""
		play_biome(p)


func _start(name: String) -> void:
	player.stream = _cache[name]
	player.play()


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func build(name: String) -> AudioStreamWAV:
	var m: Dictionary = MOODS.get(name, MOODS["bosque"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(m["seed"])
	var scale: Array = m["scale"]
	var root: int = m["root"]
	var step := 60.0 / float(m["bpm"]) / 4.0     # semicorchea
	var steps := 128
	var n := int(steps * step * RATE)
	var chords := [0, 5, 3, 4] if scale.size() >= 6 else [0, 3, 1, 2]
	# Melodía: paseo aleatorio por la escala, repetida con variación.
	var mel := []
	var deg := 0
	for i in 32:
		if rng.randf() < 0.7:
			deg = clampi(deg + [-2, -1, 1, 2][rng.randi() % 4], -2, scale.size() + 3)
		mel.append(deg if rng.randf() > 0.2 else -99)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / RATE
		var si := int(tt / step)
		var st := fmod(tt, step)
		var bar := (si / 32) % 4
		var chord_deg: int = chords[bar]
		# Bajo.
		var bass_note := root - 24 + _deg(scale, chord_deg)
		var b := (1.0 if fmod(tt * _freq(bass_note), 1.0) < 0.5 else -1.0) * 0.12
		if si % 4 >= 2:
			b *= 0.6
		# Arpegio.
		var arp_deg: int = chord_deg + [0, 2, 4, 2][si % 4]
		var ap := root - 12 + _deg(scale, arp_deg)
		var a := (4.0 * absf(fmod(tt * _freq(ap), 1.0) - 0.5) - 1.0) * 0.07 * maxf(0.0, 1.0 - st / step * 0.8)
		# Melodía (cada 2 pasos).
		var md: int = mel[(si / 2) % 32]
		var mv := 0.0
		if md != -99 and si % 64 >= 16:
			var mnote := root + _deg(scale, md)
			var ph := fmod(tt * _freq(mnote), 1.0)
			mv = (1.0 if ph < 0.25 else -1.0) * 0.06 * maxf(0.0, 1.0 - fmod(tt, step * 2.0) / (step * 2.0) * 0.7)
		# Percusión suave.
		var hat := 0.0
		if si % 2 == 0 and st < 0.02:
			hat = (randf() * 2.0 - 1.0) * 0.05 * (1.0 - st / 0.02)
		var kick := 0.0
		if si % 8 == 0 and st < 0.08:
			kick = sin(TAU * (80.0 - st * 500.0) * st) * 0.25 * (1.0 - st / 0.08)
		var s := clampf(b + a + mv + hat + kick, -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 26000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


static func _deg(scale: Array, d: int) -> int:
	var n := scale.size()
	var octave := floori(float(d) / n)
	var idx := d - octave * n
	return int(scale[idx]) + octave * 12
