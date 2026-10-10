class_name CartelTutorial
extends Area2D
## RF-13 + RN-04: cartel flotante. Muestra texto al entrar en la BoundingBox,
## oculta al salir o tras 4 s. Panel oscuro semitransparente, sin poste.

@export_multiline var texto: String = "A/D moverse - Arriba/W saltar - Espacio dash"
@export var duracion: float = 4.0

var _panel: Panel
var _label: Label
var _timer: Timer


func _ready() -> void:
	add_to_group("cartel")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 120)
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_panel = Panel.new()
	_panel.position = Vector2(-140, -120)
	_panel.size = Vector2(280, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.85)
	sb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.visible = false
	add_child(_panel)
	_label = Label.new()
	_label.text = texto
	_label.position = Vector2(-140, -120)
	_label.size = Vector2(280, 60)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_constant_override("outline_size", 6)
	_label.visible = false
	add_child(_label)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = duracion
	_timer.timeout.connect(_ocultar)
	add_child(_timer)


func _ocultar() -> void:
	_panel.visible = false
	_label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("papa"):
		_panel.visible = true
		_label.visible = true
		_timer.start(duracion)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("papa"):
		_ocultar()
		_timer.stop()
