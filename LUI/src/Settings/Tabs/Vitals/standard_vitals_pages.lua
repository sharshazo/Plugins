-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages

local Builder = Pages.StandardVitalsPageBuilder or {}
Pages.StandardVitalsPageBuilder = Builder

-- Deep-copies every field of `src` into `dst`, IN PLACE (never replaces the
-- `dst` table reference itself) so live windows/pages that already hold a
-- pointer to this exact table (VitalsBase:get_vitals_settings(), the
-- settings-page `get()` closures) see the reset without needing to be
-- rebuilt or re-fetched.
local function _reset_table_in_place(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end
    for key in pairs(dst) do
        dst[key] = nil
    end
    for key, value in pairs(src) do
        if type(value) == "table" then
            dst[key] = {}
            _reset_table_in_place(dst[key], value)
        else
            dst[key] = value
        end
    end
end

-- "Restablecer a valores predeterminados" -- a pedido explicito del usuario:
-- este boton debe existir para que la estructura RUF-WoTLK que se diseño
-- (barra unica clase-coloreada, nombre pequeño arriba, valor grande abajo)
-- sea de verdad lo que "restablecer" deja, incluso para una cuenta que ya
-- tenia ajustes guardados de ANTES de este rediseño -- default_schema.lua por
-- si solo no alcanza: los ajustes ya guardados nunca se sobrescriben con
-- valores nuevos del schema (defaults_fill.lua solo rellena claves
-- faltantes), asi que sin este boton un usuario existente jamas veria el
-- nuevo diseño sin borrar a mano su PluginData.
local function _add_reset_defaults_button(frame, options, get, page, window)
    if options.defaults == nil then
        return
    end
    frame:add_button(options.prefix .. "_reset_defaults", TR["Reset this section to defaults"],
        function()
            _reset_table_in_place(get(), options.defaults())
            page:load()
            page.refresh_preview()
            window:refresh_runtime_settings()
        end,
        TR["Restores every setting in this section (frame, colors, morale, power, texts, effects) to LUI's built-in defaults."])
    frame:add_row_break()
end

function Builder.new_standard_unit_page(window, root, options, deps)
    local get = function()
        return options.get_settings(root)
    end

    local page = deps.ConfigSectionPage(window, options.preview_key, options.preview_height, function(win)
        win[options.preview_method](win)
    end)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    _add_reset_defaults_button(frame, options, get, page, window)
    deps.add_number_field(frame, options.prefix .. "_width", TR["Frame Width"], function() return get().frame.width end,
        function(value) get().frame.width = value end)
    deps.add_number_field(frame, options.prefix .. "_border_width", TR["Border Width"],
        function() return get().frame.border_width end,
        function(value) get().frame.border_width = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_effects_height", TR["Effects Height"],
        function() return get().frame.effects_height end,
        function(value) get().frame.effects_height = value end)
    frame:add_row_break()
    deps.add_number_field(frame, options.prefix .. "_incombat_opacity", TR["In-combat opacity"],
        function() return get().frame.incombat_opacity end,
        function(value) get().frame.incombat_opacity = value end)
    deps.add_number_field(frame, options.prefix .. "_outcombat_opacity", TR["Out-of-combat opacity"],
        function() return get().frame.outcombat_opacity end,
        function(value) get().frame.outcombat_opacity = value end)
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_standard_colors_section(window, page.refresh_preview, options.prefix, get,
        options.show_outline_settings)
    page:add_tab(TR["Colors"], "colors", colors)

    local morale = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_morale_form(morale, options.prefix, get)
    page:add_tab(TR["Morale"], "morale", morale)

    local power = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_standard_power_form(power, options.prefix, get, options.boss_power_mode == true)
    page:add_tab(TR["Power / Wrath"], "power", power)

    local info = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.build_info_form(info, options.prefix, get)
    page:add_tab(TR["Info"], "info", info)

    page:add_tab(TR["Texts"], "texts", deps.new_texts_section(window, page.refresh_preview, options.prefix, get))
    page:add_tab(TR["Effects"], "effects", deps.new_effects_section(window, page.refresh_preview, options.prefix, get))
    deps.bind_standard_outline_visibility(page, colors, options.prefix, options.show_outline_settings)

    if options.boss_targets == true then
        page:add_tab(TR["Custom Bosses"], "custom_bosses",
            deps.new_boss_targets_section(window, page.refresh_preview, get))
    end

    return page
end

function Builder.new_targets_target_unit_page(window, root, deps)
    local get = function()
        return root._settings.target.vitals.targets_target
    end

    local page = deps.ConfigSectionPage(window, "target_targets_target_preview", 133, function(win)
        win:update_target_targets_target_preview()
    end)

    local frame = deps.ConfigContent(window, 4, page.refresh_preview)
    deps.add_number_field(frame, "target_targets_target_width", TR["Frame Width"], function() return get().width end,
        function(value) get().width = value end)
    deps.add_number_field(frame, "target_targets_target_height", TR["Bar Height"], function() return get().height end,
        function(value) get().height = value end)
    deps.add_number_field(frame, "target_targets_target_border_width", TR["Border Width"],
        function() return get().border_width end,
        function(value) get().border_width = value end)
    frame:add_row_break()
    deps.add_text_field(frame, "target_targets_target_bubble_text", TR["Bubble Format (%B)"],
        function() return get().bubble_format end,
        function(value) get().bubble_format = value end,
        frame.bubble_format_help, true)
    page:add_tab(TR["Frame"], "frame", frame)

    local colors = deps.new_targets_target_colors_section(window, page.refresh_preview, get)
    page:add_tab(TR["Colors"], "colors", colors)
    page:add_tab(TR["Texts"], "texts", deps.new_targets_target_texts_section(window, page.refresh_preview, get))
    deps.bind_targets_target_outline_visibility(page, colors)

    return page
end

function Builder.new_general_page(window, root, deps)
    local page = deps.ConfigContent(window, 4)
    page:add_title(TR["General"])
    page:add_checkbox("self_vitals_enabled", TR["Enable self vitals"],
        function(value)
            root._settings.self.vitals.enabled = value == true
        end,
        function()
            return root._settings.self.vitals.enabled == true
        end)
    page:add_checkbox("target_vitals_enabled", TR["Enable target vitals"],
        function(value)
            root._settings.target.vitals.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.enabled == true
        end)
    page:add_checkbox("companion_vitals_enabled", TR["Enable companion vitals"],
        function(value)
            root._settings.companion.enabled = value == true
        end,
        function()
            return root._settings.companion.enabled == true
        end)
    page:add_checkbox("target_boss_enabled", TR["Enable boss vitals"],
        function(value)
            root._settings.target.boss_vitals.enabled = value == true
        end,
        function()
            return root._settings.target.boss_vitals.enabled == true
        end)
    page:add_checkbox("target_targets_target_enabled", TR["Enable target's target"],
        function(value)
            root._settings.target.vitals.targets_target.enabled = value == true
        end,
        function()
            return root._settings.target.vitals.targets_target.enabled == true
        end)
    page:add_checkbox("fellowship_vitals_enabled", TR["Enable fellowship vitals"],
        function(value)
            root._settings.fellowship.enabled = value == true
        end,
        function()
            return root._settings.fellowship.enabled == true
        end)
    page:add_checkbox("raid_vitals_enabled", TR["Enable raid vitals"],
        function(value)
            root._settings.raid.enabled = value == true
        end,
        function()
            return root._settings.raid.enabled == true
        end)
    return page
end
