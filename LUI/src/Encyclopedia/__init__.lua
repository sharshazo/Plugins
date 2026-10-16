-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

-- the lore Items DB is staged in the background after login (Drops icons,
-- item links); the item tabs and the resource card read it
import "LUI.src.Data.items_prewarm"
import "LUI.src.Encyclopedia.card_widgets"
import "LUI.src.Encyclopedia.browser_shared"
import "LUI.src.Encyclopedia.resource_card"
import "LUI.src.Encyclopedia.item_browser"
import "LUI.src.Encyclopedia.encyclopedia_window"
