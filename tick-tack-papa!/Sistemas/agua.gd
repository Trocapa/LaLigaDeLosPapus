class_name AguaZona
extends Area2D
## RF-03 / RF-14 / RF-08: zona de agua.
## - AguaMeta (es_meta=true, verde): completa el nivel y avanza al siguiente.
## - AguaCharco (es_meta=false, azul): quita -30% calor sin completar (item de agua).
## La escena trae Sprite2D + CollisionShape2D propios; aqui SOLO se crean
## por codigo si faltan (para no pisar ediciones del editor).

@export var es_meta: bool = false
@export var es_transicion: bool = false
@export var radio: float = 48.0


func _ready() -> void:
	add_to_group("agua")
	if get_node_or_null("CollisionShape2D") == null:
		var cs := CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = radio
		cs.shape = shape
		add_child(cs)
	if get_node_or_null("Sprite2D") == null:
		var poly := Polygon2D.new()
		poly.name = "Sprite2D"
		var r := radio
		poly.polygon = PackedVector2Array([Vector2(-r, -8), Vector2(r, -8), Vector2(r, 8), Vector2(-r, 8)])
		poly.color = Color(0.2, 1.0, 0.6, 0.85) if es_meta else Color(0.2, 0.6, 1.0, 0.8)
		add_child(poly)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("papa") and body.has_method("tocar_agua"):
		body.call("tocar_agua", es_meta, es_transicion)
		if es_meta:
			var nivel := get_parent()
			while nivel != null and not nivel.has_method("completar_nivel"):
				nivel = nivel.get_parent()
			if nivel != null:
				nivel.call("completar_nivel")
