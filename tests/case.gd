class_name TestCase
extends RefCounted
## Base de los tests: aserciones sencillas.

var tree: SceneTree
var _failed := false
var _msgs: Array = []


func check(cond: bool, msg: String = "condición falsa") -> void:
	if not cond:
		_failed = true
		_msgs.append(msg)


func check_eq(a, b, msg: String = "") -> void:
	if a != b:
		_failed = true
		_msgs.append("%s esperado %s, obtenido %s" % [msg, str(b), str(a)])


func check_near(a: float, b: float, tol: float, msg: String = "") -> void:
	if absf(a - b) > tol:
		_failed = true
		_msgs.append("%s esperado %.4f ±%.4f, obtenido %.4f" % [msg, b, tol, a])
