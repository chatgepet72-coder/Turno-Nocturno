# Plan de trabajo

El juego se construye por etapas. Cada etapa termina con algo que se puede jugar. Marca `[x]` al terminar una tarea.

## Etapa 0: Base del proyecto

- [x] Proyecto de Godot 4.7 con carpetas, controles y capas de colisión
- [x] `EventBus` y `GameState`
- [x] Guion en `docs/guion.md`
- [x] Abrir el proyecto en Godot y confirmar que corre sin errores

## Etapa 1: Prototipo jugable (un pasillo de Medicina)

Objetivo: probar si el juego da miedo antes de hacer el resto.

- [x] Lalo: movimiento desde arriba, caminar y correr
- [x] Linterna con cono de luz y oscuridad alrededor
- [ ] Pistola de clavos: apuntar, disparar, recargar, munición limitada
- [ ] Lanzar objetos que hacen ruido (`EventBus.ruido_emitido`)
- [ ] Maniquí: se acerca, escucha ruidos, se derriba con clavos
- [ ] Sistema de enemigos que regresan (sigue ahí / desaparece / cambia de posición)
- [ ] Clavar al piso para que no regrese
- [ ] Vida de Lalo y curación con vendas
- [ ] Cuarto seguro con guardado
- [ ] Radio con estática que sube cuando hay enemigos cerca
- [ ] Sonidos de prueba: pasos, clavos, maniquí, estática

## Etapa 2: Prólogo completo

- [x] Mapa de la entrada: caseta, estacionamiento, caminos, patio, edificios en C y obra (armado por código en `scripts/niveles/entrada.gd`)
- [x] Don Chava sentado en la caseta

- [ ] Mapa del prólogo: caseta, estacionamiento, obra y sótano del Edificio Central
- [ ] Sistema de diálogos y mensajes de radio
- [ ] Plática por radio con Don Chava
- [ ] El sótano: escalera derrumbada y linterna de Don Chava
- [ ] Llamada al Comandante y reja cerrada
- [ ] Mapa de rondines (pantalla del mapa)
- [ ] Puzzle: llave de la caja de herramientas
- [ ] Primer enfrentamiento con el maniquí

## Etapa 3: Capítulo 1, Medicina

- [ ] Mapa de Medicina (salones, sala de simulación, bodega de esqueletos, anfiteatro)
- [ ] Esqueletos (se rearman)
- [ ] Inventario completo con mochila de 8 espacios
- [ ] Documentos y libreta de Lalo
- [ ] Puzzle: completar el esqueleto de la vitrina
- [ ] Jefe: El Donante

## Etapa 4: Capítulo 2, Museo de Biología

- [ ] Mapa del museo
- [ ] Animales disecados (enemigos rápidos)
- [ ] Mensajes falsos del ente (`EventBus.mensaje_falso_resuelto`)
- [ ] Documento: mapa del pueblo de 1953
- [ ] Puzzle: años de colecta
- [ ] Jefe: La Bestia

## Etapa 5: Capítulo 3, La Obra

- [ ] Mapa del campamento de la obra
- [ ] Trabajadores (humanos, tiro a la cabeza)
- [ ] Trabajadores con tierra en los ojos (se levantan)
- [ ] Mochila táctica (12 espacios)
- [ ] Puzzle: generador
- [ ] Jefe: El Maestro de Obra

## Etapa 6: Capítulo 4, Bellas Artes

- [ ] Mapa de Bellas Artes y la explanada
- [ ] Estatuas y bustos
- [ ] Documento: acta de 1953
- [ ] Puzzle: bustos de los rectores
- [ ] Jefe: El Fundador (andamios y grúa)

## Etapa 7: Capítulo 5 y finales

- [ ] Túneles de servicio y pasadizo del pueblo
- [ ] Silbido de Don Chava como guía
- [ ] Puzzle: apellidos de las familias
- [ ] Jefe final: Tlalixco (con la vida de Don Chava)
- [ ] Escape acompañado de Don Chava
- [ ] Los tres finales

## Etapa 8: Pulido

- [ ] Arte final de personajes, enemigos y escenarios
- [ ] Música y sonido final
- [ ] Menú principal, pausa y opciones
- [ ] Pruebas con jugadores
- [ ] Exportar a Windows
