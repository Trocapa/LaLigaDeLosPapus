extends NivelBase
## Nivel 1 tutorial: solo carteles (RF-13). Los power-ups, trajes y charcos
## NO se colocan por codigo: arrastra las escenas de Items/ en el editor.
## La meta (Items/AguaMeta.tscn) ya esta instanciada en Nivel1.tscn.

func _ready() -> void:
	nivel_num = 1
	tiempo_limite = 90.0
	siguiente_escena = "res://Niveles/Nivel2.tscn"
	super._ready()
	_crear_carteles()


func _crear_carteles() -> void:
	var CartelS: GDScript = load("res://Sistemas/cartel.gd")
	var c1: Area2D = CartelS.new()
	c1.position = Vector2(442, 120)
	c1.set("texto", "A/D o Flechas: moverse\nFLECHA ARRIBA o W: saltar\nESPACIO: dash")
	add_child(c1)
	var c2: Area2D = CartelS.new()
	c2.position = Vector2(1300, 120)
	c2.set("texto", "Llega al agua VERDE antes de explotar!\nEl agua enfria -30% (F2)")
	add_child(c2)
