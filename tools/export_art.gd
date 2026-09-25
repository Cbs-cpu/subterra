extends SceneTree
## Exporta todo el arte a res://art_export (uso: godot --headless -s res://tools/export_art.gd)

func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var art = root.get_node("Art")
	art.export_all(ProjectSettings.globalize_path("res://art_export"))
	quit()
