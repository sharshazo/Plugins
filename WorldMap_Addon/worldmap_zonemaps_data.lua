-- WorldMap_Addon/worldmap_zonemaps_data.lua
--
-- v3.1: mapas de zona (imagen del propio cliente del juego, mismos numeros
-- de recurso y factores de coordenadas que usa MoorMap) y sus iconos:
--   c = ciudad grande, r = incursion (raid), d = mazmorra (dungeon),
--   s = establo, t = cofre, e = elite.
-- Cada icono: { tipo, x, y, nombreEN, nombreES, extra } en pixeles del
-- mapa (1024x768). Varios nombres en el mismo lugar van separados por \n.
-- extra: elite = "Dificultad|nivel"; establo = "far" si es de largo alcance.
-- Fuentes: MoorMap (Defaults/MapData), LotroCompanion (lotro-data:
-- dungeons, privateEncounters, geoAreas; lotro-maps-db: markers y etiquetas
-- en espanol), WarbandsSlayer y Quest Assistant (ThreatsDB, LostLoreDB,
-- GroupPlaceES). Archivo GENERADO: no editar a mano.

_G.WorldMapAddon = _G.WorldMapAddon or {}
local D = { Maps = {}, Zones = {}, Pois = {}, Links = {}, MapZone = {} }
WorldMapAddon.ZoneMapsData = D

D.Zones["Forochel"] = { 21, 22 }
D.Zones["Gundabad"] = { 291, 298, 299, 292, 293, 294, 295, 296, 297 }
D.Zones["Angmar"] = { 4 }
D.Zones["Ered Mithrin and Withered Heath"] = { 177 }
D.Zones["Iron Hills"] = { 178 }
D.Zones["Evendim"] = { 19, 20 }
D.Zones["North Downs"] = { 25 }
D.Zones["Elderslade"] = { 263 }
D.Zones["Eryn Lasgalen and the Dale-lands"] = { 171 }
D.Zones["Ered Luin"] = { 13, 15, 14, 16 }
D.Zones["The Yondershire"] = { 361 }
D.Zones["The Wildwood"] = { 280 }
D.Zones["Wells of Langflood"] = { 242 }
D.Zones["The Shire"] = { 26, 27 }
D.Zones["Bree-land"] = { 5, 9, 6, 7, 8, 11, 10 }
D.Zones["Lone-lands"] = { 23 }
D.Zones["Trollshaws"] = { 28, 29, 463 }
D.Zones["Misty Mountains"] = { 24 }
D.Zones["Ettenmoors (PvMP)"] = { 1 }
D.Zones["Vales of Anduin"] = { 199 }
D.Zones["Azanulbizar"] = { 288 }
D.Zones["The Angle of Mitheithel"] = { 356 }
D.Zones["Eregion"] = { 17, 18 }
D.Zones["Lothlorien"] = { 31, 32 }
D.Zones["Mirkwood"] = { 33, 174 }
D.Zones["Cardolan"] = { 369 }
D.Zones["Swanfleet"] = { 368 }
D.Zones["Moria"] = { 34, 35, 36, 37, 38, 39, 41, 42, 43, 44, 45 }
D.Zones["Wildermore"] = { 112, 113 }
D.Zones["Great River"] = { 67, 68 }
D.Zones["Enedwaith"] = { 12 }
D.Zones["Nan Curunir"] = { 63, 65, 123 }
D.Zones["East Rohan"] = { 71, 72, 73, 74, 75, 76, 77, 78, 79 }
D.Zones["Dunland"] = { 61, 64 }
D.Zones["Gap of Rohan"] = { 62 }
D.Zones["West Rohan"] = { 114, 115, 116, 117, 118, 119, 120, 121, 122 }
D.Zones["Far Anorien"] = { 148, 149, 150 }
D.Zones["North Ithilien"] = { 154 }
D.Zones["Old Anorien"] = { 147, 144, 146, 145, 142 }
D.Zones["Dead Marshes"] = { 131 }
D.Zones["The Wastes"] = { 159 }
D.Zones["Mordor Besieged"] = { 204 }
D.Zones["Plateau of Gorgoroth"] = { 161, 163, 164, 165, 166, 167, 168 }
D.Zones["Morgul Vale"] = { 202, 203 }
D.Zones["Outer Gondor"] = { 399, 400, 401 }
D.Zones["Western Gondor"] = { 125, 126, 127, 128, 129, 130, 151 }
D.Zones["Central Gondor"] = { 132, 133, 134, 135, 136 }
D.Zones["Eastern Gondor"] = { 138, 139, 140, 141, 142 }
D.Zones["King's Gondor"] = { 386, 387, 388, 389, 390, 393, 394, 395, 396, 397, 398 }
D.Zones["The Shield Isles"] = { 403 }
D.Zones["Cape of Umbar"] = { 404, 405 }
D.Zones["Valley of Ikorban"] = { 419, 420, 421, 422, 423 }
D.Zones["Sug Nidar"] = { 447 }
D.Zones["Mûr Ghala"] = { 440, 441, 442, 443, 444, 445, 446 }
D.Zones["The Hatokali Fells"] = { 458 }
D.Zones["Pahar Hatokali"] = { 458 }

D.Maps[1] = { img = 1090552115, w = 1024, h = 768, tier = 3, en = "Ettenmoors", es = "Landas de Etten" }
D.Maps[3] = { img = 1090552120, w = 1024, h = 768, tier = 2, en = "Eriador", es = "Eriador" }
D.Maps[4] = { img = 1090552113, w = 1024, h = 768, tier = 3, en = "Angmar", es = "Angmar" }
D.Maps[5] = { img = 1090552118, w = 1024, h = 768, tier = 3, en = "Bree-land", es = "Tierras de Bree" }
D.Maps[6] = { img = 1090552117, w = 1024, h = 768, tier = 4, en = "Archet", es = "Archet" }
D.Maps[7] = { img = 1091610689, w = 1024, h = 768, tier = 4, en = "Barrow Downs North", es = "Quebradas de los Túmulos (Norte)" }
D.Maps[8] = { img = 1091610690, w = 1024, h = 768, tier = 4, en = "Barrow Downs South", es = "Quebradas de los Túmulos (Sur)" }
D.Maps[9] = { img = 1090552116, w = 1024, h = 768, tier = 4, en = "Bree", es = "Bree" }
D.Maps[10] = { img = 1091410516, w = 1024, h = 768, tier = 4, en = "Bree-land Homesteads", es = "Residencias de las Tierras de Bree" }
D.Maps[11] = { img = 1091456477, w = 1024, h = 768, tier = 4, en = "The Old Forest", es = "El Bosque Viejo" }
D.Maps[12] = { img = 1091584420, w = 1024, h = 768, tier = 3, en = "Enedwaith", es = "Enedwaith" }
D.Maps[13] = { img = 1090552108, w = 1024, h = 768, tier = 3, en = "Ered Luin", es = "Ered Luin" }
D.Maps[14] = { img = 1091410228, w = 1024, h = 768, tier = 4, en = "Falathlorn Homesteads", es = "Residencias de Falathlorn" }
D.Maps[15] = { img = 1090552107, w = 1024, h = 768, tier = 4, en = "Thorin's Gate", es = "Mansión de Thorin" }
D.Maps[16] = { img = 1091410518, w = 1024, h = 768, tier = 4, en = "Thorin's Hall Homesteads", es = "Residencias de la Mansión de Thorin" }
D.Maps[17] = { img = 1091470982, w = 1024, h = 768, tier = 3, en = "Eregion", es = "Eregion" }
D.Maps[18] = { img = 1091470996, w = 1024, h = 768, tier = 4, en = "The Walls of Moria", es = "Las murallas de Moria" }
D.Maps[19] = { img = 1090646148, w = 1024, h = 768, tier = 3, en = "Evendim", es = "Evendim" }
D.Maps[20] = { img = 1091464877, w = 1024, h = 768, tier = 4, en = "Annúminas", es = "Annúminas" }
D.Maps[21] = { img = 1091452742, w = 1024, h = 768, tier = 3, en = "Forochel", es = "Forochel" }
D.Maps[22] = { img = 1091622309, w = 1024, h = 768, tier = 3, en = "Frostbluff", es = "Frostbluff" }
D.Maps[23] = { img = 1090552112, w = 1024, h = 768, tier = 3, en = "Lone-lands", es = "Tierras Solitarias" }
D.Maps[24] = { img = 1090552111, w = 1024, h = 768, tier = 3, en = "Misty Mountains", es = "Montañas Nubladas" }
D.Maps[25] = { img = 1090552114, w = 1024, h = 768, tier = 3, en = "North Downs", es = "Quebradas del Norte" }
D.Maps[26] = { img = 1090552119, w = 1024, h = 768, tier = 3, en = "The Shire", es = "La Comarca" }
D.Maps[27] = { img = 1091410519, w = 1024, h = 768, tier = 4, en = "Shire Homesteads", es = "Residencias de la Comarca" }
D.Maps[28] = { img = 1092708782, w = 1024, h = 768, tier = 3, en = "Trollshaws", es = "Bosque de los Trolls" }
D.Maps[29] = { img = 1093069830, w = 1024, h = 768, tier = 4, en = "Rivendell", es = "Rivendel" }
D.Maps[30] = { img = 1092365796, w = 1024, h = 768, tier = 2, en = "Rhovanion", es = "Rhovanion" }
D.Maps[31] = { img = 1091471111, w = 1024, h = 768, tier = 3, en = "Lothlórien", es = "Lothlórien" }
D.Maps[32] = { img = 1091471110, w = 1024, h = 768, tier = 4, en = "Caras Galadhon", es = "Caras Galadhon" }
D.Maps[33] = { img = 1091571186, w = 1024, h = 768, tier = 3, en = "Mirkwood", es = "Bosque Negro" }
D.Maps[34] = { img = 1091471112, w = 1024, h = 768, tier = 3, en = "Moria", es = "Moria" }
D.Maps[35] = { img = 1091471133, w = 1024, h = 768, tier = 4, en = "Durin's Way", es = "Camino de Durin" }
D.Maps[36] = { img = 1091471126, w = 1024, h = 768, tier = 4, en = "Flaming Deeps", es = "Las Profundidades Llameantes" }
D.Maps[37] = { img = 1091471125, w = 1024, h = 768, tier = 4, en = "Foundations of Stone", es = "Fundaciones de Piedra" }
D.Maps[38] = { img = 1091471130, w = 1024, h = 768, tier = 4, en = "Nud Melek", es = "Nud-melek" }
D.Maps[39] = { img = 1091471128, w = 1024, h = 768, tier = 4, en = "Redhorn Lodes", es = "Vetas del Cuerno Rojo" }
D.Maps[40] = { img = 1091472986, w = 1024, h = 768, tier = 4, en = "The Grand Stair", es = "La Gran Escalera" }
D.Maps[41] = { img = 1091471132, w = 1024, h = 768, tier = 4, en = "The Great Delving", es = "La Gran Excavación" }
D.Maps[42] = { img = 1091471129, w = 1024, h = 768, tier = 4, en = "The Silvertine Lodes", es = "Vetas del Cuerno de Plata" }
D.Maps[43] = { img = 1091471127, w = 1024, h = 768, tier = 4, en = "The Waterworks", es = "Las Obras Hidráulicas" }
D.Maps[44] = { img = 1091471131, w = 1024, h = 768, tier = 4, en = "Zelem Melek", es = "Zelem-melek" }
D.Maps[45] = { img = 1091471134, w = 1024, h = 768, tier = 4, en = "Zirakzigil", es = "Zirakzigil" }
D.Maps[60] = { img = 1091671573, w = 1024, h = 768, tier = 3, en = "Dunland Overview", es = "Vistazo a las Tierras Brunas" }
D.Maps[61] = { img = 1091671581, w = 1024, h = 768, tier = 4, en = "Dunland", es = "Tierras Brunas" }
D.Maps[62] = { img = 1091661141, w = 1024, h = 768, tier = 4, en = "Gap of Rohan", es = "Paso de Rohan" }
D.Maps[63] = { img = 1091671559, w = 1024, h = 768, tier = 4, en = "Nan Curunír", es = "Nan Curunír" }
D.Maps[64] = { img = 1091661566, w = 1024, h = 768, tier = 5, en = "Galtrev", es = "Galtrev" }
D.Maps[65] = { img = 1091661569, w = 1024, h = 768, tier = 5, en = "Isengard", es = "Isengard" }
D.Maps[67] = { img = 1091690944, w = 1024, h = 768, tier = 3, en = "The Great River", es = "El Gran Río" }
D.Maps[68] = { img = 1091714825, w = 1024, h = 768, tier = 4, en = "Stangard", es = "Stangard" }
D.Maps[69] = { img = 1091680577, w = 1024, h = 768, tier = 4, en = "Tâl Methedras", es = "Tâl Methedras" }
D.Maps[71] = { img = 1091739319, w = 1024, h = 768, tier = 3, en = "East Rohan", es = "Rohan Oriental: El Páramo" }
D.Maps[72] = { img = 1091752413, w = 1024, h = 768, tier = 4, en = "Eaves of Fangorn", es = "Los Lindes de Fangorn" }
D.Maps[73] = { img = 1091752412, w = 1024, h = 768, tier = 4, en = "East Wall", es = "La Muralla del Este" }
D.Maps[74] = { img = 1091752417, w = 1024, h = 768, tier = 4, en = "Entwash Vale", es = "El Valle del Entaguas" }
D.Maps[75] = { img = 1091752416, w = 1024, h = 768, tier = 4, en = "Norcrofts", es = "Norcrofts" }
D.Maps[76] = { img = 1091752415, w = 1024, h = 768, tier = 4, en = "Sutcrofts", es = "Sutcrofts" }
D.Maps[77] = { img = 1091752414, w = 1024, h = 768, tier = 4, en = "The Wold", es = "El Páramo" }
D.Maps[78] = { img = 1091776016, w = 1024, h = 768, tier = 5, en = "Harwick", es = "Harwick" }
D.Maps[79] = { img = 1091776087, w = 1024, h = 768, tier = 5, en = "Snowbourn", es = "Río Nevado" }
D.Maps[80] = { img = "WorldMap_Addon/assets/worldmap/zonemaps/cliving.jpg", w = 1024, h = 768, tier = 5, en = "Cliving", es = "Cliving" }
D.Maps[81] = { img = "WorldMap_Addon/assets/worldmap/zonemaps/eaworth.jpg", w = 512, h = 384, tier = 5, en = "Eaworth", es = "Eaworth" }
D.Maps[112] = { img = 1091794351, w = 1024, h = 768, tier = 4, en = "Wildermore", es = "Tierras feroces" }
D.Maps[113] = { img = 1091795455, w = 1024, h = 768, tier = 5, en = "Forlaw", es = "Forlaw" }
D.Maps[114] = { img = 1091814181, w = 1024, h = 768, tier = 3, en = "Western Rohan", es = "Rohan Occidental" }
D.Maps[115] = { img = 1091814175, w = 1024, h = 768, tier = 4, en = "Kingstead", es = "Tierras del Rey" }
D.Maps[116] = { img = 1091814176, w = 1024, h = 768, tier = 4, en = "Broadacres", es = "Campos Amplios" }
D.Maps[117] = { img = 1091814177, w = 1024, h = 768, tier = 4, en = "Eastfold", es = "Folde Este" }
D.Maps[118] = { img = 1091814178, w = 1024, h = 768, tier = 4, en = "Stonedeans", es = "Stonedeans" }
D.Maps[119] = { img = 1091814179, w = 1024, h = 768, tier = 4, en = "Helm's Deep", es = "Abismo de Helm" }
D.Maps[120] = { img = 1091814180, w = 1024, h = 768, tier = 4, en = "Westfold", es = "Folde Oeste" }
D.Maps[121] = { img = 1091814174, w = 1024, h = 768, tier = 5, en = "Edoras", es = "Edoras" }
D.Maps[122] = { img = 1091878570, w = 1024, h = 768, tier = 4, en = "Entwood", es = "Bosque de los Ents" }
D.Maps[123] = { img = 1091887388, w = 1024, h = 768, tier = 4, en = "Nan Curunír (flooded)", es = "Nan Curunír" }
D.Maps[124] = { img = 1091912502, w = 1024, h = 768, tier = 2, en = "Gondor", es = "Gondor" }
D.Maps[125] = { img = 1091909855, w = 1024, h = 768, tier = 3, en = "Western Gondor", es = "Gondor Occidental" }
D.Maps[126] = { img = 1091915501, w = 1024, h = 768, tier = 4, en = "Blackroot Vale", es = "Valle de la Raíz Negra" }
D.Maps[127] = { img = 1091915499, w = 1024, h = 768, tier = 4, en = "Havens of Belfalas", es = "Puertos de Belfalas" }
D.Maps[128] = { img = 1091915269, w = 1024, h = 768, tier = 5, en = "Dol Amroth", es = "Dol Amroth" }
D.Maps[129] = { img = 1091915500, w = 1024, h = 768, tier = 4, en = "Lamedon", es = "Lamedon" }
D.Maps[130] = { img = 1091914804, w = 1024, h = 768, tier = 4, en = "Paths of the Dead", es = "Caminos de los Muertos" }
D.Maps[131] = { img = 1091930489, w = 1024, h = 768, tier = 3, en = "Dead Marshes", es = "Ciénaga de los Muertos" }
D.Maps[132] = { img = 1091942723, w = 1024, h = 768, tier = 3, en = "Central Gondor", es = "Gondor Central" }
D.Maps[133] = { img = 1091942719, w = 1024, h = 768, tier = 4, en = "Ringló Vale", es = "Valle del Ringló" }
D.Maps[134] = { img = 1091942724, w = 1024, h = 768, tier = 4, en = "Lebennin", es = "Lebennin" }
D.Maps[135] = { img = 1091942716, w = 1024, h = 768, tier = 5, en = "Pelargir", es = "Pelargir" }
D.Maps[136] = { img = 1091942725, w = 1024, h = 768, tier = 4, en = "Dor-en-Ernil", es = "Dor-en-Ernil" }
D.Maps[138] = { img = 1091956277, w = 1024, h = 768, tier = 3, en = "Eastern Gondor", es = "Gondor Oriental" }
D.Maps[139] = { img = 1091956280, w = 1024, h = 768, tier = 4, en = "Upper Lebennin", es = "Lebennin Superior" }
D.Maps[140] = { img = 1091956282, w = 1024, h = 768, tier = 4, en = "South Ithilien", es = "Ithilien Sur" }
D.Maps[141] = { img = 1091956284, w = 1024, h = 768, tier = 4, en = "Lossarnach", es = "Lossarnach" }
D.Maps[142] = { img = 1091956289, w = 1024, h = 768, tier = 5, en = "Osgiliath", es = "Osgiliath" }
D.Maps[144] = { img = 1091983086, w = 1024, h = 768, tier = 4, en = "Talath Anor", es = "Talath Anor" }
D.Maps[145] = { img = 1091983087, w = 1024, h = 768, tier = 5, en = "Minas Tirith", es = "Minas Tirith" }
D.Maps[146] = { img = 1091983088, w = 1024, h = 768, tier = 4, en = "Pelennor", es = "Pelennor" }
D.Maps[147] = { img = 1091983089, w = 1024, h = 768, tier = 3, en = "Old Anórien", es = "Anórien Ancestral" }
D.Maps[148] = { img = 1092005777, w = 1024, h = 768, tier = 3, en = "Far Anórien", es = "Lejano Anórien" }
D.Maps[149] = { img = 1092005771, w = 1024, h = 768, tier = 4, en = "Beacon Hills", es = "Colinas de las Almenaras" }
D.Maps[150] = { img = 1092005776, w = 1024, h = 768, tier = 4, en = "Taur Drúadan", es = "Taur Drúadan" }
D.Maps[151] = { img = 1092284241, w = 1024, h = 768, tier = 4, en = "Cape of Belfalas", es = "Cabo de Belfalas" }
D.Maps[152] = { img = 1092240179, w = 1024, h = 768, tier = 2, en = "Mordor", es = "Mordor" }
D.Maps[153] = { img = 1092240104, w = 1024, h = 768, tier = 5, en = "Pelennor after the battle", es = "Pelennor tras la batalla" }
D.Maps[154] = { img = 1092240103, w = 1024, h = 768, tier = 4, en = "North Ithilien", es = "Ithilien Norte" }
D.Maps[156] = { img = 1092240101, w = 1024, h = 768, tier = 6, en = "Osgiliath after the battle", es = "Osgiliath tras la batalla" }
D.Maps[157] = { img = 1092171933, w = 1024, h = 768, tier = 6, en = "Minas Tirith after the battle", es = "Minas Tirith tras la batalla" }
D.Maps[159] = { img = 1092278441, w = 1024, h = 768, tier = 3, en = "The Wastes", es = "Tierras baldías" }
D.Maps[161] = { img = 1092322516, w = 1024, h = 768, tier = 3, en = "Plateau of Gorgoroth", es = "Meseta de Gorgoroth" }
D.Maps[163] = { img = 1092326801, w = 1024, h = 768, tier = 4, en = "Udûn", es = "Udûn" }
D.Maps[164] = { img = 1092326798, w = 1024, h = 768, tier = 4, en = "Lhingris", es = "Lhingris" }
D.Maps[165] = { img = 1092326800, w = 1024, h = 768, tier = 4, en = "Talath Úrui", es = "Talath Úrui" }
D.Maps[166] = { img = 1092326796, w = 1024, h = 768, tier = 4, en = "Agarnaith", es = "Agarnaith" }
D.Maps[167] = { img = 1092326797, w = 1024, h = 768, tier = 4, en = "Dor Amarth", es = "Dor Amarth" }
D.Maps[168] = { img = 1092326799, w = 1024, h = 768, tier = 5, en = "Orodruin", es = "Orodruin" }
D.Maps[169] = { img = 1092337617, w = 1024, h = 768, tier = 5, en = "Nargroth", es = "Nargroth" }
D.Maps[170] = { img = 1092337616, w = 1024, h = 768, tier = 5, en = "Sammath Naur", es = "Sammath Naur" }
D.Maps[171] = { img = 1092365794, w = 1024, h = 768, tier = 3, en = "Eryn Lasgalen", es = "Eryn Lasgalen" }
D.Maps[172] = { img = 1092365793, w = 1024, h = 768, tier = 4, en = "Felegoth", es = "Felegoth" }
D.Maps[173] = { img = 1092339227, w = 3200, h = 2400, tier = 5, en = "Hall Under the Mountain", es = "Salón Bajo la Montaña" }
D.Maps[174] = { img = 1092369012, w = 1024, h = 768, tier = 4, en = "Dol Guldur (Razed)", es = "Dol Guldur (arrasado)" }
D.Maps[175] = { img = "WorldMap_Addon/assets/worldmap/zonemaps/dale.jpg", w = 1024, h = 768, tier = 4, en = "Dale", es = "Valle" }
D.Maps[176] = { img = "WorldMap_Addon/assets/worldmap/zonemaps/laketown.jpg", w = 1024, h = 768, tier = 4, en = "Lake-town", es = "Ciudad del Lago" }
D.Maps[177] = { img = 1092390313, w = 1024, h = 768, tier = 3, en = "Ered Mithrin", es = "Ered Mithrin" }
D.Maps[178] = { img = 1092408504, w = 1024, h = 768, tier = 3, en = "Iron Hills", es = "Colinas de Hierro" }
D.Maps[179] = { img = 1092412668, w = 1024, h = 768, tier = 4, en = "Thikil-gundu, the Steel Keep", es = "Thikil-gundu, la Fortaleza de Acero" }
D.Maps[180] = { img = 1092413237, w = 1024, h = 768, tier = 4, en = "Glimmerdeep", es = "Glimmerdeep" }
D.Maps[181] = { img = 1092413263, w = 1024, h = 768, tier = 4, en = "Erebor", es = "Erebor" }
D.Maps[183] = { img = 1092431546, w = 1024, h = 768, tier = 4, en = "The Anvil", es = "El Yunque" }
D.Maps[199] = { img = 1092461728, w = 1024, h = 768, tier = 3, en = "Vales of Anduin", es = "Valles del Anduin" }
D.Maps[202] = { img = 1092524609, w = 1024, h = 768, tier = 4, en = "Morgul Vale", es = "Valle de Morgul" }
D.Maps[203] = { img = 1092524610, w = 1024, h = 768, tier = 5, en = "Minas Morgul", es = "Minas Morgul" }
D.Maps[204] = { img = 1092524611, w = 1024, h = 768, tier = 5, en = "Mordor Besieged", es = "Mordor Asediado" }
D.Maps[205] = { img = 1092526842, w = 1024, h = 768, tier = 5, en = "Torech Ungol", es = "Torech Ungol" }
D.Maps[213] = { img = 1092709851, w = 1024, h = 768, tier = 5, en = "Glittering Caves (Epic Battle)", es = "Cavernas Centelleantes" }
D.Maps[235] = { img = 1092331822, w = 1600, h = 2400, tier = 6, en = "Tower of Cirith Ungol", es = "Torre de Cirith Ungol" }
D.Maps[236] = { img = 1092537315, w = 1024, h = 768, tier = 5, en = "Shelob's Lair", es = "Guarida de Ella-Laraña" }
D.Maps[242] = { img = 1092544361, w = 1024, h = 768, tier = 3, en = "Wells of Langflood", es = "Manantiales del Langflood" }
D.Maps[243] = { img = 1092542999, w = 1024, h = 768, tier = 5, en = "Eastfold Hills Homestead", es = "Residencias de las Colinas del Folde Este" }
D.Maps[244] = { img = 1092543000, w = 1024, h = 768, tier = 5, en = "Kingstead Meadows Homestead", es = "Residencias de las Praderas de las Tierras del Rey" }
D.Maps[263] = { img = 1092597871, w = 1024, h = 768, tier = 3, en = "Elderslade", es = "Valle Ancestral" }
D.Maps[280] = { img = 1092667336, w = 1024, h = 768, tier = 4, en = "Wildwood", es = "El Bosque Salvaje" }
D.Maps[288] = { img = 1092669467, w = 1024, h = 768, tier = 3, en = "Azanulbizar", es = "Azanulbizar" }
D.Maps[291] = { img = 1092687466, w = 1024, h = 768, tier = 3, en = "Gundabad", es = "Gundabad" }
D.Maps[292] = { img = 1092687471, w = 1024, h = 768, tier = 4, en = "Delvings of Gundabad", es = "Excursiones de Gundabad" }
D.Maps[293] = { img = 1092687465, w = 1024, h = 768, tier = 5, en = "Mattugard", es = "Máttugard" }
D.Maps[294] = { img = 1092687468, w = 1024, h = 768, tier = 5, en = "Pit of Stonejaws", es = "Foso de Stonejaws" }
D.Maps[295] = { img = 1092687469, w = 1024, h = 768, tier = 5, en = "Deepscrave", es = "Hendidura Profunda" }
D.Maps[296] = { img = 1092687467, w = 1024, h = 768, tier = 5, en = "Clovengap", es = "Pasohendido" }
D.Maps[297] = { img = 1092687472, w = 1024, h = 768, tier = 5, en = "Gloomingtarn", es = "Lagosombrío" }
D.Maps[298] = { img = 1092687464, w = 1024, h = 768, tier = 4, en = "Câr Bronach", es = "Câr Bronach" }
D.Maps[299] = { img = 1092687470, w = 1024, h = 768, tier = 4, en = "Welkin-lofts", es = "Welkin-lofts" }
D.Maps[301] = { img = 1092365797, w = 1024, h = 768, tier = 2, en = "Rohan", es = "Rohan" }
D.Maps[355] = { img = 1092701585, w = 1024, h = 768, tier = 5, en = "The Abodes of Erebor", es = "Residencias de Erebor" }
D.Maps[356] = { img = 1092709646, w = 1024, h = 768, tier = 6, en = "The Angle of Mitheithel", es = "El Ángulo del Mitheithel" }
D.Maps[361] = { img = 1092720973, w = 1024, h = 768, tier = 3, en = "Yondershire", es = "La Comarca Allende" }
D.Maps[368] = { img = 1092741678, w = 1024, h = 768, tier = 3, en = "Swanfleet", es = "la Ciénaga de los Cisnes" }
D.Maps[369] = { img = 1092747833, w = 1024, h = 768, tier = 3, en = "Cardolan", es = "Cardolan" }
D.Maps[370] = { img = 1092751428, w = 1024, h = 768, tier = 4, en = "Mossward", es = "Musgovilla" }
D.Maps[380] = { img = 1092809453, w = 1024, h = 768, tier = 4, en = "Carn Dûm", es = "Carn Dûm" }
D.Maps[386] = { img = 1092817731, w = 1024, h = 768, tier = 3, en = "King's Gondor", es = "Gondor del Rey" }
D.Maps[387] = { img = 1092817730, w = 1024, h = 768, tier = 4, en = "Lossarnach (King's Gondor)", es = "Lossarnach (Gondor del Rey)" }
D.Maps[388] = { img = 1092818010, w = 1024, h = 768, tier = 4, en = "Upper Lebennin (King's Gondor)", es = "Lebennin Superior (Gondor del Rey)" }
D.Maps[389] = { img = 1092818011, w = 1024, h = 768, tier = 4, en = "Lower Lebennin (King's Gondor)", es = "Bajo Lebennin (Gondor del Rey)" }
D.Maps[390] = { img = 1092818012, w = 1024, h = 768, tier = 5, en = "Pelargir (King's Gondor)", es = "Pelargir (Gondor del Rey)" }
D.Maps[392] = { img = 1092831187, w = 1024, h = 768, tier = 6, en = "Lyndelby Homesteads", es = "Residencias de Lyndelby" }
D.Maps[393] = { img = 1092903074, w = 1024, h = 768, tier = 4, en = "Ringló Vale (King's Gondor)", es = "Valle del Ringló" }
D.Maps[394] = { img = 1092903078, w = 1024, h = 768, tier = 4, en = "Lamedon (King's Gondor)", es = "Lamedon (Gondor del Rey)" }
D.Maps[395] = { img = 1092903079, w = 1024, h = 768, tier = 4, en = "Dor-en-Ernil (King's Gondor)", es = "Dor-en-Ernil (Gondor del Rey)" }
D.Maps[396] = { img = 1092903083, w = 1024, h = 768, tier = 4, en = "Blackroot Vale (King's Gondor)", es = "Valle de la Raíz Negra (Gondor del Rey)" }
D.Maps[397] = { img = 1092903082, w = 1024, h = 768, tier = 4, en = "Belfalas (King's Gondor)", es = "Belfalas (Gondor del Rey)" }
D.Maps[398] = { img = 1092851559, w = 1024, h = 768, tier = 5, en = "Dol Amroth (King's Gondor)", es = "Dol Amroth (Gondor Real)" }
D.Maps[399] = { img = 1092912271, w = 1024, h = 768, tier = 3, en = "Outer Gondor", es = "Gondor Exterior" }
D.Maps[400] = { img = 1092912273, w = 1024, h = 768, tier = 4, en = "Pinnath Gelin", es = "Pinnath Gelin" }
D.Maps[401] = { img = 1092912274, w = 1024, h = 768, tier = 4, en = "Anfalas", es = "Anfalas" }
D.Maps[403] = { img = 1092912025, w = 1024, h = 768, tier = 3, en = "Zîrar Tarka - The Shield Isles", es = "Zîrar Tarka - Las Islas Escudo" }
D.Maps[404] = { img = 1092914927, w = 1024, h = 768, tier = 3, en = "Cape of Umbar", es = "Cabo de Umbar" }
D.Maps[405] = { img = 1092914926, w = 1024, h = 768, tier = 4, en = "Umbar Baharbêl", es = "Umbar Baharbêl" }
D.Maps[407] = { img = 1092945451, w = 1024, h = 768, tier = 5, en = "Umbar-môkh: the Neaths", es = "Umbar-môkh: las Profundidades" }
D.Maps[408] = { img = 1092945456, w = 1024, h = 768, tier = 6, en = "Khabârkhad: the Crypts", es = "Khabârkhad: las Criptas" }
D.Maps[409] = { img = 1092945457, w = 1024, h = 768, tier = 6, en = "Kamrabezûr: the Vaults", es = "Kamrabezûr: las Bóvedas" }
D.Maps[410] = { img = 1092945458, w = 1024, h = 768, tier = 6, en = "Dil-irmíz: the Berths", es = "Dil-irmíz: los Atracaderos" }
D.Maps[411] = { img = 1092945459, w = 1024, h = 768, tier = 6, en = "Ilmabiri: the Wells", es = "Ilmabiri: los Pozos" }
D.Maps[412] = { img = 1092945460, w = 1024, h = 768, tier = 6, en = "Tâkhdar: the Cellars", es = "Tâkhdar: las Bodegas" }
D.Maps[419] = { img = 1092976645, w = 1024, h = 768, tier = 3, en = "The Valley of Ikorbân", es = "Valle de Ikorbân" }
D.Maps[420] = { img = 1092976660, w = 1024, h = 768, tier = 4, en = "Ambarûl", es = "Ambarûl" }
D.Maps[421] = { img = 1092976649, w = 1024, h = 768, tier = 4, en = "Urash Dâr", es = "Urash Dâr" }
D.Maps[422] = { img = 1092976657, w = 1024, h = 768, tier = 4, en = "Khûd Zagin", es = "Khûd Zagin" }
D.Maps[423] = { img = 1092976659, w = 1024, h = 768, tier = 4, en = "Imhûlar", es = "Imhûlar" }
D.Maps[440] = { img = 1093040697, w = 1024, h = 768, tier = 3, en = "Mûr Ghala", es = "Mûr Ghala (La Cresta de la Abundancia)" }
D.Maps[441] = { img = 1093040696, w = 1024, h = 768, tier = 4, en = "Idagâl", es = "Idagâl" }
D.Maps[442] = { img = 1093043075, w = 1024, h = 768, tier = 5, en = "Emax Dûl", es = "Emax Dûl" }
D.Maps[443] = { img = 1093043080, w = 1024, h = 768, tier = 4, en = "An Shêru", es = "An Shêru" }
D.Maps[444] = { img = 1093043086, w = 1024, h = 768, tier = 4, en = "Kighân", es = "Kighân" }
D.Maps[445] = { img = 1093043077, w = 1024, h = 768, tier = 5, en = "Zajâna", es = "Zajâna" }
D.Maps[446] = { img = 1093043095, w = 1024, h = 768, tier = 4, en = "Adagím", es = "Adagím" }
D.Maps[447] = { img = 1093043074, w = 1024, h = 768, tier = 4, en = "The Fearwater", es = "Sûg Nidar, las Aguas del Miedo" }
D.Maps[458] = { img = 1093081130, w = 1024, h = 768, tier = 4, en = "Hatokáli Fells", es = "Colinas de Hatokáli" }
D.Maps[463] = { img = 1093069703, w = 1024, h = 768, tier = 5, en = "Rivendell Steadings", es = "Granjas de Rivendel" }
D.Maps[9001] = { img = 1092367355, w = 1600, h = 1200, tier = 5, en = "Secret Stone Chamber", es = "Cámara de Piedra Secreta" }
D.Maps[9002] = { img = 1091670589, w = 1024, h = 768, tier = 5, en = "Isengard Depths (flooded)", es = "Profundidades de Isengard (inundadas)" }
D.Maps[9003] = { img = 1092284242, w = 1024, h = 768, tier = 5, en = "Cape of Belfalas Homesteads", es = "Residencias del Cabo de Belfalas" }


-- conectores (MoorMap tipo 41/51/52 y los del propio juego, LotroCompanion
-- links.xml): { x, y, mapaDestino } en pixeles del mapa
D.Links[3] = { { 482, 135, 21 }, { 785, 194, 4 }, { 271, 294, 13 }, { 497, 222, 19 }, { 472, 433, 26 }, { 675, 278, 25 }, { 595, 382, 5 }, { 691, 432, 23 }, { 845, 289, 1 }, { 962, 265, 24 }, { 861, 363, 28 }, { 909, 531, 17 }, { 801, 607, 12 }, { 968, 424, 30 }, { 813, 702, 60 }, { 917, 680, 63 }, { 462, 338, 361 }, { 674, 483, 369 }, { 760, 506, 368 } }
D.Links[4] = { { 459, 710, 25 }, { 137, 732, 25 }, { 1002, 105, 298 }, { 322, 94, 380 } }
D.Links[5] = { { 460, 57, 25 }, { 887, 57, 25 }, { 612, 352, 6 }, { 129, 560, 26 }, { 281, 590, 11 }, { 407, 560, 7 }, { 463, 656, 8 }, { 536, 507, 9 }, { 659, 703, 10 }, { 907, 630, 23 }, { 328, 206, 280 }, { 186, 40, 19 }, { 149, 136, 19 }, { 70, 305, 26 }, { 444, 20, 25 }, { 506, 729, 369 } }
D.Links[6] = { { 219, 736, 5 } }
D.Links[7] = { { 566, 107, 5 }, { 758, 491, 5 }, { 737, 725, 8 }, { 225, 448, 11 } }
D.Links[8] = { { 597, 35, 7 } }
D.Links[9] = { { 829, 410, 5 }, { 814, 695, 5 }, { 64, 215, 5 } }
D.Links[10] = { { 754, 135, 5 } }
D.Links[11] = { { 268, 281, 5 }, { 660, 25, 5 }, { 796, 265, 7 } }
D.Links[12] = { { 756, 86, 17 }, { 546, 707, 60 }, { 357, 143, 368 } }
D.Links[13] = { { 293, 103, 15 }, { 118, 121, 16 }, { 911, 565, 26 }, { 854, 622, 14 }, { 863, 539, 361 } }
D.Links[14] = { { 559, 113, 13 } }
D.Links[15] = { { 543, 747, 13 }, { 234, 579, 16 } }
D.Links[16] = { { 801, 532, 13 } }
D.Links[17] = { { 269, 71, 28 }, { 882, 539, 34 }, { 775, 471, 18 }, { 455, 707, 12 }, { 885, 375, 199 }, { 291, 314, 368 } }
D.Links[18] = { { 29, 350, 3 }, { 765, 475, 34 }, { 932, 447, 30 } }
D.Links[19] = { { 758, 35, 21 }, { 926, 331, 25 }, { 549, 736, 26 }, { 427, 547, 20 }, { 316, 726, 361 } }
D.Links[21] = { { 759, 735, 19 } }
D.Links[23] = { { 70, 378, 5 }, { 127, 654, 369 }, { 944, 340, 28 }, { 963, 588, 356 } }
D.Links[24] = { { 307, 503, 29 }, { 274, 627, 29 }, { 229, 722, 28 }, { 906, 202, 199 } }
D.Links[25] = { { 260, 684, 5 }, { 53, 213, 19 }, { 739, 109, 4 }, { 960, 148, 4 }, { 641, 619, 5 } }
D.Links[26] = { { 948, 408, 5 }, { 674, 48, 19 }, { 157, 199, 361 }, { 318, 703, 27 }, { 107, 303, 361 } }
D.Links[27] = { { 831, 340, 26 } }
D.Links[28] = { { 160, 277, 23 }, { 715, 625, 17 }, { 376, 535, 356 }, { 859, 150, 29 }, { 889, 63, 24 }, { 169, 664, 369 }, { 418, 697, 368 } }
D.Links[29] = { { 481, 691, 28 }, { 776, 82, 24 }, { 297, 188, 463 } }
D.Links[30] = { { 65, 352, 3 }, { 143, 533, 34 }, { 190, 632, 31 }, { 497, 696, 33 }, { 511, 201, 171 }, { 890, 171, 178 }, { 499, 72, 177 }, { 314, 406, 199 }, { 291, 221, 242 }, { 181, 91, 291 }, { 312, 723, 301 } }
D.Links[31] = { { 121, 155, 34 }, { 673, 487, 32 }, { 958, 456, 33 }, { 827, 696, 67 }, { 910, 128, 199 } }
D.Links[33] = { { 12, 490, 31 }, { 67, 405, 31 } }
D.Links[34] = { { 857, 325, 31 }, { 101, 322, 3 }, { 440, 191, 35 }, { 407, 549, 36 }, { 713, 508, 37 }, { 641, 328, 38 }, { 527, 436, 39 }, { 587, 406, 40 }, { 272, 313, 41 }, { 284, 427, 42 }, { 251, 609, 43 }, { 446, 313, 44 }, { 809, 107, 45 } }
D.Links[35] = { { 211, 275, 45 }, { 109, 556, 41 }, { 531, 575, 44 }, { 857, 575, 38 } }
D.Links[36] = { { 487, 55, 44 }, { 882, 439, 39 }, { 118, 466, 43 } }
D.Links[37] = { { 186, 80, 38 }, { 66, 173, 39 } }
D.Links[38] = { { 335, 714, 37 }, { 234, 576, 39 }, { 79, 302, 44 }, { 97, 83, 35 }, { 509, 46, 35 }, { 947, 348, 31 } }
D.Links[39] = { { 582, 98, 40 }, { 774, 120, 38 }, { 784, 303, 37 }, { 294, 681, 36 }, { 241, 249, 44 } }
D.Links[40] = { { 526, 163, 38 }, { 510, 596, 39 } }
D.Links[41] = { { 58, 380, 17 }, { 696, 139, 35 }, { 965, 422, 44 }, { 724, 621, 42 } }
D.Links[42] = { { 516, 29, 41 }, { 459, 697, 43 } }
D.Links[43] = { { 604, 112, 42 }, { 812, 334, 36 } }
D.Links[44] = { { 600, 38, 35 }, { 455, 152, 35 }, { 303, 296, 41 }, { 791, 296, 38 }, { 608, 592, 39 }, { 539, 722, 36 } }
D.Links[45] = { { 590, 686, 35 } }
D.Links[60] = { { 213, 138, 61 }, { 689, 651, 62 }, { 811, 135, 63 }, { 373, 297, 64 }, { 826, 269, 65 }, { 413, 100, 12 }, { 589, 160, 69 }, { 820, 551, 114 } }
D.Links[61] = { { 253, 165, 12 }, { 506, 81, 12 }, { 460, 352, 64 }, { 694, 653, 62 }, { 724, 184, 69 } }
D.Links[62] = { { 253, 253, 61 }, { 535, 155, 61 }, { 916, 227, 63 }, { 952, 397, 114 }, { 922, 606, 301 } }
D.Links[63] = { { 527, 239, 65 }, { 504, 738, 62 }, { 927, 587, 301 }, { 528, 320, 65 } }
D.Links[67] = { { 396, 61, 31 }, { 396, 328, 68 }, { 644, 580, 77 }, { 289, 627, 112 }, { 640, 630, 77 } }
D.Links[68] = { { 404, 64, 67 }, { 131, 416, 67 }, { 928, 254, 67 } }
D.Links[69] = { { 526, 632, 61 } }
D.Links[71] = { { 161, 77, 72 }, { 326, 226, 74 }, { 477, 338, 75 }, { 285, 586, 76 }, { 606, 553, 73 }, { 443, 39, 67 }, { 804, 75, 77 }, { 388, 130, 112 }, { 278, 675, 114 }, { 759, 699, 148 } }
D.Links[72] = { { 924, 683, 74 }, { 170, 390, 122 } }
D.Links[73] = { { 427, 44, 77 }, { 237, 264, 75 }, { 130, 673, 76 }, { 672, 695, 149 } }
D.Links[74] = { { 163, 50, 72 }, { 852, 460, 75 }, { 640, 729, 76 }, { 532, 60, 112 }, { 390, 636, 116 }, { 522, 436, 81 } }
D.Links[75] = { { 236, 313, 74 }, { 797, 72, 77 }, { 326, 706, 76 }, { 887, 366, 73 }, { 307, 39, 112 }, { 495, 84, 80 } }
D.Links[76] = { { 497, 42, 74 }, { 729, 162, 75 }, { 910, 353, 73 }, { 404, 426, 79 }, { 254, 410, 115 }, { 213, 146, 115 } }
D.Links[77] = { { 302, 34, 67 }, { 624, 735, 73 }, { 286, 575, 75 }, { 455, 374, 78 }, { 145, 140, 112 }, { 316, 88, 67 } }
D.Links[78] = { { 424, 45, 77 }, { 207, 301, 77 }, { 783, 568, 77 } }
D.Links[79] = { { 350, 60, 76 }, { 653, 719, 76 }, { 900, 321, 76 } }
D.Links[112] = { { 846, 331, 77 }, { 788, 705, 75 }, { 400, 547, 74 }, { 636, 427, 113 }, { 786, 60, 67 } }
D.Links[113] = { { 103, 543, 112 }, { 594, 725, 112 }, { 866, 404, 112 } }
D.Links[114] = { { 157, 447, 119 }, { 235, 333, 120 }, { 355, 194, 118 }, { 105, 281, 62 }, { 534, 146, 116 }, { 456, 339, 115 }, { 481, 426, 121 }, { 734, 312, 71 }, { 738, 558, 117 }, { 361, 71, 122 }, { 144, 254, 123 }, { 509, 685, 125 }, { 875, 606, 148 } }
D.Links[115] = { { 276, 301, 120 }, { 276, 50, 118 }, { 511, 38, 116 }, { 712, 121, 71 }, { 415, 341, 121 }, { 703, 536, 117 }, { 537, 721, 130 }, { 536, 220, 244 }, { 141, 253, 120 } }
D.Links[116] = { { 861, 246, 74 }, { 124, 361, 118 }, { 412, 724, 115 }, { 47, 80, 122 } }
D.Links[117] = { { 195, 109, 115 }, { 930, 471, 149 }, { 110, 239, 243 } }
D.Links[118] = { { 748, 72, 116 }, { 833, 481, 115 }, { 462, 690, 120 }, { 517, 42, 122 }, { 305, 104, 123 } }
D.Links[119] = { { 525, 44, 120 }, { 537, 624, 213 } }
D.Links[120] = { { 866, 336, 115 }, { 286, 404, 119 }, { 508, 61, 118 }, { 196, 88, 62 }, { 250, 38, 123 } }
D.Links[121] = { { 901, 250, 115 } }
D.Links[122] = { { 764, 713, 118 }, { 877, 568, 116 }, { 928, 213, 72 }, { 874, 714, 118 } }
D.Links[123] = { { 501, 732, 120 }, { 531, 225, 9002 }, { 813, 272, 118 } }
D.Links[124] = { { 461, 88, 301 }, { 386, 469, 125 }, { 871, 139, 131 }, { 579, 521, 132 }, { 791, 471, 138 }, { 843, 378, 142 }, { 763, 282, 147 }, { 771, 391, 145 }, { 563, 215, 148 }, { 944, 358, 152 }, { 903, 161, 159 }, { 167, 369, 399 }, { 964, 448, 202 } }
D.Links[125] = { { 562, 39, 130 }, { 579, 241, 126 }, { 724, 339, 129 }, { 579, 643, 127 }, { 441, 576, 128 }, { 945, 479, 132 }, { 522, 723, 151 } }
D.Links[126] = { { 614, 52, 130 }, { 832, 379, 129 }, { 629, 732, 127 } }
D.Links[127] = { { 630, 36, 126 }, { 952, 179, 129 }, { 484, 314, 128 }, { 551, 532, 151 } }
D.Links[128] = { { 939, 493, 127 } }
D.Links[129] = { { 286, 61, 126 }, { 413, 691, 127 }, { 887, 564, 133 } }
D.Links[130] = { { 654, 43, 115 }, { 638, 732, 126 } }
D.Links[132] = { { 97, 123, 125 }, { 316, 92, 133 }, { 282, 551, 136 }, { 620, 296, 134 }, { 823, 541, 135 }, { 938, 435, 138 }, { 107, 431, 151 } }
D.Links[133] = { { 172, 146, 129 }, { 586, 708, 136 } }
D.Links[134] = { { 95, 285, 136 }, { 841, 580, 135 }, { 960, 370, 139 } }
D.Links[135] = { { 282, 72, 134 }, { 916, 57, 139 } }
D.Links[136] = { { 963, 446, 134 }, { 477, 44, 133 }, { 365, 362, 151 } }
D.Links[138] = { { 129, 696, 135 }, { 280, 644, 139 }, { 373, 533, 141 }, { 823, 286, 140 }, { 738, 93, 142 }, { 90, 641, 132 }, { 499, 153, 145 }, { 573, 46, 147 }, { 579, 261, 146 }, { 900, 46, 154 } }
D.Links[139] = { { 902, 300, 141 }, { 198, 556, 134 }, { 313, 637, 135 } }
D.Links[140] = { { 661, 109, 142 }, { 305, 652, 141 }, { 332, 283, 145 }, { 471, 225, 146 }, { 440, 47, 147 }, { 862, 47, 154 } }
D.Links[141] = { { 355, 568, 139 }, { 828, 490, 140 }, { 870, 99, 146 } }
D.Links[142] = { { 879, 474, 140 }, { 94, 453, 146 } }
D.Links[144] = { { 354, 700, 146 }, { 717, 714, 142 }, { 218, 75, 150 } }
D.Links[145] = { { 922, 388, 146 } }
D.Links[146] = { { 436, 45, 144 }, { 867, 194, 142 }, { 307, 724, 141 }, { 333, 374, 145 }, { 452, 376, 145 } }
D.Links[147] = { { 531, 352, 144 }, { 449, 468, 146 }, { 628, 465, 142 }, { 305, 675, 138 }, { 675, 662, 140 }, { 265, 58, 148 }, { 641, 84, 154 }, { 368, 547, 145 } }
D.Links[148] = { { 956, 505, 147 }, { 302, 44, 71 }, { 89, 229, 114 }, { 206, 484, 149 }, { 785, 307, 150 } }
D.Links[149] = { { 133, 354, 117 }, { 463, 86, 73 }, { 875, 535, 150 } }
D.Links[150] = { { 803, 253, 144 }, { 67, 97, 149 } }
D.Links[151] = { { 400, 157, 127 }, { 916, 176, 132 }, { 394, 292, 9003 } }
D.Links[152] = { { 84, 293, 124 }, { 203, 97, 159 }, { 179, 333, 154 }, { 375, 58, 30 }, { 417, 233, 161 }, { 286, 435, 202 }, { 82, 70, 301 } }
D.Links[153] = { { 425, 61, 147 }, { 794, 78, 154 }, { 778, 328, 156 }, { 375, 461, 157 }, { 782, 674, 138 } }
D.Links[154] = { { 269, 430, 147 }, { 366, 606, 153 }, { 513, 631, 156 }, { 260, 719, 157 }, { 640, 28, 159 }, { 821, 682, 202 }, { 682, 732, 140 } }
D.Links[156] = { { 94, 445, 153 }, { 953, 486, 154 } }
D.Links[157] = { { 933, 388, 153 } }
D.Links[159] = { { 331, 718, 154 }, { 812, 733, 161 } }
D.Links[161] = { { 226, 63, 163 }, { 240, 455, 164 }, { 676, 619, 165 }, { 907, 371, 166 }, { 571, 351, 168 }, { 604, 188, 167 }, { 86, 55, 159 }, { 243, 656, 202 } }
D.Links[163] = { { 114, 51, 159 }, { 392, 723, 164 }, { 810, 696, 167 } }
D.Links[164] = { { 254, 45, 163 }, { 551, 124, 167 }, { 857, 538, 165 }, { 379, 671, 202 } }
D.Links[165] = { { 149, 228, 167 }, { 216, 561, 164 }, { 823, 341, 166 }, { 934, 452, 169 } }
D.Links[166] = { { 311, 377, 167 }, { 405, 720, 165 } }
D.Links[167] = { { 76, 323, 163 }, { 67, 491, 164 }, { 212, 684, 165 }, { 881, 637, 166 }, { 684, 298, 204 } }
D.Links[168] = { { 671, 365, 170 } }
D.Links[171] = { { 440, 364, 172 }, { 876, 362, 178 }, { 695, 698, 30 }, { 100, 593, 199 }, { 490, 82, 177 }, { 729, 108, 181 }, { 740, 311, 175 }, { 714, 486, 176 } }
D.Links[172] = { { 287, 729, 171 } }
D.Links[173] = { { 1696, 557, 9001 } }
D.Links[177] = { { 937, 695, 171 }, { 797, 138, 183 }, { 213, 643, 242 }, { 89, 591, 263 }, { 392, 272, 180 }, { 108, 312, 179 } }
D.Links[178] = { { 73, 438, 171 } }
D.Links[179] = { { 287, 729, 177 } }
D.Links[180] = { { 287, 729, 177 } }
D.Links[181] = { { 538, 280, 173 }, { 542, 661, 171 }, { 94, 504, 355 } }
D.Links[183] = { { 882, 662, 177 } }
D.Links[199] = { { 351, 171, 24 }, { 851, 73, 171 }, { 446, 712, 31 }, { 586, 72, 242 }, { 272, 508, 17 } }
D.Links[202] = { { 477, 387, 203 }, { 280, 332, 154 }, { 651, 209, 205 }, { 817, 256, 161 }, { 92, 232, 236 } }
D.Links[203] = { { 151, 121, 202 } }
D.Links[205] = { { 694, 67, 236 }, { 816, 376, 235 }, { 211, 484, 202 } }
D.Links[213] = { { 198, 232, 119 } }
D.Links[242] = { { 748, 706, 199 }, { 775, 66, 177 }, { 617, 48, 263 }, { 253, 347, 392 } }
D.Links[243] = { { 663, 166, 117 }, { 132, 142, 121 } }
D.Links[244] = { { 883, 603, 115 } }
D.Links[263] = { { 771, 732, 242 }, { 940, 619, 177 }, { 254, 378, 291 }, { 530, 45, 298 } }
D.Links[280] = { { 348, 320, 19 }, { 192, 652, 26 }, { 926, 92, 25 }, { 893, 600, 5 } }
D.Links[288] = { { 936, 614, 31 } }
D.Links[291] = { { 190, 59, 4 }, { 404, 107, 298 }, { 154, 437, 299 }, { 337, 549, 292 }, { 595, 721, 242 }, { 691, 549, 263 }, { 916, 628, 177 } }
D.Links[292] = { { 547, 116, 299 }, { 352, 238, 296 }, { 311, 526, 297 }, { 672, 700, 295 }, { 897, 656, 291 }, { 872, 515, 293 }, { 861, 356, 294 }, { 820, 142, 298 } }
D.Links[293] = { { 283, 45, 294 }, { 79, 576, 295 }, { 641, 550, 263 } }
D.Links[294] = { { 561, 112, 298 }, { 341, 720, 293 } }
D.Links[295] = { { 174, 372, 297 }, { 957, 288, 293 }, { 873, 62, 294 } }
D.Links[296] = { { 873, 179, 299 }, { 516, 714, 297 } }
D.Links[297] = { { 490, 51, 296 }, { 934, 651, 295 } }
D.Links[298] = { { 127, 169, 4 }, { 680, 685, 263 }, { 210, 508, 299 }, { 347, 624, 294 } }
D.Links[299] = { { 757, 76, 298 }, { 488, 365, 296 } }
D.Links[301] = { { 569, 49, 30 }, { 746, 66, 33 }, { 67, 419, 61 }, { 280, 474, 120 }, { 582, 624, 117 }, { 628, 705, 124 }, { 72, 243, 3 }, { 950, 596, 152 }, { 255, 66, 24 }, { 176, 322, 65 }, { 422, 500, 121 }, { 598, 130, 67 }, { 214, 542, 119 }, { 650, 230, 77 }, { 512, 174, 112 }, { 500, 315, 74 }, { 476, 379, 116 }, { 646, 447, 73 }, { 341, 371, 118 }, { 411, 448, 115 }, { 624, 327, 75 }, { 592, 520, 76 }, { 187, 376, 63 }, { 120, 478, 62 }, { 366, 262, 72 } }
D.Links[355] = { { 672, 580, 181 } }
D.Links[356] = { { 95, 151, 23 }, { 808, 443, 17 }, { 916, 151, 28 }, { 64, 437, 369 }, { 439, 694, 368 } }
D.Links[361] = { { 75, 369, 13 }, { 710, 689, 26 }, { 934, 314, 19 } }
D.Links[368] = { { 310, 564, 370 }, { 688, 67, 356 }, { 823, 278, 17 }, { 753, 570, 12 }, { 214, 340, 369 } }
D.Links[369] = { { 211, 52, 5 }, { 584, 49, 23 }, { 59, 351, 26 }, { 687, 713, 368 }, { 894, 368, 28 }, { 825, 282, 17 } }
D.Links[370] = { { 928, 162, 368 } }
D.Links[380] = { { 301, 680, 4 } }
D.Links[386] = { { 860, 416, 387 }, { 784, 484, 388 }, { 639, 498, 389 }, { 720, 547, 390 }, { 935, 336, 153 }, { 125, 428, 398 }, { 125, 703, 403 }, { 474, 381, 393 }, { 474, 487, 395 }, { 370, 267, 394 }, { 250, 166, 396 }, { 77, 249, 399 }, { 257, 611, 397 } }
D.Links[387] = { { 367, 598, 388 }, { 906, 87, 153 } }
D.Links[388] = { { 933, 228, 387 }, { 115, 500, 389 }, { 238, 635, 390 } }
D.Links[389] = { { 894, 207, 388 }, { 809, 595, 390 }, { 200, 374, 395 } }
D.Links[390] = { { 888, 246, 388 }, { 134, 405, 389 } }
D.Links[392] = { { 929, 565, 242 } }
D.Links[393] = { { 513, 702, 395 }, { 847, 505, 386 }, { 125, 58, 394 } }
D.Links[394] = { { 240, 713, 397 }, { 862, 659, 393 }, { 857, 481, 386 }, { 219, 81, 396 } }
D.Links[395] = { { 77, 190, 397 }, { 549, 50, 393 }, { 874, 415, 389 }, { 853, 682, 386 } }
D.Links[396] = { { 560, 720, 397 }, { 173, 677, 399 }, { 796, 624, 386 }, { 860, 487, 394 } }
D.Links[397] = { { 221, 69, 399 }, { 364, 170, 398 }, { 638, 39, 396 }, { 845, 47, 394 }, { 898, 150, 386 }, { 928, 324, 395 }, { 190, 671, 403 } }
D.Links[398] = { { 858, 675, 397 } }
D.Links[399] = { { 474, 282, 400 }, { 467, 534, 401 }, { 943, 503, 386 }, { 187, 735, 403 } }
D.Links[400] = { { 870, 693, 399 }, { 597, 716, 401 } }
D.Links[401] = { { 833, 173, 399 }, { 576, 84, 400 }, { 931, 524, 386 }, { 165, 682, 403 } }
D.Links[403] = { { 382, 80, 399 }, { 793, 277, 386 }, { 880, 681, 404 } }
D.Links[404] = { { 119, 112, 403 }, { 673, 413, 405 }, { 918, 137, 419 }, { 956, 361, 420 }, { 912, 602, 422 } }
D.Links[405] = { { 608, 264, 412 }, { 550, 147, 412 }, { 718, 273, 409 }, { 690, 495, 407 }, { 454, 503, 410 }, { 547, 276, 411 }, { 591, 561, 410 }, { 680, 181, 409 }, { 589, 364, 408 }, { 538, 195, 411 }, { 633, 418, 408 } }
D.Links[407] = { { 632, 549, 405 }, { 378, 627, 405 }, { 532, 689, 405 }, { 474, 98, 405 }, { 655, 123, 405 }, { 438, 175, 405 }, { 796, 632, 405 }, { 564, 180, 405 }, { 543, 234, 405 }, { 307, 556, 410 }, { 385, 281, 411 }, { 754, 296, 405 }, { 552, 53, 412 }, { 798, 202, 409 }, { 536, 373, 405 }, { 736, 500, 408 } }
D.Links[408] = { { 774, 590, 405 }, { 576, 158, 405 }, { 228, 246, 407 }, { 361, 563, 410 }, { 444, 79, 411 }, { 786, 87, 409 }, { 619, 67, 412 } }
D.Links[409] = { { 682, 471, 405 }, { 463, 102, 405 }, { 736, 636, 407 }, { 305, 260, 412 }, { 244, 639, 408 } }
D.Links[410] = { { 768, 578, 405 }, { 371, 407, 405 }, { 155, 647, 407 }, { 727, 185, 408 } }
D.Links[411] = { { 649, 432, 405 }, { 589, 148, 405 }, { 356, 577, 407 }, { 810, 156, 412 }, { 830, 703, 408 } }
D.Links[412] = { { 622, 291, 405 }, { 594, 402, 405 }, { 458, 134, 405 }, { 327, 599, 407 }, { 393, 416, 411 }, { 814, 528, 409 }, { 625, 688, 408 } }
D.Links[419] = { { 104, 167, 404 }, { 271, 248, 420 }, { 710, 292, 421 }, { 300, 546, 422 }, { 641, 544, 423 }, { 657, 695, 440 }, { 527, 713, 443 }, { 846, 724, 446 } }
D.Links[420] = { { 110, 245, 404 }, { 918, 427, 421 }, { 316, 686, 422 }, { 922, 659, 423 } }
D.Links[421] = { { 104, 458, 420 }, { 124, 720, 422 }, { 392, 703, 423 }, { 128, 200, 419 }, { 869, 614, 446 } }
D.Links[422] = { { 226, 46, 404 }, { 450, 171, 420 }, { 824, 93, 421 }, { 867, 363, 423 }, { 865, 662, 440 }, { 576, 721, 443 }, { 193, 709, 419 } }
D.Links[423] = { { 157, 144, 420 }, { 704, 84, 421 }, { 204, 549, 422 }, { 558, 721, 440 }, { 346, 701, 443 }, { 826, 695, 446 }, { 217, 54, 419 } }
D.Links[440] = { { 70, 144, 404 }, { 579, 195, 419 }, { 191, 397, 441 }, { 406, 356, 443 }, { 637, 376, 444 }, { 832, 205, 446 }, { 213, 646, 458 } }
D.Links[441] = { { 519, 84, 404 }, { 725, 153, 422 }, { 860, 455, 443 }, { 564, 662, 442 }, { 378, 716, 458 } }
D.Links[442] = { { 721, 67, 441 }, { 933, 109, 443 }, { 700, 681, 458 } }
D.Links[443] = { { 199, 434, 441 }, { 368, 116, 422 }, { 779, 59, 423 }, { 848, 223, 444 } }
D.Links[444] = { { 244, 583, 445 }, { 138, 68, 422 }, { 274, 118, 423 }, { 165, 334, 443 }, { 794, 134, 446 } }
D.Links[445] = { { 855, 61, 444 } }
D.Links[446] = { { 169, 329, 423 }, { 191, 609, 444 } }
D.Links[447] = { { 102, 412, 421 }, { 332, 707, 446 } }
D.Links[458] = { { 508, 49, 441 }, { 902, 81, 440 } }
D.Links[463] = { { 790, 526, 29 }, { 795, 95, 24 }, { 193, 348, 28 } }
D.Links[9001] = { { 800, 764, 173 } }
D.Links[9003] = { { 446, 144, 127 }, { 968, 372, 132 } }

-- zona del mapa del mundo a la que pertenece cada mapa (los de region no tienen)
D.MapZone[1] = "Ettenmoors (PvMP)"
D.MapZone[4] = "Angmar"
D.MapZone[5] = "Bree-land"
D.MapZone[6] = "Bree-land"
D.MapZone[7] = "Bree-land"
D.MapZone[8] = "Bree-land"
D.MapZone[9] = "Bree-land"
D.MapZone[10] = "Bree-land"
D.MapZone[11] = "Bree-land"
D.MapZone[12] = "Enedwaith"
D.MapZone[13] = "Ered Luin"
D.MapZone[14] = "Ered Luin"
D.MapZone[15] = "Ered Luin"
D.MapZone[16] = "Ered Luin"
D.MapZone[17] = "Eregion"
D.MapZone[18] = "Eregion"
D.MapZone[19] = "Evendim"
D.MapZone[20] = "Evendim"
D.MapZone[21] = "Forochel"
D.MapZone[22] = "Forochel"
D.MapZone[23] = "Lone-lands"
D.MapZone[24] = "Misty Mountains"
D.MapZone[25] = "North Downs"
D.MapZone[26] = "The Shire"
D.MapZone[27] = "The Shire"
D.MapZone[28] = "Trollshaws"
D.MapZone[29] = "Trollshaws"
D.MapZone[31] = "Lothlorien"
D.MapZone[32] = "Lothlorien"
D.MapZone[33] = "Mirkwood"
D.MapZone[34] = "Moria"
D.MapZone[35] = "Moria"
D.MapZone[36] = "Moria"
D.MapZone[37] = "Moria"
D.MapZone[38] = "Moria"
D.MapZone[39] = "Moria"
D.MapZone[40] = "Moria"
D.MapZone[41] = "Moria"
D.MapZone[42] = "Moria"
D.MapZone[43] = "Moria"
D.MapZone[44] = "Moria"
D.MapZone[45] = "Moria"
D.MapZone[61] = "Dunland"
D.MapZone[62] = "Gap of Rohan"
D.MapZone[63] = "Nan Curunir"
D.MapZone[64] = "Dunland"
D.MapZone[65] = "Nan Curunir"
D.MapZone[67] = "Great River"
D.MapZone[68] = "Great River"
D.MapZone[71] = "East Rohan"
D.MapZone[72] = "East Rohan"
D.MapZone[73] = "East Rohan"
D.MapZone[74] = "East Rohan"
D.MapZone[75] = "East Rohan"
D.MapZone[76] = "East Rohan"
D.MapZone[77] = "East Rohan"
D.MapZone[78] = "East Rohan"
D.MapZone[79] = "East Rohan"
D.MapZone[80] = "East Rohan"
D.MapZone[81] = "East Rohan"
D.MapZone[112] = "Wildermore"
D.MapZone[113] = "Wildermore"
D.MapZone[114] = "West Rohan"
D.MapZone[115] = "West Rohan"
D.MapZone[116] = "West Rohan"
D.MapZone[117] = "West Rohan"
D.MapZone[118] = "West Rohan"
D.MapZone[119] = "West Rohan"
D.MapZone[120] = "West Rohan"
D.MapZone[121] = "West Rohan"
D.MapZone[122] = "West Rohan"
D.MapZone[123] = "Nan Curunir"
D.MapZone[125] = "Western Gondor"
D.MapZone[126] = "Western Gondor"
D.MapZone[127] = "Western Gondor"
D.MapZone[128] = "Western Gondor"
D.MapZone[129] = "Western Gondor"
D.MapZone[130] = "Western Gondor"
D.MapZone[131] = "Dead Marshes"
D.MapZone[132] = "Central Gondor"
D.MapZone[133] = "Central Gondor"
D.MapZone[134] = "Central Gondor"
D.MapZone[135] = "Central Gondor"
D.MapZone[136] = "Central Gondor"
D.MapZone[138] = "Eastern Gondor"
D.MapZone[139] = "Eastern Gondor"
D.MapZone[140] = "Eastern Gondor"
D.MapZone[141] = "Eastern Gondor"
D.MapZone[142] = "Eastern Gondor"
D.MapZone[144] = "Old Anorien"
D.MapZone[145] = "Old Anorien"
D.MapZone[146] = "Old Anorien"
D.MapZone[147] = "Old Anorien"
D.MapZone[148] = "Far Anorien"
D.MapZone[149] = "Far Anorien"
D.MapZone[150] = "Far Anorien"
D.MapZone[151] = "Western Gondor"
D.MapZone[153] = "North Ithilien"
D.MapZone[154] = "North Ithilien"
D.MapZone[156] = "North Ithilien"
D.MapZone[157] = "North Ithilien"
D.MapZone[159] = "The Wastes"
D.MapZone[161] = "Plateau of Gorgoroth"
D.MapZone[163] = "Plateau of Gorgoroth"
D.MapZone[164] = "Plateau of Gorgoroth"
D.MapZone[165] = "Plateau of Gorgoroth"
D.MapZone[166] = "Plateau of Gorgoroth"
D.MapZone[167] = "Plateau of Gorgoroth"
D.MapZone[168] = "Plateau of Gorgoroth"
D.MapZone[169] = "Plateau of Gorgoroth"
D.MapZone[170] = "Plateau of Gorgoroth"
D.MapZone[171] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[172] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[173] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[174] = "Mirkwood"
D.MapZone[175] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[176] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[177] = "Ered Mithrin and Withered Heath"
D.MapZone[178] = "Iron Hills"
D.MapZone[179] = "Ered Mithrin and Withered Heath"
D.MapZone[180] = "Ered Mithrin and Withered Heath"
D.MapZone[181] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[183] = "Ered Mithrin and Withered Heath"
D.MapZone[199] = "Vales of Anduin"
D.MapZone[202] = "Morgul Vale"
D.MapZone[203] = "Morgul Vale"
D.MapZone[204] = "Mordor Besieged"
D.MapZone[205] = "Morgul Vale"
D.MapZone[213] = "West Rohan"
D.MapZone[235] = "Morgul Vale"
D.MapZone[236] = "Morgul Vale"
D.MapZone[242] = "Wells of Langflood"
D.MapZone[243] = "West Rohan"
D.MapZone[244] = "West Rohan"
D.MapZone[263] = "Elderslade"
D.MapZone[280] = "The Wildwood"
D.MapZone[288] = "Azanulbizar"
D.MapZone[291] = "Gundabad"
D.MapZone[292] = "Gundabad"
D.MapZone[293] = "Gundabad"
D.MapZone[294] = "Gundabad"
D.MapZone[295] = "Gundabad"
D.MapZone[296] = "Gundabad"
D.MapZone[297] = "Gundabad"
D.MapZone[298] = "Gundabad"
D.MapZone[299] = "Gundabad"
D.MapZone[355] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[356] = "The Angle of Mitheithel"
D.MapZone[361] = "The Yondershire"
D.MapZone[368] = "Swanfleet"
D.MapZone[369] = "Cardolan"
D.MapZone[370] = "Swanfleet"
D.MapZone[380] = "Angmar"
D.MapZone[386] = "King's Gondor"
D.MapZone[387] = "King's Gondor"
D.MapZone[388] = "King's Gondor"
D.MapZone[389] = "King's Gondor"
D.MapZone[390] = "King's Gondor"
D.MapZone[392] = "Wells of Langflood"
D.MapZone[393] = "King's Gondor"
D.MapZone[394] = "King's Gondor"
D.MapZone[395] = "King's Gondor"
D.MapZone[396] = "King's Gondor"
D.MapZone[397] = "King's Gondor"
D.MapZone[398] = "King's Gondor"
D.MapZone[399] = "Outer Gondor"
D.MapZone[400] = "Outer Gondor"
D.MapZone[401] = "Outer Gondor"
D.MapZone[403] = "The Shield Isles"
D.MapZone[404] = "Cape of Umbar"
D.MapZone[405] = "Cape of Umbar"
D.MapZone[407] = "Cape of Umbar"
D.MapZone[408] = "Cape of Umbar"
D.MapZone[409] = "Cape of Umbar"
D.MapZone[410] = "Cape of Umbar"
D.MapZone[411] = "Cape of Umbar"
D.MapZone[412] = "Cape of Umbar"
D.MapZone[419] = "Valley of Ikorban"
D.MapZone[420] = "Valley of Ikorban"
D.MapZone[421] = "Valley of Ikorban"
D.MapZone[422] = "Valley of Ikorban"
D.MapZone[423] = "Valley of Ikorban"
D.MapZone[440] = "Mûr Ghala"
D.MapZone[441] = "Mûr Ghala"
D.MapZone[442] = "Mûr Ghala"
D.MapZone[443] = "Mûr Ghala"
D.MapZone[444] = "Mûr Ghala"
D.MapZone[445] = "Mûr Ghala"
D.MapZone[446] = "Mûr Ghala"
D.MapZone[447] = "Sug Nidar"
D.MapZone[458] = "The Hatokali Fells"
D.MapZone[463] = "Trollshaws"
D.MapZone[9001] = "Eryn Lasgalen and the Dale-lands"
D.MapZone[9002] = "Nan Curunir"
D.MapZone[9003] = "Western Gondor"

D.Pois[1] = {
    { "s", 690, 708, "Ettenmoors", "" },
}
D.Pois[4] = {
    { "r", 960, 108, "The Rift of Nûrz Ghâshu", "La Grieta de Nûrz Ghâshu" },
    { "d", 733, 279, "Barad Gúlaran", "" },
    { "d", 319, 136, "Carn Dûm", "" },
    { "d", 350, 168, "Urugarth", "" },
    { "e", 536, 504, "Epilogue: Amardam, the Ancient Evil", "", "Nemesis|100" },
    { "s", 952, 138, "", "" },
    { "s", 118, 517, "Aughaire", "" },
    { "s", 564, 637, "Gabilshathûr", "" },
    { "s", 655, 147, "Gath Forthnír", "" },
    { "t", 694, 178, "Angmar", "" },
    { "t", 994, 150, "Treasure Cache", "" },
    { "t", 431, 259, "Treasure Cache", "" },
    { "t", 473, 346, "Treasure Cache", "" },
    { "t", 98, 374, "Treasure Cache", "" },
    { "t", 168, 290, "Treasure Cache", "" },
    { "t", 462, 84, "Treasure Cache", "" },
    { "t", 540, 88, "Treasure Cache", "" },
    { "t", 606, 56, "Treasure Cache", "" },
    { "t", 756, 354, "Treasure Cache", "" },
    { "t", 683, 567, "Treasure Cache", "" },
    { "t", 218, 536, "Treasure Cache", "" },
}
D.Pois[5] = {
    { "c", 536, 507, "Bree", "" },
    { "d", 377, 627, "The Great Barrow", "El Gran Túmulo" },
    { "s", 666, 702, "", "", "far" },
    { "s", 479, 485, "West Bree", "" },
    { "s", 501, 533, "", "", "far" },
    { "s", 492, 247, "Hengstacer Farm", "" },
    { "s", 555, 564, "South Bree", "" },
    { "s", 586, 454, "Combe", "" },
    { "s", 179, 598, "Buckland", "" },
    { "s", 351, 474, "Adso's Camp", "" },
    { "s", 83, 196, "Dwaling", "" },
    { "s", 103, 570, "Stock", "" },
    { "s", 880, 646, "The Forsaken Inn", "" },
}
D.Pois[8] = {
    { "d", 337, 192, "The Great Barrow", "El Gran Túmulo" },
}
D.Pois[9] = {
    { "c", 544, 320, "Bree", "" },
    { "s", 283, 221, "", "" },
    { "s", 386, 434, "", "", "far" },
    { "s", 631, 574, "South Bree", "" },
    { "s", 772, 80, "Combe", "" },
    { "s", 304, 215, "West Bree", "" },
}
D.Pois[10] = {
    { "s", 549, 397, "", "", "far" },
}
D.Pois[11] = {
    { "d", 748, 369, "The Great Barrow", "El Gran Túmulo" },
    { "s", 268, 299, "Buckland", "" },
}
D.Pois[12] = {
    { "r", 878, 398, "Draigoch's Lair", "Guarida de Draigoch" },
    { "r", 486, 638, "Ost Dunhoth", "" },
    { "s", 642, 137, "Echad Dagoras", "" },
    { "s", 381, 268, "Maur Tulhau", "" },
    { "s", 433, 379, "Echad Daervunn", "" },
    { "s", 665, 463, "Thrór's Coomb", "" },
    { "s", 603, 701, "Echad Naeglanc", "" },
    { "s", 573, 389, "Lhanuch", "" },
    { "s", 405, 641, "Trum Dreng", "" },
}
D.Pois[13] = {
    { "c", 293, 103, "Thorin's Gate", "Mansión de Thorin" },
    { "s", 275, 110, "Thorin's Gate", "", "far" },
    { "s", 558, 347, "Gondamon", "", "far" },
    { "s", 836, 586, "", "", "far" },
    { "s", 91, 123, "", "", "far" },
    { "s", 405, 303, "Noglond", "" },
    { "s", 515, 259, "", "" },
    { "s", 728, 519, "Duillond", "" },
    { "s", 765, 682, "Celondim", "" },
    { "s", 688, 400, "Thrasi's Lodge", "" },
}
D.Pois[14] = {
    { "s", 517, 290, "", "", "far" },
}
D.Pois[15] = {
    { "c", 453, 464, "Thorin's Gate", "Mansión de Thorin" },
    { "s", 402, 484, "Thorin's Gate", "", "far" },
}
D.Pois[16] = {
    { "s", 393, 407, "", "", "far" },
}
D.Pois[17] = {
    { "d", 326, 560, "Library at Tham Mírdain", "Biblioteca en Tham Mírdain" },
    { "d", 401, 542, "School at Tham Mírdain", "Escuela en Tham Mírdain" },
    { "s", 347, 506, "Echad Mirobel", "" },
    { "s", 675, 446, "Echad Dúnann", "" },
    { "s", 382, 74, "Gwingris", "" },
    { "s", 506, 319, "Echad Eregion", "" },
}
D.Pois[18] = {
    { "s", 152, 292, "Echad Dúnann", "" },
}
D.Pois[19] = {
    { "c", 493, 359, "Tinnudir", "" },
    { "d", 458, 598, "Annúminas: Glinghant", "" },
    { "d", 434, 501, "Annúminas: Haudh Valandil", "" },
    { "d", 447, 478, "Annúminas: Ost Elendil", "" },
    { "d", 491, 716, "The Northcotton Farm", "La Granja de Cotonorte" },
    { "s", 604, 648, "Dwaling", "" },
    { "s", 625, 413, "High King's Crossing", "" },
    { "s", 395, 591, "Annúminas", "" },
    { "s", 512, 736, "Oatbarton", "" },
    { "s", 616, 223, "Ost Forod", "" },
    { "s", 518, 365, "Tinnudir", "" },
    { "t", 303, 412, "Treasure Cache", "" },
    { "t", 346, 348, "Treasure Cache", "" },
    { "t", 245, 220, "Treasure Cache", "" },
    { "t", 481, 200, "Treasure Cache", "" },
    { "t", 525, 240, "Treasure Cache", "" },
    { "t", 572, 89, "Treasure Cache", "" },
    { "t", 700, 213, "Treasure Cache", "" },
    { "t", 660, 264, "Treasure Cache", "" },
    { "t", 737, 628, "Treasure Cache", "" },
    { "t", 606, 611, "Treasure Cache", "" },
    { "t", 572, 527, "Treasure Cache", "" },
    { "t", 427, 480, "Treasure Cache", "" },
}
D.Pois[20] = {
    { "d", 602, 512, "Annúminas: Glinghant", "" },
    { "d", 521, 108, "Annúminas: Haudh Valandil", "" },
    { "d", 548, 55, "Annúminas: Ost Elendil", "" },
    { "s", 353, 486, "Annúminas", "" },
    { "t", 481, 41, "Treasure Cache", "" },
}
D.Pois[21] = {
    { "c", 540, 144, "Suri-kylä", "Sûri-kylä" },
    { "d", 647, 445, "Agoroth, the Narrowdelve", "Agoroth, el Narrowdelve" },
    { "d", 348, 121, "Sâri-surma", "" },
    { "s", 226, 137, "Kuru-leiri", "" },
    { "s", 868, 559, "Kauppa-kohta", "" },
    { "s", 582, 342, "Pynti-peldot", "" },
    { "s", 550, 146, "Sûri-kylä", "" },
    { "s", 291, 384, "Zigilgund", "" },
    { "t", 326, 470, "Forochel", "" },
    { "t", 346, 422, "Forochel", "" },
    { "t", 676, 364, "Treasure Cache", "" },
    { "t", 433, 277, "Treasure Cache", "" },
    { "t", 549, 399, "Treasure Cache", "" },
    { "t", 386, 502, "Treasure Cache", "" },
    { "t", 263, 394, "Treasure Cache", "" },
    { "t", 113, 234, "Treasure Cache", "" },
    { "t", 188, 121, "Treasure Cache", "" },
    { "t", 466, 119, "Treasure Cache", "" },
    { "t", 576, 309, "Treasure Cache", "" },
    { "t", 616, 231, "Treasure Cache", "" },
}
D.Pois[23] = {
    { "c", 664, 331, "Ost Guruth", "" },
    { "d", 910, 212, "Garth Agarwen", "" },
    { "d", 137, 459, "Inn of the Forsaken", "Posada de los abandonados" },
    { "s", 144, 478, "The Forsaken Inn", "" },
    { "s", 270, 274, "Candaith's Encampment", "" },
    { "s", 654, 369, "Ost Guruth", "" },
    { "s", 978, 431, "The Last Bridge", "" },
}
D.Pois[24] = {
    { "c", 274, 627, "Rivendell", "Rivendel" },
    { "r", 398, 136, "Helegrod", "" },
    { "d", 745, 297, "Goblin-town Throne Room\nSeat of the Great Goblin", "Sala del Trono de Ciudad de los Trasgos\nAsiento del Gran Trasgo" },
    { "d", 724, 660, "Iorbar's Peak", "Pico de Iorbar" },
    { "s", 541, 414, "", "" },
    { "s", 665, 358, "", "" },
    { "s", 777, 406, "Hrimbarg", "", "far" },
    { "s", 324, 425, "Glóin's Camp", "" },
    { "s", 212, 606, "Rivendell", "" },
    { "t", 311, 359, "Misty Mountains", "" },
    { "t", 468, 433, "Misty Mountains", "" },
    { "t", 501, 693, "Misty Mountains", "" },
    { "t", 349, 243, "Treasure Cache", "" },
    { "t", 700, 256, "Treasure Cache", "" },
    { "t", 852, 297, "Treasure Cache", "" },
    { "t", 596, 347, "Treasure Cache", "" },
    { "t", 394, 380, "Treasure Cache", "" },
    { "t", 795, 384, "Treasure Cache", "" },
    { "t", 885, 474, "Treasure Cache", "" },
    { "t", 766, 565, "Treasure Cache", "" },
    { "t", 658, 573, "Treasure Cache", "" },
}
D.Pois[25] = {
    { "c", 683, 301, "Esteldín", "" },
    { "d", 184, 174, "Fornost", "" },
    { "d", 369, 297, "Stoneheight", "Altapiedra" },
    { "s", 220, 592, "", "" },
    { "s", 245, 603, "", "" },
    { "s", 285, 398, "Amon Raith", "" },
    { "s", 663, 304, "Esteldín", "" },
    { "s", 576, 445, "Lin Giliath", "" },
    { "s", 557, 203, "Othrikar", "" },
    { "t", 615, 170, "North Downs", "" },
    { "t", 735, 264, "Treasure Cache", "" },
    { "t", 967, 358, "Treasure Cache", "" },
    { "t", 877, 510, "Treasure Cache", "" },
    { "t", 830, 554, "Treasure Cache", "" },
    { "t", 703, 543, "Treasure Cache", "" },
    { "t", 510, 644, "Treasure Cache", "" },
    { "t", 238, 546, "Treasure Cache", "" },
    { "t", 318, 449, "Treasure Cache", "" },
    { "t", 71, 311, "Treasure Cache", "" },
    { "t", 256, 195, "Treasure Cache", "" },
    { "t", 452, 203, "Treasure Cache", "" },
}
D.Pois[26] = {
    { "c", 497, 411, "Hobbiton", "" },
    { "c", 278, 529, "Michel Delving", "Cavada Grande" },
    { "s", 353, 703, "", "", "far" },
    { "s", 227, 224, "Needlehole", "" },
    { "s", 260, 561, "Michel Delving", "" },
    { "s", 491, 416, "Hobbiton", "" },
    { "s", 659, 197, "Brockenborings", "" },
    { "s", 874, 450, "Stock", "" },
}
D.Pois[27] = {
    { "s", 657, 393, "", "", "far" },
}
D.Pois[28] = {
    { "c", 859, 150, "Rivendell", "Rivendel" },
    { "d", 577, 111, "Lost Temple", "Templo perdido" },
    { "s", 311, 316, "The Last Bridge", "" },
    { "s", 337, 354, "", "" },
    { "s", 417, 171, "North Trollshaws", "" },
    { "s", 301, 587, "Tornhad", "" },
    { "s", 878, 208, "Last Homely House", "" },
    { "s", 479, 472, "Tham Lumren", "" },
    { "s", 542, 159, "Nan Tornaeth", "" },
    { "s", 711, 356, "High Moor", "" },
    { "s", 799, 193, "Rivendell", "", "far" },
    { "s", 394, 334, "Barachan's Camp", "" },
    { "s", 574, 418, "Echad Candelleth", "" },
    { "s", 520, 520, "Gwingris", "" },
    { "s", 550, 265, "Thorenhad", "" },
}
D.Pois[29] = {
    { "c", 574, 290, "Rivendell", "Rivendel" },
    { "s", 635, 472, "Last Homely House", "" },
    { "s", 382, 424, "Rivendell", "", "far" },
}
D.Pois[31] = {
    { "c", 673, 487, "Caras Galadhon", "" },
    { "s", 587, 331, "Cerin Amroth", "" },
    { "s", 623, 476, "Inner Caras Galadhon", "" },
    { "s", 656, 550, "Caras Galadhon", "" },
    { "s", 801, 615, "The Vineyards of Lórien", "" },
    { "s", 410, 448, "Echad Andestel", "" },
    { "s", 167, 321, "Mekhem-bizru", "" },
}
D.Pois[32] = {
    { "c", 526, 429, "Caras Galadhon", "" },
    { "s", 319, 386, "Inner Caras Galadhon", "" },
    { "s", 456, 687, "Caras Galadhon", "" },
}
D.Pois[33] = {
    { "c", 524, 408, "Ost Galadh", "" },
    { "r", 923, 386, "Barad Guldur", "" },
    { "d", 951, 415, "Dungeons of Dol Guldur", "Mazmorras de Dol Guldur" },
    { "d", 933, 362, "Sammath Gûl", "" },
    { "d", 926, 422, "Sword-hall of Dol Guldur", "Sala de Espadas de Dol Guldur" },
    { "d", 830, 427, "Warg-pens of Dol Guldur", "Cercados de Huargos de Dol Guldur" },
    { "s", 68, 444, "Echad Sirion", "" },
    { "s", 293, 361, "The Haunted Inn", "" },
    { "s", 363, 522, "Estolad Mernael", "" },
    { "s", 521, 401, "Ost Galadh", "" },
    { "s", 649, 548, "Mithechad", "" },
    { "s", 747, 333, "Thangúlhad", "" },
    { "s", 817, 479, "Helethir", "" },
    { "t", 646, 634, "Southern Mirkwood", "" },
    { "t", 48, 535, "Treasure Cache", "" },
    { "t", 156, 472, "Treasure Cache", "" },
    { "t", 218, 618, "Treasure Cache", "" },
    { "t", 295, 260, "Treasure Cache", "" },
    { "t", 367, 314, "Treasure Cache", "" },
    { "t", 457, 359, "Treasure Cache", "" },
    { "t", 493, 147, "Treasure Cache", "" },
    { "t", 781, 305, "Treasure Cache", "" },
    { "t", 947, 422, "Treasure Cache", "" },
    { "t", 911, 495, "Treasure Cache", "" },
    { "t", 862, 625, "Treasure Cache", "" },
}
D.Pois[34] = {
    { "r", 750, 576, "Dâr Narbugud", "" },
    { "r", 242, 576, "Filikul", "" },
    { "r", 146, 612, "The Vile Maw", "La Fauce Vil" },
    { "d", 785, 511, "Askâd-mazal, the Chamber of Shadows", "Askâd-mazal, la Cámara de las Sombras" },
    { "d", 732, 558, "Dark Delvings", "Excavaciones Tenebrosas" },
    { "d", 366, 599, "Fil Gashan\nThe Forges of Khazad-dûm", "Fil Gashan\nLas Forjas de Khazad-dûm" },
    { "d", 365, 573, "Halls of Crafting", "Salones de Artesanía" },
    { "d", 641, 481, "Skûmfil", "" },
    { "d", 273, 414, "The Forgotten Treasury", "El Tesoro Olvidado" },
    { "d", 536, 390, "The Grand Stair", "La Gran Escalera" },
    { "d", 623, 417, "The Sixteenth Hall", "La Decimosexta Sala" },
    { "d", 270, 509, "The Water Wheels: Nalâ-dûm", "Las Ruedas de Agua: Nalâ-dûm" },
    { "s", 497, 262, "Twenty-first Hall", "", "far" },
    { "s", 294, 337, "", "", "far" },
    { "s", 422, 353, "Hall of Flowing Water", "" },
    { "s", 474, 196, "Jazârgund", "" },
    { "s", 515, 312, "Eastern Crossroads", "" },
    { "s", 553, 190, "The Fanged Pit", "" },
    { "s", 607, 360, "Second Hall Camp-site", "" },
    { "s", 672, 253, "Sudulthurkh Outpost", "" },
    { "s", 795, 324, "First Hall", "" },
    { "s", 146, 613, "The Vile Maw", "" },
    { "s", 250, 403, "Silvertine Work-site", "" },
    { "s", 277, 379, "Deep Descent", "" },
    { "s", 295, 539, "The Rotting Cellar", "" },
    { "s", 363, 571, "Hudnul-medem", "" },
    { "s", 171, 323, "Durin's Threshold", "" },
    { "s", 282, 338, "Dolven-view", "" },
    { "s", 290, 242, "Chamber of the Crossroads", "" },
    { "s", 328, 173, "Zirak-zigil", "" },
    { "s", 396, 182, "Tharâkh Bazân", "" },
    { "s", 413, 482, "Anazârmekhem", "" },
    { "s", 458, 416, "", "" },
    { "s", 616, 477, "Shadowed Refuge", "" },
    { "s", 731, 548, "Nameless Places", "" },
    { "s", 446, 418, "The Orc-watch", "" },
}
D.Pois[35] = {
    { "s", 562, 504, "Twenty-first Hall", "", "far" },
    { "s", 513, 364, "Jazârgund", "" },
    { "s", 602, 611, "Eastern Crossroads", "" },
    { "s", 681, 350, "The Fanged Pit", "" },
    { "s", 935, 484, "Sudulthurkh Outpost", "" },
    { "s", 121, 462, "Chamber of the Crossroads", "" },
    { "s", 203, 314, "Zirak-zigil", "" },
    { "s", 347, 333, "Tharâkh Bazân", "" },
}
D.Pois[36] = {
    { "d", 341, 640, "Fil Gashan", "" },
    { "d", 337, 548, "Halls of Crafting", "Salones de Artesanía" },
    { "d", 316, 628, "The Forges of Khazad-dûm", "Las Forjas de Khazad-dûm" },
    { "s", 327, 523, "Hudnul-medem", "" },
    { "s", 555, 117, "Anazârmekhem", "" },
}
D.Pois[37] = {
    { "r", 789, 752, "Dâr Narbugud", "" },
    { "d", 957, 477, "Askâd-mazal, the Chamber of Shadows", "Askâd-mazal, la Cámara de las Sombras" },
    { "d", 733, 698, "Dark Delvings", "Excavaciones Tenebrosas" },
    { "d", 320, 345, "Skûmfil", "" },
    { "s", 210, 329, "Shadowed Refuge", "" },
    { "s", 719, 644, "Nameless Places", "" },
}
D.Pois[38] = {
    { "d", 116, 565, "The Grand Stair", "La Gran Escalera" },
    { "d", 381, 647, "The Sixteenth Hall", "La Decimosexta Sala" },
    { "s", 53, 326, "Eastern Crossroads", "" },
    { "s", 333, 472, "Second Hall Camp-site", "" },
    { "s", 529, 144, "Sudulthurkh Outpost", "" },
    { "s", 903, 363, "First Hall", "" },
}
D.Pois[39] = {
    { "d", 561, 95, "The Grand Stair", "La Gran Escalera" },
    { "d", 869, 192, "The Sixteenth Hall", "La Decimosexta Sala" },
    { "s", 282, 189, "", "" },
    { "s", 242, 197, "The Orc-watch", "" },
}
D.Pois[41] = {
    { "s", 744, 490, "", "", "far" },
    { "s", 160, 425, "Durin's Threshold", "" },
    { "s", 687, 495, "Dolven-view", "" },
}
D.Pois[42] = {
    { "d", 478, 337, "The Forgotten Treasury", "El Tesoro Olvidado" },
    { "s", 370, 286, "Silvertine Work-site", "" },
    { "s", 499, 170, "Deep Descent", "" },
}
D.Pois[43] = {
    { "r", 500, 376, "Filikul", "" },
    { "r", 264, 467, "The Vile Maw", "La Fauce Vil" },
    { "d", 812, 429, "Fil Gashan", "" },
    { "d", 804, 378, "Halls of Crafting", "Salones de Artesanía" },
    { "d", 788, 419, "The Forges of Khazad-dûm", "Las Forjas de Khazad-dûm" },
    { "d", 570, 212, "The Water Wheels: Nalâ-dûm", "Las Ruedas de Agua: Nalâ-dûm" },
    { "s", 264, 469, "The Vile Maw", "" },
    { "s", 632, 285, "The Rotting Cellar", "" },
    { "s", 799, 364, "Hudnul-medem", "" },
}
D.Pois[44] = {
    { "s", 668, 151, "", "", "far" },
    { "s", 153, 340, "", "", "far" },
    { "s", 661, 138, "Twenty-first Hall", "" },
    { "s", 478, 381, "Hall of Flowing Water", "" },
    { "s", 716, 278, "Eastern Crossroads", "" },
    { "s", 455, 710, "Anazârmekhem", "" },
    { "s", 569, 543, "", "" },
    { "s", 540, 548, "The Orc-watch", "" },
}
D.Pois[45] = {
    { "d", 609, 257, "The Mirror-halls of Lumul-nar", "Las Salas de los Espejos de Lumul-nar" },
}
D.Pois[61] = {
    { "c", 460, 352, "Galtrev", "" },
    { "s", 458, 351, "Galtrev", "", "far" },
    { "s", 471, 531, "Barnavon", "" },
    { "s", 490, 248, "Echad Naeglanc", "" },
    { "s", 666, 287, "Tâl Methedras Gate", "" },
    { "s", 689, 386, "Rohirram Scout-camp", "" },
    { "s", 238, 171, "Trum Dreng", "" },
    { "s", 313, 485, "Avardin", "" },
    { "s", 216, 610, "Lhan Rhos", "" },
}
D.Pois[62] = {
    { "s", 891, 231, "Dagoras' Camp", "" },
    { "s", 231, 222, "Barnavon", "" },
    { "s", 869, 383, "Grimbold's Camp", "" },
    { "s", 682, 333, "Forthbrond", "" },
}
D.Pois[63] = {
    { "r", 733, 270, "The Tower of Orthanc", "La Torre de Orthanc" },
    { "d", 755, 285, "Dargnákh Unleashed\nThe Foundry", "Dargnákh desatado\nLa Fundición" },
    { "d", 730, 291, "Pits of Isengard", "Fosos de Isengard" },
    { "s", 453, 654, "Dagoras' Camp", "" },
}
D.Pois[64] = {
    { "c", 512, 313, "Galtrev", "" },
    { "s", 500, 304, "", "", "far" },
    { "s", 483, 285, "Galtrev", "" },
}
D.Pois[65] = {
    { "r", 883, 467, "The Tower of Orthanc", "La Torre de Orthanc" },
    { "d", 857, 473, "Pits of Isengard", "Fosos de Isengard" },
}
D.Pois[67] = {
    { "c", 377, 346, "Stangard", "" },
    { "s", 261, 315, "", "" },
    { "s", 395, 158, "", "" },
    { "s", 585, 353, "", "" },
    { "s", 703, 451, "", "" },
    { "s", 825, 528, "", "" },
    { "s", 413, 317, "Stangard", "" },
}
D.Pois[68] = {
    { "c", 423, 519, "Stangard", "" },
    { "s", 766, 244, "Stangard", "" },
}
D.Pois[71] = {
    { "c", 80, 650, "Edoras", "" },
    { "c", 613, 136, "Harwick", "" },
    { "c", 362, 653, "Snowbourn", "Río Nevado" },
    { "e", 717, 307, "Bughrakh", "", "Great Elite|77" },
    { "e", 488, 612, "Bugud", "", "Supreme Nemesis|85" },
    { "e", 553, 152, "Cinder", "", "Signature|77" },
    { "e", 476, 280, "Dahámab", "", "Signature|79" },
    { "e", 384, 404, "Dâl", "", "Great Elite|80" },
    { "e", 360, 403, "Fearrhorn\nUrgai", "", "Great Elite|80\nNemesis|81" },
    { "e", 407, 546, "Gundul", "", "Great Elite|85" },
    { "e", 580, 302, "Haglob", "", "Great Elite|79" },
    { "e", 644, 283, "Hanrun", "", "Signature|77" },
    { "e", 428, 617, "Kramp", "", "Great Elite|85" },
    { "e", 340, 279, "Mirz", "", "Elite|81" },
    { "e", 337, 262, "Mâthum", "", "Signature|80" },
    { "e", 557, 415, "Skútog", "", "Elite|79" },
    { "e", 558, 481, "Swertripeur", "", "Elite|79" },
    { "e", 712, 191, "Urush", "", "Signature|77" },
    { "s", 529, 570, "", "" },
    { "s", 626, 447, "East Wall Camp", "" },
    { "s", 207, 745, "", "", "far" },
    { "s", 222, 721, "", "" },
    { "s", 189, 377, "", "" },
    { "s", 241, 611, "", "" },
    { "s", 499, 236, "Cliving", "" },
    { "s", 333, 341, "Eaworth", "" },
    { "s", 79, 653, "Edoras", "" },
    { "s", 589, 368, "Elthengels", "" },
    { "s", 281, 539, "Entwade", "Vado del Entaguas" },
    { "s", 485, 511, "Faldham", "" },
    { "s", 702, 284, "Floodwend", "Recodo de la Crecida" },
    { "s", 375, 507, "Garsfeld", "" },
    { "s", 603, 132, "Harwick", "" },
    { "s", 121, 484, "Middlemead", "Prado Central" },
    { "s", 253, 298, "Oserley", "Mimbral" },
    { "s", 712, 603, "Parth Galen", "" },
    { "s", 388, 645, "Snowbourn", "Río Nevado" },
    { "s", 239, 216, "Thornhope", "" },
    { "s", 552, 679, "Walstow", "" },
}
D.Pois[72] = {
    { "s", 912, 627, "Thornhope", "" },
}
D.Pois[73] = {
    { "e", 306, 341, "Swertripeur", "", "Elite|79" },
    { "s", 253, 502, "", "" },
    { "s", 429, 280, "East Wall Camp", "" },
    { "s", 362, 138, "Elthengels", "" },
    { "s", 583, 561, "Parth Galen", "" },
}
D.Pois[74] = {
    { "e", 822, 307, "Dahámab", "", "Signature|79" },
    { "e", 633, 561, "Dâl", "", "Great Elite|80" },
    { "e", 582, 558, "Fearrhorn\nUrgai", "", "Great Elite|80\nNemesis|81" },
    { "e", 540, 305, "Mirz", "", "Elite|81" },
    { "e", 534, 272, "Mâthum", "", "Signature|80" },
    { "s", 527, 432, "Eaworth", "" },
    { "s", 362, 345, "Oserley", "Mimbral" },
    { "s", 333, 176, "Thornhope", "" },
}
D.Pois[75] = {
    { "e", 443, 155, "Dahámab", "", "Signature|79" },
    { "e", 648, 199, "Haglob", "", "Great Elite|79" },
    { "e", 601, 424, "Skútog", "", "Elite|79" },
    { "e", 604, 555, "Swertripeur", "", "Elite|79" },
    { "s", 739, 487, "East Wall Camp", "" },
    { "s", 488, 69, "Cliving", "" },
    { "s", 160, 276, "Eaworth", "" },
    { "s", 665, 331, "Elthengels", "" },
    { "s", 461, 613, "Faldham", "" },
}
D.Pois[76] = {
    { "c", 389, 436, "Snowbourn", "Río Nevado" },
    { "e", 660, 347, "Bugud", "", "Supreme Nemesis|85" },
    { "e", 487, 204, "Gundul", "", "Great Elite|85" },
    { "e", 532, 358, "Kramp", "", "Great Elite|85" },
    { "s", 749, 256, "", "" },
    { "s", 214, 189, "Entwade", "Vado del Entaguas" },
    { "s", 655, 127, "Faldham", "" },
    { "s", 417, 120, "Garsfeld", "" },
    { "s", 445, 419, "Snowbourn", "Río Nevado" },
    { "s", 799, 493, "Walstow", "" },
}
D.Pois[77] = {
    { "c", 508, 372, "Harwick", "" },
    { "e", 689, 665, "Bughrakh", "", "Great Elite|77" },
    { "e", 405, 400, "Cinder", "", "Signature|77" },
    { "e", 273, 619, "Dahámab", "", "Signature|79" },
    { "e", 562, 625, "Hanrun", "", "Signature|77" },
    { "e", 680, 466, "Urush", "", "Signature|77" },
    { "s", 312, 544, "Cliving", "" },
    { "s", 662, 625, "Floodwend", "Recodo de la Crecida" },
    { "s", 492, 365, "Harwick", "" },
}
D.Pois[78] = {
    { "c", 660, 334, "Harwick", "" },
    { "s", 563, 295, "Harwick", "" },
}
D.Pois[79] = {
    { "c", 392, 384, "Snowbourn", "Río Nevado" },
    { "s", 666, 302, "Snowbourn", "Río Nevado" },
}
D.Pois[112] = {
    { "c", 636, 427, "Forlaw", "" },
    { "e", 836, 554, "Arataus", "", "Great Elite|85" },
    { "e", 655, 305, "Balcharan", "", "Elite|85" },
    { "e", 547, 523, "Conog", "", "Supreme Nemesis|85" },
    { "e", 762, 363, "Foulwing", "", "Signature|85" },
    { "e", 571, 392, "Gîmtog", "", "Signature|85" },
    { "e", 392, 279, "High Knolls Blizzard", "", "Signature|85" },
    { "e", 571, 151, "Karkas", "", "Signature|85" },
    { "e", 234, 298, "Rottenheart", "", "Nemesis|85" },
    { "e", 828, 574, "Shaguk", "", "Supreme Nemesis|85" },
    { "e", 786, 605, "Shum", "", "Signature|85" },
    { "e", 307, 283, "Varg", "", "Great Elite|85" },
    { "e", 747, 433, "Voz", "", "Nemesis|85" },
    { "e", 638, 614, "Zovarr", "", "Nemesis|85" },
    { "s", 426, 229, "High Knolls", "" },
    { "s", 676, 257, "Scylfig", "" },
    { "s", 300, 321, "Balewood", "" },
    { "s", 405, 449, "Whitshaws", "" },
    { "s", 649, 479, "Forlaw", "" },
}
D.Pois[113] = {
    { "c", 427, 219, "Forlaw", "" },
    { "s", 533, 669, "Forlaw", "" },
}
D.Pois[114] = {
    { "c", 481, 426, "Edoras", "" },
    { "e", 173, 343, "Bethan, Priestess of Isengard", "", "Supreme Nemesis|95" },
    { "e", 294, 352, "Bosnauk", "", "Elite|95" },
    { "e", 761, 515, "Bûrzash", "", "Elite|88" },
    { "e", 489, 169, "Cledwun - Dunlending War-leader", "", "Great Elite|90" },
    { "e", 854, 565, "Darkheart", "", "Signature|88" },
    { "e", 683, 585, "Felljaw", "", "Elite|88" },
    { "e", 416, 279, "Geralht\nMacsen", "", "Elite|92\nSupreme Nemesis|92" },
    { "e", 459, 347, "Glendower", "", "Great Elite|87" },
    { "e", 363, 321, "Inras\nRog-Votak", "", "Signature|92\nNemesis|92" },
    { "e", 375, 382, "Krûpû and the Roving Orcs", "", "Great Elite|95" },
    { "e", 399, 205, "Neivion\nOgnir", "", "Nemesis|92\nElite|92" },
    { "e", 610, 284, "Nûdît", "", "Great Elite|86" },
    { "e", 629, 424, "Ora", "", "Great Elite|87" },
    { "e", 366, 458, "Patarshan", "", "Elite|95" },
    { "e", 725, 602, "Scion of the Great Boar", "", "Nemesis|88" },
    { "e", 684, 477, "Snapfang", "", "Signature|88" },
    { "e", 198, 296, "Voraut", "", "Signature|95" },
    { "s", 556, 488, "", "", "far" },
    { "s", 526, 336, "", "", "far" },
    { "s", 568, 469, "", "" },
    { "s", 156, 472, "Helm's Deep", "" },
    { "s", 652, 567, "Aldburg", "" },
    { "s", 778, 585, "Beaconwatch", "" },
    { "s", 385, 221, "Brockbridge", "" },
    { "s", 452, 414, "Edoras", "" },
    { "s", 616, 323, "Entwade", "" },
    { "s", 770, 525, "Fenmarch", "" },
    { "s", 268, 278, "Gapholt", "" },
    { "s", 301, 443, "Grimslade", "" },
    { "s", 485, 277, "Middlemead", "" },
    { "s", 593, 127, "Oserly", "" },
    { "s", 541, 191, "Stoke", "" },
    { "s", 462, 540, "Underharrow", "" },
    { "s", 358, 159, "Woodhurst", "" },
}
D.Pois[115] = {
    { "c", 431, 326, "Edoras", "" },
    { "e", 132, 207, "Bosnauk", "", "Elite|95" },
    { "e", 876, 468, "Bûrzash", "", "Elite|88" },
    { "e", 751, 580, "Felljaw", "", "Elite|88" },
    { "e", 326, 90, "Geralht\nMacsen", "", "Elite|92\nSupreme Nemesis|92" },
    { "e", 395, 198, "Glendower", "", "Great Elite|87" },
    { "e", 243, 157, "Inras\nRog-Votak", "", "Signature|92\nNemesis|92" },
    { "e", 261, 255, "Krûpû and the Roving Orcs", "", "Great Elite|95" },
    { "e", 635, 97, "Nûdît", "", "Great Elite|86" },
    { "e", 666, 322, "Ora", "", "Great Elite|87" },
    { "e", 247, 376, "Patarshan", "", "Elite|95" },
    { "e", 819, 607, "Scion of the Great Boar", "", "Nemesis|88" },
    { "e", 754, 408, "Snapfang", "", "Signature|88" },
    { "s", 549, 425, "", "", "far" },
    { "s", 502, 181, "", "", "far" },
    { "s", 568, 395, "", "" },
    { "s", 703, 551, "Aldburg", "" },
    { "s", 904, 580, "Beaconwatch", "" },
    { "s", 383, 307, "Edoras", "" },
    { "s", 645, 160, "Entwade", "" },
    { "s", 891, 483, "Fenmarch", "" },
    { "s", 143, 353, "Grimslade", "" },
    { "s", 437, 87, "Middlemead", "" },
    { "s", 400, 508, "Underharrow", "" },
}
D.Pois[116] = {
    { "e", 367, 418, "Cledwun - Dunlending War-leader", "", "Great Elite|90" },
    { "s", 709, 280, "Oserly", "" },
    { "s", 538, 491, "Stoke", "" },
}
D.Pois[117] = {
    { "e", 574, 272, "Bûrzash", "", "Elite|88" },
    { "e", 791, 389, "Darkheart", "", "Signature|88" },
    { "e", 392, 435, "Felljaw", "", "Elite|88" },
    { "e", 491, 475, "Scion of the Great Boar", "", "Nemesis|88" },
    { "e", 396, 184, "Snapfang", "", "Signature|88" },
    { "s", 322, 393, "Aldburg", "" },
    { "s", 615, 436, "Beaconwatch", "" },
    { "s", 596, 294, "Fenmarch", "" },
}
D.Pois[118] = {
    { "e", 339, 673, "Bosnauk", "", "Elite|95" },
    { "e", 843, 201, "Cledwun - Dunlending War-leader", "", "Great Elite|90" },
    { "e", 653, 484, "Geralht\nMacsen", "", "Elite|92\nSupreme Nemesis|92" },
    { "e", 765, 659, "Glendower", "", "Great Elite|87" },
    { "e", 518, 593, "Inras\nRog-Votak", "", "Signature|92\nNemesis|92" },
    { "e", 611, 293, "Neivion\nOgnir", "", "Nemesis|92\nElite|92" },
    { "s", 574, 334, "Brockbridge", "" },
    { "s", 272, 482, "Gapholt", "" },
    { "s", 833, 481, "Middlemead", "" },
    { "s", 504, 176, "Woodhurst", "" },
}
D.Pois[119] = {
    { "s", 457, 405, "Helm's Deep", "" },
}
D.Pois[120] = {
    { "e", 295, 210, "Bethan, Priestess of Isengard", "", "Supreme Nemesis|95" },
    { "e", 578, 231, "Bosnauk", "", "Elite|95" },
    { "e", 740, 158, "Inras\nRog-Votak", "", "Signature|92\nNemesis|92" },
    { "e", 766, 300, "Krûpû and the Roving Orcs", "", "Great Elite|95" },
    { "e", 746, 477, "Patarshan", "", "Elite|95" },
    { "e", 354, 99, "Voraut", "", "Signature|95" },
    { "s", 256, 510, "Helm's Deep", "" },
    { "s", 945, 376, "Edoras", "" },
    { "s", 518, 58, "Gapholt", "" },
    { "s", 594, 444, "Grimslade", "" },
    { "s", 970, 669, "Underharrow", "" },
}
D.Pois[121] = {
    { "c", 539, 418, "Edoras", "" },
    { "s", 341, 339, "Edoras", "" },
}
D.Pois[123] = {
    { "s", 532, 383, "Isengard (flooded", "" },
}
D.Pois[125] = {
    { "c", 441, 576, "Dol Amroth", "" },
    { "e", 444, 650, "Adîrjan the Brute", "", "Elite|99" },
    { "e", 772, 268, "Corugwen the Cunning", "", "Great Elite|98" },
    { "e", 603, 209, "Hemokh", "", "Elite|96" },
    { "e", 547, 243, "Old Brôg", "", "Elite|96" },
    { "e", 837, 356, "Old Snapper", "", "Elite|98" },
    { "e", 721, 547, "Skulkmire", "", "Elite|98" },
    { "e", 773, 394, "The Great Bull", "", "Elite|98" },
    { "s", 660, 557, "Tadrent", "" },
    { "s", 420, 592, "Dol-Amroth", "" },
    { "s", 834, 395, "Calembel", "" },
    { "s", 952, 514, "", "" },
    { "s", 539, 151, "Morlad", "" },
    { "t", 491, 267, "Gondorian Treasure Cache", "" },
    { "t", 514, 206, "Gondorian Treasure Cache", "" },
    { "t", 572, 239, "Gondorian Treasure Cache", "" },
    { "t", 553, 227, "Gondorian Treasure Cache", "" },
    { "t", 619, 239, "Gondorian Treasure Cache", "" },
    { "t", 657, 158, "Gondorian Treasure Cache", "" },
    { "t", 702, 284, "Gondorian Treasure Cache", "" },
    { "t", 693, 348, "Gondorian Treasure Cache", "" },
    { "t", 731, 358, "Gondorian Treasure Cache", "" },
    { "t", 848, 400, "Gondorian Treasure Cache", "" },
    { "t", 776, 531, "Gondorian Treasure Cache", "" },
    { "t", 771, 237, "Gondorian Treasure Cache", "" },
    { "t", 731, 590, "Gondorian Treasure Cache", "" },
    { "t", 650, 617, "Gondorian Treasure Cache", "" },
    { "t", 603, 548, "Gondorian Treasure Cache", "" },
    { "t", 493, 633, "Gondorian Treasure Cache", "" },
    { "t", 493, 673, "Gondorian Treasure Cache", "" },
    { "t", 393, 617, "Gondorian Treasure Cache", "" },
}
D.Pois[126] = {
    { "e", 689, 312, "Hemokh", "", "Elite|96" },
    { "e", 602, 367, "Old Brôg", "", "Elite|96" },
    { "s", 588, 222, "Morlad", "" },
    { "t", 513, 405, "Gondorian Treasure Cache", "" },
    { "t", 550, 308, "Gondorian Treasure Cache", "" },
    { "t", 641, 360, "Gondorian Treasure Cache", "" },
    { "t", 610, 341, "Gondorian Treasure Cache", "" },
    { "t", 716, 360, "Gondorian Treasure Cache", "" },
    { "t", 776, 232, "Gondorian Treasure Cache", "" },
}
D.Pois[127] = {
    { "c", 477, 295, "Dol Amroth", "" },
    { "e", 482, 412, "Adîrjan the Brute", "", "Elite|99" },
    { "e", 917, 250, "Skulkmire", "", "Elite|98" },
    { "s", 821, 266, "Tadrent", "" },
    { "s", 444, 320, "Dol-Amroth", "" },
    { "t", 933, 318, "Gondorian Treasure Cache", "" },
    { "t", 806, 359, "Gondorian Treasure Cache", "" },
    { "t", 731, 250, "Gondorian Treasure Cache", "" },
    { "t", 559, 385, "Gondorian Treasure Cache", "" },
    { "t", 559, 449, "Gondorian Treasure Cache", "" },
    { "t", 402, 359, "Gondorian Treasure Cache", "" },
}
D.Pois[128] = {
    { "c", 447, 382, "Dol Amroth", "" },
    { "s", 309, 486, "Dol-Amroth", "" },
}
D.Pois[129] = {
    { "e", 625, 166, "Corugwen the Cunning", "", "Great Elite|98" },
    { "e", 754, 340, "Old Snapper", "", "Elite|98" },
    { "e", 525, 719, "Skulkmire", "", "Elite|98" },
    { "e", 628, 415, "The Great Bull", "", "Elite|98" },
    { "s", 747, 417, "Calembel", "" },
    { "t", 488, 197, "Gondorian Treasure Cache", "" },
    { "t", 469, 324, "Gondorian Treasure Cache", "" },
    { "t", 544, 343, "Gondorian Treasure Cache", "" },
    { "t", 774, 428, "Gondorian Treasure Cache", "" },
    { "t", 634, 686, "Gondorian Treasure Cache", "" },
    { "t", 624, 103, "Gondorian Treasure Cache", "" },
}
D.Pois[131] = {
    { "e", 891, 271, "Sorzûr the Lone Hunter", "", "Signature|100" },
}
D.Pois[132] = {
    { "c", 442, 467, "Linhir", "" },
    { "c", 772, 502, "Pelargir", "" },
    { "e", 533, 527, "Darik", "", "Elite|102" },
    { "e", 249, 399, "Hamarsun", "", "Elite|102" },
    { "e", 256, 549, "Hokhir", "", "Nemesis|102" },
    { "e", 707, 531, "Shataz", "", "Great Elite|102" },
    { "e", 261, 463, "Shatúpash", "", "Nemesis|102" },
    { "e", 227, 155, "Skorneval", "", "Great Elite|102" },
    { "e", 762, 439, "Vilosh", "", "Great Elite|102" },
    { "s", 933, 449, "", "" },
    { "s", 644, 392, "", "" },
    { "s", 875, 508, "", "" },
    { "s", 775, 514, "Pelargir", "" },
    { "t", 232, 554, "Central Gondor", "" },
    { "t", 426, 350, "Central Gondor", "" },
    { "t", 257, 232, "Treasure Cache", "" },
    { "t", 192, 149, "Treasure Cache", "" },
    { "t", 383, 147, "Treasure Cache", "" },
    { "t", 314, 301, "Treasure Cache", "" },
    { "t", 808, 559, "Treasure Cache", "" },
    { "t", 893, 534, "Treasure Cache", "" },
    { "t", 772, 553, "Treasure Cache", "" },
    { "t", 807, 512, "Treasure Cache", "" },
    { "t", 514, 594, "Treasure Cache", "" },
    { "t", 609, 599, "Treasure Cache", "" },
    { "t", 832, 370, "Treasure Cache", "" },
    { "t", 727, 339, "Treasure Cache", "" },
    { "t", 530, 410, "Treasure Cache", "" },
    { "t", 568, 284, "Treasure Cache", "" },
    { "t", 488, 313, "Treasure Cache", "" },
    { "t", 207, 460, "Treasure Cache", "" },
    { "t", 383, 384, "Treasure Cache", "" },
    { "t", 299, 629, "Treasure Cache", "" },
}
D.Pois[133] = {
    { "e", 379, 253, "Skorneval", "", "Great Elite|102" },
    { "t", 457, 453, "Treasure Cache", "" },
    { "t", 288, 237, "Treasure Cache", "" },
    { "t", 784, 232, "Treasure Cache", "" },
    { "t", 605, 632, "Treasure Cache", "" },
}
D.Pois[134] = {
    { "c", 153, 377, "Linhir", "" },
    { "c", 753, 441, "Pelargir", "" },
    { "e", 319, 485, "Darik", "", "Elite|102" },
    { "e", 636, 493, "Shataz", "", "Great Elite|102" },
    { "e", 735, 327, "Vilosh", "", "Great Elite|102" },
    { "s", 520, 241, "", "" },
    { "s", 941, 452, "", "" },
    { "s", 759, 462, "Pelargir", "" },
    { "t", 124, 166, "Central Gondor", "" },
    { "t", 820, 544, "Treasure Cache", "" },
    { "t", 974, 499, "Treasure Cache", "" },
    { "t", 755, 533, "Treasure Cache", "" },
    { "t", 817, 459, "Treasure Cache", "" },
    { "t", 285, 607, "Treasure Cache", "" },
    { "t", 457, 616, "Treasure Cache", "" },
    { "t", 863, 203, "Treasure Cache", "" },
    { "t", 672, 146, "Treasure Cache", "" },
    { "t", 313, 275, "Treasure Cache", "" },
    { "t", 383, 47, "Treasure Cache", "" },
    { "t", 236, 100, "Treasure Cache", "" },
    { "t", 46, 227, "Treasure Cache", "" },
}
D.Pois[135] = {
    { "c", 380, 122, "Pelargir", "" },
    { "s", 867, 151, "", "" },
    { "s", 395, 178, "Pelargir", "" },
    { "t", 553, 390, "Treasure Cache", "" },
    { "t", 952, 274, "Treasure Cache", "" },
    { "t", 383, 363, "Treasure Cache", "" },
    { "t", 546, 171, "Treasure Cache", "" },
}
D.Pois[136] = {
    { "c", 820, 375, "Linhir", "" },
    { "e", 995, 490, "Darik", "", "Elite|102" },
    { "e", 449, 245, "Hamarsun", "", "Elite|102" },
    { "e", 464, 534, "Hokhir", "", "Nemesis|102" },
    { "e", 473, 368, "Shatúpash", "", "Nemesis|102" },
    { "t", 417, 543, "Central Gondor", "" },
    { "t", 789, 152, "Central Gondor", "" },
    { "t", 575, 59, "Treasure Cache", "" },
    { "t", 959, 618, "Treasure Cache", "" },
    { "t", 989, 267, "Treasure Cache", "" },
    { "t", 908, 82, "Treasure Cache", "" },
    { "t", 369, 362, "Treasure Cache", "" },
    { "t", 708, 217, "Treasure Cache", "" },
    { "t", 545, 686, "Treasure Cache", "" },
}
D.Pois[138] = {
    { "c", 499, 153, "Minas Tirith", "" },
    { "c", 101, 666, "Pelargir", "" },
    { "d", 757, 98, "Sunken Labyrinth\nThe Dome of Stars\nThe Ruined City", "Laberinto Hundido\nLa Cúpula de las Estrellas\nLa Ciudad en Ruinas" },
    { "e", 878, 134, "Gundrág", "", "Great Elite|103" },
    { "e", 228, 626, "Kasota", "", "Great Elite|103" },
    { "e", 760, 311, "Thangol-ya", "", "Great Elite|103" },
    { "s", 663, 395, "Bâr Húrin", "" },
    { "s", 832, 163, "Faramir's Lookout", "" },
    { "s", 329, 473, "Arnarch", "" },
    { "s", 181, 601, "Glaniath", "" },
    { "t", 414, 352, "Eastern Gondor", "" },
    { "t", 760, 178, "Eastern Gondor", "" },
    { "t", 422, 465, "Treasure Cache", "" },
    { "t", 387, 533, "Treasure Cache", "" },
    { "t", 313, 437, "Treasure Cache", "" },
    { "t", 332, 608, "Treasure Cache", "" },
    { "t", 606, 385, "Treasure Cache", "" },
    { "t", 727, 421, "Treasure Cache", "" },
    { "t", 483, 542, "Treasure Cache", "" },
    { "t", 700, 459, "Treasure Cache", "" },
    { "t", 716, 129, "Treasure Cache", "" },
    { "t", 749, 151, "Treasure Cache", "" },
    { "t", 724, 98, "Treasure Cache", "" },
    { "t", 760, 54, "Treasure Cache", "" },
    { "t", 299, 613, "Treasure Cache", "" },
    { "t", 112, 531, "Treasure Cache", "" },
    { "t", 214, 652, "Treasure Cache", "" },
}
D.Pois[139] = {
    { "c", 313, 637, "Pelargir", "" },
    { "e", 625, 541, "Kasota", "", "Great Elite|103" },
    { "s", 875, 165, "Arnarch", "" },
    { "s", 510, 479, "Glaniath", "" },
    { "t", 834, 77, "Treasure Cache", "" },
    { "t", 881, 495, "Treasure Cache", "" },
    { "t", 800, 509, "Treasure Cache", "" },
    { "t", 340, 306, "Treasure Cache", "" },
    { "t", 590, 603, "Treasure Cache", "" },
}
D.Pois[140] = {
    { "c", 321, 171, "Minas Tirith", "" },
    { "d", 684, 93, "Sunken Labyrinth\nThe Dome of Stars\nThe Ruined City", "Laberinto Hundido\nLa Cúpula de las Estrellas\nLa Ciudad en Ruinas" },
    { "e", 854, 144, "Gundrág", "", "Great Elite|103" },
    { "e", 687, 393, "Thangol-ya", "", "Great Elite|103" },
    { "s", 552, 512, "Bâr Húrin", "" },
    { "s", 789, 184, "Faramir's Lookout", "" },
    { "t", 201, 450, "Eastern Gondor", "" },
    { "t", 688, 206, "Eastern Gondor", "" },
    { "t", 212, 610, "Treasure Cache", "" },
    { "t", 471, 497, "Treasure Cache", "" },
    { "t", 641, 547, "Treasure Cache", "" },
    { "t", 603, 602, "Treasure Cache", "" },
    { "t", 626, 136, "Treasure Cache", "" },
    { "t", 672, 167, "Treasure Cache", "" },
    { "t", 638, 93, "Treasure Cache", "" },
    { "t", 688, 31, "Treasure Cache", "" },
}
D.Pois[141] = {
    { "s", 505, 406, "Arnarch", "" },
    { "t", 691, 141, "Eastern Gondor", "" },
    { "t", 709, 388, "Treasure Cache", "" },
    { "t", 631, 538, "Treasure Cache", "" },
    { "t", 469, 328, "Treasure Cache", "" },
    { "t", 511, 700, "Treasure Cache", "" },
    { "t", 840, 556, "Treasure Cache", "" },
    { "t", 439, 712, "Treasure Cache", "" },
}
D.Pois[142] = {
    { "d", 497, 421, "Sunken Labyrinth\nThe Dome of Stars\nThe Ruined City", "Laberinto Hundido\nLa Cúpula de las Estrellas\nLa Ciudad en Ruinas" },
    { "e", 158, 216, "Fen-skulk", "", "Elite|103" },
    { "t", 508, 729, "Eastern Gondor", "" },
    { "t", 497, 729, "Treasure Cache", "" },
    { "t", 338, 538, "Treasure Cache", "" },
    { "t", 466, 623, "Treasure Cache", "" },
    { "t", 370, 421, "Treasure Cache", "" },
    { "t", 508, 250, "Treasure Cache", "" },
}
D.Pois[144] = {
    { "e", 809, 560, "Bittergall, the Weaver", "", "Nemesis|105" },
    { "e", 625, 695, "Fen-skulk", "", "Elite|103" },
    { "e", 374, 116, "Mauzúr", "", "Elite|103" },
    { "e", 639, 579, "Tupûrta", "", "Great Elite|103" },
    { "s", 384, 640, "North-gate", "" },
    { "s", 443, 429, "", "" },
    { "t", 796, 508, "North Ithilien", "" },
    { "t", 651, 320, "North Ithilien", "" },
    { "t", 769, 709, "Treasure Cache", "" },
    { "t", 791, 280, "Treasure of North Ithilien", "" },
    { "t", 831, 517, "Treasure of North Ithilien", "" },
    { "t", 485, 44, "Treasure of North Ithilien", "" },
}
D.Pois[145] = {
    { "c", 471, 366, "Minas Tirith", "" },
    { "s", 638, 476, "", "" },
    { "s", 613, 320, "", "" },
    { "s", 740, 480, "", "" },
    { "s", 697, 296, "", "" },
    { "s", 823, 408, "Minas Tirith", "" },
    { "s", 543, 451, "", "" },
}
D.Pois[146] = {
    { "c", 405, 364, "Minas Tirith", "" },
    { "s", 481, 415, "", "" },
    { "s", 469, 343, "", "" },
    { "s", 527, 416, "", "" },
    { "s", 508, 332, "", "" },
    { "s", 565, 384, "Minas Tirith", "" },
    { "s", 438, 403, "", "" },
}
D.Pois[147] = {
    { "c", 368, 547, "Minas Tirith", "" },
    { "e", 686, 344, "Bittergall, the Weaver", "", "Nemesis|105" },
    { "e", 576, 425, "Fen-skulk", "", "Elite|103" },
    { "e", 561, 569, "Kûr-anchi", "", "Great Elite|103" },
    { "e", 425, 77, "Mauzúr", "", "Elite|103" },
    { "e", 475, 661, "Okursa", "", "Great Elite|103" },
    { "e", 540, 607, "Sharshûg", "", "Great Elite|103" },
    { "e", 584, 355, "Tupûrta", "", "Great Elite|103" },
    { "s", 407, 572, "", "" },
    { "s", 401, 536, "", "" },
    { "s", 431, 573, "", "" },
    { "s", 421, 530, "", "" },
    { "s", 450, 556, "Minas Tirith", "" },
    { "s", 385, 566, "", "" },
    { "s", 431, 392, "North-gate", "" },
    { "s", 466, 265, "", "" },
    { "t", 678, 313, "North Ithilien", "" },
    { "t", 591, 200, "North Ithilien", "" },
    { "t", 612, 50, "North Ithilien", "" },
    { "t", 620, 505, "Treasure Cache", "" },
    { "t", 652, 526, "Treasure Cache", "" },
    { "t", 628, 476, "Treasure Cache", "" },
    { "t", 662, 434, "Treasure Cache", "" },
    { "t", 691, 223, "Treasure of North Ithilien", "" },
    { "t", 699, 318, "Treasure of North Ithilien", "" },
    { "t", 491, 34, "Treasure of North Ithilien", "" },
}
D.Pois[148] = {
    { "e", 918, 409, "Aslâ Khimash", "", "Signature|105" },
    { "e", 767, 529, "Ganglemód", "", "Signature|105" },
    { "e", 428, 316, "Nauruk", "", "Signature|105" },
    { "e", 224, 274, "Yarl Vrakya", "", "Elite|105" },
    { "s", 420, 429, "Ost Rimmon", "" },
    { "s", 634, 380, "War-stead of the Rohirrim", "" },
    { "t", 920, 394, "Far Anórien", "" },
    { "t", 491, 481, "Far Anórien", "" },
    { "t", 344, 241, "Far Anórien", "" },
    { "t", 260, 388, "Far Anórien", "" },
    { "t", 926, 640, "Treasure Cache", "" },
    { "t", 830, 481, "Treasure Cache", "" },
    { "t", 785, 493, "Treasure Cache", "" },
    { "t", 434, 394, "Treasure Cache", "" },
    { "t", 98, 343, "Treasure Cache", "" },
    { "t", 326, 463, "Treasure Cache", "" },
    { "t", 251, 343, "Treasure Cache", "" },
    { "t", 533, 424, "Treasure Cache", "" },
    { "t", 551, 484, "Treasure Cache", "" },
    { "t", 92, 424, "Treasure Cache", "" },
    { "t", 608, 493, "Treasure Cache", "" },
    { "t", 641, 352, "Treasure Cache", "" },
}
D.Pois[149] = {
    { "e", 624, 461, "Nauruk", "", "Signature|105" },
    { "e", 344, 403, "Yarl Vrakya", "", "Elite|105" },
    { "s", 613, 616, "Ost Rimmon", "" },
    { "t", 711, 687, "Far Anórien", "" },
    { "t", 509, 358, "Far Anórien", "" },
    { "t", 393, 559, "Far Anórien", "" },
    { "t", 632, 568, "Treasure Cache", "" },
    { "t", 171, 498, "Treasure Cache", "" },
    { "t", 484, 662, "Treasure Cache", "" },
    { "t", 381, 498, "Treasure Cache", "" },
    { "t", 768, 609, "Treasure Cache", "" },
    { "t", 793, 691, "Treasure Cache", "" },
    { "t", 162, 609, "Treasure Cache", "" },
    { "t", 871, 704, "Treasure Cache", "" },
}
D.Pois[150] = {
    { "e", 687, 175, "Aslâ Khimash", "", "Signature|105" },
    { "e", 441, 371, "Ganglemód", "", "Signature|105" },
    { "e", 770, 653, "Krûghu", "", "Elite|105" },
    { "s", 226, 129, "War-stead of the Rohirrim", "" },
    { "t", 691, 151, "Far Anórien", "" },
    { "t", 700, 550, "Treasure Cache", "" },
    { "t", 544, 292, "Treasure Cache", "" },
    { "t", 471, 311, "Treasure Cache", "" },
    { "t", 62, 199, "Treasure Cache", "" },
    { "t", 91, 297, "Treasure Cache", "" },
    { "t", 184, 311, "Treasure Cache", "" },
    { "t", 237, 82, "Treasure Cache", "" },
}
D.Pois[151] = {
    { "s", 483, 472, "", "", "far" },
}
D.Pois[153] = {
    { "c", 375, 461, "Minas Tirith", "" },
    { "d", 304, 461, "The Silent Street", "La Calle Silenciosa" },
    { "e", 848, 132, "Bittergall, the Weaver", "", "Nemesis|105" },
    { "e", 952, 53, "Ognir, Warrior of Minas Morgul", "", "Elite|105" },
    { "s", 903, 353, "", "" },
    { "s", 558, 461, "Aragorn's Pavilion", "" },
    { "s", 471, 460, "Minas Tirith after the battle", "" },
    { "t", 919, 207, "Treasure Cache", "" },
    { "t", 869, 90, "Treasure Cache", "" },
}
D.Pois[154] = {
    { "c", 260, 719, "Minas Tirith", "" },
    { "d", 213, 719, "The Silent Street", "La Calle Silenciosa" },
    { "e", 577, 502, "Bittergall, the Weaver", "", "Nemesis|105" },
    { "e", 438, 78, "Keeper Shomushuk, Cat-master of the Khundolar", "", "Signature|105" },
    { "e", 646, 449, "Ognir, Warrior of Minas Morgul", "", "Elite|105" },
    { "s", 602, 244, "Henneth Annûn", "" },
    { "s", 613, 647, "", "" },
    { "s", 383, 718, "Aragorn's Pavilion", "" },
    { "s", 502, 41, "Camp of the Host", "" },
    { "s", 325, 718, "Minas Tirith after the battle", "" },
    { "t", 568, 469, "North Ithilien", "" },
    { "t", 477, 350, "North Ithilien", "" },
    { "t", 499, 193, "North Ithilien", "" },
    { "t", 624, 551, "Treasure Cache", "" },
    { "t", 590, 474, "Treasure Cache", "" },
    { "t", 654, 466, "Treasure Cache", "" },
    { "t", 582, 375, "Treasure Cache", "" },
    { "t", 513, 370, "Treasure Cache", "" },
    { "t", 565, 326, "Treasure Cache", "" },
    { "t", 371, 177, "Treasure Cache", "" },
    { "t", 468, 152, "Treasure Cache", "" },
    { "t", 543, 130, "Treasure Cache", "" },
}
D.Pois[156] = {
    { "s", 916, 472, "", "" },
}
D.Pois[157] = {
    { "c", 550, 388, "Minas Tirith", "" },
    { "d", 359, 388, "The Silent Street", "La Calle Silenciosa" },
    { "s", 812, 385, "Minas Tirith after the battle", "" },
}
D.Pois[159] = {
    { "s", 673, 414, "", "" },
    { "s", 327, 741, "Camp of the Host", "" },
    { "t", 246, 653, "Forgotten Caches", "" },
    { "t", 331, 643, "Forgotten Caches", "" },
    { "t", 391, 493, "Forgotten Caches", "" },
    { "t", 486, 433, "Forgotten Caches", "" },
    { "t", 321, 383, "Forgotten Caches", "" },
    { "t", 486, 204, "Forgotten Caches", "" },
    { "t", 496, 533, "Forgotten Caches", "" },
    { "t", 610, 408, "Forgotten Caches", "" },
}
D.Pois[161] = {
    { "r", 712, 210, "The Abyss of Mordath", "El Abismo de Mordath" },
    { "d", 874, 310, "The Court of Seregost", "Tribunal de Seregost" },
    { "d", 577, 601, "The Dungeons of Naerband", "Las mazmorras de Naerband" },
    { "e", 888, 262, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 708, 386, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 690, 468, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 221, 312, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 225, 359, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 379, 569, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 286, 95, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 221, 125, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 297, 231, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 523, 192, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 584, 271, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 331, 350, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 417, 350, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 457, 395, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 491, 488, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 708, 612, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 726, 574, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 489, 594, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 599, 524, "Uiliúr, the Ancient Evil", "", "Nemesis|115" },
    { "s", 372, 401, "Magh Ashtu", "", "far" },
    { "s", 328, 285, "", "" },
    { "s", 121, 131, "", "" },
    { "s", 740, 478, "Agarnaith Ranger Camp", "" },
    { "t", 685, 449, "Agarnaith", "" },
    { "t", 780, 323, "Agarnaith", "" },
    { "t", 859, 287, "Agarnaith", "" },
    { "t", 886, 274, "Agarnaith", "" },
    { "t", 439, 355, "Dor Amarth", "" },
    { "t", 518, 380, "Dor Amarth", "" },
    { "t", 559, 269, "Dor Amarth", "" },
    { "t", 331, 666, "Lhingris", "" },
    { "t", 279, 303, "Lhingris", "" },
    { "t", 246, 368, "Lhingris", "" },
    { "t", 230, 384, "Lhingris", "" },
    { "t", 699, 416, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 901, 249, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 874, 292, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 901, 292, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 877, 307, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 424, 246, "Rare Gorgoroth Chests of Dor Amarth", "" },
    { "t", 392, 359, "Rare Gorgoroth Chests of Dor Amarth", "" },
    { "t", 311, 443, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 237, 515, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 270, 474, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 548, 528, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 703, 528, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 361, 416, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 570, 652, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 678, 528, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 223, 143, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 334, 186, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 149, 192, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 135, 197, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 205, 262, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 374, 650, "Rare Mordor Chest", "" },
    { "t", 503, 456, "Talath Úrui", "" },
    { "t", 101, 235, "Treasure Cache", "" },
    { "t", 92, 181, "Treasure Cache", "" },
    { "t", 140, 122, "Treasure Cache", "" },
    { "t", 178, 190, "Treasure Cache", "" },
    { "t", 309, 127, "Treasure Cache", "" },
    { "t", 270, 228, "Treasure Cache", "" },
    { "t", 189, 231, "Treasure Cache", "" },
    { "t", 165, 235, "Treasure Cache", "" },
    { "t", 334, 197, "Treasure Cache", "" },
    { "t", 295, 404, "Treasure Cache", "" },
    { "t", 261, 463, "Treasure Cache", "" },
    { "t", 171, 314, "Treasure Cache", "" },
    { "t", 304, 526, "Treasure Cache", "" },
    { "t", 259, 269, "Treasure Cache", "" },
    { "t", 372, 578, "Treasure Cache", "" },
    { "t", 279, 458, "Treasure Cache", "" },
    { "t", 243, 319, "Treasure Cache", "" },
    { "t", 419, 677, "Treasure Cache", "" },
    { "t", 597, 528, "Treasure Cache", "" },
    { "t", 658, 522, "Treasure Cache", "" },
    { "t", 482, 596, "Treasure Cache", "" },
    { "t", 611, 646, "Treasure Cache", "" },
    { "t", 644, 594, "Treasure Cache", "" },
    { "t", 696, 621, "Treasure Cache", "" },
    { "t", 669, 621, "Treasure Cache", "" },
    { "t", 581, 490, "Treasure Cache", "" },
    { "t", 563, 495, "Treasure Cache", "" },
    { "t", 701, 504, "Treasure Cache", "" },
    { "t", 473, 436, "Treasure Cache", "" },
    { "t", 816, 303, "Treasure Cache", "" },
    { "t", 838, 305, "Treasure Cache", "" },
    { "t", 696, 431, "Treasure Cache", "" },
    { "t", 913, 314, "Treasure Cache", "" },
    { "t", 870, 355, "Treasure Cache", "" },
    { "t", 888, 237, "Treasure Cache", "" },
    { "t", 683, 242, "Treasure Cache", "" },
    { "t", 322, 350, "Treasure Cache", "" },
    { "t", 602, 279, "Treasure Cache", "" },
    { "t", 491, 283, "Treasure Cache", "" },
    { "t", 667, 244, "Treasure Cache", "" },
    { "t", 444, 231, "Treasure Cache", "" },
    { "t", 669, 192, "Treasure Cache", "" },
    { "t", 498, 307, "Treasure Cache", "" },
    { "t", 496, 296, "Treasure Cache", "" },
    { "t", 586, 292, "Treasure Cache", "" },
}
D.Pois[163] = {
    { "e", 694, 179, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 512, 260, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 725, 554, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "s", 810, 706, "", "" },
    { "s", 236, 278, "", "" },
    { "t", 519, 310, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 825, 429, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 313, 448, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 275, 461, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 469, 642, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 182, 567, "Treasure Cache", "" },
    { "t", 157, 417, "Treasure Cache", "" },
    { "t", 263, 486, "Treasure Cache", "" },
    { "t", 288, 254, "Treasure Cache", "" },
    { "t", 506, 317, "Treasure Cache", "" },
    { "t", 394, 442, "Treasure Cache", "" },
    { "t", 756, 267, "Treasure Cache", "" },
    { "t", 650, 548, "Treasure Cache", "" },
    { "t", 425, 554, "Treasure Cache", "" },
    { "t", 519, 285, "Treasure Cache", "" },
    { "t", 356, 567, "Treasure Cache", "" },
    { "t", 825, 461, "Treasure Cache", "" },
    { "t", 619, 661, "Treasure Cache", "" },
}
D.Pois[164] = {
    { "e", 363, 146, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 370, 220, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 608, 545, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 534, 206, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 667, 206, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 730, 276, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 783, 419, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 779, 584, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "s", 598, 284, "Magh Ashtu", "", "far" },
    { "s", 529, 105, "", "" },
    { "t", 702, 213, "Dor Amarth", "" },
    { "t", 825, 251, "Dor Amarth", "" },
    { "t", 534, 696, "Lhingris", "" },
    { "t", 454, 132, "Lhingris", "" },
    { "t", 401, 234, "Lhingris", "" },
    { "t", 377, 258, "Lhingris", "" },
    { "t", 629, 220, "Rare Gorgoroth Chests of Dor Amarth", "" },
    { "t", 503, 349, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 387, 461, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 440, 398, "Rare Gorgoroth Chests of Lhingris", "" },
    { "t", 870, 482, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 580, 307, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 601, 672, "Rare Mordor Chest", "" },
    { "t", 800, 370, "Talath Úrui", "" },
    { "t", 478, 290, "Treasure Cache", "" },
    { "t", 426, 381, "Treasure Cache", "" },
    { "t", 286, 149, "Treasure Cache", "" },
    { "t", 492, 479, "Treasure Cache", "" },
    { "t", 597, 559, "Treasure Cache", "" },
    { "t", 454, 374, "Treasure Cache", "" },
    { "t", 398, 156, "Treasure Cache", "" },
    { "t", 671, 714, "Treasure Cache", "" },
    { "t", 769, 587, "Treasure Cache", "" },
    { "t", 755, 339, "Treasure Cache", "" },
    { "t", 520, 206, "Treasure Cache", "" },
    { "t", 699, 227, "Treasure Cache", "" },
}
D.Pois[165] = {
    { "d", 551, 599, "The Dungeons of Naerband", "Las mazmorras de Naerband" },
    { "e", 798, 195, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 764, 348, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 177, 539, "Gristlebite, Scourge of Lhingris", "", "Nemesis|115" },
    { "e", 326, 212, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 390, 386, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 798, 620, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 832, 548, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 385, 586, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 594, 454, "Uiliúr, the Ancient Evil", "", "Nemesis|115" },
    { "s", 165, 222, "Magh Ashtu", "", "far" },
    { "s", 859, 367, "Agarnaith Ranger Camp", "" },
    { "t", 756, 314, "Agarnaith", "" },
    { "t", 441, 182, "Dor Amarth", "" },
    { "t", 781, 250, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 496, 463, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 790, 463, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 143, 250, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 539, 697, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 743, 463, "Rare Gorgoroth Chests of Talath Úrui", "" },
    { "t", 168, 693, "Rare Mordor Chest", "" },
    { "t", 411, 327, "Talath Úrui", "" },
    { "t", 164, 556, "Treasure Cache", "" },
    { "t", 253, 744, "Treasure Cache", "" },
    { "t", 590, 463, "Treasure Cache", "" },
    { "t", 705, 450, "Treasure Cache", "" },
    { "t", 373, 590, "Treasure Cache", "" },
    { "t", 615, 684, "Treasure Cache", "" },
    { "t", 679, 586, "Treasure Cache", "" },
    { "t", 777, 637, "Treasure Cache", "" },
    { "t", 726, 637, "Treasure Cache", "" },
    { "t", 560, 390, "Treasure Cache", "" },
    { "t", 526, 399, "Treasure Cache", "" },
    { "t", 785, 416, "Treasure Cache", "" },
    { "t", 356, 288, "Treasure Cache", "" },
    { "t", 777, 280, "Treasure Cache", "" },
    { "t", 211, 156, "Treasure Cache", "" },
    { "t", 398, 327, "Treasure of Talath Úrui", "" },
}
D.Pois[166] = {
    { "r", 353, 133, "The Abyss of Mordath", "El Abismo de Mordath" },
    { "d", 696, 342, "The Court of Seregost", "Tribunal de Seregost" },
    { "e", 725, 242, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 344, 504, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 306, 675, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "s", 412, 697, "Agarnaith Ranger Camp", "" },
    { "t", 296, 637, "Agarnaith", "" },
    { "t", 496, 371, "Agarnaith", "" },
    { "t", 663, 295, "Agarnaith", "" },
    { "t", 720, 266, "Agarnaith", "" },
    { "t", 325, 566, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 753, 214, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 696, 304, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 753, 304, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 701, 338, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 329, 751, "Treasure Cache", "" },
    { "t", 572, 328, "Treasure Cache", "" },
    { "t", 620, 333, "Treasure Cache", "" },
    { "t", 320, 599, "Treasure Cache", "" },
    { "t", 777, 352, "Treasure Cache", "" },
    { "t", 877, 219, "Treasure Cache", "" },
    { "t", 686, 437, "Treasure Cache", "" },
    { "t", 725, 190, "Treasure Cache", "" },
    { "t", 291, 200, "Treasure Cache", "" },
    { "t", 258, 204, "Treasure Cache", "" },
}
D.Pois[167] = {
    { "r", 864, 332, "The Abyss of Mordath", "El Abismo de Mordath" },
    { "e", 855, 673, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 58, 371, "Nuzdum, Scourge of Udûn", "", "Nemesis|115" },
    { "e", 496, 297, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 614, 450, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 123, 603, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 290, 603, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 369, 691, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "s", 117, 477, "", "" },
    { "t", 334, 612, "Dor Amarth", "" },
    { "t", 487, 660, "Dor Amarth", "" },
    { "t", 566, 446, "Dor Amarth", "" },
    { "t", 303, 402, "Rare Gorgoroth Chests of Dor Amarth", "" },
    { "t", 242, 621, "Rare Gorgoroth Chests of Dor Amarth", "" },
    { "t", 128, 284, "Rare Gorgoroth Chests of Udûn", "" },
    { "t", 128, 305, "Treasure Cache", "" },
    { "t", 807, 393, "Treasure Cache", "" },
    { "t", 106, 603, "Treasure Cache", "" },
    { "t", 649, 465, "Treasure Cache", "" },
    { "t", 434, 472, "Treasure Cache", "" },
    { "t", 776, 397, "Treasure Cache", "" },
    { "t", 329, 630, "Treasure Cache", "" },
    { "t", 250, 634, "Treasure Cache", "" },
    { "t", 342, 371, "Treasure Cache", "" },
    { "t", 780, 297, "Treasure Cache", "" },
    { "t", 448, 520, "Treasure Cache", "" },
    { "t", 443, 498, "Treasure Cache", "" },
    { "t", 618, 489, "Treasure Cache", "" },
}
D.Pois[168] = {
    { "e", 902, 436, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 852, 661, "Bolvág the Cursed, Scourge of Agarnaith", "", "Nemesis|115" },
    { "e", 558, 116, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 95, 335, "Rotwing, Scourge of Dor Amarth", "", "Nemesis|115" },
    { "e", 208, 461, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "e", 302, 717, "Spitpyre, Scourge of Talath Úrui", "", "Nemesis|115" },
    { "t", 839, 611, "Agarnaith", "" },
    { "t", 158, 348, "Dor Amarth", "" },
    { "t", 377, 417, "Dor Amarth", "" },
    { "t", 489, 110, "Dor Amarth", "" },
    { "t", 877, 517, "Rare Gorgoroth Chests of Agarnaith", "" },
    { "t", 333, 630, "Talath Úrui", "" },
    { "t", 552, 723, "Treasure Cache", "" },
    { "t", 502, 736, "Treasure Cache", "" },
    { "t", 252, 573, "Treasure Cache", "" },
    { "t", 870, 561, "Treasure Cache", "" },
    { "t", 608, 138, "Treasure Cache", "" },
    { "t", 302, 148, "Treasure Cache", "" },
    { "t", 152, 373, "Treasure Cache", "" },
    { "t", 320, 216, "Treasure Cache", "" },
    { "t", 314, 185, "Treasure Cache", "" },
    { "t", 564, 173, "Treasure Cache", "" },
    { "t", 314, 630, "Treasure of Talath Úrui", "" },
}
D.Pois[171] = {
    { "c", 738, 299, "Dale", "Valle" },
    { "c", 739, 194, "Erebor", "" },
    { "c", 471, 391, "Felegoth", "" },
    { "c", 691, 482, "Lake-town", "Ciudad del Lago" },
    { "e", 319, 393, "Gloomthorn, Scourge of Eryn-Lasgalen", "", "Nemesis|115" },
    { "e", 207, 488, "Gloomthorn, Scourge of Eryn-Lasgalen", "", "Nemesis|115" },
    { "e", 321, 524, "Gloomthorn, Scourge of Eryn-Lasgalen", "", "Nemesis|115" },
    { "e", 486, 510, "Gloomthorn, Scourge of Eryn-Lasgalen", "", "Nemesis|115" },
    { "e", 695, 347, "Kalabrazân, Scourge of the Dale-lands", "", "Nemesis|115" },
    { "e", 760, 397, "Kalabrazân, Scourge of the Dale-lands\nUrdâr, Scourge of the Dale-lands", "", "Nemesis|115\nNemesis|115" },
    { "e", 574, 474, "Kalabrazân, Scourge of the Dale-lands", "", "Nemesis|115" },
    { "e", 805, 529, "Kalabrazân, Scourge of the Dale-lands\nUrdâr, Scourge of the Dale-lands", "", "Nemesis|115\nNemesis|115" },
    { "e", 688, 330, "Urdâr, Scourge of the Dale-lands", "", "Nemesis|115" },
    { "e", 788, 474, "Urdâr, Scourge of the Dale-lands", "", "Nemesis|115" },
    { "s", 250, 603, "Tham Taerdol", "" },
    { "s", 725, 318, "Dale", "" },
    { "s", 736, 199, "Erebor", "" },
    { "s", 470, 406, "Felegoth", "" },
    { "s", 683, 482, "Lake-town", "" },
    { "t", 661, 125, "Treasure Cache", "" },
    { "t", 658, 248, "Treasure Cache", "" },
    { "t", 518, 521, "Treasure Cache", "" },
    { "t", 815, 284, "Treasure Cache", "" },
    { "t", 742, 246, "Treasure Cache", "" },
    { "t", 719, 409, "Treasure Cache", "" },
    { "t", 467, 602, "Treasure Cache", "" },
    { "t", 156, 557, "Treasure Cache", "" },
    { "t", 229, 440, "Treasure Cache", "" },
    { "t", 434, 438, "Treasure Cache", "" },
    { "t", 508, 388, "Treasure Cache", "" },
    { "t", 441, 402, "Treasure Cache", "" },
    { "t", 302, 325, "Treasure Cache", "" },
    { "t", 592, 409, "Treasure Cache", "" },
    { "t", 686, 366, "Treasure Cache", "" },
    { "t", 683, 340, "Treasure Cache", "" },
    { "t", 797, 483, "Treasure Cache", "" },
    { "t", 789, 544, "Treasure Cache", "" },
    { "t", 671, 612, "Treasure Cache", "" },
    { "t", 579, 172, "Treasure Cache", "" },
}
D.Pois[177] = {
    { "c", 429, 413, "Skarháld", "" },
    { "r", 797, 138, "The Anvil of Winterstith", "Yunque Invernal" },
    { "d", 389, 291, "Glimmerdeep", "Brilloprofundo" },
    { "d", 105, 311, "Thikil-gundu", "" },
    { "s", 741, 530, "", "" },
    { "s", 471, 466, "Skarháld", "" },
    { "t", 897, 114, "Ered Mithrin", "" },
    { "t", 685, 451, "Ered Mithrin", "" },
    { "t", 873, 600, "Treasure Cache", "" },
    { "t", 600, 518, "Treasure Cache", "" },
    { "t", 298, 647, "Treasure Cache", "" },
    { "t", 325, 581, "Treasure Cache", "" },
    { "t", 282, 490, "Treasure Cache", "" },
    { "t", 143, 408, "Treasure Cache", "" },
    { "t", 41, 532, "Treasure Cache", "" },
    { "t", 994, 651, "Treasure Cache", "" },
    { "t", 525, 395, "Treasure Cache", "" },
    { "t", 125, 286, "Treasure Cache", "" },
}
D.Pois[178] = {
    { "c", 925, 228, "Járnfast", "" },
    { "s", 365, 565, "Skald's Drop", "" },
    { "s", 529, 114, "Hammerstead", "" },
    { "s", 920, 229, "Járnfast", "" },
    { "t", 873, 252, "Mining Cache", "" },
    { "t", 860, 220, "Mining Cache", "" },
    { "t", 775, 202, "Mining Cache", "" },
    { "t", 287, 270, "Mining Cache", "" },
    { "t", 502, 258, "Mining Cache", "" },
    { "t", 556, 527, "Mining Cache", "" },
    { "t", 649, 423, "Mining Cache", "" },
    { "t", 683, 486, "Mining Cache", "" },
    { "t", 879, 320, "Mining Cache", "" },
    { "t", 844, 390, "Mining Cache", "" },
}
D.Pois[199] = {
    { "d", 338, 434, "The Depths of Kidzul-kâlah", "Las profundidades de Kidzul-kâlah" },
    { "s", 698, 119, "", "" },
    { "s", 568, 260, "", "" },
    { "s", 642, 497, "", "" },
    { "s", 502, 604, "", "" },
    { "s", 665, 324, "Hultvís", "", "far" },
    { "t", 691, 414, "Hidden Cache", "" },
    { "t", 736, 418, "Hidden Cache", "" },
    { "t", 492, 479, "Hidden Cache", "" },
    { "t", 539, 711, "Hidden Cache", "" },
    { "t", 477, 733, "Hidden Cache", "" },
    { "t", 553, 586, "Hidden Cache", "" },
    { "t", 746, 487, "Hidden Cache", "" },
    { "t", 620, 382, "Hidden Cache", "" },
    { "t", 586, 398, "Hidden Cache", "" },
    { "t", 545, 477, "Hidden Cache", "" },
    { "t", 631, 280, "Hidden Cache", "" },
    { "t", 461, 246, "Hidden Cache", "" },
    { "t", 530, 221, "Hidden Cache", "" },
    { "t", 603, 315, "Hidden Cache", "" },
    { "t", 718, 183, "Hidden Cache", "" },
    { "t", 673, 40, "Hidden Cache", "" },
    { "t", 607, 41, "Hidden Cache", "" },
    { "t", 547, 162, "Hidden Cache", "" },
}
D.Pois[202] = {
    { "d", 718, 605, "Bâr Nírnaeth, the Houses of Lamentation", "Bâr Nírnaeth, las Casas de la Lamentación" },
    { "d", 711, 375, "Eithel Gwaur, the Filth-well", "Eithel Gwaur, el Pozo de la Inmundicia" },
    { "d", 535, 407, "Gath Daeroval, the Shadow-roost", "Gath Daeroval, el Nido de la Sombra" },
    { "d", 469, 413, "Ghashan-kútot, the Halls of Black Lore", "Ghashan-kútot, los Salones del Saber Oscuro" },
    { "d", 565, 441, "Gorthad Nûr, the Deep-barrow", "Gorthad Nûr, el Túmulo Profundo" },
    { "s", 366, 287, "Estolad Lân", "", "far" },
    { "s", 428, 195, "Echad Taerdim", "" },
    { "s", 470, 320, "Minas Morgul", "" },
    { "s", 593, 310, "Echad Uial", "" },
    { "s", 651, 372, "Taen Orwath", "" },
    { "t", 469, 387, "Minas Morgul", "" },
    { "t", 544, 398, "Minas Morgul", "" },
    { "t", 504, 402, "Minas Morgul", "" },
    { "t", 401, 102, "Rare Chests of Cirith Ungol", "" },
    { "t", 572, 113, "Rare Chests of Cirith Ungol", "" },
    { "t", 522, 195, "Rare Chests of Cirith Ungol", "" },
    { "t", 583, 163, "Rare Chests of Cirith Ungol", "" },
    { "t", 458, 441, "Rare Chests of Minas Morgul", "" },
    { "t", 568, 384, "Rare Chests of Minas Morgul", "" },
    { "t", 554, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 476, 348, "Rare Chests of Minas Morgul", "" },
    { "t", 465, 430, "Rare Chests of Minas Morgul", "" },
    { "t", 540, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 469, 419, "Rare Chests of Minas Morgul", "" },
    { "t", 497, 373, "Rare Chests of Minas Morgul", "" },
    { "t", 522, 373, "Rare Chests of Minas Morgul", "" },
    { "t", 529, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 440, 352, "Rare Chests of Rath Dúath", "" },
    { "t", 504, 248, "Rare Chests of Rath Dúath", "" },
    { "t", 721, 373, "Rare Chests of Rath Dúath", "" },
    { "t", 608, 259, "Rare Chests of Rath Dúath", "" },
    { "t", 561, 441, "Rare Chests of Rath Dúath", "" },
    { "t", 565, 316, "Rare Chests of Rath Dúath", "" },
    { "t", 807, 469, "Rare Chests of Thuringwath", "" },
    { "t", 824, 498, "Rare Chests of Thuringwath", "" },
    { "t", 703, 551, "Rare Chests of Thuringwath", "" },
    { "t", 718, 544, "Rare Chests of Thuringwath", "" },
    { "t", 711, 615, "Rare Chests of Thuringwath", "" },
    { "t", 604, 174, "Rare Mordor Chest", "" },
    { "t", 731, 550, "Rare Mordor Chest", "" },
    { "t", 227, 110, "Treasure Cache", "" },
}
D.Pois[203] = {
    { "d", 553, 465, "Gath Daeroval, the Shadow-roost", "Gath Daeroval, el Nido de la Sombra" },
    { "d", 291, 487, "Ghashan-kútot, the Halls of Black Lore", "Ghashan-kútot, los Salones del Saber Oscuro" },
    { "s", 294, 119, "Minas Morgul", "" },
    { "t", 291, 387, "Minas Morgul", "" },
    { "t", 587, 430, "Minas Morgul", "" },
    { "t", 432, 444, "Minas Morgul", "" },
    { "t", 248, 599, "Rare Chests of Minas Morgul", "" },
    { "t", 685, 373, "Rare Chests of Minas Morgul", "" },
    { "t", 629, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 319, 232, "Rare Chests of Minas Morgul", "" },
    { "t", 277, 556, "Rare Chests of Minas Morgul", "" },
    { "t", 572, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 291, 373, "Rare Chests of Minas Morgul", "" },
    { "t", 291, 514, "Rare Chests of Minas Morgul", "" },
    { "t", 403, 331, "Rare Chests of Minas Morgul", "" },
    { "t", 502, 331, "Rare Chests of Minas Morgul", "" },
    { "t", 530, 387, "Rare Chests of Minas Morgul", "" },
    { "t", 432, 430, "Rare Chests of Minas Morgul", "" },
    { "t", 178, 246, "Rare Chests of Rath Dúath", "" },
    { "t", 178, 260, "Rath Dúath", "" },
}
D.Pois[204] = {
    { "e", 542, 244, "The Bane of Rhûn, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 587, 244, "The Black Blade of Lebennin, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 425, 262, "The Cursed Rider, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 857, 379, "The Forsaken Reaver, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 632, 334, "The Gloom of Nurn, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 137, 515, "The Grim Southron, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 794, 280, "The High Sorcerer of Harad, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 713, 397, "The Witch-king, Lord of the Nazgûl, Scourge of Mordor", "", "Nemesis|130" },
    { "e", 227, 425, "The Woe of Khand, Scourge of Mordor", "", "Nemesis|130" },
    { "s", 633, 297, "Barthost", "" },
    { "s", 346, 460, "Adambel", "" },
    { "s", 120, 405, "Díngarth", "" },
    { "s", 288, 344, "Echad-in-Edhil", "" },
    { "t", 452, 198, "Mordor Besieged", "" },
    { "t", 200, 610, "Rare Chests of Mordor Besieged", "" },
    { "t", 448, 234, "Rare Chests of Mordor Besieged", "" },
    { "t", 457, 216, "Rare Chests of Mordor Besieged", "" },
    { "t", 695, 366, "Rare Chests of Mordor Besieged", "" },
    { "t", 835, 465, "Rare Chests of Mordor Besieged", "" },
    { "t", 848, 352, "Rare Chests of Mordor Besieged", "" },
    { "t", 812, 289, "Rare Chests of Mordor Besieged", "" },
    { "t", 889, 307, "Rare Chests of Mordor Besieged", "" },
    { "t", 668, 234, "Rare Chests of Mordor Besieged", "" },
    { "t", 448, 316, "Rare Chests of Mordor Besieged", "" },
}
D.Pois[205] = {
    { "t", 681, 525, "Rare Chests of Cirith Ungol", "" },
    { "t", 585, 236, "Rare Chests of Cirith Ungol", "" },
    { "r", 606, 161, "Remmorchant, the Net of Darkness", "Remmorchant, la Red de la Oscuridad" },
}
D.Pois[242] = {
    { "s", 627, 307, "", "" },
    { "s", 596, 136, "", "" },
    { "s", 721, 503, "Limlók", "" },
    { "s", 214, 345, "", "", "far" },
    { "s", 354, 264, "Lyndelby", "" },
    { "t", 472, 534, "Treasure Cache", "" },
    { "t", 432, 463, "Treasure Cache", "" },
    { "t", 778, 616, "Treasure Cache", "" },
    { "t", 864, 464, "Treasure Cache", "" },
    { "t", 725, 309, "Treasure Cache", "" },
    { "t", 532, 81, "Treasure Cache", "" },
    { "t", 632, 148, "Treasure Cache", "" },
    { "t", 552, 231, "Treasure Cache", "" },
    { "t", 695, 403, "Treasure Cache", "" },
    { "t", 560, 489, "Treasure Cache", "" },
    { "t", 677, 507, "Treasure Cache", "" },
    { "t", 654, 35, "Treasure Cache", "" },
    { "t", 456, 455, "Treasure-seeker of the Wells of Langflood", "" },
    { "t", 546, 246, "Treasure-seeker of the Wells of Langflood", "" },
    { "t", 444, 463, "Wells of Langflood", "" },
    { "t", 553, 220, "Wells of Langflood", "" },
}
D.Pois[243] = {
    { "s", 558, 313, "", "", "far" },
    { "s", 635, 195, "", "" },
}
D.Pois[244] = {
    { "s", 402, 265, "", "", "far" },
}
D.Pois[263] = {
    { "c", 697, 707, "Annâk-khurfu", "" },
    { "d", 428, 353, "Shakalush, the Stair Battle", "Shakalush, la Batalla de la Escalera" },
    { "s", 479, 405, "Drenghól", "" },
    { "s", 523, 501, "Zudramdân", "" },
    { "s", 708, 712, "Annâk-khurfu", "" },
    { "t", 880, 651, "Treasure Cache", "" },
    { "t", 652, 631, "Treasure Cache", "" },
    { "t", 643, 543, "Treasure Cache", "" },
    { "t", 904, 694, "Treasure Cache", "" },
    { "t", 570, 697, "Treasure Cache", "" },
    { "t", 417, 587, "Treasure Cache", "" },
    { "t", 448, 488, "Treasure Cache", "" },
    { "t", 620, 725, "Treasure Cache", "" },
    { "t", 725, 533, "Treasure Cache", "" },
    { "t", 606, 302, "Treasure Cache", "" },
    { "t", 370, 373, "Treasure Cache", "" },
    { "t", 321, 473, "Treasure Cache", "" },
    { "t", 320, 521, "Treasure Cache", "" },
    { "t", 621, 645, "Treasure Cache", "" },
    { "t", 621, 556, "Treasure Cache", "" },
    { "t", 873, 683, "Treasure Cache", "" },
}
D.Pois[280] = {
    { "s", 894, 233, "", "" },
    { "s", 218, 437, "Dwaling", "" },
}
D.Pois[288] = {
    { "e", 542, 458, "Bagnaz Rot-sting", "", "Signature|130" },
    { "e", 611, 520, "Bagnaz Rot-sting", "", "Signature|130" },
    { "e", 604, 499, "Bagnaz Rot-sting", "", "Signature|130" },
    { "e", 446, 148, "Krùmpug", "", "Signature|130" },
    { "e", 480, 148, "Krùmpug", "", "Signature|130" },
    { "e", 439, 73, "Krùmpug", "", "Signature|130" },
    { "e", 617, 231, "Muzbuk", "", "Signature|130" },
    { "e", 659, 169, "Muzbuk", "", "Signature|130" },
    { "e", 652, 210, "Muzbuk", "", "Signature|130" },
    { "e", 796, 389, "Skegghorn", "", "Signature|130" },
    { "e", 769, 410, "Skegghorn", "", "Signature|130" },
    { "e", 714, 382, "Skegghorn", "", "Signature|130" },
    { "e", 356, 348, "Zaugnakh", "", "Signature|130" },
    { "e", 363, 313, "Zaugnakh", "", "Signature|130" },
    { "e", 370, 286, "Zaugnakh", "", "Signature|130" },
    { "s", 592, 586, "Amdân", "" },
    { "s", 717, 194, "Ashmargathâl", "" },
    { "s", 727, 545, "Khur Azan", "" },
    { "s", 470, 424, "Zirakazhâr", "" },
    { "t", 460, 145, "Treasure Cache", "" },
    { "t", 506, 423, "Treasure Cache", "" },
    { "t", 450, 354, "Treasure Cache", "" },
    { "t", 385, 271, "Treasure Cache", "" },
    { "t", 372, 371, "Treasure Cache", "" },
    { "t", 566, 507, "Treasure Cache", "" },
    { "t", 618, 506, "Treasure Cache", "" },
    { "t", 668, 625, "Treasure Cache", "" },
    { "t", 762, 483, "Treasure Cache", "" },
    { "t", 787, 418, "Treasure Cache", "" },
    { "t", 760, 409, "Treasure Cache", "" },
    { "t", 563, 170, "Treasure Cache", "" },
}
D.Pois[291] = {
    { "e", 152, 288, "Khanakarg", "", "Signature|140" },
    { "e", 185, 254, "Khanakarg", "", "Signature|140" },
    { "e", 379, 263, "Skerla", "", "Signature|136" },
    { "e", 583, 217, "Skerla", "", "Signature|136" },
    { "s", 390, 221, "Grúmachath", "" },
    { "s", 488, 310, "Leitstáth", "" },
    { "s", 221, 241, "Fellgát", "" },
    { "s", 260, 349, "", "" },
    { "t", 239, 487, "Rare Gondor Chest", "" },
    { "t", 538, 248, "Rare Gundabad Chest", "" },
    { "t", 338, 276, "Rare Gundabad Chest", "" },
    { "t", 370, 149, "Rare Gundabad Chest", "" },
    { "t", 262, 103, "Rare Gundabad Chest", "" },
    { "t", 145, 357, "Rare Gundabad Chest", "" },
    { "t", 215, 274, "Rare Gundabad Chest", "" },
    { "t", 239, 380, "Rare Gundabad Chest", "" },
    { "t", 133, 377, "Rare Gundabad Chest", "" },
    { "t", 145, 330, "Rare Gundabad Chests of Welkin-lofts", "" },
    { "t", 552, 676, "Treasure Cache", "" },
    { "t", 552, 628, "Treasure Cache", "" },
    { "t", 691, 697, "Treasure Cache", "" },
    { "t", 618, 168, "Treasure Cache", "" },
    { "t", 316, 277, "Treasure Cache", "" },
    { "t", 647, 197, "Treasure Cache", "" },
    { "t", 414, 264, "Treasure Cache", "" },
    { "t", 370, 165, "Treasure Cache", "" },
    { "t", 327, 110, "Treasure Cache", "" },
    { "t", 280, 53, "Treasure Cache", "" },
    { "t", 226, 137, "Treasure Cache", "" },
    { "t", 204, 372, "Treasure Cache", "" },
    { "t", 303, 449, "Treasure Cache", "" },
    { "t", 225, 217, "Treasure Cache", "" },
    { "t", 176, 240, "Treasure Cache", "" },
    { "t", 320, 309, "Treasure Cache", "" },
    { "t", 196, 271, "Treasure Cache", "" },
    { "t", 196, 234, "Treasure Cache", "" },
    { "t", 149, 288, "Treasure Cache", "" },
}
D.Pois[292] = {
    { "c", 691, 477, "Vérnozal", "" },
    { "r", 317, 48, "The Hiddenhoard of Abnankâra", "El Tesoro Escondido de Abnankâra" },
    { "d", 691, 231, "Adkhât-zahhar, the Houses of Rest", "Adkhât-zahhar, las Casas del Reposo" },
    { "d", 594, 609, "Assault on Dhúrstrok", "Asalto a Dhúrstrok" },
    { "d", 551, 497, "Den of Pughlak", "Guarida de Pughlak" },
    { "e", 751, 630, "Forsting", "", "Signature|133" },
    { "e", 793, 546, "Forsting", "", "Signature|133" },
    { "e", 505, 575, "Gullush", "", "Signature|138" },
    { "e", 443, 541, "Gullush", "", "Signature|138" },
    { "e", 591, 630, "Gurlazg", "", "Signature|134" },
    { "e", 565, 696, "Gurlazg", "", "Signature|134" },
    { "e", 420, 119, "Kurzkub", "", "Signature|139" },
    { "e", 353, 97, "Kurzkub", "", "Signature|139" },
    { "e", 763, 354, "Skrizug", "", "Signature|136" },
    { "e", 807, 215, "Skrizug", "", "Signature|136" },
    { "s", 506, 311, "Hagbuth", "" },
    { "s", 496, 166, "Bazanmanar", "" },
    { "s", 796, 509, "Asbaj-khîrfin", "" },
    { "s", 438, 565, "Watchers' Roost", "" },
    { "s", 614, 649, "Aslíf", "" },
    { "s", 691, 609, "Imrêkh-guthlu", "" },
    { "s", 801, 626, "Maergind", "" },
    { "s", 691, 476, "Vérnozal", "", "far" },
    { "s", 705, 487, "Vérnozal", "", "far" },
    { "s", 735, 430, "Vérnozal", "" },
    { "t", 768, 364, "Crystal Hunter", "" },
    { "t", 772, 268, "Crystal Hunter", "" },
    { "t", 809, 275, "Crystal Hunter", "" },
    { "t", 868, 260, "Crystal Hunter", "" },
    { "t", 684, 308, "Crystal Hunter", "" },
    { "t", 890, 408, "Crystal Hunter", "" },
    { "t", 750, 264, "Crystal Hunter", "" },
    { "t", 588, 593, "Deepscrave", "" },
    { "t", 848, 537, "Rare Gundabad Chest", "" },
    { "t", 702, 581, "Rare Gundabad Chest", "" },
    { "t", 802, 697, "Rare Gundabad Chest", "" },
    { "t", 753, 455, "Rare Gundabad Chest", "" },
    { "t", 881, 420, "Rare Gundabad Chest", "" },
    { "t", 737, 268, "Rare Gundabad Chest", "" },
    { "t", 755, 286, "Rare Gundabad Chest", "" },
    { "t", 574, 613, "Rare Gundabad Chest", "" },
    { "t", 663, 602, "Rare Gundabad Chest", "" },
    { "t", 562, 648, "Rare Gundabad Chest", "" },
    { "t", 659, 685, "Rare Gundabad Chest", "" },
    { "t", 406, 267, "Rare Gundabad Chest", "" },
    { "t", 355, 166, "Rare Gundabad Chest", "" },
    { "t", 395, 224, "Rare Gundabad Chest", "" },
    { "t", 457, 90, "Rare Gundabad Chest", "" },
    { "t", 503, 601, "Rare Gundabad Chest", "" },
    { "t", 416, 635, "Rare Gundabad Chest", "" },
    { "t", 697, 520, "Treasure Cache", "" },
    { "t", 833, 553, "Treasure Cache", "" },
    { "t", 671, 570, "Treasure Cache", "" },
    { "t", 691, 571, "Treasure Cache", "" },
    { "t", 726, 487, "Treasure Cache", "" },
    { "t", 779, 492, "Treasure Cache", "" },
    { "t", 705, 298, "Treasure Cache", "" },
    { "t", 650, 279, "Treasure Cache", "" },
    { "t", 883, 256, "Treasure Cache", "" },
    { "t", 704, 236, "Treasure Cache", "" },
    { "t", 808, 383, "Treasure Cache", "" },
    { "t", 636, 315, "Treasure Cache", "" },
    { "t", 610, 702, "Treasure Cache", "" },
    { "t", 603, 544, "Treasure Cache", "" },
    { "t", 646, 626, "Treasure Cache", "" },
    { "t", 595, 629, "Treasure Cache", "" },
    { "t", 586, 661, "Treasure Cache", "" },
    { "t", 528, 729, "Treasure Cache", "" },
    { "t", 678, 693, "Treasure Cache", "" },
    { "t", 499, 244, "Treasure Cache", "" },
    { "t", 423, 310, "Treasure Cache", "" },
    { "t", 367, 119, "Treasure Cache", "" },
    { "t", 489, 361, "Treasure Cache", "" },
    { "t", 436, 183, "Treasure Cache", "" },
    { "t", 423, 241, "Treasure Cache", "" },
    { "t", 375, 75, "Treasure Cache", "" },
    { "t", 457, 122, "Treasure Cache", "" },
    { "t", 440, 581, "Treasure Cache", "" },
    { "t", 541, 498, "Treasure Cache", "" },
    { "t", 412, 480, "Treasure Cache", "" },
    { "t", 447, 386, "Treasure Cache", "" },
    { "t", 488, 612, "Treasure Cache", "" },
    { "t", 487, 502, "Treasure Cache", "" },
    { "t", 440, 602, "Treasure Cache", "" },
    { "t", 421, 427, "Treasure Cache", "" },
}
D.Pois[293] = {
    { "c", 233, 154, "Vérnozal", "" },
    { "e", 370, 515, "Forsting", "", "Signature|133" },
    { "e", 467, 317, "Forsting", "", "Signature|133" },
    { "s", 474, 229, "Asbaj-khîrfin", "" },
    { "s", 232, 467, "Imrêkh-guthlu", "" },
    { "s", 487, 507, "Maergind", "" },
    { "s", 232, 153, "Vérnozal", "", "far" },
    { "s", 265, 179, "Vérnozal", "", "far" },
    { "t", 596, 297, "Rare Gundabad Chest", "" },
    { "t", 258, 399, "Rare Gundabad Chest", "" },
    { "t", 375, 102, "Rare Gundabad Chest", "" },
    { "t", 167, 449, "Rare Gundabad Chest", "" },
    { "t", 158, 644, "Rare Gundabad Chest", "" },
    { "t", 247, 255, "Treasure Cache", "" },
    { "t", 560, 335, "Treasure Cache", "" },
    { "t", 186, 374, "Treasure Cache", "" },
    { "t", 232, 375, "Treasure Cache", "" },
    { "t", 264, 252, "Treasure Cache", "" },
    { "t", 314, 178, "Treasure Cache", "" },
    { "t", 435, 189, "Treasure Cache", "" },
    { "t", 363, 101, "Treasure Cache", "" },
    { "t", 128, 506, "Treasure Cache", "" },
}
D.Pois[294] = {
    { "d", 252, 201, "Adkhât-zahhar, the Houses of Rest", "Adkhât-zahhar, las Casas del Reposo" },
    { "e", 421, 490, "Skrizug", "", "Signature|136" },
    { "e", 526, 164, "Skrizug", "", "Signature|136" },
    { "s", 356, 670, "Vérnozal", "" },
    { "t", 435, 514, "Crystal Hunter", "" },
    { "t", 443, 288, "Crystal Hunter", "" },
    { "t", 530, 306, "Crystal Hunter", "" },
    { "t", 670, 271, "Crystal Hunter", "" },
    { "t", 234, 384, "Crystal Hunter", "" },
    { "t", 722, 619, "Crystal Hunter", "" },
    { "t", 391, 280, "Crystal Hunter", "" },
    { "t", 397, 728, "Rare Gundabad Chest", "" },
    { "t", 688, 253, "Rare Gundabad Chest", "" },
    { "t", 700, 648, "Rare Gundabad Chest", "" },
    { "t", 361, 289, "Rare Gundabad Chest", "" },
    { "t", 402, 332, "Rare Gundabad Chest", "" },
    { "t", 386, 727, "Treasure Cache", "" },
    { "t", 285, 360, "Treasure Cache", "" },
    { "t", 155, 314, "Treasure Cache", "" },
    { "t", 703, 614, "Treasure Cache", "" },
    { "t", 705, 260, "Treasure Cache", "" },
    { "t", 283, 214, "Treasure Cache", "" },
    { "t", 529, 561, "Treasure Cache", "" },
    { "t", 392, 313, "Treasure Cache", "" },
}
D.Pois[295] = {
    { "d", 615, 256, "Assault on Dhúrstrok", "Asalto a Dhúrstrok" },
    { "e", 327, 147, "Gullush", "", "Signature|138" },
    { "e", 607, 324, "Gurlazg", "", "Signature|134" },
    { "e", 523, 539, "Gurlazg", "", "Signature|134" },
    { "s", 681, 388, "Aslíf", "" },
    { "t", 595, 205, "Deepscrave", "" },
    { "t", 551, 272, "Rare Gundabad Chest", "" },
    { "t", 841, 234, "Rare Gundabad Chest", "" },
    { "t", 511, 382, "Rare Gundabad Chest", "" },
    { "t", 828, 502, "Rare Gundabad Chest", "" },
    { "t", 318, 231, "Rare Gundabad Chest", "" },
    { "t", 306, 229, "Rare Gundabad Chests of Gloomingtarn", "" },
    { "t", 868, 131, "Treasure Cache", "" },
    { "t", 669, 559, "Treasure Cache", "" },
    { "t", 645, 49, "Treasure Cache", "" },
    { "t", 786, 312, "Treasure Cache", "" },
    { "t", 620, 322, "Treasure Cache", "" },
    { "t", 589, 424, "Treasure Cache", "" },
    { "t", 401, 643, "Treasure Cache", "" },
    { "t", 892, 528, "Treasure Cache", "" },
    { "t", 269, 268, "Treasure Cache", "" },
    { "t", 620, 205, "Treasure of Deepscrave", "" },
}
D.Pois[296] = {
    { "r", 406, 101, "The Hiddenhoard of Abnankâra", "El Tesoro Escondido de Abnankâra" },
    { "e", 594, 232, "Kurzkub", "", "Signature|139" },
    { "e", 470, 190, "Kurzkub", "", "Signature|139" },
    { "s", 751, 584, "Hagbuth", "" },
    { "s", 732, 318, "Bazanmanar", "" },
    { "t", 569, 504, "Rare Gundabad Chest", "" },
    { "t", 475, 317, "Rare Gundabad Chest", "" },
    { "t", 549, 424, "Rare Gundabad Chest", "" },
    { "t", 661, 177, "Rare Gundabad Chest", "" },
    { "t", 737, 460, "Treasure Cache", "" },
    { "t", 599, 582, "Treasure Cache", "" },
    { "t", 498, 232, "Treasure Cache", "" },
    { "t", 721, 674, "Treasure Cache", "" },
    { "t", 624, 348, "Treasure Cache", "" },
    { "t", 600, 454, "Treasure Cache", "" },
    { "t", 511, 150, "Treasure Cache", "" },
    { "t", 662, 236, "Treasure Cache", "" },
    { "t", 644, 721, "Treasure Cache", "" },
}
D.Pois[297] = {
    { "d", 922, 532, "Assault on Dhúrstrok", "Asalto a Dhúrstrok" },
    { "d", 821, 269, "Den of Pughlak", "Guarida de Pughlak" },
    { "e", 714, 452, "Gullush", "", "Signature|138" },
    { "e", 566, 373, "Gullush", "", "Signature|138" },
    { "e", 916, 582, "Gurlazg", "", "Signature|134" },
    { "e", 855, 738, "Gurlazg", "", "Signature|134" },
    { "s", 555, 429, "Watchers' Roost", "" },
    { "s", 969, 628, "Aslíf", "" },
    { "t", 908, 495, "Deepscrave", "" },
    { "t", 875, 543, "Rare Gundabad Chest", "" },
    { "t", 847, 624, "Rare Gundabad Chest", "" },
    { "t", 370, 233, "Rare Gundabad Chest", "" },
    { "t", 707, 514, "Rare Gundabad Chest", "" },
    { "t", 504, 594, "Rare Gundabad Chest", "" },
    { "t", 359, 303, "Rare Gundabad Chest", "" },
    { "t", 376, 303, "Rare Gundabad Chests of Gloomingtarn", "" },
    { "t", 925, 580, "Treasure Cache", "" },
    { "t", 903, 655, "Treasure Cache", "" },
    { "t", 560, 468, "Treasure Cache", "" },
    { "t", 798, 272, "Treasure Cache", "" },
    { "t", 493, 230, "Treasure Cache", "" },
    { "t", 672, 541, "Treasure Cache", "" },
    { "t", 669, 282, "Treasure Cache", "" },
    { "t", 558, 515, "Treasure Cache", "" },
    { "t", 514, 104, "Treasure Cache", "" },
}
D.Pois[298] = {
    { "e", 80, 539, "Khanakarg", "", "Signature|140" },
    { "e", 450, 557, "Skerla", "", "Signature|136" },
    { "e", 841, 467, "Skerla", "", "Signature|136" },
    { "s", 470, 476, "Grúmachath", "" },
    { "s", 658, 645, "Leitstáth", "" },
    { "s", 148, 514, "Fellgát", "" },
    { "s", 222, 719, "", "" },
    { "t", 755, 528, "Rare Gundabad Chest", "" },
    { "t", 372, 581, "Rare Gundabad Chest", "" },
    { "t", 433, 339, "Rare Gundabad Chest", "" },
    { "t", 227, 250, "Rare Gundabad Chest", "" },
    { "t", 136, 576, "Rare Gundabad Chest", "" },
    { "t", 906, 375, "Treasure Cache", "" },
    { "t", 330, 582, "Treasure Cache", "" },
    { "t", 962, 430, "Treasure Cache", "" },
    { "t", 517, 558, "Treasure Cache", "" },
    { "t", 432, 368, "Treasure Cache", "" },
    { "t", 351, 264, "Treasure Cache", "" },
    { "t", 261, 156, "Treasure Cache", "" },
    { "t", 158, 315, "Treasure Cache", "" },
    { "t", 156, 467, "Treasure Cache", "" },
    { "t", 62, 512, "Treasure Cache", "" },
    { "t", 338, 643, "Treasure Cache", "" },
    { "t", 101, 570, "Treasure Cache", "" },
    { "t", 99, 501, "Treasure Cache", "" },
}
D.Pois[299] = {
    { "e", 495, 276, "Khanakarg", "", "Signature|140" },
    { "e", 567, 204, "Khanakarg", "", "Signature|140" },
    { "s", 643, 176, "Fellgát", "" },
    { "s", 725, 405, "", "" },
    { "t", 682, 700, "Rare Gondor Chest", "" },
    { "t", 892, 251, "Rare Gundabad Chest", "" },
    { "t", 482, 422, "Rare Gundabad Chest", "" },
    { "t", 630, 245, "Rare Gundabad Chest", "" },
    { "t", 680, 472, "Rare Gundabad Chest", "" },
    { "t", 455, 466, "Rare Gundabad Chest", "" },
    { "t", 482, 365, "Rare Gundabad Chests of Welkin-lofts", "" },
    { "t", 845, 252, "Treasure Cache", "" },
    { "t", 607, 455, "Treasure Cache", "" },
    { "t", 816, 618, "Treasure Cache", "" },
    { "t", 652, 124, "Treasure Cache", "" },
    { "t", 547, 174, "Treasure Cache", "" },
    { "t", 854, 320, "Treasure Cache", "" },
    { "t", 590, 239, "Treasure Cache", "" },
    { "t", 589, 161, "Treasure Cache", "" },
    { "t", 489, 276, "Treasure Cache", "" },
}
D.Pois[356] = {
    { "s", 235, 38, "", "" },
    { "s", 279, 103, "", "" },
    { "s", 217, 500, "Tornhad", "" },
    { "s", 522, 305, "Tham Lumren", "" },
    { "s", 919, 107, "", "" },
    { "s", 377, 70, "Barachen's Camp", "Campamento de Barachen" },
    { "s", 685, 212, "Echad Candelleth", "" },
    { "s", 593, 386, "Gwingris", "" },
}
D.Pois[361] = {
    { "s", 341, 453, "Tighfield", "" },
    { "s", 335, 350, "Gamwich", "" },
    { "s", 493, 594, "Foxden Road", "" },
    { "s", 502, 482, "Nobottle", "" },
    { "s", 528, 269, "Long Cleeve", "" },
    { "s", 633, 523, "Needlehole", "" },
    { "s", 725, 353, "Bullroarer's Way", "" },
}
D.Pois[368] = {
    { "c", 216, 502, "Tharbad", "" },
    { "e", 674, 208, "Drindolf", "", "Great Elite|19" },
    { "e", 653, 223, "Drindolf", "", "Great Elite|19" },
    { "e", 551, 572, "Gnaw", "", "Signature|12" },
    { "e", 555, 586, "Gnaw", "", "Signature|12" },
    { "e", 530, 591, "Gnaw", "", "Signature|12" },
    { "e", 459, 345, "Gristbite", "", "Elite|13" },
    { "e", 560, 284, "Norlúg", "", "Elite|18" },
    { "e", 554, 266, "Norlúg", "", "Elite|18" },
    { "e", 529, 335, "Stoneback", "", "Elite|16" },
    { "e", 557, 324, "Stoneback", "", "Elite|16" },
    { "e", 360, 349, "Thostmoth", "", "Elite|15" },
    { "e", 332, 367, "Thostmoth", "", "Elite|15" },
    { "s", 517, 420, "Lhan Garan", "" },
    { "s", 650, 347, "Caras Gelebren", "" },
    { "s", 455, 691, "", "" },
    { "s", 550, 618, "", "" },
    { "s", 598, 601, "Lintrev", "" },
    { "s", 744, 194, "Idhobel", "" },
    { "s", 674, 739, "Echad Daervunn", "" },
    { "s", 800, 337, "Echad Mirobel", "" },
    { "s", 626, 635, "Maur Tulhau", "" },
    { "s", 305, 577, "Mossward", "" },
    { "t", 542, 623, "Dwellers of Old Swanfleet", "" },
    { "t", 694, 359, "Dwellers of Old Swanfleet", "" },
    { "t", 736, 438, "Dwellers of Old Swanfleet", "" },
    { "t", 688, 528, "Dwellers of Old Swanfleet", "" },
    { "t", 548, 323, "Dwellers of Old Swanfleet", "" },
    { "t", 612, 244, "Dwellers of Old Swanfleet", "" },
    { "t", 310, 517, "Dwellers of Old Swanfleet", "" },
    { "t", 654, 570, "Swanfleet", "" },
    { "t", 665, 160, "Treasure cache", "" },
    { "t", 719, 373, "Treasure cache", "" },
    { "t", 290, 409, "Treasure cache", "" },
    { "t", 482, 466, "Treasure cache", "" },
    { "t", 570, 490, "Treasure cache", "" },
    { "t", 343, 600, "Treasure cache", "" },
    { "t", 535, 671, "Treasure cache", "" },
}
D.Pois[369] = {
    { "c", 562, 702, "Tharbad", "" },
    { "d", 194, 135, "Sarch Vorn, the Black Grave", "Sarch Vorn, la Tumba Negra" },
    { "d", 33, 192, "Woe of the Willow", "El infortunio del sauce" },
    { "e", 134, 253, "Agerbrath", "", "Elite|27" },
    { "e", 119, 273, "Agerbrath", "", "Elite|27" },
    { "e", 706, 461, "Borhashat", "", "Elite|24" },
    { "e", 710, 472, "Borhashat", "", "Elite|24" },
    { "e", 171, 132, "Crugaul", "", "Great Elite|28" },
    { "e", 154, 138, "Crugaul", "", "Great Elite|28" },
    { "e", 244, 415, "Drugodech", "", "Signature|22" },
    { "e", 241, 397, "Drugodech", "", "Signature|22" },
    { "e", 223, 262, "Penthul", "", "Elite|26" },
    { "e", 188, 273, "Penthul", "", "Elite|26" },
    { "e", 729, 250, "Skrizug", "", "Elite|21" },
    { "e", 699, 274, "Skrizug", "", "Elite|21" },
    { "e", 164, 614, "Tarangarn", "", "Elite|23" },
    { "e", 200, 599, "Tarangarn", "", "Elite|23" },
    { "e", 878, 388, "Turch", "", "Signature|20" },
    { "e", 858, 383, "Turch", "", "Signature|20" },
    { "e", 270, 245, "Withergrip", "", "Elite|25" },
    { "e", 264, 272, "Withergrip", "", "Elite|25" },
    { "s", 256, 136, "", "" },
    { "s", 86, 437, "Sarn Ford", "" },
    { "s", 403, 494, "Herne", "" },
    { "s", 552, 340, "Caranost", "" },
    { "s", 716, 300, "Scurloc Farm", "" },
    { "s", 531, 613, "Stonecrop Encampment", "" },
    { "t", 796, 218, "Cardolan", "" },
    { "t", 254, 382, "Cardolan", "" },
    { "t", 627, 655, "Cardolan", "" },
    { "t", 613, 684, "The Ravaging of Cardolan", "" },
    { "t", 151, 592, "The Ravaging of Cardolan", "" },
    { "t", 234, 192, "The Ravaging of Cardolan", "" },
    { "t", 848, 328, "The Ravaging of Cardolan", "" },
    { "t", 203, 322, "The Ravaging of Cardolan", "" },
    { "t", 532, 615, "The Ravaging of Cardolan", "" },
    { "t", 373, 627, "Treasure Cache", "" },
    { "t", 123, 476, "Treasure Cache", "" },
    { "t", 166, 347, "Treasure Cache", "" },
    { "t", 534, 155, "Treasure Cache", "" },
    { "t", 478, 375, "Treasure Cache", "" },
    { "t", 649, 463, "Treasure Cache", "" },
    { "t", 632, 524, "Treasure Cache", "" },
    { "t", 900, 374, "Treasure Cache", "" },
}
D.Pois[370] = {
    { "s", 612, 432, "Mossward", "" },
}
D.Pois[380] = {
    { "r", 548, 319, "Gwathrenost, the Witch-king's Citadel", "Gwathrenost, la Ciudadela del Rey Brujo" },
}
D.Pois[386] = {
    { "c", 159, 403, "Dol Amroth", "" },
    { "c", 549, 500, "Linhir", "" },
    { "c", 705, 517, "Pelargir", "" },
    { "d", 921, 375, "The Quays of the Harlond", "Los Muelles del Harlond" },
    { "d", 912, 265, "The Silent Street", "La Calle Silenciosa" },
    { "s", 299, 389, "Tadrent", "" },
    { "s", 194, 197, "", "" },
    { "s", 343, 229, "Dínadab", "" },
    { "s", 597, 478, "Malbarth", "" },
    { "s", 631, 531, "Aerthir", "" },
    { "s", 644, 465, "Ost Anglebed", "" },
    { "s", 706, 523, "Pelargir", "", "far" },
    { "s", 712, 445, "Zarsatrâd", "" },
    { "s", 737, 482, "Erynos", "" },
    { "s", 754, 520, "Pelargir East Gate", "", "far" },
    { "s", 150, 411, "Dol Amroth", "", "far" },
    { "s", 781, 492, "Glaniath", "" },
    { "s", 861, 423, "Arnach", "" },
    { "s", 249, 402, "Ost Lontir", "" },
    { "s", 927, 369, "The Harlond", "" },
    { "s", 466, 480, "Parth Rest", "" },
    { "s", 476, 559, "Dor-en-Ernil", "" },
    { "s", 555, 506, "Linhir", "" },
    { "s", 380, 245, "Lothgobel", "" },
    { "s", 407, 288, "Calembel", "" },
    { "s", 481, 363, "Ethring", "" },
    { "s", 795, 438, "Tumladen", "" },
    { "s", 829, 501, "Harlach", "" },
    { "s", 874, 389, "", "" },
    { "s", 224, 137, "Morlad", "" },
    { "s", 290, 155, "Lancrath", "" },
    { "s", 703, 343, "Furukzahar", "" },
    { "s", 544, 490, "Linhir", "" },
}
D.Pois[387] = {
    { "d", 824, 228, "The Quays of the Harlond", "Los Muelles del Harlond" },
    { "s", 581, 425, "Arnach", "" },
    { "s", 847, 204, "The Harlond", "" },
    { "s", 632, 287, "", "" },
}
D.Pois[388] = {
    { "s", 272, 399, "Erynos", "" },
    { "s", 356, 591, "Pelargir East Gate", "", "far" },
    { "s", 494, 449, "Glaniath", "" },
    { "s", 564, 173, "Tumladen", "" },
    { "s", 737, 494, "Harlach", "" },
}
D.Pois[389] = {
    { "c", 294, 510, "Linhir", "" },
    { "c", 736, 558, "Pelargir", "" },
    { "s", 430, 446, "Malbarth", "" },
    { "s", 526, 596, "Aerthir", "" },
    { "s", 564, 410, "Ost Anglebed", "" },
    { "s", 740, 573, "Pelargir", "", "far" },
    { "s", 756, 353, "Zarsatrâd", "" },
    { "s", 828, 459, "Erynos", "" },
    { "s", 312, 527, "Linhir", "" },
    { "s", 729, 63, "Furukzahar", "" },
    { "s", 280, 482, "Linhir", "" },
}
D.Pois[390] = {
    { "c", 325, 322, "Pelargir", "" },
    { "s", 336, 362, "Pelargir", "", "far" },
    { "s", 681, 344, "Pelargir East Gate", "", "far" },
}
D.Pois[393] = {
    { "s", 566, 238, "Ethring", "" },
}
D.Pois[394] = {
    { "s", 458, 203, "Dínadab", "" },
    { "s", 599, 263, "Lothgobel", "" },
    { "s", 702, 427, "Calembel", "" },
}
D.Pois[395] = {
    { "c", 701, 354, "Linhir", "" },
    { "s", 896, 261, "Malbarth", "" },
    { "s", 362, 272, "Parth Rest", "" },
    { "s", 403, 592, "Dor-en-Ernil", "" },
    { "s", 727, 377, "Linhir", "" },
    { "s", 681, 313, "Linhir", "" },
}
D.Pois[396] = {
    { "s", 408, 416, "", "" },
    { "s", 515, 199, "Morlad", "" },
    { "s", 753, 264, "Lancrath", "" },
}
D.Pois[397] = {
    { "c", 364, 170, "Dol Amroth", "" },
    { "s", 649, 143, "Tadrent", "" },
    { "s", 346, 186, "Dol Amroth", "", "far" },
    { "s", 547, 169, "Ost Lontir", "" },
    { "s", 538, 589, "", "", "far" },
}
D.Pois[398] = {
    { "c", 570, 373, "Dol Amroth", "" },
    { "s", 497, 442, "Dol Amroth", "", "far" },
}
D.Pois[399] = {
    { "s", 919, 414, "", "" },
    { "s", 209, 391, "Iáphel", "" },
    { "s", 490, 165, "Ost Arndir", "" },
    { "s", 570, 317, "Mereham", "" },
    { "s", 357, 646, "Lond Cirion", "", "far" },
    { "s", 978, 295, "", "" },
    { "s", 571, 591, "Barad Faen", "" },
    { "s", 701, 639, "Melgobas", "" },
}
D.Pois[400] = {
    { "s", 247, 514, "Iáphel", "" },
    { "s", 619, 215, "Ost Arndir", "" },
    { "s", 726, 417, "Mereham", "" },
}
D.Pois[401] = {
    { "s", 915, 220, "", "" },
    { "s", 310, 469, "Lond Cirion", "", "far" },
    { "s", 541, 409, "Barad Faen", "" },
    { "s", 680, 461, "Melgobas", "" },
}
D.Pois[403] = {
    { "c", 480, 571, "Halrax", "" },
    { "e", 596, 612, "Proto-beast", "", "Great Elite|146" },
    { "e", 635, 649, "Proto-crab\nProto-huorn", "", "Great Elite|150\nGreat Elite|146" },
    { "e", 589, 655, "Proto-crow", "", "Great Elite|149" },
    { "e", 669, 649, "Proto-salamender", "", "Elite|146" },
    { "t", 136, 93, "Treasure Cache", "" },
    { "t", 157, 194, "Treasure Cache", "" },
    { "t", 292, 230, "Treasure Cache", "" },
    { "t", 280, 270, "Treasure Cache", "" },
    { "t", 415, 313, "Treasure Cache", "" },
    { "t", 323, 414, "Treasure Cache", "" },
    { "t", 390, 420, "Treasure Cache", "" },
    { "t", 289, 469, "Treasure Cache", "" },
    { "t", 366, 502, "Treasure Cache", "" },
    { "t", 534, 554, "Treasure Cache", "" },
    { "t", 384, 576, "Treasure Cache", "" },
    { "t", 611, 597, "Treasure Cache", "" },
    { "t", 629, 634, "Treasure Cache", "" },
    { "t", 476, 670, "Treasure Cache", "" },
}
D.Pois[404] = {
    { "c", 673, 413, "Umbar Baharbêl", "" },
    { "r", 443, 422, "Depths of Mâkhda Khorbo", "Profundidades de Mâkhda Khorbo" },
    { "d", 752, 388, "Dahâl Huliz, The Arena\nThe Dragon and the Storm", "Dahâl Huliz, la Arena\nEl Dragón y la Tormenta" },
    { "s", 78, 585, "Rakhatâb", "" },
    { "s", 328, 374, "Khûtra", "" },
    { "s", 122, 212, "Jax Phanâl", "" },
    { "s", 677, 465, "Jâshadar", "" },
    { "s", 676, 396, "Mâr Bahir", "" },
    { "s", 582, 352, "Mâr Bahir", "" },
    { "s", 689, 444, "Râhal Bakh", "" },
    { "s", 727, 422, "Râhal Bakh", "" },
    { "s", 678, 316, "Râhal Ghol", "" },
    { "s", 704, 537, "Thargushakâl", "" },
    { "s", 791, 513, "Thargushakâl", "" },
    { "t", 150, 218, "Treasure Cache", "" },
    { "t", 191, 367, "Treasure Cache", "" },
    { "t", 133, 428, "Treasure Cache", "" },
    { "t", 83, 509, "Treasure Cache", "" },
    { "t", 272, 388, "Treasure Cache", "" },
    { "t", 495, 404, "Treasure Cache", "" },
    { "t", 532, 401, "Treasure Cache", "" },
    { "t", 522, 300, "Treasure Cache", "" },
    { "t", 546, 273, "Treasure Cache", "" },
    { "t", 583, 232, "Treasure Cache", "" },
    { "t", 603, 218, "Treasure Cache", "" },
    { "t", 688, 232, "Treasure Cache", "" },
    { "t", 796, 293, "Treasure Cache", "" },
    { "t", 884, 215, "Treasure Cache", "" },
    { "t", 894, 306, "Treasure Cache", "" },
    { "t", 847, 384, "Treasure Cache", "" },
    { "t", 843, 472, "Treasure Cache", "" },
    { "t", 962, 452, "Treasure Cache", "" },
    { "t", 928, 409, "Treasure Cache", "" },
}
D.Pois[405] = {
    { "c", 561, 296, "Umbar Baharbêl", "" },
    { "d", 712, 247, "Dahâl Huliz, The Arena\nThe Dragon and the Storm", "Dahâl Huliz, la Arena\nEl Dragón y la Tormenta" },
    { "s", 568, 394, "Jâshadar", "" },
    { "s", 568, 264, "Mâr Bahir", "" },
    { "s", 387, 180, "Mâr Bahir", "" },
    { "s", 592, 353, "Râhal Bakh", "" },
    { "s", 665, 312, "Râhal Bakh", "" },
    { "s", 571, 111, "Râhal Ghol", "" },
    { "s", 621, 531, "Thargushakâl", "" },
    { "s", 785, 484, "Thargushakâl", "" },
    { "t", 222, 279, "Treasure Cache", "" },
    { "t", 293, 273, "Treasure Cache", "" },
    { "t", 892, 241, "Treasure Cache", "" },
    { "t", 886, 407, "Treasure Cache", "" },
}
D.Pois[419] = {
    { "d", 217, 514, "Nirgambâr, the Restless Tomb", "Nirgambâr, la Tumba Inquieta" },
    { "s", 334, 284, "", "" },
    { "s", 665, 192, "Shengarâsh", "" },
    { "s", 348, 572, "", "", "far" },
    { "s", 453, 562, "Ghalbûru", "" },
    { "s", 463, 709, "", "" },
    { "s", 841, 372, "", "" },
    { "s", 629, 653, "", "" },
    { "s", 673, 310, "Ub Nishir", "", "far" },
    { "s", 682, 374, "Ilzag Khûl", "" },
    { "s", 778, 220, "Nêruzig", "" },
    { "s", 266, 351, "Gha Nêkha", "" },
    { "s", 680, 595, "Kûr Anzar", "" },
    { "s", 595, 577, "Urmâkh", "" },
    { "s", 395, 387, "Wrackwade crossing", "" },
    { "t", 483, 408, "Ambarûl", "" },
    { "t", 248, 215, "Ambarûli Treasure Cache", "" },
    { "t", 235, 246, "Ambarûli Treasure Cache", "" },
    { "t", 301, 168, "Ambarûli Treasure Cache", "" },
    { "t", 363, 292, "Ambarûli Treasure Cache", "" },
    { "t", 421, 255, "Ambarûli Treasure Cache", "" },
    { "t", 303, 304, "Ambarûli Treasure Cache", "" },
    { "t", 188, 312, "Ambarûli Treasure Cache", "" },
    { "t", 240, 409, "Ambarûli Treasure Cache", "" },
    { "t", 310, 404, "Ekhamâti Treasure Cache", "" },
    { "t", 282, 684, "Ekhamâti Treasure Cache", "" },
    { "t", 417, 509, "Ekhamâti Treasure Cache", "" },
    { "t", 425, 594, "Ekhamâti Treasure Cache", "" },
    { "t", 436, 606, "Ekhamâti Treasure Cache", "" },
    { "t", 492, 486, "Imhûlar", "" },
    { "t", 593, 532, "Imhûlari Treasure Cache", "" },
    { "t", 568, 565, "Imhûlari Treasure Cache", "" },
    { "t", 627, 648, "Imhûlari Treasure Cache", "" },
    { "t", 662, 674, "Imhûlari Treasure Cache", "" },
    { "t", 664, 629, "Imhûlari Treasure Cache", "" },
    { "t", 803, 604, "Imhûlari Treasure Cache", "" },
    { "t", 685, 502, "Imhûlari Treasure Cache", "" },
    { "t", 710, 477, "Imhûlari Treasure Cache", "" },
    { "t", 151, 470, "Khûd Zagin", "" },
    { "t", 195, 524, "Khûd Zagin", "" },
    { "t", 215, 566, "Khûd Zagin", "" },
    { "t", 314, 617, "Khûd Zagin", "" },
    { "t", 374, 664, "Khûdi Treasure Cache", "" },
    { "t", 216, 661, "Khûdi Treasure Cache", "" },
    { "t", 144, 318, "Khûdi Treasure Cache", "" },
    { "t", 350, 514, "Khûdi Treasure Cache", "" },
    { "t", 257, 530, "Khûdi Treasure Cache", "" },
    { "t", 355, 580, "Khûdi Treasure Cache", "" },
    { "t", 316, 470, "Khûdi Treasure Cache", "" },
    { "t", 184, 552, "Khûdi Treasure Cache", "" },
    { "t", 483, 294, "Treasure-seeker of Urash Dâr", "" },
    { "t", 572, 274, "Treasure-seeker of Urash Dâr", "" },
    { "t", 574, 185, "Treasure-seeker of Urash Dâr", "" },
    { "t", 681, 316, "Treasure-seeker of Urash Dâr", "" },
    { "t", 701, 248, "Treasure-seeker of Urash Dâr", "" },
    { "t", 712, 450, "Treasure-seeker of Urash Dâr", "" },
    { "t", 757, 243, "Treasure-seeker of Urash Dâr", "" },
    { "t", 775, 214, "Treasure-seeker of Urash Dâr", "" },
    { "t", 777, 258, "Treasure-seeker of Urash Dâr", "" },
    { "t", 824, 276, "Treasure-seeker of Urash Dâr", "" },
    { "t", 835, 377, "Treasure-seeker of Urash Dâr", "" },
    { "t", 314, 179, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 327, 216, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 360, 259, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 373, 143, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 389, 158, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 412, 143, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 478, 484, "[Hidden] The Lion's Roar", "" },
}
D.Pois[420] = {
    { "s", 553, 415, "", "" },
    { "s", 429, 539, "Gha Nêkha", "" },
    { "s", 665, 603, "Wrackwade crossing", "" },
    { "t", 826, 643, "Ambarûl", "" },
    { "t", 395, 290, "Ambarûli Treasure Cache", "" },
    { "t", 361, 194, "Ambarûli Treasure Cache", "" },
    { "t", 373, 346, "Ambarûli Treasure Cache", "" },
    { "t", 492, 204, "Ambarûli Treasure Cache", "" },
    { "t", 606, 430, "Ambarûli Treasure Cache", "" },
    { "t", 712, 363, "Ambarûli Treasure Cache", "" },
    { "t", 496, 452, "Ambarûli Treasure Cache", "" },
    { "t", 286, 466, "Ambarûli Treasure Cache", "" },
    { "t", 382, 645, "Ambarûli Treasure Cache", "" },
    { "t", 510, 634, "Ekhamâti Treasure Cache", "" },
    { "t", 528, 623, "Ekhamâti Treasure Cache", "" },
    { "t", 207, 478, "Khûdi Treasure Cache", "" },
    { "t", 826, 434, "Treasure-seeker of Urash Dâr", "" },
    { "t", 518, 225, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 541, 291, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 600, 371, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 624, 158, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 653, 185, "[Hidden] Cliff-diver of Ambarûl", "" },
    { "t", 696, 158, "[Hidden] Cliff-diver of Ambarûl", "" },
}
D.Pois[421] = {
    { "r", 829, 80, "The Temple of Utug-bûr", "El Templo de Utug-bûr" },
    { "s", 465, 197, "Shengarâsh", "" },
    { "s", 787, 525, "", "" },
    { "s", 481, 411, "Ub Nishir", "", "far" },
    { "s", 497, 528, "Ilzag Khûl", "" },
    { "s", 672, 246, "Nêruzig", "" },
    { "t", 151, 733, "Imhûlar", "" },
    { "t", 549, 717, "Imhûlari Treasure Cache", "" },
    { "t", 134, 382, "Treasure-seeker of Urash Dâr", "" },
    { "t", 296, 345, "Treasure-seeker of Urash Dâr", "" },
    { "t", 495, 422, "Treasure-seeker of Urash Dâr", "" },
    { "t", 531, 299, "Treasure-seeker of Urash Dâr", "" },
    { "t", 551, 667, "Treasure-seeker of Urash Dâr", "" },
    { "t", 634, 289, "Treasure-seeker of Urash Dâr", "" },
    { "t", 667, 236, "Treasure-seeker of Urash Dâr", "" },
    { "t", 670, 316, "Treasure-seeker of Urash Dâr", "" },
    { "t", 756, 349, "Treasure-seeker of Urash Dâr", "" },
    { "t", 776, 534, "Treasure-seeker of Urash Dâr", "" },
    { "t", 124, 730, "[Hidden] The Lion's Roar", "" },
}
D.Pois[422] = {
    { "d", 356, 685, "Dun Shûma, The King's Fortress", "Dun Shûma, la Fortaleza del Rey" },
    { "d", 294, 361, "Nirgambâr, the Restless Tomb", "Nirgambâr, la Tumba Inquieta" },
    { "s", 504, 454, "", "", "far" },
    { "s", 673, 437, "Ghalbûru", "" },
    { "s", 690, 673, "", "" },
    { "s", 955, 584, "", "" },
    { "s", 168, 278, "Zadûru", "" },
    { "s", 580, 157, "Wrackwade crossing", "" },
    { "t", 722, 191, "Ambarûl", "" },
    { "t", 330, 194, "Ambarûli Treasure Cache", "" },
    { "t", 443, 184, "Ekhamâti Treasure Cache", "" },
    { "t", 459, 174, "Ekhamâti Treasure Cache", "" },
    { "t", 363, 684, "Ekhamâti Treasure Cache", "" },
    { "t", 398, 634, "Ekhamâti Treasure Cache", "" },
    { "t", 614, 352, "Ekhamâti Treasure Cache", "" },
    { "t", 612, 364, "Ekhamâti Treasure Cache", "" },
    { "t", 628, 489, "Ekhamâti Treasure Cache", "" },
    { "t", 646, 508, "Ekhamâti Treasure Cache", "" },
    { "t", 736, 316, "Imhûlar", "" },
    { "t", 898, 390, "Imhûlari Treasure Cache", "" },
    { "t", 858, 443, "Imhûlari Treasure Cache", "" },
    { "t", 953, 576, "Imhûlari Treasure Cache", "" },
    { "t", 188, 290, "Khûd Zagin", "" },
    { "t", 258, 378, "Khûd Zagin", "" },
    { "t", 290, 444, "Khûd Zagin", "" },
    { "t", 450, 526, "Khûd Zagin", "" },
    { "t", 546, 601, "Khûdi Treasure Cache", "" },
    { "t", 292, 596, "Khûdi Treasure Cache", "" },
    { "t", 507, 361, "Khûdi Treasure Cache", "" },
    { "t", 358, 386, "Khûdi Treasure Cache", "" },
    { "t", 516, 467, "Khûdi Treasure Cache", "" },
    { "t", 452, 291, "Khûdi Treasure Cache", "" },
    { "t", 240, 421, "Khûdi Treasure Cache", "" },
    { "t", 713, 314, "[Hidden] The Lion's Roar", "" },
}
D.Pois[423] = {
    { "d", 760, 516, "Tûl Zakana, the Well of Forgetting", "Tûl Zakana, el Pozo del Olvido" },
    { "s", 158, 391, "Ghalbûru", "" },
    { "s", 479, 558, "", "" },
    { "s", 573, 451, "Kûr Anzar", "" },
    { "s", 417, 420, "Urmâkh", "" },
    { "t", 214, 111, "Ambarûl", "" },
    { "t", 92, 294, "Ekhamâti Treasure Cache", "" },
    { "t", 90, 307, "Ekhamâti Treasure Cache", "" },
    { "t", 612, 658, "Ekhamâti Treasure Cache", "" },
    { "t", 664, 680, "Ekhamâti Treasure Cache", "" },
    { "t", 230, 253, "Imhûlar", "" },
    { "t", 722, 635, "Imhûlari Treasure Cache", "" },
    { "t", 413, 338, "Imhûlari Treasure Cache", "" },
    { "t", 368, 398, "Imhûlari Treasure Cache", "" },
    { "t", 766, 527, "Imhûlari Treasure Cache", "" },
    { "t", 771, 499, "Imhûlari Treasure Cache", "" },
    { "t", 476, 549, "Imhûlari Treasure Cache", "" },
    { "t", 539, 596, "Imhûlari Treasure Cache", "" },
    { "t", 543, 515, "Imhûlari Treasure Cache", "" },
    { "t", 798, 469, "Imhûlari Treasure Cache", "" },
    { "t", 581, 282, "Imhûlari Treasure Cache", "" },
    { "t", 628, 237, "Imhûlari Treasure Cache", "" },
    { "t", 631, 187, "Treasure-seeker of Urash Dâr", "" },
    { "t", 204, 250, "[Hidden] The Lion's Roar", "" },
}
D.Pois[440] = {
    { "c", 162, 671, "Emax Dûl", "" },
    { "c", 533, 607, "Zajâna", "" },
    { "d", 175, 648, "Ekal-nêbi, the Fallen Palace", "Ekal-nêbi, el Palacio Caído" },
    { "d", 382, 574, "Kôth Rau, the Wailing Hold", "Kôth Rau, la Fortaleza del Lamento" },
    { "d", 498, 573, "The Treasure Caves of Hurum Kâna", "Las Cuevas del Tesoro de Hurum Kâna" },
    { "e", 673, 559, "Bloodtooth", "", "Nemesis|160" },
    { "e", 335, 583, "Daithor, Terror of An Sheru", "", "Nemesis|160" },
    { "e", 142, 492, "Imtushal the Gall-spitter", "", "Nemesis|160" },
    { "s", 150, 536, "Dur Nâgu", "" },
    { "s", 766, 276, "Laivárth", "" },
    { "s", 173, 651, "Nashûbu", "" },
    { "s", 239, 515, "", "", "far" },
    { "s", 333, 459, "Jiret-menêsh", "", "far" },
    { "s", 397, 526, "Khanág Gur", "" },
    { "s", 612, 595, "Ingar-garâsh", "" },
    { "s", 470, 443, "Gadim-ûn", "" },
    { "s", 528, 516, "Sen Chatâk", "" },
    { "s", 674, 528, "Sormedân", "" },
    { "s", 785, 402, "Sâr Marsag", "" },
    { "s", 544, 602, "Zajâna", "" },
    { "t", 760, 275, "Adagím Treasure Cache", "" },
    { "t", 786, 399, "Adagím Treasure Cache", "" },
    { "t", 833, 289, "Adagím Treasure Cache", "" },
    { "t", 888, 270, "Adagím Treasure Cache", "" },
    { "t", 706, 364, "Adagím Treasure Cache", "" },
    { "t", 707, 448, "Adagím Treasure Cache", "" },
    { "t", 794, 357, "Adagím Treasure Cache", "" },
    { "t", 286, 532, "An Shêru Treasure Cache", "" },
    { "t", 295, 598, "An Shêru Treasure Cache", "" },
    { "t", 363, 583, "An Shêru Treasure Cache", "" },
    { "t", 416, 557, "An Shêru Treasure Cache", "" },
    { "t", 460, 411, "An Shêru Treasure Cache", "" },
    { "t", 483, 540, "An Shêru Treasure Cache", "" },
    { "t", 474, 495, "An Shêru Treasure Cache", "" },
    { "t", 436, 485, "An Shêru Treasure Cache", "" },
    { "t", 355, 421, "An Shêru Treasure Cache", "" },
    { "t", 356, 477, "An Shêru Treasure Cache", "" },
    { "t", 339, 453, "An Shêru Treasure Cache", "" },
    { "t", 358, 558, "An Shêru Treasure Cache", "" },
    { "t", 210, 405, "Idagâl", "" },
    { "t", 158, 591, "Idagâl Treasure Cache", "" },
    { "t", 234, 447, "Idagâl Treasure Cache", "" },
    { "t", 198, 428, "Idagâl Treasure Cache", "" },
    { "t", 155, 448, "Idagâl Treasure Cache", "" },
    { "t", 160, 698, "Idagâl Treasure Cache", "" },
    { "t", 529, 587, "Kighân Treasure Cache", "" },
    { "t", 658, 524, "Kighân Treasure Cache", "" },
    { "t", 636, 495, "Kighân Treasure Cache", "" },
    { "t", 647, 462, "Kighân Treasure Cache", "" },
    { "t", 551, 512, "Kighân Treasure Cache", "" },
    { "t", 552, 496, "Kighân Treasure Cache", "" },
    { "t", 553, 430, "Kighân Treasure Cache", "" },
    { "t", 571, 597, "Kighân Treasure Cache", "" },
    { "t", 610, 545, "Kighân Treasure Cache", "" },
    { "t", 701, 593, "Kighân Treasure Cache", "" },
}
D.Pois[441] = {
    { "c", 564, 662, "Emax Dûl", "" },
    { "d", 581, 632, "Ekal-nêbi, the Fallen Palace", "Ekal-nêbi, el Palacio Caído" },
    { "e", 526, 350, "Imtushal the Gall-spitter", "", "Nemesis|160" },
    { "s", 540, 428, "Dur Nâgu", "" },
    { "s", 580, 632, "Nashûbu", "" },
    { "s", 697, 390, "", "", "far" },
    { "s", 367, 227, "The Dawn-warden", "" },
    { "t", 780, 421, "An Shêru Treasure Cache", "" },
    { "t", 646, 194, "Idagâl", "" },
    { "t", 381, 204, "Idagâl Treasure Cache", "" },
    { "t", 553, 526, "Idagâl Treasure Cache", "" },
    { "t", 369, 77, "Idagâl Treasure Cache", "" },
    { "t", 482, 232, "Idagâl Treasure Cache", "" },
    { "t", 383, 291, "Idagâl Treasure Cache", "" },
    { "t", 688, 269, "Idagâl Treasure Cache", "" },
    { "t", 625, 236, "Idagâl Treasure Cache", "" },
    { "t", 549, 271, "Idagâl Treasure Cache", "" },
    { "t", 361, 336, "Idagâl Treasure Cache", "" },
    { "t", 468, 365, "Idagâl Treasure Cache", "" },
    { "t", 558, 717, "Idagâl Treasure Cache", "" },
}
D.Pois[442] = {
    { "c", 467, 491, "Emax Dûl", "" },
    { "d", 535, 368, "Ekal-nêbi, the Fallen Palace", "Ekal-nêbi, el Palacio Caído" },
    { "s", 531, 367, "Nashûbu", "" },
}
D.Pois[443] = {
    { "d", 506, 572, "Kôth Rau, the Wailing Hold", "Kôth Rau, la Fortaleza del Lamento" },
    { "d", 817, 568, "The Treasure Caves of Hurum Kâna", "Las Cuevas del Tesoro de Hurum Kâna" },
    { "e", 384, 595, "Daithor, Terror of An Sheru", "", "Nemesis|160" },
    { "s", 376, 265, "Jiret-menêsh", "", "far" },
    { "s", 548, 444, "Khanág Gur", "" },
    { "s", 742, 222, "Gadim-ûn", "" },
    { "s", 897, 418, "Sen Chatâk", "" },
    { "t", 251, 461, "An Shêru Treasure Cache", "" },
    { "t", 275, 636, "An Shêru Treasure Cache", "" },
    { "t", 456, 595, "An Shêru Treasure Cache", "" },
    { "t", 599, 527, "An Shêru Treasure Cache", "" },
    { "t", 715, 138, "An Shêru Treasure Cache", "" },
    { "t", 777, 482, "An Shêru Treasure Cache", "" },
    { "t", 752, 361, "An Shêru Treasure Cache", "" },
    { "t", 652, 335, "An Shêru Treasure Cache", "" },
    { "t", 437, 164, "An Shêru Treasure Cache", "" },
    { "t", 440, 313, "An Shêru Treasure Cache", "" },
    { "t", 392, 249, "An Shêru Treasure Cache", "" },
    { "t", 444, 528, "An Shêru Treasure Cache", "" },
    { "t", 899, 606, "Kighân Treasure Cache", "" },
}
D.Pois[444] = {
    { "c", 268, 543, "Zajâna", "" },
    { "d", 188, 464, "The Treasure Caves of Hurum Kâna", "Las Cuevas del Tesoro de Hurum Kâna" },
    { "e", 589, 432, "Bloodtooth", "", "Nemesis|160" },
    { "s", 450, 516, "Ingar-garâsh", "" },
    { "s", 257, 333, "Sen Chatâk", "" },
    { "s", 591, 360, "Sormedân", "" },
    { "s", 846, 68, "Sâr Marsag", "" },
    { "s", 292, 531, "Zajâna", "" },
    { "t", 848, 62, "Adagím Treasure Cache", "" },
    { "t", 668, 175, "Adagím Treasure Cache", "" },
    { "t", 258, 496, "Kighân Treasure Cache", "" },
    { "t", 675, 410, "Kighân Treasure Cache", "" },
    { "t", 555, 351, "Kighân Treasure Cache", "" },
    { "t", 504, 283, "Kighân Treasure Cache", "" },
    { "t", 529, 208, "Kighân Treasure Cache", "" },
    { "t", 310, 323, "Kighân Treasure Cache", "" },
    { "t", 310, 287, "Kighân Treasure Cache", "" },
    { "t", 313, 132, "Kighân Treasure Cache", "" },
    { "t", 355, 519, "Kighân Treasure Cache", "" },
    { "t", 444, 398, "Kighân Treasure Cache", "" },
    { "t", 783, 340, "Kighân Treasure Cache", "" },
    { "t", 654, 510, "Kighân Treasure Cache", "" },
}
D.Pois[445] = {
    { "c", 601, 154, "Zajâna", "" },
    { "s", 687, 112, "Zajâna", "" },
}
D.Pois[446] = {
    { "r", 800, 707, "The Folly of Nagakhêdi", "La Locura de Nagakhêdi" },
    { "e", 834, 590, "Agathar the Bereft", "", "Nemesis|160" },
    { "s", 726, 690, "Nagakhêdi", "" },
    { "s", 400, 277, "Laivárth", "" },
    { "s", 704, 537, "Sul Madásh", "", "far" },
    { "s", 441, 555, "Sâr Marsag", "" },
    { "t", 386, 275, "Adagím Treasure Cache", "" },
    { "t", 561, 582, "Adagím Treasure Cache", "" },
    { "t", 443, 549, "Adagím Treasure Cache", "" },
    { "t", 547, 306, "Adagím Treasure Cache", "" },
    { "t", 668, 263, "Adagím Treasure Cache", "" },
    { "t", 267, 472, "Adagím Treasure Cache", "" },
    { "t", 270, 658, "Adagím Treasure Cache", "" },
    { "t", 719, 685, "Adagím Treasure Cache", "" },
    { "t", 835, 689, "Adagím Treasure Cache", "" },
    { "t", 720, 525, "Adagím Treasure Cache", "" },
    { "t", 460, 457, "Adagím Treasure Cache", "" },
    { "t", 483, 464, "Adagím Treasure Cache", "" },
}
D.Pois[458] = {
    { "d", 812, 534, "Pagru-kirít, the Garden of Corpses", "Pagru-kirít, el Jardín de Cadáveres" },
    { "e", 279, 502, "Zâkhabat the Malice-eater", "", "Nemesis|160" },
    { "s", 316, 186, "Hanamíku", "", "far" },
    { "s", 549, 427, "Ingarûma", "" },
    { "t", 631, 411, "Hatokáli Fells", "" },
    { "t", 165, 180, "Hatokáli Fells Treasure Cache", "" },
    { "t", 194, 577, "Hatokáli Fells Treasure Cache", "" },
    { "t", 340, 620, "Hatokáli Fells Treasure Cache", "" },
    { "t", 411, 327, "Hatokáli Fells Treasure Cache", "" },
    { "t", 374, 198, "Hatokáli Fells Treasure Cache", "" },
    { "t", 655, 445, "Hatokáli Fells Treasure Cache", "" },
    { "t", 880, 441, "Hatokáli Fells Treasure Cache", "" },
    { "t", 443, 501, "Hatokáli Fells Treasure Cache", "" },
    { "t", 445, 447, "Hatokáli Fells Treasure Cache", "" },
    { "t", 267, 465, "Hatokáli Fells Treasure Cache", "" },
}
D.Pois[463] = {
    { "c", 790, 526, "Rivendell", "Rivendel" },
    { "s", 614, 533, "", "", "far" },
    { "s", 806, 629, "Rivendell", "", "far" },
}
