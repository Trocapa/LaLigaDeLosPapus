class_name Trajes
extends RefCounted
## RF-07: Matriz de tipos de papa. Datos de balance usados por papa.gd.

const DATOS := {
	"rey": {
		"nombre": "Rey Papa (Base)",
		"speed": 300.0,
		"jump": -600.0,
		"heat_mult": 1.0,
		"dash_mult": 1.0,
		"inmune_pinchos": false,
		"doble_salto": false,
		"resbala": false,
		"pierde_con_agua": false,
		"color": Color(0.72, 0.53, 0.26),
	},
	"criolla": {
		"nombre": "Papa Criolla",
		"speed": 390.0, # +30%
		"jump": -600.0,
		"heat_mult": 1.5, # se quema 1.5x mas rapido
		"dash_mult": 1.6,
		"inmune_pinchos": false,
		"doble_salto": false,
		"resbala": false,
		"pierde_con_agua": false,
		"color": Color(0.95, 0.80, 0.35),
	},
	"rustica": {
		"nombre": "Papa Rustica (Piel Dura)",
		"speed": 300.0,
		"jump": -480.0, # -20% salto
		"heat_mult": 1.0,
		"dash_mult": 1.0,
		"inmune_pinchos": true,
		"doble_salto": false,
		"resbala": false,
		"pierde_con_agua": false,
		"color": Color(0.45, 0.30, 0.18),
	},
	"helada": {
		"nombre": "Papa Helada",
		"speed": 300.0,
		"jump": -600.0,
		"heat_mult": 0.5, # mitad de calor
		"dash_mult": 1.0,
		"inmune_pinchos": false,
		"doble_salto": false,
		"resbala": true, # velX *= 0.92 al frenar -> resbala
		"pierde_con_agua": false,
		"color": Color(0.60, 0.85, 1.0),
	},
	"picante": {
		"nombre": "Papa Picante / Frita",
		"speed": 340.0,
		"jump": -600.0,
		"heat_mult": 1.2,
		"dash_mult": 1.2,
		"inmune_pinchos": false,
		"doble_salto": true,
		"resbala": false,
		"pierde_con_agua": true, # si toca agua pierde el traje
		"color": Color(0.90, 0.30, 0.15),
	},
}

const BASE_HEAT_POR_SEG := 4.0 ## %/s con traje rey (25 s hasta explotar)


static func existe(t: String) -> bool:
	return DATOS.has(t)


static func obtener(t: String) -> Dictionary:
	return DATOS.get(t, DATOS["rey"])
