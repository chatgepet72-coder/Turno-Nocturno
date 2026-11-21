# Plan de adaptación

Cómo juntar la historia entregada (El Último Cuatrimestre) con la jugabilidad de nuestra versión anterior, para que el juego no sea solo correr y esconderse. Fecha: 21 de noviembre de 2026.

## 1. La historia entregada (no se cambia)

- **Inicio:** última semana del cuatrimestre. Lalo, estudiante agotado, va a Dirección a entregar un trámite urgente. Se queda dormido en la sala de espera a las 23:59. Despierta a medianoche: la salida ya no está, en su lugar hay una pared de archiveros.
- **El Archivero:** el estrés académico hecho entidad. Alto, sin rostro: en su lugar un sello de goma rojo que gira. Cuerpo de actas cosidas; arrastra carpetas que suenan a clips. No ve: detecta por ruido y actividad (correr, abrir cajones de golpe, dejar puertas abiertas). No ataca: "sella" el expediente y vuelve Eco a su víctima. **No hay combate directo contra él.**
- **Cordura:** baja al ser detectado o al cometer errores. En cero, Lalo se vuelve un Eco: pantalla de "expediente cerrado" y reinicio en el último punto seguro.
- **Los Ecos:** alumnos que "causaron baja" y nunca salieron.
  - La de Cómputo: repite una tecla en un monitor roto. Ayuda si se corrige su bucle; delata si se le asusta.
  - El de Talleres: carga una maqueta sin terminar. Hostil si Lalo toca lo que no es suyo.
  - La Prefecta: el Eco más antiguo, ligado a Rectoría. Da pistas a cambio de recuerdos.
- **Niveles:** 1, Dirección y área administrativa (tutorial, breakers, Archivero lento). 2, Laboratorios de Cómputo y Talleres (monitores con glitch, cables que hacen ruido). 3, Aulas y Rectoría (pasillos que se repiten, el salón 204 corrupto, reunir tres firmas).
- **Finales:** escapar solo con su expediente, o liberar a los Ecos con el Sello Roto (más difícil).
- **Objetos del documento:** linterna del celular (batería limitada), llave maestra, extintor (ciega al Archivero), grapadora y objetos para lanzar (ruido), termo de café (cordura), gafete de prefectura (pasar una vez sin ser visto).
- **Coleccionables:** fragmentos de expediente, memorias de los Ecos (USB, maqueta, identificación), actas selladas, el Sello Roto.

El código actual de esta rama ya agregó cosas que no están en el documento (Don Chuy en la caseta, la USB enterrada, el reporte). Se pueden conservar mientras no contradigan el documento.

## 2. La idea: referencia The Evil Within

Se toman ideas de mecánica (mundo dentro de una mente, combate con recursos escasos, quemar enemigos caídos, cuarto seguro con mejoras, un perseguidor que no se puede matar). **No** sus nombres, personajes, lugares ni arte.

**Giro propuesto (pendiente de confirmar con el equipo):** Lalo se desmayó de agotamiento en la sala de espera y está internado. La escuela es su mente tratando de "cerrar el expediente", o sea rendirse. Se cuelan pistas: pitido de monitor, voces de enfermeras, luz de hospital en los glitches. Alternativas: el sistema de expedientes de la escuela, o dejarlo ambiguo.

## 3. Jugabilidad que se agrega (pendiente de confirmar)

- **El Archivero sigue intocable:** solo se aturde (extintor), se distrae o se evita.
- **Enemigos nuevos que sí se enfrentan**, hechos de papel y presión escolar: las "Bajas" (alumnos archivados; usan la IA y el arte de los maniquíes de `main`), expedientes que se arrastran, estatuas de egresados.
- **El fuego es su debilidad.** Un encendedor quema a los caídos para que no regresen.
- **Armas escolares:** pistola de clavos o engrapadora neumática de Talleres; molotov (alcohol del laboratorio + trapo); trampa eléctrica (baterías + cables de Cómputo); extintor; grapadora para lanzar; regla de metal o compás para golpear. Tipos de munición: normal, al rojo (quema), con descarga (aturde).
- **Pelear hace ruido y atrae al Archivero:** cada encuentro se decide entre sigilo y pelea.
- **Cuarto seguro:** la sala de espera donde se durmió. Ahí está la Prefecta; con "créditos" se mejoran cordura, cargador, batería y sigilo.
- **Un jefe por Eco:** "El Examen" (Cómputo), "La Maqueta" (Talleres), "El Reglamento" (Prefecta). El final contra el Archivero es escape y Sello Roto, no pelea.
- **Cambios de realidad:** pasillos que cambian mientras caminas, aulas que cambian de número, el hospital un segundo.
- **Don Chava (opcional):** el guardia que encontró a Lalo desmayado y llamó a la ambulancia; en la mente es la voz del radio que lo mantiene cuerdo.

## 4. Sistemas de `main` que se pueden traer

| De `main` | Para qué sirve aquí |
| --- | --- |
| Oscuridad (`CanvasModulate`) y cono de linterna | Linterna del celular con batería |
| Pantalla de salud (sangre, desaturación, latido) y luz del control | Medidor de Cordura |
| Estática del radio que sube con enemigos cerca | Crujido de papel y sello del Archivero acercándose |
| Maniquí: escucha ruidos, embiste, escondidos que saltan | Base de las Bajas y del oído del Archivero |
| Pistola de clavos, clavos, recarga | Engrapadora o pistola de clavos de Talleres |
| Molotov (vendas + alcohol) y fuego que quema enemigos | Molotov y encendedor contra enemigos de papel |
| Mochila, menú de pausa, documentos, "examinar" | Coleccionables y notas |
| Puertas con llave, cadena de puzzles, huecos, golpes tras puertas | Llave maestra, breakers, sustos |
| Transiciones de puerta estilo Resident Evil, guardado, control con vibración | Se quedan igual |

Archivos en `main`: `scripts/jugador/lalo.gd`, `scripts/enemigos/maniqui.gd`, `scripts/objetos/molotov.gd` y `clavo.gd`, `scripts/ui/pantalla_vida.gd`, `menu_pausa.gd`, `transicion_puerta.gd`, `scripts/niveles/medicina.gd`.

## 5. Pendiente de decidir

- [ ] El giro: desmayo y hospital, sistema de la escuela, o ambiguo.
- [ ] Enemigos de papel que le temen al fuego: sí o no.
- [ ] Qué se queda de lo agregado en esta rama (Don Chuy, USB, reporte).
- [ ] Si entra Don Chava y cómo.
