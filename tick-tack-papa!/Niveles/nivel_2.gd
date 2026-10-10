extends NivelBase
## Nivel 2 demo: cartel + pinchos leves. Los power-ups, trajes y charcos
## NO se colocan por codigo: arrastra las escenas de Items/ en el editor.
## La meta (Items/AguaMeta.tscn) ya esta instanciada en Nivel2.tscn.

func _ready() -> void:
	nivel_num = 2
	tiempo_limite = 75.0
	siguiente_escena = "res://Niveles/Nivel3.tscn"
	super._ready()
	_crear_contenido()


func _crear_contenido() -> void:
	var CartelS: GDScript = load("res://Sistemas/cartel.gd")
	var PinchosS: GDScript = load("res://Sistemas/pinchos.gd")
	var c: Area2D = CartelS.new()
	c.position = Vector2(442, 120)
	c.set("texto", "NIVEL 2: cuidado con los pinchos\nLa RUSTICA (Items/TrajeRustica) es inmune a los leves")
	add_child(c)
	var p: Area2D = PinchosS.new()
	p.position = Vector2(1100, 374)
	p.set("mortal", false)
	add_child(p)
