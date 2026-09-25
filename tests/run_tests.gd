extends SceneTree
## Runner mínimo de tests. Uso:
##   Godot_console.exe --headless --path . -s res://tests/run_tests.gd
## Ejecuta todos los métodos test_* de tests/test_*.gd. Sale con código 1 si falla alguno.

var failures := 0
var passed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dir := DirAccess.open("res://tests")
	var files := []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			failures += 1
			print("  FALLO  %s no compila" % f)
			continue
		var suite = script.new()
		suite.set("tree", self)
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			suite.set("_failed", false)
			suite.set("_msgs", [])
			await suite.call(name)
			if suite.get("_failed"):
				failures += 1
				print("  FALLO  %s::%s" % [f, name])
				for msg in suite.get("_msgs"):
					print("         ", msg)
			else:
				passed += 1
				print("  ok     %s::%s" % [f, name])
		if suite is Node:
			suite.free()
	print("\n%d tests pasados, %d fallidos" % [passed, failures])
	quit(1 if failures > 0 else 0)
