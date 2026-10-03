-- WorldMap_Addon/tooltip_data.lua
-- Datos generados automaticamente: tamano y piezas del marco de la ventana
-- flotante de info de zona (la que aparece al pasar el mouse sobre una zona
-- del mapa), y las coordenadas exactas de sus 5 huecos de contenido.
-- No editar a mano: regenerar desde tooltip_tiles_manifest.json.
--
-- Mismo patron real del motor que worldmap_data.lua (namespace global en
-- vez de "return"). Se carga con import "WorldMap_Addon.tooltip_data".

_G.WorldMapAddon = _G.WorldMapAddon or {}
WorldMapAddon.TooltipData = WorldMapAddon.TooltipData or {}
local TooltipData = WorldMapAddon.TooltipData

-- Tamano total de la ventana flotante, en pixeles.
TooltipData.CanvasWidth = 320
TooltipData.CanvasHeight = 330

-- Huecos de contenido (donde el juego dibuja texto/imagen encima del marco).
-- Coordenadas dentro del canvas de 320x330.
TooltipData.Holes = {
  nombre = { x = 29, y = 24,  w = 260, h = 24 },  -- nombre de la zona
  imagen = { x = 19, y = 66,  w = 280, h = 99 },  -- mini imagen de referencia
  intro  = { x = 19, y = 179, w = 281, h = 47 },  -- introduccion (<= 3 lineas)
  nivel  = { x = 24, y = 237, w = 270, h = 16 },  -- "Nivel X-Y"
  dlc    = { x = 23, y = 266, w = 271, h = 16 },  -- DLC/expansion requerida
}

-- Piezas del marco (cuero + filigrana), cada una un archivo chico e
-- independiente para no repetir el problema de texturas unicas demasiado
-- pesadas (el motor las rechaza en silencio). Los cuadros que hubieran
-- caido enteramente dentro de un hueco de contenido ya vienen omitidos.
-- Maximo peso sin comprimir de cualquier pieza: 25.9 KB.
TooltipData.Tiles = {
  { file = "tooltip_r0_c0.tga", x = 0,   y = 0,   w = 80, h = 82 },
  { file = "tooltip_r0_c1.tga", x = 80,  y = 0,   w = 80, h = 82 },
  { file = "tooltip_r0_c2.tga", x = 160, y = 0,   w = 80, h = 82 },
  { file = "tooltip_r0_c3.tga", x = 240, y = 0,   w = 80, h = 82 },
  { file = "tooltip_r1_c0.tga", x = 0,   y = 82,  w = 80, h = 83 },
  { file = "tooltip_r1_c3.tga", x = 240, y = 82,  w = 80, h = 83 },
  { file = "tooltip_r2_c0.tga", x = 0,   y = 165, w = 80, h = 83 },
  { file = "tooltip_r2_c1.tga", x = 80,  y = 165, w = 80, h = 83 },
  { file = "tooltip_r2_c2.tga", x = 160, y = 165, w = 80, h = 83 },
  { file = "tooltip_r2_c3.tga", x = 240, y = 165, w = 80, h = 83 },
  { file = "tooltip_r3_c0.tga", x = 0,   y = 248, w = 80, h = 82 },
  { file = "tooltip_r3_c1.tga", x = 80,  y = 248, w = 80, h = 82 },
  { file = "tooltip_r3_c2.tga", x = 160, y = 248, w = 80, h = 82 },
  { file = "tooltip_r3_c3.tga", x = 240, y = 248, w = 80, h = 82 },
}
