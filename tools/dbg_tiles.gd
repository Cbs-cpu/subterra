extends SceneTree
func _initialize() -> void:
	var d := DistrictGen.generate(1, "nido", 21, [])
	for y in range(8, 18):
		var row := ""
		for x in range(28, 72):
			row += str(DistrictGen.tile_at(d, x, y))
		print(y, " ", row)
	print(d["spawn"])
	quit()
