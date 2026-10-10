extends Control
## RF-10: menu de pausa por nodos (UI/pausa.tscn). Corre en modo ALWAYS para
## funcionar con el arbol pausado. Reset reintenta, back va al menu.

@onready var btn_reset: Button = %BtnReset
@onready var btn_back: Button = %BtnBack


func _ready() -> void:
	btn_reset.pressed.connect(_on_reset)
	btn_back.pressed.connect(_on_back)


func _on_reset() -> void:
	var nivel := get_tree().get_first_node_in_group("nivel")
	if nivel != null and nivel.has_method("reintentar"):
		nivel.call("reintentar")
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_back() -> void:
	get_tree().paused = false
	Sfx.suena(self, "CambiarLevel.mp3")
	get_tree().change_scene_to_file("res://UI/menu_principal.tscn")
