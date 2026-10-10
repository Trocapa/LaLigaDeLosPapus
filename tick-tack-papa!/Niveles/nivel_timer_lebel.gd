extends Label
## RF-12 (legacy): muestra cuenta regresiva del NivelTimer.

func _process(_delta: float) -> void:
	var t := get_tree().get_first_node_in_group("nivel_timer")
	if t is Timer:
		text = "Tiempo: %d" % int(ceil((t as Timer).time_left))
