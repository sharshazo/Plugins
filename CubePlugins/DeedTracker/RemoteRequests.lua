-- CubePlugins/DeedTracker/RemoteRequests.lua
--
-- Pedidos desde el Mapa del Mundo (2026-09-26, pedido del jugador): la
-- ventana de hazañas de cada zona del mapa (WorldMap_Addon) no puede tocar
-- Deed Tracker directamente -- corren en "apartamentos" separados -- asi
-- que deja sus pedidos en un archivo de PluginData y Deed Tracker los
-- cumple aca, cada 1 segundo:
--
--   DeedTracker_MapRequests (personaje): { ops = { ["n"] = { op, id, done } } }
--     op = "set"  -> marca (done = 1) o desmarca (done = 0) la hazaña id,
--                    exactamente como si se hubiera tildado su casilla aca
--                    (misma cascada de sub-hazañas y mismo guardado)
--     op = "open" -> abre la ventana principal filtrada a esa hazaña y su
--                    descripcion en una ventanita aparte (la misma que sale
--                    al pasar el mouse, "despegada")
--   DeedTracker_MapAck (personaje): { last = n } -- ultimo pedido cumplido.
--
-- Pedidos hechos con Deed Tracker descargado quedan en el archivo y se
-- cumplen al cargarlo. Cualquier error queda contenido (pcall): nunca
-- rompe el resto del plugin.
--
-- 2026-09-27 (error real en el juego, llenaba el chat cada segundo):
-- Turbine.PluginData.Load SIN funcion de aviso solo se puede usar mientras
-- el plugin carga -- desde el temporizador el juego responde "The data
-- load event handler must be specified" y PatchDataLoad lo escribia en el
-- chat. Ahora las lecturas de aca son asincronicas (con funcion de aviso,
-- como el resto de los addons) y nunca escriben en el chat.

local REQUEST_KEY = "DeedTracker_MapRequests";
local ACK_KEY = "DeedTracker_MapAck";
local POLL_MS = 1000;

local LOAD_TIMEOUT = 10;   -- s: si el juego nunca avisa, se vuelve a pedir

local lastDone = nil;
local loading = false;
local loadingAt = 0;

-- lectura asincronica (el dato llega un instante despues, a callback);
-- mismo arreglo de VindarPatch que PatchDataLoad (convBack), sin chat
local function LoadAsync(key, callback)
    local answered = false;
    local ok = pcall(Turbine.PluginData.Load, Turbine.DataScope.Character, key, function(data)
        if (answered) then
            return;
        end
        answered = true;
        local okConv, res = pcall(convBack, data);
        if (not okConv) then
            res = nil;
        end
        local okCb, err = pcall(callback, res);
        if (not okCb) then
            Debug("Deed Tracker: error leyendo pedidos del mapa: " .. tostring(err));
        end
    end);
    if (not ok and not answered) then
        answered = true;
        pcall(callback, nil);
    end
end

local function AckNumber(ack)
    if (type(ack) == "table" and tonumber(ack.last) ~= nil) then
        return tonumber(ack.last);
    end
    return 0;
end

local function SetDeedFromMap(deed, wantDone)
    local me = MYCHAR:GetName();
    if (GetDeedComplete(me, deed.ID) == wantDone) then
        return false;
    end
    local mainWin = DeedTrackerWin.GetInstance();
    if (mainWin.selectedCharacter == me and deed["CHECK"] ~= nil and
        deed["CHECK_PAGE"] == mainWin.selectedTab) then
        -- la casilla esta dibujada: tildarla hace todo lo mismo que un clic
        deed["CHECK"]:SetChecked(wantDone);
    else
        SetDeedComplete(me, deed, wantDone);
        mainWin:UpdateProgress();
    end
    return true;
end

local function OpenDeedFromMap(deed)
    local mainWin = DeedTrackerWin.GetInstance();
    mainWin:SetVisible(true);
    SETTINGS.MAINWIN.VISIBLE = true;

    -- filtrar a esa hazaña, en su pagina original y con su pestaña abierta
    mainWin:SaveRegionExpandedStates();
    local character = mainWin.ddCharacter:GetText();
    mainWin:SetRegionExpanded(character, deed.i, deed.j, true);
    if (mainWin.searchTextBox ~= nil) then
        mainWin.searchTextBox:SetText(deed.NAME);
    end
    _CHARDATA[":SEARCH"] = deed.NAME;
    mainWin.selectedCharacter = character;
    _CHARDATA[character]["UI"]["SELECTED_TAB"] = deed.i;
    mainWin:SetUsedTab(deed.i);
    mainWin:RefreshDeedView(character);
    if (deed["CHECK"] ~= nil and deed["CHECK"].EnsureVisible ~= nil) then
        deed["CHECK"].EnsureVisible();
    end
    mainWin:Activate();

    -- descripcion en una ventanita aparte, al lado de la ventana principal
    local tooltip = DeedTooltipWindow.GetInstance();
    tooltip:LoadDeed(deed);
    tooltip:SetVisible(true);
    tooltip:DetachTooltip();
    local target = DeedTooltipWindow.detachedTooltips[deed.ID] or tooltip;
    local x = mainWin:GetLeft() + mainWin:GetWidth() + 6;
    if (x + target:GetWidth() > Turbine.UI.Display.GetWidth()) then
        x = mainWin:GetLeft() - target:GetWidth() - 6;
    end
    if (x < 0) then x = 0; end
    target:SetPosition(x, mainWin:GetTop());
    target:SetVisible(true);
    target:Activate();
end

local function HandleRequests(req)
    if (type(req) ~= "table" or type(req.ops) ~= "table") then
        return;
    end

    local pending = {};
    for key, op in pairs(req.ops) do
        local n = tonumber(key);
        if (n ~= nil and n > lastDone and type(op) == "table") then
            table.insert(pending, { n = n, op = op });
        end
    end
    if (#pending == 0) then
        return;
    end
    table.sort(pending, function(a, b) return a.n < b.n; end);

    local changed = false;
    for _, p in ipairs(pending) do
        local deed = DataFiles._DEED_DATA[tonumber(p.op.id)];
        if (deed ~= nil and not IsCategory(deed)) then
            if (p.op.op == "set") then
                local ok, didChange = pcall(SetDeedFromMap, deed, tonumber(p.op.done) == 1);
                if (not ok) then
                    Debug("Deed Tracker: pedido del mapa no aplicado: " .. tostring(didChange));
                elseif (didChange) then
                    changed = true;
                end
            elseif (p.op.op == "open") then
                local ok, err = pcall(OpenDeedFromMap, deed);
                if (not ok) then
                    Debug("Deed Tracker: no se pudo abrir la hazaña pedida por el mapa: " .. tostring(err));
                end
            end
        end
        lastDone = p.n;
    end

    if (changed) then
        -- guardar YA (no esperar los 5 s): el mapa lee este mismo archivo
        SaveCurrentCharacterData();
    end
    PatchDataSave(Turbine.DataScope.Character, ACK_KEY, { ["last"] = lastDone });
end

local function ProcessMapRequests()
    if (IsSessionPlay()) then
        return;
    end
    local now = Turbine.Engine.GetGameTime();
    if (loading and (now - loadingAt) < LOAD_TIMEOUT) then
        return;
    end
    loading = true;
    loadingAt = now;
    local function withRequests(req)
        loading = false;
        HandleRequests(req);
    end
    if (lastDone == nil) then
        LoadAsync(ACK_KEY, function(ack)
            if (lastDone == nil) then
                lastDone = AckNumber(ack);
            end
            LoadAsync(REQUEST_KEY, withRequests);
        end);
    else
        LoadAsync(REQUEST_KEY, withRequests);
    end
end

-- Comando /dtmapa (2026-09-27, pedido del jugador: "se demora mucho en
-- abrir Deed Tracker cuando clickeo una hazaña en el mapa"). El pedido por
-- archivo tarda (sondeo cada 1 s + lectura asincronica del archivo); el mapa
-- ahora pone sobre el nombre de la hazaña un atajo invisible (Quickslot con
-- alias "/dtmapa abrir <id>") que el juego ejecuta EN EL ACTO al hacer clic.
--   /dtmapa abrir <id>  -> igual que el pedido "open" del archivo
local function FindMapDeed(id)
    local deed = DataFiles._DEED_DATA[tonumber(id)];
    if (deed ~= nil and not IsCategory(deed)) then
        return deed;
    end
    return nil;
end

MapCommand = Turbine.ShellCommand();

function MapCommand:Execute(command, arguments)
    local ok, err = pcall(function()
        local verb, id = string.match(tostring(arguments or ""), "^%s*(%a+)%s+(%d+)");
        if (verb == "abrir" or verb == "open") then
            local deed = FindMapDeed(id);
            if (deed ~= nil) then
                OpenDeedFromMap(deed);
            end
        end
    end);
    if (not ok) then
        Debug("Deed Tracker: /dtmapa: " .. tostring(err));
    end
end

function MapCommand:GetHelp()
    return "/dtmapa abrir <id>: abre Deed Tracker en esa haza\195\177a (lo usa el Mapa del Mundo).";
end

function MapCommand:GetShortHelp()
    return "Abre una haza\195\177a pedida por el Mapa del Mundo.";
end

function StartMapRequests()
    pcall(Turbine.Shell.AddCommand, "dtmapa", MapCommand);
    MapRequestsTimer = Timer(POLL_MS, true, function()
        local ok, err = pcall(ProcessMapRequests);
        if (not ok) then
            Debug("Deed Tracker: error leyendo pedidos del mapa: " .. tostring(err));
        end
    end);
    MapRequestsTimer:Start();
end
