class_name HUDJuego
extends CanvasLayer
## RF-12: termometro, cuenta regresiva, tipo de papa, estado del dash.
## RF-10: mensajes de pausa / game over / victoria. RN-04 mensajes.

var barra_temp: ProgressBar
var label_tiempo: Label
var label_traje: Label
var label_dash: Label
var label_msg: Label
var label_bono: Label
var panel_fin: PanelContainer
var label_fin: Label
var _msg_timer: Timer
var _fill_temp: StyleBoxFlat

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
	# Barra temperatura arriba-izquierda
	barra_temp = ProgressBar.new()
	barra_temp.min_value = 0
	barra_temp.max_value = 100
	barra_temp.value = 0
	barra_temp.custom_minimum_size = Vector2(260, 26)
	barra_temp.position = Vector2(16, 16)
	barra_temp.show_percentage = true
	_fill_temp = StyleBoxFlat.new()
	_fill_temp.bg_color = BAR_VERDE
	barra_temp.add_theme_stylebox_override("fill", _fill_temp)
	add_child(barra_temp)

	var lab := Label.new()
	lab.text = "TEMP"
	lab.position = Vector2(16, 44)
	lab.add_theme_font_size_override("font_size", 14)
	add_child(lab)

	label_tiempo = Label.new()
	label_tiempo.position = Vector2(16, 64)
	label_tiempo.add_theme_font_size_override("font_size", 26)
	label_tiempo.add_theme_constant_override("outline_size", 6)
	label_tiempo.text = "Tiempo: --"
	add_child(label_tiempo)

	label_traje = Label.new()
	label_traje.position = Vector2(16, 100)
	label_traje.add_theme_font_size_override("font_size", 18)
	label_traje.add_theme_constant_override("outline_size", 5)
	label_traje.text = "Papa: Rey"
	add_child(label_traje)

	label_dash = Label.new()
	label_dash.position = Vector2(16, 126)
	label_dash.add_theme_font_size_override("font_size", 18)
	label_dash.add_theme_constant_override("outline_size", 5)
	label_dash.text = "Dash: LISTO (Espacio)"
	add_child(label_dash)

	label_bono = Label.new()
	label_bono.position = Vector2(16, 152)
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


func _on_temp(v: float) -> void:
	barra_temp.value = v
	if _fill_temp != null:
		_fill_temp.bg_color = color_por_temp(v / 100.0)
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
