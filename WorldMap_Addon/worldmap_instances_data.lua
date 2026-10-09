-- WorldMap_Addon/worldmap_instances_data.lua
-- v3.7: mapas interiores de incursiones y mazmorras y su ficha (niveles,
-- jugadores, jefes con su sala). Fuente: datos/LOTRO_Raids_y_Mazmorras
-- (LotroCompanion lotro-data + lotro-maps-db). Las posiciones de jefes NO
-- v3.7.1: jefes con nombre en su posicion del marcador del juego.
-- Archivo GENERADO: no editar a mano.

_G.WorldMapAddon = _G.WorldMapAddon or {}
local D = { Maps = {}, Inst = {}, ByName = {} }
WorldMapAddon.InstanceData = D
D.Maps[1879048289] = { img = 1090542890, w = 1600, h = 1200, en = "Castle of the Witch-king", es = "Castillo del Rey Brujo" }
D.Maps[1879051227] = { img = 1090551229, w = 800, h = 600, en = "Carn Dûm Sewers", es = "Alcantarillas de Carn Dûm" }
D.Maps[1879051243] = { img = 1090551220, w = 800, h = 600, en = "Barad Eithel", es = "Barad Eithel" }
D.Maps[1879051244] = { img = 1090551221, w = 800, h = 600, en = "Barad Harn", es = "Barad Harn" }
D.Maps[1879051245] = { img = 1090551222, w = 800, h = 600, en = "Barad Narthan", es = "Barad Narthan" }
D.Maps[1879051246] = { img = 1090551223, w = 800, h = 600, en = "Minas Erain", es = "Minas Erain" }
D.Maps[1879076058] = { img = 1090561668, w = 1600, h = 1200, en = "Carn Dûm Sewers", es = "Alcantarillas de Carn Dûm" }
D.Maps[1879084150] = { img = 1090640290, w = 800, h = 600, en = "Tunnel to Asht-Shâpol", es = "Túnel a Asht-Shâpol" }
D.Maps[1879087106] = { img = 1090645943, w = 1600, h = 1200, en = "Barad Gúlaran", es = "Barad Gúlaran" }
D.Maps[1879101482] = { img = 1091404129, w = 800, h = 600, en = "Bornabar", es = "Bornabar" }
D.Maps[1879101483] = { img = 1091404131, w = 1600, h = 1200, en = "Upper Noruidor", es = "Upper Noruidor" }
D.Maps[1879101485] = { img = 1091404124, w = 800, h = 600, en = "Norbar", es = "Norbar" }
D.Maps[1879101486] = { img = 1091404125, w = 800, h = 600, en = "Norbar Approach", es = "Norbar Approach" }
D.Maps[1879101489] = { img = 1091404126, w = 800, h = 600, en = "Gorthban", es = "Gorthban" }
D.Maps[1879101491] = { img = 1091404128, w = 800, h = 600, en = "Lower Noruidor", es = "Lower Noruidor" }
D.Maps[1879101643] = { img = 1091409934, w = 800, h = 600, en = "The Great Goblin's Den", es = "La Guarida del Gran Trasgo" }
D.Maps[1879102227] = { img = 1091413221, w = 1600, h = 1200, en = "Norbar", es = "Norbar" }
D.Maps[1879138594] = { img = 1091481121, w = 1600, h = 1200, en = "Skûmfil", es = "Skûmfil" }
D.Maps[1879138595] = { img = 1091494940, w = 1600, h = 1200, en = "The Forges of Khazad-dûm", es = "Las Forjas de Khazad-dûm" }
D.Maps[1879138596] = { img = 1091480128, w = 1600, h = 1200, en = "Fil Gashan", es = "Fil Gashan" }
D.Maps[1879138597] = { img = 1091481129, w = 1600, h = 1200, en = "Dark Delvings", es = "Excavaciones Tenebrosas" }
D.Maps[1879138598] = { img = 1091481124, w = 1600, h = 1200, en = "The Sixteenth Hall", es = "La Decimosexta Sala" }
D.Maps[1879138599] = { img = 1091481125, w = 1600, h = 1200, en = "The Forgotten Treasury", es = "El Tesoro Olvidado" }
D.Maps[1879145196] = { img = 1091480131, w = 1600, h = 1200, en = "Fil Gashan", es = "Fil Gashan" }
D.Maps[1879145197] = { img = 1091480127, w = 1600, h = 1200, en = "Fil Gashan", es = "Fil Gashan" }
D.Maps[1879145612] = { img = 1091494945, w = 800, h = 600, en = "The Forges of Khazad-dûm", es = "Las Forjas de Khazad-dûm" }
D.Maps[1879145613] = { img = 1091494944, w = 800, h = 600, en = "The Forges of Khazad-dûm", es = "Las Forjas de Khazad-dûm" }
D.Maps[1879149567] = { img = 1091531018, w = 800, h = 600, en = "Filikul", es = "Filikul" }
D.Maps[1879152319] = { img = 1091543402, w = 800, h = 600, en = "Dâr Narbugud", es = "Dâr Narbugud" }
D.Maps[1879152320] = { img = 1091543403, w = 800, h = 600, en = "Dâr Narbugud", es = "Dâr Narbugud" }
D.Maps[1879152321] = { img = 1091543404, w = 800, h = 600, en = "Dâr Narbugud", es = "Dâr Narbugud" }
D.Maps[1879152343] = { img = 1091547183, w = 800, h = 600, en = "Halls of Crafting", es = "Salones de Artesanía" }
D.Maps[1879153146] = { img = 1091545390, w = 1600, h = 1200, en = "The Mirror-halls of Lumul-nar", es = "Las Salas de los Espejos de Lumul-nar" }
D.Maps[1879153147] = { img = 1091545271, w = 1600, h = 1200, en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm" }
D.Maps[1879153148] = { img = 1091545268, w = 1600, h = 1200, en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm" }
D.Maps[1879153149] = { img = 1091545275, w = 1600, h = 1200, en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm" }
D.Maps[1879153150] = { img = 1091545270, w = 1600, h = 1200, en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm" }
D.Maps[1879153210] = { img = 1091545277, w = 800, h = 600, en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm" }
D.Maps[1879153312] = { img = 1091545385, w = 800, h = 600, en = "The Mirror-halls of Lumul-nar", es = "Las Salas de los Espejos de Lumul-nar" }
D.Maps[1879153314] = { img = 1091545384, w = 800, h = 600, en = "The Mirror-halls of Lumul-nar", es = "Las Salas de los Espejos de Lumul-nar" }
D.Maps[1879159718] = { img = 1091563620, w = 800, h = 600, en = "Dâr Narbugud", es = "Dâr Narbugud" }
D.Maps[1879159719] = { img = 1091563621, w = 800, h = 600, en = "Halls of Crafting", es = "Salones de Artesanía" }
D.Maps[1879159720] = { img = 1091563622, w = 800, h = 600, en = "Halls of Crafting", es = "Salones de Artesanía" }
D.Maps[1879160246] = { img = 1091564314, w = 1600, h = 1200, en = "Dungeons of Dol Guldur", es = "Mazmorras de Dol Guldur" }
D.Maps[1879161307] = { img = 1091575642, w = 1600, h = 1200, en = "Sword-hall of Dol Guldur", es = "Sala de Espadas de Dol Guldur" }
D.Maps[1879162303] = { img = 1091575482, w = 1600, h = 1200, en = "Sammath Gûl", es = "Sammath Gûl" }
D.Maps[1879162304] = { img = 1091575637, w = 1600, h = 1200, en = "Barad Guldur", es = "Barad Guldur" }
D.Maps[1879174680] = { img = 1091575481, w = 1600, h = 1200, en = "Warg-pens of Dol Guldur", es = "Cercados de Huargos de Dol Guldur" }
D.Maps[1879174850] = { img = 1091575639, w = 1600, h = 1200, en = "Barad Guldur", es = "Barad Guldur" }
D.Maps[1879174851] = { img = 1091575641, w = 1600, h = 1200, en = "Barad Guldur", es = "Barad Guldur" }
D.Maps[1879174852] = { img = 1091575634, w = 1600, h = 1200, en = "Barad Guldur", es = "Barad Guldur" }
D.Maps[1879184735] = { img = 1091586212, w = 1600, h = 1200, en = "Valandil's Tomb", es = "Tumba de Valandil" }
D.Maps[1879184736] = { img = 1091586216, w = 1600, h = 1200, en = "Glinghant", es = "Glinghant" }
D.Maps[1879184737] = { img = 1091586214, w = 800, h = 600, en = "Ost Elendil", es = "Ost Elendil" }
D.Maps[1879189787] = { img = 1091603826, w = 800, h = 600, en = "The Library at Tham Mírdain", es = "La biblioteca de Tham Mírdain" }
D.Maps[1879189788] = { img = 1091603823, w = 800, h = 600, en = "The School at Tham Mírdain", es = "La Escuela de Tham Mírdain" }
D.Maps[1879189789] = { img = 1091603828, w = 1600, h = 1200, en = "Bávor Wyrm-brand's Tomb", es = "Tumba de Bávor Wyrm-brand" }
D.Maps[1879189790] = { img = 1091603830, w = 1600, h = 1200, en = "Torech Mordeloth", es = "Torech Mordeloth" }
D.Maps[1879190613] = { img = 1091604146, w = 800, h = 600, en = "The Great Barrow", es = "El Gran Túmulo" }
D.Maps[1879190614] = { img = 1091604150, w = 800, h = 600, en = "The Great Barrow", es = "El Gran Túmulo" }
D.Maps[1879190615] = { img = 1091604154, w = 800, h = 600, en = "The Great Barrow", es = "El Gran Túmulo" }
D.Maps[1879193366] = { img = 1091636199, w = 800, h = 600, en = "Lost Temple", es = "Templo perdido" }
D.Maps[1879198093] = { img = 1091618005, w = 1600, h = 1200, en = "Ost Dunhoth", es = "Ost Dunhoth" }
D.Maps[1879198096] = { img = 1091642026, w = 800, h = 600, en = "Sâri-surma", es = "Sâri-surma" }
D.Maps[1879198097] = { img = 1091618009, w = 800, h = 600, en = "Ost Dunhoth", es = "Ost Dunhoth" }
D.Maps[1879198099] = { img = 1091618012, w = 800, h = 600, en = "Ost Dunhoth", es = "Ost Dunhoth" }
D.Maps[1879198101] = { img = 1091642024, w = 800, h = 600, en = "Sâri-surma", es = "Sâri-surma" }
D.Maps[1879198102] = { img = 1091618003, w = 1600, h = 1200, en = "Ost Dunhoth", es = "Ost Dunhoth" }
D.Maps[1879202774] = { img = 1091645659, w = 1600, h = 1200, en = "The Halls of Night", es = "Los Salones de la Noche" }
D.Maps[1879204453] = { img = 1091647688, w = 800, h = 600, en = "The Forsaken Inn", es = "La Posada Abandonada" }
D.Maps[1879210151] = { img = 1091647726, w = 1600, h = 1200, en = "Hoarwell Water Cavern", es = "Caverna de agua de Fontegrís" }
D.Maps[1879210152] = { img = 1091647723, w = 1600, h = 1200, en = "Beneath the Forsaken Inn", es = "Debajo de la Posada Abandonada" }
D.Maps[1879219925] = { img = 1091662616, w = 800, h = 600, en = "Draigoch's Lair", es = "Guarida de Draigoch" }
D.Maps[1879222607] = { img = 1091681781, w = 800, h = 600, en = "Steamworks of Orthanc", es = "La Maquinaria de Orthanc" }
D.Maps[1879222608] = { img = 1091683630, w = 800, h = 600, en = "Experimentation Pit", es = "Foso de Experimentación" }
D.Maps[1879222609] = { img = 1091680868, w = 800, h = 600, en = "Saruman's Laboratory", es = "Laboratorio de Saruman" }
D.Maps[1879224887] = { img = 1091683631, w = 800, h = 600, en = "Orthanc Throne-room", es = "Sala del trono de Orthanc" }
D.Maps[1879226336] = { img = 1091686413, w = 1600, h = 1200, en = "Pits of Isengard", es = "Fosos de Isengard" }
D.Maps[1879227068] = { img = 1091691229, w = 1600, h = 1200, en = "The Foundry", es = "La Fundición" }
D.Maps[1879227951] = { img = 1091691581, w = 800, h = 600, en = "Outbuildings of Isengard", es = "Dependencias de Isengard" }
D.Maps[1879228447] = { img = 1091694736, w = 800, h = 600, en = "Roots of Fangorn", es = "Raíces de Fangorn" }
D.Maps[1879228448] = { img = 1091694735, w = 800, h = 600, en = "Roots of Fangorn", es = "Raíces de Fangorn" }
D.Maps[1879256516] = { img = 1091775922, w = 1600, h = 1200, en = "The Great Goblin's Den", es = "La Guarida del Gran Trasgo" }
D.Maps[1879256517] = { img = 1091775921, w = 2400, h = 1800, en = "The Great Goblin's Den", es = "La Guarida del Gran Trasgo" }
D.Maps[1879257833] = { img = 1091780566, w = 800, h = 600, en = "Gate-house of the Lonely Mountain", es = "Casa del guarda de la Montaña Solitaria" }
D.Maps[1879323274] = { img = 1091957975, w = 1600, h = 1200, en = "Sunken Labyrinth", es = "Laberinto Hundido" }
D.Maps[1879323954] = { img = 1091961257, w = 1600, h = 1200, en = "The Dome of Stars", es = "La Cúpula de las Estrellas" }
D.Maps[1879323955] = { img = 1091961254, w = 800, h = 600, en = "Palace of Eldacar", es = "Palacio de Eldacar" }
D.Maps[1879334694] = { img = 1092026953, w = 3200, h = 2400, en = "The Breach of Terror", es = "La brecha del terror" }
D.Maps[1879358738] = { img = 1092340784, w = 1600, h = 1200, en = "Court of Seregost", es = "Corte de Seregost" }
D.Maps[1879359584] = { img = 1092341715, w = 1600, h = 1200, en = "Court of Seregost", es = "Corte de Seregost" }
D.Maps[1879361633] = { img = 1092342450, w = 2400, h = 1800, en = "Naerband", es = "Naerband" }
D.Maps[1879369208] = { img = 1092386205, w = 1600, h = 1200, en = "Stormwall", es = "Muro de Tormentas" }
D.Maps[1879369269] = { img = 1092388626, w = 2400, h = 1800, en = "Caverns of Thrumfall", es = "Cavernas de la Cascada Vibrante" }
D.Maps[1879388395] = { img = 1092462941, w = 1600, h = 1200, en = "Kidzul-kâlah", es = "Kidzul-kâlah" }
D.Maps[1879388396] = { img = 1092462956, w = 800, h = 600, en = "Kidzul-kâlah", es = "Kidzul-kâlah" }
D.Maps[1879388397] = { img = 1092462953, w = 800, h = 600, en = "Kidzul-kâlah", es = "Kidzul-kâlah" }
D.Maps[1879388912] = { img = 1092463747, w = 3200, h = 2400, en = "Gath Daeroval, the Shadow-roost", es = "Gath Daeroval, el Nido de la Sombra" }
D.Maps[1879389689] = { img = 1092467420, w = 1600, h = 1200, en = "Gorthad Nûr, the Deep-barrow", es = "Gorthad Nûr, el Túmulo Profundo" }
D.Maps[1879390420] = { img = 1092499599, w = 2400, h = 1800, en = "Eithel Gwaur, the Filth-well", es = "Eithel Gwaur, el Pozo de la Inmundicia" }
D.Maps[1879395042] = { img = 1092524351, w = 800, h = 600, en = "Amon Fuin", es = "Amon Fuin" }
D.Maps[1879395606] = { img = 1092525157, w = 2400, h = 1800, en = "Ghashan-kútot, the Halls of Black Lore", es = "Ghashan-kútot, los Salones del Saber Oscuro" }
D.Maps[1879406284] = { img = 1092544943, w = 1600, h = 1200, en = "Askâd-mazal, the Chamber of Shadows", es = "Askâd-mazal, la Cámara de las Sombras" }
D.Maps[1879421176] = { img = 1092683124, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421177] = { img = 1092683126, w = 1600, h = 1200, en = "Den of Pughlak", es = "Guarida de Pughlak" }
D.Maps[1879421178] = { img = 1092683127, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421179] = { img = 1092683128, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421180] = { img = 1092683129, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421181] = { img = 1092683130, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421182] = { img = 1092683131, w = 1600, h = 1200, en = "Vision of Pughlak", es = "Visión de Pughlak" }
D.Maps[1879421479] = { img = 1092683766, w = 1600, h = 1200, en = "Dhúrstrok", es = "Dhúrstrok" }
D.Maps[1879442093] = { img = 1092700626, w = 1600, h = 1200, en = "Adkhât-zahhar, the Houses of Rest", es = "Adkhât-zahhar, las Casas del Reposo" }
D.Maps[1879443657] = { img = 1092708118, w = 3200, h = 3600, en = "Caverns of Clovengap", es = "Cavernas de Pasohendido" }
D.Maps[1879443658] = { img = 1092708117, w = 3200, h = 3600, en = "The Hiddenhoard of Abnankâra", es = "El Tesoro Escondido de Abnankâra" }
D.Maps[1879443659] = { img = 1092708116, w = 3200, h = 3600, en = "Mind of the Frost-heart", es = "Mente del Corazónhelado" }
D.Maps[1879453499] = { img = 1092753789, w = 1600, h = 1200, en = "Sagroth", es = "Sagroth" }
D.Maps[1879453609] = { img = 1092778664, w = 1600, h = 1200, en = "Gwathrenost", es = "Gwathrenost" }
D.Maps[1879456452] = { img = 1092756832, w = 800, h = 600, en = "Sarch Vorn", es = "Sarch Vorn" }
D.Maps[1879456523] = { img = 1092778665, w = 1600, h = 1200, en = "Gwathrenost", es = "Gwathrenost" }
D.Maps[1879456524] = { img = 1092778666, w = 1600, h = 1200, en = "Gwathrenost", es = "Gwathrenost" }
D.Maps[1879459099] = { img = 1092812735, w = 1600, h = 1200, en = "Thaurisgar, the Vile Apothecary", es = "Thaurisgar, La Bótica Infame" }
D.Maps[1879478181] = { img = 1092912569, w = 800, h = 600, en = "The Mâkhda Khorbo -- Hidden Entrance", es = "El Mâkhda Khorbo -- Entrada oculta" }
D.Maps[1879478486] = { img = 1092915131, w = 1600, h = 1200, en = "The Mâkhda Khorbo -- Dry Docks", es = "El Mâkhda Khorbo -- Diques secos" }
D.Maps[1879478496] = { img = 1092915144, w = 1600, h = 1200, en = "The Mâkhda Khorbo -- Flooded Docks", es = "El Mâkhda Khorbo -- Diques inundados" }
D.Maps[1879478783] = { img = 1092926066, w = 800, h = 600, en = "The Mâkhda Khorbo -- Iron Stairwell", es = "El Mâkhda Khorbo -- Escalera de hierro" }
D.Maps[1879480482] = { img = 1092934374, w = 1600, h = 1200, en = "Dahâl Huliz, The Arena", es = "Dahâl Huliz, La Arena" }
D.Maps[1879487383] = { img = 1092947887, w = 1600, h = 1200, en = "Dahâl Huliz, The Arena", es = "Dahâl Huliz, La Arena" }
D.Maps[1879491954] = { img = 1092977250, w = 1600, h = 1200, en = "Ashunûg, the Fane of the Accursed", es = "Ashunûg, el Templo de los Malditos" }
D.Maps[1879492990] = { img = 1092981922, w = 1600, h = 1200, en = "The White Tombs of Nirgambâr", es = "Las Tumbas Blancas de Nirgambâr" }
D.Maps[1879494891] = { img = 1092984036, w = 1600, h = 1200, en = "Tûl Zakana, the Well of Forgetting", es = "Tûl Zakana, el Pozo del Olvido" }
D.Maps[1879495208] = { img = 1092985845, w = 1600, h = 1200, en = "Dhórgruth, the Lord's Delving", es = "Dhórgruth, la Caverna del Señor" }
D.Maps[1879495217] = { img = 1092987510, w = 1600, h = 1200, en = "Thûr Hin, Lair of the Children", es = "Thûr Hin, Guarida de los Niños" }
D.Maps[1879495218] = { img = 1092987631, w = 1600, h = 1200, en = "The Temple of Utug-bûr, Inner Sanctum", es = "El Templo de Utug-bûr, Santuario Interior" }
D.Maps[1879503002] = { img = 1093005106, w = 1600, h = 1200, en = "Citadel of Dun Shûma", es = "Ciudadela de Dun Shûma" }
D.Maps[1879506395] = { img = 1093030366, w = 1600, h = 1200, en = "Kôth Rau", es = "Kôth Rau" }
D.Maps[1879507060] = { img = 1093033166, w = 800, h = 600, en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi" }
D.Maps[1879507528] = { img = 1093034558, w = 1600, h = 1200, en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi" }
D.Maps[1879507580] = { img = 1093033570, w = 1600, h = 1200, en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi" }
D.Maps[1879507793] = { img = 1093034557, w = 1600, h = 1200, en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi" }
D.Maps[1879509384] = { img = 1093040650, w = 1600, h = 1200, en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi" }
D.Maps[1879517905] = { img = 1093057579, w = 1600, h = 1200, en = "The Caves of Hurum Kâna", es = "Las cuevas de Hurum Kâna" }
D.Maps[1879520515] = { img = 1093064374, w = 1600, h = 1200, en = "Ekal-nêbi", es = "Ekal-nêbi" }
D.Maps[268442463] = { img = 1091472986, w = 1024, h = 768, en = "The Grand Stair", es = "La Gran Escalera" }
D.Maps[268452655] = { img = 1092412668, w = 1024, h = 768, en = "Steel Keep", es = "Bastión de Acero" }
D.Maps[268452659] = { img = 1092413237, w = 1024, h = 768, en = "Glimmerdeep", es = "Brilloprofundo" }
D.Maps[268452717] = { img = 1092431546, w = 1024, h = 768, en = "The Anvil of Winterstith", es = "El Yunque del Pico Invernal" }
D.Maps[268453438] = { img = 1092537315, w = 1024, h = 768, en = "Shelob's Lair", es = "Guarida de Ella-Laraña" }
D.Maps[268453582] = { img = 1092682130, w = 1024, h = 768, en = "Nud-melek T.A. 1981", es = "Nud-melek T.E. 1981" }
D.Maps[268455160] = { img = 1093135355, w = 1024, h = 768, en = "Hatokáli Fells - Crypt", es = "Colinas de Hatokáli - Cripta" }
D.Inst[#D.Inst + 1] = { en = "Adkhât-zahhar, the Houses of Rest", es = "Adkhât-zahhar, las Casas del Reposo", lmin = "130", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879442093 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Agoroth, the Narrowdelve", es = "Agoroth, el Narrowdelve", lmin = "45", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ashunûg, the Fane of the Accursed", es = "Ashunûg, el Templo de los Malditos", lmin = "150", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879491954 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Askâd-mazal, the Chamber of Shadows", es = "Askâd-mazal, la Cámara de las Sombras", lmin = "50", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879406284 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Assault on Dhúrstrok", es = "Asalto a Dhúrstrok", lmin = "130", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879421479 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Barad Guldur", es = "Barad Guldur", lmin = "65", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879162304, 1879174850, 1879174851, 1879174852 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Blood of the Black Serpent", es = "Sangre de la Serpiente Negra", lmin = "75", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Bâr Nírnaeth, the Houses of Lamentation", es = "Bâr Nírnaeth, las Casas de la Lamentación", lmin = "121", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Caverns of Thrumfall", es = "Cavernas de Cascada Vibrante", lmin = "118", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879369208, 1879369269 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dahâl Huliz, The Arena", es = "Dahâl Huliz, La Arena", lmin = "150", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879480482 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Den of Pughlak", es = "Guarida de Pughlak", lmin = "130", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879421176, 1879421177, 1879421178, 1879421179, 1879421180, 1879421181, 1879421182 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dragon Wing", es = "Ala del dragón", lmin = "50", lmax = "160", players = "24", scaling = true, sizesES = "Incursión (24)", sizesEN = "Raid (24)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Drake Wing", es = "Ala del Dragonzuelo", lmin = "50", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879189789 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dun Shûma, The King's Fortress", es = "Dun Shûma, la Fortaleza del Rey", lmin = "150", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879503002 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dungeons of Dol Guldur", es = "Mazmorras de Dol Guldur", lmin = "65", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879160246 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Eithel Gwaur, the Filth-well", es = "Eithel Gwaur, el Pozo de la Inmundicia", lmin = "121", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879390420 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Flight to the Lonely Mountain", es = "Huida a la Montaña Solitaria", lmin = "20", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Gath Daeroval, the Shadow-roost", es = "Gath Daeroval, el Nido de la Sombra", lmin = "121", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879388912 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ghashan-kútot, the Halls of Black Lore", es = "Ghashan-kútot, los Salones del Saber Oscuro", lmin = "121", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Comunidad (6), Dúo", sizesEN = "Solo, Fellowship (6), Duo", maps = { 1879395606 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Giant Wing", es = "Ala del gigante", lmin = "50", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Glimmerdeep", es = "Brilloprofundo", lmin = "118", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 268452659 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Glinghant", es = "Glinghant", lmin = "40", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879184736 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Gorthad Nûr, the Deep-barrow", es = "Gorthad Nûr, el Túmulo Profundo", lmin = "121", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879389689 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Halls of Night", es = "Salones de la Noche", lmin = "40", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879202774 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Haudh Valandil", es = "Haudh Valandil", lmin = "40", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879184735 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Inn of the Forsaken", es = "Posada de los abandonados", lmin = "20", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879204453, 1879210151, 1879210152 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Iorbar's Peak", es = "Pico de Iorbar", lmin = "20", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Library at Tham Mírdain", es = "Biblioteca en Tham Mírdain", lmin = "50", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879189787 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Lost Temple", es = "Templo perdido", lmin = "65", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879193366 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Nirgambâr, the Restless Tomb", es = "Nirgambâr, la Tumba Inquieta", lmin = "150", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879492990 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ost Dunhoth - Disease and Poison Wing", es = "Ost Dunhoth - Ala de Enfermedad y Veneno", lmin = "65", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879198093, 1879198097, 1879198099, 1879198102 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ost Dunhoth - Gortheron Wing", es = "Ost Dunhoth - Ala de Gortheron", lmin = "65", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879198093, 1879198097, 1879198099, 1879198102 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ost Dunhoth - Wound and Fear Wing", es = "Ost Dunhoth - Ala de Herida y Miedo", lmin = "65", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879198093, 1879198097, 1879198099, 1879198102 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Ost Elendil", es = "Ost Elendil", lmin = "40", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879184737 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sagroth, Lair of Vermin", es = "Sagroth, Antro de la peste", lmin = "140", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879453499 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sambrog", es = "Sambrog", lmin = "20", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879190615 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sammath Gûl", es = "Sammath Gûl", lmin = "65", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879162303 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sant Lhoer, the Poison Gardens", es = "Sant Lhoer, los Jardines Emponzoñados", lmin = "140", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sarch Vorn, the Black Grave", es = "Sarch Vorn, la Tumba Negra", lmin = "20", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879456452 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "School at Tham Mírdain", es = "Escuela en Tham Mírdain", lmin = "50", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879189788 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Seat of the Great Goblin", es = "Asiento del Gran Trasgo", lmin = "20", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879256516, 1879256517 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Shakalush, the Stair Battle", es = "Shakalush, la batalla de las escaleras", lmin = "130", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Comunidad (6), Dúo", sizesEN = "Solo, Fellowship (6), Duo", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Spider Wing", es = "Ala de araña", lmin = "50", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879189790 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Stoneheight", es = "Altapiedra", lmin = "65", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sunken Labyrinth", es = "Laberinto Hundido", lmin = "50", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879323274 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sword-hall of Dol Guldur", es = "Sala de Espadas de Dol Guldur", lmin = "65", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879161307 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Sâri-surma", es = "Sâri-surma", lmin = "65", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879198096, 1879198101 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Thadúr", es = "Thadúr", lmin = "20", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879190614 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Thaurisgar, the Vile Apothecary", es = "Thaurisgar, el vil boticario", lmin = "140", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879459099 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Battle for Erebor", es = "La batalla por Erebor", lmin = "20", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879257833 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Bells of Dale", es = "Las campanas de Valle", lmin = "20", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Court of Seregost", es = "Tribunal de Seregost", lmin = "105", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879358738, 1879359584 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Depths of Kidzul-kâlah", es = "Las profundidades de Kidzul-kâlah", lmin = "120", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879388395, 1879388396, 1879388397 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Dome of Stars", es = "La Cúpula de las Estrellas", lmin = "50", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879323954 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Dragon and the Storm", es = "El Dragón y la Tormenta", lmin = "150", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879487383 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Dungeons of Naerband", es = "Las mazmorras de Naerband", lmin = "105", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879361633 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Fallen Kings", es = "Los Reyes Caídos", lmin = "121", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879395042 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Fires of Smaug", es = "Los fuegos de Smaug", lmin = "20", lmax = "160", players = "12", scaling = true, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Harrowing of Morgul", es = "La Desgarradora de Morgul", lmin = "121", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Isle of Storms", es = "La Isla de las Tormentas", lmin = "150", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Maze", es = "El laberinto", lmin = "20", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879190613 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Northcotton Farm", es = "La Granja de Cotonorte", lmin = "65", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Quays of the Harlond", es = "Los Muelles del Harlond", lmin = "75", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Ruined City", es = "La Ciudad Arruinada", lmin = "50", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879323955 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Silent Street", es = "La Calle Silenciosa", lmin = "75", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Streets of Râhal Bakh", es = "Las calles de Râhal Bakh", lmin = "150", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Thikil-gundu", es = "Thikil-gundu", lmin = "118", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Comunidad (6)", sizesEN = "Solo, Fellowship (6)", maps = { 268452655 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Tûl Zakana, the Well of Forgetting", es = "Tûl Zakana, el Pozo del Olvido", lmin = "150", lmax = "160", players = "6", scaling = true, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879494891 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Warg-pens of Dol Guldur", es = "Cercados de Huargos de Dol Guldur", lmin = "65", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879174680 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Webs of the Scuttledells", es = "Telarañas de las Hondonadas Enmarañadas", lmin = "20", lmax = "160", players = "3", scaling = true, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Woe of the Willow", es = "El infortunio del sauce", lmin = "20", lmax = "160", players = "3", scaling = true, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Wraith of Earth", es = "Espectro de Tierra", lmin = "25", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879051244 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Wraith of Fire", es = "Espectro de Fuego", lmin = "25", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879051245 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Wraith of Shadow", es = "Espectro de Sombra", lmin = "25", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879051246 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Wraith of Water", es = "Espectro de Agua", lmin = "25", lmax = "160", players = "6", scaling = true, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879051243 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Amdân Dammul, the Bloody Threshold", es = "Amdân Dammul, el Umbral Sangriento", lmin = "130", lmax = "130", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Arboretum", es = "Arboreto", lmin = "32", lmax = "32", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Barad Gúlaran", es = "Barad Gúlaran", lmin = "50", lmax = "50", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879087106 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Barrows", es = "Túmulos", lmin = "32", lmax = "32", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Carn Dûm", es = "Carn Dûm", lmin = "50", lmax = "50", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879048289, 1879051227, 1879076058 }, bosses = { { "Urro", "Urro", "Debajo del puente" }, { "Barashal", "Barashal", "Puentes superiores" }, { "Helchgam", "Helchgam", "Lago de las alcantarillas" }, { "Salvakh", "Sálvakh", "Despensa" }, { "Azgoth", "Azgoth", "Ascenso norte, zona de morrovals" }, { "Avalgaith", "Avalgaith", "Este, cerca de Helchgam" }, { "Tarlakh", "Tárlakh", "Puente central del norte" }, { "Tarlug", "Târlug", "Primera sala grande del castillo" }, { "Mormoz", "Mormoz", "Sala de un piso superior" }, { "Rodakhan", "Rodakhan", "Sala siguiente del castillo" }, { "Mura", "Múra", "Sala junto a Rodakhan" }, { "Gurthul", "Gúrthul", "Piso siguiente" }, { "Mordirith", "Mordirith", "Sala del trono, arriba" } } }
D.Inst[#D.Inst + 1] = { en = "Dargnákh Unleashed", es = "Dargnákh desatado", lmin = "75", lmax = "75", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879227951 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dark Delvings", es = "Excavaciones Tenebrosas", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138597 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Depths of Mâkhda Khorbo", es = "Profundidades de Mâkhda Khorbo", lmin = "150", lmax = "150", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879478181, 1879478486, 1879478496, 1879478783 }, bosses = { { "Shadow of Azagath", "Shadow of Azagath", "Primer encuentro" }, { "Burkhad", "Burkhad", "Primer encuentro, acompañante" }, { "Zagarón", "Zagarón", "Primer encuentro, acompañante" }, { "Phérida", "Phêrida", "Primer encuentro, acompañante" }, { "Ishakhâr", "Ishakhâr", "Primer encuentro, T2 o superior" }, { "Belondor", "Belondor", "Segundo encuentro" }, { "Umshûra", "Umshûra", "Tercer encuentro" } } }
D.Inst[#D.Inst + 1] = { en = "Draigoch's Lair", es = "Guarida de Draigoch", lmin = "75", lmax = "75", players = "24", scaling = false, sizesES = "Incursión (12), Incursión (24)", sizesEN = "Raid (12), Raid (24)", maps = { 1879219925 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Dâr Narbugud", es = "Dâr Narbugud", lmin = "58", lmax = "58", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879152319, 1879152320, 1879152321, 1879159718 }, bosses = { { "Blagh", "Blagh", "Sala grande de entrada" }, { "Rung", "Rung", "Sala grande de entrada" }, { "Zholuga", "Zholuga", "Encuentro de jefe" }, { "Flâgît", "Flâgît", "Encuentro de jefe" }, { "Istum", "Îstum", "Encuentro de jefe" }, { "The Blind One", "El Ciego", "Encuentro de jefe" }, { "Mistress of Pestilence", "Mistress of Pestilence", "Encuentro final" } } }
D.Inst[#D.Inst + 1] = { en = "Ekal-nêbi, the Fallen Palace", es = "Ekal-nêbi, el Palacio Caído", lmin = "160", lmax = "160", players = "6", scaling = false, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879520515 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Fangorn's Edge", es = "El Borde de Fangorn", lmin = "75", lmax = "75", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Fil Gashan", es = "Fil Gashan", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138596, 1879145196, 1879145197 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Filikul", es = "Filikul", lmin = "58", lmax = "58", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879149567 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Fortress", es = "Fortaleza", lmin = "32", lmax = "32", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Goblin-town Throne Room", es = "Sala del trono de la Ciudad de los Trasgos", lmin = "45", lmax = "45", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879101643 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Gwathrenost, the Witch-king's Citadel", es = "Gwathrenost, la Ciudadela del Rey Brujo", lmin = "140", lmax = "140", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879453609, 1879456523, 1879456524 }, bosses = { { "Gurkrak", "Gurkrak", "Primer encuentro" }, { "Obashurz", "Obashurz", "Segundo encuentro, después de las escaleras del oeste" }, { "Claghord", "Claghórd", "Tercer encuentro A" }, { "Asachal", "Ásachal", "Tercer encuentro B" }, { "Shard of Taúressar", "Fragmento de Tauressar", "Cuarto encuentro" } } }
D.Inst[#D.Inst + 1] = { en = "Halls of Crafting", es = "Salones de Artesanía", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879152343, 1879159719, 1879159720 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Kôth Rau, the Wailing Hold", es = "Kôth Rau, la Fortaleza de los Lamentos", lmin = "160", lmax = "160", players = "6", scaling = false, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 1879506395 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Pagru-kirít, the Garden of Corpses", es = "Pagru-kirít, el Jardín de los Cadáveres", lmin = "160", lmax = "160", players = "6", scaling = false, sizesES = "Solo, Dúo, Comunidad (6)", sizesEN = "Solo, Duo, Fellowship (6)", maps = { 268455160 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Pits of Isengard", es = "Fosos de Isengard", lmin = "75", lmax = "75", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879226336 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Remmorchant, the Net of Darkness", es = "Remmorchant, la Red de la Oscuridad", lmin = "130", lmax = "130", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 268453438 }, bosses = { { "Bratha Tasakh", "Bratha Tasakh", "Primer encuentro" }, { "Gragarag", "Gragarag", "Minijefe" }, { "Guruthang", "Guruthang", "Minijefe" }, { "Gamnagol", "Gamnagol", "Minijefe" }, { "Thossulun", "Thossulun", "Segundo encuentro" }, { "Captain Zabothak", "Captain Zabothak", "Tercer encuentro" }, { "Rûkhor", "Rûkhor", "Tercer encuentro" }, { "Shelob", "Ella-Laraña", "Cuarto encuentro" } } }
D.Inst[#D.Inst + 1] = { en = "Roots of Fangorn", es = "Raíces de Fangorn", lmin = "75", lmax = "75", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879228447, 1879228448 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Skûmfil", es = "Skûmfil", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138594 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Abyss of Mordath", es = "El Abismo de Mordath", lmin = "115", lmax = "115", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Anvil of Winterstith", es = "Yunque Invernal", lmin = "120", lmax = "120", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 268452717 }, bosses = { { "Isvítha", "Isvítha", "Primer encuentro, arena helada" }, { "Vethúg", "Vethúg", "Tercer encuentro" }, { "Hrimil", "Hrímil", "Cuarto encuentro" } } }
D.Inst[#D.Inst + 1] = { en = "The Fall of Khazad-dûm", es = "La Caída de Khazad-dûm", lmin = "130", lmax = "130", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 268453582 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Folly of Nagakhêdi", es = "La Locura de Nagakhêdi", lmin = "160", lmax = "160", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879507060, 1879507528, 1879507580, 1879507793, 1879509384 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Forges of Khazad-dûm", es = "Las Forjas de Khazad-dûm", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138595, 1879145612, 1879145613 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Forgotten Treasury", es = "El Tesoro Olvidado", lmin = "54", lmax = "54", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138599 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Foundry", es = "La Fundición", lmin = "75", lmax = "75", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879227068 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Grand Stair", es = "La Gran Escalera", lmin = "56", lmax = "56", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 268442463 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Hiddenhoard of Abnankâra", es = "El Tesoro Escondido de Abnankâra", lmin = "140", lmax = "140", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879443657, 1879443658, 1879443659 }, bosses = { { "Kvethar", "Kvethár", "Primer encuentro" }, { "Threkvegg", "Threkvegg", "Primer encuentro" }, { "Armod", "Armód", "Primer encuentro" }, { "Dushtalbuk", "Dushtalbuk", "Segundo encuentro" }, { "Hrimil", "Hrímil", "Tercer encuentro, sala del tesoro y sala final" } } }
D.Inst[#D.Inst + 1] = { en = "The Mirror-halls of Lumul-nar", es = "Las Salas de los Espejos de Lumul-nar", lmin = "58", lmax = "58", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879153146, 1879153312, 1879153314 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Rift of Nûrz Ghâshu", es = "La Grieta de Nûrz Ghâshu", lmin = "50", lmax = "50", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879101482, 1879101483, 1879101485, 1879101486, 1879101489, 1879101491, 1879102227 }, bosses = { { "Barz", "Barz", "Bornabar, rampa oriental" }, { "Zurm", "Zurm", "Bornabar, rampa occidental" }, { "Frûz", "Frûz", "Noruidor superior" }, { "Zogtârk", "Zogtark", "Noruidor inferior" }, { "Narnûlubat", "Narnûlubat", "Acceso a Norbar" }, { "Shadow-eater", "Devorasombras", "Norbar" }, { "Stone-biter", "Mordedor de piedra", "Norbar" }, { "Thrâng", "Thrâng", "Arena de Norbar" }, { "Thaurlach", "Thaurlach", "Sala final del Balrog" } } }
D.Inst[#D.Inst + 1] = { en = "The Sixteenth Hall", es = "La Decimosexta Sala", lmin = "58", lmax = "58", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879138598 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Temple of Utug-bûr 1 - Dhórgruth", es = "El Templo de Utug-bûr 1 - Dhórgruth", lmin = "150", lmax = "150", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879495208 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Temple of Utug-bûr 2 - Thûr Hin", es = "El Templo de Utug-bûr 2 - Thûr Hin", lmin = "150", lmax = "150", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879495217 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Temple of Utug-bûr 3 - Inner Sanctum", es = "El Templo de Utug-bûr 3 - Santuario Interior", lmin = "150", lmax = "150", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879495218 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Tower of Orthanc", es = "La Torre de Orthanc", lmin = "75", lmax = "75", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879222607, 1879222608, 1879222609, 1879224887 }, bosses = { { "Iorweth", "Iorweth", "Ala de ácido, delante a la izquierda" }, { "Crisiant", "Crisiant", "Ala de fuego y hielo, detrás de la entrada" }, { "Usgarren", "Usgarren", "Ala de fuego y hielo, detrás de la entrada" }, { "Kâlbak", "Kâlbak", "Ala de relámpago, delante a la derecha" }, { "Bukot", "Bukot", "Ala de sombra, hacia la torre" }, { "Saruman", "Saruman", "Cima de la torre" } } }
D.Inst[#D.Inst + 1] = { en = "The Treasure Caves of Hurum Kâna", es = "Las Cuevas del Tesoro de Hurum Kâna", lmin = "160", lmax = "160", players = "3", scaling = false, sizesES = "Solo, Dúo, Grupo de 3", sizesEN = "Solo, Duo, Small fellowship (3)", maps = { 1879517905 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Vile Maw", es = "La Fauce Vil", lmin = "58", lmax = "58", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = {  }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "The Water Wheels: Nalâ-dûm", es = "Las Ruedas de Agua: Nalâ-dûm", lmin = "58", lmax = "58", players = "3", scaling = false, sizesES = "Grupo de 3", sizesEN = "Small fellowship (3)", maps = { 1879153147, 1879153148, 1879153149, 1879153150, 1879153210 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Throne of the Dread Terror", es = "Trono del Terror Temible", lmin = "105", lmax = "105", players = "12", scaling = false, sizesES = "Incursión (12)", sizesEN = "Raid (12)", maps = { 1879334694 }, bosses = {  } }
D.Inst[#D.Inst + 1] = { en = "Urugarth", es = "Urugarth", lmin = "50", lmax = "50", players = "6", scaling = false, sizesES = "Comunidad (6)", sizesEN = "Fellowship (6)", maps = { 1879084150 }, bosses = { { "Burzfil", "Burzfîl", "Camino inicial de crebain, puente izquierdo" }, { "Sorkrank", "Sorkrank", "Camino inicial de crebain, puente izquierdo" }, { "Dushkal", "Dushkâl", "Guarida de Dushkal" }, { "Akrûr", "Akrûr", "Plataforma después del puente de piedra" }, { "Lhugrien", "Lhugrien", "Guarida de dracos" }, { "Grishakrum", "Gríshakrum", "Desvío en la bajada" }, { "Athpukh", "Athpukh", "Perreras del noroeste" }, { "Lâmkarn", "Lâmkarn", "Perreras del noroeste" }, { "Gruglok", "Gruglok", "Arena de oleadas" }, { "Thordragh", "Thordragh", "Patio de Lagmâs" }, { "Brizrip", "Brízrip", "Patio de Lagmâs" }, { "Morthrâng", "Morthrâng", "Patio de Lagmâs" }, { "Lagmâs", "Lagmâs", "Parte alta de las rampas del patio" } } }
D.Boss = {}
D.Boss[1879048289] = { { 830, 763, "Tarlug", "Târlug", "Primera sala grande del castillo", "b" }, { 861, 583, "Gurthul", "Gúrthul", "Piso siguiente", "b" }, { 797, 657, "Gurthul", "Gúrthul", "Piso siguiente", "b" }, { 812, 368, "Mordirith", "Mordirith", "Sala del trono, arriba", "b" }, { 829, 624, "Rodakhan\nMormoz", "Rodakhan\nMormoz", "Sala siguiente del castillo\nSala de un piso superior", "b" }, { 829, 668, "Múra", "Múra", "Sala junto a Rodakhan", "b" } }
D.Boss[1879076058] = { { 774, 510, "Helchgam", "Helchgam", "Lago de las alcantarillas", "b" }, { 782, 388, "Zûrtith", "Zûrtith", "", "b" }, { 643, 485, "Tarbâm", "Tarbâm", "", "b" }, { 912, 464, "Bolgrukh", "Bolgrukh", "", "b" }, { 246, 741, "Sálvakh", "Sálvakh", "Despensa", "b" } }
D.Boss[1879087106] = { { 844, 572, "Forvengwath's Pledge", "Juramento de Forvengwath", "", "b" }, { 758, 570, "Forvengwath's Pledge", "Juramento de Forvengwath", "", "b" }, { 995, 382, "Afraig, Gúlaran Sorceress", "Afraig, hechicera de Gularan", "", "b" }, { 608, 380, "Coblaith, Gúlaran Sorceress", "Coblaith, hechicera de Gularan", "", "b" }, { 800, 252, "Castellan Wisdán", "Castellano Wisdán", "", "b" }, { 793, 357, "Castellan Wisdán\nUdúnion", "Castellano Wisdán\nUdúnion", "\n", "b" }, { 800, 504, "Forvengwath", "Forvengwath", "", "b" }, { 800, 399, "Múlvuirë, High Sorceress", "Múlvuirë, gran hechicera", "", "b" } }
D.Boss[1879101482] = { { 519, 354, "Barz", "Barz", "Bornabar, rampa oriental", "b" }, { 312, 372, "Zurm", "Zurm", "Bornabar, rampa occidental", "b" }, { 423, 120, "Asmólf", "Asmólf", "", "b" } }
D.Boss[1879101483] = { { 690, 898, "Frûz", "Frûz", "Noruidor superior", "b" }, { 772, 455, "Hyrrokkin\nTortrygg", "Hyrrokkin\nTortrygg", "\n", "b" }, { 649, 465, "Asmólf", "Asmólf", "", "b" } }
D.Boss[1879101485] = { { 403, 313, "Stone-biter", "Mordedor de piedra", "Norbar", "b" }, { 402, 287, "Shadow-eater", "Devorasombras", "Norbar", "b" } }
D.Boss[1879101486] = { { 573, 263, "Narnûlubat", "Narnûlubat", "Acceso a Norbar", "b" } }
D.Boss[1879101489] = { { 397, 301, "Thaurlach", "Thaurlach", "Sala final del Balrog", "b" } }
D.Boss[1879101491] = { { 416, 297, "Zogtârk", "Zogtark", "Noruidor inferior", "b" } }
D.Boss[1879101643] = { { 365, 178, "Izkâl, Ashûrz's Beast\nAshûrz the Great Goblin", "Izkâl, la bestia de Ashûrz\nAshûrz, el Gran Trasgo", "\n", "b" }, { 411, 370, "Aklash, Leader of Soldiers", "Aklash, jefe de los soldados", "", "b" }, { 263, 248, "Rakothúrz, Horm's Handler", "Rakothúrz, el domador de Horm", "", "b" }, { 456, 202, "Horm, The Pit Beast", "Horm, la bestia de la fosa", "", "b" }, { 448, 241, "Bhoghad, Emissary to Goblin-town", "Bhoghad, emisario de la Ciudad de los Trasgos", "", "b" } }
D.Boss[1879102227] = { { 825, 580, "Thrâng", "Thrâng", "Arena de Norbar", "b" }, { 817, 665, "Eimyr", "Eimyr", "", "b" } }
D.Boss[1879138594] = { { 810, 840, "Gazathrug Lurker", "Merodeador Gazathrug", "", "b" }, { 944, 548, "Bonetooth", "Dientehueso", "", "b" }, { 817, 812, "Hwandrin", "Hwandrin", "", "b" } }
D.Boss[1879138595] = { { 801, 412, "Narkû", "Narkû", "", "b" } }
D.Boss[1879138596] = { { 804, 335, "Vrarz the Cook", "Vrarz el cocinero", "", "b" } }
D.Boss[1879138597] = { { 739, 324, "Void-eater", "Devorador del vacío", "", "b" }, { 447, 591, "Doom-speaker", "Portavoz del destino", "", "b" }, { 789, 866, "Gurvand", "Gurvand", "", "b" } }
D.Boss[1879138598] = { { 827, 848, "Unur", "Unur", "", "b" }, { 525, 733, "Helegfan", "Helegfan", "", "b" }, { 685, 755, "Tramug", "Tramug", "", "b" }, { 608, 656, "Dhûrz", "Dhûrz", "", "b" } }
D.Boss[1879138599] = { { 890, 479, "Nardurgûl", "Nardurgûl", "", "b" }, { 925, 571, "Frûzgûl", "Frûzgûl", "", "b" }, { 890, 660, "Darûkûrz", "Darûkûrz", "", "b" }, { 710, 660, "Narghug", "Narghug", "", "b" }, { 675, 570, "Mokza", "Mokza", "", "b" }, { 710, 481, "Lorzgûl", "Lorzgûl", "", "b" }, { 800, 901, "Morhûn", "Morhûn", "", "b" }, { 800, 571, "Morhûn", "Morhûn", "", "b" }, { 782, 737, "Skûm", "Skûm", "", "b" }, { 818, 737, "Urauth", "Urauth", "", "b" } }
D.Boss[1879145196] = { { 865, 864, "Talug's Fang-caster", "Lanzador de colmillos de Talug", "", "b" }, { 812, 755, "Talug's Fang-caster\nGeneral Talug", "Lanzador de colmillos de Talug\nGeneral Talug", "\n", "b" } }
D.Boss[1879145197] = { { 775, 600, "Commander Greb", "Comandante Greb", "", "b" } }
D.Boss[1879145612] = { { 401, 309, "Dhaub", "Dhaub", "", "b" } }
D.Boss[1879145613] = { { 400, 293, "Ruingal", "Ruingal", "", "b" }, { 356, 441, "Thrug", "Thrug", "", "b" }, { 399, 215, "Kranklûk", "Kranklûk", "", "b" } }
D.Boss[1879152319] = { { 356, 311, "Blagh\nRung", "Blagh\nRung", "Sala grande de entrada\nSala grande de entrada", "b" } }
D.Boss[1879152320] = { { 369, 207, "Zholuga", "Zholuga", "Encuentro de jefe", "b" } }
D.Boss[1879152321] = { { 522, 301, "The Blind One", "El Ciego", "Encuentro de jefe", "b" }, { 350, 310, "The Mistress of Pestilence", "La Maestra de la Peste", "Encuentro final", "b" } }
D.Boss[1879152343] = { { 266, 266, "Âmbal", "Âmbal", "", "b" } }
D.Boss[1879153210] = { { 274, 360, "Caerlûg", "Caerlûg", "", "b" } }
D.Boss[1879153314] = { { 403, 303, "Ergoth", "Ergoth", "", "b" } }
D.Boss[1879159718] = { { 288, 223, "Flâgît", "Flâgît", "Encuentro de jefe", "b" }, { 492, 423, "Istum", "Îstum", "Encuentro de jefe", "b" } }
D.Boss[1879159719] = { { 399, 134, "Thaguzg", "Thaguzg", "", "b" } }
D.Boss[1879159720] = { { 372, 138, "Bashkuga", "Bashkuga", "", "b" } }
D.Boss[1879161307] = { { 801, 453, "Carchrien", "Carchrien", "", "b" }, { 800, 741, "Urcheron", "Urcheron", "", "b" }, { 653, 600, "Durkâr", "Durkâr", "", "b" } }
D.Boss[1879162303] = { { 822, 520, "Urchír", "Urchír", "", "b" }, { 598, 376, "Alagossír", "Alagossír", "", "b" }, { 422, 680, "Gorothúl", "Gorothúl", "", "b" }, { 760, 820, "Demafaer", "Demafaer", "", "b" } }
D.Boss[1879162304] = { { 800, 276, "Dúrchest", "Dúrchest", "", "b" } }
D.Boss[1879174680] = { { 848, 445, "Kranklob", "Kranklob", "", "b" } }
D.Boss[1879174850] = { { 640, 437, "Morgaraf", "Morgaraf", "", "b" }, { 640, 763, "Cargaraf", "Cargaraf", "", "b" } }
D.Boss[1879184735] = { { 825, 488, "Valandil of Arnor\nDolvaethor", "Valandil de Arnor\nDolvaethor", "\n", "b" }, { 707, 713, "Hooktooth", "Colmilloganchudo", "", "b" }, { 823, 758, "Shingrinder", "Muelespinillas", "", "b" }, { 823, 681, "Dolvaethor", "Dolvaethor", "", "b" } }
D.Boss[1879184736] = { { 805, 842, "Nengon", "Nengon", "", "b" }, { 804, 630, "Nengon", "Nengon", "", "b" } }
D.Boss[1879184737] = { { 420, 299, "Guloth", "Guloth", "", "b" }, { 220, 299, "Balhest", "Balhest", "", "b" } }
D.Boss[1879189787] = { { 634, 299, "Chieftain Gûrsh", "Caudillo Gûrsh", "", "b" }, { 348, 299, "Chieftain Gûrsh", "Caudillo Gûrsh", "", "b" }, { 584, 299, "Commander Unudhu", "Comandante Unudhu", "", "b" }, { 131, 301, "Commander Piztor", "Comandante Piztor", "", "b" } }
D.Boss[1879189788] = { { 404, 274, "Llygad the Blade", "Llygad la Hoja", "", "b" }, { 401, 195, "Chief Warrior Thurgtârk", "Thurgtârk el jefe de guerra", "", "b" }, { 400, 45, "Commander Târsh", "Comandante Târsh", "", "b" } }
D.Boss[1879189789] = { { 265, 533, "Grisgart", "Grisgart", "", "b" }, { 240, 552, "Rêmgoj", "Rêmgoj", "", "b" }, { 241, 517, "Praunk-goj", "Praunk-goj", "", "b" }, { 297, 552, "Burzgost", "Burzgost", "", "b" }, { 292, 512, "Burzdyr", "Burzdyr", "", "b" } }
D.Boss[1879189790] = { { 962, 207, "Zaudru", "Zaudru", "", "b" }, { 961, 265, "Breosal", "Breosal", "", "b" }, { 798, 581, "Breosal", "Breosal", "", "b" } }
D.Boss[1879190613] = { { 195, 389, "Gaerdring\nGaerthel", "Gaerdring\nGaerthel", "\n", "b" } }
D.Boss[1879190615] = { { 93, 211, "Sambrog", "Sambrog", "", "b" } }
D.Boss[1879193366] = { { 398, 185, "Vernon Thistlethorn", "Vernon Cardoespina", "", "b" }, { 356, 239, "Múl Dúin", "Múl Dúin", "", "b" }, { 445, 234, "Frûmolog", "Frûmolog", "", "b" }, { 398, 231, "Ferndúr the Virulent", "Ferndúr el Virulento", "", "b" }, { 398, 290, "Fithákh", "Fithákh", "", "b" } }
D.Boss[1879198093] = { { 843, 1050, "Dunhoth Nemúl\nFrothmar", "Dunhoth Nemúl\nFrothmar", "\n", "b" }, { 822, 550, "Dourbark", "Dourbark", "", "b" }, { 733, 503, "Baleleaf", "Baleleaf", "", "b" } }
D.Boss[1879198096] = { { 461, 287, "Olwir\nWil Wheatly\nOsan", "Olwir\nWil Wheatly\nOsan", "\n\n", "b" }, { 489, 261, "Lossoth-wight", "Lossoth-wight", "", "b" }, { 461, 315, "Saija\nGrimey Proudfoot", "Saija\nGrimey Ganapié", "\n", "b" } }
D.Boss[1879198097] = { { 392, 362, "Matumáth\nNarslaug\nMatúrz-olog\nIvar", "Matumáth\nNarslaug\nMatúrz-olog\nIvar", "\n\n\n", "b" }, { 417, 361, "Dúngorth", "Dúngorth", "", "b" } }
D.Boss[1879198099] = { { 345, 232, "Drugoth's Deathsworn", "Drugoth's Deathsworn", "", "b" } }
D.Boss[1879198101] = { { 354, 161, "Grimey Proudfoot", "Grimey Ganapié", "", "b" } }
D.Boss[1879210151] = { { 862, 728, "Mal Stackwort", "Mal Juntahierbas", "", "b" } }
D.Boss[1879219925] = { { 367, 261, "Draigoch's Body", "Draigoch's Body", "", "b" } }
D.Boss[1879222607] = { { 270, 465, "Saruman\nKâlbak", "Saruman\nKâlbak", "Cima de la torre\nAla de relámpago, delante a la derecha", "b" } }
D.Boss[1879222608] = { { 162, 204, "Iorweth", "Iorweth", "Ala de ácido, delante a la izquierda", "b" }, { 133, 190, "Saruman", "Saruman", "Cima de la torre", "b" } }
D.Boss[1879222609] = { { 296, 153, "Saruman\nCrisiant\nUsgarren", "Saruman\nCrisiant\nUsgarren", "Cima de la torre\nAla de fuego y hielo, detrás de la entrada\nAla de fuego y hielo, detrás de la entrada", "b" } }
D.Boss[1879224887] = { { 204, 301, "Bukot\nSaruman", "Bukot\nSaruman", "Ala de sombra, hacia la torre\nCima de la torre", "b" } }
D.Boss[1879226336] = { { 714, 780, "Zabúrz", "Zabúrz", "", "b" }, { 1132, 777, "Fúshbraf", "Fúshbraf", "", "b" }, { 722, 287, "Ironarm", "Ironarm", "", "b" } }
D.Boss[1879227068] = { { 751, 609, "Gurbák", "Gurbák", "", "b" }, { 872, 774, "Ghashanuz\nThe Ring-forge of Orthanc", "Ghashanuz\nThe Ring-forge of Orthanc", "\n", "b" }, { 701, 454, "Dhâr", "Dhâr", "", "b" } }
D.Boss[1879227951] = { { 328, 134, "Dargnákh", "Dargnákh", "", "b" }, { 402, 482, "Dargnákh", "Dargnákh", "", "b" } }
D.Boss[1879228447] = { { 416, 245, "Frûshkul", "Frûshkul", "", "b" } }
D.Boss[1879228448] = { { 646, 287, "Gurthúl", "Gurthúl", "Piso siguiente", "b" } }
D.Boss[1879256516] = { { 469, 742, "Grudom", "Grudom", "", "b" } }
D.Boss[1879256517] = { { 883, 491, "Brosh", "Brosh", "", "b" }, { 782, 493, "Mârubh", "Mârubh", "", "b" }, { 830, 481, "Warlord Shárnakh\nBrogasht, the Great Goblin\nGorgar the Ruthless\nUloga, The Great Goblin", "Warlord Shárnakh\nBroghasht, el Gran Trasgo\nGorgar el Despiadado\nUloga, el Gran Trasgo", "\n\n\n", "b" }, { 830, 575, "Hukmún\nUloga, The Great Goblin", "Hukmún\nUloga, el Gran Trasgo", "\n", "b" } }
D.Boss[1879323274] = { { 571, 423, "Muzgásh", "Muzgásh", "", "b" }, { 971, 378, "Dagron", "Dagron", "", "b" } }
D.Boss[1879323955] = { { 400, 332, "Lúmithil", "Lúmithil", "", "b" } }
D.Boss[1879334694] = { { 1557, 856, "Mordirith", "Mordirith", "Sala del trono, arriba", "b" }, { 1578, 1741, "Amarthiel", "Amarthiel", "", "b" }, { 2025, 1997, "Mordirith", "Mordirith", "Sala del trono, arriba", "b" } }
D.Boss[1879358738] = { { 410, 458, "Gorkasak, Captain of the Guard", "Gorkasak, Captain of the Guard", "", "b" }, { 781, 569, "Dulgabêth the Broken", "Dulgabêth the Broken", "", "b" }, { 410, 704, "Kulgrú, Mistress of the Household", "Kulgrú, Mistress of the Household", "", "b" }, { 1298, 567, "Zhólug", "Zhólug", "", "b" } }
D.Boss[1879361633] = { { 1478, 254, "Gumog\nUiliúr", "Gumog\nUiliúr", "\n", "b" }, { 1316, 281, "Gumog", "Gumog", "", "b" }, { 1044, 1120, "Thraknûl", "Thraknûl", "", "b" } }
D.Boss[1879388396] = { { 290, 310, "Rúnar Wolfstooth", "Rúnar Dientelobo", "", "b" } }
D.Boss[1879388912] = { { 2010, 1323, "Khúrthak the Rent", "Khúrthak the Rent", "", "b" } }
D.Boss[1879389689] = { { 793, 92, "Gurzhorn", "Gurzhorn", "", "b" }, { 721, 848, "Shalgoth", "Shalgoth", "", "b" } }
D.Boss[1879390420] = { { 382, 808, "Gwaurodel", "Gwaurodel", "", "b" }, { 434, 815, "Gwaurodel, the Lady of Foul Water", "Gwaurodel, the Lady of Foul Water", "", "b" }, { 1064, 811, "Balchneth", "Balchneth", "", "b" } }
D.Boss[1879395042] = { { 401, 208, "Mátrothog", "Mátrothog", "", "b" } }
D.Boss[1879395606] = { { 1239, 617, "Memory of Brogur", "Memory of Brogur", "", "b" }, { 1155, 611, "Memory of Candaith", "Memory of Candaith", "", "b" }, { 1157, 576, "Memory of Lorniel", "Memory of Lorniel", "", "b" }, { 1239, 661, "Memory of Fríthild", "Memory of Fríthild", "", "b" }, { 1151, 658, "Memory of Laerdan", "Memory of Laerdan", "", "b" }, { 1238, 576, "Memory of Halbarad", "Memory of Halbarad", "", "b" }, { 1197, 682, "Memory of Golasgil", "Recuerdo de Golasgil", "", "b" }, { 1197, 968, "Gurvand\nThe Ring-forge of Orthanc\nGurthúl\nUdúnion\nVrarz the Cook\nGorothúl\nSkorgrím Dourhand", "Gurvand\nThe Ring-forge of Orthanc\nGurthúl\nUdúnion\nVrarz el cocinero\nGorothúl\nSkorgrim Duramano", "\n\nPiso siguiente\n\n\n\n", "b" }, { 1253, 966, "Gúrthul\nGhashanuz", "Gúrthul\nGhashanuz", "Piso siguiente\n", "b" }, { 1255, 1013, "Gúrthul", "Gúrthul", "Piso siguiente", "b" }, { 1197, 1010, "Gúrthul", "Gúrthul", "Piso siguiente", "b" }, { 1150, 928, "Gúrthul", "Gúrthul", "Piso siguiente", "b" }, { 1199, 926, "Gúrthul", "Gúrthul", "Piso siguiente", "b" } }
D.Boss[1879421179] = { { 450, 251, "Raging Corraler", "Raging Corraler", "", "b" } }
D.Boss[1879421479] = { { 942, 566, "Mozrúk", "Mozrúk", "", "b" }, { 746, 592, "Gâdh-and-Shum", "Gâdh-and-Shum", "", "b" } }
D.Boss[1879442093] = { { 834, 792, "Arváng Blackfoot\nAndvár Crow-feeder", "Arváng Blackfoot\nAndvár Crow-feeder", "\n", "b" }, { 786, 793, "Náli the Thumb-taker\nNíthi the Cunning", "Náli the Thumb-taker\nNíthi the Cunning", "\n", "b" } }
D.Boss[1879443657] = { { 1605, 1429, "Kvethar\nThrekvegg", "Kvethár\nThrekvegg", "Primer encuentro\nPrimer encuentro", "b" }, { 1643, 1427, "Armod", "Armód", "Primer encuentro", "b" } }
D.Boss[1879443658] = { { 1858, 2127, "Thrall-lord Dushtalbúk", "Thrall-lord Dushtalbúk", "", "b" } }
D.Boss[1879453499] = { { 631, 692, "Gárvadach", "Gárvadach", "", "b" } }
D.Boss[1879456452] = { { 396, 300, "Aglond\nFelarod\nSarlant", "Aglond\nFelarod\nSarlant", "\n\n", "b" }, { 168, 300, "Prince Amondir", "Príncipe Amondir", "", "b" }, { 370, 301, "Luilloth\nAstoryn", "Luilloth\nAstoryn", "\n", "b" } }
D.Boss[1879456523] = { { 799, 721, "Castellan Obáshurz", "Castellan Obáshurz", "", "b" } }
D.Boss[1879456524] = { { 804, 353, "Claghord\nAsachal\nShard of Taúressar\nHigh Chieftain Claghórd", "Claghórd\nÁsachal\nFragmento de Tauressar\nHigh Chieftain Claghórd", "Tercer encuentro A\nTercer encuentro B\nCuarto encuentro\n", "b" }, { 800, 268, "High Priestess Ásachal", "High Priestess Ásachal", "", "b" } }
D.Boss[1879459099] = { { 798, 235, "Aniochán the Harrower", "Aniochán el Atormentador", "", "b" }, { 811, 208, "Kârsija", "Kârsija", "", "b" }, { 767, 241, "Kurja", "Kurja", "", "b" } }
D.Boss[1879478181] = { { 471, 298, "Jadazin\nNâxam\nKaranzôr\nZagarón\nPhêrida\nDulgakhó\nBurkhad\nÊphaltud", "Jadazin\nNâxam\nKaranzôr\nZagarón\nPhêrida\nDulgakhó\nBurkhad\nÊphaltud", "\n\n\nPrimer encuentro, acompañante\nPrimer encuentro, acompañante\n\nPrimer encuentro, acompañante\n", "b" }, { 444, 292, "Ishakhâr", "Ishakhâr", "Primer encuentro, T2 o superior", "b" } }
D.Boss[1879478486] = { { 949, 587, "Belondor\nLêshana\nKhalmôz\nUmini\nNâxam\nSallax\nShayuz\nMairan\nHâkraph\nHadûlo\nImephâr\nRamish", "Belondor\nLêshana\nKhalmôz\nUmini\nNâxam\nSallax\nShayuz\nMairan\nHâkraph\nHadûlo\nImephâr\nRamish", "Segundo encuentro\n\n\n\n\n\n\n\n\n\n\n", "b" }, { 1007, 808, "Umini\nRamish", "Umini\nRamish", "\n", "b" }, { 971, 803, "Nâxam\nHadûlo", "Nâxam\nHadûlo", "\n", "b" }, { 904, 804, "Shayuz\nImephâr", "Shayuz\nImephâr", "\n", "b" } }
D.Boss[1879478496] = { { 893, 617, "Umshûra the Glutton", "Umshûra the Glutton", "", "b" } }
D.Boss[1879478783] = { { 333, 224, "Lêshana\nKhalmôz\nSallax\nHâkraph\nBelondor", "Lêshana\nKhalmôz\nSallax\nHâkraph\nBelondor", "\n\n\n\nSegundo encuentro", "b" }, { 358, 218, "Mairan", "Mairan", "", "b" } }
D.Boss[1879480482] = { { 805, 661, "Akhmâr Redstorm\nHorthion\nNakrov the Scarred", "Akhmâr Redstorm\nHorthion\nNakrov the Scarred", "\n\n", "b" }, { 904, 661, "Ulanor\nShaidal\nBhastah\nShakfut", "Ulanor\nShaidal\nBhastah\nShakfut", "\n\n\n", "b" } }
D.Boss[1879487383] = { { 851, 584, "Ragrekhûl", "Ragrekhûl", "", "b" } }
D.Boss[1879491954] = { { 1023, 371, "Hashûga\nSharâtu\nKizurdâl", "Hashûga\nSharâtu\nKizurdâl", "\n\n", "b" }, { 760, 281, "Eshêgur the Reaper", "Eshêgur the Reaper", "", "b" } }
D.Boss[1879492990] = { { 903, 775, "Imanak-tûr", "Imanak-tûr", "", "b" }, { 581, 492, "Aratûg", "Aratûg", "", "b" }, { 1121, 486, "Sakhârshag", "Sakhârshag", "", "b" } }
D.Boss[1879494891] = { { 196, 510, "Bauko, Left Hand of Forgetting", "Bauko, Left Hand of Forgetting", "", "b" }, { 196, 471, "Daiko, Right Hand of Forgetting", "Daiko, Right Hand of Forgetting", "", "b" } }
D.Boss[1879495208] = { { 572, 536, "Kulkorth\nTamâkh", "Kulkorth\nTamâkh", "\n", "b" }, { 757, 593, "Kanâshu\nMaluchon, the Pale Brother", "Kanâshu\nMaluchon, the Pale Brother", "\n", "b" } }
D.Boss[1879495217] = { { 816, 630, "Kormoltur, Lord of Terror", "Kormoltur, Lord of Terror", "", "b" }, { 804, 688, "Rumók the Blood-spiller", "Rumók the Blood-spiller", "", "b" } }
D.Boss[1879495218] = { { 830, 570, "Thahar\nSagush", "Thahar\nSagush", "\n", "b" }, { 777, 551, "Thahar\nSagush", "Thahar\nSagush", "\n", "b" } }
D.Boss[1879503002] = { { 855, 712, "Kâlach Hûl\nMethân Sai\nRaghtâ Sai", "Kâlach Hûl\nMethân Sai\nRaghtâ Sai", "\n\n", "b" } }
D.Boss[1879507528] = { { 575, 970, "Blood Sorceress Agaris", "Blood Sorceress Agaris", "", "b" }, { 1115, 279, "Badharál's Webmother", "Badharál's Webmother", "", "b" }, { 846, 441, "Badharál's Webmother", "Badharál's Webmother", "", "b" }, { 583, 1011, "Badharál the Gorger", "Badharál the Gorger", "", "b" } }
D.Boss[1879507580] = { { 847, 812, "Blood Sorceress Agaris", "Blood Sorceress Agaris", "", "b" }, { 756, 815, "Cristhir the Night-shadow", "Cristhir the Night-shadow", "", "b" } }
D.Boss[1879507793] = { { 367, 963, "Zamâktar the Putrescent", "Zamâktar the Putrescent", "", "b" } }
D.Boss[1879509384] = { { 485, 302, "Cristhir the Night-shadow", "Cristhir the Night-shadow", "", "b" }, { 487, 206, "Maukhorn", "Maukhorn", "", "b" } }
D.Boss[1879517905] = { { 736, 702, "Giríshu, Thief of Blades\nSamâshu, Thief of Blight\nGizûshu, Thief of Shadows", "Giríshu, Thief of Blades\nSamâshu, Thief of Blight\nGizûshu, Thief of Shadows", "\n\n", "b" }, { 801, 382, "Molbása the Untamed", "Molbása the Untamed", "", "b" } }
D.Boss[1879520515] = { { 703, 586, "Ratúlko the Bloody", "Ratulko el Sanguinario", "", "b" }, { 730, 664, "Thothril the Entangler", "Thothril la Enredadora", "", "b" } }
D.ByName["Adkhât-zahhar, the Houses of Rest"] = { 1 }
D.ByName["Agoroth, the Narrowdelve"] = { 2 }
D.ByName["Annúminas: Glinghant"] = { 22 }
D.ByName["Annúminas: Haudh Valandil"] = { 25 }
D.ByName["Annúminas: Ost Elendil"] = { 34 }
D.ByName["Askâd-mazal, the Chamber of Shadows"] = { 4 }
D.ByName["Assault on Dhúrstrok"] = { 5 }
D.ByName["Barad Guldur"] = { 6 }
D.ByName["Barad Gúlaran"] = { 78 }
D.ByName["Bâr Nírnaeth, the Houses of Lamentation"] = { 8 }
D.ByName["Carn Dûm"] = { 80 }
D.ByName["Dahâl Huliz, The Arena"] = { 10 }
D.ByName["Dargnákh Unleashed"] = { 81 }
D.ByName["Dark Delvings"] = { 82 }
D.ByName["Den of Pughlak"] = { 11 }
D.ByName["Depths of Mâkhda Khorbo"] = { 83 }
D.ByName["Draigoch's Lair"] = { 84 }
D.ByName["Dun Shûma, The King's Fortress"] = { 14 }
D.ByName["Dungeons of Dol Guldur"] = { 15 }
D.ByName["Dâr Narbugud"] = { 85 }
D.ByName["Eithel Gwaur, the Filth-well"] = { 16 }
D.ByName["Ekal-nêbi, the Fallen Palace"] = { 86 }
D.ByName["Fil Gashan"] = { 88 }
D.ByName["Filikul"] = { 89 }
D.ByName["Fornost"] = { 72, 73, 74, 75 }
D.ByName["Garth Agarwen"] = { 77, 79, 90 }
D.ByName["Gath Daeroval, the Shadow-roost"] = { 18 }
D.ByName["Ghashan-kútot, the Halls of Black Lore"] = { 19 }
D.ByName["Glimmerdeep"] = { 21 }
D.ByName["Goblin-town Throne Room"] = { 91 }
D.ByName["Gorthad Nûr, the Deep-barrow"] = { 23 }
D.ByName["Gwathrenost, the Witch-king's Citadel"] = { 92 }
D.ByName["Halls of Crafting"] = { 93 }
D.ByName["Helegrod"] = { 12, 13, 20, 43 }
D.ByName["Inn of the Forsaken"] = { 26 }
D.ByName["Iorbar's Peak"] = { 27 }
D.ByName["Kôth Rau, the Wailing Hold"] = { 94 }
D.ByName["Library at Tham Mírdain"] = { 28 }
D.ByName["Lost Temple"] = { 29 }
D.ByName["Nirgambâr, the Restless Tomb"] = { 30 }
D.ByName["Ost Dunhoth"] = { 31, 32, 33 }
D.ByName["Pagru-kirít, the Garden of Corpses"] = { 95 }
D.ByName["Pits of Isengard"] = { 96 }
D.ByName["Remmorchant, the Net of Darkness"] = { 97 }
D.ByName["Sammath Gûl"] = { 37 }
D.ByName["Sarch Vorn, the Black Grave"] = { 39 }
D.ByName["School at Tham Mírdain"] = { 40 }
D.ByName["Seat of the Great Goblin"] = { 41 }
D.ByName["Shakalush, the Stair Battle"] = { 42 }
D.ByName["Skûmfil"] = { 99 }
D.ByName["Stoneheight"] = { 44 }
D.ByName["Sunken Labyrinth"] = { 45 }
D.ByName["Sword-hall of Dol Guldur"] = { 46 }
D.ByName["Sâri-surma"] = { 47 }
D.ByName["The Abyss of Mordath"] = { 100 }
D.ByName["The Anvil of Winterstith"] = { 101 }
D.ByName["The Court of Seregost"] = { 52 }
D.ByName["The Depths of Kidzul-kâlah"] = { 53 }
D.ByName["The Dome of Stars"] = { 54 }
D.ByName["The Dragon and the Storm"] = { 55 }
D.ByName["The Dungeons of Naerband"] = { 56 }
D.ByName["The Folly of Nagakhêdi"] = { 103 }
D.ByName["The Forges of Khazad-dûm"] = { 104 }
D.ByName["The Forgotten Treasury"] = { 105 }
D.ByName["The Foundry"] = { 106 }
D.ByName["The Grand Stair"] = { 107 }
D.ByName["The Great Barrow"] = { 23, 36, 48 }
D.ByName["The Hiddenhoard of Abnankâra"] = { 108 }
D.ByName["The Mirror-halls of Lumul-nar"] = { 109 }
D.ByName["The Northcotton Farm"] = { 62 }
D.ByName["The Quays of the Harlond"] = { 63 }
D.ByName["The Rift of Nûrz Ghâshu"] = { 110 }
D.ByName["The Ruined City"] = { 64 }
D.ByName["The Silent Street"] = { 65 }
D.ByName["The Sixteenth Hall"] = { 111 }
D.ByName["The Temple of Utug-bûr"] = { 112, 113, 114 }
D.ByName["The Tower of Orthanc"] = { 115 }
D.ByName["The Treasure Caves of Hurum Kâna"] = { 116 }
D.ByName["The Vile Maw"] = { 117 }
D.ByName["The Water Wheels: Nalâ-dûm"] = { 118 }
D.ByName["Thikil-gundu"] = { 67 }
D.ByName["Tûl Zakana, the Well of Forgetting"] = { 68 }
D.ByName["Urugarth"] = { 120 }
D.ByName["Warg-pens of Dol Guldur"] = { 69 }
D.ByName["Woe of the Willow"] = { 71 }
