-- worldmap_engine_adapter.lua
--
-- Esta es la UNICA parte de todo el paquete que depende del motor/framework
-- real del addon. El resto (worldmap_data.lua y worldmap.lua) es logica pura
-- en Lua que no sabe nada de la API del juego.
--
-- Instrucciones: completar cada funcion de aqui abajo llamando a las
-- funciones reales de tu framework de addons de LOTRO (las que ya usan
-- enc_frame_v16.tga, las ventanas del bestiary, etc.). Dejé todo lo que
-- pude deducir de lo que ya charlamos (rutas de textura como string, TGA
-- con alfa real) pero los nombres de funcion son PLACEHOLDERS: hay que
-- pegarlos con la API real que ya tiene el resto del addon.

local Adapter = {}

-- Crea una ventana/contenedor vacio en pantalla.
-- Debe devolver un "handle" que las demas funciones de aqui abajo puedan usar.
function Adapter.CreateWindow(width, height, parent)
    -- TODO: reemplazar por la funcion real, ej:
    -- return MiFramework.Window.new{ width = width, height = height, parent = parent }
    error("Adapter.CreateWindow: completar con la API real del addon")
end

-- Crea un control de imagen (para un tile de fondo o para el marco de cuero)
-- y lo posiciona dentro de la ventana `parentHandle` en (x, y) con tamano (w, h).
function Adapter.CreateImage(parentHandle, texturePath, x, y, w, h)
    -- TODO: ej:
    -- local img = MiFramework.Image.new{ parent = parentHandle, texture = texturePath }
    -- img:SetPosition(x, y); img:SetSize(w, h)
    -- return img
    error("Adapter.CreateImage: completar con la API real del addon")
end

-- Crea un control de texto simple.
function Adapter.CreateText(parentHandle, text, x, y, color)
    -- TODO
    error("Adapter.CreateText: completar con la API real del addon")
end

-- Dibuja un poligono relleno con un color y una opacidad (alpha 0-1).
-- Si tu framework NO soporta poligonos rellenos nativos, la funcion
-- DrawZoneFallback() en worldmap.lua ya tiene un plan B (ver mas abajo).
function Adapter.DrawFilledPolygon(parentHandle, points, colorHex, alpha)
    -- TODO: si existe algo tipo MiFramework.Polygon.new{ points = points, ... }
    -- llamarlo aca. Si no existe, dejar esta funcion sin implementar y usar
    -- el modo "solo hover, sin relleno visual" (ver worldmap.lua).
    return nil
end

-- Cambia el color/alpha de un poligono ya dibujado (para resaltarlo al pasar el mouse).
function Adapter.SetPolygonStyle(polygonHandle, colorHex, alpha)
    -- TODO
end

-- Posicion actual del mouse, relativa a la ventana del mapa.
function Adapter.GetMousePosition(windowHandle)
    -- TODO: ej: return MiFramework.Input.GetMousePosition(windowHandle)
    error("Adapter.GetMousePosition: completar con la API real del addon")
end

-- Registra una funcion que se llama en cada movimiento del mouse dentro de la ventana.
-- callback recibe (x, y) en coordenadas locales de la ventana.
function Adapter.OnMouseMove(windowHandle, callback)
    -- TODO: ej: windowHandle.MouseMove = callback
    error("Adapter.OnMouseMove: completar con la API real del addon")
end

function Adapter.SetVisible(handle, visible)
    -- TODO
end

function Adapter.SetPosition(handle, x, y)
    -- TODO
end

return Adapter
