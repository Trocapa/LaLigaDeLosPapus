class_name Papa
extends CharacterBody2D
## RF-01/02/03/04/05/06/07/08/09: jugador papa caliente.
## RF-01: temperatura sube sola. RF-02/F1: explota al 100%. RF-03/F2: agua -30%.
## RF-04: A/D + Espacio + Shift dash. RF-05: items. F7: bono via GameState.

signal temperatura_changed(valor: float)
signal murio(causa: String)
signal dash_changed(listo: bool, cooldown_restante: float)
signal traje_changed(traje: String)
signal enfriado(nueva_temp: float)

const TRAJES_SCRIPT := preload("res://Sistemas/trajes.gd")

# Movimiento base (RF-04): A/D moverse, saltar con FLECHA ARRIBA/W, dash con ESPACIO

@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0
@export var nivel_num: int = 1

var temperatura: float = 0.0
var viva: bool = true
var traje: String = "rey"

var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var last_facing_dir: float = 1.0
var dash_cooldown_restante: float = 0.0

var butter_restante: float = 0.0
var chili_restante: float = 0.0
var sal_restante: float = 0.0
var controles_invertidos_restante: float = 0.0
var saltos_extra: int = 0

@onready var dash_timer: Timer = $DashTimer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles

var _cooldown_timer: Timer
var _efecto_tick: float = 0.0

# Tinte por calor (visual): verde del traje -> amarillo -> rojo con la
# temperatura. La mezcla con rojo llega al 60% para que el disfraz se siga notando.
const TINTE_AMARILLO := Color(1.0, 0.85, 0.15)
const TINTE_ROJO := Color(1.0, 0.12, 0.08)
const TINTE_AMARILLO_MAX := 0.5
const TINTE_ROJO_MAX := 0.6
var _color_base: Color = Color.WHITE


func _ready() -> void:
	add_to_group("papa")
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = dash_cooldown
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		var t: String = str(gs.get("traje_actual"))
		if TRAJES_SCRIPT.existe(t):
			traje = t
	_aplicar_color_traje()
	traje_changed.emit(traje)
	anim.play("caminar")


func stats() -> Dictionary:
	return TRAJES_SCRIPT.obtener(traje)


func velocidad_actual() -> float:
	var s: float = float(stats()["speed"])
	if butter_restante > 0.0:
		s *= 1.3
	return s


func salto_actual() -> float:
	var j: float = float(stats()["jump"])
	if sal_restante > 0.0:
		j *= 0.75
	return j


func heat_por_seg() -> float:
	var m: float = float(stats()["heat_mult"])
	if chili_restante > 0.0:
		m *= 2.0
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("heat_mult_bono"):
		m *= float(gs.call("heat_mult_bono", nivel_num))
	return TRAJES_SCRIPT.BASE_HEAT_POR_SEG * m


func _physics_process(delta: float) -> void:
	if not viva:
		return
	_actualizar_efectos(delta)
	_actualizar_temperatura(delta)
	if temperatura >= 100.0:
		_explotar("Sobrecalentamiento al 100% (F1)")
		return
	var direction := Input.get_axis("ui_left", "ui_right")
	if controles_invertidos_restante > 0.0:
		direction = -direction
	if direction != 0.0:
		last_facing_dir = sign(direction)
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_restante <= 0.0:
		start_dash(direction)
	if is_dashing:
		velocity = dash_direction * dash_speed * _dash_mult()
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			saltos_extra = 1 if bool(stats()["doble_salto"]) else 0
		if Input.is_action_just_pressed("saltar"):
			if is_on_floor():
				velocity.y = salto_actual()
			elif bool(stats()["doble_salto"]) and saltos_extra > 0:
				saltos_extra -= 1
				velocity.y = salto_actual()
		if direction != 0.0:
			var target := direction * velocidad_actual()
			if bool(stats()["resbala"]):
				velocity.x = lerp(velocity.x, target, 1.0 - pow(0.02, delta))
			else:
				velocity.x = target
		else:
			if bool(stats()["resbala"]) and is_on_floor():
				velocity.x *= 0.92
				if abs(velocity.x) < 5.0:
					velocity.x = 0.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, velocidad_actual())
	_actualizar_animacion(direction)
	move_and_slide()


## Sprite 4 de la tira = salto; resto = caminar.
func _actualizar_animacion(direction: float) -> void:
	if anim == null:
		return
	if not is_on_floor():
		if anim.animation != "saltar":
			anim.play("saltar")
	elif direction != 0.0 or abs(velocity.x) > 20.0:
		if anim.animation != "caminar" or not anim.is_playing():
			anim.play("caminar")
		anim.flip_h = last_facing_dir < 0.0
	else:
		anim.stop()
		anim.frame = 0


func _actualizar_temperatura(delta: float) -> void:
	temperatura = clampf(temperatura + heat_por_seg() * delta, 0.0, 100.0)
	_actualizar_tinte()
	_efecto_tick += delta
	if _efecto_tick >= 0.1:
		_efecto_tick = 0.0
		temperatura_changed.emit(temperatura)


func _actualizar_efectos(delta: float) -> void:
	butter_restante = maxf(0.0, butter_restante - delta)
	chili_restante = maxf(0.0, chili_restante - delta)
	sal_restante = maxf(0.0, sal_restante - delta)
	controles_invertidos_restante = maxf(0.0, controles_invertidos_restante - delta)
	if dash_cooldown_restante > 0.0:
		dash_cooldown_restante = maxf(0.0, dash_cooldown_restante - delta)
		dash_changed.emit(dash_cooldown_restante <= 0.0, dash_cooldown_restante)


func _dash_mult() -> float:
	var m: float = float(stats()["dash_mult"])
	if butter_restante > 0.0:
		m *= 2.0
	return m


func start_dash(input_dir: float) -> void:
	is_dashing = true
	var move_dir := input_dir if input_dir != 0.0 else last_facing_dir
	dash_direction = Vector2(move_dir, 0.0).normalized()
	var dur := dash_duration
	if butter_restante > 0.0:
		dur *= 2.0
	dash_timer.start(dur)
	dash_cooldown_restante = dash_cooldown
	_cooldown_timer.start(dash_cooldown)
	dash_changed.emit(false, dash_cooldown_restante)


func _on_dash_timer_timeout() -> void:
	is_dashing = false


func _on_cooldown_timeout() -> void:
	dash_cooldown_restante = 0.0
	dash_changed.emit(true, 0.0)


func tocar_agua(es_meta: bool, es_transicion: bool) -> void:
	if not viva:
		return
	enfriar(30.0)
	limpiar_debuffs()
	if bool(stats()["pierde_con_agua"]) or (es_transicion and traje != "rey"):
		cambiar_traje("rey")


func enfriar(cantidad: float) -> void:
	temperatura = clampf(temperatura - cantidad, 0.0, 100.0)
	_actualizar_tinte()
	temperatura_changed.emit(temperatura)
	enfriado.emit(temperatura)


func limpiar_debuffs() -> void:
	chili_restante = 0.0
	sal_restante = 0.0
	controles_invertidos_restante = 0.0


func aplicar_item(tipo: String) -> String:
	match tipo:
		"botella":
			enfriar(20.0)
			return "Botella de Agua: -20% calor"
		"aceite":
			var nb := get_parent()
			if nb != null and nb.has_method("agregar_tiempo"):
				nb.call("agregar_tiempo", 5.0)
			return "Aceite Dorado: +5s"
		"mantequilla":
			butter_restante = 4.0
			return "Mantequilla: +30% vel y dash x2 (4s)"
		"carbon":
			temperatura = clampf(temperatura + 20.0, 0.0, 100.0)
			temperatura_changed.emit(temperatura)
			if temperatura >= 100.0:
				_explotar("Carbon incandescente (+20%)")
			return "Carbon: +20% calor"
		"aji":
			chili_restante = 5.0
			velocity.x += last_facing_dir * 250.0
			return "Aji: impulso pero 2x calor 5s"
		"sal":
			sal_restante = 3.0
			return "Sal: -25% salto 3s"
		"misterioso":
			if randf() < 0.5:
				temperatura = 0.0
				limpiar_debuffs()
				temperatura_changed.emit(temperatura)
				return "Frasco misterioso: ENFRIAMIENTO TOTAL!"
			else:
				temperatura = 80.0
				controles_invertidos_restante = 5.0
				temperatura_changed.emit(temperatura)
				return "Frasco misterioso: 80% calor + controles invertidos!"
		"traje_criolla", "traje_rustica", "traje_helada", "traje_picante":
			cambiar_traje(tipo.trim_prefix("traje_"))
			return "Transformacion: " + str(stats()["nombre"])
	return "Item desconocido"


func cambiar_traje(nuevo: String) -> void:
	if not TRAJES_SCRIPT.existe(nuevo):
		return
	traje = nuevo
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.set("traje_actual", nuevo)
	if anim != null:
		if traje == "criolla":
			anim.scale = Vector2(0.23, 0.23)
		else:
			anim.scale = Vector2(0.32, 0.32)
	_aplicar_color_traje()
	traje_changed.emit(traje)


func _aplicar_color_traje() -> void:
	_color_base = TRAJES_SCRIPT.obtener(traje).get("color", Color.WHITE)
	_actualizar_tinte()


## 0% = color del traje, 50% = amarillento, 100% = rojo (sin tapar el disfraz).
func _actualizar_tinte() -> void:
	if anim == null:
		return
	var f := clampf(temperatura / 100.0, 0.0, 1.0)
	if f <= 0.5:
		anim.modulate = _color_base.lerp(TINTE_AMARILLO, (f * 2.0) * TINTE_AMARILLO_MAX)
	else:
		var medio := _color_base.lerp(TINTE_AMARILLO, TINTE_AMARILLO_MAX)
		anim.modulate = medio.lerp(TINTE_ROJO, (f - 0.5) * 2.0 * TINTE_ROJO_MAX)


func pincho_tocado(mortal: bool) -> void:
	if not viva:
		return
	if bool(stats()["inmune_pinchos"]) and not mortal:
		return
	if mortal:
		_explotar("Trampa mortal")
	else:
		temperatura = clampf(temperatura + 15.0, 0.0, 100.0)
		temperatura_changed.emit(temperatura)
		if temperatura >= 100.0:
			_explotar("Pinchos (+15%) -> 100%")


func _explotar(causa: String) -> void:
	if not viva:
		return
	viva = false
	velocity = Vector2.ZERO
	# Explosion visual: oculta la papa y lanza particulas de pure
	if anim != null:
		anim.visible = false
	if explosion_particles != null:
		explosion_particles.restart()
	murio.emit(causa)
