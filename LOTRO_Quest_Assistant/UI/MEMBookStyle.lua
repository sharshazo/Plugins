-- LOTRO_Quest_Assistant/UI/MEMBookStyle.lua
-- Identidad visual "libro" compartida por las ventanas de este addon
-- (QuestBookWindow.lua primero; QuestTrackerHUD/GatherWindow/QuestSyncWindow
-- despues), calcada del sistema visual de MEMLotro (Citadel UI RPG, Kodiak
-- Graphics) -- uso autorizado explicitamente por el usuario (dueño/autor de
-- ese proyecto tambien, mismo criterio ya aplicado en este addon con los
-- assets de CubePlugins/DeedTracker).
--
-- Los .tga reales viven en Resources/Book/ (copiados 1:1 desde
-- MEMLotro/Images/, 2026-08-28). Las fuentes BookAntiqua* NO son un asset
-- nuevo: son IDs numericos del propio cliente de LOTRO (confirmado leyendo
-- MEMLotro/MEMCommon/Fonts.lua, que cita como fuente un post del foro
-- oficial de LOTRO sobre estos IDs) -- el mismo mecanismo que
-- Turbine.UI.Lotro.Font.TrajanPro14 ya usa en el resto de este addon, solo
-- que BookAntiqua no tiene un nombre corto expuesto en ese enum, asi que se
-- referencia por el numero crudo.
--
-- Patron de boton replicado de MEMCommon/MEMButton.lua/MEMTagButton.lua/
-- IconButton.lua (leidos en esta sesion): un Turbine.UI.Control con 3
-- fondos .tga (normal/over/down) intercambiados por MouseEnter/Leave/Down/
-- Up -- ninguna API nueva, las mismas 4 que ya usa este addon en otros
-- lugares (GatherWindow.lua/QuestSyncWindow.lua tienen MouseDown/Move/Up
-- propios; SetBlendMode(Overlay) ya confirmado necesario para .tga chicos
-- en GatherWindow.lua/MoorMapCustomAnnotations.lua).
import "Turbine"
import "Turbine.UI"
import "Turbine.UI.Lotro"

_G.LQA = _G.LQA or {}
LQA.UI = LQA.UI or {}
LQA.UI.MEMBookStyle = {}
local MEMBookStyle = LQA.UI.MEMBookStyle

MEMBookStyle.RES_BASE = "LOTRO_Quest_Assistant/Resources/Book/"

-- Ver la nota grande arriba: numeros crudos de fuente del cliente, no un
-- archivo .ttf. Solo se listan los tamaños que este addon realmente usa.
MEMBookStyle.Font = {
    BookAntiquaBold24 = 1107296272,
    BookAntiquaBold18 = 1107296498,
    BookAntiquaBold14 = 1107296496,
    BookAntiqua18 = 1107296506,
    BookAntiqua14 = 1107296505,
    -- Agregado (V2 del panel "libro" de QuestSyncWindow, listas mas
    -- angostas que necesitan texto mas chico que quepa en 218/334px).
    BookAntiqua12 = 1107296502,
    -- Agregado (V3, pedido explicito del usuario: "necesito que sea mas
    -- grande... los textos necesito que sea mas legible por el tamaño") --
    -- reemplaza BookAntiqua14 como tamaño base del texto de cuerpo/listas.
    BookAntiqua16 = 1107296504,
}

-- Paleta calcada de MEMTagButton.lua/IconButton.lua (texto dorado-tostado
-- sobre las etiquetas de boton) y MEMMain.lua (gris de los encabezados
-- "Series"/"Memoir").
MEMBookStyle.Color = {
    TagText = Turbine.UI.Color(207 / 255, 178 / 255, 133 / 255),
    HeadingGray = Turbine.UI.Color(140 / 255, 140 / 255, 140 / 255),
    BodyText = Turbine.UI.Color(80 / 255, 80 / 255, 80 / 255),
    -- Pedido del usuario: distinguir titulo de historia "como un libro de
    -- verdad" -- antes titulo/nombre de NPC/cuerpo/encabezado "Objetivos"
    -- usaban todos el mismo BodyText gris plano. Tinta bordo/sepia oscuro,
    -- tipica de titulos de manuscrito iluminado -- suficiente contraste
    -- contra el pergamino (~151,119,80 medido esta sesion) sin competir con
    -- los colores de estado de lblBanner (verde/dorado).
    TitleInk = Turbine.UI.Color(128 / 255, 30 / 255, 24 / 255),
}

-- Boton generico de icono con 3 estados (normal/over/down), calcado de
-- MEMCommon/IconButton.lua. `texture` es el nombre base sin sufijo ni
-- extension (ej. "close_button" -> close_button.tga/_down.tga/_over.tga en
-- Resources/Book/). Sin el mecanismo de Quickslot/ubicacion de
-- MEMButton.lua -- eso es especifico de MEM (dialogos con NPCs por
-- cercania), no aplica aca; los botones "Ir" de este addon ya tienen su
-- propio Quickslot real via MoorMapAdapter, sin relacion con este estilo
-- visual.
function MEMBookStyle.CreateIconButton(texture, w, h, text)
    local btn = Turbine.UI.Control()
    btn.normalIcon = MEMBookStyle.RES_BASE .. texture .. ".tga"
    btn.clickIcon = MEMBookStyle.RES_BASE .. texture .. "_down.tga"
    btn.overIcon = MEMBookStyle.RES_BASE .. texture .. "_over.tga"
    btn.mouseOver = false

    btn:SetSize(w, h)
    btn:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    btn:SetBackground(btn.normalIcon)
    btn:SetMouseVisible(true)
    btn:SetVisible(true)

    if text ~= nil and text ~= "" then
        btn.label = Turbine.UI.Label()
        btn.label:SetFont(MEMBookStyle.Font.BookAntiquaBold14)
        btn.label:SetParent(btn)
        btn.label:SetPosition(0, 0)
        btn.label:SetSize(w, h)
        btn.label:SetMouseVisible(false)
        btn.label:SetForeColor(MEMBookStyle.Color.TagText)
        btn.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
        btn.label:SetSelectable(false)
        btn.label:SetText(text)
    end

    btn.MouseEnter = function()
        btn.mouseOver = true
        btn:SetBackground(btn.overIcon)
    end
    btn.MouseLeave = function()
        btn.mouseOver = false
        btn:SetBackground(btn.normalIcon)
    end
    btn.MouseDown = function()
        btn:SetBackground(btn.clickIcon)
        if btn.ButtonClicked then btn.ButtonClicked() end
    end
    btn.MouseUp = function()
        btn:SetBackground(btn.mouseOver and btn.overIcon or btn.normalIcon)
    end

    return btn
end

-- Boton de icono con 3 estados, MISMA logica que CreateIconButton, con
-- BlendMode.AlphaBlend (2026-09-04, pedido explicito del usuario: integrar
-- el set nuevo de botones -- activar/completar/desmarcar/narrar, arte a
-- todo color con texto ya quemado adentro).
--
-- Historial real de esta funcion, 3 rondas con captura del usuario cada
-- vez (para que la proxima sesion no repita el mismo tanteo):
-- V1: BlendMode.AlphaBlend + imagen fuente MAS GRANDE (440x160/132x48) que
--     el control (66x24) -- se vio en blanco/recortado (solo un hilo de
--     texto arriba, resto negro). Causa real (descubierta en V3):
--     SetBackground NO reescala la imagen al tamaño del control, la
--     dibuja a su resolucion REAL y recorta -- el problema nunca fue el
--     BlendMode.
-- V2: se saco el BlendMode por completo, sospechando (mal) que el
--     problema era ese -- con la imagen todavia mas grande que el
--     control, seguia recortada/rota iron igual.
-- V3: imagen generada YA al tamaño exacto del control (66x24 etc, ver
--     cada call site) -- esto arreglo el recorte, PERO sin BlendMode el
--     canal alfa no se respeta: las esquinas transparentes (RGBA
--     0,0,0,0 real, confirmado con Pillow) se dibujaban NEGRAS solidas en
--     vez de invisibles -- "veo lo que esta detras... borde negro"
--     reportado por el usuario.
-- V4 (esta version): imagen a tamaño exacto (de V3) + BlendMode.AlphaBlend
--     de vuelta (de V1) -- las 2 correcciones son ORTOGONALES y hacen
--     falta las 2 juntas: tamaño exacto para que no recorte, AlphaBlend
--     para que respete el alfa de las esquinas. Ademas el PNG fuente se
--     escala con alfa PREMULTIPLICADO antes de guardar el .tga (evita el
--     halo/franja oscura semitransparente que dejaba un resize ingenuo en
--     los bordes redondeados -- ver herramienta de conversion, no vive en
--     este archivo Lua).
-- Sin parametro `text`: estos botones nuevos ya traen la palabra dibujada
-- en el propio PNG.
function MEMBookStyle.CreateIconButtonAlpha(texture, w, h)
    local btn = Turbine.UI.Control()
    btn.normalIcon = MEMBookStyle.RES_BASE .. texture .. ".tga"
    btn.clickIcon = MEMBookStyle.RES_BASE .. texture .. "_down.tga"
    btn.overIcon = MEMBookStyle.RES_BASE .. texture .. "_over.tga"
    btn.mouseOver = false

    btn:SetSize(w, h)
    btn:SetBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    btn:SetBackground(btn.normalIcon)
    btn:SetMouseVisible(true)
    btn:SetVisible(true)

    btn.MouseEnter = function()
        btn.mouseOver = true
        btn:SetBackground(btn.overIcon)
    end
    btn.MouseLeave = function()
        btn.mouseOver = false
        btn:SetBackground(btn.normalIcon)
    end
    btn.MouseDown = function()
        btn:SetBackground(btn.clickIcon)
        if btn.ButtonClicked then btn.ButtonClicked() end
    end
    btn.MouseUp = function()
        btn:SetBackground(btn.mouseOver and btn.overIcon or btn.normalIcon)
    end

    return btn
end

-- Boton "etiqueta" con texto (Continue/Restart en MEM) -- calcado de
-- MEMCommon/MEMTagButton.lua. `color` es "blue" | "cyan" | "red" (los 3
-- juegos de tag_*.tga copiados a Resources/Book/).
function MEMBookStyle.CreateTagButton(text, color)
    local btn = MEMBookStyle.CreateIconButton("tag_" .. color, 108, 38, text)
    -- MEMTagButton usa BookAntiquaBold18 (mas grande que el generico 14 de
    -- IconButton) para el texto del tag -- se pisa aca despues de crearlo
    -- en vez de agregar un parametro de fuente al helper generico.
    if btn.label then
        btn.label:SetFont(MEMBookStyle.Font.BookAntiquaBold18)
        btn.label:SetPosition(0, 2)
    end
    return btn
end
