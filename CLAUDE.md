# Turno Nocturno

Survival horror 2D (vista desde arriba) en Godot 4.7. Lalo, velador nocturno de 25 años, busca a su compañero Don Chava en un campus universitario vacío durante una noche. Algo enterrado bajo el campus (el pueblo de San Miguel Tlalixco, sepultado en 1953) sube como tierra negra y mueve maniquíes, esqueletos, animales disecados, estatuas y personas.

## Dónde está cada cosa

- `docs/guion.md`: el guion completo. Es largo: busca la sección que necesitas (`grep -n "## " docs/guion.md`) en lugar de leerlo entero.
- `docs/tareas.md`: el plan de trabajo por etapas. Marca `[x]` al terminar una tarea.
- `scripts/autoload/`: `EventBus` (señales globales), `GameState` (progreso y cálculo del final) y `Dialogos` (caja de texto, voces y radio).
- `data/dialogos/*.json`: los textos de los diálogos. Cada línea: `quien`, `voz`, `texto` y opcional `radio: true`.
- Voces (`assets/audio/voces/`): `lalo_calmado`, `lalo_angustia` (después del sótano), `chava` (normal), `chava_debil` (débil o el ente con su voz). Se generan con `tools/arte/voces_juego.py`.
- `scripts/ui/hud.gd` (`Hud`): objetivo, salud, clavos, avisos y muerte, para todos los niveles. `scripts/ui/transicion_puerta.gd` y `transicion_escalera.gd`: transiciones estilo Resident Evil.
- Escenas: `scenes/main.tscn` (menú), `Entrada.tscn` (campus y prólogo), `Medicina.tscn` (planta baja). Se cambia con `GameState.ir_a(escena, punto)`; la partida se guarda con `GameState.guardar()` en `user://partida.json`.
- `data/medicina_cuartos.json`: medidas de cada cuarto de Medicina (paredes y puertas), generado por `tools/arte/medicina_interiores.py`.
- `scripts/niveles/prologo.gd`: el guion del prólogo, paso por paso. `scripts/personajes/don_chava.gd`: Don Chava guionizado (sin IA).
- `scenes/`: escenas por tipo (`jugador/`, `enemigos/`, `niveles/`, `ui/`, `objetos/`).
- `scripts/`: scripts con la misma estructura que `scenes/`.
- `assets/`: `sprites/`, `audio/sfx/`, `audio/musica/`, `audio/ambiente/`, `fuentes/`.
- `data/`: datos editables (mensajes de radio, objetos, documentos) en archivos `.tres` o `.json`.

## Reglas de código

- GDScript con tipos estáticos en todo (`var vida: int = 3`, `func f() -> void`).
- Nombres del juego en español y en `snake_case` (`vida_don_chava`, `mensaje_radio`). La API de Godot se queda en inglés.
- Clases y escenas en `PascalCase` (`Maniqui.tscn`, `class_name Maniqui`).
- Sistemas que no se conocen entre sí se comunican por `EventBus`, no con rutas `get_node("../../...")`.
- Composición antes que herencia: componentes como `Vida`, `Oido` (escucha ruidos), `Regresa` (enemigos que vuelven).
- Pixel art: resolución base 640×360, filtro de texturas "nearest", sin suavizado.

## Reglas de diseño que el código debe respetar

- Los enemigos derribados que "regresan" solo cambian de estado cuando están fuera de pantalla (`VisibleOnScreenNotifier2D`) y nunca junto a un cuarto seguro.
- La estática del radio sube cuando hay enemigos cerca.
- Mensajes de radio reales dicen "mijo"; los del ente dicen "Eduardo".
- Final: ver `GameState.calcular_final()`.
- Nunca: virus, laboratorios, corporaciones ni trajes contra químicos.

## Cómo trabajar

- Cambios pequeños y concretos. Edita solo lo necesario.
- Antes de crear un sistema, revisa si ya existe algo en `scripts/`.
