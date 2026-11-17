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
- [x] Pistola de clavos: apuntar, disparar, recargar, munición limitada
- [ ] Lanzar objetos que hacen ruido (`EventBus.ruido_emitido`)
- [x] Maniquí: se acerca, escucha ruidos, se derriba con clavos
- [ ] Sistema de enemigos que regresan (sigue ahí / desaparece / cambia de posición)
- [ ] Clavar al piso para que no regrese
- [x] Vida de Lalo y curación con vendas
- [x] Cuarto seguro con guardado (caseta de Medicina) y menú Continuar / Nueva partida
- [ ] Radio con estática que sube cuando hay enemigos cerca
- [ ] Sonidos de prueba: pasos, clavos, maniquí, estática

## Etapa 2: Prólogo completo

- [x] Mapa de la entrada: caseta, estacionamiento, caminos, patio, edificios en C y obra (armado por código en `scripts/niveles/entrada.gd`)
- [x] Don Chava sentado en la caseta

- [ ] Mapa del prólogo: caseta, estacionamiento, obra y sótano del Edificio Central
- [x] Sistema de diálogos y mensajes de radio (con voces de murmullo y efecto de radio)
- [x] Escena inicial: plática en la caseta, Don Chava se levanta y sale a su rondín
- [x] Plática por radio con Don Chava
- [x] Don Chava deja de contestar (Lalo lo llama con Q)
- [x] Apagón, tierra negra en los caminos y el maniquí en la banca que luego ya no está
- [x] El sótano: escalera derrumbada y linterna de Don Chava
- [x] Llamada al Comandante y reja cerrada
- [ ] Mapa de rondines (pantalla del mapa)
- [x] Caja de herramientas en la caseta con la pistola de clavos (sin llave)
- [x] Primer enfrentamiento con el maniquí

## Etapa 3: Capítulo 1, Medicina

- [x] Planta baja de Medicina: pasillo largo y 16 cuartos con arte del equipo
- [x] Transición de puertas al estilo Resident Evil (rechinido y pasos)
- [ ] Planta alta de Medicina (bodega de esqueletos, anfiteatro, morgue)
- [ ] Esqueletos (se rearman)
- [x] Mochila de 8 espacios, objetos para recoger, documentos y menú de pausa con controles
- [x] Puertas con llave y puertas que no abren; cadena de puzzles (Consultorio → Archivo → Máquinas → Escaleras)
- [x] Ala oeste: el pasillo da vuelta
- [x] Control (PlayStation/Xbox) con luz y vibración
- [x] Bombas molotov (vendas + alcohol)
- [x] Notas de la historia, cosas para examinar y emboscadas en Medicina
- [x] Choque con muebles: sala de simulación (camillas) y Salón 104 (círculo de sillas)
- [x] Choque con los muebles del resto de los cuartos (`data/medicina_muebles.json`)
- [x] Personajes al doble dentro de Medicina para que cuadren con los muebles; letreros en las puntas del pasillo
- [x] Hueco en la pared: Cuarto de máquinas → Bodega (encargo de la nota del velador)
- [x] Maniquíes escondidos que saltan si no los ves; golpes detrás de puertas cerradas; mensaje falso del ente
- [x] Tensión: latido y estática del radio cuando hay un enemigo cerca; maniquí más rápido con embestida
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
