extends SceneTree
## Herramienta (archivos NUEVOS solamente): crea Nivel3/4/5.tscn con
## TileMapLayer, parallax, HUD, Timer, musica y meta.
## Uso: godot --headless --path . --script res://tools/build_niveles345.gd

const TS_TIERRA := "res://assets/TerrenoTileset.tres"
const PAPA_SCENE := "res://papa.tscn"
const HUD_SCENE := "res://UI/hud.tscn"
const AGUA_META := "res://Items/AguaMeta.tscn"

const T_GRIS_TOP := Vector2i(1, 0)
const T_GRIS := Vector2i(1, 1)
const T_PASTO := Vector2i(7, 0)
const T_TIERRA := Vector2i(7, 1)

const FONDO_N3 := [
	["res://assets/parallax/nigth/nigth__sky.png", 0.0],
	["res://assets/parallax/nigth/nigth_back.png", 0.25],
	["res://assets/parallax/nigth/nigth_mid.png", 0.5],
	["res://assets/parallax/nigth/nigth_front.png", 0.75],
	["res://assets/parallax/nigth/nigth_floor.png", 1.0],
]
const FONDO_N4 := [
	["res://assets/parallax/forest/forest_sky.png", 0.0],
	["res://assets/parallax/forest/forest_moon.png", 0.0],
	["res://assets/parallax/forest/forest_mountain.png", 0.15],
	["res://assets/parallax/forest/forest_back.png", 0.35],
	["res://assets/parallax/forest/forest_mid.png", 0.55],
	["res://assets/parallax/forest/forest_short.png", 0.75],
	["res://assets/parallax/forest/forest_long.png", 0.9],
]
const FONDO_N5 := [
	["res://assets/parallax/skies/Sky_sky.png", 0.0],
	["res://assets/parallax/skies/sky_moon.png", 0.0],
	["res://assets/parallax/skies/sky_clouds.png", 0.1],
	["res://assets/parallax/skies/Sky_cloud_single.png", 0.2],
	["res://assets/parallax/skies/Sky_back_mountain.png", 0.25],
	["res://assets/parallax/skies/sky_front_mountain.png", 0.4],
	["res://assets/parallax/skies/Sky_front_cloud.png", 0.55],
	["res://assets/parallax/skies/sky_cloud_floor.png", 0.75],
	["res://assets/parallax/skies/sky_cloud_floor_2.png", 0.9],
]


func _pintar(layer: TileMapLayer, top: Vector2i, relleno: Vector2i, x0: int, x1: int, y0: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		layer.set_cell(Vector2i(x, y0), 0, top)
		for y in range(y0 + 1, y1 + 1):
			layer.set_cell(Vector2i(x, y), 0, relleno)


func _fondo(root: Node2D, capas: Array) -> void:
	var bg := ParallaxBackground.new()
	bg.name = "Fondo"
	root.add_child(bg)
	bg.set_owner(root)
	# Se agrega primero: queda detras de tiles, papa y meta.
	for par in capas:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(float(par[1]), 0.0)
		bg.add_child(layer)
		layer.set_owner(root)
		var spr := Sprite2D.new()
		spr.texture = load(str(par[0])) as Texture2D
		spr.position = Vector2(640, 360)
		spr.centered = true
		layer.add_child(spr)
		spr.set_owner(root)


func _base(nivel_script: String, tiempo: float, musica: String, nombre_mus: String, fondo: Array, meta_x: float) -> Node2D:
	var root := Node2D.new()
	root.name = "Nivel"
	root.set_script(load(nivel_script))
	var ts := load(TS_TIERRA) as TileSet
	if ts == null:
		push_error("Falta " + TS_TIERRA)
		quit(1)
		return root
	_fondo(root, fondo)
	var layer := TileMapLayer.new()
	layer.name = "Terreno"
	layer.tile_set = ts
	root.add_child(layer)
	layer.set_owner(root)
	_pintar(layer, T_PASTO, T_TIERRA, 0, 100, 33, 36)
	_pintar(layer, T_GRIS_TOP, T_GRIS, 31, 50, 25, 26)
	_pintar(layer, T_GRIS_TOP, T_GRIS, 56, 75, 19, 20)
	_pintar(layer, T_GRIS_TOP, T_GRIS, 81, 100, 26, 27)
	var papa := (load(PAPA_SCENE) as PackedScene).instantiate()
	papa.position = Vector2(200, 200)
	root.add_child(papa)
	papa.set_owner(root)
	var hud := (load(HUD_SCENE) as PackedScene).instantiate()
	root.add_child(hud)
	hud.set_owner(root)
	var nt := Timer.new()
	nt.name = "NivelTimer"
	nt.wait_time = tiempo
	nt.one_shot = true
	root.add_child(nt)
	nt.set_owner(root)
	var mus := AudioStreamPlayer.new()
	mus.name = nombre_mus
	mus.add_to_group("musica_nivel")
	mus.stream = load(musica) as AudioStream
	mus.autoplay = true
	root.add_child(mus)
	mus.set_owner(root)
	var meta := (load(AGUA_META) as PackedScene).instantiate()
	meta.position = Vector2(meta_x, 290)
	root.add_child(meta)
	meta.set_owner(root)
	return root


func _guardar(root: Node, ruta: String) -> void:
	var ps := PackedScene.new()
	if ps.pack(root) != OK:
		push_error("pack fallo: " + ruta)
		quit(1)
		return
	print("guardado ", ruta, " err=", ResourceSaver.save(ps, ruta))


func _init() -> void:
	var n3 := _base("res://Niveles/nivel_3.gd", 75.0, "res://assets/Sounds/introduccion.mp3", "MusicaNivel3", FONDO_N3, 1450.0)
	_guardar(n3, "res://Niveles/Nivel3.tscn")
	n3.free()
	var n4 := _base("res://Niveles/nivel_4.gd", 70.0, "res://assets/Sounds/level4.mp3", "MusicaNivel4", FONDO_N4, 1450.0)
	_guardar(n4, "res://Niveles/Nivel4.tscn")
	n4.free()
	var n5 := _base("res://Niveles/nivel_5.gd", 60.0, "res://assets/Sounds/level5.mp3", "MusicaNivel5", FONDO_N5, 1400.0)
	_guardar(n5, "res://Niveles/Nivel5.tscn")
	n5.free()
	print("listo")
	quit()
