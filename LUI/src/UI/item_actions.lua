-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- Shared right-click actions menu for item names (bestiary card drop
-- chips). Entry presence is decided here, at menu-open time, with cheap
-- probes -- never during binds, so adding entries can never slow a list.

local TR = _G.LUI.Locale.TR
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local Shortcuts = UI.Shortcuts

local ItemActions = UI.ItemActions

local _menu = nil

local function _ensure_menu(anchor)
    if _menu == nil then
        _menu = UI.Widgets.LuiMenu()
        _menu:SetVisible(false)
        _menu:SetSize(1, 1)
    end
    if _menu:GetParent() ~= anchor then
        _menu:SetParent(anchor)
    end
    _menu:set_scale(State.settings.global.scale)
    return _menu
end

-- Open the item actions menu for an item display name, at a mouse point
-- relative to anchor (the clicked control; it also decides which window
-- the click-away overlay covers). Returns true when the menu opened.
-- Cross-feature modules are resolved at call time: clicks can only happen
-- long after every feature is loaded.
function ItemActions.show_menu(anchor, x, y, item_name)
    local menu = _ensure_menu(anchor)
    if menu:is_open() == true then
        menu:close()
    end
    menu:clear_items()

    if _G.LUI.Features.Encyclopedia.encyclopedia_tab_for_item(item_name) ~= nil then
        menu:add_action({
            text = TR["Open in Encyclopedia"],
            triggered = function()
                Shortcuts.open_encyclopedia_item_search(item_name)
            end,
        })
    end

    local store = _G.LUI.Features.Crafting.get_shared_store()
    if store ~= nil then
        local producing = store:first_recipe_producing_name(item_name)
        if producing ~= nil then
            menu:add_action({
                text = TR["How to craft this"],
                triggered = function()
                    Shortcuts.open_crafting_item_search(item_name, producing.id)
                end,
            })
        end
        -- crafting materials (hides, ore, ...) link to the recipes that
        -- consume them
        if store:has_recipes_using_name(item_name) == true then
            menu:add_action({
                text = TR["Show crafts using this"],
                triggered = function()
                    Shortcuts.open_crafting_item_search(item_name)
                end,
            })
        end
    end

    local screen_x, screen_y = anchor:PointToScreen(x, y)
    menu:open_at_screen(screen_x, screen_y)
    return menu:is_open() == true
end
