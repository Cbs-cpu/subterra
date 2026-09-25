class_name BiomeLook
extends RefCounted
## Paletas de tiles y fondos por bioma.

const TILES := {
	"bosque": ["#4a9a3a", "#2e6a2a", "#5e3e26", "#4a3020", "#2a1c16", "#9c6a3c", "#6e4a30"],
	"cienaga": ["#6a4a9a", "#46307a", "#3a3a2a", "#2e2e22", "#1a1a16", "#6b5a3a", "#5a5a3a"],
	"pradera": ["#d05a6a", "#9a3a4a", "#7a4a3a", "#5e3a2e", "#2e1c18", "#b07a4a", "#8a5a4a"],
	"cavernas": ["#6a6a7a", "#4a4a5a", "#3a3a46", "#2e2e38", "#1a1a22", "#6a6a7a", "#56566a"],
	"tundra": ["#f0f6ff", "#b8d0e8", "#5a6a7a", "#46546a", "#262e3a", "#8aa0b8", "#7a8aa0"],
	"mazmorra": ["#6a6a5a", "#4a4a40", "#4a4a52", "#3a3a42", "#1e1e26", "#7a6a5a", "#5a5a64"],
	"volcan": ["#f0802a", "#b04a1a", "#3a2220", "#2e1a18", "#140a0a", "#7a4a3a", "#5a2a20"],
	"cantera": ["#6ae0d0", "#3ab0a0", "#3a4a5a", "#2e3a4a", "#161e28", "#6a8a9a", "#8af0e8"],
	"crater": ["#b08ae0", "#7a5aaa", "#2e2440", "#241c34", "#100c1a", "#6a5a8a", "#e0a0ff"],
	"nido": ["#6a2a4a", "#4a1a34", "#2a1822", "#22121a", "#0e080c", "#5a3a4a", "#e05a9a"],
	"pueblo": ["#7ab04a", "#4a8a3a", "#6e4a30", "#5a3a26", "#2a1c16", "#b08a5a", "#8a6a4a"],
}
const BG := {
	"bosque": ["#0e1a14", "#1e3a26", "#1a2e22", "#122018", "#6ae07a"],
	"cienaga": ["#120e1e", "#241a36", "#1e1630", "#150f22", "#b07ae0"],
	"pradera": ["#1e0e14", "#3a1a26", "#301620", "#220e16", "#ff9aaa"],
	"cavernas": ["#0c0c12", "#1c1c26", "#18181f", "#101016", "#8a8aa0"],
	"tundra": ["#0e1624", "#2a3e5a", "#22324a", "#182436", "#e0f4ff"],
	"mazmorra": ["#0c0a0a", "#1e1a18", "#1a1614", "#12100e", "#e0b04a"],
	"volcan": ["#1a0806", "#3a140a", "#301008", "#200a06", "#ff8a3a"],
	"cantera": ["#081414", "#123030", "#0e2626", "#0a1a1a", "#8af0e8"],
	"crater": ["#0a0614", "#1e1236", "#180e2c", "#10081e", "#e0a0ff"],
	"nido": ["#0e0408", "#2a0e1a", "#220a14", "#16060e", "#ff3a6a"],
	"pueblo": ["#101a14", "#2a4430", "#223826", "#18281c", "#ffe08a"],
}


static func apply_tiles(mat: ShaderMaterial, biome: String) -> void:
	var c: Array = TILES.get(biome, TILES["bosque"])
	var keys := ["c_top", "c_top2", "c_dirt", "c_dirt2", "c_deep", "c_plat", "c_speck"]
	for i in keys.size():
		mat.set_shader_parameter(keys[i], Color(c[i]))


static func apply_bg(mat: ShaderMaterial, biome: String) -> void:
	var c: Array = BG.get(biome, BG["bosque"])
	var keys := ["sky_top", "sky_bot", "far", "mid", "glow"]
	for i in keys.size():
		mat.set_shader_parameter(keys[i], Color(c[i]))
