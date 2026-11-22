# El Expediente (el que embosca)

Cada cuadro mide 320 × 320, con fondo transparente y contorno de 4 px.
El pivote está en el centro inferior: x = 160, y = 310, que es la línea de piso.

## Animaciones

| Archivo | Qué es | Cuadros | FPS | Loop | Descripción |
|---------|--------|---------|-----|------|-------------|
| idle | acecho | 6 | 8 | sí | Quieto entre las sombras: respira, mueve los dedos y gira la cabeza despacio. |
| crawl | arrastrarse | 8 | 10 | sí | Avanza mano sobre mano, la mano apoyada se queda fija en el piso y la cola de carpetas ondula y suelta una hoja en cada ciclo. Avanza unos 60 px/s en pantalla, a tirones. |
| attack | agarrar el tobillo | 8 | 12 | no | Se encoge, dispara el brazo por el piso, cierra la mano en el tobillo, la sostiene y jala hacia él. **El agarre es en el cuadro 4**; desde ahí empieza la mecánica de zafarse. |
| hurt | recibir golpe | 3 | 10 | no | Se encoge hacia atrás con la cabeza sacudida. |

## Archivos

- `frames/<animación>_<dirección>_<NN>.png`: cada cuadro suelto (por ejemplo `walk_down_01.png`).
- `sheets/<animación>_<dirección>.png`: una tira por animación y dirección. El cuadro 1 va a la izquierda.
- `sheets/el_expediente_todo.png`: todo en una sola hoja. El orden de las filas viene en `animaciones.json` → `hoja_completa.filas`.
- `animaciones.json`: cuadros, FPS, loop, cuadro de golpe, velocidad, archivos por dirección y pivote.
- `preview/`: GIF de cada animación con las 4 direcciones lado a lado.
- `diseno/`: el personaje en sus 4 vistas.

Direcciones: `down` (hacia la cámara), `up` (se aleja), `left` y `right`.
`left` y `right` **no son espejo** una de la otra: el personaje es asimétrico y cada lado está dibujado aparte.
