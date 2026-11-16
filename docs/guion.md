# Turno Nocturno: guion

Copia del guion al 16 de noviembre de 2026. La versión editable está en Claude Docs: https://claude.ai/artifact/Xu8neJuqMM1EkVfbXT9MiG. Si cambian algo allá, actualicen también este archivo.

## Ficha del juego

**Turno Nocturno** es un survival horror en 2D para Godot: un velador busca a su compañero en un campus universitario vacío durante una sola noche, mientras algo enterrado bajo la universidad empieza a moverse.

| Campo | Definición |
| --- | --- |
| Género | Survival horror con suspenso y combate limitado |
| Vista | 2D desde arriba (top-down), con iluminación muy cerrada |
| Duración estimada | 5 a 7 horas |
| Personajes | Solo Lalo y Don Chava, más la voz del Comandante |
| Escenario | Un campus universitario en vacaciones de diciembre |
| Tiempo de la historia | Una noche, de las 22:00 al amanecer |

**Premisa:** Lalo, de 25 años, estudia Ingeniería Civil y trabaja de velador nocturno para pagar la colegiatura. Una noche, su compañero Don Chava entra al sótano sellado que la obra encontró bajo el edificio más viejo del campus y no regresa. Lalo no se va sin él.

**Pilares del juego:**

- **Soledad:** el jugador está solo casi todo el tiempo. La voz de Don Chava por radio aparece solo en momentos específicos.
- **Desconfianza:** los enemigos derribados pueden desaparecer y volver en otro lugar, y no todo lo que dice el radio es verdad.
- **Recursos escasos:** los clavos se acaban y hay que distraer con objetos para sobrevivir.
- **Una amistad:** todo lo que hace Lalo es para salir con Don Chava.

## Personajes

**Lalo (Eduardo Mendoza), 25 años.** Estudia Ingeniería Civil y trabaja de velador nocturno en el campus para pagar la colegiatura. Es nervioso, bromista y habla solo para calmarse. Conoce el campus de memoria por los rondines. Ve a Don Chava como un segundo papá.

**Don Chava (Salvador), 50 a 55 años.** Lleva casi 30 años de velador en la universidad. Es tranquilo, curioso y algo necio. Le dice "mijo" a Lalo y cada noche comparten una torta en la caseta. Está casado con Lupita. Su curiosidad por el sótano sellado es lo que desata la historia.

**El Comandante.** Es el jefe de vigilancia y solo se le oye por radio. Contesta la llamada de auxilio de Lalo con mucha interferencia: le dice que no salga del campus y que van para allá. Al final aparece en la reja con una patrulla, al amanecer, porque venía en camino desde esa llamada.

**Detalles que solo Don Chava sabe** (sirven para distinguir su voz real de la del ente):

- Le dice "mijo", nunca "Eduardo".
- Menciona a su esposa Lupita.
- Bromea con la torta de cada noche: "¿de qué la trajiste hoy?".
- Silba la misma canción en los rondines. El silbido aparece en cuatro momentos: el rondín del prólogo, de fondo en algunos mensajes reales por radio, en los túneles del Capítulo 5 cuando el radio ya no sirve, y en la patrulla del final bueno.

## El mundo

El campus se construyó en 1953 encima del pueblo de San Miguel Tlalixco, y la tierra negra que ahora sube es ese pueblo que quiere de vuelta su tierra y cuerpos para caminar.

**El campus en vacaciones.** Es diciembre y el campus está casi vacío, pero no abandonado: hay cafés a medio tomar, carteles de eventos, un proyector encendido en un salón y celulares olvidados.

**La obra.** La universidad está demoliendo el **Edificio Central**, el más viejo, para construir el nuevo Centro de Investigación. Hay rejas con lonas ("Disculpe las molestias"), andamios, una grúa, maquinaria y la caja de herramientas donde está la pistola de clavos. Al tumbar el piso del sótano, los trabajadores encontraron un muro de ladrillo y cal que no sale en ningún plano.

**Lo que pasó en 1953.** La universidad compró el terreno y desalojó al pueblo. Los que se negaron a irse se refugiaron en la capilla. Una noche "hubo un derrumbe durante la obra" y la capilla quedó enterrada con ellos adentro. Construyeron el campus encima y nadie volvió a hablar de eso. El jugador lo descubre con documentos, fotos y notas.

**El mapa del pueblo bajo el campus.** Es un documento de historia, no un mapa para orientarse: se ve una sola vez en el Capítulo 2. Puesto encima del mapa del campus, muestra que cada facultad está sobre un lugar del pueblo:

| Zona del campus | Lugar del pueblo debajo |
| --- | --- |
| Edificio Central | La capilla y su cripta |
| Facultad de Medicina | La plaza del pueblo |
| Museo de Biología | Los corrales y el monte |
| La Obra (campamento) | Las casas de los que se negaron a irse |
| Explanada de Bellas Artes | La casa del cacique que vendió las tierras |

**La tierra negra.** Es la firma del ente. Escurre de las articulaciones de todo lo que mueve, deja rastros en los pasillos y se acompaña de un sonido grave, como un latido bajo el piso.

**Lo que no aparece nunca:** virus, laboratorios, trajes contra químicos, corporaciones ni equipos de limpieza.

## Reglas del juego

**El radio.**

- La tierra negra interfiere la señal. Donde hay mucha tierra solo hay estática. En las zonas limpias (los cuartos seguros, algunos puntos clave) la voz de Don Chava regresa.
- La estática sube cuando un enemigo está cerca, así que el radio es compañía y alarma a la vez.
- Mensajes **reales** de Don Chava: dicen "mijo", traen bromas y advertencias escondidas. Mensajes **del ente**: dicen "Eduardo", repiten frases exactas y llevan a trampas.

**El combate.**

- Arma principal: **pistola de clavos** de la obra. Los clavos son escasos.
- Humanos: mueren con varios disparos al cuerpo o pocos a la cabeza. Los tiros a la cabeza los derriban más rápido y a veces los aturden.
- Humanos con **tierra en los ojos**: los que el ente ocupó a fondo. Pueden levantarse otra vez.
- Maniquíes y esqueletos: se derriban con clavos y el combate termina ahí, pero pueden volver.
- Otras herramientas: **extintor** (aturde y abre espacio), **bengalas** (luz y fuego), clavos largos y latas explosivas.

**Los objetos para lanzar.** Botellas, latas, piedras y frascos. El ente sigue el ruido, así que lanzar algo lejos sirve para distraer y pasar sin gastar clavos. También se puede lanzar el celular con la alarma puesta, pero se pierde.

**Los enemigos que regresan (maniquíes, esqueletos y algunos humanos).** Al salir de una zona y volver, un enemigo derribado:

1. Sigue ahí, igual que antes.
2. Ya no está, y solo queda una marca de tierra negra o un rastro de arrastre. Reaparece más adelante en otro lugar.
3. Está en otra posición: más cerca de la puerta, sentado o mirando hacia donde viene Lalo.

Los cambios nunca pasan frente al jugador ni pegados a un cuarto seguro. Para que un enemigo no vuelva nunca, hay que gastar clavos extra y **clavarlo al piso**, o destruirlo por completo (aplastarlo o quemarlo).

**Guardar.** En los cuartos seguros: casetas de vigilancia con lámpara y radio con señal.

**El mapa.** Lalo toma el mapa de rondines del campus en la caseta al empezar. Es el único mapa para orientarse y se va marcando con zonas visitadas, puertas cerradas y cuartos seguros.

## Enemigos y jefes

| Enemigo | Dónde aparece | Cómo se comporta | Cómo se enfrenta |
| --- | --- | --- | --- |
| Maniquíes de RCP | Medicina y en adelante | Lentos, en grupo, se arrastran | Clavos o distracción. Regresan |
| Esqueletos de anatomía | Medicina, museo | Frágiles y rápidos | Clavos. Se rearman y regresan |
| Animales disecados | Museo de Biología | Muy rápidos, atacan de frente | Clavos y objetos para desviarlos |
| Trabajadores de la obra | La Obra y en adelante | Humanos con casco y herramientas | Varios disparos o pocos a la cabeza |
| Trabajadores con tierra en los ojos | Capítulo 3 en adelante | Igual, pero se levantan | Rematar o clavar al piso |
| Estatuas y bustos | Bellas Artes | Lentas, los clavos casi no les hacen daño | Esquivar o tirarles algo encima |

| Jefe | Capítulo | Qué es | Cómo se pelea |
| --- | --- | --- | --- |
| El Donante | 1, Medicina | Cuerpos donados fusionados con maniquíes, con muchos brazos | Clavar sus brazos a las mesas de disección y disparar al centro |
| La Bestia | 2, Museo de Biología | Jaguar disecado con astas de venado y alas de aves | Lanzar objetos para que embista contra vitrinas y pilares |
| El Maestro de Obra | 3, La Obra | El encargado que ordenó romper el muro, con marro y tierra en los ojos | Tiros a la cabeza. Se levanta varias veces |
| El Fundador | 4, Bellas Artes | La estatua de bronce del fundador que ordenó el desalojo | Usar la obra: andamios, grúa y vigas |
| Tlalixco (final) | 5, la cripta | La masa de tierra del pueblo, con Don Chava atrapado en el centro | Destruir las raíces sin darle a Don Chava |

## Inventario y objetos

La mochila empieza con 8 espacios y sube a 12 con la mochila táctica del Capítulo 3. Lo que no cabe se guarda en el locker de cada cuarto seguro.

| Objeto | Para qué sirve | Espacios |
| --- | --- | --- |
| Vendas | Curan poco y detienen el sangrado | 1 |
| Alcohol | Con vendas cura más; con una lata hace un explosivo | 1 |
| Botiquín | Cura toda la vida. Es muy raro | 1 |
| Analgésicos | Quitan el aturdimiento y el temblor de la mira | 1 |
| Caja de clavos | 10 clavos para la pistola | 1 por caja |
| Clavos largos | Más daño y atraviesan a dos enemigos | 1 por caja |
| Lata explosiva | Lata + alcohol. Explota al chocar | 1 |
| Extintor | Aturde a los enemigos cercanos. 3 usos | 2 |
| Bengala | Luz por 30 segundos y quema enemigos | 1 |
| Pilas | Recargan la linterna | 1 |
| Botellas, latas y piedras | Se lanzan para distraer. Hasta 3 por espacio | 1 |
| Llaves y objetos de puzzle | Abren puertas y resuelven puzzles | 0 |
| Documentos y notas | Se guardan en la libreta de Lalo | 0 |

Siempre lleva, sin ocupar espacio: la pistola de clavos, la linterna, el radio y el mapa de rondines. El alcohol sirve para curarse o para hacer explosivos: el jugador decide.

## Puzzles

| Capítulo | Puzzle | Recompensa |
| --- | --- | --- |
| Prólogo | Encontrar la llave de la caja de herramientas en la caseta de la obra | La pistola de clavos |
| 1, Medicina | Completar el esqueleto de la vitrina con tres huesos (cráneo, fémur, mano) de distintos salones | Llave del anfiteatro |
| 2, Museo | Juntar el año de colecta de las placas de tres animales | Combinación de la bodega de taxidermia |
| 3, La Obra | Encender el generador con diésel y un fusible. El ruido atrae enemigos | Corriente para la reja de la maquinaria |
| 4, Bellas Artes | Girar los bustos de los rectores en el orden de sus fechas para que miren al Fundador | Archivo con el acta de 1953 y llave de la explanada |
| 5, Túneles | Abrir la puerta de piedra con los apellidos de tres familias de las fotos | Paso a la cripta |

## Prólogo: el rondín

Dura unos 20 minutos y no tiene combate: termina cuando Lalo toma la pistola de clavos y el primer maniquí se le acerca.

1. **El turno normal (tutorial).** 22:00. Lalo y Don Chava en la caseta, comiendo su torta. Lalo toma el mapa de rondines. Cada uno hace su rondín. El jugador aprende a moverse, usar la linterna y el radio, y ve la obra.
2. **La plática por radio.**

> **DON CHAVA:** Oye, mijo… ¿tú sabes qué hay abajo del Central? Lo que encontraron los de la obra.
> **LALO:** Ni idea, Don Chava. Dijeron que nadie se meta hasta que venga Protección Civil.
> **DON CHAVA:** Treinta años trabajando aquí y nunca supe que había otro sótano. Lo sellaron con ladrillo, Lalo. Uno no sella algo que no quiere esconder.
> **LALO:** Pues por algo será. No se meta, ¿eh?
> **DON CHAVA:** Nomás me asomo. No me tardo.
> **LALO:** Don Chava… no sea necio.
> **DON CHAVA:** Ahorita te hablo.

3. **Don Chava deja de contestar.** Solo estática.
4. **El sótano del Central.** Muro roto, escalera de piedra derrumbada y la linterna de Don Chava encendida apuntando a los escombros. Aire frío, una respiración lenta, un hilo de tierra negra.

> **LALO:** ¿Don Chava?… ¡Don Chava! ¿Me oye?
> *(la respiración se detiene)*

5. **Algo cambió arriba.** Apagón, rastros de tierra, un maniquí sentado en una banca que luego ya no está. Nada ataca.

> **LALO:** Alguien me está jugando una broma… ¿verdad?

6. **La llamada al Comandante.**

> **LALO:** ¡Comandante! Don Chava se metió al sótano del Central y no contesta, ¡algo pasó!
> **COMANDANTE:** …Mendoza… no te… entiendo… se corta…
> **LALO:** ¡Necesito ayuda! ¡Mande a alguien!
> **COMANDANTE:** …no salgas del campus… vamos para…
> *(estática)*
> **LALO:** ¿Comandante?… ¿Me escucha?…

Sin señal de celular. La pluma de la reja no responde por el apagón.

7. **La voz de Don Chava.**

> **DON CHAVA:** …Lalo… mijo, ¿me oyes?… No sé dónde estoy… huele a alcohol, como a hospital… Hay muchas camillas… Ven por mí, Lalo. No me dejes aquí.

8. **La pistola de clavos.** Lalo la saca de la caja de herramientas de la obra. *"Nomás por si acaso…"*
9. **El primer enfrentamiento.** El maniquí de la banca está parado en un pasillo de Medicina. Se mueve hacia Lalo.

## Capítulo 1: Medicina

**Zona:** salones, sala de simulación, bodega de esqueletos, anfiteatro. **Objetivo:** llegar al anfiteatro.

1. **Primer maniquí.** Se derriba con clavos; al volver, ya no está. Se aprende la regla de los que regresan.
2. **Sala de simulación.** Maniquíes en camillas que no se mueven mientras la linterna los alumbra.
3. **Primer objeto para lanzar.** Una botella para alejar a un grupo de la puerta.
4. **Cuarto seguro: caseta de Medicina.**

> **DON CHAVA:** Mijo… ¿ya trajiste la torta? *(risa débil)* Hace mucho frío aquí. Hay unos muñecos que se mueven, Lalo… no les des la espalda.

5. **Bodega de esqueletos.** Uno cae y se rearma.

**Documento:** *"Día 12: Encontramos un muro que no sale en los planos. Mañana lo tiramos."*

**Jefe: El Donante.** Clavar sus brazos a las mesas y disparar al centro.

**Final:** la gorra de Don Chava sobre una camilla, con tierra.

> **DON CHAVA:** …ya no estoy ahí, mijo… me movieron… ahora veo animales… muchos ojos de vidrio… que no parpadean…

## Capítulo 2: Museo de Biología

**Zona:** sala de mamíferos, sala de aves, bodega de taxidermia, vitrina del jaguar. **Objetivo:** encontrar a Don Chava entre "los animales de ojos de vidrio".

1. **Vitrinas.** Al volver a pasar, algunas están rotas y vacías.
2. **Enemigos rápidos.** Venado y coyotes; se aprende a desviarlos con objetos.
3. **Primer mensaje falso.**

> **RADIO (voz de Don Chava):** Eduardo. Ven a la bodega de abajo. Aquí estoy.

Es una trampa. Le dijo "Eduardo", no "mijo".

4. **Cuarto seguro: oficina del curador.**

> **DON CHAVA:** …mijo, si te digo que vayas abajo… no me hagas caso… no siempre soy yo…

**Documento clave:** mapa de San Miguel Tlalixco (1953) y foto de familias frente a la capilla.

**Jefe: La Bestia.** Hacerla embestir contra vitrinas y pilares; disparar cuando queda aturdida.

> **DON CHAVA:** …ahora huele a cemento… se oyen máquinas, mijo… hay cascos tirados…

## Capítulo 3: La Obra

**Zona:** campamento (oficina, dormitorio de contenedores, bodega), maquinaria y andamios. **Objetivo:** encontrar a Don Chava entre "los cascos tirados".

1. **Los trabajadores.** Primeros enemigos humanos; tiro a la cabeza.
2. **Tierra en los ojos.** Uno se vuelve a levantar.
3. **Dormitorio de contenedores.** Silencio total, sin música.
4. **Cuarto seguro: oficina de la obra.**

> **DON CHAVA:** Mijo… ¿te acuerdas que te dije que Lupita me hace la torta con frijoles? Ya ni hambre tengo… no sé cuánto aguante.

**Documentos:**

> *"Día 13: Los muchachos dicen que se oye algo detrás del ladrillo. Puras supersticiones."*
> *"Día 14: Ya lo abrimos. Hace mucho frío ahí abajo."*
> *"Día 15: Ramírez y Polo no vinieron hoy. Dicen que tienen tierra en las uñas que no se les quita."*

**Jefe: El Maestro de Obra.** Cubrirse tras las máquinas y apuntar a la cabeza. Si se le remata, se queda en el piso.

> **RADIO:** …está la estatua… la del señor que fundó todo… está viendo hacia acá, mijo…

## Capítulo 4: Bellas Artes

**Zona:** talleres de escultura, galería de bustos, bodega del teatro, explanada del Fundador. **Objetivo:** llegar a la explanada.

1. **Galería de bustos.** Cuando la linterna se aparta, alguno cambia de dirección.
2. **Estatuas que caminan.** Esquivar, distraer o tirarles algo encima.
3. **Bodega del teatro.** Maniquíes con ropa de campesino de los años 50.
4. **Cuarto seguro: cabina de luces.** Primera vez sin señal.

**Documento clave:** acta firmada por el Fundador: *"Los habitantes que se nieguen a desalojar serán retirados por los medios necesarios. La obra no se detiene."* Recorte de periódico: *"Derrumbe en la obra de la Ciudad Universitaria. Sin víctimas que lamentar."*

**Jefe: El Fundador.** Atraerlo bajo andamios y grúa; tirarle vigas y costales de cemento.

**La revelación:**

> **RADIO (voz de Don Chava):** Ya casi llegas, Eduardo. Ven. Aquí estoy.
> *(estática, y de pronto la voz real, débil)*
> **DON CHAVA:** …no, mijo… no vengas… ya no soy yo el que te habla… me tiene… abajo…

Bajo la estatua rota hay una tapa de registro de los túneles.

## Capítulo 5: Túneles y cripta

**Zona:** túneles de servicio, pasadizo de piedra del pueblo, cripta de la capilla. **Objetivo:** llegar a la cripta por otro camino.

1. **Túneles.** Sin escondites. Regresan los enemigos que no se clavaron al piso.
2. **Pasadizo del pueblo.** Nichos, flores de papel, fotos de 1953.
3. **Radio muerto.** Solo estática. Lo único que guía a Lalo es el silbido de Don Chava.
4. **La cripta.** La masa de tierra que respira, con Don Chava vivo en el centro.

> **LALO:** ¡Don Chava!
> **DON CHAVA:** *(apenas)* …te dije que no vinieras, mijo…
> **LALO:** Y yo le dije que no se metiera. Estamos a mano.

**Jefe final: Tlalixco.** Destruir las raíces sin darle a Don Chava; su barra de vida está en pantalla. Al caer todas, la masa lo suelta, se ven caras en la tierra, un sonido grave se apaga y la cripta se derrumba.

## Escape y finales

**El escape.** Don Chava no puede correr. Él carga la linterna; Lalo dispara. Si Lalo se aleja mucho, se queda a oscuras.

**La reja.** Amanece. El Comandante está con una patrulla.

> **COMANDANTE:** ¡Mendoza! ¿Qué pasó aquí? ¿Y Don Chava?
> **LALO:** Aquí está, Comandante. Aquí está.

| Final | Condición | Qué pasa |
| --- | --- | --- |
| Fin de turno (bueno) | Don Chava con más de la mitad de su vida | Salen los dos. En la patrulla, Don Chava pregunta: "¿Y la torta, mijo? ¿De qué la trajiste hoy?". Lalo se ríe. La cámara se acerca: Don Chava tiene tierra negra en la oreja y se la limpia sin darse cuenta |
| Turno incompleto (malo) | Don Chava con la mitad de su vida o menos | Don Chava muere en los túneles. Lalo llega solo. El Comandante pregunta "¿Y Don Chava?" y Lalo no contesta |
| El otro turno (secreto) | Don Chava vivo y el jugador siguió la mayoría de los mensajes falsos | Todo parece el final bueno, pero en la patrulla Don Chava dice: "Ya estamos a salvo, Eduardo". Lalo se queda callado. Corte a negro |

## Pendientes

- [ ] ¿Qué canción silba Don Chava? Melodía original o de dominio público.
- [ ] Plano de cada zona, piso por piso (al diseñar los niveles en Godot).
