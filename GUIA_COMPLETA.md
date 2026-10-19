# Guía completa de los addons

Actualizada el **18 de octubre de 2026**. Esta guía describe la colección publicada; cada addon tiene también su propia guía con capturas, comandos y opciones.

## LUI: interfaz y efectos visuales

[Guía de LUI](LUI/README.md) · Versión declarada: 2.3.0.

- Marcos de moral y poder del jugador, objetivo, jefe, comunidad e incursión; objetivo del objetivo y estados de muerto o desconectado.
- Beneficios y perjuicios, efectos próximos a expirar y seguimiento de enfriamientos con filtros y umbrales.
- Marcos de grupo con aura del compañero seleccionado y aviso de moral baja; disposición de incursiones por grupos.
- Inventario opcional y enciclopedia de objetos con buscador, filtros de calidad, nivel y tipo.
- Artesanía: recetas, favoritos, ingredientes y planes por personaje.
- Barra de estado con hora, dinero, espacio de inventario, recursos y accesos a plugins.
- Carteles de misión y de zona con estilos regionales, auras, chispas y destellos.
- Puntero con anillo, halo, esferas, fuego, runas, mira o estela; colores, tamaño, opacidad y ayuda para encontrarlo.
- Aura del minimapa y efectos en el contorno de la barra de habilidades; colocación manual para adaptarlos a tu interfaz.
- Historial de botín de la sesión, filtros por rareza y aviso de objetos de calidad alta.
- Perfiles, escala, fuentes, colores y modo mover con cuadrícula.

Comandos principales: `/lui config`, `/lui move`, `/lui inventory`, `/lui craft`, `/lui encyclopedia`, `/lui raid`, `/lui puntero`, `/lui minimapa`, `/botin`.

La versión limpia retiró las ventanas Viaje y Bienes y sus accesos guardados. La enciclopedia actual se centra en objetos: no se presenta el antiguo bestiario como una función disponible.

## QuestSync: misiones, traducción y seguimiento

[Guía de QuestSync](LOTRO_Quest_Assistant/README.md).

- Base de misiones traducidas al español: nombres, diálogo y objetivos; consulta en español o inglés.
- Reconocimiento de aceptación, progreso, finalización y abandono mediante los mensajes del chat.
- Libro de misión estilo pergamino con diálogo, objetivos, botón de narración y efectos de fuego.
- Tracker flotante y redimensionable con misiones de la zona, contadores, colores, ocultación individual y acceso al destino.
- Consulta por área y zona, buscador por nombre u objetivo, etiquetas de repetición y señalización por nivel.
- Puntos de interés, cofres, tesoros, tropas, amenazas y colecciones.
- Identificación de misiones de grupo, mazmorras e incursiones, lugar en español e inglés y tamaño de grupo.
- **Buscar grupo** prepara un mensaje en inglés en el canal **LFF**, con el nombre exacto en inglés de la instancia, mazmorra o raid, tipo y tamaño. Se envía únicamente al pulsar el botón; solicita respuesta por privado.
- Botones de mapa y ruta para la integración con MoorMap y Waypoint cuando están instalados.
- Recolección por profesión y zona; guardado de puntos mediante la acción del jugador.
- Hazañas activas compartidas con Deed Tracker y marcadores compartidos con el Mapa del Mundo.
- Narración mediante la aplicación externa Narrador_IA; el addon envía el texto y la identidad del NPC, mientras la aplicación gestiona el audio.
- Diagnóstico de mensajes no reconocidos y guardado del seguimiento.

Comandos principales: `/questsync`, `/qs`, `/cofres`, `/recoleccion`, `/trackerfuego on`, `/trackerfuego off`, `/qsdiag`.

La detección depende del chat recibido y de los datos disponibles; no lee directamente todo el diario del juego. La voz requiere [Narrador_IA](https://github.com/sharshazo/Narrador_IA).

## Mapa del Mundo: exploración, objetivos y jefes

[Guía del mapa](WorldMap_Addon/README.md) · Versión declarada: **3.20.1**.

- Mapa general de la Tierra Media, búsqueda por zona o nivel, información regional, filtro de expansiones y resaltado por nivel.
- Mapas de zona, navegación entre mapas y fichas de lugares e iconos.
- Misiones activas, flechas de destino y acceso a las misiones de cada zona mediante QuestSync.
- Hazañas por zona, objetivos activos con aura y completados atenuados; sincronización con Deed Tracker.
- Capas para incursiones, mazmorras, jefes, exploración, hazañas, cofres, misiones, establos, campamentos, viajes, pesca, matanzas, historia, NPC, minería y fauna.
- Filtros guardados, opción de mostrar completados y nombres en español e inglés donde hay traducción disponible.
- Fichas de instancias y mapas interiores cuando están incluidos en los datos; no todas las salas y posiciones de jefes están confirmadas.
- Las misiones activas de esas fichas se pueden pulsar para abrir y seleccionar la misión exacta en QuestSync.
- Anillo original a la derecha de las misiones de zona y de instancia: enlace nativo al diario de LOTRO mediante el identificador real de la misión. Su activación debe comprobarse dentro del cliente y requiere que la misión esté aceptada.
- Posición del personaje con los mecanismos disponibles del juego y marcadores propios.
- Lanzador flotante para mapa, misiones y recolección.
- Recolección integrada: profesión, zona y puntos guardados por QuestSync. Pulsar un punto lo señala en el mapa; esta ventana utiliza los mapas incluidos sin exigir MoorMap.
- **Mecánicas de jefe por rol**: tanque, DPS o sanador, con selección automática o manual. Avisos para esquivar, separarse, agruparse, interrumpir, curar, usar defensas o prestar atención.
- Cuatro presentaciones de mecánicas: Auras, Lista, Flotantes y Central; tamaño, opacidad, máximo de iconos, aura anticipada, aviso grande, bloqueo y opción de mostrar solo en combate.
- **Alertas propias**: frases de combate con sugerencias de frases oídas, acción asociada y guardado por cuenta. Una frase desconocida no genera por sí sola una alerta nueva.

Comandos principales: `/mapa`, `/mapadelmundo`, `/mapa eregion`, `/mapa 50` y `/mapa jefe`.

Las mecánicas usan datos de BossCodex y PrimePlugins, el objetivo, efectos y mensajes reconocidos. Los avisos basados en chat dependen del puente de QuestSync. La cobertura depende del jefe y los datos; los tiempos anticipados son estimaciones y no garantizan el siguiente ataque.

## Deed Tracker: hazañas y recompensas

[Guía de Deed Tracker](CubePlugins/DeedTracker/README.md).

- Páginas regionales y de instancias, escaramuzas, pasatiempos, guerra, clase, raza y épica.
- Casillas manuales, progreso general y por página, fichas de hazañas y resolución de nombres ambiguos.
- Página **Por zona** que reúne hazañas regionales, de instancias y de reputación sin duplicar el progreso.
- Reconocimiento por chat de hazañas completadas; opción de completar también los requisitos previos.
- Recompensas, Puntos LOTRO y EXP de Virtud disponibles.
- Lista de completadas recientes e importación mediante la herramienta incluida para LOTRO Companion.
- Sincronización con el Mapa del Mundo y visualización de hazañas activas en el tracker de QuestSync.
- Icono minimizado configurable y guardado del progreso por personaje.

Comandos principales: `/deedtracker`, `/deed`, `/deeds` y `/dtmapa abrir <id>` para el acceso desde el mapa.

El plugin no puede leer directamente el diario de hazañas del juego: combina registros propios, chat, importación y marcas manuales.

## PvMP+ Revisited: seguimiento de JcJ

[Guía de PvMP+](PvMP_Plus_Revisited/README.md).

- Seguimiento de rango, renombre o infamia, menciones, bajas, muertes y estadísticas de sesión.
- Historial de golpes mortales, buscador y gráficas por días y meses.
- Fortalezas y puestos avanzados, auras y ventana de asedios.
- Botón **Help!** para compartir una llamada con posición y aviso pulsable que abre la marca en el mapa para otros usuarios del addon.
- Mapa de las Landas de Etten, llamadas de enemigos, últimas bajas y enemigos que te han golpeado.
- Gaergoth: icono de estado, temporizador guardado por servidor, aviso cinco minutos antes y control manual.
- Avisos de rastreo, sigilo, bajas, cofres, menciones y tareas de batalla.
- Barra de rango con estilos animados, colores, velocidades, marcos y auras; temas y bloqueo de ventanas.
- Rachas, mejor racha y rivales; marcas del mapa con duración restante.
- Interfaz española o inglesa y conservación de datos compatibles con la versión anterior.

Comandos principales: `/pvmp+ opciones`, `/pvmp+ mapa`, `/pvmp+ asedios`, `/pvmp+ rivales`, `/pvmp+ gaergoth muerto`, `/pvmp+ gaergoth activo`, `/pvmp+ idioma es`.

Help! y los avisos compartidos requieren otros usuarios compatibles. Si no se detecta la muerte de Gaergoth, se puede marcar manualmente. Los tiempos se basan en el registro del addon.

## Turbine y conexiones

`Turbine` es la librería compartida incluida en todos los paquetes individuales; no es un addon que se active por separado.

| Conexión | Función |
|---|---|
| QuestSync ↔ Mapa | Misiones, objetivos, idioma y puntos de recolección |
| Deed Tracker ↔ Mapa | Estado y acceso a hazañas por zona |
| Deed Tracker ↔ QuestSync | Hazañas activas y lectura compartida del chat |
| QuestSync → Narrador_IA | Solicitudes de lectura de misiones |
| LUI | Interfaz configurable y carteles que reconocen mensajes de misión |

## Descargar e instalar sin arrastrar archivos viejos

Las [descargas más recientes](https://github.com/sharshazo/Plugins/releases/latest) ofrecen **RAR y ZIP** de cada addon y de todos juntos. Los individuales incluyen Turbine.

1. Cierra LOTRO y extrae el paquete en una carpeta temporal.
2. En `Documentos\The Lord of the Rings Online\Plugins\`, reemplaza únicamente la carpeta del addon que actualizas. Reemplazarla completa evita conservar archivos retirados.
3. Para la colección completa reemplaza `LUI`, `LOTRO_Quest_Assistant`, `WorldMap_Addon`, `CubePlugins` y `PvMP_Plus_Revisited`, y copia también `Turbine`.
4. Conserva `PluginData` y las carpetas de otros addons. Si tu `CubePlugins` contiene otros plugins ajenos a este paquete, conserva esos componentes.
5. Activa los plugins desde el gestor del juego. No cambies los nombres ni agregues un nivel extra de carpetas.

Con OneDrive, la ruta suele ser `OneDrive\Documentos\The Lord of the Rings Online\Plugins\`.

## Créditos y alcance

LUI: Geldahr, MPL-2.0. Deed Tracker: Cube. PvMP+: Urundus; traducción alemana RenthoMar. Mecánicas de jefe: datos de BossCodex (Arebel) y PrimePlugins. Se conservan las licencias y atribuciones incluidas en cada carpeta.

Esta documentación se contrastó con los archivos incluidos. La publicación verifica las copias y los paquetes; no sustituye una prueba dentro de LOTRO de cada función o jefe.

## Comprobaciones del 18 de octubre de 2026

[Resultados y problemas pendientes](COMPROBACIONES_2026-10-18.md). Las pruebas automatizadas cubren escenarios concretos y no sustituyen una sesión completa dentro del juego.


## Actualización del 19 de octubre de 2026

El tamaño del botín de LUI vuelve al 100 %. Para cambiarlo: Opciones de LUI → Botín → Diseño → Tamaño del botín (%). Rango: 75–150; escribe 100 para restaurar el tamaño original. Guarda o aplica los cambios desde la ventana de opciones. La escala del botín es independiente del escalado global del juego. Se mantienen el historial y los avisos; durante ráfagas grandes se distribuye su creación entre varias actualizaciones.

Los marcos de raid que no corresponden a la vista elegida liberan sus conexiones y no siguen consultando efectos. El modo de movimiento y la alternancia entre ventanas combinadas y separadas se conservan.

El mapa incluye las correcciones recientes de asociaciones de misiones/instancias, apariencia de anillos y títulos, y avisos por destinatario. El usuario confirmó que el anillo abre la misión en el diario; la corrección visual requiere comprobarse en las distintas ventanas del cliente. QuestSync conserva el mensaje LFF con destino exacto en inglés.

[Comprobaciones, memoria medida y limitaciones conocidas](COMPROBACIONES_2026-10-19.md).


## Revisión 2 — rendimiento y paquetes actualizados (19 de octubre de 2026)

- **LUI:** party desactivada sin seguimiento de efectos; menos repintados de buffs/debuffs, señales y barras; consultas de fabricación con caché. Se conservan marcos, temporizadores, animaciones, raid y botín ajustable.
- **QuestSync / Quest Assistant:** progreso idéntico sin guardado repetido y refrescos de listas agrupados; las ventanas ocultas difieren su reconstrucción.
- **Mapa del Mundo:** sincronización de hazañas sin notificaciones repetidas cuando no cambia el estado.
- **PvMP+:** refresco visual agrupado durante combate y marcas caducadas sin repintado continuo; contadores conservados.
- **Descargas:** RAR y ZIP regenerados desde cero y verificados; solo se conservan los RAR de la versión actual.

[Comprobaciones y límites de las pruebas](COMPROBACIONES_2026-10-19.md). Las reducciones de llamadas se comprobaron en simulaciones; no equivalen a una medición de FPS en combate real.


### LUI

Marcos de party desactivados: liberan jugadores y dejan de consultar efectos. Barras de buffs/debuffs propios y del objetivo: evitan repetir colores, tamaños y texto sin cambios; mantienen renovación de efectos, temporizadores y los tres diseños con animaciones. El inventario de fabricación utiliza eventos y caché; las señales de curación evitan repintados idénticos. Se conservan los ajustes de botín (100 % inicial, rango 75–150 %), historial y vistas de raid.

### LOTRO_Quest_Assistant

El progreso idéntico ya no solicita guardado ni publicación repetidos. Los listados agrupan refrescos cercanos y difieren la reconstrucción mientras permanecen ocultos; los cambios de datos y su guardado se conservan. Se mantienen LFF en inglés con el destino exacto, enlaces de misiones y recolección.

### WorldMap_Addon

La consulta periódica de hazañas ya no vuelve a notificar el mismo estado sin cambios. Se mantienen confirmaciones, progreso, sincronización, señales, asociaciones verificadas de instancias y acceso a misiones. Las coordenadas aproximadas siguen marcadas como tales.

### PvMP_Plus_Revisited

Los eventos de combate agrupan la actualización visual de la ventana general en intervalos de 100 ms; los contadores se actualizan inmediatamente. Las marcas caducadas dejan de repintarse y se evita repetir texto o dimensiones sin cambios. No se modifican los canales de chat ni el registro de estadísticas.

### CubePlugins

Versión local actual, conservando sincronización y recuperación de guardados. Se vuelve a distribuir con Turbine y sin temporales; esta revisión no añade funciones a Deed Tracker.


## Revisión 3 — curas, habilidades y estabilidad (19 de octubre de 2026)

- **LUI:** menos trabajo repetido al curar en party y raid; etiquetas y bordes se actualizan cuando cambian. El aviso animado de vida baja conserva su pulso durante las curas.
- **Habilidades:** las reutilizaciones evitan limpiar casillas vacías en cada refresco y repetir tamaños o tiempos iguales. El seguimiento evita consultar buffs propios cuando no hay ninguno configurado para seguir.
- **PvMP+:** el aviso de menciones se sincroniza con la primera lectura de la cartera; los observadores de mochila conservan callbacks anteriores con claves nominales, numéricas y de función.
- **Turbine:** los temporizadores respetan la reprogramación propia o de otro temporizador y los cambios de gestor; se conserva el aislamiento de callbacks con errores.
- Se mantienen los arreglos anteriores de misiones, LFF en inglés, anillos, recolección, botín ajustable, señales y guardados. RAR y ZIP regenerados y verificados.

[Comprobaciones y límites](COMPROBACIONES_2026-10-19.md). Las pruebas no sustituyen una medición de FPS o cierres dentro del juego.

Para instalar esta revisión, cierra LOTRO, sustituye la carpeta del addon y actualiza también Turbine, incluido en cada paquete. Conserva PluginData y los demás addons. El botín mantiene el tamaño inicial 100 % y la opción de ajuste 75–150 %. Las actualizaciones de vida y escudos siguen siendo inmediatas; el ahorro se aplica al trabajo repetido.
