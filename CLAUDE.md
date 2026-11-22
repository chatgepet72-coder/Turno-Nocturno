# Turno Nocturno: El Último Cuatrimestre

Juego de terror psicológico en 2D (vista desde arriba) en Godot 4.7.2, renderer GL Compatibility, ventana de 1280×720. Proyecto escolar de la optativa Creación de Videojuegos. Roles: Juan Pablo (dirección y narrativa), Alan (programación y QA), Gerardo (arte 2D), Alejandro (audio y programación de apoyo).

## Ramas del repositorio

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
- `src/world/cuartos.gd`: solo se ve el cuarto actual y las puertas se cruzan con `src/ui/transicion_puerta.gd`.
- `src/story/`: historia (`campana.gd` guarda los hechos; `relato_turno.gd` los diálogos).
- `src/ui/`, `src/world/`, `src/audio/` (`AudioManager`, autoload).
- `tests/`: pruebas que corren con `godot --headless --path . --script res://tests/<archivo>.gd`.

## Reglas de código

- GDScript con tipos estáticos. Nombres del juego en español y `snake_case`; la API de Godot en inglés.
- Cambios pequeños y concretos. Antes de crear un sistema, revisa si ya existe en `src/` o en la rama `main`.
- No borrar ni renombrar el arte del equipo. Lo que se reemplace se queda en su carpeta.
- Al traer algo de `main`, adáptalo a la estructura de esta rama (`src/...`), no copies la estructura vieja (`scripts/...`).
