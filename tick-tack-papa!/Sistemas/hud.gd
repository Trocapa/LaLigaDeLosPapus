class_name HUDJuego
extends CanvasLayer
## RF-12: termometro de 5 niveles, cuenta regresiva, tipo de papa, dash radial.
## RF-10 / RN-04: mensajes y teclas (pausa R/M/N/Esc) — el HUD corre en
## modo ALWAYS para seguir recibiendo input en pausa. Nodos en UI/hud.tscn.
## Teclas (kb_light_symbols, flechas) se iluminan al presionarlas.

const BAR_VERDE := Color(0.35, 0.9, 0.35)
const BAR_ROJO := Color(1.0, 0.35, 0.3)
const DASH_LISTO := Color(0.2, 0.9, 0.3)
const DASH_CARGA := Color(1.0, 0.2, 0.15)

# Rellenos del termometro (Healthbars.png): 5 niveles de vida, y 252-276.
const FILLS := [119.0, 103.0, 87.0, 71.0, 55.0] # x por nivel de vida 1..5
# Circulo blanco del dash (Healthbars.png).
const CIRCULO := Rect2(0, 0, 16, 16)

@onready var termo_fill: TextureRect = $TermoFill
@onready var label_pct: Label = $Pct
@onready var label_tiempo: Label = $Tiempo
@onready var label_traje: Label = $Traje
@onready var dash_bar: TextureProgressBar = $DashBar
@onready var transicion: ColorRect = $Transicion
@onready var label_bono: Label = $Bono
@onready var label_msg: Label = $Msg
@onready var key_izq: TextureRect = $Teclas/FilaMove/KeyIzq
@onready var key_der: TextureRect = $Teclas/FilaMove/KeyDer
@onready var key_salto: TextureRect = $Teclas/FilaUp/KeySalto
@onready var key_dash: PanelContainer = $Teclas/FilaDash/KeyDash

var _fills: Array[AtlasTexture] = []
var _tecla_idle := {}
var _tecla_puls := {}
var _dash_bg: ImageTexture
var _dash_rojo: ImageTexture
var _dash_verde: ImageTexture
var _dash_cooldown := 1.0
var _msg_timer: Timer
var _trans_t := -1.0
var _trans_dur := 0.9
var _trans_nivel: Node = null


static func nivel_vida(vida_pct: float) -> int:
	## 5 = lleno-verde … 1 = casi vacio-rojo.
	if vida_pct > 80.0:
		return 5
	if vida_pct > 60.0:
		return 4
	if vida_pct > 40.0:
		return 3
	if vida_pct > 20.0:
		return 2
	return 1


func _atlas(path: String, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = load(path)
	a.region = region
	return a


## Tiñe el circulo blanco del asset al color dado (conserva alfa).
func _circulo_tintado(color: Color) -> ImageTexture:
	var img := (load("res://assets/Healthbars.png") as Texture2D).get_image()
	var c := img.get_region(Rect2i(CIRCULO))
	c.convert(Image.FORMAT_RGBA8)
	for y in range(c.get_height()):
		for x in range(c.get_width()):
			var p := c.get_pixel(x, y)
			if p.a > 0.0:
				c.set_pixel(x, y, Color(color.r, color.g, color.b, p.a))
	return ImageTexture.create_from_image(c)


func _ready() -> void:
	add_to_group("hud")
	for x in FILLS:
		_fills.append(_atlas("res://assets/Healthbars.png", Rect2(x, 252, 3, 24)))
	_tecla_idle["izq"] = _atlas("res://assets/kb_light_symbols.png", Rect2(64, 208, 16, 16))
	_tecla_puls["izq"] = _atlas("res://assets/kb_light_symbols.png", Rect2(80, 208, 16, 16))
	_tecla_idle["der"] = _atlas("res://assets/kb_light_symbols.png", Rect2(64, 240, 16, 16))
	_tecla_puls["der"] = _atlas("res://assets/kb_light_symbols.png", Rect2(80, 240, 16, 16))
	_tecla_idle["salto"] = _atlas("res://assets/kb_light_symbols.png", Rect2(64, 192, 16, 16))
	_tecla_puls["salto"] = _atlas("res://assets/kb_light_symbols.png", Rect2(80, 192, 16, 16))
	key_izq.texture = _tecla_idle["izq"]
	key_der.texture = _tecla_idle["der"]
	key_salto.texture = _tecla_idle["salto"]
	_dash_bg = _circulo_tintado(Color(0.18, 0.18, 0.2))
	_dash_rojo = _circulo_tintado(DASH_CARGA)
	_dash_verde = _circulo_tintado(DASH_LISTO)
	dash_bar.texture_under = _dash_bg
	dash_bar.texture_progress = _dash_verde
	dash_bar.value = 100.0
	_msg_timer = Timer.new()
	_msg_timer.one_shot = true
	_msg_timer.wait_time = 3.0
	_msg_timer.timeout.connect(func() -> void: label_msg.text = "")
	add_child(_msg_timer)
	_on_temp(0.0)
	# Conectar papa si existe
	await get_tree().process_frame
	var papa := get_tree().get_first_node_in_group("papa")
	if papa != null:
		_dash_cooldown = float(papa.get("dash_cooldown")) if papa.get("dash_cooldown") != null else 1.0
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
	_actualizar_tecla(key_izq, "izq", Input.is_action_pressed("ui_left"))
	_actualizar_tecla(key_der, "der", Input.is_action_pressed("ui_right"))
	_actualizar_tecla(key_salto, "salto", Input.is_action_pressed("saltar"))
	key_dash.modulate = Color(1.5, 1.5, 1.0) if Input.is_action_pressed("dash") else Color.WHITE
	_actualizar_transicion(_delta)


func _unhandled_input(event: InputEvent) -> void:
	var nivel := get_tree().get_first_node_in_group("nivel")
	if nivel == null:
		return
	if event.is_action_pressed("pausa"):
		if nivel.has_method("alternar_pausa"):
			nivel.call("alternar_pausa")
		return
	var terminado: bool = bool(nivel.get("terminado"))
	if event.is_action_pressed("reintentar"):
		if nivel.has_method("reintentar"):
			nivel.call("reintentar")
	elif event.is_action_pressed("menu"):
		if terminado and nivel.has_method("ir_menu"):
			nivel.call("ir_menu")
	elif event.is_action_pressed("siguiente"):
		if terminado and nivel.has_method("siguiente"):
			nivel.call("siguiente")


func _actualizar_tecla(nodo: TextureRect, cual: String, pulsada: bool) -> void:
	var tex: AtlasTexture = _tecla_puls[cual] if pulsada else _tecla_idle[cual]
	if nodo.texture != tex:
		nodo.texture = tex


func _on_temp(v: float) -> void:
	var vida := 100.0 - v
	termo_fill.texture = _fills[nivel_vida(vida) - 1]
	label_pct.text = "%d%%" % int(round(vida))
	if v >= 80.0:
		mostrar_mensaje("PELIGRO: la papa va a explotar!", BAR_ROJO)


func _on_dash(listo: bool, restante: float) -> void:
	var carga := 1.0 if listo else clampf(1.0 - restante / _dash_cooldown, 0.0, 1.0)
	dash_bar.value = carga * 100.0
	dash_bar.texture_progress = _dash_verde if listo else _dash_rojo


func _on_traje(t: String) -> void:
	label_traje.text = "Papa: " + t.capitalize()


func mostrar_mensaje(m: String, color: Color = Color.WHITE) -> void:
	label_msg.text = m
	label_msg.add_theme_color_override("font_color", color)
	_msg_timer.start(3.0)


func mostrar_bono_f7(activo: bool) -> void:
	label_bono.text = "BONO F7: -30% calor +10s (2 derrotas)" if activo else ""


## Numero del efecto: rebota en pantalla y vuela al termometro (32,64),
## sumando o restando segun el signo. Verde = positivo, rojo = negativo.
func mostrar_efecto(texto: String, bueno: bool) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.4) if bueno else Color(1.0, 0.35, 0.3))
	l.position = Vector2(590, 330)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position", Vector2(640, 290), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position", Vector2(32, 64), 0.7)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)


## Cierre circular a negro y avance de nivel (el arbol esta pausado;
## el HUD corre en ALWAYS y anima el shader).
func iniciar_transicion(duracion: float, nivel: Node) -> void:
	_trans_t = 0.0
	_trans_dur = maxf(0.2, duracion)
	_trans_nivel = nivel
	transicion.visible = true
	_poner_radio(1.5)


func _poner_radio(r: float) -> void:
	var mat := transicion.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("radio", r)


func _actualizar_transicion(delta: float) -> void:
	if _trans_t < 0.0:
		return
	_trans_t += delta
	var f := clampf(_trans_t / _trans_dur, 0.0, 1.0)
	_poner_radio(lerpf(1.5, 0.0, f))
	if f >= 1.0:
		_trans_t = -1.0
		var n := _trans_nivel
		_trans_nivel = null
		if n != null and is_instance_valid(n) and n.has_method("siguiente"):
			n.call("siguiente")
