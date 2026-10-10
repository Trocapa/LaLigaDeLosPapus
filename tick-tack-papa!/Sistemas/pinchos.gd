class_name PinchosTrampa
extends Area2D
## RF-09: colision AABB con la papa. Leves (+15% calor, rustica inmune),
## mortales (derrota directa). RF-02.

@export var mortal: bool = false
@export var ancho: float = 48.0


func _ready() -> void:
	add_to_group("pinchos")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(ancho, 20.0)
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	var poly := Polygon2D.new()
	var h := 20.0
	var c := Color(0.6, 0.6, 0.65) if not mortal else Color(1.0, 0.2, 0.2)
	poly.polygon = PackedVector2Array([Vector2(-ancho / 2, h / 2), Vector2(ancho / 2, h / 2), Vector2(0, -h / 2)])
	poly.color = c
	add_child(poly)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("papa") and body.has_method("pincho_tocado"):
		body.call("pincho_tocado", mortal)
