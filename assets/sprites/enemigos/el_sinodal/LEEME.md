# El Sinodal (el pesado)

Cada cuadro mide **480 × 480** (los demás usan 320), con fondo transparente y contorno de 4 px.
El pivote está en el centro inferior: x = 240, y = 464, que es la línea de piso.

Está dibujado a la **misma escala** que Lalo y los demás: en el motor no hay que reescalarlo. Solo cambian el tamaño del cuadro y el pivote, y así mide 1.6 Lalos.

## Animaciones

| Archivo | Qué es | Cuadros | FPS | Loop | Descripción |
|---------|--------|---------|-----|------|-------------|
| idle | reposo | 6 | 6 | sí | La panza respira pesado, el ojo busca entre las hojas y la mano libre se crispa. |
| walk | caminata pesada | 8 | 7 | sí | Lenta, con balanceo, sin detenerse nunca. La guillotina se arrastra y la bisagra rebota contra el piso. Unos 40 px/s en pantalla, constante. |
| attack | guillotinazo | 10 | 10 | no | Arrastra la guillotina hacia atrás, la levanta, la sube por encima de la cabeza, la deja caer frente a él (vuelan pedazos de exámenes) y la vuelve a arrastrar. **Golpe en el cuadro 7.** |
| hurt | recibir golpe | 3 | 10 | no | Se tambalea hacia atrás. Úsala cuando los clavos solo lo frenan. |
| stun | aturdido | 6 | 8 | sí | Aturdido por el extintor: se bambolea, el fajo de la cabeza se ladea y el ojo gira. Repítela mientras dure el aturdimiento; es el momento de rodearlo. |

## Archivos

- `frames/<animación>_<dirección>_<NN>.png`: cada cuadro suelto (por ejemplo `walk_down_01.png`).
- `sheets/<animación>_<dirección>.png`: una tira por animación y dirección. El cuadro 1 va a la izquierda.
- `sheets/el_sinodal_todo.png`: todo en una sola hoja. El orden de las filas viene en `animaciones.json` → `hoja_completa.filas`.
- `animaciones.json`: cuadros, FPS, loop, cuadro de golpe, velocidad, archivos por dirección y pivote.
- `preview/`: GIF de cada animación con las 4 direcciones lado a lado.
- `diseno/`: el personaje en sus 4 vistas.

Direcciones: `down` (hacia la cámara), `up` (se aleja), `left` y `right`.
`left` y `right` **no son espejo** una de la otra: el personaje es asimétrico y cada lado está dibujado aparte.
