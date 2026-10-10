-- WorldMap_Addon/Main.lua
--
-- Punto de entrada del addon "Mapa del Mundo" para el Gestor de Plugins de
-- LOTRO. Lo declara MapaDelMundo.plugin (<Package>WorldMap_Addon.Main</Package>).
--
-- Version funcional: carga los datos y la logica real (worldmap_data,
-- tooltip_data, worldmap, worldmap_launcher -- los 4 ya convertidos al
-- patron real del motor: namespace global + import, en vez de require()) y
-- crea el boton anclable. Todo el detalle de las decisiones de diseño
-- (por que Lotro.Window para el mapa, por que Window sin chrome para el
-- tooltip, por que el resaltado de zona es un recuadro y no un relleno con
-- la forma exacta, etc.) esta documentado en worldmap.lua -- son
-- decisiones tomadas leyendo codigo real y probado de
-- LOTRO_Quest_Assistant, no adivinadas.
--
-- QUE FALTA (side esto ya carga y el boton ya deberia aparecer):
-- 1. Nunca se probo dentro del juego real (solo con luac -p, que valida
--    sintaxis, no la API real de Turbine) -- puede haber algun nombre de
--    metodo o firma que no sea exactamente como se documento en los
--    comentarios de worldmap.lua/worldmap_launcher.lua. Si tira un error
--    de Lua al cargar o al abrir el mapa, mandenme el texto exacto del
--    error (aparece en el chat, en rojo) y lo corrijo.
-- 2. El campo "dlc" de cada zona en worldmap_data.lua todavia no esta
--    cargado (la ventana flotante muestra "DLC requerido: pendiente").
-- 3. El resaltado de zona es un recuadro semitransparente detras del
--    nombre, no un relleno con la forma exacta de la zona (ver punto 3 del
--    comentario grande en worldmap.lua).

import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

import "WorldMap_Addon.worldmap_data"
import "WorldMap_Addon.tooltip_data"
-- v2.1: puente de solo lectura con LOTRO_Quest_Assistant (ver ese archivo);
-- va antes de worldmap.lua, que lo toma en una local al cargarse.
import "WorldMap_Addon.worldmap_quests"
-- v2.6: hazañas por zona (datos generados + sincronizacion con Deed Tracker)
import "WorldMap_Addon.worldmap_deeds_data"
import "WorldMap_Addon.worldmap_deeds"
-- v3.3: hazañas con progreso (chat compartido) / completadas, para el mapa de zona
import "WorldMap_Addon.worldmap_deedactive"
-- v3.1: mapas de zona (datos generados + ventana); van antes de
-- worldmap.lua, que abre esa ventana al hacer clic en una zona.
import "WorldMap_Addon.worldmap_zonemaps_data"
-- v3.2: capas del panel "Filtros del Mapa" (datos generados) y el panel
import "WorldMap_Addon.worldmap_layers_data"
import "WorldMap_Addon.worldmap_filters"
-- v3.5: mapas interiores y ficha de incursiones / mazmorras
import "WorldMap_Addon.worldmap_instances_data"
-- v3.5: nombres en español que faltaban
import "WorldMap_Addon.worldmap_names_es"
-- v3.8: informacion de hazañas de Deed Tracker para el cartel (opcional)
pcall(import, "WorldMap_Addon.worldmap_deedinfo_data")
import "WorldMap_Addon.worldmap_zonemap"
import "WorldMap_Addon.worldmap"
import "WorldMap_Addon.worldmap_launcher"

_G.WorldMapAddon = _G.WorldMapAddon or {}

local function Iniciar()
	WorldMapAddon.launcher = WorldMapAddon.UI.Launcher()
	Turbine.Shell.WriteLine("<rgb=#00FF00>Mapa del Mundo: addon cargado. Buscá el icono del mapa en pantalla (arrastralo para moverlo, click derecho para bloquear la posición, click izquierdo para desplegar los iconos: Mapa, Misiones y Recolección).</rgb>")
end

local ok, err = pcall(Iniciar)
if not ok then
	Turbine.Shell.WriteLine("<rgb=#FF0000>Mapa del Mundo: error al iniciar -- " .. tostring(err) .. "</rgb>")
end

-- v2.3: al descargar este addon, Quest Assistant recupera sus iconos
-- sueltos (el icono principal del mapa los tenia ocultos, ver
-- worldmap_launcher.lua). Mismo patron que LUI (Plugins["LUI"].Unload);
-- la clave es el <Name> de MapaDelMundo.plugin.
pcall(function()
	local me = Plugins ~= nil and Plugins["Mapa del Mundo"] or nil
	if me ~= nil then
		me.Unload = function()
			if WorldMapAddon.launcher ~= nil then
				pcall(function() WorldMapAddon.launcher:RestoreLqaLauncher() end)
			end
		end
	end
end)
