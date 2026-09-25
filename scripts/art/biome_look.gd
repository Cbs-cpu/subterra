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
	"bosque": ["#070e0b", "#101f14", "#0e1912", "#09110d", "#6ae07a"],
	"cienaga": ["#090710", "#130e1d", "#100c1a", "#0b0812", "#b07ae0"],
	"pradera": ["#10070b", "#1f0e14", "#1a0c11", "#12070c", "#ff9aaa"],
	"cavernas": ["#060609", "#0f0f14", "#0d0d11", "#08080c", "#8a8aa0"],
	"tundra": ["#070c13", "#172231", "#121b28", "#0d131d", "#e0f4ff"],
	"mazmorra": ["#060505", "#100e0d", "#0e0c0b", "#090807", "#e0b04a"],
	"volcan": ["#0e0403", "#1f0b05", "#1a0804", "#110503", "#ff8a3a"],
	"cantera": ["#040b0b", "#091a1a", "#071414", "#050e0e", "#8af0e8"],
	"crater": ["#05030b", "#10091d", "#0d0718", "#080410", "#e0a0ff"],
	"nido": ["#070204", "#17070e", "#12050b", "#0c0307", "#ff3a6a"],
	"pueblo": ["#080e0b", "#17251a", "#121e14", "#0d160f", "#ffe08a"],
}


const AMBIENT := {
	"bosque": "#0f1412", "cienaga": "#0f0e13", "pradera": "#140e11", "cavernas": "#0c0c0f", "tundra": "#14171c",
	"mazmorra": "#0b0a0a", "volcan": "#140c0a", "cantera": "#0c1213", "crater": "#0e0b13", "nido": "#0f090d",
	"pueblo": "#1d1b18",
}


static func ambient(biome: String) -> Color:
	return Color(AMBIENT.get(biome, "#3a4a44"))


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
