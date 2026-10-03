-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local lui_tokenize_format = _G.LUI.Utils.lui_tokenize_format
import "Turbine.UI"
import "LUI.src.Utils.font"
import "LUI.src.Utils.token_format"
import "LUI.src.Utils.timed_row_layout"
import "LUI.src.Settings.enums"
import "LUI.src.StatusBar.common"
import "LUI.src.UI.native_scaling"

local LUI = _G.LUI
local UI = LUI.UI
local Settings = LUI.Settings
local State = Settings.State
local ToLotro = Settings.ToLotro
local LUI_ENUMS = Settings.Enums
local S = LUI.Features.StatusBar.Common
local FONT_TO_LOTRO = LUI.Utils.FONT_TO_LOTRO
local lui_timed_row_resolve_item_footprint = LUI.Utils.lui_timed_row_resolve_item_footprint
local lui_timed_row_resolve_bar_size = LUI.Utils.lui_timed_row_resolve_bar_size
local lui_timed_row_time_format = LUI.Utils.lui_timed_row_time_format
local TIMED_ROW_LABEL_PAD = LUI.Utils.lui_timed_row_label_pad

-- Resolve an expiring-effects surface once per rebuild: clamped bar size,
-- entry footprint, effective show_time, and the fitted vertical time font.
-- Windows and entries read this instead of re-running the fit per slot.
local function build_expiring_effects_resolved(dst)
    local vertical = dst.orientation == LUI_ENUMS.orientation.VERTICAL
    local r = {}
    r.bar_length, r.thickness, r.show_time, r.time_font_size = lui_timed_row_resolve_bar_size(
        vertical, dst.show_time,
        dst.bar_width, dst.bar_height,
        dst.border_width, TIMED_ROW_LABEL_PAD,
        dst.font.name, dst.font.size,
        dst.threshold, lui_timed_row_time_format.AUTO
    )

    if vertical then
        r.entry_width = r.thickness
        r.entry_height = r.bar_length + r.thickness
    else
        r.entry_width = r.bar_length + r.thickness
        r.entry_height = r.thickness
    end

    if r.time_font_size ~= nil then
        r.time_font = FONT_TO_LOTRO(dst.font.name, r.time_font_size)
    end

    return r
end

function Settings.rebuild()
    local raw = State.loaded_settings
    local configured_scaling = UI.NativeScaling.get_configured_scale(raw)
    local scaling = UI.NativeScaling.get_effective_scale(raw)
    local refresh_rate = raw.global.refresh_rate

    local function scaled_int(value)
        local n = value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            error("Invalid numeric setting in rebuild_settings", 2)
        end
        return math.floor((n * scaling) + 0.5)
    end

    local function clamped_scaled_int(value, min_value, max_value)
        local n = value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            error("Invalid numeric setting in rebuild_settings", 2)
        end
        if n < min_value then
            n = min_value
        elseif n > max_value then
            n = max_value
        end
        return scaled_int(n)
    end

    local function normalize_launcher_direction(orientation, direction)
        if orientation == "horizontal" then
            if direction == "left" or direction == "right" then
                return direction
            end
            return "right"
        end

        if orientation == "vertical" then
            if direction == "up" or direction == "down" then
                return direction
            end
            return "down"
        end

        error("Invalid launcher orientation in rebuild_settings: " .. tostring(orientation), 2)
    end

    local function scaled_number(value)
        local n = value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil then
            error("Invalid numeric setting in rebuild_settings", 2)
        end
        return n * scaling
    end

    local function scaled_border(value)
        local n = value
        if type(n) ~= "number" then
            n = tonumber(n)
        end
        if n == nil or n <= 0 then
            return 0
        end
        local out = math.floor(n * scaling)
        if out < 1 then out = 1 end
        return out
    end

    State.settings = {
        global = {
            number_abbrev = {},
            style = {},
        },
        encyclopedia = {
            bestiary_capture = false,
        },
        ui = {
            windows = {},
            hud = {},
        },
        status_bar = {
            bg = {},
            font = {},
            zones = { left = {}, center = {}, right = {} },
            item_registry = {},
            widgets = {},
        },
        self = {
            vitals = {
                frame = {},
                morale = { color = {} },
                power = { color = {} },
                labels = {},
                info = { color = {} },
                class_icon = {},
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                    layout = { top = {}, bottom = {} },
                },
            },
            expiring_effects = { font = {}, color = {} },
            cooldowns = { font = {}, color = {} },
            upkeep = { font = {} },
            drops = { hud = {}, item = {} },
        },
        target = {
            vitals = {
                frame = {},
                morale = { color = {} },
                power = { color = {} },
                labels = {},
                info = { color = {} },
                class_icon = {},
                targets_target = { color = {}, labels = {} },
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                    layout = { top = {}, bottom = {} },
                },
            },
            boss_vitals = {
                frame = {},
                morale = { color = {} },
                power = { color = {} },
                labels = {},
                info = { color = {} },
                effects = {
                    buffs = { timer_font = {} },
                    debuffs = { timer_font = {} },
                    layout = { top = {}, bottom = {} },
                },
            },
            expiring_effects = { font = {}, color = {} },
        },
        companion = {
            frame = {},
            morale = { color = {} },
            power = { color = {} },
            labels = {},
            info = { color = {} },
            effects = {
                buffs = { timer_font = {} },
                debuffs = { timer_font = {} },
                layout = { top = {}, bottom = {} },
            },
        },
        fellowship = {
            frame = {},
            morale = { color = {} },
            power = { color = {} },
            labels = {},
            info = { color = {} },
            layout = {},
            class_icon = {},
            leader_icon = {},
            select = {},
            effects = {
                buffs = { timer_font = {} },
                debuffs = { timer_font = {} },
                layout = { top = {}, bottom = {} },
            },
        },
        raid = {
            frame = {},
            morale = { color = {} },
            power = { color = {} },
            labels = {},
            info = { color = {} },
            layout = {},
            group_border_width = 0,
            group_colors = {},
            class_icon = {},
            leader_icon = {},
            select = {},
            effects = {
                buffs = { timer_font = {} },
                debuffs = { timer_font = {} },
                layout = { top = {}, bottom = {} },
            },
        },
        inventory = {},
        drops = { hud = {}, item = {} },
        crafting = {},
        travel = {},
        assets = { tile = {}, layouts = { icons = {}, details = {} } },
        bestiary = {},
        launcher = {},
    }

    State.settings.global.scale = scaling
    State.settings.global.configured_scale = configured_scaling
    State.settings.global.refresh_rate = refresh_rate
    State.settings.global.native_scaling = raw.global.native_scaling == true
    State.settings.global.move_mode_shortcut = raw.global.move_mode_shortcut
    State.settings.global.close_windows_with_esc = raw.global.close_windows_with_esc == true
    State.settings.global.style = raw.global.style
    -- Idioma de la interfaz (dropdown de Global -> General). BUG CORREGIDO
    -- (reporte del usuario: "el apartado de configuracion de LUI no
    -- respeta cambiarse a español"): este campo nunca se copiaba aca, asi
    -- que State.settings.global.language quedaba SIEMPRE en nil y main.lua
    -- (Locale.reload_translations) caia siempre en "auto" -> ingles, sin
    -- importar lo que se eligiera en el dropdown.
    State.settings.global.language = raw.global.language
    State.settings.encyclopedia.bestiary_capture = raw.encyclopedia.bestiary_capture == true
    State.settings.ui.windows = raw.ui.windows
    State.settings.ui.hud = raw.ui.hud

    local function build_color(value)
        if value == nil then
            error("Missing color setting in rebuild_settings", 2)
        end
        if value.A ~= nil and value.R ~= nil and value.G ~= nil and value.B ~= nil then
            return Turbine.UI.Color(value.A, value.R, value.G, value.B)
        end
        if type(value) == "table" then
            error("Invalid color setting in rebuild_settings", 2)
        end
        return value
    end

    local function build_morale_colors(src)
        return {
            gradient = src.gradient == true,
            gradient_full = build_color(src.gradient_full),
            gradient_mid = build_color(src.gradient_mid),
            gradient_low = build_color(src.gradient_low),
            high = build_color(src.high),
            medium = build_color(src.medium),
            low = build_color(src.low),
            critical = build_color(src.critical),
            neutral = build_color(src.neutral),
            background = build_color(src.background),
            bubble = build_color(src.bubble),
        }
    end

    local function build_power_colors(src)
        return {
            power = build_color(src.power),
            wrath = build_color(src.wrath),
        }
    end

    local function build_target_target_colors(src)
        return {
            gradient = src.gradient == true,
            gradient_full = build_color(src.gradient_full),
            gradient_mid = build_color(src.gradient_mid),
            gradient_low = build_color(src.gradient_low),
            high = build_color(src.high),
            medium = build_color(src.medium),
            low = build_color(src.low),
            critical = build_color(src.critical),
            neutral = build_color(src.neutral),
            background = build_color(src.background),
            border = build_color(src.border),
            bubble = build_color(src.bubble),
        }
    end

    local function build_expiring_effect_colors(src)
        return {
            background = build_color(src.background),
            border = build_color(src.border),
            bar_buff = build_color(src.bar_buff),
            bar_debuff_curable = build_color(src.bar_debuff_curable),
            bar_debuff_noncurable = build_color(src.bar_debuff_noncurable),
        }
    end

    local function build_vital_label(src)
        local dst = { font = {} }
        dst.enabled = src.enabled == true
        dst.text = src.text
        dst.tokens = lui_tokenize_format(dst.text)
        dst.link_to = src.link_to
        dst.anchor = src.anchor
        dst.width_mode = src.width_mode
        dst.text_alignment = src.text_alignment
        dst.x_offset = scaled_int(src.x_offset)
        dst.y_offset = scaled_int(src.y_offset)
        dst.font.name = src.font.name
        dst.font.size = scaled_number(src.font.size)
        dst.font.lotro = FONT_TO_LOTRO(dst.font.name, dst.font.size)
        dst.font.style = src.font.style
        dst.font.color = build_color(src.font.color)
        dst.font.outline_color = build_color(src.font.outline_color)
        return dst
    end

    local function effect_slot_is_top(slot)
        return slot == LUI_ENUMS.vitals_effect_slot.TOP_NEAR or slot == LUI_ENUMS.vitals_effect_slot.TOP_FAR
    end

    local function effect_slot_is_bottom(slot)
        return slot == LUI_ENUMS.vitals_effect_slot.BOTTOM_NEAR or slot == LUI_ENUMS.vitals_effect_slot.BOTTOM_FAR
    end

    local function effect_slot_order(slot)
        if slot == LUI_ENUMS.vitals_effect_slot.TOP_FAR or slot == LUI_ENUMS.vitals_effect_slot.BOTTOM_FAR then
            return 2
        end
        return 1
    end

    local function build_effect_layout(dst)
        local half_height = dst.frame.effects_height / 2
        local layout = {
            buffs_reserved_height = half_height,
            debuffs_reserved_height = half_height,
            buffs_reverse_fill = effect_slot_is_top(dst.effects.buffs.slot),
            debuffs_reverse_fill = effect_slot_is_top(dst.effects.debuffs.slot),
            top_reserved_height = 0,
            bottom_reserved_height = 0,
            top = {},
            bottom = {},
        }

        local function add_entry(list, area_key, slot, reserved_height)
            list[#list + 1] = {
                area_key = area_key,
                order = effect_slot_order(slot),
                reserved_height = reserved_height,
            }
        end

        local buff_slot = dst.effects.buffs.slot
        if effect_slot_is_top(buff_slot) then
            add_entry(layout.top, "buffs", buff_slot, layout.buffs_reserved_height)
            layout.top_reserved_height = layout.top_reserved_height + layout.buffs_reserved_height
        elseif effect_slot_is_bottom(buff_slot) then
            add_entry(layout.bottom, "buffs", buff_slot, layout.buffs_reserved_height)
            layout.bottom_reserved_height = layout.bottom_reserved_height + layout.buffs_reserved_height
        end

        local debuff_slot = dst.effects.debuffs.slot
        if effect_slot_is_top(debuff_slot) then
            add_entry(layout.top, "debuffs", debuff_slot, layout.debuffs_reserved_height)
            layout.top_reserved_height = layout.top_reserved_height + layout.debuffs_reserved_height
        elseif effect_slot_is_bottom(debuff_slot) then
            add_entry(layout.bottom, "debuffs", debuff_slot, layout.debuffs_reserved_height)
            layout.bottom_reserved_height = layout.bottom_reserved_height + layout.debuffs_reserved_height
        end

        table.sort(layout.top, function(a, b)
            return a.order > b.order
        end)
        table.sort(layout.bottom, function(a, b)
            return a.order < b.order
        end)

        dst.effects.layout = layout
    end

    local function build_vital(dst, src)
        dst.enabled = src.enabled == true
        dst.frame.width = scaled_int(src.frame.width)
        dst.frame.border_width = scaled_border(src.frame.border_width)
        dst.frame.border_color = build_color(src.frame.border_color)
        dst.frame.incombat_opacity = src.frame.incombat_opacity
        dst.frame.outcombat_opacity = src.frame.outcombat_opacity

        dst.morale.height = scaled_int(src.morale.height)
        dst.power.height = scaled_int(src.power.height)

        dst.morale.color = build_morale_colors(src.morale.color)
        dst.power.color = build_power_colors(src.power.color)

        dst.morale.bubble_format = src.morale.bubble_format
        dst.morale.bubble_tokens = lui_tokenize_format(dst.morale.bubble_format)
        dst.background_matches_missing = src.background_matches_missing
        dst.background_dimming = src.background_dimming
        dst.background_opacity = src.background_opacity
        dst.info.enabled = src.info.enabled == true
        dst.info.height = scaled_int(src.info.height)
        dst.info.opacity = src.info.opacity
        dst.info.color.background = build_color(src.info.color.background)
        dst.labels = {
            build_vital_label(src.labels[1]),
            build_vital_label(src.labels[2]),
            build_vital_label(src.labels[3]),
            build_vital_label(src.labels[4]),
        }

        dst.frame.effects_height = scaled_int(src.frame.effects_height)
        dst.frame.effects_position = src.frame.effects_position

        if src.effects ~= nil then
            dst.effects.buffs.slot = src.effects.buffs.slot
            dst.effects.buffs.alignment = src.effects.buffs.alignment
            dst.effects.buffs.icon_size = scaled_int(src.effects.buffs.icon_size)
            dst.effects.debuffs.slot = src.effects.debuffs.slot
            dst.effects.debuffs.alignment = src.effects.debuffs.alignment
            dst.effects.debuffs.icon_size = scaled_int(src.effects.debuffs.icon_size)

            dst.effects.buffs.timer_font.name = src.effects.buffs.timer_font.name
            dst.effects.buffs.timer_font.size = scaled_number(src.effects.buffs.timer_font.size)
            dst.effects.buffs.timer_font.lotro = FONT_TO_LOTRO(dst.effects.buffs.timer_font.name,
                dst.effects.buffs.timer_font.size)
            dst.effects.buffs.timer_font.style = src.effects.buffs.timer_font.style
            dst.effects.buffs.timer_font.color = build_color(src.effects.buffs.timer_font.color)
            dst.effects.buffs.timer_font.outline_color = build_color(src.effects.buffs.timer_font.outline_color)

            dst.effects.debuffs.timer_font.name = src.effects.debuffs.timer_font.name
            dst.effects.debuffs.timer_font.size = scaled_number(src.effects.debuffs.timer_font.size)
            dst.effects.debuffs.timer_font.lotro = FONT_TO_LOTRO(dst.effects.debuffs.timer_font.name,
                dst.effects.debuffs.timer_font.size)
            dst.effects.debuffs.timer_font.style = src.effects.debuffs.timer_font.style
            dst.effects.debuffs.timer_font.color = build_color(src.effects.debuffs.timer_font.color)
            dst.effects.debuffs.timer_font.outline_color = build_color(src.effects.debuffs.timer_font.outline_color)

            dst.effects.debuffs.track_curable = src.effects.debuffs.track_curable
            dst.effects.debuffs.track_noncurable = src.effects.debuffs.track_noncurable
            build_effect_layout(dst)
        end
    end

    -- BUG CORREGIDO (log real: "rebuild_settings.lua:476: attempt to index
    -- local 'raw_class_icon' (a nil value)" -- LUI no abria NINGUNA
    -- ventana, ni el icono flotante del launcher). Se agrego el default de
    -- self.vitals/target.vitals.class_icon en default_schema.lua, pero eso
    -- SOLO alcanza a un perfil NUEVO (State.loaded_settings se arma desde
    -- Defaults.Schema recien ahi) -- un perfil YA GUARDADO (el caso mas
    -- comun, el de cualquiera que ya viene usando LUI) carga directo del
    -- PluginData guardado, que nunca tuvo esta clave -- src.class_icon
    -- seguiria siendo nil igual. Con un fallback local aca, la funcion
    -- queda a prueba de perfiles viejos Y nuevos, sin depender de que el
    -- schema se propague.
    local function build_vital_class_icon(dst, src)
        local raw_class_icon = src.class_icon or { enabled = false, size = 20, x = 1, y = 1 }
        dst.class_icon.enabled = raw_class_icon.enabled == true
        dst.class_icon.size = scaled_int(raw_class_icon.size)
        dst.class_icon.x = scaled_int(raw_class_icon.x)
        dst.class_icon.y = scaled_int(raw_class_icon.y)
    end

    local function build_group_vital(dst, src)
        build_vital(dst, src)

        -- Mismo fallback defensivo que build_vital_class_icon (ver esa nota
        -- grande mas arriba) -- por las dudas de un perfil guardado que
        -- tampoco tenga estas claves.
        local raw_class_icon = src.class_icon or { enabled = true, size = 20, x = 1, y = 10 }
        dst.class_icon.enabled = raw_class_icon.enabled
        dst.class_icon.size = scaled_int(raw_class_icon.size)
        dst.class_icon.x = scaled_int(raw_class_icon.x)
        dst.class_icon.y = scaled_int(raw_class_icon.y)

        local raw_leader_icon = src.leader_icon or { enabled = true, size = 20, x = 120, y = 10 }
        dst.leader_icon.enabled = raw_leader_icon.enabled
        dst.leader_icon.size = scaled_int(raw_leader_icon.size)
        dst.leader_icon.x = scaled_int(raw_leader_icon.x)
        dst.leader_icon.y = scaled_int(raw_leader_icon.y)

        local raw_select = src.select
        dst.select.enabled = raw_select.enabled == true
        dst.select.border_width = scaled_border(raw_select.border_width)
        dst.select.border_color = build_color(raw_select.border_color)
        -- opciones nuevas (aura, mouse encima, vida baja): encendidas salvo
        -- que el perfil diga false; mismo criterio defensivo que arriba
        dst.select.glow = raw_select.glow ~= false
        dst.select.hover = raw_select.hover ~= false
        dst.select.low_health = raw_select.low_health ~= false
        dst.select.low_health_pct = tonumber(raw_select.low_health_pct) or 35

        local raw_layout = src.layout
        dst.layout.rows = raw_layout.rows
        dst.layout.mode = raw_layout.mode
        dst.layout.spacing_x = scaled_int(raw_layout.spacing_x)
        dst.layout.spacing_y = scaled_int(raw_layout.spacing_y)
    end

    build_vital(State.settings.self.vitals, raw.self.vitals)
    build_vital_class_icon(State.settings.self.vitals, raw.self.vitals)
    build_vital(State.settings.target.vitals, raw.target.vitals)
    build_vital_class_icon(State.settings.target.vitals, raw.target.vitals)
    build_vital(State.settings.target.boss_vitals, raw.target.boss_vitals)
    build_vital(State.settings.companion, raw.companion)
    build_group_vital(State.settings.fellowship, raw.fellowship)
    build_group_vital(State.settings.raid, raw.raid)
    State.settings.fellowship.show_self_in_fellowship = raw.fellowship.show_self_in_fellowship == true
    State.settings.fellowship.background_effect_tracking = raw.fellowship.background_effect_tracking == true
    State.settings.raid.background_effect_tracking = raw.raid.background_effect_tracking == true
    State.settings.raid.group_border_width = scaled_border(raw.raid.group_border_width)
    State.settings.raid.split_by_group = raw.raid.split_by_group == true
    State.settings.raid.group_colors.a = build_color(raw.raid.group_colors.a)
    State.settings.raid.group_colors.b = build_color(raw.raid.group_colors.b)
    State.settings.raid.group_colors.c = build_color(raw.raid.group_colors.c)
    State.settings.raid.group_colors.d = build_color(raw.raid.group_colors.d)

    local raw_inv = raw.inventory
    if raw_inv ~= nil then
        local inv = State.settings.inventory
        inv.enabled = raw_inv.enabled
        inv.replace = raw_inv.replace
        inv.tile_size = scaled_int(raw_inv.tile_size)
    end

    local raw_assets = raw.assets
    if raw_assets ~= nil then
        local assets = State.settings.assets
        assets.layouts = raw_assets.layouts
        assets.enabled = raw_assets.enabled
        assets.view_mode = raw_assets.view_mode
        assets.stack_items = raw_assets.stack_items
        assets.tile.icons = scaled_int(raw_assets.tile.icons)
        assets.tile.details = scaled_int(raw_assets.tile.details)
    end

    local raw_crafting = raw.crafting
    State.settings.crafting.display_mode = raw_crafting.display_mode
    State.settings.crafting.enabled = raw_crafting.enabled

    local raw_travel = raw.travel
    State.settings.travel.display_mode = raw_travel.display_mode
    State.settings.travel.enabled = raw_travel.enabled

    local raw_launcher = raw.launcher
    local launcher = State.settings.launcher
    launcher.enabled = raw_launcher.enabled == true
    launcher.icon_size = clamped_scaled_int(raw_launcher.icon_size, 16, 128)
    launcher.spacing = scaled_int(raw_launcher.spacing)
    launcher.orientation = raw_launcher.orientation
    launcher.direction = normalize_launcher_direction(raw_launcher.orientation, raw_launcher.direction)
    launcher.collapse_after_click = raw_launcher.collapse_after_click == true
    launcher.buttons = raw_launcher.buttons

    local raw_tt = raw.target.vitals.targets_target
    local dst_tt = State.settings.target.vitals.targets_target
    dst_tt.enabled = raw_tt.enabled == true
    dst_tt.width = scaled_int(raw_tt.width)
    dst_tt.height = scaled_int(raw_tt.height)
    dst_tt.border_width = scaled_border(raw_tt.border_width)
    dst_tt.color = build_target_target_colors(raw_tt.color)
    dst_tt.bubble_format = raw_tt.bubble_format
    dst_tt.bubble_tokens = lui_tokenize_format(dst_tt.bubble_format)
    dst_tt.background_matches_missing = raw_tt.background_matches_missing
    dst_tt.background_dimming = raw_tt.background_dimming
    dst_tt.background_opacity = raw_tt.background_opacity
    dst_tt.labels = {
        build_vital_label(raw_tt.labels[1]),
        build_vital_label(raw_tt.labels[2]),
    }

    local raw_bv = raw.target.boss_vitals
    local dst_bv = State.settings.target.boss_vitals
    dst_bv.enabled = raw_bv.enabled
    dst_bv.power.width = scaled_int(raw_bv.power.width)
    dst_bv.power.hide = raw_bv.power.hide
    dst_bv.power.side = raw_bv.power.side

    -- Parse the user's multiline custom boss list (one name per line) into an
    -- exact-match set so the runtime boss check is a single table lookup.
    local custom_target_names = {}
    for line in string.gmatch(raw_bv.custom_targets, "[^\r\n]+") do
        local name = string.gsub(line, "^%s+", "")
        name = string.gsub(name, "%s+$", "")
        if name ~= "" then
            custom_target_names[name] = true
        end
    end
    dst_bv.custom_target_names = custom_target_names

    local raw_self_ee = raw.self.expiring_effects
    local self_ee = State.settings.self.expiring_effects
    self_ee.enabled = raw_self_ee.enabled
    self_ee.show_buffs = raw_self_ee.show_buffs
    self_ee.show_curable_debuffs = raw_self_ee.show_curable_debuffs
    self_ee.show_noncurable_debuffs = raw_self_ee.show_noncurable_debuffs
    self_ee.icon_side = raw_self_ee.icon_side
    self_ee.bar_expire_towards = raw_self_ee.bar_expire_towards
    self_ee.bar_mode = raw_self_ee.bar_mode
    self_ee.orientation = raw_self_ee.orientation
    self_ee.show_time = raw_self_ee.show_time
    self_ee.name_max_chars = raw_self_ee.name_max_chars
    self_ee.threshold = raw_self_ee.threshold
    self_ee.columns = raw_self_ee.columns
    self_ee.rows = raw_self_ee.rows
    self_ee.spacing = scaled_int(raw_self_ee.spacing)
    self_ee.bar_width = scaled_int(raw_self_ee.bar_width)
    self_ee.bar_height = scaled_int(raw_self_ee.bar_height)
    self_ee.border_width = scaled_border(raw_self_ee.border_width)
    self_ee.bar_background_matches_fill = raw_self_ee.bar_background_matches_fill
    self_ee.bar_background_dimming = raw_self_ee.bar_background_dimming
    self_ee.background_opacity = raw_self_ee.background_opacity
    self_ee.bar_opacity = raw_self_ee.bar_opacity
    self_ee.color = build_expiring_effect_colors(raw_self_ee.color)

    self_ee.font.name = raw_self_ee.font.name
    self_ee.font.size = scaled_number(raw_self_ee.font.size)
    self_ee.font.lotro = FONT_TO_LOTRO(self_ee.font.name, self_ee.font.size)
    self_ee.font.style = raw_self_ee.font.style
    self_ee.font.color = build_color(raw_self_ee.font.color)
    self_ee.font.outline_color = build_color(raw_self_ee.font.outline_color)

    self_ee.resolved = build_expiring_effects_resolved(self_ee)

    local raw_expiring_target_effects = raw.target.expiring_effects
    local target_ee = State.settings.target.expiring_effects
    target_ee.enabled = raw_expiring_target_effects.enabled
    target_ee.show_buffs = raw_expiring_target_effects.show_buffs
    target_ee.show_curable_debuffs = raw_expiring_target_effects.show_curable_debuffs
    target_ee.show_noncurable_debuffs = raw_expiring_target_effects.show_noncurable_debuffs
    target_ee.icon_side = raw_expiring_target_effects.icon_side
    target_ee.bar_expire_towards = raw_expiring_target_effects.bar_expire_towards
    target_ee.bar_mode = raw_expiring_target_effects.bar_mode
    target_ee.orientation = raw_expiring_target_effects.orientation
    target_ee.show_time = raw_expiring_target_effects.show_time
    target_ee.name_max_chars = raw_expiring_target_effects.name_max_chars
    target_ee.threshold = raw_expiring_target_effects.threshold
    target_ee.columns = raw_expiring_target_effects.columns
    target_ee.rows = raw_expiring_target_effects.rows
    target_ee.spacing = scaled_int(raw_expiring_target_effects.spacing)
    target_ee.bar_width = scaled_int(raw_expiring_target_effects.bar_width)
    target_ee.bar_height = scaled_int(raw_expiring_target_effects.bar_height)
    target_ee.border_width = scaled_border(raw_expiring_target_effects.border_width)
    target_ee.bar_background_matches_fill = raw_expiring_target_effects.bar_background_matches_fill
    target_ee.bar_background_dimming = raw_expiring_target_effects.bar_background_dimming
    target_ee.background_opacity = raw_expiring_target_effects.background_opacity
    target_ee.bar_opacity = raw_expiring_target_effects.bar_opacity
    target_ee.color = build_expiring_effect_colors(raw_expiring_target_effects.color)

    target_ee.font.name = raw_expiring_target_effects.font.name
    target_ee.font.size = scaled_number(raw_expiring_target_effects.font.size)
    target_ee.font.lotro = FONT_TO_LOTRO(target_ee.font.name, target_ee.font.size)
    target_ee.font.style = raw_expiring_target_effects.font.style
    target_ee.font.color = build_color(raw_expiring_target_effects.font.color)
    target_ee.font.outline_color = build_color(raw_expiring_target_effects.font.outline_color)

    target_ee.resolved = build_expiring_effects_resolved(target_ee)

    -- (2026-10-02) efecto del puntero: valores ya validados (pointer_fx.lua)
    if _G.LUI.Features.Pointer ~= nil and _G.LUI.Features.Pointer.normalize ~= nil then
        State.settings.pointer = _G.LUI.Features.Pointer.normalize(raw.pointer)
    else
        State.settings.pointer = { enabled = false }
    end

    local raw_abbrev = raw.global.number_abbrev
    State.settings.global.number_abbrev.enabled = raw_abbrev.enabled
    State.settings.global.number_abbrev.digits = raw_abbrev.digits
    State.settings.global.number_abbrev.width = raw_abbrev.width
    State.settings.global.number_abbrev.method = raw_abbrev.method

    local raw_sb = raw.status_bar
    local sb = State.settings.status_bar
    sb.enabled = raw_sb.enabled
    -- cartel de zona (src/ZoneBanner): en pixeles reales, sin escalar
    sb.zone_banner = raw_sb.zone_banner ~= false
    sb.zone_banner_size = tonumber(raw_sb.zone_banner_size) or 380
    sb.zone_tint = raw_sb.zone_tint ~= false
    sb.zone_animations = raw_sb.zone_animations ~= false
    sb.height = scaled_int(raw_sb.height)
    sb.padding = scaled_int(raw_sb.padding)
    sb.gap = scaled_int(raw_sb.gap)
    sb.bg.opacity = raw_sb.bg.opacity
    sb.bg.color = raw_sb.bg.color

    sb.font.name = raw_sb.font.name
    sb.font.size = scaled_number(raw_sb.font.size)
    sb.font.lotro = FONT_TO_LOTRO(sb.font.name, sb.font.size)
    sb.font.style = raw_sb.font.style
    sb.font.color = raw_sb.font.color
    sb.font.outline_color = raw_sb.font.outline_color

    sb.layout = raw_sb.layout
    sb.item_registry = raw_sb.item_registry
    sb.zones.left = S.parse_status_bar_layout(raw_sb.layout.left, sb.item_registry)
    sb.zones.center = S.parse_status_bar_layout(raw_sb.layout.center, sb.item_registry)
    sb.zones.right = S.parse_status_bar_layout(raw_sb.layout.right, sb.item_registry)

    local function list_has(list, value)
        for i = 1, #list do
            if list[i] == value then
                return true
            end
        end
        return false
    end

    local function in_zones(widget_key)
        return list_has(sb.zones.left, widget_key) or list_has(sb.zones.center, widget_key) or
            list_has(sb.zones.right, widget_key)
    end

    sb.widgets.time_local = {
        enabled = in_zones("time_local"),
        width = scaled_int(raw_sb.widgets.time_local.width),
        content_alignment = ToLotro.text_alignment[raw_sb.widgets.time_local.text_alignment],
        time_format = raw_sb.widgets.time_local.time_format,
    }
    sb.widgets.inventory_space = {
        enabled = in_zones("inventory_space"),
        width = scaled_int(raw_sb.widgets.inventory_space.width),
        icon = raw_sb.widgets.inventory_space.icon,
        color = raw_sb.widgets.inventory_space.color,
        content_alignment = ToLotro.text_alignment[raw_sb.widgets.inventory_space.text_alignment],
    }
    sb.widgets.equipment_wear = {
        enabled = in_zones("equipment_wear"),
        width = scaled_int(raw_sb.widgets.equipment_wear.width),
        icon = raw_sb.widgets.equipment_wear.icon,
        coloring = raw_sb.widgets.equipment_wear.coloring == true,
        color = raw_sb.widgets.equipment_wear.color,
        content_alignment = ToLotro.text_alignment[raw_sb.widgets.equipment_wear.text_alignment],
    }
    sb.widgets.money = {
        enabled = in_zones("money"),
        width = scaled_int(raw_sb.widgets.money.width),
        content_alignment = ToLotro.text_alignment[raw_sb.widgets.money.text_alignment],
    }
    sb.widgets.wallet = {
        enabled = in_zones("wallet"),
        width = scaled_int(raw_sb.widgets.wallet.width),
        items = S.parse_wallet_item_list(raw_sb.widgets.wallet.items),
        content_alignment = ToLotro.text_alignment[raw_sb.widgets.wallet.text_alignment],
    }
    sb.widgets.item = {
        width = scaled_int(raw_sb.widgets.item.width),
    }

    sb.widgets.shortcut = {
        width = scaled_int(raw_sb.widgets.shortcut.width),
        height = scaled_int(raw_sb.widgets.shortcut.height),
    }

    sb.widgets.craft_plan = {
        enabled = in_zones("craft_plan"),
        width = scaled_int(raw_sb.widgets.craft_plan.width),
        max_visible = math.max(1, tonumber(raw_sb.widgets.craft_plan.max_visible)),
    }

    sb.widgets.button = {
        width = sb.widgets.shortcut.width,
        height = sb.widgets.shortcut.height,
    }

    local function build_shortcut_widget(widget_key)
        return {
            enabled = in_zones(widget_key),
            width = sb.widgets.shortcut.width,
            height = sb.widgets.shortcut.height,
        }
    end

    sb.widgets.config = build_shortcut_widget("config")
    sb.widgets.assets = build_shortcut_widget("assets")
    sb.widgets.encyclopedia = build_shortcut_widget("encyclopedia")
    sb.widgets.craft = build_shortcut_widget("craft")
    sb.widgets.travel = build_shortcut_widget("travel")
    sb.widgets.raid = build_shortcut_widget("raid")

    local raw_cd = raw.self.cooldowns
    local cd = State.settings.self.cooldowns
    cd.enabled = raw_cd.enabled
    cd.threshold = raw_cd.threshold
    cd.min_base_cooldown = raw_cd.min_base_cooldown
    cd.group_display = raw_cd.group_display
    cd.columns = raw_cd.columns
    cd.rows = raw_cd.rows
    cd.flow = raw_cd.flow
    cd.spacing = scaled_int(raw_cd.spacing)
    cd.border_width = scaled_border(raw_cd.border_width)
    cd.item_w = scaled_int(raw_cd.item_w)
    cd.item_h = scaled_int(raw_cd.item_h)
    cd.icon_side = raw_cd.icon_side
    cd.bar_expire_towards = raw_cd.bar_expire_towards
    cd.bar_mode = raw_cd.bar_mode
    cd.orientation = raw_cd.orientation
    cd.show_time = raw_cd.show_time
    cd.time_format = raw_cd.time_format
    cd.text_margin = scaled_int(raw_cd.text_margin)
    cd.name_max_chars = raw_cd.name_max_chars
    cd.whitelist = raw_cd.whitelist
    cd.blacklist = raw_cd.blacklist
    cd.bar_background_matches_fill = raw_cd.bar_background_matches_fill
    cd.bar_background_dimming = raw_cd.bar_background_dimming
    cd.background_opacity = raw_cd.background_opacity
    cd.bar_opacity = raw_cd.bar_opacity
    cd.color = raw_cd.color

    cd.font.name = raw_cd.font.name
    cd.font.size = scaled_number(raw_cd.font.size)
    cd.font.lotro = FONT_TO_LOTRO(cd.font.name, cd.font.size)
    cd.font.style = raw_cd.font.style
    cd.font.color = raw_cd.font.color
    cd.font.outline_color = raw_cd.font.outline_color

    -- Resolve the entry footprint, effective show_time, and the fitted
    -- vertical time font once per rebuild; the window and entries read this
    -- instead of re-running the fit per slot.
    local cd_resolved = {}
    cd_resolved.width, cd_resolved.height, cd_resolved.show_time, cd_resolved.time_font_size =
        lui_timed_row_resolve_item_footprint(
            cd.orientation == LUI_ENUMS.orientation.VERTICAL,
            cd.show_time,
            cd.item_w, cd.item_h,
            cd.border_width, cd.text_margin,
            cd.font.name, cd.font.size,
            cd.threshold, cd.time_format
        )
    if cd_resolved.time_font_size ~= nil then
        cd_resolved.time_font = FONT_TO_LOTRO(cd.font.name, cd_resolved.time_font_size)
    end
    cd.resolved = cd_resolved

    local raw_uk = raw.self.upkeep
    local uk = State.settings.self.upkeep
    uk.enabled = raw_uk.enabled
    local uk_count = math.floor(raw_uk.count + 0.5)
    if uk_count < 1 then uk_count = 1 end
    if uk_count > 12 then uk_count = 12 end
    uk.count = uk_count
    -- even sides pair with even containers for exact pixel centering
    local uk_icon = scaled_int(raw_uk.icon_size)
    if uk_icon % 2 ~= 0 then
        uk_icon = uk_icon - 1
    end
    if uk_icon < 8 then uk_icon = 8 end
    uk.icon_size = uk_icon
    uk.spacing = scaled_int(raw_uk.spacing)
    uk.orientation = raw_uk.orientation
    uk.auto_order = raw_uk.auto_order
    uk.auto_order_anchor = raw_uk.auto_order_anchor
    uk.slots = raw_uk.slots
    uk.slot_modes = raw_uk.slot_modes
    uk.show_time = raw_uk.show_time
    uk.drain_enabled = raw_uk.drain_enabled
    uk.drain_color = raw_uk.drain_color
    uk.drain_opacity = raw_uk.drain_opacity
    uk.cd_shade = raw_uk.cd_shade
    uk.cd_during_active = raw_uk.cd_during_active
    uk.cd_shade_color = raw_uk.cd_shade_color
    uk.cd_shade_opacity = raw_uk.cd_shade_opacity
    uk.cd_transparent = raw_uk.cd_transparent
    uk.cd_transparent_opacity = raw_uk.cd_transparent_opacity
    uk.cd_show_time = raw_uk.cd_show_time
    uk.dim_unusable = raw_uk.dim_unusable
    uk.unusable_opacity = raw_uk.unusable_opacity
    uk.time_format = raw_uk.time_format
    uk.active_text_color = raw_uk.active_text_color
    uk.cooldown_text_color = raw_uk.cooldown_text_color

    uk.font.name = raw_uk.font.name
    uk.font.size = scaled_number(raw_uk.font.size)
    uk.font.lotro = FONT_TO_LOTRO(uk.font.name, uk.font.size)
    uk.font.style = raw_uk.font.style
    uk.font.outline_color = raw_uk.font.outline_color

    local raw_drops = raw.drops
    local drops = State.settings.drops
    drops.enabled = raw_drops.enabled
    drops.visible_duration = raw_drops.visible_duration
    drops.rows = raw_drops.rows
    drops.icon_size = scaled_int(raw_drops.icon_size)
    drops.width = scaled_int(raw_drops.width)
    drops.flow = raw_drops.flow
    drops.align = raw_drops.align
    drops.icon_side = raw_drops.icon_side
    drops.animations_enabled = raw_drops.animations_enabled
    drops.merge_similar = raw_drops.merge_similar
    drops.show_banner = raw_drops.show_banner ~= false
    drops.rare_alert = raw_drops.rare_alert ~= false
    drops.move_duration = raw_drops.move_duration
    drops.hud.background_opacity = raw_drops.hud.background_opacity
    drops.hud.background_color = raw_drops.hud.background_color
    drops.item.background_opacity = raw_drops.item.background_opacity
    drops.item.background_color = raw_drops.item.background_color
end
