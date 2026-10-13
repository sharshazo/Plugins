DeedTooltipWindow = class(Turbine.UI.Window);
DeedTooltipWindow.instance = nil;

-- List of detached deed tooltips that haven't been closed:
DeedTooltipWindow.detachedTooltips = {};

function DeedTooltipWindow.GetInstance()
    if (DeedTooltipWindow.instance ~= nil) then
        return DeedTooltipWindow.instance;
    end
    return DeedTooltipWindow();
end

function DeedTooltipWindow:Constructor()
    -- Enforce only one such window:
    if (DeedTooltipWindow.instance) then
        return;
    end
    Turbine.UI.Window.Constructor(self);
    DeedTooltipWindow.instance = self;

    self.borderWidth = 6;
    self.maxWindowWidth = 380;
    self.maxWindowHeight = 500;
    self.maxContentWidth = self.maxWindowWidth - (self.borderWidth * 2);
    self.maxContentHeight = self.maxWindowHeight - (self.borderWidth * 2);

    self:SetZOrder(0x7FFFFFFF); -- Most on-top we can get
    -- v2 (pedido del jugador): "tarjeta moderna" como el Mapa del Mundo:
    -- fondo oscuro con esquinas redondeadas (piezas de imagen) y la ventana
    -- transparente.
    self:SetBackColor(Turbine.UI.Color(0, 0, 0, 0));
    self.cardFrame = DTCardFrame(self);
    self:SetWantsKeyEvents(true);
    self.actionDetachTooltip = 0x1000001A;
    self.isDetached = false;
    -- (v3: sin SetOpacity: en el juego deja invisible el fondo de la tarjeta)

    -- Create simple border:
    self.border = Turbine.UI.Control();
    self.border:SetParent(self);
    -- (v4) mismo fondo que la tarjeta: un color 100% transparente aqui
    -- "borraba" el fondo de la tarjeta en el juego (se veia todo detras)
    self.border:SetBackColor(DT_CARD.BG);
    self.border:SetMouseVisible(false);
    self.border:SetPosition(self.borderWidth, self.borderWidth);

    -- Create close button:
    self.closeButton = Turbine.UI.Control();
    self.closeButton:SetParent(self);
    self.closeButton:SetBackground(_IMAGES.DETACHED_TOOLTIP_CLOSE_NORMAL);
    self.closeButton:SetSize(16, 16);
    self.closeButton:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend);
    self.closeButton.MouseClick = function()
        DeedTooltipWindow.detachedTooltips[self.ID] = nil;
        self:Close();
    end
    self.closeButton.MouseEnter = function()
        self.closeButton:SetBackground(_IMAGES.DETACHED_TOOLTIP_CLOSE_ROLLOVER);
    end
    self.closeButton.MouseDown = function()
        self.closeButton:SetBackground(_IMAGES.DETACHED_TOOLTIP_CLOSE_PRESSED);
    end
    self.closeButton.MouseUp = function()
        self.closeButton:SetBackground(_IMAGES.DETACHED_TOOLTIP_CLOSE_ROLLOVER);
    end
    self.closeButton.MouseLeave = function()
        self.closeButton:SetBackground(_IMAGES.DETACHED_TOOLTIP_CLOSE_NORMAL);
    end
    self.closeButton:SetZOrder(0x7FFFFFFF); -- Most on-top we can get
    self.closeButton:SetVisible(false);

    -- Make the listbox for scrolling:
    self.listbox = Turbine.UI.ListBox();
    self.listbox:SetParent(self);
    self.listbox:SetPosition(self.borderWidth, self.borderWidth);
    self.listbox:SetSize(self.maxContentWidth, self.maxContentHeight);
    -- Pass mouse events through to support moving the tooltip via drag & drop
    self.listbox.MouseDown = function(sender, args)
        self:MouseDown(args);
    end
    self.listbox.MouseMove = function(sender, args)
        self:MouseMove(args);
    end
    self.listbox.MouseUp = function(sender, args)
        self:MouseUp(args);
    end

    -- Make the scrollbar for the listbox:
    self.scrollbar = Turbine.UI.Lotro.ScrollBar();
    self.scrollbar:SetParent(self.listbox);
    self.scrollbar:SetOrientation(Turbine.UI.Orientation.Vertical);
    self.scrollbar:SetZOrder(0x7FFFFFFF);
    self.scrollbar:SetVisible(true);
    self.listbox:SetVerticalScrollBar(self.scrollbar);

end

function DeedTooltipWindow:KeyDown(sender, args)
    if (self:IsVisible() and
        sender.Action == self.actionDetachTooltip) then
        self:DetachTooltip();
    end
end

-- support moving the tooltip:

function DeedTooltipWindow:MouseDown(args)
    if (not self.isDetached) then
        return;
    end

    self:Activate();
    if (args.Button == Turbine.UI.MouseButton.Left) then
        local startLeft, startTop = self:GetPosition();
        local startX, startY = Turbine.UI.Display:GetMousePosition();
        self.mouseDown = { startX, startY };
        self.mouseDownOffset = { startX - startLeft, startY - startTop };
        self.hasMoved = false;
    end
end

function DeedTooltipWindow:MouseMove(args)
    if (not self.isDetached) then
        return;
    end

    if (self.mouseDown) then
        local startX, startY = unpack(self.mouseDown);
        local currentX, currentY = Turbine.UI.Display.GetMousePosition();

        local deltaX = currentX - startX;
        local deltaY = currentY - startY;

        if (self.hasMoved or
            (math.abs(deltaX) > 5 or math.abs(deltaY) > 5)) then
            -- we've moved enough
            self.hasMoved = true;
            local offsetX, offsetY = unpack(self.mouseDownOffset);
            self:SetPosition(startX + deltaX - offsetX, startY + deltaY - offsetY);
        end
    end
end

function DeedTooltipWindow:MouseUp(args)
    if (not self.isDetached) then
        return;
    end

    if (self.mouseDown) then
        if (self.hasMoved) then
            Onscreen(self);
        end
        self.mouseDown = nil;
    end
end

-- end moving tooltip

function DeedTooltipWindow:LoadDeed(deed)
    -- Get rid of any existing controls:
    self.listbox:ClearItems();
    if (self.deedControl ~= nil) then
        self.deedControl:SetParent(nil);
        self.deedControl = nil;
    end

    self.ID = deed.ID;

    -- Add the current deed control:
    local okCard, card = pcall(GetDeedCardControl, deed, self.maxContentWidth, true);
    if (okCard and card ~= nil) then
        self.deedControl = card;
        self.cardFrame.accent:SetBackColor(card.accentColor or DT_CARD.ACCENT_DEF);
    else
        self.deedControl = GetDeedInformationControl(deed, self.maxContentWidth, true);
        self.cardFrame.accent:SetBackColor(DT_CARD.ACCENT_DEF);
    end
    self.deedControl:SetParent(self.listbox);
    self.listbox:AddItem(self.deedControl);

    -- Adjust the size of everything:
    self:SetWidth(self.maxWindowWidth);
    self.scrollbar:SetPosition(self.listbox:GetLeft() + self.listbox:GetWidth() - 14, self.listbox:GetTop() + 20);
    self.scrollbar:SetSize(8, self.listbox:GetHeight() - 25);

    local height = self.deedControl:GetHeight();
    if (height > self.maxContentHeight) then
        height = self.maxContentHeight;
        self:SetHeight(self.maxWindowHeight);
    else
        self:SetHeight(height + (self.borderWidth * 2));
    end

    self.closeButton:SetPosition(self:GetWidth() - self.closeButton:GetWidth() - 2, 2);
    self.border:SetSize(self:GetWidth() - self.borderWidth * 2, self:GetHeight() - self.borderWidth * 2);
    DTLayoutCardFrame(self.cardFrame, self:GetWidth(), self:GetHeight());
end

function DeedTooltipWindow:DisplayTooltip(windowLeft, windowTop, mouseX, mouseY)
    self:SetPosition(windowLeft + mouseX + 25, windowTop + mouseY + 25);
    self:SetVisible(true);
end

function DeedTooltipWindow:HideTooltip()
    if (not self.isDetached) then
        self:SetVisible(false);
    end
end

function DeedTooltipWindow:DetachTooltip()
    -- Check if this deed is already detached.
    if (self.ID ~= nil and
        DeedTooltipWindow.detachedTooltips[self.ID] ~= nil) then
    --   If it is, bring its window to the top and hide the "tooltip" version.
        DeedTooltipWindow.detachedTooltips[self.ID]:Activate();
        self:HideTooltip();
        return;
    end

    -- Otherwise,
    -- Add to list of detached windows
    self.isDetached = true;
    DeedTooltipWindow.detachedTooltips[self.ID] = self;
    -- Show the Close button:
    self.closeButton:SetVisible(true);
    -- We're not the "tooltip" window anymore:
    DeedTooltipWindow.instance = nil;
    -- Move under the mouse for easy grabbing /
    -- letting the user know something happened
    local mouseX, mouseY = self:GetMousePosition();
    self:SetPosition(self:GetLeft() + mouseX - 25, self:GetTop() + mouseY - 25);
end

-- =====================================================================
-- v2 (2026-10-13, pedido del jugador): tarjeta moderna, igual que los
-- carteles del Mapa del Mundo y de QuestSync. Mismos datos que el cartel
-- original (nombre, tipo, nivel, saber, recompensas, titulo, objetivos con
-- coordenadas y boton de Waypoint); solo cambia como se ve. Si algo falla,
-- DeedTooltipWindow usa el cartel original (GetDeedInformationControl).
-- =====================================================================
local CARD_RES = "CubePlugins/DeedTracker/Resources/Card/";
DT_CARD = {
    R = 12,
    BG = Turbine.UI.Color(1, 16/255, 18/255, 24/255),
    BORDER = Turbine.UI.Color(1, 60/255, 66/255, 80/255),
    ACCENT_DEF = Turbine.UI.Color(1, 150/255, 160/255, 180/255),
};
local TYPE_INFO = {
    [100] = { "Clase", "fl_hazana_32.tga", { 240, 200, 110 } },
    [101] = { "Raza", "fl_hazana_32.tga", { 90, 200, 170 } },
    [102] = { "Evento", "fl_hazana_32.tga", { 240, 150, 70 } },
    [103] = { "Explorador", "fl_exploracion_32.tga", { 80, 170, 255 } },
    [104] = { "Saber", "fl_historia_32.tga", { 190, 120, 255 } },
    [105] = { "Reputaci\195\179n", "fl_hazana_32.tga", { 120, 200, 140 } },
    [106] = { "Matanza", "fl_mobs_32.tga", { 235, 95, 80 } },
};
local ES = (LANGUAGE == nil or LANGUAGE == "ES");
local TX = ES and {
    lvl = "Nivel ", done = "Completada", na = "No activa", vxp = " XP virtud", rep = "reputaci\195\179n",
    title = "T\195\173tulo: ", obj = "OBJETIVOS",
} or {
    lvl = "Level ", done = "Completed", na = "Not active", vxp = " virtue XP", rep = "reputation",
    title = "Title: ", obj = "OBJECTIVES",
};
local TYPE_EN = { [100] = "Class", [101] = "Race", [102] = "Event", [103] = "Explorer", [104] = "Lore", [105] = "Reputation", [106] = "Slayer" };
local function C(r, g, b, a) return Turbine.UI.Color(a or 1, r / 255, g / 255, b / 255); end
local function CardFont(name, fallback)
    local F = Turbine.UI.Lotro.Font;
    return F[name] or F[fallback] or F.Verdana12;
end
local function TextW(text, px)
    local n = 0;
    for _ in tostring(text or ""):gmatch("[^\128-\191]") do n = n + 1; end
    return math.floor(n * (px or 6.6) + 0.5);
end
local function Thousands(n)
    local s = tostring(math.floor(tonumber(n) or 0));
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse();
    return (out:gsub("^%.", ""));
end

-- marco de la ventana: esquinas + relleno + borde + barra de color
function DTCardFrame(win)
    local f = {};
    local function box(color)
        local k = Turbine.UI.Control();
        k:SetParent(win);
        k:SetMouseVisible(false);
        k:SetBackColor(color);
        return k;
    end
    local function img(file)
        local k = Turbine.UI.Control();
        k:SetParent(win);
        k:SetSize(DT_CARD.R, DT_CARD.R);
        k:SetBackground(CARD_RES .. file);
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend);
        k:SetMouseVisible(false);
        return k;
    end
    f.tl, f.tr, f.bl, f.br = img("card_tl.tga"), img("card_tr.tga"), img("card_bl.tga"), img("card_br.tga");
    f.top, f.mid, f.bot = box(DT_CARD.BG), box(DT_CARD.BG), box(DT_CARD.BG);
    f.lineT, f.lineB, f.lineL, f.lineR = box(DT_CARD.BORDER), box(DT_CARD.BORDER), box(DT_CARD.BORDER), box(DT_CARD.BORDER);
    f.accent = box(DT_CARD.ACCENT_DEF);
    return f;
end

function DTLayoutCardFrame(f, W, H)
    local R = DT_CARD.R;
    if (H < 2 * R + 4) then H = 2 * R + 4; end
    f.tl:SetPosition(0, 0); f.tr:SetPosition(W - R, 0);
    f.bl:SetPosition(0, H - R); f.br:SetPosition(W - R, H - R);
    f.top:SetPosition(R, 0); f.top:SetSize(W - 2 * R, R);
    f.mid:SetPosition(0, R); f.mid:SetSize(W, H - 2 * R);
    f.bot:SetPosition(R, H - R); f.bot:SetSize(W - 2 * R, R);
    f.lineT:SetPosition(R, 0); f.lineT:SetSize(W - 2 * R, 1);
    f.lineB:SetPosition(R, H - 1); f.lineB:SetSize(W - 2 * R, 1);
    f.lineL:SetPosition(0, R); f.lineL:SetSize(1, H - 2 * R);
    f.lineR:SetPosition(W - 1, R); f.lineR:SetSize(1, H - 2 * R);
    f.accent:SetPosition(1, R); f.accent:SetSize(4, H - 2 * R);
end

-- contenido de la tarjeta (lo que va dentro de la lista del cartel)
function GetDeedCardControl(deed, width, includeObjectives)
    local card = Turbine.UI.Control();
    card:SetWidth(width);
    card:SetMouseVisible(false);
    local info = TYPE_INFO[deed.TYPE] or { nil, "fl_hazana_32.tga", { 150, 160, 180 } };
    local accent = info[3];
    card.accentColor = C(accent[1], accent[2], accent[3]);
    local PAD = 12;
    local inner = width - PAD - 14;
    local function label(font, color, x, y, w, h, text, multi, align)
        local l = Turbine.UI.Label();
        l:SetParent(card);
        l:SetFont(font);
        l:SetForeColor(color);
        l:SetTextAlignment(align or Turbine.UI.ContentAlignment.TopLeft);
        l:SetMultiline(multi == true);
        l:SetMouseVisible(false);
        l:SetPosition(x, y);
        l:SetSize(w, h);
        l:SetText(text or "");
        return l;
    end
    local function img(file, x, y, w, h)
        local k = Turbine.UI.Control();
        k:SetParent(card);
        k:SetPosition(x, y);
        k:SetSize(w, h);
        k:SetBackground(CARD_RES .. file);
        k:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend);
        k:SetMouseVisible(false);
        return k;
    end
    local function box(x, y, w, h, color)
        local k = Turbine.UI.Control();
        k:SetParent(card);
        k:SetPosition(x, y);
        k:SetSize(w, h);
        k:SetBackColor(color);
        k:SetMouseVisible(false);
        return k;
    end
    local V12 = Turbine.UI.Lotro.Font.Verdana12;
    local V10 = CardFont("Verdana10", "Verdana12");
    -- cabecera: icono, nombre, tipo y nivel
    img(info[2], 8, 6, 32, 32);
    local titleX = 48;
    local titleW = width - titleX - 12;
    local title = label(CardFont("Verdana16", "Verdana14"), C(245, 248, 255), titleX, 6, titleW, 20, deed.NAME or "", true);
    local th = AutoFitLabelHeight(title, 60);
    local y = 6 + th + 1;
    local sub = (ES and info[1] or TYPE_EN[deed.TYPE]) or "";
    if (deed.MIN_LVL ~= nil and deed.MIN_LVL > 0) then
        sub = sub .. ((sub ~= "") and "  \194\183  " or "") .. TX.lvl .. deed.MIN_LVL;
    end
    if (sub ~= "") then
        label(V12, C(140, 170, 210), titleX, y, titleW, 16, sub);
        y = y + 18;
    end
    y = math.max(y, 44) + 6;
    -- etiquetas: completada / no activa
    local pills = {};
    local okC, done = pcall(function()
        return GetDeedComplete(DeedTrackerWin.GetInstance():GetUiCharacter(), deed.ID);
    end);
    if (okC and done) then
        pills[#pills + 1] = { TX.done, "green", C(140, 240, 170), C(22, 70, 40) };
    end
    if (deed.NA ~= nil) then
        local reason = DataFiles._NOT_ACTIVE_REASON and DataFiles._NOT_ACTIVE_REASON[deed.NA] or nil;
        pills[#pills + 1] = { TX.na .. (reason and (": " .. reason) or ""), "amber", C(255, 200, 90), C(90, 60, 10) };
    end
    local px = PAD;
    for _, d in ipairs(pills) do
        local w = TextW(d[1], 6.2) + 8;
        if (px + w + 18 <= PAD + inner) then
            img("card_" .. d[2] .. "_l.tga", px, y, 9, 18);
            box(px + 9, y, w, 18, d[4]);
            img("card_" .. d[2] .. "_r.tga", px + 9 + w, y, 9, 18);
            label(V10, d[3], px + 9, y, w, 18, d[1], false, Turbine.UI.ContentAlignment.MiddleCenter);
            px = px + w + 24;
        end
    end
    if (#pills > 0) then y = y + 26; end
    -- saber de la hazaña
    local showObjectives = (includeObjectives and SETTINGS.OBJECTIVES_SHOW_FULL_OBJECTIVES) and true or false;
    if (not showObjectives and deed.SUMMARY ~= nil and deed.SUMMARY ~= "" and deed.SUMMARY ~= deed.LORE) then
        local su = label(V12, C(160, 200, 255), PAD, y, inner, 20, deed.SUMMARY, true);
        y = y + AutoFitLabelHeight(su, 200) + 6;
    end
    local loreText = deed.LORE;
    if ((loreText == nil or loreText == "") and showObjectives) then loreText = deed.SUMMARY; end
    if (loreText ~= nil and loreText ~= "") then
        local lore = label(V12, C(190, 196, 210), PAD, y, inner, 20, loreText, true);
        y = y + AutoFitLabelHeight(lore, 1000) + 8;
    end
    -- recompensas con su icono
    local chips = {};
    if ((deed.VXP or 0) > 0) then chips[#chips + 1] = { "card_vxp.tga", Thousands(deed.VXP) .. TX.vxp, C(150, 220, 255) }; end
    if ((deed.LP or 0) > 0) then chips[#chips + 1] = { "card_lp.tga", deed.LP .. " LOTRO", C(255, 215, 90) }; end
    if ((deed.REP or 0) > 0) then
        local fac = DataFiles._FACTIONS and DataFiles._FACTIONS[deed.FACTION] or TX.rep;
        chips[#chips + 1] = { "card_rep.tga", "+" .. Thousands(deed.REP) .. " " .. fac, C(160, 220, 170) };
    end
    local cx = PAD;
    for _, ch in ipairs(chips) do
        local w = TextW(ch[2], 6.2) + 28;
        if (cx > PAD and cx + w + 24 > PAD + inner) then
            cx = PAD;
            y = y + 30;
        end
        img("card_chip_l.tga", cx, y, 12, 24);
        box(cx + 12, y, w, 24, C(30, 34, 44));
        img("card_chip_r.tga", cx + 12 + w, y, 12, 24);
        img(ch[1], cx + 5, y + 3, 18, 18);
        label(V10, ch[3], cx + 27, y, w - 15, 24, ch[2], false, Turbine.UI.ContentAlignment.MiddleLeft);
        cx = cx + w + 30;
    end
    if (#chips > 0) then y = y + 30; end
    if (deed.TITLE ~= nil and deed.TITLE ~= "") then
        local t = label(V12, C(230, 200, 120), PAD, y, inner, 16, TX.title .. deed.TITLE, true);
        y = y + AutoFitLabelHeight(t, 60) + 4;
    end
    -- objetivos (con su lugar, coordenadas y boton de Waypoint)
    local objectives = (includeObjectives and SETTINGS.OBJECTIVES_SHOW_FULL_OBJECTIVES and deed.ID ~= nil and DataFiles._OBJECTIVES) and DataFiles._OBJECTIVES[deed.ID] or nil;
    if (objectives ~= nil) then
        local count = 0;
        for i = 1, table.maxn(objectives) do if (objectives[i] ~= nil) then count = count + 1; end end
        if (count > 0) then
            y = y + 4;
            box(PAD, y, inner, 1, C(45, 50, 62));
            y = y + 7;
            label(V10, C(140, 150, 170), PAD, y, inner, 14, TX.obj .. " (" .. count .. ")");
            y = y + 18;
            for i = 1, table.maxn(objectives) do
                local o = objectives[i];
                if (o ~= nil) then
                    if (o.POINTS ~= nil) then
                        local name = o.PROGRESS or o.NAME or "";
                        local points = table.maxn(o.POINTS);
                        local textX = PAD + 12;
                        if (WAYPOINT_AVAILABLE and points == 1) then
                            pcall(MakeWaypointControl, card, o.POINTS[1], PAD - 2, y + 1);
                            textX = PAD + 18;
                        else
                            box(PAD + 2, y + 6, 5, 5, C(accent[1], accent[2], accent[3]));
                        end
                        local coords = "";
                        if (SETTINGS.OBJECTIVES_SHOW_COORDINATES and points == 1) then
                            coords = "  (" .. o.POINTS[1].LAT .. ", " .. o.POINTS[1].LONG .. ")";
                        end
                        local l = label(V12, C(240, 208, 96), textX, y, PAD + inner - textX, 16, name .. coords, true);
                        y = y + AutoFitLabelHeight(l, 200);
                        if (o.LORE ~= nil and o.LORE ~= "") then
                            local lo = label(V10, C(168, 176, 192), textX, y, PAD + inner - textX, 14, o.LORE, true);
                            y = y + AutoFitLabelHeight(lo, 1000);
                        end
                        if (points > 1) then
                            for pi = 1, points do
                                local pt = o.POINTS[pi];
                                if (pt ~= nil) then
                                    if (WAYPOINT_AVAILABLE) then
                                        pcall(MakeWaypointControl, card, pt, textX - 2, y + 1);
                                    end
                                    label(V10, C(255, 236, 160), textX + 18, y, PAD + inner - textX - 18, 16, pi .. ": " .. pt.LAT .. ", " .. pt.LONG);
                                    y = y + 17;
                                end
                            end
                        end
                        y = y + 6;
                    else
                        local text = o[1] or o.NAME or "";
                        if (type(text) == "string" and text ~= "") then
                            box(PAD + 2, y + 6, 5, 5, C(accent[1], accent[2], accent[3]));
                            local l = label(V12, C(200, 206, 218), PAD + 12, y, inner - 12, 16, text, true);
                            y = y + AutoFitLabelHeight(l, 1000) + 4;
                        end
                    end
                end
            end
        end
    end
    card:SetHeight(y + 6);
    return card;
end
