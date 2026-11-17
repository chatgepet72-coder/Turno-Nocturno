extends Node
## Señales globales para comunicar sistemas sin que dependan entre sí.
## Uso: EventBus.ruido_emitido.emit(global_position, 200.0)
## Las señales que todavía no usa ningún sistema llevan @warning_ignore para que Godot no avise.

## Un ruido en el mundo (objeto lanzado, disparo, puerta). Los enemigos lo escuchan.
@warning_ignore("unused_signal")
signal ruido_emitido(posicion: Vector2, alcance: float)

## Empieza un mensaje de radio. es_real = false cuando habla el ente con la voz de Don Chava.
@warning_ignore("unused_signal")
signal mensaje_radio(id: StringName, es_real: bool)

## El jugador siguió (true) o ignoró (false) las indicaciones de un mensaje del ente.
@warning_ignore("unused_signal")
signal mensaje_falso_resuelto(id: StringName, lo_siguio: bool)

## Un enemigo quedó derribado. Lo usa el sistema de enemigos que regresan.
@warning_ignore("unused_signal")
signal enemigo_derribado(enemigo: Node)

## Un enemigo fue clavado al piso o destruido y ya no regresa.
@warning_ignore("unused_signal")
signal enemigo_eliminado_para_siempre(id_enemigo: StringName)

## El jugador entró a otra zona del campus.
@warning_ignore("unused_signal")
signal zona_cambiada(zona: StringName)

## Se leyó un documento o nota.
@warning_ignore("unused_signal")
signal documento_leido(id_documento: StringName)
