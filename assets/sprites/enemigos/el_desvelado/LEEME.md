# El Desvelado (enemigo rápido)

Cada cuadro mide 320 × 320, con fondo transparente y contorno de 4 px.
El pivote está en el centro inferior: x = 160, y = 310, que es la línea de piso.

## Animaciones

| Archivo | Qué es | Cuadros | FPS | Loop | Descripción |
|---------|--------|---------|-----|------|-------------|
| idle | reposo | 6 | 8 | sí | Congelado mientras la linterna lo alumbra. Tiembla y en el cuadro 4 da un tic brusco con la cabeza. El café gotea y la pantalla del celular parpadea. |
| run | carrera a saltos | 8 | 12 | sí | Dos saltos cortados por ciclo: se agacha, se impulsa, se suspende y aterriza en seco. Muévelo rápido en los cuadros 2, 3, 6 y 7. |
| attack | termazo | 8 | 12 | no | Se agacha, levanta el termo, salta y lo azota mientras con la mano del celular trata de agarrar. Al impacto salpica café. **Golpe en el cuadro 5.** |
| hurt | recibir golpe | 3 | 10 | no | Retrocede con los brazos abiertos y la cabeza sacudida. |

## Archivos

- `frames/<animación>_<dirección>_<NN>.png`: cada cuadro suelto (por ejemplo `walk_down_01.png`).
- `sheets/<animación>_<dirección>.png`: una tira por animación y dirección. El cuadro 1 va a la izquierda.
- `sheets/el_desvelado_todo.png`: todo en una sola hoja. El orden de las filas viene en `animaciones.json` → `hoja_completa.filas`.
- `animaciones.json`: cuadros, FPS, loop, cuadro de golpe, velocidad, archivos por dirección y pivote.
- `preview/`: GIF de cada animación con las 4 direcciones lado a lado.
- `diseno/`: el personaje en sus 4 vistas.

Direcciones: `down` (hacia la cámara), `up` (se aleja), `left` y `right`.
`left` y `right` **no son espejo** una de la otra: el personaje es asimétrico y cada lado está dibujado aparte.
