-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
-- LUI/src/UI/book_style.lua
-- Tema "cafe/dorado" pedido explicito del usuario ("puedes generar la
-- misma skin cafe visual que concuerde con nuestro addon"), para que LUI
-- combine con la paleta del addon LOTRO_Quest_Assistant (QuestSyncWindow,
-- estilo "libro" -- fondos cafe oscuro, texto dorado/tostado, bordes
-- cafe-dorado). LUI dibuja con COLORES PLANOS (rellenos + degradados), no
-- con texturas de madera/pergamino como las ventanas del otro addon -- asi
-- que esto no va a verse como paginas de libro, va a ser un tema oscuro de
-- tonos cafe/dorado que armoniza en espiritu, no un calco pixel a pixel.
--
-- Mecanismo: LUI/src/UI/Widgets/style.lua ya define un punto de extension
-- documentado para esto -- "LUI.UI.Style" es la "capa de estilo del
-- desarrollador/plugin", resuelta ANTES de los valores por defecto
-- (DEFAULTS) pero DESPUES de "LUI.UI.UserStyle" (la personalizacion
-- guardada del jugador via la pantalla de configuracion de LUI, si
-- alguna vez toco colores ahi). LUI.src.namespace ya crea
-- "LUI.UI.Style = {}" -- este archivo solo AGREGA claves a esa tabla
-- existente (nunca la reemplaza entera), asi que el orden respecto a
-- Apply.saved_global_style() (que sobreescribe UI.UserStyle, una tabla
-- DISTINTA) no importa.
--
-- Los valores de color siguen el MISMO orden de parametros real que ya usa
-- el resto de style.lua: Turbine.UI.Color(a,r,g,b) con 4 argumentos
-- cuando el original necesita alpha explicito, o Turbine.UI.Color(r,g,b)
-- con 3 cuando el original es siempre opaco (ej. PANEL_BACKGROUND) -- se
-- respeta cual usaba cada clave en DEFAULTS, no se adivina.
import "Turbine.UI"

local LUI = _G.LUI
local UI = LUI.UI
local Style = UI.Style

-- ===== Fondos y texto base =====
Style.BACKGROUND = Turbine.UI.Color(1, 0.10, 0.07, 0.04)
Style.FOREGROUND = Turbine.UI.Color(1, 0.88, 0.77, 0.57)
Style.INFO_FOREGROUND = Turbine.UI.Color(1, 0.80, 0.70, 0.55)
Style.FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.55, 0.48, 0.38)
Style.TEXT_OUTLINE = Turbine.UI.Color(1, 0.04, 0.02, 0.01)

Style.ALTERNATE_BACKGROUND = Turbine.UI.Color(1, 0.08, 0.055, 0.03)
Style.ALTERNATE_FOREGROUND = Turbine.UI.Color(0.85, 0.80, 0.68)
Style.SUBTLE_FOREGROUND = Turbine.UI.Color(1, 0.45, 0.38, 0.28)
Style.SEPARATOR = Turbine.UI.Color(1, 0.30, 0.22, 0.12)

-- ===== Controles (botones, campos, etc.) =====
Style.CONTROL_BACKGROUND = Turbine.UI.Color(1, 0.16, 0.11, 0.06)
Style.CONTROL_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.30, 0.22, 0.10)
Style.CONTROL_BACKGROUND_PRESSED = Turbine.UI.Color(1, 0.12, 0.08, 0.04)
Style.CONTROL_BACKGROUND_ACTIVE = Turbine.UI.Color(1, 0.35, 0.26, 0.12)
Style.CONTROL_BACKGROUND_DISABLED = Turbine.UI.Color(1, 0.10, 0.10, 0.10)
Style.CONTROL_BACKGROUND_READONLY = Turbine.UI.Color(1, 0.20, 0.16, 0.10)
Style.CONTROL_FOREGROUND = Turbine.UI.Color(1, 0.92, 0.82, 0.62)
Style.CONTROL_FOREGROUND_HOVER = Turbine.UI.Color(1, 1, 0.92, 0.72)
Style.CONTROL_FOREGROUND_PRESSED = Turbine.UI.Color(1, 0.92, 0.82, 0.62)
Style.CONTROL_FOREGROUND_ACTIVE = Turbine.UI.Color(1, 1, 0.94, 0.76)
Style.CONTROL_FOREGROUND_DISABLED = Turbine.UI.Color(0.55, 0.65, 0.60, 0.50)
Style.CONTROL_BORDER = Turbine.UI.Color(1, 0.55, 0.42, 0.20)
Style.CONTROL_BORDER_HOVER = Turbine.UI.Color(1, 0.70, 0.55, 0.26)
Style.CONTROL_BORDER_ACTIVE = Turbine.UI.Color(1, 0.80, 0.62, 0.28)
Style.CONTROL_BORDER_DISABLED = Turbine.UI.Color(0.45, 0.45, 0.40, 0.30)

-- ===== Acento (resaltes, checkboxes marcados, etc.) =====
Style.ACCENT_BACKGROUND = Turbine.UI.Color(1, 0.75, 0.55, 0.20)
Style.ACCENT_BACKGROUND_DISABLED = Turbine.UI.Color(0.50, 0.55, 0.50, 0.42)
Style.ACCENT_FOREGROUND = Turbine.UI.Color(1, 0.10, 0.06, 0.02)

-- ===== Seleccion (filas de tabla/lista elegidas) =====
Style.SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.40, 0.28, 0.10)
Style.SELECTION_BACKGROUND_HOVER = Turbine.UI.Color(1, 0.32, 0.24, 0.12)
Style.SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 0.94, 0.78)
Style.ALTERNATE_SELECTION_BACKGROUND = Turbine.UI.Color(1, 0.22, 0.15, 0.06)
Style.ALTERNATE_SELECTION_FOREGROUND = Turbine.UI.Color(1, 1, 0.94, 0.78)

-- ===== Paneles =====
Style.PANEL_BACKGROUND = Turbine.UI.Color(0.10, 0.07, 0.04)
Style.PANEL_INNER_BACKGROUND = Turbine.UI.Color(0.13, 0.09, 0.055)
Style.PLACEHOLDER_FOREGROUND = Turbine.UI.Color(1, 0.55, 0.48, 0.36)
Style.INVALID_BACKGROUND = Turbine.UI.Color(0.28, 0.14, 0.10)

-- ===== Dialogo modal =====
Style.MODAL_DIALOG_BACKGROUND = Turbine.UI.Color(0.95, 0.10, 0.07, 0.04)
