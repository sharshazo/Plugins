-- LOTRO_Quest_Assistant/Core/MoorMapZoneResolver.lua
-- Encuentra, para una coordenada region/ns/ew (la misma que devuelve /loc),
-- cual de los 206 mapas reales de Data/MoorMapZones.lua la contiene --
-- prefiriendo el de MAYOR tier (mas zoom/mas especifico) cuando varios
-- coinciden, igual criterio que usa el propio MoorMap para resolver mapas
-- (comentario real en su Defaults.lua: "Tier is... used to determine the
-- best map for adding annotations whose coordinates are included in more
-- than one map").
--
-- POR QUE ESTO REEMPLAZA A Data/WarbandMapBounds.lua PARA GatherSync
-- (2026-08-23): WarbandMapBounds tiene 53 cajas MUY grandes/imprecisas
-- (armadas originalmente para WarbandsSlayer, no para esto) -- confirmado en
-- vivo que un punto capturado cerca de Bree se etiquetaba "Eryn Lasgalen and
-- the Dale-lands" (a cientos de km de distancia real) porque esa caja
-- delimitadora era demasiado ancha y lo contenia matematicamente igual. Los
-- datos de MoorMap (extraidos de su propio Defaults.lua) son mucho mas
-- precisos: 206 mapas reales con limites ajustados de verdad.
import "Turbine"

_G.MoorMapZoneResolver = {}

-- entry: {idx, name, image, width, height, hFactor, hOffset, vFactor,
-- vOffset, region, minNS, maxNS, minEW, maxEW, tier}
--
-- BUG REAL encontrado en auditoria (2026-09-07): el dato CRUDO de MoorMap
-- (GaranStuff/MoorMap/Defaults.lua, tmpMapInfo[370] "mossward") trae
-- MinNS=60.98 > MaxNS=-60.35 -- limites invertidos en la FUENTE original, no
-- un error nuestro de extraccion (Data/MoorMapZones.lua copia ese dato tal
-- cual, como debe ser).
--
-- INTENTO 1 (revertido, causo un bug PEOR -- confirmado en vivo 2026-09-07
-- con captura real: un punto en Eregion se guardo como "Musgovilla" /
-- Mossward): normalizar min/max (intercambiarlos si minNS>maxNS) asumiendo
-- que solo estaban invertidos por una transcripcion al reves. Eso funciona
-- SOLO si los 2 valores son parecidos en magnitud -- aca no lo son
-- (60.98 vs -60.35), asi que el rango "normalizado" quedo de -60.35 a
-- +60.98 -- una franja de mas de 120 unidades de NS que cubre casi medio
-- mapa, tragandose zonas reales enteras (Eregion, tier 3) porque Mossward
-- tiene tier 4 (mas especifico) y gana el desempate.
--
-- FIX REAL: no se puede saber CUAL de los 2 valores es el que esta mal sin
-- una fuente externa que lo confirme -- adivinar cualquiera de las 2
-- direcciones (usar tal cual, o normalizar) puede fabricar una caja
-- gigante incorrecta. Lo unico seguro es DESCARTAR la zona de la
-- comparacion cuando sus limites no tienen sentido (min > max en cualquier
-- eje) -- vuelve a quedar "muerta" (nunca gana un match), que es mucho
-- menos daFino que ganar matches que no le corresponden: un punto real
-- cerca de Mossward cae en la region padre (correcto a nivel de zona
-- amplia, solo pierde el zoom especifico), en vez de robarle puntos a
-- CUALQUIER zona que se cruce con la caja fabricada.
--
-- (2026-09-30, pedido del jugador: "se dibujan fuera del mapa ciertos
-- nodos") Los limites de MoorMap son RECTANGULOS aproximados: un mismo
-- punto cae en varios mapas del mismo tier. P.ej. 7.0S 110.9W esta dentro
-- de "Durin's Way", "The Great Delving" y "Zelem Melek" (los 3 tier 4) y
-- antes ganaba el primero de la lista (Durin's Way), donde ese lugar cae en
-- la zona vacia del dibujo (la salida "hacia la Gran Excavacion"). Ahora,
-- a igual tier, se prefiere (1) el mapa donde el punto cae DENTRO de la
-- imagen y (2) el de mas zoom (mas pixeles por unidad de coordenada =
-- mapa mas detallado de ese lugar). El tier sigue mandando primero.
local function _inside_image(entry, ns, ew)
    local px = ew * entry.hFactor + entry.hOffset
    local py = ns * entry.vFactor + entry.vOffset
    return px >= 0 and py >= 0 and px <= (entry.width or 0) and py <= (entry.height or 0)
end

local function _better(entry, best, ns, ew)
    if best == nil then return true end
    local t1, t2 = entry.tier or 0, best.tier or 0
    if t1 ~= t2 then return t1 > t2 end
    local in1, in2 = _inside_image(entry, ns, ew), _inside_image(best, ns, ew)
    if in1 ~= in2 then return in1 end
    return math.abs(entry.hFactor) > math.abs(best.hFactor)
end

function MoorMapZoneResolver.Resolve(region, ns, ew)
    if region == nil or ns == nil or ew == nil or _G.MoorMapZones == nil then return nil end

    local best = nil
    for _, entry in ipairs(MoorMapZones) do
        if entry.region == region and entry.hFactor ~= 0 and entry.vFactor ~= 0 and
            entry.minNS <= entry.maxNS and entry.minEW <= entry.maxEW and
            ns >= entry.minNS and ns <= entry.maxNS and
            ew >= entry.minEW and ew <= entry.maxEW then
            if _better(entry, best, ns, ew) then
                best = entry
            end
        end
    end
    return best
end

-- Convierte ns/ew a pixel DENTRO de la imagen nativa de zone (formula real
-- de MoorMap, confirmada leyendo su Main.lua lineas 6708-6710/7411-7460):
-- px = ew*hFactor+hOffset, py = ns*vFactor+vOffset.
function MoorMapZoneResolver.ToPixel(zone, ns, ew)
    if zone == nil then return nil end
    local px = math.floor(ew * zone.hFactor + zone.hOffset)
    local py = math.floor(ns * zone.vFactor + zone.vOffset)
    return px, py
end

-- Busca una zona por idx (para reabrir el mapa de un punto ya guardado sin
-- tener que volver a resolver por coordenada).
function MoorMapZoneResolver.GetByIdx(idx)
    if idx == nil or _G.MoorMapZones == nil then return nil end
    for _, entry in ipairs(MoorMapZones) do
        if entry.idx == idx then return entry end
    end
    return nil
end

-- Nombre de zona en el idioma activo -- traduccion real via el "diccionario
-- maestro" (LotRO Companion/app/data/lore/labels/{en,es}/parchmentMaps.xml +
-- geoAreas.xml, la misma fuente profesional que usa el resto del addon, ver
-- Data/MoorMapZonesES.lua), NUNCA traduccion automatica. Emparejado por
-- texto (MoorMap no comparte el ID numerico de LotRO Companion) asi que no
-- cubre el 100% -- 177/206 zonas reales tienen ES; el resto cae al ingles
-- (mismo criterio de respaldo que LocalizedText() ya usa en todo el resto
-- del addon cuando falta traduccion).
function MoorMapZoneResolver.DisplayName(name)
    if name == nil then return "" end
    if _G.LanguageSettings and LanguageSettings.IsSpanish() and _G.MoorMapZonesES then
        return MoorMapZonesES[name] or name
    end
    return name
end
