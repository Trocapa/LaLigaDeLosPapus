extends Node
## Autoload GameState: estado global, derrotas por nivel (F7/RN-05),
## traje persistente entre niveles y control de pausa (RF-10).

var derrotas_por_nivel: Dictionary = {}
var nivel_actual: int = 1
var traje_actual: String = "rey"
var juego_pausado: bool = false

const BONO_DERROTAS := 2 ## RN-05: con 2+ derrotas seguidas se activa compensacion
const BONO_HEAT_MULT := 0.7 ## F7: la papa se calienta 30% mas lento
const BONO_TIEMPO_EXTRA := 10.0 ## F7: +10s al limite del nivel


func registrar_derrota(nivel: int) -> void:
	derrotas_por_nivel[nivel] = int(derrotas_por_nivel.get(nivel, 0)) + 1


func registrar_victoria(nivel: int) -> void:
	derrotas_por_nivel[nivel] = 0
	nivel_actual = nivel + 1


func tiene_bono(nivel: int) -> bool:
	return int(derrotas_por_nivel.get(nivel, 0)) >= BONO_DERROTAS


func heat_mult_bono(nivel: int) -> float:
	return BONO_HEAT_MULT if tiene_bono(nivel) else 1.0


func set_traje(t: String) -> void:
	traje_actual = t


func reset() -> void:
	derrotas_por_nivel.clear()
	nivel_actual = 1
	traje_actual = "rey"
	juego_pausado = false
