# Prompt para la IA que va a programar el inventario

Copia todo lo que está debajo de la línea y pásalo junto con la carpeta `inventario/`.

---

Implementa la pantalla de **inventario** del juego usando los recursos de la carpeta `inventario/`. No dibujes ni generes arte nuevo: todo ya está hecho.

## Archivos

- `inventario.json`: el catálogo. Trae las 6 pestañas y los 43 objetos (id, nombre, categoría, tipo, descripción, si se apila y cuánto), más efectos, usos y combinaciones sugeridas.
- `iconos/<id>.png`: el ícono de cada objeto con fondo transparente, a su tamaño original (unos 100–180 px).
- `iconos_256/<id>.png`: el mismo ícono centrado en un cuadro de 256 × 256 transparente.
- `iconos_512/<id>.png`: íconos pintados directamente a 512 × 512 (alcohol, pistola de clavos, sello roto, refresco).
- `vistas_previas_512/<id>.png`: vistas previas a 512 × 512 sin ampliar (pistola de clavos, molotov, botiquín, las tres llaves y la carpeta confidencial). Si un objeto tiene `vista_previa_512` en el JSON, úsala en la caja de vista previa (solo se reduce, nunca se amplía). Si no tiene, usa `icono_512` o `icono_256`.
- `ui/panel_fondo.png`: el panel vacío (1614 × 354), con el marco, las pestañas sin texto, el hueco de la cuadrícula, la caja de vista previa, la caja de descripción y la barra de abajo.
- `ui/layout.json`: las posiciones, tamaños, fuentes y colores de todo, en píxeles dentro de `panel_fondo.png`.
- `ui/slot.png` y `ui/slot_seleccionado.png`: la casilla normal y la seleccionada (con brillo). Respeta los márgenes que indica `layout.json`.
- `ui/pestana_activa.png`: el fondo de la pestaña activa. Se estira al ancho de cada pestaña.
- `ui/iconos_pestanas/*.png`: los íconos blancos de cada pestaña.
- `ui/botones/playstation|xbox|teclado/*.png`: los íconos de botón (38 × 38) de Usar, Combinar y Volver para cada control. `layout.json` dice cuál va con cada acción.
- `ui/salud_ecg.png`: la línea de electrocardiograma de la barra de **Cordura** (verde → amarillo → rojo).
- `ui/fuente/CrimsonText-*.ttf`: la tipografía (licencia OFL, se puede incluir en el juego).
- `ui/referencia_original.png`: cómo debe verse.
- `ui/ejemplo_*.png` y `ui/referencia_implementacion.py`: la pantalla ya armada con estos mismos archivos, en Python. Úsala como guía del orden de dibujo.

## Cómo debe funcionar

1. **Pestañas:** Objetos, Documentos, Evidencias, Llaves, Recuperación y Otros. Cada objeto aparece en la pestaña de su `categoria`. Se cambia de pestaña con L1/R1, LB/RB o Tab / Shift+Tab.
2. **Cuadrícula:** 6 columnas con 2 filas visibles. La tercera fila asoma cortada por abajo y la lista hace scroll. Recorta todo lo que salga del área `cuadricula.area`. La selección se mueve con las flechas o el stick.
3. **Íconos en las casillas:** escálalos para que quepan con un margen de unos 8 px y céntralos. Si el objeto se apila y tienes más de 1, pon el número abajo a la derecha (Crimson Text, blanco con sombra).
4. **Vista previa:** el ícono del objeto seleccionado en grande, centrado, con una sombra suave.
5. **Descripción:** `nombre` en blanco, `tipo` en naranja (#E7A415) y en mayúsculas, una línea separadora tenue y luego `descripcion` con salto de línea automático.
6. **Cordura:** la barra de abajo dice "Cordura" (no "Salud"). La tira ECG se recorta de izquierda a derecha según la cordura (100% = completa). Los `efecto_sugerido` de comida y botiquín suben `cordura`.
7. **Botones:** Usar, Combinar y Volver. PlayStation ✕ □ ○, Xbox A X B, teclado E Q Esc. Muestra los íconos del último dispositivo que se usó (si el jugador toca el teclado, cambia a los de teclado al instante).
   - **Usar:** aplica `efecto_sugerido` (salud o aguante), equipa un arma, o abre un documento para leerlo.
   - **Combinar:** pide elegir un segundo objeto y busca la pareja en `recetas_sugeridas` (por ejemplo, botella + trapo + alcohol = molotov).
8. **Escala:** el panel se diseñó a 1614 px de ancho. A 1920 × 1080 escálalo ×1.15 (o lo que quepa), céntralo horizontalmente y pégalo abajo con un margen de unos 20 px. Escala con filtro lineal, no "nearest".
9. **Juego en pausa:** mientras el inventario está abierto, el juego se pausa y el fondo se oscurece un 60%.

Los nombres, descripciones, efectos y cantidades son una propuesta. Déjalos en el JSON para que se puedan cambiar sin tocar el código.
