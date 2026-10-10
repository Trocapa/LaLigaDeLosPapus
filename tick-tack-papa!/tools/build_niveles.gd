extends SceneTree
## Herramienta: reconstruye Nivel1.tscn / Nivel2.tscn con TileMapLayer,
## HUD instanciado, Timer visible y musica propia.
## !! NO EJECUTAR: los niveles tienen ediciones manuales que se perderian.
## Los cambios a niveles se hacen con edicion quirurgica del .tscn.
## Uso (solo si se acepta perder ediciones):
## godot --headless --path . --script res://tools/build_niveles.gd

const TS_TIERRA := "res://assets/TerrenoTileset.tres"
const PAPA_SCENE := "res://papa.tscn"
const HUD_SCENE := "res://UI/hud.tscn"
const AGUA_META := "res://Items/AguaMeta.tscn"

const T_GRIS_TOP := Vector2i(1, 0)
const T_GRIS := Vector2i(1, 1)
const T_PASTO := Vector2i(7, 0)
const T_TIERRA := Vector2i(7, 1)


func _pintar(layer: TileMapLayer, top: Vector2i, relleno: Vector2i, x0: int, x1: int, y0: int, y1: int) -> void:
	for x in range(x0, x1 + 1):
		layer.set_cell(Vector2i(x, y0), 0, top)
		for y in range(y0 + 1, y1 + 1):
			layer.set_cell(Vector2i(x, y), 0, relleno)


func _base(nivel_script: String, tiempo: float, musica: String) -> Node2D:
	var root := Node2D.new()
	root.name = "Nivel"
	root.set_script(load(nivel_script))
	var ts := load(TS_TIERRA) as TileSet
	if ts == null:
		push_error("Falta " + TS_TIERRA + " (corre build_tileset.gd primero)")
		quit(1)
		return root
	var layer := TileMapLayer.new()
	layer.name = "Terreno"
	layer.tile_set = ts
	root.add_child(layer)
	layer.set_owner(root)
	# Suelo: fila 33 pasto, 34-36 tierra (techo del suelo en y=528).
	_pintar(layer, T_PASTO, T_TIERRA, 0, 100, 33, 36)
	# Plataforma 1 (techo y=400) y 2 (techo y=304).
	_pintar(layer, T_GRIS_TOP, T_GRIS, 31, 50, 25, 26)
	_pintar(layer, T_GRIS_TOP, T_GRIS, 56, 75, 19, 20)
	# Plataforma de la meta (techo y=416).
	_pintar(layer, T_GRIS_TOP, T_GRIS, 81, 100, 26, 27)
	var papa := (load(PAPA_SCENE) as PackedScene).instantiate()
	papa.position = Vector2(200, 200)
	root.add_child(papa)
	papa.set_owner(root)
	var hud := (load(HUD_SCENE) as PackedScene).instantiate()
	root.add_child(hud)
	hud.set_owner(root)
	# Timer visible del nivel (NivelBase lo reutiliza y le aplica tiempo/bono).
	var nt := Timer.new()
	nt.name = "NivelTimer"
	nt.wait_time = tiempo
	nt.one_shot = true
	root.add_child(nt)
	nt.set_owner(root)
	# Musica del nivel.
	var mus := AudioStreamPlayer.new()
	mus.name = "Musica"
	mus.stream = load(musica) as AudioStream
	mus.autoplay = true
	root.add_child(mus)
	mus.set_owner(root)
	return root


func _guardar(root: Node, ruta: String) -> void:
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack fallo: " + ruta)
		quit(1)
		return
	err = ResourceSaver.save(ps, ruta)
	print("guardado ", ruta, " err=", err)


func _init() -> void:
	# Nivel 1
	var n1 := _base("res://Niveles/nivel_1.gd", 90.0, "res://assets/Sounds/(1 Level) Cave Pulse.mp3")
	var meta1 := (load(AGUA_META) as PackedScene).instantiate()
	meta1.position = Vector2(1450, 290)
	n1.add_child(meta1)
	meta1.set_owner(n1)
	_guardar(n1, "res://Niveles/Nivel1.tscn")
	n1.free()
	# Nivel 2
	var n2 := _base("res://Niveles/nivel_2.gd", 75.0, "res://assets/Sounds/(2 Level) Frozen Cavern Arpeggios.mp3")
	var meta2 := (load(AGUA_META) as PackedScene).instantiate()
	meta2.position = Vector2(1400, 290)
	n2.add_child(meta2)
	meta2.set_owner(n2)
	_guardar(n2, "res://Niveles/Nivel2.tscn")
	n2.free()
	print("listo")
	quit()
