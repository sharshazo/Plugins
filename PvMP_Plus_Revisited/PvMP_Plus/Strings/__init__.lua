Turbine.Language.Russian = 268435463

-- v4.3.2-es: deteccion de ruso protegida (antes podia fallar si el
-- personaje aun no tenia habilidades cargadas y el plugin no arrancaba).
Turbine.Engine._GetLanguage = Turbine.Engine._GetLanguage or Turbine.Engine.GetLanguage
function Turbine.Engine.GetLanguage()
    local language = Turbine.Engine._GetLanguage()
    local ok, isRussian = pcall(function()
        local russianAlphabet = "АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя"
        local skills = Turbine.Gameplay.LocalPlayer:GetInstance():GetTrainedSkills()
        if skills == nil or skills:GetCount() < 1 then
            return false
        end
        local skillName = skills:GetItem(1):GetSkillInfo():GetName()
        return russianAlphabet:match(skillName:sub(1, 2)) ~= nil
    end)
    if ok and isRussian then
        return Turbine.Language.Russian
    end
    return language
end

_G.locale = nil
if Turbine.Engine:GetLanguage() == Turbine.Language.English or Turbine.Engine:GetLanguage() == Turbine.Language.EnglishGB then
    _G.locale = "en"
elseif Turbine.Engine:GetLanguage() == Turbine.Language.German then
	_G.locale = "de"
elseif Turbine.Engine:GetLanguage() == Turbine.Language.French then
	_G.locale = "fr"
elseif Turbine.Engine:GetLanguage() == Turbine.Language.Russian then
	_G.locale = "ru"
    SetCyrillicEnabled(true)
end
if _G.locale == nil then
    _G.locale = "en"
end

-- Idioma de la interfaz en el cliente ingles: Espanol (por defecto) o English.
-- Se guarda para toda la cuenta. Los textos del juego (chat, mejoras,
-- fortalezas) siguen en ingles porque el juego los envia asi.
_G.PvMP_Language_Key = "PvMP_Plus_Language"
_G.PvMP_Language_Switchable = (_G.locale == "en")
if _G.locale == "en" then
    local saved = nil
    pcall(function()
        saved = Turbine.PluginData.Load(Turbine.DataScope.Account, PvMP_Language_Key)
    end)
    if not (type(saved) == "table" and saved.language == "en") then
        _G.locale = "es"
    end
end

if _G.locale == "es" then
    import "PvMP_Plus_Revisited.PvMP_Plus.Strings.en"
    import "PvMP_Plus_Revisited.PvMP_Plus.Strings.es"
else
    import("PvMP_Plus_Revisited.PvMP_Plus.Strings." .. locale)
end

-- Cambia el idioma (solo cliente ingles) y recarga el plugin.
function _G.PvMP_SetLanguage(lang)
    if not PvMP_Language_Switchable or (lang ~= "es" and lang ~= "en") then
        return false
    end
    pcall(Turbine.PluginData.Save, Turbine.DataScope.Account, PvMP_Language_Key, { language = lang })
    if lang ~= locale and type(ReloadPlugin) == "function" then
        pcall(ReloadPlugin)
    end
    return true
end
