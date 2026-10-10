extends NivelBase
## Nivel 4 bosque completo: mas pinchos. Items por escenas de Items/.

func _ready() -> void:
	nivel_num = 4
	tiempo_limite = 70.0
	siguiente_escena = "res://Niveles/Nivel5.tscn"
	super._ready()
	_crear_contenido()


func _crear_contenido() -> void:
	var CartelS: GDScript = load("res://Sistemas/cartel.gd")
	var PinchosS: GDScript = load("res://Sistemas/pinchos.gd")
	var c: Area2D = CartelS.new()
	c.position = Vector2(442, 120)
	c.set("texto", "NIVEL 4: el bosque esta revuelto\nEl aji (Items/ItemAji) da impulso pero calienta x2")
	add_child(c)
	for px in [700.0, 1100.0]:
		var p: Area2D = PinchosS.new()
		p.position = Vector2(px, 374.0)
		p.set("mortal", false)
		add_child(p)
