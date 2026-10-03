-- LOTRO_Quest_Assistant/Persistence/GatherPointsStore.lua
-- Guarda los puntos de recoleccion que el propio jugador va descubriendo,
-- uno por personaje (mismo patron que Core/QuestStateManager.lua:
-- Turbine.PluginData con Turbine.DataScope.Character, carga asincrona).
--
-- Resuelve a que zona pertenece un punto usando Core/MoorMapZoneResolver.lua
-- + Data/MoorMapZones.lua (206 mapas reales extraidos del propio MoorMap).
--
-- CAMBIO (2026-08-23): antes esto usaba Data/WarbandMapBounds.lua (53 cajas
-- NS/EW, pedido original del usuario de no depender de MoorMap). Se
-- confirmo en vivo un bug real: esas cajas eran demasiado grandes/imprecisas
-- (armadas para WarbandsSlayer, no para esto) -- un punto capturado cerca de
-- Bree se guardaba como "Eryn Lasgalen and the Dale-lands", a cientos de km
-- de distancia real, porque esa caja ancha lo contenia matematicamente
-- igual. El usuario pidio despues explicitamente usar los mapas/iconos
-- reales de MoorMap dentro de nuestra propia ventana (ver historial completo
-- en UI/GatherWindow.lua) -- esto ya no evita "depender del numero de
-- region", lo usa a proposito porque es mucho mas preciso.
--
-- Los puntos ahora se agrupan por zoneIdx (numero, ver Data/MoorMapZones.lua)
-- en vez de por nombre de archivo .jpg. Puntos guardados ANTES de este
-- cambio (con mapFile tipo "32.jpg" como clave) quedan huerfanos -- muy
-- pocos existian (fase de prueba), no se escribio migracion para no sumar
-- complejidad por datos de prueba ya sabidos incorrectos.
import "Turbine"

_G.GatherPointsStore = {}

local SAVE_KEY = "QuestSync_GatherPoints"

-- Mismo umbral de distancia que ya usa MoorMap para emparejar cofres
-- (Main.lua linea ~3336, "< .2121 == .15 de margen en cada eje") -- criterio
-- ya validado en este ecosistema, no inventado.
local DEDUP_DISTANCE = 0.2121

-- State.Points[profesion][zoneIdx] = { {node=, tier=, confidence=, ns=, ew=,
--   region=, timesSeen=, firstSeen=, lastSeen=}, ... }
GatherPointsStore.Points = {}

-- (2026-09-30) Reubica los puntos ya guardados si ahora pertenecen a otro
-- mapa (ver la nota del desempate en Core/MoorMapZoneResolver.Resolve: p.ej.
-- los puntos de 7S 110-112W estaban en "Durin's Way", fuera del dibujo, y
-- su mapa es "The Great Delving"). Solo mueve puntos con region/ns/ew
-- validos y un mapa encontrado; nunca borra nada. Devuelve cuantos movio.
function GatherPointsStore.RelocatePoints(points)
    local resolver = _G.MoorMapZoneResolver
    if resolver == nil or type(points) ~= "table" then return 0 end
    local moved = 0
    for _, zones in pairs(points) do
        if type(zones) == "table" then
            local moves = {}
            for idx, list in pairs(zones) do
                if type(list) == "table" then
                    for i = #list, 1, -1 do
                        local p = list[i]
                        if type(p) == "table" and type(p.ns) == "number" and type(p.ew) == "number" and p.region ~= nil then
                            local zone = resolver.Resolve(p.region, p.ns, p.ew)
                            if zone ~= nil and zone.idx ~= idx then
                                table.remove(list, i)
                                moves[#moves + 1] = { zone.idx, p }
                            end
                        end
                    end
                end
            end
            for _, m in ipairs(moves) do
                zones[m[1]] = zones[m[1]] or {}
                table.insert(zones[m[1]], m[2])
                moved = moved + 1
            end
        end
    end
    return moved
end

function GatherPointsStore.Initialize()
    GatherPointsStore.Points = {}

    Turbine.PluginData.Load(Turbine.DataScope.Character, SAVE_KEY, function(loadedData)
        if loadedData and type(loadedData) == "table" then
            GatherPointsStore.Points = loadedData
            local okMove, moved = pcall(GatherPointsStore.RelocatePoints, loadedData)
            if okMove == true and type(moved) == "number" and moved > 0 then
                GatherPointsStore.Save()
            end
            if LQA and LQA.Core and LQA.Core.EventBus then
                LQA.Core.EventBus:Publish("GATHER_POINTS_LOADED", {})
            end
        end
    end)
end

function GatherPointsStore.Save()
    Turbine.PluginData.Save(Turbine.DataScope.Character, SAVE_KEY, GatherPointsStore.Points)
end

local function Distance(ns1, ew1, ns2, ew2)
    local dNS, dEW = ns1 - ns2, ew1 - ew2
    return math.sqrt(dNS * dNS + dEW * dEW)
end

-- entry = { profession=, node=, tier=, confidence= } (mismo objeto que
-- devuelve GatherNodesDB), ns/ew/region = coordenada capturada por
-- LocationAdapter (region es el mismo numero crudo "r<N>" de /loc).
function GatherPointsStore.AddPoint(entry, ns, ew, region)
    if entry == nil or ns == nil or ew == nil then return false, "datos incompletos" end

    local zone = _G.MoorMapZoneResolver and MoorMapZoneResolver.Resolve(region, ns, ew)
    if zone == nil then
        -- Confirmacion siempre visible (no gateada por LQA.Debug.Enabled),
        -- mismo criterio que QuestStateManager.SetQuestActive: es el
        -- resultado real de una accion del jugador, no ruido interno.
        Turbine.Shell.WriteLine("<rgb=#FF0000>GatherSync: sin mapa conocido para esa coordenada [" ..
            tostring(ns) .. "N/S, " .. tostring(ew) .. "E/W] -- punto NO guardado.</rgb>")
        return false, "sin mapa conocido para esa coordenada"
    end

    local prof = entry.profession
    GatherPointsStore.Points[prof] = GatherPointsStore.Points[prof] or {}
    GatherPointsStore.Points[prof][zone.idx] = GatherPointsStore.Points[prof][zone.idx] or {}
    local list = GatherPointsStore.Points[prof][zone.idx]

    local now = Turbine.Engine.GetGameTime()

    for _, existing in ipairs(list) do
        if existing.node == entry.node and Distance(existing.ns, existing.ew, ns, ew) < DEDUP_DISTANCE then
            existing.timesSeen = (existing.timesSeen or 1) + 1
            existing.lastSeen = now
            GatherPointsStore.Save()
            LQA.Core.EventBus:Publish("GATHER_POINT_UPDATED", { profession = prof, zoneIdx = zone.idx, point = existing })
            return true, "actualizado"
        end
    end

    local point = {
        node = entry.node,
        tier = entry.tier,
        zone = entry.zone,
        confidence = entry.confidence,
        ns = ns,
        ew = ew,
        region = region,
        timesSeen = 1,
        firstSeen = now,
        lastSeen = now,
    }
    table.insert(list, point)
    GatherPointsStore.Save()

    -- Ya no es "siempre visible" (2026-09-07, pedido del usuario: "sacar los
    -- ruidos del chat") -- el cierre del boton flotante (GatherCaptureButton,
    -- se esconde al recibir GATHER_POINT_ADDED) ya confirma visualmente que
    -- el guardado funciono, no hace falta ademas un mensaje de chat. La
    -- confirmacion de FALLO (arriba, "sin mapa conocido") si se deja visible
    -- -- un guardado que falla en silencio es peor que uno exitoso sin aviso.
    if LQA.Debug.Enabled then
        local zoneDisplayName = _G.MoorMapZoneResolver and MoorMapZoneResolver.DisplayName(zone.name) or zone.name
        Turbine.Shell.WriteLine("<rgb=#00FF00>GatherSync: punto nuevo guardado -> " .. tostring(entry.node) ..
            " (tier " .. tostring(entry.tier) .. ") en " .. tostring(zoneDisplayName) ..
            " [" .. tostring(ns) .. "N/S, " .. tostring(ew) .. "E/W]</rgb>")
    end

    LQA.Core.EventBus:Publish("GATHER_POINT_ADDED", { profession = prof, zoneIdx = zone.idx, point = point })
    return true, "nuevo"
end

-- Lista de puntos de una profesion+zona (para GatherWindow.lua).
function GatherPointsStore.GetPoints(profession, zoneIdx)
    if GatherPointsStore.Points[profession] == nil then return {} end
    return GatherPointsStore.Points[profession][zoneIdx] or {}
end

-- Lista de zonas que tienen al menos un punto guardado para esa profesion
-- (para el selector de zona) -- evita mostrar los 206 mapas si el jugador
-- solo recolecto en unos pocos. Ignora en silencio claves huerfanas de
-- antes del cambio a zoneIdx numerico (ver historial arriba).
function GatherPointsStore.GetMapsWithPoints(profession)
    local result = {}
    if GatherPointsStore.Points[profession] == nil then return result end
    for zoneIdx, list in pairs(GatherPointsStore.Points[profession]) do
        if #list > 0 then
            local zone = _G.MoorMapZoneResolver and MoorMapZoneResolver.GetByIdx(zoneIdx)
            if zone ~= nil then
                table.insert(result, { zoneIdx = zoneIdx, name = zone.name, count = #list })
            end
        end
    end
    table.sort(result, function(a, b) return (a.name or "") < (b.name or "") end)
    return result
end
