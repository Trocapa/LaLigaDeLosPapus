# AI_TRACE.md — Auditoría y trazabilidad (RNF-05)
Todo cambio de lógica o arquitectura queda registrado aquí.

## 2026-10-10 — Implementación completa F1-F7 / RF-01..RF-15
- `Sistemas/game_state.gd` (autoload GameState): derrotas por nivel, bono F7
  (heat x0.7 + 10s si >=2 derrotas, RN-05), traje persistente, RF-10.
- `Sistemas/trajes.gd`: matriz RF-07 (rey/criolla/rustica/helada/picante)
  con speed/jump/heat_mult/dash_mult/inmunidad/doble-salto/resbala.
- `papa.gd` reescrito: RF-01 subida 4%/s base, RF-02 explota al 100%,
  RF-03 agua -30% + RN-03 limpia debuffs, RF-04 A/D+Espacio+Shift,
  RF-05 catálogo (hielo -20%+freeze 3s, aceite +5s, mantequilla +30% vel/dash x2 4s,
  carbón +20%, ají impulso+2x calor 5s, sal -25% salto 3s, misterioso 50/50),
  RF-07/08 cambio y pérdida de traje, RF-09 AABB via CharacterBody2D/Area2D,
  dash con cooldown 1s + estado para HUD (RF-12).
- `Sistemas/agua.gd`: RF-03/RF-08/RF-14 (enfría, quita traje, meta completa nivel).
- `Sistemas/item.gd`: RN-02 consumo único, colores por tipo, mensaje a HUD.
- `Sistemas/item_spawner.gd`: RF-15 + RN-06 tabla ponderada N1..N5,
  spawn fijo y dinámico (N4-N5).
- `Sistemas/cartel.gd`: RF-13 + RN-04 (muestra 4s al entrar, oculta al salir).
- `Sistemas/pinchos.gd`: RF-09 trampas leves (+15%) y mortales; rústica inmune a leves.
- `Sistemas/hud.gd`: RF-12 termómetro/timer/traje/dash + mensajes + panel fin RF-10.
- `Sistemas/nivel_base.gd`: RF-02 timeout=F4 derrota, RF-14 meta resetea 0% y frena
  timer, RF-10 pausa (Esc/P), R reintenta, M menú, N siguiente; F7 aplica bono.
- `Niveles/nivel_1.gd` + `Nivel1.tscn`: tutorial RN-06 N1 (solo hielo/aceite fijos),
  carteles RF-13, agua intermedia + meta verde, plataformas AABB, HUD instanciado.
- `Niveles/nivel_2.gd` + `Nivel2.tscn`: demo RN-06 N2 (80/20 + sal + pinchos leves).
- `UI/menu_principal.tscn/.gd`: RF-10 menú jugar N1/N2.
- `project.godot`: autoload GameState, main_scene=menú, inputs dash/reintentar(R)/
  pausa(Esc/P)/menu(M)/siguiente(N), viewport 1280x720.
- `papa.tscn`: colisión 48x48 (criolla escala visual menor), DashTimer one_shot,
  cámara con smoothing.
- Verificación: `demo.py` simula temperatura/items/timer/F7/spawner sin motor.
- Verificación Godot 4.7.2 headless 2026-10-10: los 14 .gd pasan --check-only
  sin errores; Nivel1 (180 frames), Nivel2 (120) y menú (60) corren sin errores.

## 2026-10-10 — Particulas, tinte por calor y escenas colocables
- `papa.tscn`: nodo `ExplosionParticles` (CPUParticles2D, 48 particulas,
  gradiente amarillo->naranja->humo, one_shot). `papa.gd:_explotar()` oculta
  el sprite y hace `restart()` de las particulas.
- `papa.gd`: tinte progresivo `_actualizar_tinte()` — `modulate =
  color_traje.lerp(rojo, temp/100 * 0.55)`. A 100% solo 55% rojo para que el
  disfraz siga viendose. Se actualiza al calentarse, enfriarse y cambiar traje.
- `Items/`: 13 escenas arrastrables al nivel (sin codigo que las auto-coloque):
  ItemHielo/Aceite/Mantequilla/Carbon/Aji/Sal/Misterioso, TrajeCriolla/Rustica/
  Helada/Picante, AguaMeta (verde, completa el nivel RF-14) y AguaCharco
  (azul, solo quita -30% calor).
- `Niveles/nivel_1.gd` y `nivel_2.gd`: ya no colocan items ni agua por codigo
  (solo carteles y, en N2, pinchos leves). La meta va instanciada en los .tscn
  y se puede mover/borrar en el editor.

## 2026-10-10 — Escenas con nodos, controles, rampa de color y avance automatico
- `Items/*.tscn` (13) y `papa.tscn`: ahora traen nodos reales (Sprite2D con
  logo de Godot tenhido por tipo + CollisionShape2D + Label). `item.gd` y
  `agua.gd` solo crean hijos por codigo si faltan: tus colisiones editadas no
  se pisan. Particulas de explosion usan el logo como textura.
- Controles (RF-04): `saltar` = FLECHA ARRIBA/W, `dash` = ESPACIO (ya no Shift;
  se quito ui_accept del salto). Carteles, menu y HUD actualizados.
- Rampa termica: papa `color_traje -> amarillo (50%) -> rojo (100%, mezcla
  60%)`; barra del HUD verde->amarillo->rojo (`hud.gd:color_por_temp`).
- Salto base -400 -> -550 (rustica -320 -> -440) para alcanzar plataformas.
- Cartel sin poste cafe: panel oscuro flotante + rombo gris de referencia.
- Menu por nodos (`menu_principal.tscn` centrado con CenterContainer, solo
  boton JUGAR); `menu_principal.gd` solo conecta la senhal.
- `NivelBase.completar_nivel()`: al tocar la meta avanza solo al siguiente
  nivel a los 1.5 s (timer hijo, seguro ante reintento).
- Demo: 30 checks (tinte en 0/50/100% + rampa de la barra).
