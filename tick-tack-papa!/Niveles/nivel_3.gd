extends NivelBase
## Nivel 3 noche: cartel + pinchos leves. Items por escenas de Items/.

func _ready() -> void:
	nivel_num = 3
	tiempo_limite = 75.0
	siguiente_escena = "res://Niveles/Nivel4.tscn"
	super._ready()
	_crear_contenido()


func _crear_contenido() -> void:
	var CartelS: GDScript = load("res://Sistemas/cartel.gd")
	var PinchosS: GDScript = load("res://Sistemas/pinchos.gd")
	var c: Area2D = CartelS.new()
	c.position = Vector2(442, 120)
	c.set("texto", "NIVEL 3: de noche hace mas frio... o no?\nBusca la botella (Items/ItemBotella) si te acaloras")
	add_child(c)
	var p: Area2D = PinchosS.new()
	p.position = Vector2(700, 374)
	p.set("mortal", false)
	add_child(p)
