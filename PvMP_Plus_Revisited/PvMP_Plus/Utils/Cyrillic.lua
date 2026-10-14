_G._CyrillicEnabled = false;

function _G.SetCyrillicEnabled(enabled)
    _G._CyrillicEnabled = enabled;
end

function _G.CyrillicIsEnabled()
    return _G._CyrillicEnabled;
end

-- TrajanPro and TrajanProBold don't support Cyrillic characters, so we substitute Verdana
-- of smaller or equal height.
local function ChangeFontForCyrillic(font)
    local fontMap = {
        [Turbine.UI.Lotro.Font.TrajanPro13] = Turbine.UI.Lotro.Font.Verdana12;
        [Turbine.UI.Lotro.Font.TrajanPro14] = Turbine.UI.Lotro.Font.Verdana14;
        [Turbine.UI.Lotro.Font.TrajanPro15] = Turbine.UI.Lotro.Font.Verdana14;
        [Turbine.UI.Lotro.Font.TrajanPro16] = Turbine.UI.Lotro.Font.Verdana16;
        [Turbine.UI.Lotro.Font.TrajanPro18] = Turbine.UI.Lotro.Font.Verdana18;
        [Turbine.UI.Lotro.Font.TrajanPro19] = Turbine.UI.Lotro.Font.Verdana18;
        [Turbine.UI.Lotro.Font.TrajanPro20] = Turbine.UI.Lotro.Font.Verdana20;
        [Turbine.UI.Lotro.Font.TrajanPro21] = Turbine.UI.Lotro.Font.Verdana20;
        [Turbine.UI.Lotro.Font.TrajanPro23] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanPro24] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanPro25] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanPro26] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanPro28] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanProBold16] = Turbine.UI.Lotro.Font.Verdana16;
        [Turbine.UI.Lotro.Font.TrajanProBold22] = Turbine.UI.Lotro.Font.Verdana20;
        [Turbine.UI.Lotro.Font.TrajanProBold24] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanProBold25] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanProBold30] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.TrajanProBold36] = Turbine.UI.Lotro.Font.Verdana23;
        [Turbine.UI.Lotro.Font.LucidaConsole12] = Turbine.UI.Lotro.Font.Verdana12;
    };
    return fontMap[font] or font;
end

-- Returns a string of spaces which can be put in a window's title with
-- SetText(), and whose width (in TrajanPro18) will exceed the width of
-- the specified Cyrillic string (in Verdana14).
local function GetTitleSpaces(cyrillicText)
    local label = Turbine.UI.Label();
    label:SetFont(Turbine.UI.Lotro.Font.Verdana14);
    label:SetText(cyrillicText);
    local spaces = math.ceil((label:GetWidth() - 17) / 6);
    return string.rep(" ", spaces);
end

-- Create derived classes for basic controls and windows
Turbine.UI._Button = Turbine.UI.Button;
Turbine.UI._CheckBox = Turbine.UI.CheckBox;
Turbine.UI._Label = Turbine.UI.Label;
Turbine.UI._TextBox = Turbine.UI.TextBox;
Turbine.UI._Window = Turbine.UI.Window;
Turbine.UI.Lotro._Button = Turbine.UI.Lotro.Button;
Turbine.UI.Lotro._CheckBox = Turbine.UI.Lotro.CheckBox;
Turbine.UI.Lotro._GoldButton = Turbine.UI.Lotro.GoldButton;
Turbine.UI.Lotro._GoldWindow = Turbine.UI.Lotro.GoldWindow;
Turbine.UI.Lotro._TextBox = Turbine.UI.Lotro.TextBox;
Turbine.UI.Lotro._Window = Turbine.UI.Lotro.Window;

Turbine.UI.Button = class(Turbine.UI._Button);
Turbine.UI.CheckBox = class(Turbine.UI._CheckBox);
Turbine.UI.Label = class(Turbine.UI._Label);
Turbine.UI.TextBox = class(Turbine.UI._TextBox);
Turbine.UI.Window = class(Turbine.UI._Window);
Turbine.UI.Lotro.Button = class(Turbine.UI.Lotro._Button);
Turbine.UI.Lotro.CheckBox = class(Turbine.UI.Lotro._CheckBox);
Turbine.UI.Lotro.GoldButton = class(Turbine.UI.Lotro._GoldButton);
Turbine.UI.Lotro.GoldWindow = class(Turbine.UI.Lotro._GoldWindow);
Turbine.UI.Lotro.TextBox = class(Turbine.UI.Lotro._TextBox);
Turbine.UI.Lotro.Window = class(Turbine.UI.Lotro._Window);

Turbine.UI.Button._baseClass = Turbine.UI._Button;
Turbine.UI.CheckBox._baseClass = Turbine.UI._CheckBox;
Turbine.UI.Label._baseClass = Turbine.UI._Label;
Turbine.UI.TextBox._baseClass = Turbine.UI._TextBox;
Turbine.UI.Window._baseClass = Turbine.UI._Window;
Turbine.UI.Lotro.Button._baseClass = Turbine.UI.Lotro._Button;
Turbine.UI.Lotro.CheckBox._baseClass = Turbine.UI.Lotro._CheckBox;
Turbine.UI.Lotro.GoldButton._baseClass = Turbine.UI.Lotro._GoldButton;
Turbine.UI.Lotro.GoldWindow._baseClass = Turbine.UI.Lotro._GoldWindow;
Turbine.UI.Lotro.TextBox._baseClass = Turbine.UI.Lotro._TextBox;
Turbine.UI.Lotro.Window._baseClass = Turbine.UI.Lotro._Window;

-- Change font handling for controls
for controlClass, defaultFont in pairs({
    [Turbine.UI.Button] = Turbine.UI.Lotro.Font.TrajanPro14;
    [Turbine.UI.CheckBox] = Turbine.UI.Lotro.Font.LucidaConsole12;
    [Turbine.UI.Label] = Turbine.UI.Lotro.Font.LucidaConsole12;
    [Turbine.UI.TextBox] = Turbine.UI.Lotro.Font.LucidaConsole12;
    [Turbine.UI.Lotro.Button] = Turbine.UI.Lotro.Font.TrajanPro14;
    [Turbine.UI.Lotro.CheckBox] = Turbine.UI.Lotro.Font.LucidaConsole12;
    [Turbine.UI.Lotro.GoldButton] = Turbine.UI.Lotro.Font.TrajanPro14;
    [Turbine.UI.Lotro.TextBox] = Turbine.UI.Lotro.Font.Verdana20;
}) do
    -- Change default font for the class
    function controlClass:Constructor()
        controlClass._baseClass.Constructor(self);
        self._nonCyrillicFont = defaultFont;
    end

    function controlClass:SetText(text)
        local font = self._nonCyrillicFont;
        if ((type(text) == "string") and CyrillicIsEnabled() and text:match("[А-Яа-я]")) then
            font = ChangeFontForCyrillic(self._nonCyrillicFont);
        end
        controlClass._baseClass.SetFont(self, font);
        controlClass._baseClass.SetText(self, text);
    end

    -- Convert SetFont() font to Verdana, if needed
    function controlClass:SetFont(font)
        self._nonCyrillicFont = font;
        controlClass._baseClass.SetText(self, self:GetText());
    end
end

-- Allow window titles to display Cyrillic for Lotro.Window and Lotro.GoldWindow.
for _, windowClass in pairs({ Turbine.UI.Window, Turbine.UI.Lotro.Window, Turbine.UI.Lotro.GoldWindow }) do
    function windowClass:Constructor()
        windowClass._baseClass.Constructor(self);

        -- Superimpose Verdana text on it.
        self._CyrillicTitle = Turbine.UI.Label();
        self._CyrillicTitle:SetParent(self);
        self._CyrillicTitle:SetSize(self:GetWidth(), 32);
        self._CyrillicTitle:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
        self._CyrillicTitle:SetFont(Turbine.UI.Lotro.Font.Verdana14);
        self._CyrillicTitle:SetFontStyle(Turbine.UI.FontStyle.Outline);
        self._CyrillicTitle:SetForeColor(Turbine.UI.Color.PaleGoldenrod);
        self._CyrillicTitle:SetOutlineColor(Turbine.UI.Color.Black);
        self._CyrillicTitle:SetMouseVisible(false);
    end

    function windowClass:SetWidth(width)
        windowClass._baseClass.SetWidth(self, width);
        self._CyrillicTitle:SetWidth(width);
    end

    function windowClass:SetSize(width, height)
        windowClass._baseClass.SetSize(self, width, height);
        self._CyrillicTitle:SetWidth(width);
    end

    function windowClass:SetText(text)
        if (CyrillicIsEnabled()) then
            windowClass._baseClass.SetText(self, GetTitleSpaces(text));
            self._CyrillicTitle:SetText(text);
        else
            windowClass._baseClass.SetText(self, text);
            self._CyrillicTitle:SetText(nil);
        end
    end

    function windowClass:GetText()
        if (CyrillicIsEnabled()) then
            return self._CyrillicTitle:GetText();
        else
            return windowClass._baseClass.GetText(self);
        end
    end

    -- Prevent GetControls():Clear() from clearing the window title.
    function windowClass:GetControls()
        local controlList = windowClass._baseClass.GetControls(self);
        controlList.Clear = function(cl)
            Turbine.UI.ControlList.Clear(cl);
            self._CyrillicTitle:SetParent(self);
        end
        return controlList;
    end
end