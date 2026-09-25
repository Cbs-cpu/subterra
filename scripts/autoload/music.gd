extends Node
## Música chiptune generada por código. Tempo, tonalidad/modo, brillo y estructura están
## calibrados midiendo la banda sonora original (tempo por autocorrelación de onsets,
## tonalidad por perfil de croma); las melodías son nuevas.
## Voces: lead de pulso 25 % con vibrato y eco, arpegio de pulso 12,5 %, bajo triangular y
## batería (bombo, caja, charles). Estructura: intro (bajo+arpegio) → A → B → A'.

const RATE := 16000

## root: nota MIDI de la tónica. mode: intervalos. prog: grados de la progresión (4 compases).
const MOODS := {
	"titulo": {"root": 54, "mode": [0, 2, 4, 5, 7, 9, 10], "bpm": 91, "seed": 11, "prog": [0, 4, 0, 6], "drums": 1},
	"pueblo": {"root": 54, "mode": [0, 2, 4, 5, 7, 9, 11], "bpm": 104, "seed": 3, "prog": [0, 3, 4, 0], "drums": 1},
	"bosque": {"root": 49, "mode": [0, 2, 3, 5, 7, 9, 10], "bpm": 141, "seed": 7, "prog": [0, 4, 0, 3], "drums": 2},
	"cienaga": {"root": 47, "mode": [0, 1, 3, 5, 7, 8, 10], "bpm": 112, "seed": 21, "prog": [0, 5, 6, 4], "drums": 1},
	"pradera": {"root": 54, "mode": [0, 2, 4, 5, 7, 9, 10], "bpm": 120, "seed": 5, "prog": [0, 4, 3, 0], "drums": 2},
	"cavernas": {"root": 45, "mode": [0, 2, 3, 5, 7, 8, 10], "bpm": 96, "seed": 17, "prog": [0, 5, 3, 4], "drums": 1},
	"tundra": {"root": 52, "mode": [0, 2, 3, 5, 7, 9, 10], "bpm": 108, "seed": 9, "prog": [0, 3, 6, 4], "drums": 1},
	"mazmorra": {"root": 45, "mode": [0, 1, 4, 5, 7, 8, 10], "bpm": 126, "seed": 31, "prog": [0, 1, 0, 6], "drums": 2},
	"volcan": {"root": 47, "mode": [0, 1, 3, 5, 6, 8, 10], "bpm": 150, "seed": 41, "prog": [0, 5, 1, 6], "drums": 2},
	"cantera": {"root": 51, "mode": [0, 2, 4, 6, 7, 9, 11], "bpm": 116, "seed": 13, "prog": [0, 1, 4, 3], "drums": 1},
	"crater": {"root": 50, "mode": [0, 2, 4, 6, 7, 9, 10], "bpm": 132, "seed": 23, "prog": [0, 6, 1, 4], "drums": 2},
	"nido": {"root": 44, "mode": [0, 1, 3, 4, 6, 7, 9], "bpm": 156, "seed": 51, "prog": [0, 1, 6, 5], "drums": 2},
	"fin": {"root": 54, "mode": [0, 2, 4, 5, 7, 9, 11], "bpm": 84, "seed": 2, "prog": [0, 4, 5, 3], "drums": 0},
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
	player.volume_db = -5.0
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


static func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func _deg(mode: Array, d: int) -> int:
	var n := mode.size()
	var octave := floori(float(d) / n)
	return int(mode[d - octave * n]) + octave * 12


## Motivo melódico de 2 compases (32 semicorcheas): notas (grado o -99 silencio) y duraciones.
static func _motif(rng: RandomNumberGenerator) -> Array:
	var out := []
	var deg := rng.randi_range(2, 4)
	var step := 0
	var rhythms := [[4, 2, 2, 4, 4], [2, 2, 2, 2, 4, 4], [6, 2, 4, 4], [3, 3, 2, 4, 4], [4, 4, 2, 2, 4]]
	while step < 32:
		var r: Array = rhythms[rng.randi() % rhythms.size()]
		for d in r:
			if step >= 32:
				break
			if rng.randf() < 0.12 and step > 0:
				out.append([-99, d])
			else:
				deg = clampi(deg + [-2, -1, -1, 1, 1, 2, 0, 3][rng.randi() % 8], -1, 9)
				out.append([deg, d])
			step += d
	return out


static func build(name: String) -> AudioStreamWAV:
	var m: Dictionary = MOODS.get(name, MOODS["bosque"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(m["seed"])
	var mode: Array = m["mode"]
	var root: int = m["root"]
	var prog: Array = m["prog"]
	var drums: int = m["drums"]
	var step_len := 60.0 / float(m["bpm"]) / 4.0
	# Estructura en compases: intro 4, A 8, B 8, A' 8.
	var sections := [["intro", 4], ["A", 8], ["B", 8], ["A2", 8]]
	var bars := 0
	for sct in sections:
		bars += int(sct[1])
	var steps := bars * 16
	var n := int(steps * step_len * RATE)
	var motif_a := _motif(rng)
	var motif_b := _motif(rng)
	# Tabla de notas por semicorchea: [lead_midi o -1, inicio_de_nota(bool)] y sección.
	var lead := PackedFloat32Array()
	lead.resize(steps)
	lead.fill(-1.0)
	var lead_on := PackedByteArray()
	lead_on.resize(steps)
	var sec_of := PackedByteArray()
	sec_of.resize(steps)
	var bar0 := 0
	for si in sections.size():
		var sname: String = sections[si][0]
		var nb: int = sections[si][1]
		for b in nb:
			for k in 16:
				sec_of[(bar0 + b) * 16 + k] = si
		if sname != "intro":
			var mot: Array = motif_b if sname == "B" else motif_a
			var shift := 2 if sname == "B" else 0
			for rep in nb / 2:
				var st := (bar0 + rep * 2) * 16
				var var_up := 1 if (rep % 2 == 1 and sname == "A2") else 0
				for note in mot:
					var d: int = note[1]
					if note[0] != -99 and st < steps:
						var midi := root + 12 + _deg(mode, int(note[0]) + shift + var_up)
						for k in d:
							if st + k < steps:
								lead[st + k] = midi
						lead_on[st] = 1
					st += d
		bar0 += nb
	var data := PackedByteArray()
	data.resize(n * 2)
	var echo_len := int(step_len * 3.0 * RATE)
	var echo := PackedFloat32Array()
	echo.resize(echo_len)
	var ei := 0
	var lead_phase := 0.0
	# Filtros paso bajo de un polo por voz (evitan el aliasing de las ondas cuadradas).
	var f_lead := 0.0
	var f_arp := 0.0
	var f_bass := 0.0
	var f_mix := 0.0
	var a_lead := 1.0 - exp(-TAU * 3400.0 / RATE)
	var a_arp := 1.0 - exp(-TAU * 1800.0 / RATE)
	var a_bass := 1.0 - exp(-TAU * 900.0 / RATE)
	var a_mix := 1.0 - exp(-TAU * 5000.0 / RATE)
	var note_t := 0.0
	var prev_si := -1
	for i in n:
		var tt := float(i) / RATE
		var si := mini(int(tt / step_len), steps - 1)
		var st := fmod(tt, step_len)
		var bar := si / 16
		var chord: int = prog[bar % prog.size()]
		var section: int = sec_of[si]
		var s := 0.0
		# Bajo triangular en corcheas, con salto de octava.
		var bass_note := root - 12 + _deg(mode, chord) + (12 if (si / 2) % 2 == 1 else 0)
		var bp := fmod(tt * _freq(bass_note), 1.0)
		var bass_env := maxf(0.0, 1.0 - fmod(tt, step_len * 2.0) / (step_len * 2.0) * 0.9)
		f_bass += a_bass * ((4.0 * absf(bp - 0.5) - 1.0) - f_bass)
		s += f_bass * 0.3 * bass_env * (0.0 if section == 0 else 1.0)
		# Arpegio de pulso fino (12,5 %).
		var arp_deg: int = chord + [0, 2, 4, 7, 4, 2][si % 6]
		var ap := fmod(tt * _freq(root + 12 + _deg(mode, arp_deg)), 1.0)
		var arp_env := maxf(0.0, 1.0 - st / (step_len * 0.6))
		f_arp += a_arp * ((1.0 if ap < 0.125 else -0.14) - f_arp)
		s += f_arp * 0.12 * arp_env * (0.5 if section == 0 else (0.8 if section == 2 else 0.65))
		# Lead de pulso 25 % con vibrato retrasado y ataque suave.
		var lm: float = lead[si]
		var lv := 0.0
		if si != prev_si:
			if lead_on[si] == 1:
				note_t = 0.0
			prev_si = si
		note_t += 1.0 / RATE
		if lm > 0.0:
			var vib := sin(TAU * 5.5 * tt) * 0.12 * clampf((note_t - 0.12) * 4.0, 0.0, 1.0)
			lead_phase = fmod(lead_phase + _freq(lm + vib) / RATE, 1.0)
			var env := minf(note_t / 0.008, 1.0) * maxf(0.25, 1.0 - note_t * 2.2)
			f_lead += a_lead * ((1.0 if lead_phase < 0.25 else -0.33) - f_lead)
			lv = f_lead * 0.2 * env * (1.15 if section == 2 else 1.0)
		else:
			f_lead *= 0.99
		# Eco del lead.
		var e := echo[ei]
		echo[ei] = lv + e * 0.35
		ei = (ei + 1) % echo_len
		s += lv + e * 0.35
		# Batería.
		if drums > 0 and section > 0:
			var in_bar := si % 16
			if (in_bar == 0 or in_bar == 8 or (drums == 2 and in_bar == 10)) and st < 0.09:
				s += sin(TAU * (130.0 - st * 900.0) * st) * 0.4 * (1.0 - st / 0.09)
			if (in_bar == 4 or in_bar == 12) and st < 0.08:
				s += (randf() * 2.0 - 1.0) * 0.1 * pow(1.0 - st / 0.08, 2.0) + sin(TAU * 190.0 * st) * 0.12 * (1.0 - st / 0.08)
			if (si % 2 == 0 or drums == 2) and st < 0.012:
				s += (randf() * 2.0 - 1.0) * 0.025 * (1.0 - st / 0.012)
		f_mix += a_mix * (s - f_mix)
		data.encode_s16(i * 2, int(clampf(f_mix * 1.3, -1.0, 1.0) * 26000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w
