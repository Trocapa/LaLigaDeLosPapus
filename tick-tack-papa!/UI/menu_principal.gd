extends Control
## RF-10: menu principal por nodos (ver menu_principal.tscn).
## Solo crea la conexion del boton JUGAR; posiciones/textos se editan en el .tscn.

@onready var btn_jugar: Button = %Jugar


func _ready() -> void:
	btn_jugar.pressed.connect(_on_jugar_pressed)


func _on_jugar_pressed() -> void:
	Sfx.suena(self, "CambiarLevel.mp3")
	get_tree().change_scene_to_file("res://Niveles/Nivel1.tscn")
