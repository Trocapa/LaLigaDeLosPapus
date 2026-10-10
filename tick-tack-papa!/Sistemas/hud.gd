class_name HUDJuego
extends CanvasLayer
## RF-12: termometro, cuenta regresiva, tipo de papa, estado del dash.
## RF-10: mensajes de pausa / game over / victoria. RN-04 mensajes.

var termo_frame: TextureRect
var mercurio: ColorRect
var label_pct: Label
var label_tiempo: Label
var label_traje: Label
var label_dash: Label
var label_msg: Label
var label_bono: Label
var panel_fin: PanelContainer
var label_fin: Label
var _msg_timer: Timer

# Geometria del termometro (Healthbars.png): tubo x 3-13, y 248-279.
# Mercurio interior: x 5-11, y 250-277. Escala de dibujo 3x.
const TERMO_REGION := Rect2(3, 248, 11, 32)
const TERMO_ESCALA := 3.0
const MERC_X := 5.0
const MERC_W := 7.0
const MERC_ABAJO := 277.0
const MERC_ALTO_MAX := 27.0

const BAR_VERDE := Color(0.35, 0.9, 0.35)
const BAR_AMARILLO := Color(1.0, 0.85, 0.15)
const BAR_ROJO := Color(1.0, 0.15, 0.1)


static func color_por_temp(f: float) -> Color:
	var c := clampf(f, 0.0, 1.0)
	if c <= 0.5:
		return BAR_VERDE.lerp(BAR_AMARILLO, c * 2.0)
	return BAR_AMARILLO.lerp(BAR_ROJO, (c - 0.5) * 2.0)


func _ready() -> void:
	add_to_group("hud")
	# Termometro (asset Healthbars.png) arriba-izquierda + % a su derecha
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/Healthbars.png")
	atlas.region = TERMO_REGION
	termo_frame = TextureRect.new()
	termo_frame.texture = atlas
	termo_frame.position = Vector2(16, 16)
	termo_frame.custom_minimum_size = Vector2(11 * TERMO_ESCALA, 32 * TERMO_ESCALA)
	termo_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	termo_frame.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(termo_frame)
	mercurio = ColorRect.new()
	mercurio.color = BAR_VERDE
	add_child(mercurio)
	_actualizar_mercurio(0.0)

	label_pct = Label.new()
	label_pct.position = Vector2(58, 48)
	label_pct.add_theme_font_size_override("font_size", 26)
	label_pct.add_theme_constant_override("outline_size", 6)
	label_pct.text = "0%"
	add_child(label_pct)

	label_tiempo = Label.new()
	label_tiempo.position = Vector2(16, 120)
	label_tiempo.add_theme_font_size_override("font_size", 26)
	label_tiempo.add_theme_constant_override("outline_size", 6)
	label_tiempo.text = "Tiempo: --"
	add_child(label_tiempo)

	label_traje = Label.new()
	label_traje.position = Vector2(16, 152)
	label_traje.add_theme_font_size_override("font_size", 18)
	label_traje.add_theme_constant_override("outline_size", 5)
	label_traje.text = "Papa: Rey"
	add_child(label_traje)

	label_dash = Label.new()
	label_dash.position = Vector2(16, 178)
	label_dash.add_theme_font_size_override("font_size", 18)
	label_dash.add_theme_constant_override("outline_size", 5)
	label_dash.text = "Dash: LISTO (Espacio)"
	add_child(label_dash)

	label_bono = Label.new()
	label_bono.position = Vector2(16, 204)
	label_bono.add_theme_font_size_override("font_size", 16)
	label_bono.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	label_bono.text = ""
	add_child(label_bono)

	label_msg = Label.new()
	label_msg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label_msg.position = Vector2(-300, 16)
	label_msg.size = Vector2(600, 40)
	label_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_msg.add_theme_font_size_override("font_size", 20)
	label_msg.add_theme_constant_override("outline_size", 6)
	add_child(label_msg)

	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.wait_time = 3.0
	_msg_timer.timeout.connect(func() -> void: label_msg.text = "")
	add_child(_msg_timer)

	# Conectar papa si existe
	await get_tree().process_frame
	var papa := get_tree().get_first_node_in_group("papa")
	if papa != null:
		if papa.has_signal("temperatura_changed"):
			papa.connect("temperatura_changed", _on_temp)
		if papa.has_signal("dash_changed"):
			papa.connect("dash_changed", _on_dash)
		if papa.has_signal("traje_changed"):
			papa.connect("traje_changed", _on_traje)


func _process(_delta: float) -> void:
	var t := get_tree().get_first_node_in_group("nivel_timer")
	if t is Timer:
		label_tiempo.text = "Tiempo: %d" % int(ceil((t as Timer).time_left))


func _actualizar_mercurio(v: float) -> void:
	var f := clampf(v / 100.0, 0.0, 1.0)
	var h := maxf(1.0, f * MERC_ALTO_MAX * TERMO_ESCALA) if f > 0.0 else 0.0
	var abajo := 16.0 + (MERC_ABAJO - TERMO_REGION.position.y) * TERMO_ESCALA
	mercurio.position = Vector2(16.0 + (MERC_X - TERMO_REGION.position.x) * TERMO_ESCALA, abajo - h)
	mercurio.size = Vector2(MERC_W * TERMO_ESCALA, h)
	mercurio.color = color_por_temp(f)
	mercurio.visible = f > 0.0


func _on_temp(v: float) -> void:
	_actualizar_mercurio(v)
	label_pct.text = "%d%%" % int(round(v))
	if v >= 80.0:
		mostrar_mensaje("PELIGRO: la papa va a explotar!")


func _on_dash(listo: bool, restante: float) -> void:
	label_dash.text = "Dash: LISTO (Espacio)" if listo else "Dash: %.1fs" % restante


func _on_traje(t: String) -> void:
	label_traje.text = "Papa: " + t.capitalize()


func mostrar_mensaje(m: String) -> void:
	label_msg.text = m
	_msg_timer.start(3.0)


func mostrar_bono_f7(activo: bool) -> void:
	label_bono.text = "BONO F7: -30% calor +10s (2 derrotas)" if activo else ""


func mostrar_fin(titulo: String, detalle: String) -> void:
	if panel_fin != null:
		panel_fin.queue_free()
	panel_fin = PanelContainer.new()
	panel_fin.set_anchors_preset(Control.PRESET_CENTER)
	panel_fin.custom_minimum_size = Vector2(420, 200)
	var vb := VBoxContainer.new()
	panel_fin.add_child(vb)
	label_fin = Label.new()
	label_fin.text = titulo + "\n" + detalle + "\n[R] reintentar  [M] menu"
	label_fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_fin.add_theme_font_size_override("font_size", 20)
	vb.add_child(label_fin)
	add_child(panel_fin)
