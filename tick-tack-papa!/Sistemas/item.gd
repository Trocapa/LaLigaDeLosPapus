class_name ItemRecogible
extends Area2D
## RF-05 + RN-02: item de un solo uso. Catalogo 3.1/3.2/3.3 + trajes RF-07.
## Tipos: botella, aceite, mantequilla, carbon, aji, sal, misterioso,
##        traje_criolla, traje_rustica, traje_helada, traje_picante.
## La escena (Items/*.tscn) trae Sprite2D + CollisionShape2D propios con el
## arte final; aqui SOLO se crea colision por codigo si falta (para no pisar
## ediciones del editor). No se toca modulate ni se agregan etiquetas.

signal recogido(tipo: String, mensaje: String)

@export var tipo: String = "botella"
var consumido: bool = false

# Numero que vuela al termometro al recoger.
const VALORES := {
	"botella": "-20%", "aceite": "+5s", "mantequilla": "+30%",
	"carbon": "+20%", "aji": "2x!", "sal": "-25%",
	"misterioso": "?", "traje_criolla": "+TRAJE", "traje_rustica": "+TRAJE",
	"traje_helada": "+TRAJE", "traje_picante": "+TRAJE",
}

# Levitacion: sube y baja en bucle.
const LEV_AMP := 6.0
const LEV_VEL := 2.0
var _base_y := 0.0
var _base_ok := false
var _fase := 0.0

const COLORES := {
	"botella": Color(0.6, 0.9, 1.0),
	"aceite": Color(1.0, 0.8, 0.2),
	"mantequilla": Color(1.0, 0.95, 0.6),
	"carbon": Color(0.25, 0.25, 0.25),
	"aji": Color(1.0, 0.2, 0.1),
	"sal": Color(0.9, 0.9, 0.9),
	"misterioso": Color(0.8, 0.3, 0.9),
	"traje_criolla": Color(0.95, 0.8, 0.35),
	"traje_rustica": Color(0.45, 0.3, 0.18),
	"traje_helada": Color(0.6, 0.85, 1.0),
	"traje_picante": Color(0.9, 0.3, 0.15),
}


func _ready() -> void:
	add_to_group("item")
	if get_node_or_null("CollisionShape2D") == null:
		var cs := CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 20.0
		cs.shape = shape
		add_child(cs)
	if get_node_or_null("Sprite2D") == null and get_node_or_null("Polygon2D") == null:
		var poly := Polygon2D.new()
		poly.name = "Polygon2D"
		var s := 16.0
		poly.polygon = PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)])
		poly.color = COLORES.get(tipo, Color.WHITE)
		add_child(poly)
	# Destellos del color del item (solo si la escena no trae particulas).
	if get_node_or_null("ItemParticulas") == null:
		var chispas := CPUParticles2D.new()
		chispas.name = "ItemParticulas"
		chispas.amount = 10
		chispas.lifetime = 1.2
		chispas.preprocess = 1.2
		chispas.spread = 180.0
		chispas.gravity = Vector2(0, -20)
		chispas.initial_velocity_min = 10.0
		chispas.initial_velocity_max = 25.0
		chispas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		chispas.emission_sphere_radius = 14.0
		chispas.scale_amount_min = 2.0
		chispas.scale_amount_max = 4.0
		chispas.color = COLORES.get(tipo, Color.WHITE)
		add_child(chispas)
	_fase = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if consumido:
		return
	if not _base_ok:
		_base_y = position.y
		_base_ok = true
	position.y = _base_y + sin(Time.get_ticks_msec() / 1000.0 * LEV_VEL + _fase) * LEV_AMP


func _on_body_entered(body: Node2D) -> void:
	if consumido:
		return
	if body.is_in_group("papa") and body.has_method("aplicar_item"):
		consumido = true # RN-02: consumo unico
		var msg: String = str(body.call("aplicar_item", tipo))
		Sfx.suena(self, "SFX_Item.mp3")
		recogido.emit(tipo, msg)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("mostrar_efecto"):
			# Verde si el efecto es positivo, rojo si es negativo.
			var bueno := tipo in ["botella", "aceite", "mantequilla"] \
				or tipo.begins_with("traje_") \
				or (tipo == "misterioso" and "TOTAL" in msg)
			hud.call("mostrar_efecto", VALORES.get(tipo, "?"), bueno)
		queue_free()
