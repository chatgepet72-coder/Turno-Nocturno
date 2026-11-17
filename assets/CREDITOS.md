# Créditos de arte y sonido

Todo el arte del juego está en `sprites/` al tamaño final (1 pixel de arte = 4 px de pantalla). Los scripts que lo generan están en `tools/arte/`.

## Arte

| Carpeta / archivo | Qué es | Origen |
| --- | --- | --- |
| `sprites/personajes/lalo/` (originales) y `lalo/caminar/` | Lalo caminando en 4 direcciones | Repositorio `magicart99/Turno-Nocturno` |
| `sprites/personajes/don_chava/` (originales) y `don_chava/caminar/` | Don Chava (antes "guardia") | Repositorio `magicart99/Turno-Nocturno` |
| `sprites/personajes/*/sentado/` | Sentados (2 cuadros) y levantarse (5 cuadros) | Generados por código a partir de las imágenes de magicart99 (`tools/arte/sentados_v2.py`) |
| `sprites/enemigos/jefe_final_referencia/` | Referencia para el jefe final (antes "Archivero") | Repositorio `magicart99/Turno-Nocturno` |
| `sprites/escenario/edificio_largo.png`, `excavadora.png`, `arbol.png`, `banca.png`, `poste.png` | Edificios de la C, excavadora, árbol, banca, poste | Arte del equipo |
| `sprites/escenario/caseta_*.png`, `central_demolido.png`, `fuente.png`, `seto_*.png`, `reja.png`, `pluma.png`, `puerta_alumnos.png`, `hueco_con_cinta.png`, `escombro.png`, `cono.png` | Piezas en el estilo del equipo | Generadas por código (`tools/arte/piezas.py`, `preparar_assets.py`) |
| `sprites/escenario/autos/` | Autos, vochos y Tsuru con lodo | Generados por código (`tools/arte/autos.py`, `autos_v2.py`) |
| `sprites/escenario/tierra/` | Tierra negra (rastros, juntas, huellas) | Generada por código (`tools/arte/tierra_v3.py`) |
| `sprites/pisos/` | Pasto, adoquín, losas, asfalto | Generados por código (`tools/arte/piezas.py`) |
| `sprites/escenario/caseta/` | Escritorio, casillero, silla, termo | Repositorio `magicart99/Turno-Nocturno` |
| `sprites/escenario/prologo/sotano.png` | Sótano del Edificio Central: pared agrietada con tubos, piso de concreto, escalera de obra y derrumbe | Arte del equipo, armado por código (`tools/arte/transicion_sotano.py`) |
| `sprites/ui/escalera_transicion.png` | La escalera de la transición al sótano | Arte del equipo |
| `sprites/escenario/lapida.png` | Lápida para la cripta del final | Arte del equipo |
| `sprites/escenario/prologo/linterna_don_chava.png`, `maniqui_sentado.png` | Linterna tirada y maniquí sentado | Generados por código (`tools/arte/prologo_piezas.py`) |
| `sprites/enemigos/maniqui/` | Maniquí caminando en 4 direcciones, parado con ojos y señalando | Arte del equipo (`tools/arte/pistola_y_maniqui.py`) |
| `sprites/objetos/caja_*.png`, `sprites/ui/pistola_clavos.png` | Caja de herramientas y pistola de clavos | Arte del equipo |
| `sprites/objetos/clavo.png` | Clavo disparado | Generado por código |
| `sprites/interiores/medicina/` | Pasillo largo y 17 cuartos de la Facultad de Medicina (versión corregida) | Arte del equipo, recortado y escalado con `tools/arte/medicina_interiores.py` |
| `sprites/ui/puerta_1..4.png` | Puerta de la transición (4 cuadros) | Arte del equipo |
| `sprites/enemigos/maniqui/*.png` | Maniquí con ojos rojos en 4 direcciones | Arte del equipo (`tools/arte/maniqui_ojos_rojos.py`) |
| `sprites/interiores/medicina/pasillo_oeste.png` | Ala oeste: un tramo del pasillo girado | Arte del equipo (`tools/arte/ala_oeste_e_iconos.py`) |
| `sprites/objetos/iconos/` | Íconos de la mochila (llave y documento de magicart99; vendas, cizalla y brillo por código) | `tools/arte/ala_oeste_e_iconos.py` |
| `sprites/luces/` | Texturas de luz radial y cono de linterna | Generadas por código (`tools/arte/preparar_assets.py`) |

## Sonido

Tomado del repositorio `magicart99/Turno-Nocturno`. Licencias y fuentes originales en `audio/licencias/`.

| Carpeta | Qué es | Licencia |
| --- | --- | --- |
| `audio/pasos/footstep_*` | Pasos en concreto y pasto (Kenney, Impact Sounds) | CC0 |
| `audio/pasos/Ejimas1.ogg` | Pasos de interior (IgnasD, OpenGameArt) | CC0 |
| `audio/ambiente/lost.ogg`, `ambient_horror.ogg` | Música y tensión ambiental (OpenGameArt) | CC0 |
| `audio/efectos/door_open.wav`, `puerta.ogg` | Puertas (OpenGameArt) | CC0 |
| `audio/efectos/disparo_clavos.wav`, `clavo_impacto.wav`, `recarga.wav`, `sin_clavos.wav`, `golpe.wav`, `maniqui_cae.wav` | Sonidos del combate | Sintetizados por código (`tools/arte/pistola_y_maniqui.py`) |
| `audio/efectos/puerta_rechina.wav` | Rechinido de la puerta en la transición | Generado por el equipo con poppop.ai, recortado (de 0.95 a 3.1 s) |
| `audio/efectos/paso_metal_*.wav` y `audio/voces/` | Pasos en la escalera metálica y voces de murmullo | Sintetizados por código (`tools/arte/`) |
| `audio/efectos/radio_estatica.wav` y demás `.wav` | Sintetizados por el equipo de magicart99 | Originales |
