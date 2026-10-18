# Comprobaciones de esta publicación

La publicación del 18 de octubre de 2026 contiene las versiones locales actualizadas de LUI, QuestSync, Mapa del Mundo, Deed Tracker, PvMP+ y la biblioteca Turbine. Los paquetes excluyen copias de respaldo, archivos temporales y borradores. Conservan las licencias, atribuciones, recursos y guías.

## Qué se ha comprobado

- Compilación de los archivos Lua con la biblioteca Lua 5.1 del cliente instalado.
- Existencia de los puntos de entrada de los manifiestos, importaciones literales y recursos literales.
- Dieciocho pruebas aisladas de estabilidad y guardados, trece de selección de misiones e iconos del mapa y dieciséis escenarios previos de regresión.
- Mensajes LFF: 5.172 comprobaciones, incluidas 1.448 misiones de grupo. Nombre de destino y mensaje en inglés.
- Identificadores de las 14.974 misiones de la base instalada.
- 13.578 posiciones de capas y conectores del mapa, y las correcciones verificadas de 66 misiones.
- Integridad de los nuevos archivos de descarga y correspondencia con las carpetas publicadas.

Las pruebas de funciones usan servicios y controles simulados. No prueban todas las ventanas, animaciones, combates o mecánicas dentro de LOTRO, ni certifican ausencia total de errores. Las posiciones deducidas de imágenes conservan su indicación de aproximadas.

## Problemas conocidos que siguen pendientes

Estos problemas se conservan como limitaciones conocidas; esta publicación no los presenta como corregidos:

1. **PvMP+: aviso de moneda al cargar.** Si la cantidad guardada y la cartera actual están a lados distintos del umbral configurado, el aviso puede conservar el estado anterior hasta que cambie otra vez la cantidad.
2. **PvMP+: callback anterior de mochila.** Cuando el evento anterior es una tabla con funciones bajo claves no numéricas, el observador actual no ejecuta esas funciones. No ocurre con todos los formatos de callback.
3. **PvMP+: marcas vencidas.** Los controles ocultos de marcas de enemigos siguen recibiendo actualizaciones de fondo cada segundo. El pool está limitado a doce; no se demostró crecimiento ilimitado de memoria ni se midió el impacto en FPS.
4. **Turbine: reprogramación cruzada.** Un temporizador ya incluido en la lista de vencidos puede ejecutarse aunque otro callback lo reprograme hacia el futuro antes de su turno. No se ha demostrado que afecte una mecánica concreta de esta instalación.

## Anillo del diario original

El título de la misión abre QuestSync. El anillo contiene un enlace nativo `QuestRef:DID` al identificador real de la misión. La apertura del diario original y la zona de clic del icono siguen pendientes de confirmación dentro del cliente. La misión debe estar aceptada; si no aparece en el diario del personaje, el cliente puede mostrar la última misión seleccionada.

Documentación del mecanismo: [Lotro UI Tags](https://www.lotrointerface.com/forums/showthread.php?p=8643) y [enlaces nativos en etiquetas](https://www.lotrointerface.com/forums/archive/index.php/t-3828.html).
