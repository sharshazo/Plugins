-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local TR = _G.LUI.Locale.TR
local Pages = _G.LUI.Settings.Pages
local ConfigContent = _G.LUI.Settings.Content.ConfigContent
local ConfigTabs = _G.LUI.Settings.Content.ConfigTabs
local FONT_TO_LOTRO = _G.LUI.Utils.FONT_TO_LOTRO
local State = _G.LUI.Settings.State
local UI = _G.LUI.UI
local class = _G.LUI.Core.class
import "Turbine.UI"

import "LUI.src.Settings.Tabs.feature_shell"
import "LUI.src.Settings.Content.content"
import "LUI.src.Settings.Content.tabs"
import "LUI.src.UI.Widgets"

local FeatureShell = _G.LUI.Settings.Tabs.SettingsFeatureShell
local scaled_int = FeatureShell.scaled_int
local Style = UI.Widgets.Style

local HELP_PAGE_FONT_SIZE_OFFSET = 3
local GITHUB_URL = "https://github.com/Geldahr/LUI"
local GITHUB_LABEL_TEXT =
    TR["For more information, feature requests, or bug reports, please visit the GitHub repository:"]
local ABOUT_HEIGHT = 156
local GITHUB_HEIGHT = 59
local FEATURES_HEIGHT = 620
local INTERACTIONS_HEIGHT = 980
local COMMANDS_HEIGHT = 400
local GITHUB_LINK_HEIGHT = 22
local GITHUB_LABEL_HEIGHT = 30

local function _scaled_help_size(value)
    return value * State.settings.global.scale
end

local function _scaled_help_int(value)
    return math.floor(_scaled_help_size(value) + 0.5)
end

local function _scaled_help_font()
    local size = Style.CONTENT_SMALL_FONT_SIZE + HELP_PAGE_FONT_SIZE_OFFSET
    local font = FONT_TO_LOTRO(Style.CONTENT_SMALL_FONT_NAME, _scaled_help_size(size))
    if font == nil then
        error("Missing help font: " .. tostring(Style.CONTENT_SMALL_FONT_NAME) .. " " .. tostring(size))
    end
    return font
end

local function _layout_help_text(entry)
    local w, h = entry.control:GetSize()
    entry.body:SetPosition(0, 0)
    entry.body:SetSize(w, h)
end

local function _create_help_text(page, key, text, height)
    local entry = page:add_custom(key, height)

    entry.body = UI.Widgets.LuiLabel()
    entry.body:SetParent(entry.control)
    entry.body:SetFont(_scaled_help_font())
    entry.body:SetMultiline(true)
    entry.body:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    entry.body:SetForeColor(Style.FOREGROUND)
    entry.body:SetText(text)

    entry.control.SizeChanged = function()
        _layout_help_text(entry)
    end
    entry.apply_ui_scale = function()
        entry.body:SetFont(_scaled_help_font())
        _layout_help_text(entry)
    end
    entry:apply_ui_scale()

    return entry
end

local function _layout_link_box(entry)
    local w = entry.control:GetWidth()
    local link_h = _scaled_help_int(GITHUB_LINK_HEIGHT)
    local label_h = _scaled_help_int(GITHUB_LABEL_HEIGHT)
    if label_h < 1 then
        label_h = 1
    end

    entry.label:SetPosition(0, 0)
    entry.label:SetSize(w, label_h)
    entry.link_tb:SetPosition(0, entry.label:GetTop() + entry.label:GetHeight())
    entry.link_tb:SetSize(w, link_h)
end

local function _create_link_box(page, key, label_text, link_text, height)
    local entry = page:add_custom(key, height)

    entry.label = UI.Widgets.LuiLabel()
    entry.label:SetParent(entry.control)
    entry.label:SetFont(_scaled_help_font())
    entry.label:SetMultiline(true)
    entry.label:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
    entry.label:SetForeColor(Style.FOREGROUND)
    entry.label:SetText(label_text)

    entry.link_tb = UI.Widgets.LuiLineEdit()
    entry.link_tb:SetParent(entry.control)
    entry.link_tb:SetFont(_scaled_help_font())
    entry.link_tb:SetForeColor(Style.CONTROL_FOREGROUND)
    entry.link_tb:SetMultiline(false)
    entry.link_tb:SetReadOnly(true)
    entry.link_tb:SetSelectable(true)
    entry.link_tb:SetText(link_text)
    entry.link_tb:SetBackColor(Style.CONTROL_BACKGROUND_READONLY)
    entry.link_tb:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    entry.link_tb:SetZOrder(2)

    entry.control.SizeChanged = function()
        _layout_link_box(entry)
    end
    entry.apply_ui_scale = function()
        entry.label:SetFont(_scaled_help_font())
        entry.link_tb:SetFont(_scaled_help_font())
        _layout_link_box(entry)
    end
    entry:apply_ui_scale()

    return entry
end

local function _new_about_section(window)
    local page = ConfigContent(window, 4)

    local about_text = table.concat({
        TR["LUI replaces and extends key LotRO UI elements with a cleaner and more configurable layout."],
        TR["It focuses on combat-related UI such as self vitals, target vitals, boss vitals, fellowship vitals, raid vitals, expiring effects, cooldowns elements and also inventory, and status bar."],
        "",
        TR["The global LUI UI scale applies uniformly across the whole LUI interface."],
        TR["By default it is separate from the built-in LotRO UI scaling; native scaling can be enabled in Global settings."],
        "",
        TR["For the best experience, set the global LUI UI scale before changing individual sizes."],
        TR["Recommended starting points: 1080p = 1.0, 1440p = 1.3 to 1.4, 2160p / 4k = 2.0."],
        TR["After the global LUI UI scale feels right, use the other settings for micro adjustments."],
    }, "\n")

    _create_help_text(page, "help_about", about_text, ABOUT_HEIGHT)
    page:add_break()
    _create_link_box(page, "help_github", GITHUB_LABEL_TEXT, GITHUB_URL, GITHUB_HEIGHT)

    return page
end

local function _new_commands_section(window)
    local page = ConfigContent(window, 4)

    local commands_text = table.concat({
        TR["/lui help - Print slash command help in chat."],
        TR["/lui config - Toggle the configuration window."],
        TR["/lui move - Toggle LUI move mode."],
        TR["/lui move cancel - Leave move mode without saving the current positions."],
        TR["/lui inventory - Toggle the inventory window."],
        TR["/lui inv - Short alias for /lui inventory."],
        TR["/lui assets - Toggle the assets window."],
        TR["/lui a - Short alias for /lui assets."],
        TR["/lui craft - Toggle the crafting window."],
        TR["/lui travel - Toggle the travel window."],
        TR["/lui trav - Short alias for /lui travel."],
        TR["/lui bestiary - Toggle the encyclopedia window."],
        TR["/lui beast - Alias for /lui bestiary."],
        TR["/lui b - Short alias for /lui bestiary."],
        TR["/lui card [monster name] - Open the bestiary card for a monster."],
        TR["/lui api sb --add -k key -t title -i image -c /command - Register a status bar API button."],
    }, "\n")

    _create_help_text(page, "help_commands", commands_text, COMMANDS_HEIGHT)
    return page
end

local function _new_features_section(window)
    local page = ConfigContent(window, 4)

    local features_text = table.concat({
        TR["Combat HUD"],
        TR["LUI can replace self, target, boss, target's target, fellowship, and raid vitals while handing disabled parts back to the built-in LotRO HUD."],
        TR["Vitals can show morale, power/wrath, bubbles, class/leader icons, effect slots, and configurable text labels."],
        TR["Expiring Effects show timed self and target buffs/debuffs, including curable and non-curable target debuffs."],
        TR["Cooldowns track skill cooldowns with filters for minimum cooldown, whitelist, blacklist, rows, and columns."],
        TR["Drops shows recent loot from chat/backpack events with icons when the game exposes them."],
        "",
        TR["Inventory and Assets"],
        TR["The inventory window can replace the default backpack and accepts normal item drag/drop between slots."],
        TR["Assets indexes backpack, bank, vault, and shared storage items by character, storage, owner, quantity, and source."],
        TR["Assets can stack matching items, switch icon/detail view, and open Crafting for materials used by recipes."],
        "",
        TR["Knowledge and Travel"],
        TR["Bestiary browses monster records, drops, levels, morale/power, taxonomy, locations, quests, deeds, abilities, mitigations, and resistances."],
        TR["Bestiary capture and target-name lookup are available on the English client."],
        TR["Crafting browses recipes, favorites, availability, source scopes, material trees, and tracked plans."],
        TR["Crafting can open Bestiary searches for droppable missing materials."],
        TR["Travel lists detected travel skills as usable quickslots in list or grid mode."],
        "",
        TR["Status Bar and Profiles"],
        TR["Status Bar can show time, inventory space, equipment wear, money, wallet items, shortcut buttons, the tracked crafting plan, tracked inventory items, and custom API buttons."],
        TR["Profiles let characters share or switch configurations; Global settings control LUI scale, native scaling, colors, fonts, borders, and overlays."],
    }, "\n")

    _create_help_text(page, "help_features", features_text, FEATURES_HEIGHT)
    return page
end

local function _new_interactions_section(window)
    local page = ConfigContent(window, 4)

    local interactions_text = table.concat({
        TR["General"],
        TR["LUI windows with title bars can be dragged by the title bar, resized from edges/corners, closed from the close button, and maximized/restored when the maximize button is visible."],
        TR["/lui move toggles HUD move mode; drag HUD frames to place them. /lui move cancel exits without saving the current positions."],
        TR["When enabled, the LotRO move-mode action can toggle LUI move mode."],
        TR["The LotRO hide-UI action also toggles LUI HUD visibility."],
        TR["If the LUI inventory replacement is enabled, the backpack key opens the LUI inventory window."],
        TR["Drop rows with item info expose the normal LotRO item hover tooltip."],
        "",
        TR["Bestiary"],
        TR["Double-click a non-player target's LUI target vitals to open its Bestiary card on the English client."],
        TR["Double-click a Bestiary result row to open that monster's card."],
        TR["Use the Bestiary compass/location button while the Bestiary is open to run the localized location command and filter Bestiary results to the current area when LUI can resolve it."],
        TR["Bestiary search supports plain text, quoted phrases, OR with |, and filters loc:<region/area>, gen:<genus/subcategory>, and lvl:<min-max>."],
        "",
        TR["Crafting"],
        TR["Click a recipe row or recipe icon to select the recipe."],
        TR["Click a recipe star to toggle favorite; the star beside search filters to favorites."],
        TR["Use fav:true or fav:false, prof:<name>, rank:<rank>, lvl:<min-max>, and avail:ready or avail:missing in Crafting search."],
        TR["Hover material source/amount hints to see where required items are available."],
        TR["Click a material Bestiary button to search for droppable sources; click the plan Bestiary button to search missing droppable materials."],
        TR["Use the plan count controls to change recipe counts, x to remove a recipe, Track Plan to save it to the status bar, Revert to reload the saved plan, and Clear to empty the draft."],
        "",
        TR["Assets, Inventory, and Travel"],
        TR["Assets search supports owner:<character> and store:<backpack|bank|vault|shared_storage>."],
        TR["Click Stack items text or checkbox to group matching Assets results."],
        TR["Click the Assets view icons to switch between icon and detail views; click Recipes to open Crafting for visible recipe materials."],
        TR["Drag items into LUI inventory slots to move them through LotRO item drag/drop."],
        TR["Travel quickslots behave like LotRO travel skill quickslots; click them to use the skill."],
        "",
        TR["Status Bar"],
        TR["Right-click the status bar or any status bar widget to open Edit Bar; widget menus also include Remove."],
        TR["In Edit Bar, drag entries onto the status bar and drag existing status bar items to reorder them."],
        TR["Drag an existing status bar item outside the bar to remove it."],
        TR["Drag an item from the LUI inventory window onto the status bar to track that item count."],
        TR["Status bar layout tokens include %time%, %inventory%, %durability%, %gold%, %wallet%, %config%, %craft%, %craft.plan%, %travel%, %assets%, %encyclopedia%, and %raid%."],
        TR["Tracked item tokens use %item:[Item Name]%; command buttons use %button:<icon-or-label>:/command%."],
        TR["External plugins or aliases can add custom status bar buttons with /lui api sb --add -k key -t title -i image -c /command."],
    }, "\n")

    _create_help_text(page, "help_interactions", interactions_text, INTERACTIONS_HEIGHT)
    return page
end

local HelpPage = class(ConfigTabs)
Pages.HelpPage = HelpPage

function HelpPage:Constructor(window)
    ConfigTabs.Constructor(self, window)
    self.show_main_content_border = false
    self.sub_tab_bar:set_content_padding(scaled_int(8))
    self:add_tab(TR["About LUI"], "about", _new_about_section(window))
    self:add_tab(TR["Features"], "features", _new_features_section(window))
    self:add_tab(TR["Interactions"], "interactions", _new_interactions_section(window))
    self:add_tab(TR["Commands"], "commands", _new_commands_section(window))
end

function HelpPage:apply_ui_scale()
    ConfigTabs.apply_ui_scale(self)
    self.sub_tab_bar:set_content_padding(scaled_int(8))
end
