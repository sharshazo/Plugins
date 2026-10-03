-- CubePlugins/DeedTracker/DataFiles/DeedsByZone.lua
--
-- Pagina extra "Por zona" (pedido del jugador: "reordenar todo por zona").
--
-- NO mueve ni borra nada: las 10 paginas originales (Clase/Raza/Epica,
-- Escaramuzas, Instancias, Pasatiempos, La Guerra, Eriador, Rhovanion,
-- Gondor, Mordor, Haradwaith) quedan exactamente igual. Esta pagina es
-- una VISTA mas, armada al cargar a partir de los mismos datos:
--
--   una pestaña por zona (las mismas zonas y en el mismo orden que las
--   paginas Eriador..Haradwaith), y dentro de cada una:
--     1) las hazañas propias de la zona (identicas a su pestaña original)
--     2) "Instancias": las hazañas de las instancias/incursiones que estan
--        en esa zona (sacadas de la pagina Instancias)
--     3) "Reputacion": las hazañas de las facciones de esa zona (sacadas
--        de Clase/Raza/Epica > Reputacion)
--
-- Las hazañas son las MISMAS (mismo ID, mismo guardado): marcar una aca la
-- marca tambien en su pagina original y viceversa. Los totales generales
-- se calculan sobre la base de hazañas (no sobre las paginas), asi que no
-- se cuentan dos veces. Una instancia o faccion cuya zona no es segura se
-- deja solo en su pagina original (mejor no ubicarla que ubicarla mal).
--
-- Mismo entorno que DeedInfo.lua (se importa justo despues, desde Main.lua),
-- por eso usa los mismos nombres globales (_DEED_LOG_PAGES, ERIADOR, ...).

BY_ZONE = 11;

-- nombre del boton de la pagina, segun el idioma del plugin
local PAGE_NAME = {
    ["ES"] = "Por zona";
    ["EN"] = "By Zone";
    ["DE"] = "Nach Zone";
    ["FR"] = "Par zone";
    ["RU"] = "По зонам";
};
local SECTION_INSTANCES = {
    ["ES"] = "Instancias de la zona";
    ["EN"] = "Instances in this zone";
    ["DE"] = "Instanzen in dieser Zone";
    ["FR"] = "Instances de la zone";
    ["RU"] = "Подземелья зоны";
};
local SECTION_REPUTATION = {
    ["ES"] = "Reputación de la zona";
    ["EN"] = "Reputation in this zone";
    ["DE"] = "Ruf in dieser Zone";
    ["FR"] = "Réputation de la zone";
    ["RU"] = "Репутация зоны";
};
local function Localized(t)
    return t[LANGUAGE] or t["EN"];
end

-- categorias "Level NN+" (encabezados de nivel, no de lugar) y "Not
-- Actively Achievable" (hazañas que ya no se pueden hacer): mismos IDs en
-- todos los idiomas (DeedCategories*.lua comparten numeracion)
local LEVEL_HEADERS = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true,
    [14]=true, [16]=true, [22]=true, [27]=true, [29]=true, [33]=true, [42]=true, [44]=true };
local NOT_ACHIEVABLE = { [21]=true, [41]=true, [63]=true, [69]=true, [76]=true, [91]=true, [95]=true,
    [100]=true, [110]=true, [113]=true, [119]=true, [282]=true, [153]=true, [170]=true, [240]=true,
    [257]=true, [259]=true };

-- Instancias: pestaña de la pagina Instancias -> zona por defecto de TODA
-- la pestaña (expansiones que transcurren en una sola zona). Pestañas con
-- instancias en varias zonas no tienen defecto: se ubica cada instancia
-- por separado en INSTANCE_CATEGORY_ZONE.
local INSTANCE_TAB_ZONE = {
    [I_MINES_OF_MORIA] = { PAGE = RHOVANION, TAB = R_MORIA };
    [I_SCOURGE_OF_KHAZAD_DUM] = { PAGE = RHOVANION, TAB = R_MORIA };
    [I_TOWER_OF_DOL_GULDUR] = { PAGE = RHOVANION, TAB = R_SOUTHERN_MIRKWOOD };
    [I_ASHES_OF_OSGILIATH] = { PAGE = GONDOR, TAB = G_EASTERN_GONDOR };
    [I_THE_BATTLE_OF_PELENNOR] = { PAGE = GONDOR, TAB = G_OLD_ANORIEN };
    [I_THE_PLATEAU_OF_GORGOROTH] = { PAGE = MORDOR, TAB = M_GORGOROTH };
    [I_THE_GREY_MOUNTAINS] = { PAGE = RHOVANION, TAB = R_THE_DWARF_HOLDS };
    [I_MINAS_MORGUL] = { PAGE = MORDOR, TAB = M_IMLAD_MORGUL };
    [I_THE_WAR_OF_THREE_PEAKS] = { PAGE = RHOVANION, TAB = R_ELDERSLADE };
    [I_THE_MOUNTAIN_HOLD] = { PAGE = RHOVANION, TAB = R_GUNDABAD };
    [I_RETURN_TO_CARN_DUM] = { PAGE = ERIADOR, TAB = E_ANGMAR };
    [I_CORSAIRS_OF_UMBAR] = { PAGE = HARADWAITH, TAB = H_UMBAR_BAHARBEL };
    [I_THE_LEGACY_OF_MORGOTH] = { PAGE = HARADWAITH, TAB = H_MUR_GHALA };
};

-- Instancias ubicadas una por una (id de su categoria en la pagina
-- Instancias). Sin ubicar a proposito: Ost Dunhoth, Iorbar's Peak y las de
-- Kingdoms of Harad (zona no confirmada).
local INSTANCE_CATEGORY_ZONE = {
    -- Shadows of Angmar
    [23] = { ERIADOR, E_BREE_LAND };        -- The Great Barrow
    [24] = { ERIADOR, E_LONE_LANDS };       -- Inn of the Forsaken
    [25] = { ERIADOR, E_BREE_LAND };        -- Woe of the Willow (Old Forest)
    [26] = { ERIADOR, E_SWANFLEET_CARDOLAN }; -- Sarch Vorn, the Black Grave
    [28] = { ERIADOR, E_NORTH_DOWNS };      -- Fornost
    [30] = { ERIADOR, E_EVENDIM };          -- Annuminas (+ The Halls of Night)
    [32] = { ERIADOR, E_TROLLSHAWS };       -- Agoroth, the Narrowdelve
    [34] = { ERIADOR, E_ANGMAR };           -- Angmar (Carn Dum, Urugarth, Barad Gularan, The Rift)
    [39] = { ERIADOR, E_MISTY_MOUNTAINS };  -- Helegrod
    [40] = { ERIADOR, E_EREGION };          -- Tham Mirdain
    -- In Their Absence
    [64] = { ERIADOR, E_SHIRE };            -- Northcotton Farm
    [65] = { ERIADOR, E_NORTH_DOWNS };      -- Stoneheight
    [66] = { ERIADOR, E_TROLLSHAWS };       -- Lost Temple
    [67] = { ERIADOR, E_FOROCHEL };         -- Sari-surma
    -- Rise of Isengard (Isengard / Nan Curunir y alrededores)
    [70] = { ERIADOR, E_DUNLAND };          -- The Foundry
    [71] = { ERIADOR, E_DUNLAND };          -- Fangorn's Edge
    [72] = { ERIADOR, E_DUNLAND };          -- Pits of Isengard
    [73] = { ERIADOR, E_DUNLAND };          -- Dargnakh Unleashed
    [74] = { ERIADOR, E_DUNLAND };          -- The Tower of Orthanc
    [75] = { ERIADOR, E_DUNLAND };          -- Draigoch's Lair
    -- The Road to Erebor
    [77] = { ERIADOR, E_MISTY_MOUNTAINS };  -- Seat of the Great Goblin
    [78] = { RHOVANION, R_SOUTHERN_MIRKWOOD }; -- Web of Scuttledells
    [80] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- Flight to the Lonely Mountain
    [81] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- The Bells of Dale
    [82] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- The Fires of Smaug
    [83] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- The Battle for Erebor
};

-- Reputacion (Clase/Raza/Epica > Reputacion): faccion -> zona
local REPUTATION_CATEGORY_ZONE = {
    [173] = { ERIADOR, E_ERED_LUIN };       -- Thorin's Hall
    [174] = { ERIADOR, E_SHIRE };           -- The Mathom Society
    [175] = { ERIADOR, E_BREE_LAND };       -- Men of Bree
    [177] = { ERIADOR, E_LONE_LANDS };      -- The Eglain
    [178] = { ERIADOR, E_NORTH_DOWNS };     -- Rangers of Esteldin
    [179] = { ERIADOR, E_EVENDIM };         -- The Wardens of Annuminas
    [180] = { ERIADOR, E_TROLLSHAWS };      -- Elves of Rivendell
    [181] = { ERIADOR, E_ANGMAR };          -- Council of the North
    [182] = { ERIADOR, E_FOROCHEL };        -- Lossoth of Forochel
    [183] = { RHOVANION, R_LOTHLORIEN };    -- Galadhrim
    [184] = { RHOVANION, R_MORIA };         -- Iron Garrison Guards
    [185] = { RHOVANION, R_MORIA };         -- Iron Garrison Miners
    [186] = { ERIADOR, E_ENEDWAITH };       -- Algraig, Men of Enedwaith
    [187] = { ERIADOR, E_ENEDWAITH };       -- The Grey Company
    [188] = { RHOVANION, R_SOUTHERN_MIRKWOOD }; -- Malledhrim
    [189] = { ERIADOR, E_DUNLAND };         -- Men of Dunland
    [190] = { RHOVANION, R_GREAT_RIVER };   -- The Riders of Stangard
    [191] = { ERIADOR, E_DUNLAND };         -- Theodred's Riders (Gap of Rohan)
    [192] = { RHOVANION, R_GREAT_RIVER };   -- Heroes of Limlight Gorge
    [193] = { RHOVANION, R_EASTERN_ROHAN }; -- Men of the Wold
    [194] = { RHOVANION, R_EASTERN_ROHAN }; -- Men of the Norcrofts
    [195] = { RHOVANION, R_EASTERN_ROHAN }; -- Men of the Sutcrofts
    [196] = { RHOVANION, R_EASTERN_ROHAN }; -- Men of the Entwash Vale
    [197] = { RHOVANION, R_WILDERMORE };    -- People of Wildermore
    [198] = { RHOVANION, R_WILDERMORE };    -- Survivors of Wildermore
    [200] = { RHOVANION, R_WESTERN_ROHAN }; -- The Eorlingas
    [201] = { RHOVANION, R_WESTERN_ROHAN }; -- The Helmingas
    [202] = { GONDOR, G_WESTERN_GONDOR };   -- Dol Amroth
    [203] = { GONDOR, G_WESTERN_GONDOR };   -- Dol Amroth City Watch
    [204] = { GONDOR, G_WESTERN_GONDOR };   -- Men of Ringlo Vale
    [205] = { GONDOR, G_WESTERN_GONDOR };   -- Men of Dor-en-Ernil
    [206] = { GONDOR, G_CENTRAL_GONDOR };   -- Men of Lebennin
    [207] = { GONDOR, G_CENTRAL_GONDOR };   -- Pelargir
    [208] = { GONDOR, G_EASTERN_GONDOR };   -- Rangers of Ithilien
    [209] = { GONDOR, G_OLD_ANORIEN };      -- Defenders of Minas Tirith
    [210] = { GONDOR, G_THE_WASTES };       -- Host of the West
    [211] = { GONDOR, G_THE_WASTES };       -- Host of the West Master
    [212] = { GONDOR, G_THE_WASTES };       -- Host of the West: Weapons
    [213] = { GONDOR, G_THE_WASTES };       -- Host of the West: Armour
    [214] = { GONDOR, G_THE_WASTES };       -- Host of the West: Provisions
    [215] = { GONDOR, G_FAR_ANORIEN };      -- Riders of Rohan
    [216] = { MORDOR, M_GORGOROTH };        -- The Plateau of Gorgoroth
    [217] = { MORDOR, M_GORGOROTH };        -- Conquest of Gorgoroth
    [218] = { MORDOR, M_GORGOROTH };        -- Fushaum Bal South
    [219] = { MORDOR, M_GORGOROTH };        -- Fushaum Bal North
    [220] = { MORDOR, M_GORGOROTH };        -- Red Sky Clan
    [221] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- Dwarves of Erebor
    [222] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- Elves of Felegoth
    [223] = { RHOVANION, R_STRONGHOLDS_OF_THE_NORTH }; -- Men of Dale
    [224] = { RHOVANION, R_THE_DWARF_HOLDS }; -- Grey Mountains Expedition
    [225] = { RHOVANION, R_VALES_OF_ANDUIN }; -- Wilderfolk
    [227] = { MORDOR, M_IMLAD_MORGUL };     -- The White Company
    [228] = { MORDOR, M_IMLAD_MORGUL };     -- Reclamation of Minas Ithil
    [230] = { RHOVANION, R_GUNDABAD };      -- March on Gundabad
    [236] = { RHOVANION, R_GUNDABAD };      -- Reclaimers of the Mountain-hold
    [238] = { ERIADOR, E_SHIRE };           -- The Yonder-watch
    [239] = { ERIADOR, E_SWANFLEET_CARDOLAN }; -- Dunedain of Cardolan
    [283] = { RHOVANION, R_THE_DWARF_HOLDS }; -- Stewards of the Iron-home
    [290] = { HARADWAITH, H_UMBAR_BAHARBEL }; -- Citizens of Umbar Baharbel
    [312] = { HARADWAITH, H_UMBAR_BAHARBEL }; -- The Tale-wardens
    [323] = { HARADWAITH, H_MUR_GHALA };    -- The Kintai of Sul Madash
    [324] = { HARADWAITH, H_MUR_GHALA };    -- The Temamir of Jiret-menesh
    [325] = { HARADWAITH, H_MUR_GHALA };    -- The City of Zajana
    [331] = { HARADWAITH, H_MUR_GHALA };    -- Hamat Renewed
    [332] = { HARADWAITH, H_MUR_GHALA };    -- Hunter's Guild of Mur Ghala
};

-- encabezados nuevos de seccion (IDs altos, fuera de los del plugin)
local SECTION_INSTANCES_ID = 90001;
local SECTION_REPUTATION_ID = 90002;

local ZONE_PAGES = { ERIADOR, RHOVANION, GONDOR, MORDOR, HARADWAITH };

local function CategoryTier(catID)
    local cat = _DEED_CATEGORIES[catID];
    return (cat and cat.TIER) or 0;
end

local function ZoneKey(page, tab)
    return tostring(page) .. "/" .. tostring(tab);
end

-- Parte el contenido de una pestaña en grupos por zona. mapping[catID] =
-- {page, tab}; defaultZone = {page, tab} o nil. Devuelve lista de
-- { zone = key, items = {...} } en orden.
local function SplitByZone(contents, mapping, defaultZone)
    local groups = {};
    local current = nil;       -- grupo abierto
    local currentTier = 0;     -- tier del encabezado que lo abrio
    for _, item in ipairs(contents) do
        local catID = item.CAT_ID;
        if (catID) then
            local zone = mapping[catID];
            if (NOT_ACHIEVABLE[catID]) then
                current = nil;
            elseif (zone) then
                current = { zone = ZoneKey(zone[1], zone[2]), items = { item } };
                currentTier = CategoryTier(catID);
                table.insert(groups, current);
            elseif (current and CategoryTier(catID) > currentTier) then
                -- sub-instancia dentro de la instancia abierta (ej. Carn Dum
                -- dentro de "- Angmar -"): sigue en el mismo grupo
                table.insert(current.items, item);
            elseif (LEVEL_HEADERS[catID]) then
                -- encabezado de nivel: no es un lugar; cierra el grupo salvo
                -- en pestañas de una sola zona
                if (defaultZone) then
                    current = { zone = ZoneKey(defaultZone.PAGE, defaultZone.TAB), items = {} };
                    currentTier = -1;
                    table.insert(groups, current);
                else
                    current = nil;
                end
            elseif (defaultZone) then
                current = { zone = ZoneKey(defaultZone.PAGE, defaultZone.TAB), items = { item } };
                currentTier = CategoryTier(catID);
                table.insert(groups, current);
            else
                current = nil;
            end
        else
            if (current == nil and defaultZone) then
                -- hazañas generales de la expansion antes de la 1ra categoria
                current = { zone = ZoneKey(defaultZone.PAGE, defaultZone.TAB), items = {} };
                currentTier = -1;
                table.insert(groups, current);
            end
            if (current) then
                table.insert(current.items, item);
            end
        end
    end
    return groups;
end

local function BuildDeedsByZonePage()
    if (_DEED_LOG_PAGES[BY_ZONE] ~= nil) then
        return; -- ya armada (recarga del plugin)
    end

    -- 1) instancias y reputacion agrupadas por zona
    local instancesByZone = {};
    local reputationByZone = {};
    local function add(target, groups)
        for _, g in ipairs(groups) do
            if (#g.items > 0) then
                target[g.zone] = target[g.zone] or {};
                for _, it in ipairs(g.items) do
                    table.insert(target[g.zone], it);
                end
            end
        end
    end
    for tab = 1, #_DEED_LOG_PAGE_TAB_CONTENTS[INSTANCES] do
        add(instancesByZone, SplitByZone(_DEED_LOG_PAGE_TAB_CONTENTS[INSTANCES][tab],
            INSTANCE_CATEGORY_ZONE, INSTANCE_TAB_ZONE[tab]));
    end
    add(reputationByZone, SplitByZone(_DEED_LOG_PAGE_TAB_CONTENTS[CLASS_RACE_EPIC][CRE_REPUTATION],
        REPUTATION_CATEGORY_ZONE, nil));

    -- 2) secciones nuevas (categorias propias, sin tier)
    _DEED_CATEGORIES[SECTION_INSTANCES_ID] = { ["NAME"] = "== " .. Localized(SECTION_INSTANCES) .. " ==" };
    _DEED_CATEGORIES[SECTION_REPUTATION_ID] = { ["NAME"] = "== " .. Localized(SECTION_REPUTATION) .. " ==" };

    -- 3) la pagina: una pestaña por zona, en el orden de las paginas de zona
    local tabs = {};
    local contents = {};
    for _, page in ipairs(ZONE_PAGES) do
        for tab = 1, #_DEED_LOG_PAGE_TABS[page] do
            local originalKey = _DEED_LOG_PAGE_TABS[page][tab];
            local newKey = "BY_ZONE_" .. originalKey;
            _DEED_LOG_PAGE_TAB_NAMES[newKey] = _DEED_LOG_PAGE_TAB_NAMES[originalKey];

            local list = {};
            for _, it in ipairs(_DEED_LOG_PAGE_TAB_CONTENTS[page][tab]) do
                table.insert(list, it);
            end
            local key = ZoneKey(page, tab);
            if (instancesByZone[key]) then
                table.insert(list, { ["CAT_ID"] = SECTION_INSTANCES_ID; });
                for _, it in ipairs(instancesByZone[key]) do
                    table.insert(list, it);
                end
            end
            if (reputationByZone[key]) then
                table.insert(list, { ["CAT_ID"] = SECTION_REPUTATION_ID; });
                for _, it in ipairs(reputationByZone[key]) do
                    table.insert(list, it);
                end
            end

            table.insert(tabs, newKey);
            table.insert(contents, list);
        end
    end

    _DEED_LOG_PAGE_NAMES["BY_ZONE_STR"] = Localized(PAGE_NAME);
    _DEED_LOG_PAGES[BY_ZONE] = "BY_ZONE_STR";
    _DEED_LOG_PAGE_TABS[BY_ZONE] = tabs;
    _DEED_LOG_PAGE_TAB_CONTENTS[BY_ZONE] = contents;
end

BuildDeedsByZonePage();
