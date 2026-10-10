class_name NivelBase
extends Node2D
## RF-02/RF-10/RF-14 + F7/RN-05: gestiona timer, derrota, victoria, pausa,
## reintento (R), menu (M), siguiente (N). RF-09 colisiones via nodos fisicos.

@export var nivel_num: int = 1
@export var tiempo_limite: float = 60.0
@export var siguiente_escena: String = ""

var tiempo_restante: float = 60.0
var terminado: bool = false
var timer: Timer
var papa: Node


func _ready() -> void:
	add_to_group("nivel")
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.set("nivel_actual", nivel_num)
		if gs.has_method("tiene_bono") and bool(gs.call("tiene_bono", nivel_num)):
			tiempo_limite += float(gs.get("BONO_TIEMPO_EXTRA"))
	tiempo_restante = tiempo_limite
	# Timer de nivel (RF-02/F4)
	timer = Timer.new()
	timer.name = "NivelTimer"
	timer.wait_time = tiempo_limite
	timer.one_shot = true
	timer.autostart = false
	add_to_group("nivel_timer")
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	timer.start(tiempo_limite)
	# Registrar en grupo para HUD (el HUD busca "nivel_timer")
	timer.add_to_group("nivel_timer")
	await get_tree().process_frame
	papa = get_tree().get_first_node_in_group("papa")
	if papa != null:
		if papa.has_signal("murio"):
			papa.connect("murio", _on_papa_muerta)
		if papa.has_method("set"):
			papa.set("nivel_num", nivel_num)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_bono_f7") and gs != null:
		hud.call("mostrar_bono_f7", bool(gs.call("tiene_bono", nivel_num)))
	set_process(true)


func _process(delta: float) -> void:
	if terminado:
		return
	if timer != null:
		tiempo_restante = timer.time_left
	# RF-10: pausa / reintento
	if Input.is_action_just_pressed("pausa"):
		_alternar_pausa()
	if Input.is_action_just_pressed("reintentar"):
		_reintentar()


func _unhandled_input(event: InputEvent) -> void:
	if not terminado:
		return
	if event.is_action_pressed("reintentar"):
		_reintentar()
	elif event.is_action_pressed("menu"):
		_ir_menu()
	elif event.is_action_pressed("siguiente"):
		_siguiente()


func _on_timeout() -> void:
	if terminado:
		return
	_derrota("Tiempo agotado (F4)")


func _on_papa_muerta(causa: String) -> void:
	if terminado:
		return
	_derrota(causa)


func _derrota(causa: String) -> void:
	terminado = true
	get_tree().paused = false
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("registrar_derrota"):
		gs.call("registrar_derrota", nivel_num)
	var hud := get_tree().get_first_node_in_group("hud")
	var n_der := 0
	if gs != null:
		n_der = int((gs.get("derrotas_por_nivel") as Dictionary).get(nivel_num, 1))
	var extra := ""
	if n_der >= 1:
		extra = " (derrota %d - bono F7 con 2)" % n_der
	if hud != null and hud.has_method("mostrar_fin"):
		hud.call("mostrar_fin", "GAME OVER - Explotaste", causa + extra + "\n[R] reintentar  [M] menu")
		if hud.has_method("mostrar_mensaje"):
			hud.call("mostrar_mensaje", "Derrota: " + causa)


func completar_nivel() -> void:
	if terminado:
		return
	terminado = true
	if papa != null and papa.get("temperatura") != null:
		papa.set("temperatura", 0.0) # RF-14: resetea a 0%
	if timer != null:
		timer.stop() # RF-14: detiene el tiempo
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("registrar_victoria"):
		gs.call("registrar_victoria", nivel_num)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_mensaje"):
		hud.call("mostrar_mensaje", "NIVEL COMPLETADO! Al siguiente...")
	if siguiente_escena != "" and ResourceLoader.exists(siguiente_escena):
		# Avance automatico a los 1.5 s (timer hijo: si reintentas antes, muere con el nivel)
		var adv := Timer.new()
		adv.one_shot = true
		adv.wait_time = 1.5
		add_child(adv)
		adv.timeout.connect(_siguiente)
		adv.start()
	elif hud != null and hud.has_method("mostrar_fin"):
		hud.call("mostrar_fin", "NIVEL COMPLETADO!", "Temperatura 0%. Fuente alcanzada.")


func agregar_tiempo(s: float) -> void:
	if timer != null and not terminado:
		timer.start(maxf(0.5, timer.time_left + s))


func _reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _ir_menu() -> void:
	get_tree().paused = false
	if ResourceLoader.exists("res://UI/menu_principal.tscn"):
		get_tree().change_scene_to_file("res://UI/menu_principal.tscn")
	else:
		get_tree().reload_current_scene()


func _siguiente() -> void:
	get_tree().paused = false
	if siguiente_escena != "" and ResourceLoader.exists(siguiente_escena):
		get_tree().change_scene_to_file(siguiente_escena)
	else:
		get_tree().reload_current_scene()


func _alternar_pausa() -> void:
	get_tree().paused = not get_tree().paused
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_mensaje"):
		hud.call("mostrar_mensaje", "PAUSA" if get_tree().paused else "CONTINUA")
