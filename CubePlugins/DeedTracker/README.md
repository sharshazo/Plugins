<p align="center"><img src="media/logo.png" width="96" alt="Logo de Deed Tracker"></p>

# 🏆 Deed Tracker (versión en español)

Seguimiento de **hazañas** para **The Lord of the Rings Online**, con la base de datos de hazañas **en español**.

Es una **versión en español del addon original Deed Tracker de Cube** (v3.3.0, traducción de la interfaz de Heisenchad), con añadidos de esta colección: la página **«Por zona»** y la **conexión con el Mapa del Mundo**. Todo el mérito del addon original es de su autor (ver [Créditos](#requisitos-limitaciones-y-créditos)).

Nombre en el gestor de plugins: **Deed Tracker**

---

## Índice

1. [Progreso de hazañas](#1-progreso-de-hazañas)
2. [Página «Por zona»](#2-página-por-zona)
3. [Hazañas en el Mapa del Mundo](#3-hazañas-en-el-mapa-del-mundo)
4. [Detección automática por el chat](#4-detección-automática-por-el-chat)
5. [Recompensas y totales](#5-recompensas-y-totales)
6. [Hazañas completadas recientemente](#6-hazañas-completadas-recientemente)
7. [Importar desde LOTRO Companion](#7-importar-desde-lotro-companion)
8. [Icono minimizado](#8-icono-minimizado)
9. [Comandos](#comandos)
10. [Opciones y guardado](#opciones-y-guardado)
11. [Conexión con los otros addons](#conexión-con-los-otros-addons)
12. [Instalación](#instalación)
13. [Requisitos, limitaciones y créditos](#requisitos-limitaciones-y-créditos)

---

## 1. Progreso de hazañas

**Para qué sirve:** saber qué hazañas te faltan (o cuáles ya hiciste).

**Cómo se usa:** `/deedtracker` (o `/deed`, `/deeds`) abre la ventana principal. Las hazañas están en **10 páginas**, igual que el diario del juego: **Eriador, Rhovanion, Gondor, Mordor, Haradwaith, Instancias, Escaramuza, Pasatiempos, La Guerra y Clase/Raza/Épica**, cada una con sus pestañas.

**Detalles:**
- Cada hazaña con su **casilla** de completada; se puede marcar a mano.
- Tipos: clase, raza, evento, explorador, saber, reputación y matanza.
- **Barras de progreso** «Progreso de hazañas – General» y «– Esta página», con su ficha al pasar el ratón.
- Al pasar el ratón por una hazaña sale su **ficha** con la descripción y la información de la hazaña.
- Si un nombre coincide con varias hazañas, se abre una ventana para **elegir** cuál es.

![Lista de hazañas con su progreso y sus recompensas](media/progreso_hazanas.gif)

---

## 2. Página «Por zona»

Botón **«Por zona»** en la fila de abajo. Cada pestaña es una zona (las mismas zonas y en el mismo orden que Eriador, Rhovanion, Gondor, Mordor y Haradwaith) y junta **todo lo de esa zona**:

1. las hazañas propias de la zona;
2. **«== Instancias de la zona ==»**: las hazañas de las instancias e incursiones que están en esa zona;
3. **«== Reputación de la zona ==»**: las hazañas de las facciones de esa zona.

Son las **mismas hazañas** con el mismo guardado: marcar una en «Por zona» la marca en su página original, y la detección por el chat funciona igual. Los totales generales no cambian (nada se cuenta dos veces). Las 10 páginas de siempre siguen igual.

Quedan solo en su página original las de zona no confirmada (Ost Dunhoth, Iorbar's Peak, las instancias de Kingdoms of Harad y algunas facciones repartidas por varias zonas). Escaramuzas, Pasatiempos y La Guerra no son de una zona.

---

## 3. Hazañas en el Mapa del Mundo

**Para qué sirve:** ver en el mapa dónde están los objetivos de tus hazañas.

**Cómo funciona:**
- La ventana de cada zona del **Mapa del Mundo** tiene una pestaña **«Hazañas»** con las mismas hazañas de «Por zona». **Marcar una allí la marca aquí** (y al revés, en 1 o 2 segundos).
- **Clic en el nombre** de una hazaña en el mapa: Deed Tracker se abre **al instante** en esa hazaña (comando `/dtmapa`), con su descripción en una ventanita aparte.
- En el mapa de zona, los objetivos de las hazañas se ven **con aura** si la hazaña está activa y **en gris con X** si está completada (o se ocultan, según el filtro «Ver completadas» del mapa).
- Si Deed Tracker no está cargado, el mapa guarda los pedidos y se aplican al cargarlo.

![Hazañas activas con aura y completadas en gris con X en el mapa de zona](media/hazanas_mapa.gif)

---

## 4. Detección automática por el chat

LOTRO no deja a los addons leer el diario de hazañas, así que Deed Tracker **reconoce las hazañas por el nombre** cuando el chat dice «Hazaña completada: …» o «Completado: …», y la marca sola. Comparte el gancho del chat con QuestSync. Opcionalmente, al completar una hazaña marca también como completadas sus **hazañas previas**.

---

## 5. Recompensas y totales

- Contadores de **Puntos LOTRO** y **EXP de Virtud** disponibles, en total y en la página actual.
- Las hazañas muestran sus recompensas (títulos, reputación con su facción, etc.) en la ficha.

---

## 6. Hazañas completadas recientemente

Una ventana con las hazañas que completaste hace poco, con dos botones: **limpiar** la lista (no las desmarca) y **escribir un resumen** de tus hazañas recientes en el canal de chat Estándar.

---

## 7. Importar desde LOTRO Companion

Si usas la aplicación de escritorio **LOTRO Companion**, el archivo `ImportDeedCompletionFromLotroCompanion.hta` lee sus datos y Deed Tracker muestra una ventana de **Importación de LOTRO Companion** con las hazañas que LOTRO Companion considera completadas, para marcarlas de una vez («Importar hazañas completadas»). También tiene en cuenta las fechas de completado manuales.

---

## 8. Icono minimizado

Icono pequeño en pantalla para abrir la ventana. Se puede mostrar u ocultar y elegir su opacidad, forma y tamaño, y si queda siempre encima. **Clic derecho** abre las opciones del plugin.

---

## Comandos

| Comando | Qué hace |
|---|---|
| `/deedtracker`, `/deed` o `/deeds` | Abre o cierra la ventana principal. |
| `/dtmapa abrir <id>` | Abre Deed Tracker en esa hazaña (lo usa el Mapa del Mundo). |
| `/help deedtracker` | Ayuda del comando. |

---

## Opciones y guardado

**Opciones** (en las opciones del plugin):
- Ocultar hazañas completadas, barras de progreso completadas, hazañas que ya no se pueden completar por nivel y hazañas que no se pueden conseguir activamente.
- Marcar las hazañas previas al completar una.
- Límite de nivel de los servidores estándar y legendarios, servidor legendario y Velo de los Nueve.
- Opciones del icono minimizado.

**Guardado:**

| Qué | Dónde |
|---|---|
| Opciones de Deed Tracker | Por personaje |
| Hazañas completadas de cada personaje | Por servidor (un archivo por personaje) |
| Pedidos del Mapa del Mundo y su confirmación | Por personaje |

---

## Conexión con los otros addons

- **Mapa del Mundo:** pestaña Hazañas sincronizada en los dos sentidos, apertura instantánea con `/dtmapa` y estado de las hazañas (activa / completada) en el mapa de zona.
- **QuestSync:** comparten el gancho del chat; el tracker de QuestSync muestra las hazañas en curso.

---

## Instalación

1. Copia la carpeta `CubePlugins` (con `DeedTracker.plugin` y la carpeta `DeedTracker` dentro) en:
   ```
   Documentos\The Lord of the Rings Online\Plugins\
   ```
   Debe quedar `Plugins\CubePlugins\DeedTracker.plugin`.
2. En el juego, abre el gestor de plugins (**Opciones → Plugins** o `/pluginmanager`) y carga **Deed Tracker**.

---

## Requisitos, limitaciones y créditos

**Limitaciones conocidas**
- Deed Tracker reconoce las hazañas comparando el nombre que sale en el chat con su lista. Si un nombre está mal escrito en la lista o falta, no la reconoce.
- No todas las hazañas están en «Por zona» (ver arriba).

**Créditos**
- **Deed Tracker** es obra de **Cube** (CubePlugins). Traducción de la interfaz al español: **Heisenchad**. Web: <https://deedtracker.lifebeyondtheshire.com/> · Discord de CubePlugins: <https://discord.gg/Vj2ERg3ZHJ>.
- El autor original agradece a Galuhad y Hytbold Assistant, Berry's Completionist Tracker, Reminders, TitanBar, DailyTasks, Garan y MinstrelBuffs, Thurallor, Lyrical, Vindar, FowlMap, Damien y LotRO Companion, y Lunarwater, y a sus probadores (ver `readme.txt`).
- Los añadidos de esta colección («Por zona», conexión con el Mapa del Mundo y `/dtmapa`) no cambian el funcionamiento original.
