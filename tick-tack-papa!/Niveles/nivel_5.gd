extends NivelBase
## Nivel 5 cielo: ultimo nivel, poco tiempo. Items por escenas de Items/.

func _ready() -> void:
	nivel_num = 5
	tiempo_limite = 60.0
	siguiente_escena = ""
	super._ready()
	_crear_contenido()


func _crear_contenido() -> void:
	var CartelS: GDScript = load("res://Sistemas/cartel.gd")
	var PinchosS: GDScript = load("res://Sistemas/pinchos.gd")
	var c: Area2D = CartelS.new()
	c.position = Vector2(442, 120)
	c.set("texto", "NIVEL FINAL: la Fuente Sagrada esta cerca\n60 segundos. Sin piedad.")
	add_child(c)
	for d in [[700.0, 374.0], [1100.0, 374.0]]:
		var p: Area2D = PinchosS.new()
		p.position = Vector2(d[0], d[1])
		p.set("mortal", false)
		add_child(p)
