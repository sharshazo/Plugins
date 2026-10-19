# Comprobaciones del 19 de octubre de 2026 — revisión 3

Se reconstruyen las seis carpetas desde la instalación actual. Se excluyen copias de respaldo, temporales, guardados personales y exportaciones de desarrollo. Se conservan dependencias, recursos, licencias y guías. No se borran archivos del usuario en la instalación del juego.

## Correcciones incluidas

- LUI: Marcos de party desactivados: liberan jugadores y dejan de consultar efectos. Barras de buffs/debuffs propios y del objetivo: evitan repetir colores, tamaños y texto sin cambios; mantienen renovación de efectos, temporizadores y los tres diseños con animaciones. El inventario de fabricación utiliza eventos y caché; las señales de curación evitan repintados idénticos. Se conservan los ajustes de botín (100 % inicial, rango 75–150 %), historial y vistas de raid.
- LOTRO_Quest_Assistant: El progreso idéntico ya no solicita guardado ni publicación repetidos. Los listados agrupan refrescos cercanos y difieren la reconstrucción mientras permanecen ocultos; los cambios de datos y su guardado se conservan. Se mantienen LFF en inglés con el destino exacto, enlaces de misiones y recolección.
- WorldMap_Addon: La consulta periódica de hazañas ya no vuelve a notificar el mismo estado sin cambios. Se mantienen confirmaciones, progreso, sincronización, señales, asociaciones verificadas de instancias y acceso a misiones. Las coordenadas aproximadas siguen marcadas como tales.
- PvMP_Plus_Revisited: Los eventos de combate agrupan la actualización visual de la ventana general en intervalos de 100 ms; los contadores se actualizan inmediatamente. Las marcas caducadas dejan de repintarse y se evita repetir texto o dimensiones sin cambios. No se modifican los canales de chat ni el registro de estadísticas.
- CubePlugins: Versión local actual, conservando sincronización y recuperación de guardados. Se vuelve a distribuir con Turbine y sin temporales; esta revisión no añade funciones a Deed Tracker.

## Evidencia de las comprobaciones

- Distribución limpia: 600 fuentes Lua comprobadas con Lua 5.1 del cliente; verificación adicional de imports y recursos literales.
- Instalación: 714 fuentes Lua compiladas. Última revisión de efectos: 691.328 comprobaciones; salud, escudos e iconos: 71.291; estabilidad y guardados: 18 escenarios y 777.328 comprobaciones.
- Party: 400 ciclos de activación, desactivación, vista previa, ocultación del propio jugador y paso a raid. Raid: 1.600 cambios entre vista combinada, separada y desactivada, sin sondeo residual en marcos desactivados en la reproducción.
- Buffs/debuffs propios y del objetivo: 14.400 pasos por clase comparados con la versión anterior; idénticos tamaños y tiempos. En ese escenario las escrituras de color bajaron de 28.800 a 2 y las de geometría de 28.800 a 1.202 por clase. Son recuentos simulados de llamadas, no porcentajes de FPS.
- Diseños clásico, barras e iconos: 2.400 pasos por diseño y clase con renovaciones, cambios de efecto y animaciones.
- Memoria: 36.000 reemplazos de efectos por clase sin referencias residuales a efectos retirados; variación de memoria Lua de 0 KiB entre lotes equivalentes tras calentamiento. Los controles nativos fueron simulados.
- Gestores de efectos: 15.000 ciclos, conexiones compartidas y retirada de listeners; cero callbacks residuales en la reproducción.
- Fabricación: consultas redundantes de mochila reducidas en pruebas de 500 espacios y 300 pasos; se conservan eventos, consulta de recuperación y lectura forzada. La firma de inventario se reutiliza mientras no cambian los datos.
- Refrescos: cien eventos cercanos agrupan la reconstrucción del tracker en una; treinta sondeos iguales del mapa notifican una vez, conservando cambios reales y confirmaciones.
- Botín conserva tamaño inicial 100 %, control 75–150 %, límite de ventanas durante ráfagas, historial y cantidades.
- Los RAR y ZIP se crean nuevos; cada contenido extraído se compara por SHA-256 contra las carpetas publicadas.

## Límites conocidos

No se midieron FPS o tiempos de cuadro durante combate real, memoria gráfica ni memoria nativa de todos los controles. No se reprodujo ni se diagnosticó un cierre nativo mediante volcado. Estas pruebas no garantizan que desaparezcan todos los microcongelamientos o cierres.

Las ventanas de efectos activas aún consultan, filtran y ordenan efectos al ritmo configurado. El sondeo de seguridad y las animaciones habilitadas se conservan para no perder comportamiento cuando faltan eventos del cliente. Los datos aislados medidos en una auditoría anterior (aproximadamente 57,8 MiB de QuestSync y 26,1 MiB de LUI, más caché de búsqueda limitada) no son memoria total del cliente ni demuestran por sí solos una fuga.

El aviso inicial de menciones, las tablas de callbacks de mochila y la reprogramación cruzada/propia de temporizadores quedaron corregidos en esta revisión y pasaron sus reproducciones. Las posiciones de mapa deducidas visualmente no se consideran coordenadas exactas confirmadas.

Para instalar: cierra el juego, sustituye la carpeta anterior del addon y copia Turbine. Conserva PluginData y los addons ajenos; si CubePlugins contiene otros componentes, consérvalos. No se alteran guardados personales.


## Verificación conjunta de la revisión 3

- 23 conjuntos de pruebas aprobados, cero fallidos; 43 archivos corregidos coinciden con sus últimas versiones. Los 714 archivos Lua instalados compilan.
- Revisión estructural de 41 fuentes modificadas frente a respaldos anteriores: ninguna función con nombre eliminada. Las 600 fuentes de la distribución y los 2.836 recursos de ejecución revisados siguen presentes; siete entradas de carga válidas. Los siete cambios de parámetros conservan sus llamadas revisadas.
- Integración adicional con Class, Type, Table, Event, Timer y TimerManager reales: constructores, eventos, cambios de gestor/intervalo, autoeliminación y aislamiento de errores comprobados. El reloj y los controles nativos se simulan.
- Ocho pruebas de navegación mapa–Quest Assistant: misión exacta, ambos idiomas, clic derecho, destinos viejos, reutilización de filas, plegado, recorte y ausencia del addon de destino. Las filas permanecen opacas, como requiere la corrección de transparencia.
- Curas y habilidades: 974.298 comprobaciones. Dos mil casos de cambio de etiquetas; 800 casos de selección/hover/tamaño; 14.400 pasos de reutilizaciones y 3.600 pasos por cada uno de los tres diseños con sus animaciones. Veinte mil cambios de etiquetas sin crecimiento de memoria Lua retenida entre lotes equivalentes de la simulación.
- En 1.000 avisos con las mismas etiquetas, las escrituras de texto pasaron de 4.000 a 3 y las de colocación de 12.001 a 13. En 1.000 avisos de vida baja, las escrituras de geometría pasaron de 10.000 a 10. Son recuentos de llamadas simuladas, no porcentajes de mejora de FPS.
- Reproducciones de PvMP+ y Turbine: cuatro escenarios adicionales aprobados, incluyendo cien ciclos de callbacks, doscientos de reprogramación y diez mil altas/bajas de temporizadores sin referencias residuales en la prueba.

Los microcongelamientos y cierres nativos reales aún requieren validación en combate dentro de LOTRO. Tampoco se certifica la cobertura de cada misión o coordenada del mapa. Las pruebas conservan comportamientos concretos; no garantizan ausencia absoluta de errores.
