-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local Settings = _G.LUI.Settings
local Persistence = _G.LUI.Settings.Persistence
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local StatusBar = _G.LUI.Features.StatusBar
local Windows = _G.LUI.Runtime.Windows
local Apply = _G.LUI.Runtime.Apply
local class = _G.LUI.Core.class
import "LUI.src.StatusBar.common"
import "LUI.src.StatusBar.widget_base"
import "LUI.src.StatusBar.Widgets"
import "LUI.src.StatusBar.edit_bar_window"
import "LUI.src.UI.Widgets"

local S = StatusBar.Common
local StatusBarEditWindow = StatusBar.StatusBarEditWindow
local Style = UI.Widgets.Style

local SHORTCUT_WIDGETS = {
    config = { shortcut_key = "config", display_mode = "icon" },
    craft = { shortcut_key = "craft", display_mode = "icon" },
    travel = { shortcut_key = "travel", display_mode = "icon" },
    assets = { shortcut_key = "assets", display_mode = "icon" },
    encyclopedia = { shortcut_key = "encyclopedia", display_mode = "icon" },
    raid = { shortcut_key = "raid", display_mode = "icon" },
}

local DRAG_PREVIEW_EDGE_W = 2
local EDIT_DRAG_START_DISTANCE = 4
local EDIT_DRAG_GHOST_FONT_SIZE_OFFSET = 1

local function _edit_drag_ghost_font()
    local size = Style.CONTENT_SMALL_FONT_SIZE + EDIT_DRAG_GHOST_FONT_SIZE_OFFSET
    local font = FONT_TO_LOTRO(Style.CONTENT_SMALL_FONT_NAME, size * State.settings.global.scale)
    if font == nil then
        error("Missing edit drag ghost font: " .. tostring(Style.CONTENT_SMALL_FONT_NAME) .. " " .. tostring(size))
    end
    return font
end

local function _widget_participates_in_layout(widget)
    return widget ~= nil and widget._status_bar_drag_hidden ~= true
end

local function _write_status_bar_message(text)
    if Turbine ~= nil and Turbine.Shell ~= nil and Turbine.Shell.WriteLine ~= nil then
        Turbine.Shell.WriteLine("<rgb=#3399FA>LUI</rgb>: " .. tostring(text or ""))
    end
end

local function _resolve_drop_zone_key(bar_w, mouse_x)
    local width = type(bar_w) == "number" and bar_w or 0
    if width <= 0 then
        return "right"
    end

    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        return "right"
    end

    if x < (width / 3) then
        return "left"
    elseif x < ((width * 2) / 3) then
        return "center"
    end
    return "right"
end

local function _sync_status_bar_after_raw_edit(edit_window_state_override)
    local edit_window_state = edit_window_state_override
    if edit_window_state == nil and Windows.status_bar ~= nil then
        edit_window_state = Windows.status_bar:capture_edit_window_state()
    end

    Settings.rebuild()
    if Windows.status_bar ~= nil then
        Windows.status_bar:apply_settings()
    else
        Apply.status_bar_settings()
    end
    if edit_window_state ~= nil and edit_window_state.visible == true and Windows.status_bar ~= nil then
        Windows.status_bar:restore_edit_window_state(edit_window_state)
    end
    if Windows.config ~= nil and Windows.config.IsVisible ~= nil and Windows.config:IsVisible() == true then
        local controls = Windows.config.controls or nil
        local raw_sb = State.loaded_settings ~= nil and State.loaded_settings.status_bar or nil
        if controls ~= nil and raw_sb ~= nil then
            local function sync_layout_box(key, value)
                local control = controls[key]
                if control ~= nil and control.tb ~= nil and control.tb.SetText ~= nil then
                    control.tb:SetText(value)
                end
            end
            sync_layout_box("sb_layout_left", raw_sb.layout.left)
            sync_layout_box("sb_layout_center", raw_sb.layout.center)
            sync_layout_box("sb_layout_right", raw_sb.layout.right)
        end
    end
    Persistence.save_settings()
end

local function _extract_layout_tokens(text)
    local tokens = {}
    local source = tostring(text or "")
    for token in source:gmatch("%%[^%%]+%%") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function _layout_token_is_visible(token)
    local inner = tostring(token or ""):match("^%%([^%%]+)%%$")
    if inner == nil then
        return false
    end

    if S.parse_status_bar_button_token(inner) ~= nil then
        return true
    end

    if S.parse_status_bar_item_name(inner) ~= nil then
        return true
    end

    if S.get_status_bar_api_item(inner) ~= nil then
        return true
    end

    return S.STATUS_BAR_LAYOUT_TOKENS[string.lower(inner)] ~= nil
end

local function _insert_layout_token_at_visible_index(text, token, insert_index)
    local tokens = _extract_layout_tokens(text)
    if #tokens == 0 then
        return token
    end

    local wanted_index = insert_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        wanted_index = 1
    end

    local visible_before = 0
    for i = 1, #tokens do
        if _layout_token_is_visible(tokens[i]) == true then
            if wanted_index == (visible_before + 1) then
                table.insert(tokens, i, token)
                return table.concat(tokens, " ")
            end
            visible_before = visible_before + 1
        end
    end

    table.insert(tokens, token)
    return table.concat(tokens, " ")
end

local function _remove_visible_layout_token_at_index(text, remove_index)
    local tokens = _extract_layout_tokens(text)
    local wanted_index = remove_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        return tostring(text or ""), nil
    end

    local visible_index = 0
    for i = 1, #tokens do
        if _layout_token_is_visible(tokens[i]) == true then
            visible_index = visible_index + 1
            if visible_index == wanted_index then
                local removed_token = tokens[i]
                table.remove(tokens, i)
                return table.concat(tokens, " "), removed_token
            end
        end
    end

    return table.concat(tokens, " "), nil
end

local function _get_raw_status_bar_settings()
    local raw = State.loaded_settings
    return raw.status_bar
end

local function _get_combined_layout_text(raw_sb)
    return table.concat({
        raw_sb.layout.left,
        raw_sb.layout.center,
        raw_sb.layout.right,
    }, " ")
end

local function _cleanup_removed_item_registry_entry(raw_sb, removed_token)
    if raw_sb == nil or type(raw_sb.item_registry) ~= "table" then
        return
    end

    local inner = tostring(removed_token or ""):match("^%%([^%%]+)%%$")
    local item_name = inner ~= nil and S.parse_status_bar_item_name(inner) or nil
    if item_name == nil then
        return
    end

    if S.status_bar_layout_has_item(_get_combined_layout_text(raw_sb), item_name) == true then
        return
    end

    local key = S.make_status_bar_item_registry_key(item_name)
    if key ~= nil then
        raw_sb.item_registry[key] = nil
    end
end

local function _get_widget_menu_title(widget_key, widget_entry)
    if S.is_status_bar_item_entry(widget_entry) == true then
        return widget_entry.name or ""
    elseif S.is_status_bar_api_entry(widget_entry) == true then
        return widget_entry.title or widget_entry.description or ""
    elseif S.is_status_bar_button_entry(widget_entry) == true then
        local api_entry = S.get_status_bar_api_item_by_command(widget_entry.command)
        if api_entry ~= nil then
            return api_entry.title or api_entry.description or widget_entry.command or "button"
        end
        return widget_entry.command or "button"
    end
    return S.get_status_bar_widget_display_name(widget_key)
end

local function _bind_widget_interactions(owner, widget, menu_title)
    if owner == nil or widget == nil then
        return
    end

    widget._status_bar_menu_title = tostring(menu_title or "")
    local target = widget
    if widget.get_interaction_target ~= nil then
        local candidate = widget:get_interaction_target()
        if candidate ~= nil then
            target = candidate
        end
    elseif widget._interaction_target ~= nil then
        target = widget._interaction_target
    end

    target:SetMouseVisible(true)
    if target.SetAllowDrop ~= nil then
        target:SetAllowDrop(true)
    end

    local prior_mouse_click = target.MouseClick
    target.MouseClick = function(sender, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Right then
            owner:_show_widget_menu(widget)
            return
        end
        if owner:_is_edit_mode_active() == true then
            return
        end
        if prior_mouse_click ~= nil then
            prior_mouse_click(sender, args)
        end
    end

    local prior_mouse_down = target.MouseDown
    target.MouseDown = function(sender, args)
        if owner:_handle_widget_mouse_down(widget, args) == true then
            return
        end
        if prior_mouse_down ~= nil then
            prior_mouse_down(sender, args)
        end
    end

    target.DragDrop = function(_, args)
        owner:_handle_drag_drop(widget, args)
    end
    target.DragEnter = function(_, args)
        owner:_handle_drag_enter(widget, args)
    end
    target.DragLeave = function(_, args)
        owner:_handle_drag_leave(widget, args)
    end

    local prior_mouse_move = target.MouseMove
    target.MouseMove = function(sender, args)
        if owner:_handle_widget_mouse_move(widget, args) == true then
            return
        end
        owner:_handle_drag_move(widget, args)
        if prior_mouse_move ~= nil then
            prior_mouse_move(sender, args)
        end
    end

    local prior_mouse_up = target.MouseUp
    target.MouseUp = function(sender, args)
        if owner:_handle_widget_mouse_up(widget, args) == true then
            return
        end
        if prior_mouse_up ~= nil then
            prior_mouse_up(sender, args)
        end
    end
end

local function _sum_zone_width_with_preview(widgets, gap, preview_width)
    local total = 0
    local visible_count = 0
    for i = 1, #(widgets or {}) do
        local widget = widgets[i]
        if _widget_participates_in_layout(widget) == true then
            if visible_count > 0 then
                total = total + gap
            end
            total = total + widget:GetWidth()
            visible_count = visible_count + 1
        end
    end
    if type(preview_width) == "number" and preview_width > 0 then
        if visible_count > 0 then
            total = total + gap
        end
        total = total + preview_width
    end
    return total
end

local function _zone_widgets_contains_x(widgets, mouse_x)
    if widgets == nil or #widgets == 0 or type(mouse_x) ~= "number" then
        return false
    end

    local first = nil
    local last = nil
    for i = 1, #widgets do
        local widget = widgets[i]
        if _widget_participates_in_layout(widget) == true then
            if first == nil then
                first = widget
            end
            last = widget
        end
    end
    if first == nil or last == nil then
        return false
    end

    local left = first:GetLeft()
    local right = last:GetLeft() + last:GetWidth()
    return mouse_x >= left and mouse_x <= right
end

local function _zone_insertion_index(widgets, mouse_x)
    if widgets == nil or #widgets == 0 then
        return 1
    end

    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        local visible_count = 0
        for i = 1, #widgets do
            if _widget_participates_in_layout(widgets[i]) == true then
                visible_count = visible_count + 1
            end
        end
        return visible_count + 1
    end

    local visible_index = 0
    for i = 1, #widgets do
        local widget = widgets[i]
        if _widget_participates_in_layout(widget) == true then
            visible_index = visible_index + 1
            local midpoint = widget:GetLeft() + (widget:GetWidth() / 2)
            if x < midpoint then
                return visible_index
            end
        end
    end

    return visible_index + 1
end

local function _widgets_pkg()
    return StatusBar.Widgets
end

local function _widget_ctor(name)
    local widgets = _widgets_pkg()
    return widgets[name]
end

local function _widget_factory(widget_key, widget_w, bar_h, font, widget_cfg, widget_entry)
    local shortcut_spec = SHORTCUT_WIDGETS[widget_key]
    if shortcut_spec ~= nil then
        local ctor = _widget_ctor("ShortcutButtonWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: ShortcutButtonWidget")
        end
        return ctor(
            shortcut_spec.shortcut_key,
            shortcut_spec.display_mode,
            widget_w,
            S.clamp_shortcut_height(widget_cfg ~= nil and widget_cfg.height or nil, bar_h),
            font
        )
    end

    if widget_key == "time_local" then
        local ctor = _widget_ctor("TimeLocalWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: TimeLocalWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg.content_alignment, widget_cfg.time_format)
    elseif widget_key == "inventory_space" then
        local ctor = _widget_ctor("InventorySpaceWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: InventorySpaceWidget")
        end
        local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color,
            widget_cfg.content_alignment)
    elseif widget_key == "equipment_wear" then
        local ctor = _widget_ctor("EquipmentWearWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: EquipmentWearWidget")
        end
        local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
        return ctor(widget_w, bar_h, font, icon_path, widget_cfg.color, widget_cfg.coloring,
            widget_cfg.content_alignment)
    elseif widget_key == "money" then
        local ctor = _widget_ctor("MoneyWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: MoneyWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg.content_alignment)
    elseif widget_key == "wallet" then
        local ctor = _widget_ctor("WalletWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: WalletWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg.content_alignment, widget_cfg.items)
    elseif widget_key == "item" then
        local ctor = _widget_ctor("ItemCountWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: ItemCountWidget")
        end
        return ctor(widget_entry ~= nil and widget_entry.name or nil, widget_w, bar_h, font,
            widget_entry ~= nil and widget_entry.icon_image_id or nil)
    elseif widget_key == "craft_plan" then
        local ctor = _widget_ctor("CraftPlanWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: CraftPlanWidget")
        end
        return ctor(widget_w, bar_h, font, widget_cfg ~= nil and widget_cfg.max_visible or nil)
    elseif widget_key == "button" then
        local ctor = _widget_ctor("AliasButtonWidget")
        if ctor == nil then
            error("Missing StatusBar widget constructor: AliasButtonWidget")
        end
        return ctor(
            widget_entry,
            widget_w,
            S.clamp_shortcut_height(widget_cfg ~= nil and widget_cfg.height or nil, bar_h),
            font
        )
    end

    local alignment = Turbine.UI.ContentAlignment.MiddleLeft
    local ctor = _widget_ctor("DummyWidget")
    if ctor == nil then
        error("Missing StatusBar widget constructor: DummyWidget")
    end
    local icon_path = widget_cfg ~= nil and widget_cfg.icon == true and S.get_widget_icon(widget_key) or nil
    return ctor(widget_key, widget_w, bar_h, font, widget_cfg.content_alignment or alignment, icon_path)
end

local StatusBarWindow = class(UI.Widgets.LuiBaseWindow)
StatusBar.StatusBarWindow = StatusBarWindow

function StatusBarWindow:_ensure_edit_window()
    local edit_window = self._edit_window or Windows.status_bar_edit
    if edit_window == nil or edit_window._destroying == true or edit_window.done_button == nil then
        edit_window = StatusBarEditWindow(self)
        Windows.status_bar_edit = edit_window
    elseif edit_window.set_owner ~= nil then
        edit_window:set_owner(self)
    else
        edit_window.owner = self
    end

    self._edit_window = edit_window
    return edit_window
end

function StatusBarWindow:Constructor()
    UI.Widgets.LuiBaseWindow.Constructor(self, {
        hideable = true,
    })

    self.last_update_at = 0
    self.update_every = 1.0
    self._last_display_w = nil
    self._display_check_due_at = 0

    self._widgets = {}
    self._update_widgets = {}
    self._zone_widgets_left = {}
    self._zone_widgets_center = {}
    self._zone_widgets_right = {}
    self._drag_preview_details = nil
    self._drag_preview_next_at = 0
    self._drag_preview_zone_key = nil
    self._drag_preview_insert_index = nil
    self._edit_drag_session = nil
    self._drag_preview_window = Turbine.UI.Window()
    self:apply_native_scaling(self._drag_preview_window)
    self._drag_preview_window:SetMouseVisible(false)
    self._drag_preview_window:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._drag_preview_window:SetVisible(true)
    self._drag_preview_window:SetZOrder(200)

    self._drag_preview_fill = Turbine.UI.Control()
    self._drag_preview_fill:SetParent(self._drag_preview_window)
    self._drag_preview_fill:SetMouseVisible(false)
    self._drag_preview_fill:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_fill:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_fill:SetBackColor(Style.DRAG_PREVIEW_FILL)
    self._drag_preview_fill:SetVisible(false)
    self._drag_preview_fill:SetZOrder(100)

    self._drag_preview_edge = Turbine.UI.Control()
    self._drag_preview_edge:SetParent(self._drag_preview_window)
    self._drag_preview_edge:SetMouseVisible(false)
    self._drag_preview_edge:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_edge:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_edge:SetBackColor(Style.DRAG_PREVIEW_EDGE)
    self._drag_preview_edge:SetVisible(false)
    self._drag_preview_edge:SetZOrder(101)

    self._drag_preview_trailing_edge = Turbine.UI.Control()
    self._drag_preview_trailing_edge:SetParent(self._drag_preview_window)
    self._drag_preview_trailing_edge:SetMouseVisible(false)
    self._drag_preview_trailing_edge:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_trailing_edge:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._drag_preview_trailing_edge:SetBackColor(Style.DRAG_PREVIEW_EDGE)
    self._drag_preview_trailing_edge:SetVisible(false)
    self._drag_preview_trailing_edge:SetZOrder(101)

    self:_ensure_edit_window()

    self._edit_drag_overlay = Turbine.UI.Window()
    self:apply_native_scaling(self._edit_drag_overlay)
    self._edit_drag_overlay:SetVisible(false)
    self._edit_drag_overlay:SetMouseVisible(false)
    self._edit_drag_overlay:SetZOrder(3500)
    self._edit_drag_overlay:SetBackColor(Style.TRANSPARENT_BACKGROUND)
    self._edit_drag_overlay.MouseMove = function(_, args)
        self:_handle_edit_drag_overlay_mouse_move(args)
    end
    self._edit_drag_overlay.MouseUp = function(_, args)
        self:_handle_edit_drag_overlay_mouse_up(args)
    end

    self._edit_drag_ghost = Turbine.UI.Control()
    self._edit_drag_ghost:SetParent(self._edit_drag_overlay)
    self._edit_drag_ghost:SetVisible(false)
    self._edit_drag_ghost:SetMouseVisible(false)
    self._edit_drag_ghost:SetBackColor(Style.DRAG_GHOST_BACKGROUND)
    self._edit_drag_ghost:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    self._edit_drag_ghost:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)

    self._edit_drag_ghost_top = Turbine.UI.Control()
    self._edit_drag_ghost_top:SetParent(self._edit_drag_ghost)
    self._edit_drag_ghost_top:SetMouseVisible(false)
    self._edit_drag_ghost_top:SetBackColor(Style.DRAG_GHOST_BORDER)

    self._edit_drag_ghost_bottom = Turbine.UI.Control()
    self._edit_drag_ghost_bottom:SetParent(self._edit_drag_ghost)
    self._edit_drag_ghost_bottom:SetMouseVisible(false)
    self._edit_drag_ghost_bottom:SetBackColor(Style.DRAG_GHOST_BORDER)

    self._edit_drag_ghost_left = Turbine.UI.Control()
    self._edit_drag_ghost_left:SetParent(self._edit_drag_ghost)
    self._edit_drag_ghost_left:SetMouseVisible(false)
    self._edit_drag_ghost_left:SetBackColor(Style.DRAG_GHOST_BORDER)

    self._edit_drag_ghost_right = Turbine.UI.Control()
    self._edit_drag_ghost_right:SetParent(self._edit_drag_ghost)
    self._edit_drag_ghost_right:SetMouseVisible(false)
    self._edit_drag_ghost_right:SetBackColor(Style.DRAG_GHOST_BORDER)

    self._edit_drag_ghost_label = UI.Widgets.LuiLabel()
    self._edit_drag_ghost_label:SetParent(self._edit_drag_ghost)
    self._edit_drag_ghost_label:SetMouseVisible(false)
    self._edit_drag_ghost_label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self._edit_drag_ghost_label:SetForeColor(Style.DRAG_GHOST_FOREGROUND)
    self._edit_drag_ghost_label:SetFont(_edit_drag_ghost_font())

    self:SetMouseVisible(false)
    self:SetVisible(true)
    self:SetWantsUpdates(true)
    self:SetZOrder(-1)
    if self.SetAllowDrop ~= nil then
        self:SetAllowDrop(true)
    end
    self.DragEnter = function(_, args)
        self:_handle_drag_enter(self, args)
    end
    self.DragLeave = function(_, args)
        self:_handle_drag_leave(self, args)
    end
    self.DragDrop = function(_, args)
        self:_handle_drag_drop(self, args)
    end
    self.MouseClick = function(_, args)
        if args ~= nil and args.Button == Turbine.UI.MouseButton.Right then
            self:_show_bar_menu()
        end
    end
    self.MouseMove = function(_, args)
        self:_handle_drag_move(self, args)
    end

    self:apply_settings()
end

function StatusBarWindow:apply_settings()
    local sb = State.settings.status_bar

    self:_apply_back_color()
    self:apply_native_scaling()
    self:apply_native_scaling(self._drag_preview_window)
    self:apply_native_scaling(self._edit_drag_overlay)

    self._last_display_w = nil
    self._display_check_due_at = 0
    self:_sync_display_width(sb)

    self:_rebuild_widgets(sb)
    self._widgets_interaction_enabled = nil
    self:_sync_widget_interaction_modes(self:_is_edit_mode_active() ~= true)
    local edit_window = self:_ensure_edit_window()
    if edit_window ~= nil then
        edit_window:apply_native_scaling()
        edit_window:apply_scale()
        edit_window:refresh_state()
    end
    self.last_update_at = 0
end

-- Color de fondo: el de Opciones, o el del cartel de zona si esta activo
-- "Tenir la barra" (src/ZoneBanner). El tenido usa como minimo 0.85 de
-- opacidad para que el color se vea, y agrega una linea fina abajo con el
-- color del texto del cartel. Sin tenido todo queda como siempre.
function StatusBarWindow:set_zone_tint(bar_rgb, edge_rgb)
    if type(bar_rgb) == "table" then
        self._zone_tint = { bar = bar_rgb, edge = edge_rgb }
    else
        self._zone_tint = nil
    end
    self:_apply_back_color()
end

function StatusBarWindow:_apply_back_color()
    local bg = State.settings.status_bar.bg
    local tint = self._zone_tint
    if tint == nil then
        self:SetBackColor(Turbine.UI.Color(bg.opacity, bg.color.R, bg.color.G, bg.color.B))
        if self._zone_tint_edge ~= nil then
            self._zone_tint_edge:SetVisible(false)
        end
        return
    end

    local opacity = math.max(tonumber(bg.opacity) or 0, 0.85)
    local c = tint.bar
    self:SetBackColor(Turbine.UI.Color(opacity, c[1] / 255, c[2] / 255, c[3] / 255))

    if self._zone_tint_edge == nil then
        self._zone_tint_edge = Turbine.UI.Control()
        self._zone_tint_edge:SetParent(self)
        self._zone_tint_edge:SetMouseVisible(false)
        self._zone_tint_edge:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    end
    local e = tint.edge or c
    local w, h = self:GetSize()
    self._zone_tint_edge:SetBackColor(Turbine.UI.Color(0.55, e[1] / 255, e[2] / 255, e[3] / 255))
    self._zone_tint_edge:SetPosition(0, math.max(0, h - 1))
    self._zone_tint_edge:SetSize(w, 1)
    self._zone_tint_edge:SetVisible(true)
end

function StatusBarWindow:Update()
    local now = Turbine.Engine.GetGameTime()
    local interactions_enabled = self:_is_edit_mode_active() ~= true
    if self._widgets_interaction_enabled ~= interactions_enabled then
        self:_sync_widget_interaction_modes(interactions_enabled)
    end

    if self._drag_preview_details ~= nil and now >= (self._drag_preview_next_at or 0) then
        self:_refresh_drag_preview_target_from_mouse()
        self:_update_drag_preview(now, false)
    end

    if now >= (self._display_check_due_at or 0) then
        self._display_check_due_at = now + 0.5
        self:_sync_display_width(State.settings.status_bar)
    end

    if now - self.last_update_at < self.update_every then
        return
    end
    self.last_update_at = now

    for i = 1, #self._update_widgets do
        local w = self._update_widgets[i]
        if w ~= nil then
            w:update(now)
        end
    end
end

function StatusBarWindow:destroy()
    self:SetWantsUpdates(false)
    self:SetVisible(false)
    self:_cancel_edit_drag()
    self:_clear_widgets()
    if self._context_menu ~= nil then
        self._context_menu:close()
        self._context_menu:SetParent(nil)
        self._context_menu = nil
    end
    if self._edit_window ~= nil and self._edit_window.owner == self then
        if self._edit_window.set_owner ~= nil then
            self._edit_window:set_owner(nil)
        else
            self._edit_window.owner = nil
        end
    end
    self._edit_window = nil
    if self._drag_preview_fill ~= nil then self._drag_preview_fill:SetParent(nil) end
    if self._drag_preview_edge ~= nil then self._drag_preview_edge:SetParent(nil) end
    if self._drag_preview_trailing_edge ~= nil then self._drag_preview_trailing_edge:SetParent(nil) end
    if self._drag_preview_window ~= nil then
        self._drag_preview_window:SetVisible(false)
    end
    if self._edit_drag_ghost_label ~= nil then self._edit_drag_ghost_label:SetParent(nil) end
    if self._edit_drag_ghost_top ~= nil then self._edit_drag_ghost_top:SetParent(nil) end
    if self._edit_drag_ghost_bottom ~= nil then self._edit_drag_ghost_bottom:SetParent(nil) end
    if self._edit_drag_ghost_left ~= nil then self._edit_drag_ghost_left:SetParent(nil) end
    if self._edit_drag_ghost_right ~= nil then self._edit_drag_ghost_right:SetParent(nil) end
    if self._edit_drag_ghost ~= nil then self._edit_drag_ghost:SetParent(nil) end
    if self._edit_drag_overlay ~= nil then
        self._edit_drag_overlay:SetVisible(false)
    end
end

function StatusBarWindow:_clear_widgets()
    for i = 1, #self._widgets do
        local w = self._widgets[i]
        if w ~= nil then
            w:SetVisible(false)
            w:destroy()
        end
    end
    self._widgets = {}
    self._update_widgets = {}
end

function StatusBarWindow:_is_edit_mode_active()
    return self._edit_window ~= nil and self._edit_window.IsVisible ~= nil and self._edit_window:IsVisible() == true
end

function StatusBarWindow:_sync_widget_interaction_modes(enabled)
    self._widgets_interaction_enabled = enabled == true
    for i = 1, #self._widgets do
        local widget = self._widgets[i]
        if widget ~= nil and widget.set_interaction_enabled ~= nil then
            widget:set_interaction_enabled(self._widgets_interaction_enabled)
        end
    end
end

function StatusBarWindow:open_edit_window()
    local edit_window = self:_ensure_edit_window()
    if edit_window == nil then
        return
    end
    edit_window:open()
end

function StatusBarWindow:capture_edit_window_state()
    local edit_window = self:_ensure_edit_window()
    if edit_window == nil or edit_window.IsVisible == nil then
        return { visible = false }
    end

    local state = {
        visible = edit_window:IsVisible() == true,
    }
    if state.visible == true and edit_window.GetPosition ~= nil then
        state.left, state.top = edit_window:GetPosition()
    end
    return state
end

function StatusBarWindow:restore_edit_window_state(state)
    local edit_window = self:_ensure_edit_window()
    if edit_window == nil or type(state) ~= "table" or state.visible ~= true then
        return
    end

    edit_window:refresh_state()
    edit_window:SetVisible(true)
    if type(state.left) == "number" and type(state.top) == "number" then
        edit_window:SetPosition(state.left, state.top)
    else
        edit_window:position_near_bar()
    end
    edit_window:Activate()
end

function StatusBarWindow:is_palette_widget_available(widget_key)
    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil then
        return false
    end
    return S.status_bar_layout_has_widget(_get_combined_layout_text(raw_sb), widget_key) ~= true
end

function StatusBarWindow:is_palette_entry_available(palette_entry)
    if type(palette_entry) ~= "table" then
        return self:is_palette_widget_available(palette_entry)
    end

    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil then
        return false
    end

    if palette_entry.kind == "api_item" then
        local api_entry = palette_entry.api_entry
        return S.status_bar_layout_has_api_item(_get_combined_layout_text(raw_sb), api_entry ~= nil and api_entry.command or nil) ~= true
    end

    return self:is_palette_widget_available(palette_entry.widget_key)
end

function StatusBarWindow:_get_drag_preview_details_from_session(session)
    if session == nil then
        return nil
    end
    return {
        name = session.menu_title or "",
        preview_width = session.preview_width,
    }
end

function StatusBarWindow:_set_drag_preview(details, zone_key, insert_index)
    if details == nil or zone_key == nil or insert_index == nil then
        self:_hide_drag_preview()
        return
    end

    local preview_width = details.preview_width
    if type(preview_width) ~= "number" then
        preview_width = tonumber(preview_width)
    end
    if preview_width == nil or preview_width < 1 then
        preview_width = self:_get_drag_preview_width_from_details(details)
    end
    details.preview_width = preview_width

    local changed = self._drag_preview_details ~= details or zone_key ~= self._drag_preview_zone_key or
        insert_index ~= self._drag_preview_insert_index

    self._drag_preview_details = details
    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index
    if changed == true then
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_mouse_is_over_bar()
    local x, y = self:_get_mouse_position_in_bar()
    local w, h = self:GetSize()
    if type(x) ~= "number" or type(y) ~= "number" then
        return false, nil, nil
    end
    return x >= 0 and x <= w and y >= 0 and y <= h, x, y
end

function StatusBarWindow:_update_edit_drag_overlay_bounds()
    if self._edit_drag_overlay == nil then
        return
    end
    local display_w, display_h = Turbine.UI.Display.GetSize()
    self._edit_drag_overlay:SetPosition(0, 0)
    self._edit_drag_overlay:SetSize(display_w, display_h)
end

function StatusBarWindow:_layout_edit_drag_ghost(ghost_w, ghost_h)
    if self._edit_drag_ghost == nil then
        return
    end
    local border = 1
    self._edit_drag_ghost:SetSize(ghost_w, ghost_h)
    self._edit_drag_ghost_top:SetPosition(0, 0)
    self._edit_drag_ghost_top:SetSize(ghost_w, border)
    self._edit_drag_ghost_bottom:SetPosition(0, math.max(0, ghost_h - border))
    self._edit_drag_ghost_bottom:SetSize(ghost_w, border)
    self._edit_drag_ghost_left:SetPosition(0, 0)
    self._edit_drag_ghost_left:SetSize(border, ghost_h)
    self._edit_drag_ghost_right:SetPosition(math.max(0, ghost_w - border), 0)
    self._edit_drag_ghost_right:SetSize(border, ghost_h)
    self._edit_drag_ghost_label:SetPosition(8, 0)
    self._edit_drag_ghost_label:SetSize(math.max(0, ghost_w - 16), ghost_h)
end

function StatusBarWindow:_refresh_edit_drag_ghost_text(text)
    if self._edit_drag_ghost_label == nil or self._edit_drag_ghost == nil then
        return
    end

    local title = tostring(text or "")
    local ghost_w = math.max(140, math.min(300, 28 + (string.len(title) * 7)))
    local ghost_h = math.max(22, math.floor(self:GetHeight() + 6))

    self._edit_drag_ghost_label:SetText(title)
    self._edit_drag_ghost_label:SetFont(_edit_drag_ghost_font())
    self:_layout_edit_drag_ghost(ghost_w, ghost_h)
end

function StatusBarWindow:_get_event_screen_position(source, args)
    if source ~= nil and source.PointToScreen ~= nil and args ~= nil then
        local x = args.X
        local y = args.Y
        if type(x) ~= "number" then
            x = tonumber(x)
        end
        if type(y) ~= "number" then
            y = tonumber(y)
        end
        if type(x) == "number" and type(y) == "number" then
            local sx, sy = source:PointToScreen(x, y)
            if type(sx) == "number" and type(sy) == "number" then
                return sx, sy
            end
        end
    end

    if Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Display ~= nil and Turbine.UI.Display.GetMousePosition ~= nil then
        return Turbine.UI.Display.GetMousePosition()
    end

    return nil, nil
end

function StatusBarWindow:_update_edit_drag_ghost_position()
    if self._edit_drag_ghost == nil or self._edit_drag_session == nil then
        return
    end

    local sx, sy = Turbine.UI.Display.GetMousePosition()
    if type(sx) ~= "number" or type(sy) ~= "number" then
        return
    end

    local display_w, display_h = Turbine.UI.Display.GetSize()
    local ghost_w, ghost_h = self._edit_drag_ghost:GetSize()
    local left = sx + 16
    local top = sy + 18

    if left + ghost_w > display_w then
        left = math.max(0, display_w - ghost_w - 4)
    end
    if top + ghost_h > display_h then
        top = math.max(0, display_h - ghost_h - 4)
    end

    self._edit_drag_ghost:SetPosition(left, top)
    self._edit_drag_ghost:SetVisible(true)
end

function StatusBarWindow:_set_widget_drag_hidden(widget, hidden)
    if widget == nil then
        return false
    end

    local wanted_hidden = hidden == true
    if widget._status_bar_drag_hidden == wanted_hidden then
        return false
    end

    widget._status_bar_drag_hidden = wanted_hidden
    widget:SetVisible(wanted_hidden ~= true)
    return true
end

function StatusBarWindow:_restore_edit_drag_source_widget(session)
    if session == nil or session.kind ~= "widget" then
        return false
    end
    return self:_set_widget_drag_hidden(session.source, false)
end

function StatusBarWindow:_restore_widget_after_failed_edit_drag(session)
    if self:_restore_edit_drag_source_widget(session) == true then
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_cancel_edit_drag(restore_source_widget)
    local session = self._edit_drag_session
    local relayout_source = false
    if restore_source_widget ~= false then
        relayout_source = self:_restore_edit_drag_source_widget(session) == true
    end

    self._edit_drag_session = nil
    if self._edit_drag_overlay ~= nil then
        self._edit_drag_overlay:SetMouseVisible(false)
        self._edit_drag_overlay:SetVisible(false)
    end
    if self._edit_drag_ghost ~= nil then
        self._edit_drag_ghost:SetVisible(false)
    end
    self:_hide_drag_preview()
    if relayout_source == true then
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_arm_edit_drag(session, source, args)
    if session == nil or source == nil then
        return
    end

    self:_cancel_edit_drag()
    local start_sx, start_sy = self:_get_event_screen_position(source, args)
    session.source = source
    session.dragging = false
    session.start_screen_x = start_sx
    session.start_screen_y = start_sy
    self._edit_drag_session = session
end

function StatusBarWindow:_ensure_edit_drag_started(source, args)
    local session = self._edit_drag_session
    if session == nil or session.source ~= source then
        return false
    end
    if session.dragging == true then
        return true
    end

    local sx, sy = self:_get_event_screen_position(source, args)
    if type(sx) ~= "number" or type(sy) ~= "number" or type(session.start_screen_x) ~= "number" or
        type(session.start_screen_y) ~= "number" then
        return false
    end

    if math.abs(sx - session.start_screen_x) < EDIT_DRAG_START_DISTANCE and
        math.abs(sy - session.start_screen_y) < EDIT_DRAG_START_DISTANCE then
        return false
    end

    session.dragging = true
    if session.kind == "widget" then
        self:_set_widget_drag_hidden(session.source, true)
    end
    self:_update_edit_drag_overlay_bounds()
    self:_refresh_edit_drag_ghost_text(session.menu_title or "")
    self:_update_edit_drag_ghost_position()
    if self._edit_drag_overlay ~= nil then
        self._edit_drag_overlay:SetMouseVisible(true)
        self._edit_drag_overlay:SetVisible(true)
    end
    self:_update_edit_drag_preview_from_mouse()
    return true
end

function StatusBarWindow:_make_widget_drag_session(widget)
    if widget == nil then
        return nil
    end

    local token = widget._status_bar_layout_token
    if type(token) ~= "string" or token == "" then
        return nil
    end

    return {
        kind = "widget",
        widget_key = widget._status_bar_widget_key,
        source_zone_key = widget._status_bar_zone_key,
        source_visible_index = widget._status_bar_visible_index,
        layout_token = token,
        menu_title = widget._status_bar_menu_title or "",
        preview_width = widget:GetWidth(),
    }
end

function StatusBarWindow:arm_palette_drag(palette_entry, source, args)
    local entry = palette_entry
    if type(entry) ~= "table" then
        entry = {
            kind = "widget",
            widget_key = palette_entry,
            title = S.get_status_bar_widget_display_name(palette_entry),
            token = S.make_status_bar_layout_token(palette_entry),
        }
    end

    if self:is_palette_entry_available(entry) ~= true then
        return
    end

    local token = entry.token
    if token == nil then
        return
    end

    local widget_key = entry.kind == "api_item" and "button" or entry.widget_key

    self:_arm_edit_drag({
        kind = "palette",
        palette_entry = entry,
        widget_key = widget_key,
        layout_token = token,
        menu_title = entry.title or S.get_status_bar_widget_display_name(widget_key),
        preview_width = self:_get_widget_preview_width(widget_key),
    }, source, args)
end

function StatusBarWindow:handle_palette_drag_move(_, source, args)
    local session = self._edit_drag_session
    if session == nil or session.source ~= source then
        return false
    end

    if self:_ensure_edit_drag_started(source, args) == true then
        self:_update_edit_drag_ghost_position()
        self:_update_edit_drag_preview_from_mouse()
    end
    return true
end

function StatusBarWindow:handle_palette_drag_release(_, source, args)
    local session = self._edit_drag_session
    if session == nil or session.source ~= source then
        return false
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return false
    end

    local was_dragging = session.dragging == true
    if was_dragging ~= true then
        self:_cancel_edit_drag()
        return true
    end

    self:_finish_edit_drag_release(session)
    return true
end

function StatusBarWindow:_handle_widget_mouse_down(widget, args)
    if self:_is_edit_mode_active() ~= true then
        return false
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return false
    end

    local session = self:_make_widget_drag_session(widget)
    if session == nil then
        return false
    end

    self:_arm_edit_drag(session, widget, args)
    return true
end

function StatusBarWindow:_handle_widget_mouse_move(widget, args)
    local session = self._edit_drag_session
    if session == nil or session.source ~= widget then
        return false
    end

    if self:_ensure_edit_drag_started(widget, args) == true then
        self:_update_edit_drag_ghost_position()
        self:_update_edit_drag_preview_from_mouse()
    end
    return true
end

function StatusBarWindow:_handle_widget_mouse_up(widget, args)
    local session = self._edit_drag_session
    if session == nil or session.source ~= widget then
        return false
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return false
    end

    local was_dragging = session.dragging == true
    if was_dragging ~= true then
        self:_cancel_edit_drag()
        return true
    end

    self:_finish_edit_drag_release(session)
    return true
end

function StatusBarWindow:_handle_edit_drag_overlay_mouse_move(_)
    local session = self._edit_drag_session
    if session == nil or session.dragging ~= true then
        return
    end

    self:_update_edit_drag_ghost_position()
    self:_update_edit_drag_preview_from_mouse()
end

function StatusBarWindow:_finish_edit_drag_release(session)
    if session == nil then
        return
    end

    local inside_bar, x = self:_mouse_is_over_bar()
    local zone_key = nil
    local insert_index = nil
    if inside_bar == true then
        zone_key, insert_index = self:_get_drop_target_from_mouse_x(x)
    end

    self:_cancel_edit_drag(session.kind ~= "widget")
    if session.kind == "palette" then
        if zone_key ~= nil and insert_index ~= nil then
            self:_apply_palette_drop(session, zone_key, insert_index)
        end
        return
    end

    if zone_key ~= nil and insert_index ~= nil then
        self:_apply_widget_move(session, zone_key, insert_index)
    else
        self:_apply_widget_remove(session)
    end
end

function StatusBarWindow:_handle_edit_drag_overlay_mouse_up(args)
    local session = self._edit_drag_session
    if session == nil or session.dragging ~= true then
        return
    end
    if args ~= nil and args.Button ~= Turbine.UI.MouseButton.Left then
        return
    end

    self:_finish_edit_drag_release(session)
end

function StatusBarWindow:_update_edit_drag_preview_from_mouse()
    local session = self._edit_drag_session
    if session == nil then
        return
    end

    local inside_bar, x = self:_mouse_is_over_bar()
    if inside_bar ~= true then
        self:_hide_drag_preview()
        return
    end

    local zone_key, insert_index = self:_get_drop_target_from_mouse_x(x)
    self:_set_drag_preview(self:_get_drag_preview_details_from_session(session), zone_key, insert_index)
end

function StatusBarWindow:_remove_token_from_zone(raw_sb, zone_key, visible_index)
    if raw_sb == nil or raw_sb.layout == nil or zone_key == nil then
        return nil
    end

    local updated, removed_token = _remove_visible_layout_token_at_index(raw_sb.layout[zone_key], visible_index)
    if removed_token == nil then
        return nil
    end

    raw_sb.layout[zone_key] = updated
    return removed_token
end

function StatusBarWindow:_apply_palette_drop(session, zone_key, insert_index)
    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil or zone_key == nil or insert_index == nil then
        return
    end

    local layout_text = _get_combined_layout_text(raw_sb)
    if session.palette_entry ~= nil and session.palette_entry.kind == "api_item" then
        local api_entry = session.palette_entry.api_entry
        if S.status_bar_layout_has_api_item(layout_text, api_entry ~= nil and api_entry.command or nil) == true then
            _write_status_bar_message(string.format("%s is already on the status bar.", session.menu_title or "Widget"))
            return
        end
    elseif S.status_bar_layout_has_widget(layout_text, session.widget_key) == true then
        _write_status_bar_message(string.format("%s is already on the status bar.", session.menu_title or "Widget"))
        return
    end

    raw_sb.layout[zone_key] = _insert_layout_token_at_visible_index(raw_sb.layout[zone_key], session.layout_token, insert_index)
    _sync_status_bar_after_raw_edit()
end

function StatusBarWindow:_apply_widget_move(session, zone_key, insert_index)
    local raw_sb = _get_raw_status_bar_settings()
    if session == nil or session.source_zone_key == nil or session.source_visible_index == nil then
        self:_restore_widget_after_failed_edit_drag(session)
        return
    end

    local before_left = raw_sb.layout.left
    local before_center = raw_sb.layout.center
    local before_right = raw_sb.layout.right
    local removed_token = self:_remove_token_from_zone(raw_sb, session.source_zone_key, session.source_visible_index)
    if removed_token == nil then
        self:_restore_widget_after_failed_edit_drag(session)
        return
    end

    local target_index = insert_index
    raw_sb.layout[zone_key] = _insert_layout_token_at_visible_index(raw_sb.layout[zone_key], removed_token, target_index)

    if before_left == raw_sb.layout.left and before_center == raw_sb.layout.center and
        before_right == raw_sb.layout.right then
        self:_restore_widget_after_failed_edit_drag(session)
        return
    end

    _sync_status_bar_after_raw_edit()
end

function StatusBarWindow:_apply_widget_remove(session)
    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil or session == nil or session.source_zone_key == nil or session.source_visible_index == nil then
        self:_restore_widget_after_failed_edit_drag(session)
        return
    end

    local removed_token = self:_remove_token_from_zone(raw_sb, session.source_zone_key, session.source_visible_index)
    if removed_token == nil then
        self:_restore_widget_after_failed_edit_drag(session)
        return
    end

    _cleanup_removed_item_registry_entry(raw_sb, removed_token)
    _sync_status_bar_after_raw_edit()
end


function StatusBarWindow:_layout_widgets(sb)
    local bar_w = self:GetWidth()
    local bar_h = self:GetHeight()
    local pad = sb.padding
    local gap = sb.gap

    local left_widgets = self._zone_widgets_left
    local center_widgets = self._zone_widgets_center
    local right_widgets = self._zone_widgets_right

    local preview_zone_key = self._drag_preview_zone_key
    local preview_insert_index = self._drag_preview_insert_index
    local preview_width = self._drag_preview_details ~= nil and self:_get_drag_preview_width() or nil

    local center_preview_w = preview_zone_key == "center" and preview_width or nil
    local right_preview_w = preview_zone_key == "right" and preview_width or nil

    local center_w = _sum_zone_width_with_preview(center_widgets, gap, center_preview_w)
    local right_w = _sum_zone_width_with_preview(right_widgets, gap, right_preview_w)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local function place(zone_key, list, x0)
        local x = x0
        local zone_preview_w = zone_key == preview_zone_key and preview_width or nil
        local zone_preview_index = zone_key == preview_zone_key and preview_insert_index or nil
        local visible_index = 0
        for i = 1, #list do
            local w = list[i]
            if _widget_participates_in_layout(w) == true then
                visible_index = visible_index + 1
                if zone_preview_w ~= nil and zone_preview_index == visible_index then
                    x = x + zone_preview_w + gap
                end
                local y = math.floor((bar_h - w:GetHeight()) / 2)
                if y < 0 then y = 0 end
                w:SetPosition(x, y)
                x = x + w:GetWidth() + gap
            end
        end
    end

    place("left", left_widgets, x_left)
    place("center", center_widgets, x_center)
    place("right", right_widgets, x_right)

    if self._drag_preview_details ~= nil then
        self:_update_drag_preview(Turbine.Engine.GetGameTime(), true)
    end
end

function StatusBarWindow:_rebuild_widgets(sb)
    self:_clear_widgets()

    self._zone_widgets_left = {}
    self._zone_widgets_center = {}
    self._zone_widgets_right = {}

    local zones = sb.zones
    local widgets_cfg = sb.widgets
    local function build_zone(zone_key, dst)
        local list = zones[zone_key]
        for i = 1, #list do
            local entry = list[i]
            local widget_key = entry
            local cfg = nil

            if S.is_status_bar_item_entry(entry) == true then
                widget_key = "item"
                cfg = widgets_cfg.item
            elseif S.is_status_bar_api_entry(entry) == true then
                widget_key = "button"
                cfg = widgets_cfg.button
            elseif S.is_status_bar_button_entry(entry) == true then
                widget_key = "button"
                cfg = widgets_cfg.button
            else
                cfg = widgets_cfg[widget_key]
            end

            if cfg ~= nil and (widget_key == "item" or widget_key == "button" or cfg.enabled == true) then
                local inst = _widget_factory(widget_key, cfg.width, sb.height, sb.font, cfg, entry)
                inst._status_bar_zone_key = zone_key
                inst._status_bar_visible_index = i
                inst._status_bar_widget_key = widget_key
                inst._status_bar_entry = entry
                if S.is_status_bar_item_entry(entry) == true then
                    inst._status_bar_layout_token = entry.token or S.make_status_bar_item_token(entry.name)
                elseif S.is_status_bar_api_entry(entry) == true then
                    inst._status_bar_layout_token = entry.token
                elseif S.is_status_bar_button_entry(entry) == true then
                    inst._status_bar_layout_token = entry.token or
                        S.make_status_bar_button_token(entry.icon_background, entry.command)
                else
                    inst._status_bar_layout_token = S.make_status_bar_layout_token(widget_key)
                end
                inst:SetParent(self)
                inst:SetZOrder(1)
                inst:SetVisible(false)
                _bind_widget_interactions(self, inst, _get_widget_menu_title(widget_key, entry))
                table.insert(self._widgets, inst)
                table.insert(self._update_widgets, inst)
                table.insert(dst, inst)
            end
        end
    end

    build_zone("left", self._zone_widgets_left)
    build_zone("center", self._zone_widgets_center)
    build_zone("right", self._zone_widgets_right)

    self:SetMouseVisible(true)

    self:_layout_widgets(sb)
    if self._edit_window ~= nil then
        self._edit_window:refresh_state()
    end

    for i = 1, #self._widgets do
        local w = self._widgets[i]
        if w ~= nil then
            w:SetVisible(true)
        end
    end
end

function StatusBarWindow:_get_drop_target()
    local mouse_x = select(1, self:_get_mouse_position_in_bar())
    return self:_get_drop_target_from_mouse_x(mouse_x)
end

function StatusBarWindow:_get_drop_target_from_mouse_x(mouse_x)
    local x = mouse_x
    if type(x) ~= "number" then
        x = tonumber(x)
    end

    local zone_key = _resolve_drop_zone_key(self:GetWidth(), x)
    if _zone_widgets_contains_x(self._zone_widgets_left, x) == true then
        zone_key = "left"
    elseif _zone_widgets_contains_x(self._zone_widgets_center, x) == true then
        zone_key = "center"
    elseif _zone_widgets_contains_x(self._zone_widgets_right, x) == true then
        zone_key = "right"
    end

    local widgets = self._zone_widgets_left
    if zone_key == "center" then
        widgets = self._zone_widgets_center
    elseif zone_key == "right" then
        widgets = self._zone_widgets_right
    end

    return zone_key, _zone_insertion_index(widgets, x)
end

function StatusBarWindow:_get_drag_preview_refresh_interval()
    local fps = State.settings ~= nil and State.settings.global ~= nil and State.settings.global.refresh_rate or nil
    if type(fps) ~= "number" then
        fps = tonumber(fps)
    end
    if fps == nil or fps <= 0 then
        fps = 30
    end
    return 1 / fps
end

function StatusBarWindow:_hide_drag_preview()
    local had_preview = self._drag_preview_details ~= nil or self._drag_preview_zone_key ~= nil or
        self._drag_preview_insert_index ~= nil
    self._drag_preview_details = nil
    self._drag_preview_next_at = 0
    self._drag_preview_zone_key = nil
    self._drag_preview_insert_index = nil
    self._drag_preview_fill:SetVisible(false)
    self._drag_preview_edge:SetVisible(false)
    self._drag_preview_trailing_edge:SetVisible(false)
    if had_preview == true then
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_can_preview_drag_item()
    local raw = State.loaded_settings
    local raw_sb = raw ~= nil and raw.status_bar or nil
    return raw_sb ~= nil
end

function StatusBarWindow:_relayout_after_drag_preview_change()
    local sb = State.settings ~= nil and State.settings.status_bar or nil
    if sb ~= nil then
        self:_layout_widgets(sb)
    end
end

function StatusBarWindow:_resolve_drag_target(source, args)
    if source ~= nil and source ~= self and source._status_bar_zone_key ~= nil and
        source._status_bar_visible_index ~= nil then
        local insert_index = source._status_bar_visible_index
        local x = args ~= nil and args.X or nil
        if type(x) ~= "number" then
            x = tonumber(x)
        end
        if type(x) == "number" and x >= (source:GetWidth() / 2) then
            insert_index = insert_index + 1
        end
        return source._status_bar_zone_key, insert_index
    end

    local x = args ~= nil and args.X or nil
    if type(x) ~= "number" then
        x = tonumber(x)
    end
    if x == nil then
        return self:_get_drop_target()
    end
    return self:_get_drop_target_from_mouse_x(x)
end

function StatusBarWindow:_handle_drag_enter(source, args)
    local drag_drop_info = args ~= nil and args.DragDropInfo or nil
    local details = S.extract_item_details_from_drag_drop_info(drag_drop_info)
    if drag_drop_info ~= nil and details == nil then
        self:_hide_drag_preview()
        return
    end
    if details == nil then
        details = { name = "" }
    end
    details.preview_width = self:_get_widget_preview_width("item")
    if self:_can_preview_drag_item() ~= true then
        self:_hide_drag_preview()
        return
    end

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    if zone_key == nil or insert_index == nil then
        self:_hide_drag_preview()
        return
    end

    self:_set_drag_preview(details, zone_key, insert_index)
end

function StatusBarWindow:_handle_drag_leave(source, _)
    if source == self then
        self:_hide_drag_preview()
    end
end

function StatusBarWindow:_handle_drag_move(source, args)
    if self._drag_preview_details == nil then
        return
    end

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    if zone_key == nil or insert_index == nil then
        return
    end

    if zone_key == self._drag_preview_zone_key and insert_index == self._drag_preview_insert_index then
        return
    end

    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index

    local now = Turbine.Engine.GetGameTime()
    if now >= (self._drag_preview_next_at or 0) then
        self._drag_preview_next_at = now + self:_get_drag_preview_refresh_interval()
        self:_relayout_after_drag_preview_change()
    end
end

function StatusBarWindow:_refresh_drag_preview_target_from_mouse()
    if self._drag_preview_details == nil then
        return
    end

    local x, y = self:_get_mouse_position_in_bar()
    local bar_w, bar_h = self:GetSize()
    if type(x) ~= "number" or type(y) ~= "number" then
        return
    end
    if x < 0 or x > bar_w or y < 0 or y > bar_h then
        return
    end

    local zone_key, insert_index = self:_get_drop_target_from_mouse_x(x)
    if zone_key == nil or insert_index == nil then
        return
    end

    if zone_key == self._drag_preview_zone_key and insert_index == self._drag_preview_insert_index then
        return
    end

    self._drag_preview_zone_key = zone_key
    self._drag_preview_insert_index = insert_index
    self:_relayout_after_drag_preview_change()
end

function StatusBarWindow:_get_mouse_position_in_bar()
    if Turbine ~= nil and Turbine.UI ~= nil and Turbine.UI.Display ~= nil and
        Turbine.UI.Display.GetMousePosition ~= nil and self.PointToClient ~= nil then
        local sx, sy = Turbine.UI.Display.GetMousePosition()
        if type(sx) == "number" and type(sy) == "number" then
            return self:PointToClient(sx, sy)
        end
    end

    if self.GetMousePosition ~= nil then
        return self:GetMousePosition()
    end

    return nil, nil
end

function StatusBarWindow:_get_widget_preview_width(widget_key)
    local widgets = State.settings ~= nil and State.settings.status_bar ~= nil and State.settings.status_bar.widgets or nil
    local widget_cfg = widgets ~= nil and widgets[widget_key] or nil
    local width = widget_cfg ~= nil and widget_cfg.width or nil
    if type(width) ~= "number" then
        width = tonumber(width)
    end
    if width == nil or width < 1 then
        width = math.max(24, self:GetHeight())
    end
    return width
end

function StatusBarWindow:_get_drag_preview_width_from_details(details)
    local preview_width = details ~= nil and details.preview_width or nil
    if type(preview_width) ~= "number" then
        preview_width = tonumber(preview_width)
    end
    if preview_width ~= nil and preview_width > 0 then
        return preview_width
    end
    return self:_get_widget_preview_width("item")
end

function StatusBarWindow:_get_drag_preview_width()
    return self:_get_drag_preview_width_from_details(self._drag_preview_details)
end

function StatusBarWindow:_get_drag_preview_x(zone_key, insert_index, preview_width)
    local sb = State.settings.status_bar
    local gap = sb.gap
    local pad = sb.padding
    local bar_w = self:GetWidth()

    local center_preview_w = zone_key == "center" and preview_width or nil
    local right_preview_w = zone_key == "right" and preview_width or nil

    local center_w = _sum_zone_width_with_preview(self._zone_widgets_center, gap, center_preview_w)
    local right_w = _sum_zone_width_with_preview(self._zone_widgets_right, gap, right_preview_w)

    local x_left = pad
    local x_center = math.floor((bar_w - center_w) / 2)
    local x_right = bar_w - pad - right_w
    if x_center < pad then x_center = pad end
    if x_right < pad then x_right = pad end

    local widgets = self._zone_widgets_left
    local x = x_left
    if zone_key == "center" then
        widgets = self._zone_widgets_center
        x = x_center
    elseif zone_key == "right" then
        widgets = self._zone_widgets_right
        x = x_right
    end

    local wanted_index = insert_index
    if type(wanted_index) ~= "number" then
        wanted_index = tonumber(wanted_index)
    end
    if wanted_index == nil or wanted_index < 1 then
        wanted_index = 1
    end

    for i = 1, #widgets do
        local widget = widgets[i]
        if _widget_participates_in_layout(widget) == true then
            if wanted_index == 1 then
                return x
            end
            x = x + widget:GetWidth() + gap
            wanted_index = wanted_index - 1
        end
    end

    return x
end

function StatusBarWindow:_update_drag_preview(now, force)
    if self._drag_preview_details == nil then
        self._drag_preview_fill:SetVisible(false)
        self._drag_preview_edge:SetVisible(false)
        self._drag_preview_trailing_edge:SetVisible(false)
        return
    end

    local zone_key = self._drag_preview_zone_key
    local insert_index = self._drag_preview_insert_index
    if zone_key == nil or insert_index == nil then
        self:_hide_drag_preview()
        return
    end

    if force ~= true then
        self._drag_preview_next_at = now + self:_get_drag_preview_refresh_interval()
    end

    local preview_width = self:_get_drag_preview_width()
    local preview_x = self:_get_drag_preview_x(zone_key, insert_index, preview_width)
    local preview_y = self:GetHeight() > 2 and 1 or 0
    local preview_h = math.max(1, self:GetHeight() - (preview_y * 2))

    self._drag_preview_fill:SetPosition(preview_x, preview_y)
    self._drag_preview_fill:SetSize(preview_width, preview_h)
    self._drag_preview_fill:SetVisible(true)

    self._drag_preview_edge:SetPosition(preview_x, 0)
    self._drag_preview_edge:SetSize(DRAG_PREVIEW_EDGE_W, self:GetHeight())
    self._drag_preview_edge:SetVisible(true)

    self._drag_preview_trailing_edge:SetPosition(preview_x + preview_width - DRAG_PREVIEW_EDGE_W, 0)
    self._drag_preview_trailing_edge:SetSize(DRAG_PREVIEW_EDGE_W, self:GetHeight())
    self._drag_preview_trailing_edge:SetVisible(true)
end

function StatusBarWindow:_handle_drag_drop(source, args)
    self:_hide_drag_preview()
    local edit_window_state = nil
    if self:_is_edit_mode_active() == true then
        edit_window_state = self:capture_edit_window_state()
    end

    local drag_drop_info = args ~= nil and args.DragDropInfo or nil
    local details = S.extract_item_details_from_drag_drop_info(drag_drop_info)
    if details == nil or details.name == nil then
        return
    end

    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil then
        return
    end

    local token = S.make_status_bar_item_token(details.name)
    if token == nil then
        return
    end

    if S.status_bar_layout_has_item(_get_combined_layout_text(raw_sb), details.name) == true then
        _write_status_bar_message(string.format("%s is already on the status bar.", token))
        return
    end

    local zone_key, insert_index = self:_resolve_drag_target(source, args)
    raw_sb.layout[zone_key] = _insert_layout_token_at_visible_index(raw_sb.layout[zone_key], token, insert_index)
    S.set_status_bar_item_registry_icon(raw_sb.item_registry, details.name, details.icon_image_id)

    _sync_status_bar_after_raw_edit(edit_window_state)
end

function StatusBarWindow:_ensure_context_menu()
    if self._context_menu == nil then
        local menu = UI.Widgets.LuiMenu()
        menu:SetVisible(false)
        menu:SetSize(1, 1)
        menu:SetParent(self)
        self._context_menu = menu
    end

    local menu = self._context_menu
    menu:set_scale(State.settings.global.scale)
    if menu:is_open() == true then
        menu:close()
    end
    menu:clear_items()
    return menu
end

function StatusBarWindow:_open_context_menu(menu)
    local mouse_x, mouse_y = Turbine.UI.Display.GetMousePosition()
    menu:open_at_screen(mouse_x, mouse_y)
end

function StatusBarWindow:_show_bar_menu()
    local menu = self:_ensure_context_menu()
    menu:add_action({ text = TR["Status Bar"], enabled = false })
    menu:add_separator()
    menu:add_action({
        text = TR["Edit Bar"],
        triggered = function()
            self:open_edit_window()
        end,
    })
    self:_open_context_menu(menu)
end

function StatusBarWindow:_show_widget_menu(widget)
    if widget == nil then
        return
    end

    local menu = self:_ensure_context_menu()
    menu:add_action({ text = widget._status_bar_menu_title or "", enabled = false })
    menu:add_separator()
    menu:add_action({
        text = TR["Edit Bar"],
        triggered = function()
            self:open_edit_window()
        end,
    })
    menu:add_action({
        text = TR["Remove"],
        triggered = function()
            self:_remove_widget_instance(widget)
        end,
    })
    self:_open_context_menu(menu)
end

function StatusBarWindow:_remove_widget_instance(widget)
    local zone_key = widget ~= nil and widget._status_bar_zone_key or nil
    local visible_index = widget ~= nil and widget._status_bar_visible_index or nil
    local raw_sb = _get_raw_status_bar_settings()
    if raw_sb == nil or zone_key == nil then
        return
    end
    local hid_widget = self:_set_widget_drag_hidden(widget, true)
    local removed_token = self:_remove_token_from_zone(raw_sb, zone_key, visible_index)
    if removed_token == nil then
        if hid_widget == true then
            self:_set_widget_drag_hidden(widget, false)
        end
        return
    end

    _cleanup_removed_item_registry_entry(raw_sb, removed_token)
    _sync_status_bar_after_raw_edit()
end

function StatusBarWindow:_sync_display_width(sb)
    local display_w, display_h = Turbine.UI.Display.GetSize()
    if display_w == self._last_display_w then
        return
    end

    self._last_display_w = display_w
    self:SetPosition(0, 0)
    self:SetSize(display_w, sb.height)
    if self._zone_tint_edge ~= nil then
        self._zone_tint_edge:SetPosition(0, math.max(0, sb.height - 1))
        self._zone_tint_edge:SetSize(display_w, 1)
    end
    if self._drag_preview_window ~= nil then
        self._drag_preview_window:SetPosition(0, 0)
        self._drag_preview_window:SetSize(display_w, sb.height)
    end
    if self._edit_drag_overlay ~= nil then
        self._edit_drag_overlay:SetPosition(0, 0)
        self._edit_drag_overlay:SetSize(display_w, display_h)
    end
    if self._edit_window ~= nil and self._edit_window.IsVisible ~= nil and self._edit_window:IsVisible() == true then
        self._edit_window:position_near_bar()
    end
    self:_layout_widgets(sb)
end
