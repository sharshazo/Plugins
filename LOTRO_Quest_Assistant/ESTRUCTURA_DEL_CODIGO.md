# Estructura del Código — QuestSync (`LOTRO_Quest_Assistant`)

**Addon:** `LOTRO_Quest_Assistant` (nombre final/interno: **QuestSync**)
**Autor:** Cube (también autor de WarbandsSlayer y DeedTracker, ambos reutilizados/integrados aquí)
**Última actualización de este documento:** 2026-08-20.

Este archivo vive DENTRO de la carpeta del addon (se copia junto con todo lo demás en cada `deploy.py`) para que la estructura y el historial de bugs queden guardados con el propio addon, no solo en apuntes externos. Describe el estado ACTUAL del código: qué hace cada archivo, cómo se conectan entre sí, y por qué está construido así — no es una bitácora cronológica completa (eso vive en la memoria de la sesión de desarrollo), pero sí resume los bugs reales más importantes y por qué se resolvieron como se resolvieron.

---

## 1. Qué hace el addon

QuestSync lee el chat de LOTRO en tiempo real, detecta cuándo el jugador acepta, avanza, completa o abandona una misión, y muestra esa información en español (traducción profesional del cliente, nunca traducción automática) en una ventana única con pestañas (más un HUD chico flotante). Permite saltar directo a la ubicación de cualquier misión, punto de interés, amenaza o colección usando dos addons ya existentes — **MoorMap** (mapa con marcador) y **Waypoint** (flecha direccional) — sin que el jugador escriba el comando a mano. También se integra con **DeedTracker** (mismo autor): comparte el gancho de chat y muestra las proezas en curso de ese addon en su propio Tracker.

LOTRO no permite que un addon ejecute comandos de chat por código directamente. El mecanismo "click en un botón → se abre MoorMap/Waypoint" pasa por un truco: cada botón visible tiene, escondido detrás y del mismo tamaño, un `Turbine.UI.Lotro.Quickslot` invisible con un `Shortcut` (alias) ya cargado con el comando exacto. Al hacer click, LOTRO ejecuta el shortcut como si el jugador lo hubiera tecleado.

## 2. Estructura de carpetas

```
LOTRO_Quest_Assistant/
├── QuestSync.plugin                  # manifest (unico -- ver §10, duplicado borrado 2026-09-05)
├── Main.lua                          # orquestador: orden de carga, /questsync, /cofres, chat hook compartido
├── ESTRUCTURA_DEL_CODIGO.md          # este archivo
├── Core/
│   ├── EventBus.lua                  # namespace _G.LQA, pub/sub, LQA.Debug.Enabled
│   ├── QuestEventParser.lua          # detecta ACEPTADA/PROGRESO/COMPLETADA/ABANDONADA en chat
│   ├── QuestDiag.lua                 # registro de lo NO detectado + comando /qsdiag (ver §7.10)
│   ├── QuestLocResolver.lua          # texto de chat -> ndx (con desambiguación), NormalizeES
│   ├── QuestStateManager.lua         # única fuente de verdad del estado (activa/completada/rastreada)
│   ├── LanguageSettings.lua          # toggle ES/EN, persistido, publica LANGUAGE_CHANGED
│   ├── GroupQuest.lua                # misiones de grupo: color/icono/textos compartidos (ver §7.6)
│   ├── QuestTags.lua                 # Diaria/Semanal + "apropiada para tu nivel" (ver §7.7)
│   ├── NavigationParser.lua          # NO usado (ver §8)
│   ├── QuestManager.lua              # NO usado (legacy, ver §8)
│   └── QuestResolver.lua             # NO usado (legacy, ver §8)
├── Data/
│   ├── QuestDatabase.lua             # loader maestro: importa los 10 bloques de abajo
│   ├── QuestDatabase_001..010.lua    # catálogo de las 14.824 misiones (id, ndx, area, zone, nivel, prev/next...)
│   ├── GroupQuestDB.lua              # id -> tamaño de grupo oficial + mazmorra/raid/zona (1.448 misiones, ver §7.6)
│   ├── QuestLockDB.lua               # id -> Diaria/Semanal/Quincenal oficial (2.093 misiones, ver §7.7)
│   ├── QuestNameIndex.lua            # nombre EN (minúscula) -> ndx
│   ├── QuestZoneIndex.lua            # índice por zona (EN)
│   ├── QuestNameESIndex_Full.lua     # nombre ES -> lista de ndx candidatos (base completa, 14.824)
│   ├── QuestNameESIndex_Lv1_10.lua   # igual, extracción más rica de nivel 1-10 (se fusiona encima)
│   ├── QuestObjectiveESIndex_Full.lua # texto de objetivo ES -> lista de ndx (base completa)
│   ├── QuestLocES_Full.lua           # ndx -> {nameES=...} (base completa, 14.824)
│   ├── QuestLocalization_Full.lua    # ndx -> {nameES=..., objectivesES={...}} (base completa) — fuente real de _G.QuestLocES
│   ├── QuestLocCoords.lua            # ndx -> "NS, EW" (una coordenada por misión)
│   ├── QuestStagesCoords.lua         # ndx -> {{name, nameES, loc}, ...} (todas las coordenadas conocidas)
│   ├── ZoneMapIndex.lua              # nombre de área/zona (EN, normalizado) -> mapID de MoorMap (703 entradas, ver §6.3)
│   ├── ChestsDB.lua                  # cacerías de tesoro (extraído de WarbandsSlayer)
│   ├── ThreatsDB.lua                 # jefes/amenazas itinerantes con nombre propio
│   ├── LostLoreDB.lua                # colecciones extraídas de LostLore 3.7.3 (277 entradas, 1.962 puntos)
│   ├── WarbandMapBounds.lua          # caja delimitadora NS/EW de cada mapa interno usado (53 mapas)
│   ├── QuestLocES.lua                # VIEJO, con mojibake — NO se importa (ver §8)
│   └── FarmingDB.lua                 # generado pero NO se importa (ver §8)
├── Legacy/
│   ├── MoorMapAdapter.lua            # integración con MoorMap (SÍ se usa pese al nombre de carpeta)
│   ├── WaypointAdapter.lua           # integración con Waypoint (SÍ se usa)
│   ├── QuestDatabase.lua             # NO usado (legacy, ver §8)
│   └── QuestObjectiveIndex.lua       # NO usado (legacy, ver §8)
├── UI/
│   ├── QuestSyncWindow.lua           # ventana ÚNICA ("QuestSync") — misiones + puntos de interés + tropas + colecciones
│   ├── QuestTrackerHUD.lua           # ventana chica flotante ("QuestSync Tracker") — misiones activas + proezas de DeedTracker
│   ├── QuestSyncLauncher.lua         # icono flotante arrastrable "QS" que abre/cierra ventana + HUD
│   ├── QuestInfoTooltip.lua          # tooltip al pasar el mouse (portado de DeedTracker/DeedTooltipWindow.lua)
│   ├── ChestsWindow.lua              # NO IMPORTADO desde sesión 35 (fusionado en QuestSyncWindow.lua, ver §7.1)
│   └── NavigationPanel.lua           # NO usado (ver §8)
├── Resources/
│   ├── Maps/                         # 53 imágenes .jpg de mapa (copiadas de WarbandsSlayer)
│   ├── ProgressBar.tga / ProgressBar_Back.tga / ProgressBarComplete.tga   # copiadas de DeedTracker
│   ├── lostlore_book.tga / lostlore_treasure.tga
│   └── chest.jpg / chestFound.jpg
├── Map/ Nav/ Persistence/ Utils/     # vacías (quedaron del plan original, todo terminó en Core/Data/Legacy/UI)
└── tools/QuestSync/
    ├── validate_lua_project.py       # backticks/llaves-paréntesis desbalanceados/BOM
    └── deploy.py                     # valida + copia a Plugins/ real + compara hash SHA-256
```

## 3. Orden de carga (`Main.lua`)

El orden importa: la localización en español tiene que estar lista ANTES de crear la UI (si no, las misiones se muestran en inglés — bug de la sesión 1, corregido).

```
1. Core/EventBus.lua              (declara _G.LQA y LQA.Debug.Enabled)
2. Data/QuestDatabase.lua + índices + ZoneMapIndex + ChestsDB/ThreatsDB/LostLoreDB + WarbandMapBounds
2b. FUSIÓN de localización (en Main.lua):
    _G.QuestNameESIndex = QuestNameESIndex_Full
    _G.QuestObjectiveESIndex = QuestObjectiveESIndex_Full
    _G.QuestLocES = QuestLocalization_Full
3. Core/QuestLocResolver.lua → QuestStateManager.lua → QuestDiag.lua → QuestEventParser.lua → LanguageSettings.lua
4. Legacy/MoorMapAdapter.lua → WaypointAdapter.lua
5. UI/QuestInfoTooltip.lua → QuestTrackerHUD.lua → QuestSyncWindow.lua → QuestSyncLauncher.lua
   QuestStateManager.Initialize()      -- carga async del guardado anterior
   LanguageSettings.Initialize()
   _G.HUD = QuestTrackerHUD()
   _G.MainWindow = QuestSyncWindow()   -- oculta por defecto
   _G.Launcher = QuestSyncLauncher()
   registro de /questsync (alias /qs) y /cofres (alias /qcofres)
   instalación del dispatcher de chat compartido con DeedTracker (ver §4b)
```

## 4. Flujo de extremo a extremo (chat → pantalla)

```
Chat de LOTRO (Turbine.ChatType.Quest, o Standard si contiene "/" o ":")
   │
   ▼
Main.lua: dispatcher compartido (_G.LQA_ChatHookRef) → OnChatReceived
   - descarta mensajes propios (contienen "QuestSync:" o "<rgb=")
   │
   ▼
QuestEventParser.ParseMessage(sender, message)
   - PROGRESO   "Texto (N/M)" o "Texto: N/M"   → primero, es lo más frecuente
   - ACEPTADA   "Nueva misión: X" / "Has aceptado la misión: X" / etc.
   - COMPLETADA "Completado: X" / "Misión completada: X" / etc.
   - ABANDONADA "Has abandonado la misión: X" / etc.
   - FALLBACK   si nada coincidió, prueba el mensaje ENTERO contra nombres/objetivos
                conocidos (reafirma estado, solo activa si la coincidencia fue por
                OBJETIVO exacto — nunca por nombre suelto, evita falsos positivos
                de diálogo de NPC)
   │
   ▼
QuestLocResolver.FindQuestByAnyName(texto)
   - normaliza (minúsculas + tildes, byte a byte, UTF-8-seguro)
   - busca en QuestNameESIndex, si no QuestObjectiveESIndex, si no QuestNameIndex (EN)
   - 1 candidato → SUCCESS
   - varios candidatos: ¿exactamente 1 ya ACTIVA? (solo para OBJETIVO) → esa
                        si no, ¿exactamente 1 con "prev" completada/activa? → esa
                        si no → AMBIGUA, nunca se adivina
   │
   ▼
QuestStateManager.SetQuestActive / UpdateProgress / SetQuestCompleted / SetQuestAbandoned
   - actualiza State.active / State.completed / State.tracked
   - Turbine.PluginData.Save (persiste entre sesiones)
   - EventBus:Publish("QUEST_STATE_CHANGED" / "QUEST_PROGRESS" / "QUEST_TRACKED", {ndx=...})
   │
   ▼
QuestSyncWindow / QuestTrackerHUD (suscritos a esos 3 eventos)
   - QuestSyncWindow: si está VISIBLE, repuebla la lista; si está oculta, solo marca
     self.pendingRepopulate=true y repuebla una vez al reabrirse (VisibleChanged) —
     evita escanear las 14.824 misiones en cada línea de chat mientras la ventana
     está cerrada (bug de rendimiento real, corregido 2026-08-20)
   - colores de estado (StateColor): Beige=disponible, LightBlue=activa, (0,1,0)=completada
     — paleta alineada a propósito con la de DeedTracker (mismo autor, mismo criterio visual)
   - piden a MoorMapAdapter/WaypointAdapter que actualicen los Quickslots detrás de
     cada botón "Ir"/"Mapa"/"Ruta" con la coordenada correcta
```

## 4b. Gancho de chat compartido con DeedTracker

`_G.LQA_ChatListeners` (tabla `nombre -> función`), `_G.LQA_ChatHookRef`, `_G.LQA_ChatHookInstalled`, `_G.LQA_ChatHookWatcher`. Cualquiera de los 2 addons que cargue primero instala UN dispatcher compartido que encadena sobre lo que hubiera antes en `Turbine.Chat.Received` (nil, una función, o una TABLA de funciones — confirmado que MoorMap usa esa 3ª forma) y llama a cada listener registrado. Un watchdog (control con `SetWantsUpdates(true)`, chequea cada 1s) reinstala el dispatcher si un 3er addon mal comportado (Waypoint/WarbandsSlayer/ChatNotif, todos hacen `Turbine.Chat.Received = function...end` sin encadenar) lo pisa. `QuestSync` se registra como `_G.LQA_ChatListeners["QuestSync"] = OnChatReceived`; `DeedTracker` se registra igual bajo `"DeedTracker"`. Ambos archivos (`Main.lua` aquí, `ChatLogger.lua` en DeedTracker) implementan el MISMO contrato — si alguna vez se toca uno, revisar que el otro siga siendo idéntico en la firma del dispatcher.

## 5. Módulos `Core/`

### 5.1 `EventBus.lua`
Namespace `_G.LQA` (`LQA.Core`, `LQA.Data`, `LQA.UI`, `LQA.Map`, `LQA.Nav`, `LQA.Localization`, `LQA.Debug`) y pub/sub (`Subscribe`/`Publish`). `LQA.Debug.Enabled` es el único interruptor de depuración de todo el addon — `false` por defecto.

### 5.2 `QuestEventParser.lua`
Tabla `PATTERNS` (ACCEPTED/COMPLETED/PROGRESS/ABANDONED), cada patrón usa `%s*` en vez de espacio literal (LOTRO a veces parte el nombre en una línea separada del contador). Los acentos van como variantes literales lado a lado ("misión"/"mision") porque Lua no tiene alternancia `(a|b)` ni clases de caracteres UTF-8-seguras. Función pública única: `ParseMessage(sender, message)`.

### 5.3 `QuestLocResolver.lua`
- `GetQuestNameES(ndx_or_nombreEN, fallbackEN)`
- `FindQuestByAnyName(nameRaw)` → `status, ndx_o_lista, resType` (`"SUCCESS"`/`"AMBIGUA"`/`"FAIL"`; `resType` = `"NAME"`/`"OBJECTIVE"`/`"..._CHAIN"`/`"..._ACTIVE"`)
- `NormalizeES(s)` — minúsculas + plegado de tildes byte-a-byte, expuesto para que otros archivos (buscador de `QuestSyncWindow.lua`) no dupliquen la lógica.

### 5.4 `QuestStateManager.lua`
Única fuente de verdad. `State = {active={}, completed={}, tracked=nil}`. `SetQuestActive` limpia `completed[ndx]` (repetibles). `SetQuestCompleted` mueve de `active` a `completed` sin exigir que estuviera activa antes. `ResetQuest` es el "Desmarcar" manual de la UI.

## 6. Adapters (`Legacy/MoorMapAdapter.lua`, `WaypointAdapter.lua`)

### 6.1 El truco del Quickslot
```lua
function MoorMapAdapter.CreateQuickslot()
    local qs = Turbine.UI.Lotro.Quickslot()
    qs:SetSize(32, 32)
    qs:SetVisible(true)   -- debe ser true para recibir clics
    qs:SetOpacity(0)      -- se oculta con opacidad, no con Visible(false)
    qs:SetAllowDrop(false) -- evita que acepte arrastrar-soltar (bug de sesión pasada)
    return qs
end

function MoorMapAdapter.AttachToButton(quickslot, button)
    quickslot:SetParent(button)
    local w, h = button:GetSize()
    quickslot:SetPosition(0, 0)
    quickslot:SetSize(w, h)
    quickslot:SetZOrder(10)
end
```
Cada botón visible (`Turbine.UI.Lotro.Button`, nunca una `Label` plana) tiene su PROPIO Quickslot como HIJO, mismo tamaño, `SetZOrder(10)` para recibir el clic. **Nunca se comparte un Quickslot entre 2 botones** — un control solo puede tener un padre a la vez.

**Sangrado de texto "/MOO"/"/WAY" — investigado a fondo, no resuelto, y por qué no se sigue intentando a ciegas:** un `Turbine.UI.Lotro.Quickslot` con un shortcut de tipo Alias muestra su propio tooltip nativo ("ALIAS: <comando completo>") al pasar el mouse — **esto NO es un bug de este addon, es el comportamiento nativo e inevitable de LOTRO para cualquier control que reciba un clic real de esa forma** (confirmado con una captura de pantalla real del usuario mostrando el tooltip completo). Se intentó una restructuración (Quickslot como hermano del botón en vez de hijo, con `SetMouseVisible(false)` en el botón para dejar pasar el clic) pero se **revirtió** en la misma sesión que se probó: no se encontró en NINGÚN addon de este entorno un caso real y comprobado de ese patrón exacto de "clic atravesando un hermano invisible al mouse hacia otro control detrás" — todos los usos reales de `SetMouseVisible(false)` en este entorno son de un HIJO decorativo dejando que su PADRE reciba el clic (burbujeo normal), no de hermano a hermano. Arriesgar que los botones de navegación dejen de responder por una hipótesis cosmética no verificada no valía la pena. La estructura actual (child + Opacity(0) + ZOrder(10)) es la versión SEGURA, con clic garantizado — el sangrado visual queda como limitación conocida, no un bug abierto a "arreglar" con otro intento a ciegas.

### 6.2 `MoorMapAdapter.ParseCoord(texto)`
Convierte `"25.29S, 47.61W"` a un par de números con signo (`-25.29, -47.61}`) — MoorMap exige signo, no letra pegada.

### 6.3 `MoorMapAdapter.ResolveMapID(quest)` — el más complejo del addon
Compara `quest.area`/`quest.zone` (inglés, Compendium) contra `ZoneMapIndex` probando hasta 16 variantes: con/sin paréntesis, con/sin sufijo tras coma, con/sin prefijo "the ", con/sin acentos plegados. Cubre ~85,9% de las 14.824 misiones. El resto son mayormente misiones de instancia sin `area`/`zone` (no hay nada que resolver) o zonas que MoorMap 1.66 no tiene mapeadas bajo ningún nombre. **`ZoneMapIndex.lua` fue verificado el 2026-08-20 contra el archivo real `Defaults.lua` de MoorMap (fórmula de validación real extraída de `GaranStuff/MoorMap/Main.lua` línea ~6117) y está limpio — 0 ids inexistentes, 0 discrepancias reales de nombre.**

### 6.4 `MoorMapAdapter.ResolveQuestLoc(ndx, quest)`
Coordenada "por defecto" de una misión: `quest.loc` (nunca presente hoy) → primer lugar de `QuestStagesCoords` → `QuestLocCoords`. Punto único usado por ambas ventanas.

### 6.5 `WaypointAdapter`
Más simple: solo necesita el string crudo de coordenada, Waypoint lo parsea solo, sin mapID. Por eso casi el 100% de las misiones con coordenada conocida tienen flecha de Waypoint funcional aunque MoorMap no pueda ubicarlas.

### 6.6 Limitación conocida y aceptada: "sub-mapa vs. mapa general"
Una coordenada de una sub-zona específica (ej. "Nain Enidh" dentro de "Ered Luin") a veces no encaja en el sistema de coordenadas del mapa GENERAL de MoorMap para esa región amplia — no es un signo invertido, es una escala/proyección distinta que ni corrigiendo el signo se arregla. Investigado a fondo en varias sesiones (incluida una verificación cruzada contra una guía real de la comunidad para un caso concreto) — **no se intenta corregir en masa por heurística**, cada caso necesitaría verificación externa real. Cuando MoorMap tira "Coordenada NS/EO del mapa no válida", primero comprobar con la fórmula real (§6.3, misma que usa DeedTracker) si es este caso antes de asumir que es un bug nuevo.

## 7. UI

### 7.1 `QuestSyncWindow.lua` — ventana única con pestañas
700×720 (mínimo 700×600, redimensionable). Pestañas: "QuestSync" (misiones), "Puntos de Interes" (ChestsDB), "Tropas y Amenazas" (ThreatsDB), "Colecciones" (LostLoreDB) + botón de idioma ES/EN. Banda superior fija: misión activa/rastreada + progreso + botón "Ir". Columna izquierda (270px): lista agrupada por área/zona, plegable. Columna derecha: panel de detalle (misión seleccionada O punto de interés/amenaza/colección seleccionado), comparten la misma lista `pointsList` para el desglose de lugares.

**Buscador** (solo en la pestaña QuestSync): busca por nombre (ES/EN) o texto de objetivo entre las 14.824 misiones, debounce de 0.35s, resultados planos con `[Área]` de sufijo, tope de 200 con aviso visible (nunca trunca en silencio).

**`AddQuestListRow`**: fila de la lista principal — el texto más visto de todo el addon. Tenía una fuente sin especificar (usaba lo que fuera el default del SDK) hasta que se detectó en una auditoría explícita el 2026-08-20; ahora usa `Verdana12` explícito (no `Verdana14` como DeedTracker usa para sus nombres — sus nombres son de una sola línea, los de QuestSync necesitan 2-3, y una fuente más grande reduciría caracteres por línea forzando una 4ª línea sin recalcular la altura de fila).

**Rendimiento**: `OnQuestEvent` (suscrito a los 3 eventos de misión) solo repuebla la lista si `self:IsVisible()` es verdadero — si la ventana está cerrada, solo marca `self.pendingRepopulate=true`, y `self.VisibleChanged` la repuebla una sola vez al reabrirse. Antes de este fix (2026-08-20), cada línea de chat con progreso escaneaba las 14.824 misiones DOS VECES para repintar una lista que nadie estaba viendo.

### 7.2 `QuestTrackerHUD.lua` — ventana chica flotante
Mínimo 220×160, redimensionable. Lista TODAS las misiones activas del mapa actual con nombre+progreso+botón "Ir" en `LightBlue` (mismo color que DeedTracker usa para "en progreso"). También lista, con una insignia violeta separada, las proezas en curso de DeedTracker (`_G.LQA_InProgressDeeds`, chequeado cada 2s) — **limitación conocida**: esa tabla nunca se limpia cuando una proeza se completa en DeedTracker (no hay ningún global que exponga "completada" del otro lado), así que puede seguir apareciendo como "en curso" hasta cerrar sesión.

### 7.3 `QuestSyncLauncher.lua` — icono flotante "QS"
40×40, arrastrable, posición persistida (`Turbine.PluginData`, clave `QuestSync_LauncherPos`). Clic simple → `ToggleWindows()` (muestra/oculta MainWindow+HUD juntas). Sin Quickslot — solo llama funciones Lua propias, no dispara comandos de LOTRO.

### 7.4 `QuestInfoTooltip.lua` — tooltip al pasar el mouse
Ventana flotante (patrón portado de `DeedTracker/DeedTooltipWindow.lua`). Muestra nivel/área y hasta 2 líneas de objetivo REAL, filtrando frases de diálogo/flavor-text: **bug real corregido 2026-08-20** — antes usaba `objectivesES[1]`/`[2]` por índice fijo asumiendo que [1] es "resumen" y [2] "objetivo corto"; en el 23,5% de las 14.824 misiones esa suposición es falsa (el array trae citas de PNJ mezcladas, en cualquier posición). Ahora `IsFlavorText(s, nameEN)` descarta cualquier entrada que empiece con `'`/`"`/¡/¿ (comparando el byte correcto: ¡/¿ ocupan 2 bytes en UTF-8, un bug de "un byte vs. dos" que se coló en la primera versión de este mismo fix y se corrigió el mismo día) o que sea igual al nombre en inglés, y usa las primeras 2 entradas limpias que encuentre en cualquier posición. Medido: **0 de las 14.824 misiones tienen el array completamente vacío de texto limpio** — la corrección cubre toda la base sin necesitar curar contenido a mano.

### 7.5 Paleta de colores — alineada con DeedTracker a propósito
`StateColor()` en `QuestSyncWindow.lua`: `Beige` (disponible, antes gris plano), `LightBlue` (activa, antes azul RGB a mano), `(0,1,0)` (completada, antes verde RGB a mano) — igualada el 2026-08-20 a los colores reales que usa `DeedTracker/MainWin.lua` (`deedForeColor`/`LightBlue`/`(0,1,0)`), a pedido explícito del usuario de unificar el formato visual entre los dos addons del mismo autor. Encabezados de sección: `Turbine.UI.Color.Yellow` (antes un dorado apagado a mano), mismo criterio.

### 7.6 Misiones de GRUPO (mazmorras / incursiones / instancias) — 2026-09-22
Pedido explícito del usuario: color específico + logo de grupo + "a qué mazmorra/raid hay que ir" en todas las misiones de grupo.
- **`Data/GroupQuestDB.lua`** (generado): `id` real de la misión (hex, `QuestDB.quests[ndx].id`) → `{ s, k, p }`. `s` = tamaño OFICIAL del juego (`S` grupo pequeño 3 / `F` comunidad 6 / `R` incursión 12+), sacado de `lore/quests.xml` de LotroCompanion/lotro-data (atributo `size`), cruzado por id contra las 14.974 misiones (14.974/14.974 cruzadas, **1.448 de grupo**). `k` = tipo de lugar (`inst` mazmorra/incursión, `pe` instancia privada, `skirm` escaramuza, `epic` batalla épica, `open` zona abierta). `p` = lugar: nombre real de la instancia (`lore/instancesTree.xml` + dungeons/privateEncounters) o, si no es instancia, área/zona de la propia QuestDB. Nombres de lugar en inglés a propósito (nombre propio oficial, regla §11). Clave por `id` y no por `ndx` para no desalinearse si se regeneran los bloques.
- **`Core/GroupQuest.lua`**: único punto de consulta — `Get/IsGroup/SizeText/PlaceText/Statement/OneLine`, `Color.Dark` (texto claro con contorno, fondos oscuros) / `Color.Ink` (pergamino), `ICON_16`/`ICON_24`. Cambiar el color de grupo = tocar solo `GroupQuest.Color`. Si `GroupQuestDB` no carga, `Get()` devuelve nil y todas las ventanas quedan exactamente como antes.
- **Íconos** `Resources/Book/group_icon_16.tga` / `group_icon_24.tga`: generados al tamaño EXACTO de uso (SetBackground no reescala), TGA tipo 10 (RLE) 32bpp como el resto de los .tga del addon, alfa premultiplicado al achicar, siempre con `BlendMode.AlphaBlend`.
- Dónde se ve: lista de `QuestSyncWindow` (texto naranja + logo 16px; el ESTADO sigue en la insignia chica), panel de detalle (`self.groupBanner` en el hueco libre y=352..422 entre "Objetivo de la Misión" y MoorMap/Waypoint, solo en `SelectQuest`; `SelectPoi`/`ClearDetailPanel` lo ocultan), Tracker (`ClassifyQuest` consulta `GroupQuest` ANTES que "epic"; logo en vez del punto), libro de misión (logo junto al título + primera fila del checklist con el enunciado) y tooltip (título naranja + línea de grupo).
- Probado con un arnés de simulación del SDK que carga `Main.lua` real completo: versión original y modificada, 0 errores; las 1.448 misiones de grupo pasan por `SelectQuest`/`QuestBookWindow:ShowFor`/tooltip sin errores y con cartel correcto; misión normal después de una de grupo resetea todo.
- **Atención deploy**: este cambio se hizo directo en `Plugins/` (la carpeta de desarrollo con `tools/QuestSync/deploy.py` no estaba conectada a la sesión). Antes del próximo `deploy.py`, copiar estos archivos a la carpeta de desarrollo o el deploy los va a pisar: `Core/GroupQuest.lua`, `Data/GroupQuestDB.lua`, `Resources/Book/group_icon_16.tga`, `Resources/Book/group_icon_24.tga`, `Main.lua`, `UI/QuestSyncWindow.lua`, `UI/QuestTrackerHUD.lua`, `UI/QuestBookWindow.lua`, `UI/QuestInfoTooltip.lua`, este `.md`.

### 7.7 Ronda 2 (2026-09-22): filtro de grupo, "Buscar grupo", Diaria/Semanal, tu nivel
- **Filtro de grupo** (`btnGroupFilter`, `QuestSyncWindow`): botón nativo chico en la fila del buscador (el buscador bajó de 140 a 94px de ancho, "Ver todas" no se movió). Apagado por defecto = lista idéntica a antes. Prendido: `PopulateMisionesTab`/`PopulateSearchResults` solo listan misiones de `GroupQuestDB` y `lblSearchInfo` lo avisa.
- **Botón "Buscar grupo"** (`btnLff`): misma fila y mismo mecanismo que MoorMap/Waypoint (§6.1: `Turbine.UI.Lotro.Button` + Quickslot con Alias). Solo visible en misiones de grupo. Comando: `GroupQuest.LffCommand` → `/world LFF <lugar> (<tamaño>) - Quest: <nombre EN>`, plegado a ASCII (`GroupQuest.FoldAscii`, el parser de comandos no es UTF-8-seguro, mismo bug documentado en `MoorMapAdapter`). Canal en UNA constante: `GroupQuest.LFF_CHANNEL` (las notas oficiales de la Update 19.3 recomiendan `/lff` para buscar grupo; el usuario pidió `/world`). El mensaje sale SOLO al hacer click.
- **Diaria/Semanal/Quincenal**: `Data/QuestLockDB.lua` (generado del atributo oficial `lockType` de lotro-data, 2.093 misiones: 1.897 D, 165 W, 31 B) + `Core/QuestTags.lua`. Se agrega " · Diaria" en la fila de la lista (salvo que el nombre ya lo diga) y una línea en el tooltip.
- **Tu nivel**: `QuestTags.GetPlayerLevel()` (`Turbine.Gameplay.LocalPlayer.GetInstance():GetLevel()` en pcall, `import "Turbine.Gameplay"` confirmado en LUI y en `Core/QuestManager.lua`). Franja verde de 3px a la izquierda de la fila y línea en el tooltip si el nivel numérico de la misión está entre nivel-4 y nivel+2 (`QuestTags.LEVEL_BELOW/ABOVE`). Misiones "Scaling" no se marcan. Se lee una vez por `PopulateList`.
- Probado con el mismo arnés: original y modificado 0 errores; filtro (38 de 98 filas en un área, todas de grupo), búsqueda filtrada, 1.448 comandos LFF válidos (ASCII, ≤ 207 caracteres), etiquetas y nivel (mock nivel 50), textos en EN.
- **Atención deploy** (igual que §7.6): además copiar `Core/QuestTags.lua` y `Data/QuestLockDB.lua` a la carpeta de desarrollo.

### 7.8 Verificacion del sistema de deteccion de misiones (2026-09-25)
Prueba automatica con el arnes (carga Main.lua real) sobre las 14.974 misiones, las 4.673 hazanas de Deed Tracker (EN y ES, nombres y objetivos) y mensajes de chat comunes. Se encontraron y corrigieron 4 problemas:
- **Nombres con punto** ("01. The Further Adventures...", "...and the Body Will Die"): el parser borraba TODOS los puntos antes de buscar, asi que 438 misiones nunca se detectaban. Ahora `Resolve()` prueba el texto tal cual, sin punto final, y recien despues sin puntos.
- **Hazanas tomadas como misiones**: LOTRO dice "Completed:" tanto para misiones como para hazanas. 258 nombres de hazana (EN) marcaban completada (y abrian el libro de) una mision que el jugador no tenia; 38 objetivos de hazana activaban misiones. Arreglo: ACEPTADA/COMPLETADA/ABANDONADA resuelven solo por NOMBRE (`QuestLocResolver.FindQuestByName`, nunca por texto de objetivo) y `Data/DeedQuestCollisions.lua` (generado, 379 textos) hace que esos textos solo toquen una mision si ya esta ACTIVA.
- **Homonimas**: de dos misiones con el mismo nombre se activaba/completaba una "al azar" segun el indice (544 al aceptar, 571 al completar, equivocadas). Ahora son ambiguas de verdad: al completar/abandonar gana la unica activa; al aceptar se descartan la ya activa y la completada no repetible (`PickNewQuest`); si aun quedan varias no se activa ninguna. Se probo elegir por zona y se descarto (elegia mal al cambiar de zona).
- **Nombre suelto en el chat**: el indice de objetivos trae el nombre de muchas misiones, asi que un nombre suelto activaba la mision (2.158). Ahora `IsQuestOwnName` lo impide, como ya decia la nota del fallback.
Resultado: 0 misiones equivocadas en todas las pruebas; aceptar 13.667, completar 14.974/14.974, progreso OK; `FindQuestByAnyName` devuelve exactamente lo mismo que antes (177.365 textos comparados). Limite conocido: una mision cuyo nombre es igual al de una hazana, completada sin estar marcada activa, ya no se marca sola.

### 7.9 Nombre de la mazmorra en español y en inglés (2026-09-27)
Pedido del usuario: en la informacion de las misiones de mazmorra/incursion mostrar el nombre de la instancia en los dos idiomas. `Data/GroupPlaceES.lua` (generado, 156 nombres) = nombre en ingles de `GroupQuestDB` (campo `p`) -> nombre en español, sacado de las etiquetas en español de lotro-data (`lore/labels/es/instances.xml`, `dungeons.xml`, `geoAreas.xml`, misma fuente que `QuestLocES_Full.lua`) cruzadas por id real; compuestos ("Helegrod: Drake Wing") = parte + parte. Sin etiqueta en español (batallas epicas, Cortes de Osgiliath) = solo ingles. `Core/GroupQuest.lua`: `PlaceNames` (principal/secundario segun el idioma del addon; nada para zona abierta ni si es igual en los dos), `PlaceText` usa el principal, `Statement` agrega 3a linea "En inglés: ..." / "In Spanish: ...", `PlaceTextBoth` (una linea, la usa el Mapa del Mundo), `IsInstance`, `EstimateLines`. El cartel de grupo de la ventana principal pasa a letra 12 si el texto no entra en su alto fijo; la fila de grupo del libro crece. "Buscar grupo" sigue usando el nombre en ingles (ASCII, para el chat).

### 7.10 Deteccion de misiones nuevas y Tracker (2026-09-27)
Reporte del usuario: "no me detecto las misiones nuevas y el progreso de nuevas misiones en el tracker" (Forochel, nivel 53). Causas encontradas y arreglos:
- **Tracker (`UI/QuestTrackerHUD.lua`)**: filtra por zona con `quest.zone` de la base, pero ~1.000 misiones traen zona equivocada (p.ej. "Enanos y mamuts": Bree-land, subzona Länsi-mâ = Forochel) y 1.343 no traen zona. Al avanzar una mal catalogada, el Tracker cambiaba de zona y escondia todas las demas; las sin zona no se veian nunca. Ahora usa `QuestLocResolver.QuestZone(ndx)`: zona mayoritaria (60%+) de la subzona, si no la propia, si no la categoria cuando es nombre de zona; "zonas" que no son lugar (Special, Mission..., Festival, Midsummer) = desconocida. Zona desconocida = se muestra siempre.
- **Progreso con color**: 2.469 misiones tienen el objetivo con `<rgb=...>` y `Main.lua` descartaba toda linea con `<rgb=`. Del canal de Misiones ya no se descarta (del resto si); `QuestLocResolver.StripRGB`, variantes sin color en `Resolve`, e indice de objetivos sin color (`RgbFreeObjective`, solo claves nuevas).
- **Nombres compartidos al aceptar** (`PickNewQuest`): despues del filtro de siempre, (1) NIVEL: se descartan las que el personaje no puede aceptar (nivel minimo, o nivel - 15); (2) ZONA ACTUAL del aviso "... - Regional" del chat (solo entrada: "Entered"/"Entró"; `QuestEventParser.NoteRegionalMessage`, `QuestLocResolver.ZoneFromText` con nombres en ingles y español de `MoorMapZonesES`). Nunca por "donde venia haciendo misiones" (descartado antes). Si siguen quedando varias, no se activa ninguna. Lo mismo para un contador (N/M) cuyo objetivo comparten varias misiones y ninguna esta activa.
- **`Core/QuestDiag.lua`**: guarda (por personaje, `QuestSync_Diag`, maximo 40, guardado agrupado cada 5 s, carga con callback 6 s despues de entrar) los mensajes del canal de Misiones que no se pudieron resolver. `/qsdiag` los muestra con zona y nivel; `/qsdiag borrar` lo vacia.
Pruebas: detect2 igual que antes salvo progreso 3.000/3.000 (antes 15 fallaban por el color); a nivel 53 las 34 homonimas que cambian de eleccion son todas imposibles para ese nivel (0 mal); prueba nueva de 40 casos (zona, Regional, nivel, color, Tracker) sin fallas.

### 7.11 Recolección: nodos dibujados fuera del mapa (2026-09-30)
Reporte del usuario: en la ventana Recolección, mapa "Camino de Durin", 4 nodos de Erudito salían en la parte vacía del dibujo. Causa: los límites de MoorMap son rectángulos aproximados y un punto cae en varios mapas del mismo tier (7S 110-112W está dentro de Durin's Way, The Great Delving y Zelem Melek, los 3 tier 4); ganaba el primero de la lista. `MoorMapZoneResolver.Resolve` ahora, a igual tier, prefiere el mapa donde el punto cae dentro de la imagen y después el de más zoom (`|hFactor|` mayor). `GatherPointsStore.RelocatePoints` mueve al cargar los puntos ya guardados a su mapa correcto (nunca borra; guarda solo si movió algo). Con los datos del usuario: solo esos 4 puntos pasan a The Great Delving; los otros 16 quedan igual.

### 7.12 Tracker: misiones viejas al entrar o relogear (2026-10-01)
Reporte del usuario: al entrar con el personaje el Tracker mostraba misiones muy antiguas y recien se acomodaba al aceptar/completar una. Causa: el Tracker arrancaba sin zona (`currentZone = nil` = sin filtro) y mostraba TODAS las activas guardadas de todas las zonas (con el guardado del usuario: 36 filas de 52 activas); la zona solo se ponia con el primer aviso de mision. Ahora `UI/QuestTrackerHUD.lua` arranca con `StartZone()`: la zona que tenia el Tracker al salir (`QuestStateManager.State.zone`, nueva, se guarda solo cuando cambia) y si no hay, la zona de la mision activa (no oculta) con `lastUpdate` mas reciente (hora del juego, sigue corriendo entre sesiones). Con el guardado del usuario: 3 filas (The Misty Mountains). Nada del guardado se borra; las activas viejas siguen guardadas y aparecen al volver a su zona.

### 7.13 Tracker: efectos de fuego (2026-10-01)
Pedido del usuario: brillo y destellos como el cartel de misiones de LUI, pero de fuego, continuos, con el anillo y los bordes distintos en efecto y color. `UI/TrackerFireFX.lua` (importado por `UI/QuestTrackerHUD.lua`, que solo llama `TrackerFireFX.Attach(self, self.pageBg)` al final del Constructor, en `pcall`). Anillo: la inscripcion arde (`tracker_fx_anillo_brasa.tga`, opacidad que late) + llamas sobre el borde de arriba (`tracker_fx_anillo_llama_1..12.tga`, bucle) + brasas rojo-naranja que suben. Titulo: cada 5,5 s una lengua de fuego recorre la placa (`tracker_fx_titulo_barrido_1..12.tga`) con chispas doradas. Bordes: fuego elfico AZUL, brillo que respira siguiendo el borde rasgado (`tracker_fx_borde_azul.tga`, pagina completa) + llamitas azules que suben por los costados. `QUEST_JUST_ACCEPTED`/`QUEST_JUST_COMPLETED` = llamarada de 3 s. Todo hijo de `pageBg` (debajo de la lista, sin mouse) y derivado de `tracker_parchment.tga` 307x425 (calza pixel a pixel). Un error interno apaga el efecto una sola vez (no spamea). `/trackerfuego [on|off]` lo apaga/prende; se guarda en `QuestStateManager.State.fxOff`. Imagenes generadas desde el mismo pergamino con Pillow (no se edita el pergamino).

### 7.14 Anillos en llamas, estrellas en el titulo y cartel de grupo mas grande (2026-10-01)
Pedido del usuario con captura. `UI/RingFireFX.lua` (importado por `UI/QuestSyncWindow.lua` y `UI/QuestBookWindow.lua`, enganchado al final de cada Constructor en `pcall`): `AttachRing` pone el MISMO fuego del anillo del Tracker en el anillo de `book_menu.tga` (QuestSync, control en 504,353 de 120x155) y en el de `questbook.tga` (libro "Nueva mision", 306,301 de 144x170) -- `questsync_fx_anillo_*` / `questbook_fx_anillo_*` (brasa de la inscripcion + 12 cuadros de llamas), brasas `tracker_fx_brasa_*`; la silueta del anillo se ajusto con una elipse y la inscripcion se saco de la diferencia con `ring_hover.tga`/`questbook_ring_hover.tga`. `AttachTitleStars`: OTRO efecto para el titulo grande de QuestSync (`lblTitle`): estrellas dorado-blancas que titilan sobre las letras (`questsync_fx_estrella_9/13/17.tga`) y una cascada cada 6,5 s; solo con una mision o punto elegido. Un reloj por ventana, oculto si la ventana esta cerrada, llamarada con `QUEST_JUST_ACCEPTED/COMPLETED`, `/trackerfuego off` los apaga tambien. Cartel de grupo (`lblGroupBanner`): primero BookAntiquaBold18 si entra (estimado 8,5 px por letra, 21 px por linea), si no Bold14 y despues Antiqua12, nunca se corta.

### 7.15 Abandonar: aviso con nombre, mas variantes y Mapa del Mundo al dia (2026-10-01)
Pedido del usuario: que al abandonar una mision (en Quest Assistant o desde el juego) el Mapa del Mundo se entere. `Core/QuestEventParser.lua`: patrones ABANDONED nuevos (`Misión abandonada:`, `Abandonaste la misión:`, `Quest Abandoned:`, `Abandoned:` y sin tilde), y toda linea del canal de Misiones que diga "abandon" y no coincida queda en `/qsdiag` como ABANDONO (texto real del juego, para agregar su patron exacto). `QuestStateManager.SetQuestAbandoned` escribe el nombre de la mision en el chat. El Mapa del Mundo (`WorldMap_Addon/worldmap.lua` v2.9, `_syncQuestEvents`) se suscribe al EventBus (`QUEST_STATE_CHANGED`, `QUEST_JUST_ACCEPTED`, `QUEST_JUST_COMPLETED`): el aviso solo marca "hay cambios" y en el cuadro siguiente rehace medallones, resumen del cartel y la lista abierta de la zona.

## 8. Código NO usado (no tocar sin pedirlo explícitamente)

`Core/NavigationParser.lua`, `Core/QuestManager.lua`, `Core/QuestResolver.lua`, `Legacy/QuestDatabase.lua`, `Legacy/QuestObjectiveIndex.lua`, `UI/NavigationPanel.lua`, `UI/ChestsWindow.lua` (fusionado dentro de `QuestSyncWindow.lua`), `Data/QuestLocES.lua` (mojibake heredado de una extracción TSV vieja), `Data/FarmingDB.lua` (solo 8/34 entradas con coordenada, la pestaña que lo usaba se sacó). Inofensivos porque `Main.lua` nunca los importa — no asumir que hacen algo.

## 9. Herramientas de build (`tools/QuestSync/`)

- **`validate_lua_project.py`** — antes de cada deploy: sin backticks sueltos, sin llaves/paréntesis desbalanceados, sin BOM de UTF-8.
- **`deploy.py`** — valida, copia `LOTRO_Quest_Assistant/` a la carpeta `Plugins/` real, compara hash SHA-256 origen/destino. **Nunca se edita `Plugins/` a mano.**
- No hay verificador de balance `function/if/for/while/do/repeat` vs `end` en el repo (el validador solo chequea llaves/paréntesis/backticks/BOM) — se escribió uno ad-hoc en Python durante la auditoría del 2026-08-20 (vive en el scratchpad de esa sesión, no en el repo) que SÍ detecta ese tipo de desbalance; considerar agregarlo a `tools/QuestSync/` si se repiten sesiones de auditoría estructural.

## 10. Notas y advertencias estructurales

- **Resuelto 2026-09-05**: había dos archivos `.plugin` (`LOTRO_Quest_Assistant.plugin`/`QuestSync.plugin`) apuntando al mismo `Package` — riesgo de doble carga si el usuario tildaba los dos en el gestor de addons. Se borró `LOTRO_Quest_Assistant.plugin` (dev y desplegado), queda `QuestSync.plugin` como único manifest.
- Lua no garantiza el orden de `pairs()` — cualquier lista que dependa de orden estable debe ordenarse explícitamente por `ndx` (ya hecho en `PopulateList`).
- Los archivos de `Data/` con texto en español están en UTF-8 literal (sin escapes `\DDD`) — mantener esa convención al generar datos nuevos.
- **Nunca usar PowerShell `Set-Content`/`Out-File -Encoding utf8` sobre archivos `.lua`** — agrega BOM y rompe el parser de Lua. Usar herramientas de edición directa (Read/Edit) o Python con `encoding='utf-8'` explícito sin BOM.

## 11. Reglas permanentes del proyecto

- El `ndx` es la única identidad real de una misión — nunca el nombre en inglés o español.
- Compendium = fuente de estructura; el DAT profesional / extracción de LOTRO Companion = fuente de verdad de traducción. Nunca traducir con IA si ya existe un string profesional en español; nunca inventar nombres.
- `QuestStateManager` es la única autoridad sobre el estado de una misión; `QuestDatabase` es solo catálogo.
- MoorMap y Waypoint se reutilizan vía sus adapters, nunca se reconstruyen.
- Nunca editar la carpeta `Plugins/` en vivo directamente — siempre desplegar vía `deploy.py`.
- Antes de "corregir" el sangrado de texto bajo los botones MoorMap/Waypoint otra vez: leer §6.1 completo primero. Ya se investigó a fondo, se intentó una vez, y se revirtió por falta de evidencia — no es terreno nuevo.

