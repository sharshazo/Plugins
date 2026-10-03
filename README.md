# Addons de LOTRO en español

Carpetas listas para copiar en la carpeta `Plugins` de The Lord of the Rings
Online. Cada carpeta ya tiene el **nombre exacto** que el juego necesita.

| Carpeta | Qué es | Nombre en Opciones → Plugins |
|---|---|---|
| `LOTRO_Quest_Assistant` | QuestSync: asistente de misiones en español (tracker, libro de misiones, mapa, misiones de grupo) | QuestSync |
| `LUI` | Interfaz LUI (de Geldahr, MPL-2.0) en español, con efecto de puntero y carteles de zona/misión | LUI |
| `WorldMap_Addon` | Mapa del Mundo: las zonas de la Tierra Media en español, mapas de zona, comando `/mapa` | Mapa del Mundo |
| `CubePlugins` | Deed Tracker: seguimiento de hazañas, con página "Por zona" | Deed Tracker |
| `Turbine` | Librería que necesitan QuestSync y el Mapa del Mundo | (no se activa, solo se copia) |

## Instalación

1. Botón verde **Code → Download ZIP**.
2. Abrí el ZIP. Adentro hay una sola carpeta (`Plugins-main`). Entrá en ella.
3. Copiá las **5 carpetas** que hay adentro (`LOTRO_Quest_Assistant`, `LUI`,
   `WorldMap_Addon`, `Turbine`, `CubePlugins`) y pegalas en:

   ```
   Documentos\The Lord of the Rings Online\Plugins\
   ```

   (con OneDrive: `OneDrive\Documentos\The Lord of the Rings Online\Plugins\`).
   Si Windows pregunta, aceptá **combinar** carpetas y **reemplazar** archivos.

   **No copies la carpeta `Plugins-main` entera**, solo las 5 de adentro.
   Debe quedar, por ejemplo:

   ```
   Plugins\LUI\LUI.plugin
   Plugins\LOTRO_Quest_Assistant\QuestSync.plugin
   Plugins\WorldMap_Addon\MapaDelMundo.plugin
   Plugins\CubePlugins\DeedTracker.plugin
   Plugins\Turbine\Class.lua
   ```

4. Abrí LOTRO → **Opciones → Plugins** (o `/pluginmanager` en el chat) y
   activá los que quieras.

## Problemas comunes

- **`Unable to resolve package ...`**: la carpeta quedó con otro nombre o
  dentro de otra carpeta. Revisá que quede como en el paso 3.
- **`attempt to call global 'class' (a nil value)`**: falta la carpeta
  `Turbine` dentro de `Plugins`.

## Narración por voz (opcional)

Los botones "Narrar" de QuestSync necesitan el programa
[Narrador_IA](https://github.com/sharshazo/Narrador_IA), que se instala
aparte (LOTRO no deja que un addon reproduzca sonido).

## Licencias

`LUI` es un trabajo derivado del [LUI original de Geldahr](https://github.com/Geldahr/LUI)
bajo licencia MPL-2.0 (ver `LUI/LICENSE` y `LUI/ATTRIBUTIONS.md`).
Deed Tracker está basado en el addon original de Cube.
