# Manos de Lalo en primera persona: clavadora industrial

Son las dos manos de Lalo, vistas desde sus ojos, sosteniendo una clavadora industrial gris y amarilla, gastada.
La pistola queda en la esquina inferior derecha y apunta hacia el centro de la pantalla.
- **Mano derecha:** en la empuñadura, con el índice en el gatillo y el pulgar a lo largo del costado.
- **Mano izquierda:** sostiene el frente por debajo.
- **Mangas:** de la sudadera azul de la universidad, con puño de resorte.
- **Estilo:** piel morena como la de Lalo, contorno oscuro y luz tenue azulada para que combine con lo oscuro del juego.

**Formato:** todos los cuadros miden 640 × 360 px, con fondo transparente.
Colócalos en (0, 0) cubriendo la pantalla y escálalos ×3 para 1920 × 1080 con filtro *nearest*, para que el pixel quede nítido.
En `animaciones.json` vienen todos los datos.

## Animaciones

| Archivo | Cuadros | FPS | Loop | Qué pasa |
|---------|---------|-----|------|----------|
| `reposo` | 4 | 6 | sí | Respira: todo sube y baja muy poco, y la mano izquierda va con un leve retraso. |
| `disparo` | 3 | 15 | no | **Cuadro 1:** el gatillo se jala, la pistola salta hacia arriba y hacia atrás, sale el clavo con chispas. **Cuadro 2:** humo y la pistola baja. **Cuadro 3:** se asienta. Después regresa a `reposo`. |
| `recarga` | 6 | 8 | no | **1:** levanta la pistola. **2–3:** la mano izquierda saca la tira de clavos vieja por atrás del cargador (el riel queda vacío). **4:** trae una tira nueva y brillante. **5:** la mete. **6:** la mano regresa abajo. |
| `molotov` | 4 | 10 | no | La pistola baja de lado. **1:** la mano izquierda sube la botella ámbar con el trapo ardiendo, que ilumina con luz cálida. **2:** la echa atrás. **3:** la lanza. **4:** la mano queda abierta y la botella sale girando. |
| `sin_arma` | 2 | 3 | sí | Solo la mano derecha, relajada a un lado, respirando. |

Momentos para el código:
- **Disparo:** aplícalo en el cuadro 1.
- **Molotov:** crea el proyectil en el cuadro 4.
- **Recarga:** está completa al terminar el cuadro 6.

## Archivos

- `frames/<animación>_<NN>.png`: cada cuadro suelto, por ejemplo `recarga_03.png`.
- `sheets/<animación>.png`: una tira por animación. El cuadro 1 va a la izquierda.
- `animaciones.json`: cuadros, FPS, loop, archivos y notas de cada animación.
- `preview/`: GIF de cada animación sobre una captura del juego, y `todas_las_animaciones.png` con todo junto.
- `diseno/`: el diseño en reposo, solo y sobre la pantalla a 1920 × 1080.
