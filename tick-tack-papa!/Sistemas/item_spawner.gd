class_name ItemSpawner
extends Node2D
## RF-15 + RN-06: spawner con tabla ponderada que escala por nivel (1-5).
## Nivel 1: 100% ventajas fijas. N2: 80/20. N3: introduce ? y carbon.
## N4: spawners dinamicos con mas aji. N5: escasez de botella.

const ITEM_SCRIPT := preload("res://Sistemas/item.gd")

@export var nivel: int = 1
@export var intervalo: float = 6.0
@export var radio_spawn: float = 200.0
@export var activo: bool = true

var _t: float = 0.0


func _ready() -> void:
	add_to_group("spawner")


func _process(delta: float) -> void:
	if not activo:
		return
	# Solo niveles 4-5 usan respawn dinamico continuo (RN-06)
	if nivel < 4:
		return
	_t += delta
	if _t >= intervalo:
		_t = 0.0
		spawn_aleatorio()


func tabla_pesos() -> Dictionary:
	match nivel:
		1:
			return {"botella": 50.0, "aceite": 50.0}
		2:
			return {"botella": 40.0, "aceite": 25.0, "mantequilla": 15.0, "sal": 20.0}
		3:
			return {"botella": 25.0, "aceite": 20.0, "mantequilla": 10.0, "carbon": 20.0, "misterioso": 15.0, "sal": 10.0}
		4:
			return {"botella": 15.0, "aceite": 20.0, "mantequilla": 15.0, "carbon": 15.0, "aji": 20.0, "misterioso": 10.0, "sal": 5.0}
		_:
			return {"botella": 8.0, "aceite": 12.0, "mantequilla": 10.0, "carbon": 25.0, "aji": 25.0, "misterioso": 10.0, "sal": 10.0}


func elegir_tipo() -> String:
	var tabla := tabla_pesos()
	var total := 0.0
	for k in tabla:
		total += float(tabla[k])
	var r := randf() * total
	var acc := 0.0
	for k in tabla:
		acc += float(tabla[k])
		if r <= acc:
			return str(k)
	return "botella"


func spawn_aleatorio() -> Node:
	var tipo := elegir_tipo()
	return spawn_tipo(tipo, Vector2(randf_range(-radio_spawn, radio_spawn), randf_range(-80.0, 0.0)))


func spawn_tipo(tipo: String, offset: Vector2) -> Node:
	var item: Area2D = ITEM_SCRIPT.new()
	item.set("tipo", tipo)
	item.position = position + offset
	get_parent().call_deferred("add_child", item)
	return item


## Items fijos deterministas para diseno de niveles (RF-15 modalidad fija)
func spawn_fijo(tipo: String, pos_global: Vector2) -> Node:
	var item: Area2D = ITEM_SCRIPT.new()
	item.set("tipo", tipo)
	get_parent().call_deferred("add_child", item)
	item.set_deferred("global_position", pos_global)
	return item
