-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Runtime = _G.LUI.Runtime
local Windows = Runtime.Windows
local Commands = Runtime.Commands
local UI = _G.LUI.UI
local Shortcuts = UI.Shortcuts
local MoveMode = UI.MoveMode
local StatusBarCommon = _G.LUI.Features.StatusBar.Common
local StatusBarApiCommandParser = _G.LUI.Features.StatusBar.APICommandParser
import "LUI.src.StatusBar.api_command_parser"

local command = Turbine.ShellCommand()
Commands.shell = command

local HELP_COMMAND_COLOR = "#33C7FF"
local STATUS_BAR_API_USAGE = "/lui api sb --add -k key -t title -i image -c /command"

local function _write_help_command(prefix, translated_line_key)
    local line = TR[translated_line_key]
    if type(line) ~= "string" then
        return
    end

    local start_at, end_at = string.find(line, prefix, 1, true)
    if start_at ~= nil and end_at ~= nil then
        Turbine.Shell.WriteLine(
            string.sub(line, 1, start_at - 1) ..
            "<rgb=" .. HELP_COMMAND_COLOR .. ">" .. prefix .. "</rgb>" ..
            string.sub(line, end_at + 1)
        )
        return
    end

    Turbine.Shell.WriteLine(line)
end

local function display_help()
    Turbine.Shell.WriteLine(TR["Available commands:"])
    _write_help_command("/lui help", "  /lui help       - Print slash command help")
    _write_help_command("/lui config", "  /lui config     - Toggle configuration window")
    _write_help_command("/lui move", "  /lui move       - Toggle move mode")
    _write_help_command("/lui move cancel", "  /lui move cancel - Cancel move mode changes")
    _write_help_command("/lui inventory", "  /lui inventory  - Toggle inventory window")
    _write_help_command("/lui inv", "  /lui inv        - Short alias for /lui inventory")
    _write_help_command("/lui assets", "  /lui assets      - Toggle assets window")
    _write_help_command("/lui a", "  /lui a          - Short alias for /lui assets")
    _write_help_command("/lui craft", "  /lui craft      - Toggle crafting window")
    _write_help_command("/lui travel", "  /lui travel     - Toggle travel window")
    _write_help_command("/lui raid", "  /lui raid       - Toggle raid manager window")
    _write_help_command("/lui trav", "  /lui trav       - Short alias for /lui travel")
    _write_help_command("/lui encyclopedia", "  /lui encyclopedia - Toggle encyclopedia window")
    _write_help_command("/lui ency", "  /lui ency       - Alias for /lui encyclopedia")
    _write_help_command("/lui bestiary", "  /lui bestiary   - Alias for /lui encyclopedia")
    _write_help_command("/lui beast", "  /lui beast      - Alias for /lui bestiary")
    _write_help_command("/lui b", "  /lui b          - Short alias for /lui bestiary")
    _write_help_command("/lui card [monster name]", "  /lui card [monster name] - Open the bestiary card for a monster")
    _write_help_command("/lui menu", "  /lui menu       - Show the LUI Menu icon again (/lui menu off hides it)")
    _write_help_command("/lui diag", "  /lui diag       - Image check after a game update")
    _write_help_command("/lui puntero", "  /lui puntero    - Pointer effect: on / off / <style> / <color> / prueba")
    _write_help_command("/lui minimapa", "  /lui minimapa   - Minimap aura: on / off / colocar / <design> / <color> / <size>")
    _write_help_command("/lui cartel", "  /lui cartel     - Quest banner demo (all 11 styles); /lui cartel <quest name> shows that title")
    _write_help_command("/lui botin", "  /lui botin      - Historial de bot\195\173n de la sesi\195\179n (tambi\195\169n /botin)")
    _write_help_command("/lui api sb --add", "  /lui api sb --add -k key -t title -i image -c /command - Register a status bar API button")
end

local function _write_error(message)
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. tostring(message or ""))
end

-- (2026-09-30) El icono del menu LUI (launcher) quedaba apagado en los
-- perfiles nuevos y no habia forma rapida de volver a mostrarlo. "/lui menu"
-- lo activa en el perfil actual, lo trae a un lugar visible si quedo fuera
-- de la pantalla y guarda. "/lui menu off" lo apaga.
local function _set_launcher_enabled(enabled, quiet)
    local State = _G.LUI.Settings.State
    local Apply = _G.LUI.Runtime.Apply
    local loaded = State.loaded_settings
    if type(loaded) ~= "table" or type(loaded.launcher) ~= "table" then
        _write_error(TR["The LUI Menu settings are not loaded yet."])
        return
    end
    loaded.launcher.enabled = enabled == true
    loaded.launcher.setup_menu_v1 = true
    if enabled == true then
        local hud = loaded.ui and loaded.ui.hud and loaded.ui.hud.launcher
        if type(hud) == "table" then
            local sw = Turbine.UI.Display.GetWidth()
            local sh = Turbine.UI.Display.GetHeight()
            local left, top = tonumber(hud.left), tonumber(hud.top)
            if left == nil or top == nil or left < 0 or top < 0 or left > sw - 40 or top > sh - 40 then
                hud.left, hud.top = 20, 260
            end
        end
    end
    pcall(_G.LUI.Settings.rebuild)
    if Apply.launcher_settings ~= nil then
        Apply.launcher_settings()
    end
    pcall(_G.LUI.Settings.Persistence.save_settings)
    if quiet == true then
        return
    end
    if enabled == true then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. TR["LUI Menu icon enabled."])
    else
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. TR["LUI Menu icon disabled."])
    end
end

Commands.set_launcher_enabled = _set_launcher_enabled

-- (2026-09-30) Diagnostico de imagenes tras una actualizacion del juego.
-- Se muestra con "/lui diag" y ademas se guarda solo (LUI_DIAG, por
-- personaje) unos segundos despues de entrar, para poder revisarlo sin
-- tener que copiar nada del chat.
local function _measure(image_id)
    local probe = Turbine.UI.Control()
    local mw, mh = nil, nil
    pcall(function()
        probe:SetSize(0, 0)
        probe:SetBackground(image_id)
        probe:SetStretchMode(2)
        mw, mh = probe:GetSize()
        probe:SetStretchMode(0)
    end)
    return tostring(mw) .. "x" .. tostring(mh)
end

local function _collect_image_diag()
    local d = UI.Widgets.ImageDiag or {}
    local probe = Turbine.UI.Control()
    local State = _G.LUI.Settings.State
    local s = State and State.settings and State.settings.launcher
    return {
        attach_edges = tostring(probe.AttachEdges ~= nil),
        edge_enum = tostring(Turbine.UI.EdgeAttachmentType ~= nil),
        measure_tga_64 = _measure("LUI/assets/ui/x_64.tga"),
        measure_coin = _measure(0x41007e7b),
        table_hits = tostring(d.table_hits or 0),
        measured_ok = tostring(d.measured_ok or 0),
        measured_fail = tostring(d.measured_fail or 0),
        no_stretch = tostring(d.fallback or 0),
        last_fail = tostring(d.last_fail or ""),
        launcher_enabled = tostring(s ~= nil and s.enabled == true),
    }
end

local function _write_image_diag()
    local r = _collect_image_diag()
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> diag: AttachEdges=" .. r.attach_edges ..
        " EdgeAttachmentType=" .. r.edge_enum ..
        " | medida x_64 (debe ser 64x64) = " .. r.measure_tga_64 ..
        " | moneda = " .. r.measure_coin)
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> diag: tabla=" .. r.table_hits ..
        " medidas_ok=" .. r.measured_ok ..
        " medidas_fallidas=" .. r.measured_fail ..
        " sin_estirar=" .. r.no_stretch ..
        (r.last_fail ~= "" and (" ultima_fallida=" .. r.last_fail) or ""))
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> diag: menu LUI activo=" .. r.launcher_enabled)
    -- (2026-09-30) escalado: con "Use native LotRO UI scaling" las filas de
    -- botin se corren por este factor (ver Drops/drop_window.lua)
    local NS = UI.NativeScaling
    local State = _G.LUI.Settings.State
    local native = State and State.settings and State.settings.global and
        State.settings.global.native_scaling == true
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> diag: escalado nativo=" .. tostring(native) ..
        " escala global del juego=" .. tostring(NS.has_global_scale_api() and NS.get_global_scale() or "sin API"))
end

-- (2026-09-30) "/lui imgtest": ventana de prueba con la MISMA imagen de
-- 64x64 dibujada en una caja de 24x24 con distintas secuencias de la API
-- (A..J). Con una captura se ve cual escala bien en esta version del
-- juego; esa es la que usa LUI. Fila 1: .tga propio; fila 2: icono del
-- juego (pluma 0x41004D92).
local _imgtest_window = nil
local function _imgtest_variants(EA)
    local T = 24
    local function lim(c, w, h)
        if c.SetMinimumSize ~= nil then c:SetMinimumSize(1, 1) end
        if c.SetMaximumSize ~= nil then c:SetMaximumSize(w, h) end
    end
    local function maxonly(c, w, h)
        if c.SetMaximumSize ~= nil then c:SetMaximumSize(w, h) end
    end
    local function none(c)
        if EA ~= nil and c.AttachEdges ~= nil then pcall(c.AttachEdges, c, EA.None, EA.None, EA.None, EA.None) end
    end
    local function P(c, img) c:SetBackground(img); c:SetStretchMode(2); c:SetStretchMode(1); lim(c, T, T); c:SetSize(T, T) end
    local function L(c, img) c:SetBackground(img); c:SetStretchMode(1); lim(c, T, T); c:SetSize(T, T) end
    return {
        { "P1", function(c, img) P(c, img) end },
        { "P2", function(c, img) P(c, img); P(c, img) end },
        { "P0P", function(c, img) P(c, img); c:SetStretchMode(0); P(c, img) end },
        { "L2", function(c, img) L(c, img); L(c, img) end },
        { "Z0", function(c, img)
            for _ = 1, 2 do
                c:SetStretchMode(0)
                if c.SetMaximumSize ~= nil then c:SetMinimumSize(0, 0); c:SetMaximumSize(0, 0) end
                c:SetBackground(img); c:SetSize(64, 64); c:SetStretchMode(1); none(c); lim(c, T, T); c:SetSize(T, T)
            end
        end },
        { "Z1", function(c, img)
            for _ = 1, 2 do
                c:SetStretchMode(0); c:SetBackground(img); c:SetSize(64, 64); c:SetStretchMode(1); lim(c, T, T); c:SetSize(T, T)
            end
        end },
        { "Z2", function(c, img) P(c, img); if c.SetMaximumSize ~= nil then c:SetMaximumSize(4096, 4096) end; P(c, img) end },
        { "PE", function(c, img) P(c, img); none(c); P(c, img); none(c) end },
        { "M2", function(c, img)
            for _ = 1, 2 do c:SetBackground(img); c:SetStretchMode(2); c:SetStretchMode(1); maxonly(c, T, T); c:SetSize(T, T) end
        end },
        { "LUI", function(c, img) c:set_icon(img, T, T); c:set_icon(img, T, T) end },
    }
end

local function _open_imgtest()
    if _imgtest_window ~= nil then
        _imgtest_window:SetVisible(false)
        _imgtest_window = nil
        return
    end
    local EA = Turbine.UI.EdgeAttachmentType
    local w = Turbine.UI.Window()
    _imgtest_window = w
    w:SetSize(560, 150)
    w:SetPosition(300, 200)
    w:SetBackColor(Turbine.UI.Color(0.95, 0.05, 0.05, 0.08))
    w:SetMouseVisible(true)
    w:SetZOrder(2000)
    local title = Turbine.UI.Label()
    title:SetParent(w)
    title:SetPosition(8, 4)
    title:SetSize(540, 18)
    title:SetText("LUI imgtest - caja gris 24x24; la X debe caber EXACTA en la caja. LUI = como dibuja LUI ahora. (/lui imgtest cierra)")
    local images = { "LUI/assets/ui/x_64.tga", 0x41004D92 }
    local variants = _imgtest_variants(EA)
    local report = {}
    for row = 1, 2 do
        for i = 1, #variants do
            local v = variants[i]
            local x = 10 + (i - 1) * 54
            local y = 30 + (row - 1) * 58
            local label = Turbine.UI.Label()
            label:SetParent(w)
            label:SetPosition(x, y)
            label:SetSize(44, 16)
            label:SetText(v[1])
            local box = Turbine.UI.Control()
            box:SetParent(w)
            box:SetPosition(x + 14, y + 16)
            box:SetSize(24, 24)
            box:SetBackColor(Turbine.UI.Color(1, 0.35, 0.35, 0.35))
            local img = nil
            if v[1] == "LUI" then
                img = UI.Widgets.Image()
            else
                img = Turbine.UI.Control()
            end
            img:SetParent(w)
            img:SetPosition(x + 14, y + 16)
            img:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
            local ok, err = pcall(v[2], img, images[row])
            local gw, gh = img:GetSize()
            if row == 1 then
                local mn = ""
                if img.GetMinimumSize ~= nil then
                    local a, b = img:GetMinimumSize()
                    mn = "(min" .. tostring(a) .. "x" .. tostring(b) .. ")"
                end
                report[#report + 1] = v[1] .. "=" .. tostring(gw) .. "x" .. tostring(gh) .. mn .. (ok and "" or "!ERR")
            end
            if not ok then
                Turbine.Shell.WriteLine("LUI imgtest " .. v[1] .. ": " .. tostring(err))
            end
        end
    end
    w:SetVisible(true)
    local probe = Turbine.UI.Control()
    local mw, mh = "?", "?"
    pcall(function()
        probe:SetSize(0, 0)
        probe:SetBackground("LUI/assets/ui/x_64.tga")
        probe:SetStretchMode(2)
        mw, mh = probe:GetSize()
    end)
    local mm = ""
    pcall(function()
        local p2 = Turbine.UI.Control()
        p2:SetSize(64, 64)
        p2:SetBackground("LUI/assets/ui/x_64.tga")
        p2:SetStretchMode(1)
        local a, b = p2:GetMinimumSize()
        local c, d = p2:GetMaximumSize()
        p2:SetSize(24, 24)
        local e, f = p2:GetSize()
        mm = " modo1: min=" .. tostring(a) .. "x" .. tostring(b) .. " max=" .. tostring(c) .. "x" .. tostring(d) .. " tras24=" .. tostring(e) .. "x" .. tostring(f)
    end)
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> imgtest:" .. mm)
    Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb> imgtest: medida modo2=" .. tostring(mw) .. "x" .. tostring(mh) ..
        " AttachEdges=" .. tostring(probe.AttachEdges ~= nil) .. " EA=" .. tostring(EA ~= nil) ..
        " | " .. table.concat(report, " "))
end
Commands.open_imgtest = _open_imgtest

function Commands.save_image_diag()
    local ok, r = pcall(_collect_image_diag)
    if ok == true and type(r) == "table" then
        pcall(Turbine.PluginData.Save, Turbine.DataScope.Character, "LUI_DIAG", r)
    end
end

-- (2026-10-02) "/lui puntero": efecto del puntero (src/Pointer). Sin nada
-- o "on" lo enciende, "off" lo apaga, un estilo o color lo cambia (y lo
-- enciende), "prueba" hace el destello grande. Se guarda en el perfil.
local function _pointer_command(arg)
    local Pointer = _G.LUI.Features.Pointer
    local State = _G.LUI.Settings.State
    local Apply = _G.LUI.Runtime.Apply
    local prefix = "<rgb=#3399FA>LUI</rgb> puntero: "
    local loaded = State.loaded_settings
    if Pointer == nil or type(loaded) ~= "table" then
        Turbine.Shell.WriteLine(prefix .. "no disponible")
        return
    end
    if type(loaded.pointer) ~= "table" then
        loaded.pointer = {}
    end
    local p = loaded.pointer
    local a = string.lower(arg or "")
    local function has(list, v)
        for i = 1, #list do
            if list[i] == v then
                return true
            end
        end
        return false
    end
    if a == "prueba" or a == "test" then
        if Pointer.flash() ~= true then
            Turbine.Shell.WriteLine(prefix .. "est\195\161 apagado (/lui puntero on)")
        end
        return
    elseif a == "off" or a == "no" then
        p.enabled = false
    elseif a == "" or a == "on" or a == "si" then
        p.enabled = true
    elseif has(Pointer.STYLES, a) then
        p.enabled = true
        p.style = a
    elseif has(Pointer.COLORS, a) then
        p.enabled = true
        p.color = a
    else
        Turbine.Shell.WriteLine(prefix .. "estilos: " .. table.concat(Pointer.STYLES, ", ") ..
            " | colores: " .. table.concat(Pointer.COLORS, ", ") .. " | on, off, prueba")
        return
    end
    pcall(_G.LUI.Settings.rebuild)
    if Apply.pointer_settings ~= nil then
        Apply.pointer_settings()
    end
    pcall(_G.LUI.Settings.Persistence.save_settings)
    local cfg = Pointer.normalize(p)
    if cfg.enabled == true then
        Turbine.Shell.WriteLine(prefix .. "activado (" .. cfg.style .. ", " .. cfg.color .. ")")
    else
        Turbine.Shell.WriteLine(prefix .. "desactivado")
    end
end

-- (2026-10-03) "/lui minimapa": aura del minimapa (src/MinimapAura). Sin
-- nada o "on" la enciende (la primera vez deja colocarla), "off" la
-- apaga, "colocar" deja moverla sobre el radar, "listo" termina, un diseno
-- o un color la cambia y un numero cambia el tamano (px). Se guarda en el
-- perfil.
local function _minimap_command(arg)
    local MM = _G.LUI.Features.MinimapAura
    local State = _G.LUI.Settings.State
    local Apply = _G.LUI.Runtime.Apply
    local prefix = "<rgb=#3399FA>LUI</rgb> minimapa: "
    local loaded = State.loaded_settings
    if MM == nil or type(loaded) ~= "table" or Apply.minimap_settings == nil then
        Turbine.Shell.WriteLine(prefix .. "no disponible")
        return
    end
    if type(loaded.minimap) ~= "table" then
        loaded.minimap = {}
    end
    local m = loaded.minimap
    local a = string.lower(arg or "")
    local function has(list, v)
        for i = 1, #list do
            if list[i] == v then
                return true
            end
        end
        return false
    end
    local place = false
    if a == "colocar" or a == "mover" or a == "place" then
        if Windows.minimap_aura ~= nil then
            MM.start_placement(nil)
            Turbine.Shell.WriteLine(prefix .. "arrastra el aro sobre el radar; rueda o - / + para el tama\195\177o; clic derecho u OK para terminar")
            return
        end
        m.enabled = true
        place = true
    elseif a == "listo" or a == "ok" or a == "done" then
        if MM.is_placing() == true then
            MM.finish_placement(true)
        else
            Turbine.Shell.WriteLine(prefix .. "no se est\195\161 colocando (/lui minimapa colocar)")
        end
        return
    elseif a == "off" or a == "no" then
        m.enabled = false
    elseif a == "" or a == "on" or a == "si" then
        m.enabled = true
        place = MM.normalize(m).cx == nil
    elseif has(MM.DESIGNS, a) then
        m.enabled = true
        m.design = a
    elseif has(MM.COLORS, a) then
        m.enabled = true
        m.color = a
    elseif tonumber(a) ~= nil then
        m.enabled = true
        m.diameter = tonumber(a)
    else
        Turbine.Shell.WriteLine(prefix .. "dise\195\177os: " .. table.concat(MM.DESIGNS, ", ") ..
            " | colores: " .. table.concat(MM.COLORS, ", ") ..
            " | tama\195\177o: un n\195\186mero (" .. MM.MIN_D .. "-" .. MM.MAX_D .. ") | on, off, colocar, listo")
        return
    end
    pcall(_G.LUI.Settings.rebuild)
    Apply.minimap_settings()
    pcall(_G.LUI.Settings.Persistence.save_settings)
    local cfg = MM.normalize(m)
    if cfg.enabled == true and Windows.minimap_aura ~= nil then
        Turbine.Shell.WriteLine(prefix .. "activado (" .. cfg.design .. ", " .. cfg.color .. ", " ..
            tostring(cfg.diameter) .. " px)")
        if place == true then
            MM.start_placement(nil)
            Turbine.Shell.WriteLine(prefix .. "arrastra el aro sobre el radar; rueda o - / + para el tama\195\177o; clic derecho u OK para terminar")
        end
    elseif cfg.enabled == true then
        Turbine.Shell.WriteLine(prefix .. "no se pudo crear (revisa el chat)")
    else
        Turbine.Shell.WriteLine(prefix .. "desactivado")
    end
end

-- (2026-09-30) "/lui cartel": cartel de misiones (src/QuestBanner)
local function _banner_command(arg)
    local QuestBanner = _G.LUI.Features.QuestBanner
    local prefix = "<rgb=#3399FA>LUI</rgb> cartel: "
    if QuestBanner == nil or QuestBanner.notify == nil then
        Turbine.Shell.WriteLine(prefix .. "no disponible")
        return
    end
    if Windows.quest_banner == nil then
        Turbine.Shell.WriteLine(prefix .. "est\195\161 apagado (Opciones > Barra de estado > Cartel de misiones)")
        return
    end
    if arg == nil or arg == "" or string.lower(arg) == "demo" then
        QuestBanner.start_demo()
        return
    end
    if string.lower(arg) == "cola" and QuestBanner.start_queue_test ~= nil then
        QuestBanner.start_queue_test()
        Turbine.Shell.WriteLine(prefix .. "3 misiones aceptadas seguidas y una completada: salen una tras otra")
        return
    end
    if string.lower(arg) == "prueba" and QuestBanner.start_fit_test ~= nil then
        QuestBanner.start_fit_test()
        Turbine.Shell.WriteLine(prefix .. "12 t\195\173tulos: los que m\195\161s justo entran en su cartel y el m\195\161s largo")
        return
    end
    local style = QuestBanner.lookup(arg)
    QuestBanner.notify("accepted", arg, style or "general", nil)
    Turbine.Shell.WriteLine(prefix .. arg .. " (estilo " .. tostring(style or "general") ..
        (style == nil and ", no est\195\161 en la base" or "") .. ")")
end

local function _handle_status_bar_api_command(list, index)
    local spec, err = StatusBarApiCommandParser.parse_status_bar_api_spec(list, index)
    if spec == nil then
        return nil, err
    end

    return StatusBarCommon.register_status_bar_api_item(spec)
end

function command:Execute(_, str)
    if str == nil or string.len(str) == 0 then
        Turbine.Shell.WriteLine(TR["Missing Argument for more information type /lui help."])
        return
    end

    local list = StatusBarApiCommandParser.tokenize_command_arguments(str)
    if #list == 0 then
        Turbine.Shell.WriteLine(TR["Missing Argument for more information type /lui help."])
        return
    end

    local cmd = string.lower(list[1])

    if cmd == "help" then
        display_help()
    elseif cmd == "move" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == "cancel" then
            MoveMode.cancel()
        else
            MoveMode.toggle()
        end
    elseif cmd == "config" then
        Shortcuts.toggle_config()
    elseif cmd == "inventory" or cmd == "inv" then
        Shortcuts.toggle_inventory()
    elseif cmd == "assets" or cmd == "a" then
        Shortcuts.toggle_assets()
    elseif cmd == "craft" then
        Shortcuts.toggle_crafting()
    elseif cmd == "travel" or cmd == "trav" then
        Shortcuts.toggle_travel()
    elseif cmd == "raid" then
        Shortcuts.toggle_raid_groups()
    elseif cmd == "encyclopedia" or cmd == "ency" or cmd == "bestiary" or cmd == "beast" or cmd == "b" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        if action == nil then
            Shortcuts.toggle_encyclopedia()
        else
            display_help()
        end
    elseif cmd == "menu" or cmd == "launcher" then
        local action = list[2] ~= nil and string.lower(list[2]) or nil
        _set_launcher_enabled(action ~= "off" and action ~= "no")
    elseif cmd == "diag" then
        _write_image_diag()
    elseif cmd == "imgtest" then
        _open_imgtest()
    elseif cmd == "puntero" or cmd == "pointer" or cmd == "cursor" then
        _pointer_command(str:match("^%s*%S+%s+(.-)%s*$"))
    elseif cmd == "minimapa" or cmd == "minimap" or cmd == "radar" then
        _minimap_command(str:match("^%s*%S+%s+(.-)%s*$"))
    elseif cmd == "cartel" or cmd == "banner" then
        _banner_command(str:match("^%s*%S+%s+(.-)%s*$"))
    elseif cmd == "botin" or cmd == "loot" then
        local History = _G.LUI.Features.Drops.History
        if History ~= nil then
            History.execute(table.concat(list, " ", 2))
        end
    elseif cmd == "card" then
        local monster_name = table.concat(list, " ", 2)
        if monster_name == nil or monster_name == "" then
            Turbine.Shell.WriteLine(TR["Usage: /lui card [monster name]"])
            return
        end

        if Windows.bestiary_card:show_for_name(monster_name, nil) ~= true then
            Turbine.Shell.WriteLine(TR["Monster not found in bestiary: "] .. monster_name)
        end
    elseif cmd == "api.sb" or (cmd == "api" and list[2] ~= nil and string.lower(list[2]) == "sb") then
        local start_index = cmd == "api.sb" and 2 or 3
        local _, err = _handle_status_bar_api_command(list, start_index)
        if err ~= nil then
            _write_error(err)
            Turbine.Shell.WriteLine("  " .. STATUS_BAR_API_USAGE)
        end
    else
        if cmd == "api" then
            display_help()
        end
    end
end

Turbine.Shell.AddCommand("LUI", command)
