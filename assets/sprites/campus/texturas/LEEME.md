# Texturas del exterior (noche)

Todas son PNG vistas de frente y planas, sin luz ni sombras marcadas (la iluminación la pone el juego), con colores apagados de noche. `muestrario.png` muestra cada textura repetida 2 × 2 para comprobar que no se notan los cortes.

| Archivo | Tamaño | Se repite | Escala sugerida (1 repetición) |
|---|---|---|---|
| `pasto.png` | 1024 × 1024 | sí, en las dos direcciones | 2 × 2 m |
| `concreto_banqueta.png` | 1024 × 1024 | sí | 2 × 2 m (cada textura trae 4 losas de 1 m) |
| `asfalto_estacionamiento.png` | 1024 × 1024 | sí | 4 × 4 m |
| `pared_block.png` | 1024 × 1024 | **solo a lo ancho** | 3.2 m de ancho × 3.2 m de alto (16 hiladas de block de 40 × 20 cm) |
| `ventana_salon.png` | 512 × 512 | no | una ventana completa con su marco |
| `ventana_salon_rota.png` | 512 × 512 | no | la misma, con el vidrio de abajo a la derecha roto |
| `lamina_roja_oxidada.png` | 1024 × 1024 | sí | 2 × 2 m, con las ondas en dirección de la pendiente |
| `malla_ciclonica.png` | 1024 × 1024, fondo transparente | sí | 0.8 × 0.8 m (rombos de 5 cm) |
| `tierra_removida.png` | 1024 × 1024 | sí | 2 × 2 m |

Notas:
- **Pared:** representa la pared completa de piso a techo: crema arriba, gris abajo (desde ~1.15 m) y salitre subiendo desde el piso. Se repite a lo ancho; no la repitas hacia arriba, porque se vería otra franja gris.
- **Asfalto:** no trae líneas amarillas, como pediste.
- **Malla ciclónica:** los píxeles transparentes conservan el color del alambre, para que no salga un borde negro al alejarse (mipmaps). Usa el modo de transparencia "alpha clip" o "alpha test".
- **Lámina:** los tornillos van en dos líneas (las vigas), cada uno con su escurrimiento de óxido hacia abajo. Las ondas quedan verticales en la imagen: oriéntala para que bajen con la pendiente del techo.
- **Ventana:** la sana y la rota encajan en el mismo hueco. Por dentro solo se adivinan unos pupitres y hay una huella de mano en el vidrio.
