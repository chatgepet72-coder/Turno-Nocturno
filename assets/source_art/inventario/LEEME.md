# Inventario: objetos e interfaz

Todo sale de la imagen de referencia del inventario, más lo que se pintó aparte a 512 px.

- `catalogo.png`: todos los objetos (43) con su id y su pestaña.
- `nuevos_512.png`: lo pintado a 512 × 512: alcohol, pistola de clavos (diseño de las manos en primera persona), sello roto y refresco genérico, más las vistas previas de pistola, molotov, botiquín, las tres llaves y la carpeta confidencial.
- `inventario.json`: el catálogo de datos (nombres, tipos, descripciones, pilas, efectos y combinaciones sugeridas).
- `iconos/`, `iconos_256/`, `iconos_512/` y `vistas_previas_512/`.
- `ui/`: el panel, las casillas, las pestañas y sus íconos, los botones de PlayStation, Xbox y teclado, la línea de Cordura, la fuente y `layout.json`.
- `ui/ejemplo_*.png`: la pantalla armada solo con estas piezas (con controles de PlayStation, Xbox y teclado).
- `PROMPT_IA.md`: el texto para pasarle a la IA que lo va a programar.

Cambios de esta versión:
- La pestaña "Tesoros" ahora es "Evidencias", con un ícono de huella digital. La barra de abajo dice "Cordura".
- Dos bolsas de papas cambiaron de rojo a morado (`papas_rojas`) y a verde azulado (`frituras_rojas`), para que no se parezcan a marcas reales. Las papas de adentro no cambiaron.
- El refresco ahora es una botella recta, sin marca, con etiqueta naranja sin texto.
- Nuevos: `alcohol` (pestaña Otros, sirve para la molotov) y `sello_roto` (pestaña Evidencias).
- Receta de molotov: botella + trapo + alcohol.
