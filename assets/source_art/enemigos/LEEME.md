# Enemigos: diseños, sprites y animaciones

Los cuatro enemigos que sí se pueden pelear, en el mismo estilo que Lalo y el Archivero:
- Pixel art con contorno oscuro grueso y colores apagados (gris papel, beige, negro tinta, azul marino y rojo sello).
- Hombros, brazos y uniones redondeados.
- Revisados sobre una captura real del juego, a la escala de Lalo (`los_4_enemigos_en_juego.png`).

| Carpeta | Enemigo | Cuadro | Pivote (x, y) | Animaciones (cuadros) |
|---------|---------|--------|---------------|-----------------------|
| `la_baja/` | La Baja (común) | 320 × 320 | 160, 310 | idle 4 · walk 8 · attack 8 · hurt 3 |
| `el_desvelado/` | El Desvelado (rápido) | 320 × 320 | 160, 310 | idle 6 · run 8 · attack 8 · hurt 3 |
| `el_expediente/` | El Expediente (embosca) | 320 × 320 | 160, 310 | idle 6 · crawl 8 · attack 8 · hurt 3 |
| `el_sinodal/` | El Sinodal (pesado) | **480 × 480** | 240, 464 | idle 6 · walk 8 · attack 10 · hurt 3 · stun 6 |

En total son 424 cuadros: 4 direcciones por animación (`down`, `left`, `right` y `up`).

## Cómo meterlos al juego

1. **Escala:** todos están dibujados a la misma escala que Lalo. Muéstralos con el mismo factor que a él (en la captura, 50%). No reescales a El Sinodal: su cuadro es más grande para que mida 1.6 Lalos.
2. **Pivote:** usa el centro inferior de cada cuadro, con el valor de la tabla. Así los pies de todos quedan sobre la misma línea de piso.
3. **Datos:** cada personaje trae `animaciones.json` con los cuadros, FPS, si la animación se repite (loop), el **cuadro de golpe** de cada ataque, la velocidad sugerida y la lista de archivos por dirección. Puedes leerlo desde el código para no configurar nada a mano.
4. **Ataques y golpes:** `attack` y `hurt` no se repiten. Al terminar, regresa a `idle` o a la animación de movimiento. El daño se aplica en el cuadro de golpe que indica el JSON:

| Enemigo | Ataque | Cuadro de golpe |
|---------|--------|-----------------|
| La Baja | Embiste de cerca | 5 |
| El Desvelado | Termazo | 5 |
| El Expediente | Agarre del tobillo | 4 (aquí empieza la mecánica de zafarse) |
| El Sinodal | Guillotinazo | 7 |

5. **Lados:** `left` y `right` no son espejo una de la otra. Cada lado está dibujado por separado porque los personajes son asimétricos (el brazo largo, el pie arrastrado, el termo y el celular, la guillotina).
6. **Velocidades:** las animaciones están hechas para que los pies no patinen a la velocidad sugerida de cada una. Cada `LEEME.md` explica cuándo acelerar o frenar para que el movimiento se sienta a tirones.

## Qué hay en cada carpeta

- `frames/`: cuadros sueltos, con nombres como `attack_down_05.png`.
- `sheets/`: una tira por animación y dirección, más una hoja con todo.
- `preview/`: GIFs de cada animación con las 4 direcciones lado a lado.
- `diseno/`: el personaje en sus 4 vistas.
- `animaciones.json` y `LEEME.md`.

## Pendiente, cuando Alejandro defina la lista final

`caer`, `levantarse` (para La Baja si no se quema) y `quemarse`. Los esqueletos de animación ya están listos para hacerlas con el mismo estilo.
