# Comprobaciones de la publicación del 19 de octubre de 2026

Las seis carpetas se sustituyeron desde la instalación actual: LUI, LOTRO_Quest_Assistant, WorldMap_Addon, CubePlugins, PvMP_Plus_Revisited y Turbine. Se excluyen respaldos, temporales, guardados personales y exportaciones de desarrollo; se conservan licencias, atribuciones y documentación.

## Verificaciones

- Compilación de los 600 archivos Lua de la distribución limpia con la biblioteca Lua 5.1 del cliente instalado.
- Revisión integral de 714 archivos instalados, incluidos respaldos con extensión Lua: sin errores de sintaxis ni dependencias/recursos literales faltantes.
- Diecisiete conjuntos de pruebas de estabilidad, guardados, localización, anillos, LFF, recolección, señales, botín y marcos de raid completados en la auditoría. El ajuste posterior de tamaño también pasó pruebas de perfiles existentes/nuevos, lectura/escritura del control, límites, alineación y conservación de los ajustes de rendimiento.
- 14.974 misiones y 1.448 misiones de grupo examinadas. Los destinos contrastados por identificador no se sustituyen por referencias narrativas incidentales.
- Señales: 6.000 encuentros simulados, 144.000 eventos de efectos y 48.000 avisos flotantes; 37 controles simulados estables tras el calentamiento.
- Historial: 32.000 objetos distintos; límite de 300 entradas y cantidades conservadas. Conexiones de efectos: 15.000 ciclos sin callbacks residuales en la reproducción.
- Ráfaga de 1.000 objetos: con cuatro filas, máximo de ocho ventanas de botín coexistentes con animación y cuatro sin animación; hasta cuatro ventanas nuevas por actualización.
- Bases de datos aisladas: QuestSync retuvo aproximadamente 57,8 MiB; LUI, 26,1 MiB, más 4,2 MiB de caché limitada a 64 búsquedas. Son datos de Lua, no memoria nativa total del cliente.
- Los RAR y ZIP se crean desde cero; sus archivos extraídos se comparan mediante SHA-256 con las carpetas publicadas.

## Limitaciones conocidas

1. QuestSync solicita guardado y refresco aun si recibe el mismo progreso. Cien llamadas iguales produjeron cien solicitudes en una reproducción aislada. Optimización pendiente.
2. PvMP+ sigue actualizando el fondo de las marcas caducadas: doce marcas ocultas producen 720 solicitudes por minuto en la reproducción; el conjunto tiene límite de doce. Optimización pendiente.
3. Se conservan las limitaciones anteriores de PvMP+ (aviso inicial de moneda y cierto formato de callback de mochila) y de Turbine (reprogramación cruzada de temporizadores). No se presentan como corregidas en esta publicación.
4. Windows registra un cierre de LOTRO el 16 de octubre en lua51.dll; no identifica el addon responsable. No hubo cierres posteriores en los registros consultados el 19 de octubre. No se examinó un volcado ni se reprodujo un cierre nativo.
5. Las pruebas usan servicios y controles simulados y la biblioteca Lua real del cliente. No certifican FPS, memoria nativa, todas las interacciones del juego ni la ausencia total de errores. Las coordenadas visuales aproximadas siguen siendo aproximadas.

No se modificaron PluginData ni los guardados de los personajes para preparar los paquetes.
