# La Baja (enemigo común)

Cada cuadro mide 320 × 320, con fondo transparente y contorno de 4 px.
El pivote está en el centro inferior: x = 160, y = 310, que es la línea de piso.

## Animaciones

| Archivo | Qué es | Cuadros | FPS | Loop | Descripción |
|---------|--------|---------|-----|------|-------------|
| idle | reposo | 4 | 6 | sí | Respira, la cabeza se le va de lado y los dedos se crispan. |
| walk | caminata | 8 | 7 | sí | Da un paso con la pierna buena y arrastra la izquierda tiesa, con la punta del pie raspando el piso. Avanza unos 60 px/s en pantalla. |
| attack | embiste | 8 | 10 | no | Se echa hacia atrás para cargar, se lanza con los brazos al frente y la cabeza por delante, sostiene el agarre y se recupera. **Golpe en el cuadro 5.** |
| hurt | recibir golpe | 3 | 10 | no | Retrocede y la cabeza se le dobla todavía más. |

## Archivos

- `frames/<animación>_<dirección>_<NN>.png`: cada cuadro suelto (por ejemplo `walk_down_01.png`).
- `sheets/<animación>_<dirección>.png`: una tira por animación y dirección. El cuadro 1 va a la izquierda.
- `sheets/la_baja_todo.png`: todo en una sola hoja. El orden de las filas viene en `animaciones.json` → `hoja_completa.filas`.
- `animaciones.json`: cuadros, FPS, loop, cuadro de golpe, velocidad, archivos por dirección y pivote.
- `preview/`: GIF de cada animación con las 4 direcciones lado a lado.
- `diseno/`: el personaje en sus 4 vistas.

Direcciones: `down` (hacia la cámara), `up` (se aleja), `left` y `right`.
`left` y `right` **no son espejo** una de la otra: el personaje es asimétrico y cada lado está dibujado aparte.
