-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

import "LUI.src.Languages.de"
import "LUI.src.Languages.fr"
import "LUI.src.Languages.es"

local LUI = _G.LUI
local Locale = _G.LUI.Locale

local LANGUAGE_TABLES = {
    de = LUI.src.Languages.de.DE,
    fr = LUI.src.Languages.fr.FR,
    -- es.lua ya existia completo (1145 entradas) pero nunca se importaba
    -- ni se registraba aca -- por eso Inventario/Opciones/etc se quedaban
    -- en ingles al pasar el cliente a español: _language_code_from_value
    -- de abajo tampoco tenia NINGUN caso para español, caia siempre al
    -- "return en" del final sin importar el idioma real del cliente.
    es = LUI.src.Languages.es.ES,
}

-- Override manual guardado en Settings (global.language: "auto"/"en"/
-- "es"/"de"/"fr") -- ver Settings/Tabs/Global/global_page.lua. Necesario
-- porque el valor numerico real que el cliente en español devuelve en
-- Turbine.Engine.GetLanguage() no esta confirmado (ni siquiera otros
-- addons de esta carpeta lo saben -- MoorMap/Main.lua tiene un comentario
-- textual: "not sure what the ES client uses for Turbine.Language.Spanish").
-- Sin adivinar un numero que podria detectar mal el idioma, un dropdown
-- manual es la via confiable. nil hasta que Settings termine de cargar
-- (ver nota grande en Locale.reload_translations mas abajo).
Locale.language_override = nil

-- (2026-10-02) Idioma guardado en un archivo propio (scope de cuenta,
-- lectura SINCRONA): las traducciones de TODOS los modulos que arman
-- textos al importarse (listas de opciones, etiquetas del lanzador,
-- Bestiario, Ayuda...) se calculan ANTES de que Persistence cargue el
-- perfil, asi que sin esto se quedaban en ingles aunque el perfil dijera
-- "es". main.lua y la ventana de configuracion mantienen este archivo al
-- dia con Locale.persist_language(). Todo va en pcall: si algo falla,
-- se usa la deteccion normal del cliente.
local LANGUAGE_FILE_KEY = "LUI_LANGUAGE_OVERRIDE"

local function _read_saved_language()
    local ok, value = pcall(function()
        return Turbine.PluginData.Load(Turbine.DataScope.Account, LANGUAGE_FILE_KEY)
    end)
    if ok and type(value) == "string" then
        if value == "auto" or value == "en" or LANGUAGE_TABLES[value] ~= nil then
            return value
        end
    end
    return nil
end

Locale.language_override = _read_saved_language()
Locale._persisted_language = Locale.language_override

local function _language_code_from_value(lang)
    if type(lang) == "number" then
        local language_enum = Turbine.Language
        if lang == language_enum.German then
            return "de"
        end
        if lang == language_enum.French then
            return "fr"
        end
        if lang == language_enum.English or lang == language_enum.EnglishGB then
            return "en"
        end
        -- Solo se usa el enum con nombre real (Turbine.Language.Spanish),
        -- nunca un numero adivinado -- si el cliente no lo expone, este
        -- chequeo simplemente no aplica (deja pasar al resto de la
        -- funcion) en vez de arriesgar una deteccion incorrecta.
        --
        -- BUG CORREGIDO (reportado por el usuario: "desaparecio el icono
        -- flotante de LUI"): esta era la sospecha real -- Turbine.Language
        -- podria ser un enum del motor, no una tabla Lua comun, y acceder
        -- a un miembro que no existe (".Spanish") tirar un error en vez de
        -- devolver nil. Esto corre en Locale.TR = _load_translations()
        -- (mas abajo en este mismo archivo), que se ejecuta al IMPORTAR
        -- este archivo -- mucho antes de que exista ninguna ventana de
        -- LUI, launcher incluido. Un error aca tira abajo TODO lo que se
        -- importa despues. pcall lo hace seguro sin importar que tipo de
        -- objeto sea realmente Turbine.Language.
        local ok, spanish_value = pcall(function() return language_enum.Spanish end)
        if ok and spanish_value ~= nil and lang == spanish_value then
            return "es"
        end

        if lang == 3 then
            return "de"
        end
        if lang == 2 then
            return "fr"
        end
        return "en"
    end

    if type(lang) == "string" then
        local l = lang:lower():gsub("_", "-")
        if l == "de" or l:find("^de%-") == 1 then
            return "de"
        end
        if l == "fr" or l:find("^fr%-") == 1 then
            return "fr"
        end
        if l == "es" or l:find("^es%-") == 1 then
            return "es"
        end
        -- Treat en / en-gb / en-us etc as English.
        return "en"
    end

    -- Unknown numeric enum or missing API: default to English.
    return "en"
end

local function _detect_language_code()
    if Locale.language_override ~= nil and Locale.language_override ~= "auto" then
        return Locale.language_override
    end
    return _language_code_from_value(Turbine.Engine.GetLanguage())
end

-- BUG CORREGIDO (encontrado revisando el crash del icono, no reportado
-- todavia por el usuario pero real): esta funcion devolvia la tabla
-- ORIGINAL de es.lua/de.lua/fr.lua directamente (LANGUAGE_TABLES[code] es
-- LITERALMENTE LUI.src.Languages.es.ES, no una copia). La PRIMERA vez que
-- carga el idioma, Locale.TR = esa misma tabla (linea 103 mas abajo). Si
-- despues Locale.reload_translations() corre de nuevo con el MISMO
-- idioma, "fresh" y "Locale.TR" terminan siendo el mismo objeto -- el
-- primer for-loop (que limpia Locale.TR) tambien vacia "fresh" al mismo
-- tiempo (son la misma tabla), y el segundo for-loop copia de una tabla
-- ya vacia -- el diccionario real de 1145 entradas quedaria borrado para
-- siempre en memoria. Se devuelve una copia nueva siempre, nunca la tabla
-- original.
local function _translation_table_for_code(code)
    if code == "en" then
        return {}
    end
    local source = LANGUAGE_TABLES[code]
    if source == nil then
        return {}
    end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local TR_METATABLE = { __index = function(k, v) return v or k end }

local function _load_translations()
    local code = _detect_language_code()
    local tr = _translation_table_for_code(code)
    setmetatable(tr, TR_METATABLE)
    return tr
end

-- BUG CORREGIDO (reportado por el usuario: "LUI mantiene error de icono
-- flotante y no abre el addons y sus funciones" -- el pcall puntual de
-- mas arriba, alrededor de language_enum.Spanish, NO alcanzo). Esta linea
-- es codigo de NIVEL SUPERIOR (no esta dentro de ninguna funcion) que
-- corre INMEDIATAMENTE al importar este archivo -- si _load_translations
-- (o cualquier cosa que llame, directa o indirectamente: _detect_
-- language_code, _language_code_from_value, Turbine.Engine.GetLanguage())
-- tira CUALQUIER error, no hay ningun pcall que lo atrape aca todavia, y
-- el import de este archivo completo aborta -- lo que corta TODO lo que
-- main.lua importa despues (Windows.launcher incluido, mucho mas abajo).
-- Ahora esta TODA la deteccion envuelta en pcall, con un fallback a una
-- tabla vacia (equivale a ingles sin traducir, el modo mas seguro) si
-- algo sale mal -- sin importar la causa exacta, Locale.TR SIEMPRE queda
-- en un estado usable.
local ok, result = pcall(_load_translations)
if ok then
    Locale.TR = result
else
    Locale.TR = setmetatable({}, TR_METATABLE)
end

function Locale.is_english_language()
    local ok, code = pcall(_detect_language_code)
    return ok ~= true or code == "en"
end

function Locale.language_code()
    local ok, code = pcall(_detect_language_code)
    if ok then
        return code
    end
    return "en"
end

-- Recalcula Locale.TR usando el override manual guardado por el usuario
-- (Settings/Tabs/Global/global_page.lua) -- llamado desde main.lua justo
-- despues de Persistence.load_settings(), que es cuando State.settings
-- recien tiene el valor REAL guardado (este archivo se importa mucho
-- antes de eso, ver Utils/__init__.lua -> main.lua linea ~38, contra
-- Persistence.load_settings() en la linea ~487 -- si State.settings.
-- global.language se leyera aca arriba, siempre seria nil).
--
-- MUTA Locale.TR EN EL MISMO LUGAR (borra sus entradas y las vuelve a
-- llenar) en vez de reemplazar la tabla -- decenas de archivos ya
-- hicieron "local TR = _G.LUI.Locale.TR" al importarse (captura la
-- REFERENCIA a esta tabla). Si aca se hiciera "Locale.TR = tabla_nueva"
-- esos TR locales seguirian apuntando a la tabla VIEJA -- Inventario/
-- Opciones/etc seguirian en ingles igual, ahora sin ninguna pista de por
-- que. Mutar en el mismo lugar hace que TODAS esas referencias vean el
-- cambio.
function Locale.reload_translations()
    local ok, code = pcall(_detect_language_code)
    if ok ~= true then
        return
    end
    local ok2, fresh = pcall(_translation_table_for_code, code)
    if ok2 ~= true then
        return
    end

    for key in pairs(Locale.TR) do
        Locale.TR[key] = nil
    end
    for key, value in pairs(fresh) do
        Locale.TR[key] = value
    end
end

-- (2026-10-02) Guarda el idioma elegido para que el proximo arranque lo
-- lea ANTES de importar los modulos (ver _read_saved_language arriba).
function Locale.persist_language(code)
    if type(code) ~= "string" or code == "" then
        return
    end
    if Locale._persisted_language == code then
        return
    end
    local ok = pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, LANGUAGE_FILE_KEY, code)
    if ok then
        Locale._persisted_language = code
    end
end
