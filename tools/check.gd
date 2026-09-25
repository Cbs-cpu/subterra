extends SceneTree
## Compila todos los scripts y muestra los errores (uso: godot --headless -s res://tools/check.gd)

func _initialize() -> void:
	var files := []
	_scan("res://scripts", files)
	for f in files:
		var s = load(f)
		if s == null or not s.can_instantiate():
			print("FALLA: ", f)
	print("revisados: ", files.size())
	quit()


func _scan(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_scan(dir + "/" + sub, out)
