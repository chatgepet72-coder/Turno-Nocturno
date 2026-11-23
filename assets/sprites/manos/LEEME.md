# Manos de Lalo en primera persona (v4: diseño de la referencia)

Son las mismas manos y la misma clavadora de la imagen de referencia, con las correcciones aplicadas.

- **Tamaño:** ocupan el cuarto inferior derecho, y la punta de la clavadora no pasa del centro de la pantalla.
- **Ángulo:** la boquilla apunta hacia el centro, casi horizontal.
- **Luz de noche:** la linterna está en el pecho y alumbra desde abajo. La parte de arriba queda en sombra y los colores están apagados y sucios. La única luz cálida es el fuego de la molotov.
- **Fondo:** totalmente transparente, sin franjas negras. Las mangas siguen hasta salir de la pantalla.

## Carpetas

| Carpeta | Contenido |
|---|---|
| `frames/` | 640 × 360, **mismos nombres de archivo** que la entrega anterior |
| `frames_1920x1080/` | Los mismos cuadros en 1920 × 1080 (16:9) |
| `sheets/` | Una tira horizontal por animación (640 × 360 por cuadro) |
| `preview/` | Un GIF por animación dentro del pasillo, más `todas_las_animaciones.png` |
| `diseno/` | El cuadro de reposo suelto y dentro del juego |

`animaciones.json` es **idéntico** al anterior: mismas animaciones, cuadros, fps y loops.
`animaciones_1920x1080.json` es el mismo archivo, pero apunta a `frames_1920x1080/`.

| Animación | Cuadros | fps | Loop | Nota |
|---|---|---|---|---|
| reposo | 4 | 6 | sí | Respira (balanceo en ocho, suave) |
| disparo | 3 | 15 | no | El clavo sale en el cuadro 1: retroceso corto arriba y atrás, con chispa |
| recarga | 6 | 8 | no | 2-3 sale la tira vieja, 4 llega la nueva, 5 entra. Las manos no salen de la esquina |
| molotov | 4 | 10 | no | Baja la clavadora y la izquierda lanza la botella. La botella sale en el cuadro 4 |
| sin_arma | 2 | 3 | sí | Manos relajadas abajo |

**Ojo con el escalado:** este dibujo es de estilo cómic, no pixel art. Si usas los cuadros de 640 × 360 y los escalas a pantalla completa, usa filtro lineal: con "nearest" se ven escalones. Si tu pantalla es de 1920 × 1080, mejor usa `frames_1920x1080/` directamente.
