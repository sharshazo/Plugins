-- LOTRO_Quest_Assistant/Legacy/LocationAdapter.lua
-- Captura la coordenada actual del jugador para GatherSync (ver
-- Arquitectura_GatherSync.md #3.3). Mismo principio que MoorMapAdapter.lua:
-- no existe una funcion Lua que devuelva la posicion directamente -- hay que
-- disparar el comando nativo /loc (via un Quickslot oculto con Shortcut de
-- tipo Alias, mismo truco documentado en ESTRUCTURA_DEL_CODIGO.md #6.1) y
-- parsear la linea de chat que el juego imprime como respuesta.
--
-- El patron de abajo (locale ESPAÑOL) esta confirmado leyendo el codigo REAL
-- de MoorMap (MoorMap ver 1_66/GaranStuff/MoorMap/Main.lua lineas 3242-3249),
-- que tiene exactamente este string documentado en un comentario:
--   "Estás en el servidor Peregrin 11 en r2 lx773 ly669 i39 ox105.15
--    oy109.54 oz302.48 h77.3. Marca de tiempo del juego 38653147.076."
-- No se adivino -- MoorMap ya soporta este idioma en produccion.
--
-- La formula lx/ly -> NS/EW (linea comentario 22 de Main.lua, y usada 2 veces
-- mas en el archivo con las mismas constantes) tambien viene de ahi, es
-- universal (no depende de la region):
--   ew = ((floor(lx/8)*160 + ox) - 29360) / 200
--   ns = ((floor(ly/8)*160 + oy) - 24880) / 200
--
-- La zona se resuelve via MoorMapZoneResolver.Resolve(region, ns, ew) contra
-- Data/MoorMapZones.lua (206 mapas reales de MoorMap, mucho mas precisos que
-- las 53 cajas de WarbandMapBounds.lua que se usaban antes -- ver historial
-- completo en Persistence/GatherPointsStore.lua/UI/GatherWindow.lua). Este
-- archivo solo captura/parsea region+ns+ew crudos, ese resto vive en
-- GatherPointsStore.AddPoint.
--
-- CONFIRMADO EN VIVO (2026-08-23): un quickslot:MouseClick() PROGRAMATICO
-- (sin clic fisico real) NO dispara el alias -- se probo, "GatherSync:
-- pidiendo /loc..." aparecia en el chat pero nunca llegaba la respuesta de
-- /loc. Por eso este archivo ya NO expone una funcion "RequestLocation" que
-- se llame sola: en su lugar expone CreateQuickslot/AttachToButton (mismo
-- patron EXACTO que MoorMapAdapter.CreateQuickslot/AttachToButton, ver
-- ESTRUCTURA_DEL_CODIGO.md #6.1) para que una UI visible (ver
-- UI/GatherCaptureButton.lua) parentee el quickslot real detras de un boton
-- que el jugador clickea de verdad -- el click SI llega a traves de ese
-- patron porque es exactamente el mismo mecanismo que ya usan de forma
-- probada los botones "Ir" de MoorMap/Waypoint en QuestSyncWindow.
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.LocationAdapter = {}

local PATTERNS = {
    -- Con "cInside" (interior) y con "i<N>" (instancia) -- mismo orden que
    -- MoorMap prueba (patternString4, 3, 2, 1 de mas especifico a menos).
    "Estás en el servidor .* en r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)",
    "Estás en el servidor .* en r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) i(%d+) ox(%d+%.?%d*) oy(%d+%.?%d*) oz(%d+%.?%d*)",
    "Estás en el servidor .* en r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)",
    "Estás en el servidor .* en r(%d+) lx(%d+%.?%d*) ly(%d+%.?%d*) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)",
}

-- (2026-10-04) Respaldo SIN depender del idioma. Reporte del jugador: la
-- ventanita "Guardar ubicacion de recoleccion" aparecia, pero al pulsarla
-- no se guardaba nada. Los 4 patrones de arriba exigen el texto en espanol
-- "Estás en el servidor ... en r<N> ...", pero el parche de traduccion de
-- este cliente deja varias plantillas del juego en ingles (el registro
-- QuestSync_Diag muestra "New Quest:", "Collected ...", "Defeated the ...")
-- -- si /loc responde "You are on Glamdring server 12 at r2 lx... ly...
-- ox... oy... oz...", ningun patron coincidia y el punto se perdia en
-- silencio. Esta busqueda solo mira los datos (r, lx, ly, ox, oy, oz), que
-- son iguales en cualquier idioma. Se usa SOLO si los 4 patrones de arriba
-- no coinciden, asi que el caso que ya funcionaba sigue exactamente igual.
-- Acepta coma decimal por si el cliente la usara ("ox105,15").
local NUM = "(%-?[%d]+[%.,]?%d*)"
local function _num(text)
    if text == nil then return nil end
    return tonumber((string.gsub(text, ",", ".")))
end

local function _GenericMatch(message)
    local region, lx, ly = string.match(message, "r(%d+)%s+lx" .. NUM .. "%s+ly" .. NUM)
    if region == nil then return nil end
    local ox, oy, oz = string.match(message, "ox" .. NUM .. "%s+oy" .. NUM .. "%s+oz" .. NUM)
    if ox == nil then return nil end
    return region, lx, ly, ox, oy, oz
end

local function ToNSEW(lx, ly, ox, oy)
    local ew = ((math.floor(lx / 8) * 160 + ox) - 29360) / 200
    local ns = ((math.floor(ly / 8) * 160 + oy) - 24880) / 200
    return ns, ew
end

-- Callback registrado por GatherEventParser/GatherWindow: se llama con
-- (region, ns, ew) cuando una respuesta de /loc termina de parsearse.
LocationAdapter.OnLocationResolved = nil

-- Aviso visible (una vez por sesion) si llega algo con forma de /loc que
-- ninguna busqueda entiende -- antes eso fallaba sin decir nada.
local unparsedWarned = false

function LocationAdapter.ParseLocationMessage(message)
    if not message then return false end
    local candidates = {}
    for _, pattern in ipairs(PATTERNS) do
        candidates[#candidates + 1] = { string.match(message, pattern) }
    end
    candidates[#candidates + 1] = { _GenericMatch(message) }
    for _, found in ipairs(candidates) do
        local region, lx, ly, ox, oy, oz = _num(found[1]), _num(found[2]), _num(found[3]),
            _num(found[4]), _num(found[5]), _num(found[6])
        if region ~= nil and lx ~= nil and ly ~= nil and ox ~= nil and oy ~= nil then
            local ns, ew = ToNSEW(lx, ly, ox, oy)
            -- Ya no es "siempre visible" (2026-09-07, pedido del usuario:
            -- "sacar los ruidos del chat") -- esto se disparaba con
            -- CUALQUIER /loc exitoso, no solo los de recoleccion (el
            -- jugador puede usar /loc por curiosidad o via otro addon), asi
            -- que era la fuente de ruido mas frecuente de las 4. Ver nota
            -- igual en GatherPointsStore.lua/GatherEventParser.lua.
            if LQA.Debug.Enabled then
                Turbine.Shell.WriteLine("<rgb=#00AAFF>GatherSync: /loc resuelto -> region=" ..
                    tostring(region) .. " ns=" .. tostring(ns) .. " ew=" .. tostring(ew) .. "</rgb>")
            end
            if LocationAdapter.OnLocationResolved ~= nil then
                LocationAdapter.OnLocationResolved(region, ns, ew, lx, ly)
            end
            return true
        end
    end
    if not unparsedWarned and string.find(message, "lx%d") ~= nil and string.find(message, "ly%d") ~= nil then
        unparsedWarned = true
        Turbine.Shell.WriteLine("<rgb=#FF0000>GatherSync: no pude leer la respuesta de /loc, el punto NO se guardo. " ..
            "Texto recibido: " .. string.sub(message, 1, 160) .. "</rgb>")
    end
    return false
end

-- Quickslot oculto -- mismo patron EXACTO que MoorMapAdapter.CreateQuickslot
-- (ver ESTRUCTURA_DEL_CODIGO.md #6.1): Visible(true) + Opacity(0) para
-- recibir el clic, SetAllowDrop(false). A proposito NO se asigna el
-- Shortcut aca -- en el codigo real de MoorMap, CreateQuickslot() SIEMPRE
-- devuelve un Quickslot en blanco, y SetShortcut se llama en un paso
-- SEPARADO, mas tarde (ver MoorMapAdapter.lua ~linea 154-155, "SetShortcut"
-- solo aparece fuera de CreateQuickslot). El juego se cerro (2026-08-23) tras
-- una version anterior de este archivo que llamaba SetShortcut DENTRO de
-- CreateQuickslot, antes de que el Quickslot tuviera padre -- no hay
-- evidencia 100% de que esa fuera la causa exacta, pero es la unica
-- diferencia real contra el patron ya probado en produccion, asi que se
-- corrige para calzar exacto en vez de arriesgar otra teoria.
function LocationAdapter.CreateQuickslot()
    local qs = Turbine.UI.Lotro.Quickslot()
    qs:SetSize(32, 32)
    qs:SetVisible(true)
    qs:SetOpacity(0)
    qs:SetAllowDrop(false)
    return qs
end

function LocationAdapter.AttachToButton(quickslot, button)
    quickslot:SetParent(button)
    local w, h = button:GetSize()
    quickslot:SetPosition(0, 0)
    quickslot:SetSize(w, h)
    quickslot:SetZOrder(10)
end

-- Se llama DESPUES de AttachToButton (mismo orden atado-al-padre-primero que
-- usa MoorMapAdapter.SetQuestMarker con su propio quickslot).
function LocationAdapter.SetLocShortcut(quickslot)
    quickslot:SetShortcut(Turbine.UI.Lotro.Shortcut(Turbine.UI.Lotro.ShortcutType.Alias, "/loc"))
end
