extends SceneTree
## Herramienta (correr una vez): construye el TileSet con colisiones desde
## assets/Terrain (16x16).png y lo guarda en assets/TerrenoTileset.tres.
## Uso: godot --headless --path . --script res://tools/build_tileset.gd
## La hoja es una grilla de 22x11 tiles de 16px con separadores transparentes
## en columnas 5/11/16 y filas 3/7 (esas celdas se omiten).

const RUTA_TEX := "res://assets/Terrain (16x16).png"
const RUTA_TS := "res://assets/TerrenoTileset.tres"

# Ocupacion medida: '#' = tile con pixeles (filas de tiles 0,1,2,4,5,6,8,9,10).
const OCUP := {
	0: "#####.#####.####.###..",
	1: "#####.#####.####.###..",
	2: "###...###....###.###..",
	4: "#####.#####.####.#####",
	5: "#####.#####.####.#####",
	6: "###...###....###.###..",
	8: "#####.#####.####.####.",
	9: "#####.#####.####.####.",
	10: "###...###....###..###.",
}
# Filas con bloques completos -> colision cuadrada. Filas 2/6/10 son piezas
# parciales: se crean sin colision para no generar bordes invisibles.
const FILAS_SOLIDAS := [0, 1, 4, 5, 8, 9]


func _init() -> void:
	var tex := load(RUTA_TEX) as Texture2D
	if tex == null:
		push_error("No se pudo cargar " + RUTA_TEX)
		quit(1)
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer(0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, 0)
	var n_tiles := 0
	var n_col := 0
	for ty in OCUP.keys():
		var fila: String = OCUP[ty]
		for tx in range(22):
			if tx >= fila.length() or fila[tx] != "#":
				continue
			var coord := Vector2i(tx, ty)
			src.create_tile(coord)
			n_tiles += 1
			if ty in FILAS_SOLIDAS:
				var td := src.get_tile_data(coord, 0)
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
				n_col += 1
	var err := ResourceSaver.save(ts, RUTA_TS)
	print("Tiles creados: ", n_tiles, " con colision: ", n_col, " err=", err)
	quit(0 if err == OK else 1)
