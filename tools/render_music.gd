extends SceneTree
## Renderiza la música de varios biomas a WAV para analizarla (uso: -s res://tools/render_music.gd -- <dir>).

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var M = load("res://scripts/autoload/music.gd")
	for name in ["titulo", "bosque", "pradera"]:
		var s: AudioStreamWAV = M.build(name)
		s.save_to_wav(out + "/gen_" + name + ".wav")
	quit()
