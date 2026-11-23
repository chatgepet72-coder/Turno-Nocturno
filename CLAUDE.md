# Turno Nocturno: El Último Cuatrimestre

Juego de terror psicológico en 2D (vista desde arriba) en Godot 4.7.2, renderer GL Compatibility, ventana de 1280×720. Proyecto escolar de la optativa Creación de Videojuegos. Roles: Juan Pablo (dirección y narrativa), Alan (programación y QA), Gerardo (arte 2D), Alejandro (audio y programación de apoyo).

## Ramas del repositorio

- `primera-persona`: la versión en primera persona (en desarrollo). `src/fp/`: `primera_persona.gd` (cámara, mirar, linterna en el pecho, enemigos como dibujos que miran a la cámara) y `mundo_3d.gd` (levanta en 3D el edificio a partir del mapa 2D, que sigue mandando: choques, enemigos, puzzles). Afuera (campus) y el teaser todavía se ven en 2D. Para jugar la vista 2D en esta rama: `TURNO_2D=1`.

- `el-ultimo-cuatrimestre`: **aquí se trabaja**. Empezó como copia exacta del proyecto del equipo (repositorio `magicart99/Turno-Nocturno`, commit `089943e`).
- `magicart99-original`: copia de respaldo de ese proyecto. No se toca.
- `main` y `respaldo-nuestra-version`: la versión anterior (Lalo velador, Don Chava, Facultad de Medicina, pistola de clavos, molotov). No se toca; de ahí se copian sistemas.

## Lo que manda

La historia entregada al profesor (documento "Turno Nocturno — El Último Cuatrimestre", 21 de septiembre de 2026) **no se puede cambiar**, solo ampliar. Resumen y plan en `docs/plan_adaptacion.md`. Léelo antes de cambiar historia, enemigos o armas.

## Dónde está cada cosa

- `scenes/escuela.tscn`: escena principal. `src/core/escuela.gd`: el nivel, el guardado (`guardado.gd`) y los controles (`controles.gd`, autoload).
- `src/player/`: Lalo (`jugador.gd`), cordura, mochila y animación.
- `src/enemies/archivero.gd`: el Archivero (no se puede matar).
- `src/enemies/enemigo.gd` (`Enemigo`): base de los enemigos que sí se pelean; lee `assets/sprites/enemigos/<tipo>/animaciones.json`. Cada tipo en `la_baja.gd`, `el_desvelado.gd`, `el_expediente.gd`, `el_sinodal.gd`. Dónde aparecen: `data/enemigos.json` (lo arma `encuentros.gd`).
- `src/player/pistola_clavos.gd` y `clavo.gd`: la pistola de clavos. Un enemigo tirado se clava al piso con 3 clavos más y ya no se levanta.
- `src/world/cuartos.gd`: solo se ve el cuarto actual y las puertas se cruzan con `src/ui/transicion_puerta.gd`. Ahí están los cuartos con llave (`LLAVES`) y el cuarto seguro (`REFUGIO`, el Taller: ni el Archivero ni los enemigos entran).
- `data/enemigos.json`: cuándo aparece cada enemigo (`aparece`: inicio, zona, hecho, etapa, objeto) y los objetos del mundo: recogibles y puntos (`src/world/punto_interes.gd`: examinar, candado de 4 números, mesa de trabajo).
- `src/story/teaser.gd`: el teaser del inicio (Lalo llega, saluda a Don Chuy, entra, se duerme a las 23:59 y despierta con todo cambiado). Sale al elegir "Iniciar juego" (`escuela.iniciar_con_teaser()`); Esc / Start lo salta. Sonidos en `assets/audio/teaser/` (`tools/teaser/sonidos_teaser.py`).
- Reparto de objetos (estilo Resident Evil / Silent Hill): nada tirado en los pasillos; suministros sobre pupitres y escritorios o dentro de cajones (`punto_interes.gd`, tipo `cajon`); una nota de aviso antes de cada enemigo. Todo en `data/enemigos.json` → `objetos`. Molotov = botella vacía + alcohol + trapo. `Botiquín` recupera 40 de Cordura.
- Mochila (`src/ui/inventario.gd`): diseño del equipo en `assets/sprites/inventario/` (posiciones en `ui/layout.json`, fuente Crimson Text en `assets/fuentes/`). Pestañas Objetos/Documentos/Evidencias/Llaves/Recuperación/Otros (Tab/Shift+Tab, LB/RB); Usar (E/A), Combinar (Q/X: caja de clavos + pistola = recargar), Tirar (R/R3), Volver (Esc/B). Íconos de botones según teclado, Xbox o PlayStation. Cada objeto → ícono y pestaña en `CATALOGO`; los productos de la cafetería usan nombres genéricos (`PRODUCTOS_ARTE`). Vista previa: `vistas_previas_512` → `iconos_512` → `iconos_256`. El mismo panel es el mostrador de la cafetería (`tienda`).
- Cuarto seguro: `src/world/refugio.gd` (luz cálida siempre y música tranquila `assets/audio/refugio/refugio.wav`, hecha con `tools/arte/musica_refugio.py`).
- Puzzle del Taller: el reloj de la Entrada (11:59 p. m.) y el memorándum de Dirección (formato de 24 horas) dan la combinación 2359 de la caja de llaves (`src/ui/candado.gd`).
- Modo de prueba para administradores (`escuela.modo_prueba`): invencible, todo lo demás igual. F9 o "Admin · Modo de prueba" en la pausa; con él activo, la pausa también da pistola, clavos, molotovs y llaves. Solo existe al correr desde el editor de Godot (`OS.has_feature("editor")`): el juego exportado no lo tiene.
- `src/story/`: historia (`campana.gd` guarda los hechos; `relato_turno.gd` los diálogos).
- `src/ui/`, `src/world/`, `src/audio/` (`AudioManager`, autoload).
- `tests/`: pruebas que corren con `godot --headless --path . --script res://tests/<archivo>.gd`.

## Reglas de código

- GDScript con tipos estáticos. Nombres del juego en español y `snake_case`; la API de Godot en inglés.
- Cambios pequeños y concretos. Antes de crear un sistema, revisa si ya existe en `src/` o en la rama `main`.
- No borrar ni renombrar el arte del equipo. Lo que se reemplace se queda en su carpeta.
- Al traer algo de `main`, adáptalo a la estructura de esta rama (`src/...`), no copies la estructura vieja (`scripts/...`).
