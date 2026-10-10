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

## 2026-10-10 — Assets PNG: animacion, items, tilemap y termometro
- `papa.tscn`: Sprite2D -> AnimatedSprite2D con SpriteFrames de
  `assets/papaAnimation.png` (8 frames de 216x274): `caminar` = frames
  1,2,3,5,6,7,8 a 8 fps en loop, `saltar` = sprite 4. `papa.gd` elige
  animacion (aire=saltar, moviendose=caminar, quieto=frame 0) y voltea
  con flip_h. Escala 0.32 (criolla 0.23). Colision del editor intacta.
- `Items/ItemBotella.tscn` (nuevo, botella azul -20% calor, reemplaza al
  hielo): se borro `ItemHielo.tscn` y el tipo `hielo` del codigo/tablas/demo.
  `Items/AguaMeta.tscn` ahora usa el charco del PNG (meta del nivel).
  `Items/AguaCharco.tscn` borrada (la botella es el item que refresca).
  Resto de items con su arte del PNG (AtlasTexture por bbox medida).
  `item.gd` ya no pisa modulate ni crea etiquetas.
- `assets/TerrenoTileset.tres` generado por `tools/build_tileset.gd`
  (144 tiles, 108 con colision cuadrada; filas parciales sin colision).
  `tools/build_niveles.gd` reconstruye Nivel1/Nivel2 con TileMapLayer
  (suelo pasto/tierra + plataformas grises) en vez de plataformas
  provisionales. Prueba fisica headless: cuerpo cae y reposa en y=518.3
  (techo del suelo y=528). Meta reubicada a y=290 (alcanzable).
- `hud.gd`: ProgressBar -> termometro del `assets/Healthbars.png` (marco
  azul + columna de mercurio con rampa verde->amarillo->rojo) y % a la derecha.
- `project.godot`: filtro de texturas canvas a Nearest (pixel-art nitido).

## 2026-10-10 — Game over escena, timer visible, vida 5 niveles, teclas, caida, explosion y musica
- `UI/game_over.tscn` + `game_over.gd`: menu de derrota/victoria por nodos
  (Titulo/Detalle/Ayuda editables); `nivel_base` la instancia y llama a
  `mostrar()`. Se elimino el panel construido por codigo del HUD.
- Timer por nivel: nodo `NivelTimer` real en Nivel1 (90 s) y Nivel2 (75 s),
  reutilizado por `NivelBase` (aplica tiempo y bono F7). Al acabarse llama a
  `papa.explotar("Tiempo agotado (F4)")` (antes solo panel): explota con
  particulas + asset. `_explotar` paso a publica `explotar`.
- Barra de vida: termometro con 5 rellenos de Healthbars.png por quintiles de
  VIDA (100-temp): 5 lleno-verde … 1 punta-roja; % muestra vida restante.
  Nodos del HUD en `UI/hud.tscn` (TermoFrame/Fill, Pct, Tiempo, Traje, Dash,
  Bono, Msg, Teclas) instanciada por el generador de niveles.
- Teclas `kb_light_symbols` (flechas filas 12-15, normal col 4 / pulsada col 5)
  abajo-izquierda con su accion; ESPACIO como keycap de texto. Se iluminan con
  Input (ui_left/ui_right/saltar/dash).
- Efectos en rojo (carbon, aji, sal, misterioso malo) o verde (botella, aceite,
  mantequilla, trajes, misterioso bueno) via `mostrar_mensaje(msg, color)`.
- Caida: `limite_caida_y = 700` en NivelBase; al pasar explota y reinicia.
- Explosion: `ExplosionSprite` (AnimatedSprite2D, 5 frames de explosion.png
  32px a 10 fps, escala 2.5) ademas de las particulas.
- Musica: menu `(main) Cozy Game Over`, N1 `(1 Level) Cave Pulse`,
  N2 `(2 Level) Frozen Cavern Arpeggios` (AudioStreamPlayer autoplay).
- Demo: 34 checks (+vida 5 niveles, timeout y caida con causa).

## 2026-10-10 — Game over visible, pausa, botones, dust, dash radial, tinte y musica
- BUG pantalla de muerte: el panel bajo Node2D quedaba en tamano (0,0)
  (probado con sonda: size=(0,0)). Ahora game over y pausa se agregan bajo el
  CanvasLayer del HUD (sonda: size=viewport, visible). `build_niveles.gd`
  marcado NO EJECUTAR: los niveles solo se tocan con edicion quirurgica.
- Carteles: fuera los rombos grises (pinchos se conservan).
- `Restart.png` movido de Sounds/ a assets/ y usado como icono de reset.
- Menu JUGAR con icono Play.png; game over y pausa con botones Reset/Back
  (iconos + R/M/Esc/ clic). Pausa es escena propia `UI/pausa.tscn` con musica.
- `papa.tscn`: PolvoPasos (Dust Particle al caminar en suelo) y
  DashParticulas (estela cyan en dash), controlados en `_actualizar_animacion`.
- Tinte: color original hasta 35% y de ahi a rojo (mezcla max 60%).
- Musica: N1 <- track 2, N2 <- track 3, game over <- track 1 (Cave Pulse),
  pausa <- track 4 (Frozen Cavern); nodos renombrados MusicaNivel1/2,
  MusicaGameOver/MusicaPausa + grupo musica_nivel (parar/congelar al morir/pausar).
- Teclas: flecha arriba centrada sobre izq/der; ESPACIO rectangular (140px)
  debajo; HUD en modo ALWAYS y maneja pausa/R/M/N (el nivel ya no, para poder
  despausar con Esc).
- Dash radial abajo-centro (TextureProgressBar, circulo blanco de Healthbars
  tenhido en codigo: fondo oscuro, rojo cargando, verde listo) + caption DASH.
- Items: levitacion sinusoidal + destellos CPUParticles2D de su color.
- Demo: 36 checks (+tinte por tramos y carga de dash).

## 2026-10-10 — Tinte original, run/idle, splash, parallax N1-N5, SFX y renombres
- REGLA: niveles N1/N2 solo con edicion quirurgica (verificado tras cada paso);
  `build_niveles.gd` marcado NO EJECUTAR. N3-N5 generados con script nuevo.
- Tinte: arranca en blanco puro (color original, sin filtros) y de 35% a rojo
  (mezcla 60%). Demo actualizada.
- `papa_run.png` (7 frames 32px) reemplaza caminar; `papa_rey_idle.png`
  (10 frames) nueva anim `quieto`; salto sigue sprite 4 de papaAnimation.
  Escalas por anim (caminar 1.6, quieto 1.15, saltar 0.3, criolla x0.72).
- Polvo de pasos mas grande (0.6-1.1).
- `Items/AguaMeta.tscn`: sprite `agua_splash.png` (8 frames 152px, calma=
  frame 0, splash una vez a 12 fps); `agua.gd` lo ejecuta solo si vy > 150.
- Marco del dash: Panel con StyleBox hueco sobre la barra radial.
- Niveles 3/4/5 nuevos (noche, bosque completo, cielo; timers 75/70/60;
  musicas introduccion/level4/level5) + parallax por nivel (N1 forest sin
  short/long, N2 desert, N3 night, N4 forest full, N5 skies; capas con
  motion_scale y scroll solo horizontal). N2 ahora lleva a N3.
- Transicion: pausa breve + cierre circular a negro (shader en HUD, 0.9 s en
  vez de 1.5 s); `hud.iniciar_transicion()`.
- SFX (`Sistemas/sfx.gd` + cableado): Jump9 saltos, Explosion3, SFX_Item al
  recoger, UI_Pause/Resume, CambiarLevel (victoria, Jugar, Back).
- Canciones renombradas por uso: menu/nivel1/nivel2/gameover/pausa/
  introduccion.mp3 (level4/level5 intactos); 5 referencias actualizadas.
- Demo: 38 checks (+tinte blanco y carga de dash).
