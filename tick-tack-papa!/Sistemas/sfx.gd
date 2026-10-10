class_name Sfx
extends RefCounted
## Reproduce un SFX de assets/Sounds/SFX/ segun su nombre:
## Jump9 (saltos), Explosion3 (explosion), SFX_Item (recoger item),
## SFX_UI_Pause / SFX_UI_Resume (pausa), CambiarLevel (cambiar de nivel/menu).

const RUTA := "res://assets/Sounds/SFX/"


static func suena(origen: Node, archivo: String, vol_db: float = 0.0) -> void:
	if origen == null:
		return
	var stream := load(RUTA + archivo) as AudioStream
	if stream == null:
		return
	var arbol := origen.get_tree()
	if arbol == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = vol_db
	p.finished.connect(p.queue_free)
	arbol.root.add_child(p)
	p.play()
