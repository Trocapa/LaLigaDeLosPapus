class_name NivelBase
extends Node2D
## RF-02/RF-10/RF-14 + F7/RN-05: gestiona timer, derrota, victoria, pausa,
## reintento (R), menu (M), siguiente (N). RF-09 colisiones via nodos fisicos.

@export var nivel_num: int = 1
@export var tiempo_limite: float = 60.0
@export var siguiente_escena: String = ""
@export var limite_caida_y: float = 750.0 ## caerse mas abajo = muerte

const GAME_OVER_SCENE := "res://UI/game_over.tscn"
const PAUSA_SCENE := "res://UI/pausa.tscn"

var tiempo_restante: float = 60.0
var terminado: bool = false
var timer: Timer
var papa: Node
var pausa_panel: Control = null


func _ready() -> void:
	add_to_group("nivel")
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.set("nivel_actual", nivel_num)
		if gs.has_method("tiene_bono") and bool(gs.call("tiene_bono", nivel_num)):
			tiempo_limite += float(gs.get("BONO_TIEMPO_EXTRA"))
	tiempo_restante = tiempo_limite
	# Timer de nivel (RF-02/F4): reutiliza el nodo "NivelTimer" de la escena
	# si existe (visible y editable), si no lo crea por codigo.
	timer = get_node_or_null("NivelTimer") as Timer
	if timer == null:
		timer = Timer.new()
		timer.name = "NivelTimer"
		add_child(timer)
	timer.wait_time = tiempo_limite
	timer.one_shot = true
	timer.autostart = false
	timer.add_to_group("nivel_timer")
	if not timer.timeout.is_connected(_on_timeout):
		timer.timeout.connect(_on_timeout)
	timer.start(tiempo_limite)
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


func _process(_delta: float) -> void:
	if terminado or get_tree().paused:
		return
	if timer != null:
		tiempo_restante = timer.time_left
	# Caerse del mundo tambien mata y reinicia.
	if papa != null and papa is Node2D and bool(papa.get("viva")):
		if (papa as Node2D).global_position.y > limite_caida_y:
			papa.call("explotar", "Caida al vacio")
			return


func _on_timeout() -> void:
	if terminado:
		return
	# Al acabarse el tiempo tambien explotamos (con particulas + asset).
	if papa != null and bool(papa.get("viva")) and papa.has_method("explotar"):
		papa.call("explotar", "Tiempo agotado (F4)")
	else:
		_derrota("Tiempo agotado (F4)")


func _on_papa_muerta(causa: String) -> void:
	if terminado:
		return
	_derrota(causa)


func _derrota(causa: String) -> void:
	terminado = true
	get_tree().paused = false
	_cerrar_pausa()
	get_tree().call_group("musica_nivel", "stop")
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
	_mostrar_game_over("GAME OVER - Explotaste", causa + extra)
	if hud != null and hud.has_method("mostrar_mensaje"):
		hud.call("mostrar_mensaje", "Derrota: " + causa, Color(1.0, 0.35, 0.3))


func _mostrar_game_over(titulo: String, detalle: String) -> void:
	if not ResourceLoader.exists(GAME_OVER_SCENE):
		return
	var go := (load(GAME_OVER_SCENE) as PackedScene).instantiate()
	# Bajo el CanvasLayer del HUD: un Control bajo Node2D queda en tamano (0,0).
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		hud.add_child(go)
	else:
		add_child(go)
	if go.has_method("mostrar"):
		go.call("mostrar", titulo, detalle)


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
		hud.call("mostrar_mensaje", "NIVEL COMPLETADO!", Color(0.4, 1.0, 0.4))
	Sfx.suena(self, "CambiarLevel.mp3")
	get_tree().call_group("musica_nivel", "stop")
	if siguiente_escena != "" and ResourceLoader.exists(siguiente_escena):
		# Pausa breve + cierre circular a negro (lo anima el HUD en ALWAYS).
		get_tree().paused = true
		if hud != null and hud.has_method("iniciar_transicion"):
			hud.call("iniciar_transicion", 0.9, self)
		else:
			siguiente()
	else:
		_mostrar_game_over("NIVEL COMPLETADO!", "Temperatura 0%. Fuente alcanzada.")


func agregar_tiempo(s: float) -> void:
	if timer != null and not terminado:
		timer.start(maxf(0.5, timer.time_left + s))


func reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func ir_menu() -> void:
	get_tree().paused = false
	if ResourceLoader.exists("res://UI/menu_principal.tscn"):
		get_tree().change_scene_to_file("res://UI/menu_principal.tscn")
	else:
		get_tree().reload_current_scene()


func siguiente() -> void:
	get_tree().paused = false
	if siguiente_escena != "" and ResourceLoader.exists(siguiente_escena):
		get_tree().change_scene_to_file(siguiente_escena)
	else:
		get_tree().reload_current_scene()


## RF-10: pausa con menu propio (UI/pausa.tscn). La musica del nivel se
## congela y suena la de pausa.
func alternar_pausa() -> void:
	if terminado:
		return
	if get_tree().paused:
		get_tree().paused = false
		Sfx.suena(self, "SFX_UI_Resume.mp3")
		get_tree().call_group("musica_nivel", "set_stream_paused", false)
		_cerrar_pausa()
	else:
		get_tree().paused = true
		Sfx.suena(self, "SFX_UI_Pause.mp3")
		get_tree().call_group("musica_nivel", "set_stream_paused", true)
		if pausa_panel == null and ResourceLoader.exists(PAUSA_SCENE):
			pausa_panel = ((load(PAUSA_SCENE) as PackedScene).instantiate() as Control)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null:
				hud.add_child(pausa_panel)
			else:
				add_child(pausa_panel)
		var hud2 := get_tree().get_first_node_in_group("hud")
		if hud2 != null and hud2.has_method("mostrar_mensaje"):
			hud2.call("mostrar_mensaje", "PAUSA")


func _cerrar_pausa() -> void:
	if pausa_panel != null and is_instance_valid(pausa_panel):
		pausa_panel.queue_free()
	pausa_panel = null
