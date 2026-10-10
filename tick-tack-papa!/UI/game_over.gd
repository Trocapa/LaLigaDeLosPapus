extends Control
## RF-10: menu de game over / victoria por nodos (UI/game_over.tscn).
## El nivel la instancia y llama a mostrar(); textos y posiciones en el .tscn.
## Botones: reset reintenta el nivel, back vuelve al menu principal.

@onready var titulo: Label = %Titulo
@onready var detalle: Label = %Detalle
@onready var btn_reset: Button = %BtnReset
@onready var btn_back: Button = %BtnBack


func _ready() -> void:
	btn_reset.pressed.connect(_on_reset)
	btn_back.pressed.connect(_on_back)


func mostrar(t: String, d: String) -> void:
	titulo.text = t
	detalle.text = d


func _on_reset() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/menu_principal.tscn")
