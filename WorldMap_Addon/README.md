<p align="center"><img src="media/logo.gif" width="220" alt="Logo animado del Mapa del Mundo"></p>

# 🗺️ Mapa del Mundo (WorldMap_Addon)

Mapa interactivo de la Tierra Media para **The Lord of the Rings Online**, en **español** (con nombres en inglés donde ayudan), que se conecta con **QuestSync (Quest Assistant)** y **Deed Tracker** para mostrar en vivo tus misiones activas, tus hazañas y los lugares importantes de cada zona.

Versión actual: **3.7.1** · Nombre en el gestor de plugins: **Mapa del Mundo**

![Captura real del Mapa del Mundo abierto en el juego](media/captura_juego.jpg)

---

## Índice

1. [Mapa del mundo](#1-mapa-del-mundo)
2. [Misiones activas en el mapa](#2-misiones-activas-en-el-mapa)
3. [Buscador de zonas y misiones](#3-buscador-de-zonas-y-misiones)
4. [Ventana de la zona: Misiones y Hazañas](#4-ventana-de-la-zona-misiones-y-hazañas)
5. [Mapa de zona, iconos y filtros](#5-mapa-de-zona-iconos-y-filtros)
6. [Hazañas en el mapa](#6-hazañas-en-el-mapa)
7. [Mazmorras e incursiones](#7-mazmorras-e-incursiones)
8. [Tu personaje en el mapa](#8-tu-personaje-en-el-mapa)
9. [Auras y animaciones](#9-auras-y-animaciones)
10. [Marcadores propios](#10-marcadores-propios)
11. [Filtro de expansiones y resaltado por nivel](#11-filtro-de-expansiones-y-resaltado-por-nivel)
12. [Icono flotante (lanzador)](#12-icono-flotante-lanzador)
13. [Ventana del mapa](#13-ventana-del-mapa)
14. [Comandos](#comandos)
15. [Opciones y guardado](#opciones-y-guardado)
16. [Conexión con los otros addons](#conexión-con-los-otros-addons)
17. [Instalación](#instalación)
18. [Requisitos, limitaciones y créditos](#requisitos-limitaciones-y-créditos)

---

## 1. Mapa del mundo

**Para qué sirve:** ver de un vistazo toda la Tierra Media (Eriador, Rhovanion, Rohan, Gondor, Mordor, Harad…) con **59 zonas**, cada una dibujada con su borde real, su **nombre en español** y su **rango de nivel** debajo.

**Cómo se usa:**
- **Pasa el ratón** por una zona: se ilumina con un borde brillante y aparece una ficha flotante con su nombre, nivel, una descripción corta, la **expansión** que la añadió al juego (por ejemplo «Minas de Moria (2008)»), el número de **misiones activas** que tienes allí y tus **hazañas** de la zona (por ejemplo «Hazañas 12/45»).
- **Haz clic** en una zona (sin arrastrar): se abre su **mapa de zona** dentro de la misma ventana y, al lado, la lista de tus misiones activas en esa zona.
- **Arrastra** con el botón izquierdo para mover el mapa.

**Detalles:**
- Las zonas vecinas comparten el borde exacto, así el ratón siempre cae en una sola zona.
- **Colores por volumen épico**: rojo = El Legado de Angmar, naranja = Minas de Moria, amarillo = Aliados del Rey, verde = La Fuerza de Sauron, celeste = El Libro Negro de Mordor, azul = El Legado de Durin, violeta = Umbar/Harad, gris = Páramos Etten (JcJ), turquesa = contenido nuevo estimado. Hay una **leyenda** abajo a la izquierda.
- Los nombres van en blanco con contorno negro, partidos en renglones para que no se corten.
- El mapa se dibuja siempre a su **tamaño real** (no se estira): lo que cambia al agrandar la ventana es la parte visible.

![Continente con zonas, nombres y niveles; zona iluminada con su ficha y flechas de misiones activas](media/mundo_misiones.gif)

---

## 2. Misiones activas en el mapa

**Para qué sirve:** saber dónde tienes misiones pendientes sin abrir el diario.

**Cómo funciona:** con QuestSync cargado, junto al nombre de cada zona donde tienes misiones activas aparece una **flecha dorada animada con el número de misiones**. Si alguna de esas misiones es de grupo, aparecen además:
- una **puerta de mazmorra** con aura (mazmorra o instancia de grupo de 3 o 6);
- una **calavera de incursión** con fuego y ojos que laten (incursión de 12 o más).

Las escaramuzas, las batallas épicas y las misiones de grupo en zona abierta no ponen puerta ni calavera. Al pasar el ratón sobre la puerta o la calavera sale el nombre de la mazmorra o incursión en **español e inglés**.

**Detalles:**
- Los marcadores se actualizan solos al **aceptar, avanzar, completar o abandonar** una misión: QuestSync avisa al mapa y este se pone al día enseguida.
- Botón **Actualizar**: las misiones activas que QuestSync no vio moverse en **7 días** quedan en gris y no cuentan en las flechas.
- Las zonas ocultas por el filtro de expansiones no muestran marca.

![Flechas doradas con el número de misiones, puerta de mazmorra y calavera de incursión animadas](media/mundo_misiones.gif)

---

## 3. Buscador de zonas y misiones

**Para qué sirve:** encontrar rápido una zona o una misión.

**Cómo se usa:** escribe en la caja de búsqueda de arriba del mapa.
- **Texto** (por ejemplo «moria»): resalta las zonas cuyo nombre coincide y mueve el mapa a la primera.
- **Un número** (por ejemplo «50»): resalta las zonas cuyo rango de nivel incluye ese nivel.
- **Misiones** (3 letras o más, en español o inglés, las activas primero): un clic en el resultado lleva a su zona, la resalta y pone un **pin dorado con «!»** sobre el nombre de la zona (un clic en el pin la abre en QuestSync). El botón **Abrir** la abre directamente.
- En los resultados, cada misión de mazmorra, incursión, instancia o escaramuza muestra debajo el nombre del lugar en los dos idiomas, por ejemplo: *Mazmorra: La Decimosexta Sala (The Sixteenth Hall)*.

También puedes buscar desde el chat con `/mapa <texto>` (ver [Comandos](#comandos)).

---

## 4. Ventana de la zona: Misiones y Hazañas

Al hacer clic en una zona se abre a su lado una ventana con dos pestañas:

**Misiones**
- Tus misiones **activas** en esa zona. Un clic en una la abre en QuestSync.
- Las misiones de grupo llevan el logo de grupo de QuestSync y, si corresponde, la puerta de mazmorra o la calavera de incursión en pequeño.
- Una **X** al final de cada misión: el primer clic pide confirmar («Quitar») y el segundo la desmarca en QuestSync (igual que su botón Desmarcar): deja de estar activa en el mapa, el tracker y el libro.

**Hazañas**
- Todas las hazañas de la zona en 3 secciones (de la zona, Instancias y Reputación), cada una con su %, y una barra de % total arriba.
- Cada hazaña tiene una **casilla** para marcarla a mano. «Ver: pendientes / todas» oculta las ya hechas.
- Un **clic en el nombre** abre Deed Tracker filtrado en esa hazaña, con su descripción en una ventanita aparte.
- Las casillas están **sincronizadas con Deed Tracker**: marcar en el mapa la marca en Deed Tracker y lo que marques en Deed Tracker se ve en el mapa en 1 o 2 segundos. Si Deed Tracker no está cargado, las marcas quedan guardadas y se aplican al cargarlo.
- Si la zona no tiene misiones activas, la ventana se abre directamente en Hazañas.

---

## 5. Mapa de zona, iconos y filtros

**Para qué sirve:** ver dentro de cada zona los lugares importantes en su **posición exacta del juego**.

**Cómo se usa:**
- El mapa de zona es la **imagen del propio cliente del juego** y aparece dentro de la misma ventana.
- **Clic en el nombre de un mapa vecino** (por ejemplo «hacia las Tierras de Bree»): viajas a ese mapa.
- **Clic derecho**: vuelves al mapa anterior y, desde el primero, al mapa del mundo.
- Las flechas **◀ ▶** de la barra de arriba recorren los mapas de la zona.
- **Pasa el ratón** sobre un icono: se ilumina y sale su ficha en español (e inglés) con su estado y su progreso.

**Filtros:** dentro de una zona, la fila de arriba muestra la **barra de filtros**; el botón **Filtros** abre el panel completo **«Filtros del Mapa»** (4 columnas × 5 filas, en español o inglés según el botón ES/EN de QuestSync). Un clic en cada cuadro muestra u oculta esa clase de iconos. La elección **se guarda**.

| Filtro | Qué marca | Al empezar |
|---|---|---|
| Raids | Entradas de incursiones | Encendido |
| Mazmorras | Entradas de mazmorras | Encendido |
| Jefes | Jefes con nombre | Encendido |
| Exploración | Puntos de exploración de las hazañas | Encendido |
| Hazañas | Todo lo que forma parte de una hazaña | Encendido |
| Cofres y tesoros | Cofres | Encendido |
| Misiones | Lugares de tus misiones activas | Encendido |
| Establos blancos / Establos azules | Establos normales y de largo alcance | Encendido |
| Campamentos | Campamentos | Encendido |
| Puntos de viaje | Puntos de viaje | Encendido |
| Pesca | Lugares de pesca | Encendido |
| Matar monstruos | Zonas de hazañas de matar monstruos | Apagado |
| Historia y saber | Lugares de historia | Apagado |
| NPC | NPC de servicio | Apagado |
| Minería | Vetas | Apagado |
| Fauna | Fauna | Apagado |
| Ver completadas | Opción: muestra lo ya completado en gris con X | Apagado |

Las ciudades grandes se ven siempre, con su aura. Cada icono tiene una punta abajo: la **punta** queda en el lugar exacto.

![Mapa de las Tierras de Bree: los filtros se encienden uno a uno, hazañas activas con aura y completadas en gris con X, flecha sobre la mazmorra con misiones](media/zona_iconos.gif)

![Todos los iconos de los filtros del mapa](media/iconos.png)

---

## 6. Hazañas en el mapa

**Para qué sirve:** ver qué hazañas de la zona llevas empezadas y cuáles ya hiciste.

**Cómo funciona:**
- **Activa (con aura):** la hazaña tuvo **progreso**. LOTRO no avisa a los addons qué hazañas están empezadas, así que el mapa lee el **chat de misiones** (el mismo que leen QuestSync y Deed Tracker): si un aviso nombra una hazaña o uno de sus objetivos (en inglés o en español), esa hazaña queda activa.
- **Completada (gris con X):** lo que ya guardan Deed Tracker (hazañas completadas de ese personaje) y QuestSync («encontrado» de colecciones y cofres), y lo que el mapa ve en el chat («Completado: <hazaña>»). Si un aviso nombra un objetivo (un lugar descubierto), ese icono queda completado.
- Las completadas **no se ven** salvo que enciendas **«Ver completadas»**.
- En la ficha del icono aparece el progreso de la hazaña cuando se conoce (por ejemplo «Progreso: 3/8»).
- Si en una sesión no está cargado Deed Tracker o QuestSync, el mapa usa la última copia guardada de sus datos.

![Hazañas activas con aura y completadas en gris con X en el mapa de zona](media/zona_iconos.gif)

---

## 7. Mazmorras e incursiones

**Para qué sirve:** ver por dentro las instancias donde tienes misiones.

**Cómo se usa:**
- En el mapa de zona, las mazmorras e incursiones donde tienes misiones activas llevan **aura** y una **flecha dorada que sube y baja** con el número de misiones.
- Al pasar el ratón sale la lista de tus **misiones activas en ese lugar**.
- **Clic** en una mazmorra o incursión: se abre su **mapa interior** (imagen del propio cliente; ◀ ▶ recorren sus plantas) y una **ficha a color** con partes, niveles, número de jugadores, «Misiones activas aquí» y sus jefes. Sin mapa interior se ve solo la ficha. **Clic derecho** vuelve al mapa de la zona.
- **Jefes con nombre** marcados en el mapa interior con su icono (cabeza de orco con corona) y su nombre en español, solo donde el marcador del propio juego cae en ese mapa. Se ven con el filtro «Jefes».
- Si una misión activa nombra a un jefe (en sus objetivos o en su nombre), la **flecha dorada lo señala**.

![Mapa interior del Castillo del Rey Brujo con sus jefes y la flecha sobre el jefe de la misión](media/mazmorra_jefes.gif)

---

## 8. Tu personaje en el mapa

**Para qué sirve:** ver en qué zona estás.

**Cómo se usa:** con los botones **Hombre / Mujer** de la fila de arriba eliges la figura (guerrero o guerrera). La figura aparece **en la zona donde estás**, con su **anillo de luz animado** bajo los pies (naranja para Hombre, rosa para Mujer). Al pasar el ratón dice «Estás aquí».

**Cómo sabe la zona:** la API de LOTRO no da la posición del jugador, así que el mapa usa lo que QuestSync ya sabe y gana lo más reciente:
- el aviso del canal **Regional** al entrar en una región;
- la zona de la misión que aceptas, avanzas o completas;
- al empezar, la última zona guardada.

Sin QuestSync no se muestra la figura.

![Botones Hombre y Mujer y la figura con su anillo animado en la zona donde estás](media/personaje.gif)

---

## 9. Auras y animaciones

Las marcas del mapa tienen **auras animadas**: flechas de misión, puertas de mazmorra, calaveras de incursión con fuego, ciudades, cofres y jefes. Están hechas para verse bien sobre el arte del mapa sin tapar los nombres. Los establos no llevan aura, y las mazmorras e incursiones del mapa de zona solo la llevan si tienes misiones activas allí. El logo de la ventana también tiene su aura, destello y estrellas.

---

## 10. Marcadores propios

- **Clic derecho** en cualquier punto del mapa del mundo: se abre un cuadro para escribir una nota (por ejemplo «comprar reactivos aquí»). Al guardarla aparece un **pin dorado** en ese punto.
- **Clic izquierdo** en un pin: muestra u oculta tu nota.
- **Clic derecho** en un pin: te deja borrarlo.
- Se guardan solos, **por personaje**.

---

## 11. Filtro de expansiones y resaltado por nivel

- **Expansiones…** (arriba a la derecha): un menú para marcar qué expansiones tienes. Las zonas de las que no marques se ocultan; el contenido base nunca se oculta. Es un filtro **manual**: el juego no deja a los addons saber qué compraste. Al principio está todo marcado. Se guarda **por cuenta**.
- **Resaltado por nivel:** las zonas cuyo rango incluye el nivel de tu personaje se ven con relleno más fuerte y un marco dorado en el nombre. Se recalcula cada vez que abres el mapa.

---

## 12. Icono flotante (lanzador)

- En pantalla queda un **icono redondo** del mapa (35 px).
- **Clic:** despliega a su lado los iconos **Mapa del Mundo** y, si QuestSync está cargado, su **Libro** (misiones y tracker) y su **Lupa** (Recolección). Al elegir uno, la fila se recoge. Si el icono está pegado al borde derecho de la pantalla, la fila se abre hacia la izquierda.
- **Arrastrar:** mueve el icono. **Clic derecho:** bloquea o desbloquea la posición.
- Mientras el Mapa del Mundo está cargado, los iconos sueltos de QuestSync se ocultan; vuelven solos al descargar el mapa.

---

## 13. Ventana del mapa

- Ventana **redimensionable desde el borde**; el mapa se mueve arrastrándolo.
- Banner **«MAPA DEL MUNDO»** arriba, siempre centrado.
- Recuerda **posición, tamaño y hacia dónde estaba movido el mapa** (por personaje).

---

## Comandos

| Comando | Qué hace |
|---|---|
| `/mapa` o `/mapadelmundo` | Abre o cierra el mapa. |
| `/mapa <texto>` | Abre el mapa con esa búsqueda ya hecha (por ejemplo `/mapa eregion`). |
| `/mapa <número>` | Abre el mapa resaltando las zonas de ese nivel (por ejemplo `/mapa 50`). |

Para ponerle una tecla, crea una macro con el texto `/mapa` y arrástrala a una barra de acciones.

---

## Opciones y guardado

Todo se guarda con el sistema de datos de plugins de LOTRO:

| Qué | Dónde |
|---|---|
| Posición, tamaño y desplazamiento de la ventana, figura elegida y última zona | Por personaje |
| Marcadores propios | Por personaje |
| Posición del icono flotante y si está bloqueado | Por personaje |
| Progreso de hazañas visto en el chat y copia de los datos de Deed Tracker / QuestSync | Por personaje |
| Expansiones marcadas | Por cuenta |
| Filtros del mapa y posición del panel de filtros | Por cuenta |

---

## Conexión con los otros addons

- **QuestSync (Quest Assistant):** el mapa lee tus misiones **activas**, sus objetivos y sus lugares; QuestSync le avisa al aceptar, completar o abandonar. Desde el mapa puedes abrir una misión en QuestSync o desmarcarla. El idioma del panel de filtros sigue el botón ES/EN de QuestSync.
- **Deed Tracker:** casillas de hazañas sincronizadas en los dos sentidos; clic en una hazaña abre Deed Tracker en ella (comando `/dtmapa`); las completadas se ven en gris con X.
- **LUI:** funciona por separado; su icono no se puede agrupar en el lanzador del mapa.
- Si un addon no está cargado, el mapa sigue funcionando igual, solo sin esos datos.

---

## Instalación

1. Copia la carpeta `WorldMap_Addon` (y la carpeta `Turbine`, que también necesita) dentro de:
   ```
   Documentos\The Lord of the Rings Online\Plugins\
   ```
2. En el juego, abre el gestor de plugins (**Opciones → Plugins** o `/pluginmanager`) y carga **Mapa del Mundo**.
3. Busca el icono redondo del mapa en pantalla.

---

## Requisitos, limitaciones y créditos

**Requisitos**
- La carpeta `Turbine` dentro de `Plugins`.
- Opcional pero recomendado: **QuestSync** (misiones, personaje y libro) y **Deed Tracker** (hazañas).

**Limitaciones conocidas**
- La API de LOTRO no da la posición del jugador: la figura solo sabe la **zona**, no el punto exacto.
- El filtro de expansiones es manual.
- El estado «activa» de las hazañas depende de los avisos del chat.
- Las posiciones de los jefes solo se muestran donde el marcador del juego está confirmado en ese mapa.

**Créditos**
- Las imágenes de los mapas de zona e interiores son las del propio cliente del juego; la navegación entre mapas sigue el mismo sistema que **MoorMap**.
- Datos de misiones de **QuestSync** y de hazañas de **Deed Tracker** (de Cube).
- Los iconos, auras y figuras son diseños del autor de esta colección.
