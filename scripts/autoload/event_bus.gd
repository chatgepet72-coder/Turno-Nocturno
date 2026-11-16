extends Node
## Señales globales para comunicar sistemas sin que dependan entre sí.
## Uso: EventBus.ruido_emitido.emit(global_position, 200.0)

## Un ruido en el mundo (objeto lanzado, disparo, puerta). Los enemigos lo escuchan.
signal ruido_emitido(posicion: Vector2, alcance: float)

## Empieza un mensaje de radio. es_real = false cuando habla el ente con la voz de Don Chava.
signal mensaje_radio(id: StringName, es_real: bool)

## El jugador siguió (true) o ignoró (false) las indicaciones de un mensaje del ente.
signal mensaje_falso_resuelto(id: StringName, lo_siguio: bool)

## Un enemigo quedó derribado. Lo usa el sistema de enemigos que regresan.
signal enemigo_derribado(enemigo: Node)

## Un enemigo fue clavado al piso o destruido y ya no regresa.
signal enemigo_eliminado_para_siempre(id_enemigo: StringName)

## El jugador entró a otra zona del campus.
signal zona_cambiada(zona: StringName)

## Se leyó un documento o nota.
signal documento_leido(id_documento: StringName)
