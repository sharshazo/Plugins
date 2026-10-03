-- LOTRO_Quest_Assistant/Data/GroupQuestDB.lua
--
-- Misiones de GRUPO (pedido explicito del usuario, 2026-09-22: "las
-- misiones que son de mazmorras, raid, dungeon... sean de otro color
-- especifico... con un logo de grupo y que mencione que mazmorra o raid hay
-- que ir").
--
-- GENERADO (no escrito a mano) cruzando las 14.974 misiones de
-- QuestDatabase_001..011 (por su id hexadecimal real del juego) contra
-- lore/quests.xml de LotroCompanion/lotro-data (GitHub, datos extraidos del
-- propio cliente de LOTRO -- misma fuente que ya se uso para
-- QuestDatabase_011_Missing.lua). Ese archivo trae, por mision, el atributo
-- real size="SMALL_FELLOWSHIP"/"FELLOWSHIP"/"RAID" -- es el dato OFICIAL de
-- tamaño de grupo que el juego muestra en el diario, no una adivinanza por
-- nombre/categoria. 14.974/14.974 misiones cruzadas por id, 1.448 son de
-- grupo.
--
-- El lugar ("p") sale, en este orden de prioridad (todo dato real, nada
-- inventado):
--   1. nombre de la instancia (lore/instancesTree.xml) si coincide con una
--      de las "dungeons" (mapas interiores) que la mision referencia, con la
--      categoria real de la mision (ej. "Helegrod", "Great Barrows"), o con
--      el propio nombre de la mision (ej. "Featured Instance: Ost Dunhoth");
--   2. la instancia privada (lore/privateEncounters.xml, questId) atada a
--      la mision;
--   3. si no es una instancia: area/zona de la propia QuestDB (misiones de
--      grupo en zona abierta -- warbands, "Roving Threats", elites, etc.).
-- Los nombres de lugar quedan en INGLES a proposito (nombre propio oficial
-- del juego -- regla del proyecto: nunca traducir con IA ni inventar
-- nombres).
--
-- Campos: s = tamaño ("S" grupo pequeño 3, "F" comunidad 6, "R" incursion
-- 12+), k = tipo ("inst" mazmorra/incursion, "pe" instancia privada de
-- grupo, "skirm" escaramuza, "epic" batalla epica, "open" zona abierta),
-- p = lugar (puede ser "" si no hay uno real conocido).
-- Clave = QuestDB.quests[ndx].id (id real del juego, no el ndx -- asi no
-- se desalinea si algun dia se regeneran los bloques de QuestDatabase).
_G.GroupQuestDB = {
    ["70017529"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 39
    ["70002DF2"] = { s = "F", k = "open", p = "Giant Valley, The Trollshaws" }, -- 42
    ["700076AA"] = { s = "S", k = "open", p = "Northern Bree-fields, Bree-land" }, -- 55
    ["700442D7"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 86
    ["70028B83"] = { s = "R", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 113
    ["70017598"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 146
    ["70041173"] = { s = "F", k = "open", p = "Western Gondor: Tarlang's Crown" }, -- 170
    ["70001203"] = { s = "S", k = "open", p = "Eastern Malenhad, Angmar" }, -- 224
    ["70041176"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 227
    ["70017524"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 262
    ["7001758C"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 263
    ["7007161D"] = { s = "S", k = "open", p = "The Dry-whelm, Idagâl, the Dry-whelm" }, -- 280
    ["70017509"] = { s = "R", k = "open", p = "The Water-works, Bree-land" }, -- 282
    ["700381C5"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 287
    ["70015AD6"] = { s = "S", k = "open", p = "Nan Sirannon, Eregion" }, -- 289
    ["70015E1F"] = { s = "S", k = "open", p = "Glâd Ereg, Bree-land" }, -- 311
    ["70000DE9"] = { s = "S", k = "open", p = "Rushock Bog, The Shire" }, -- 346
    ["7000C389"] = { s = "S", k = "open", p = "Northern High Pass, The Misty Mountains" }, -- 374
    ["70041171"] = { s = "F", k = "open", p = "Dol Amroth, Western Gondor" }, -- 376
    ["70009EFA"] = { s = "F", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 404
    ["70058BB9"] = { s = "S", k = "open", p = "Elderslade: War of Three Peaks" }, -- 424
    ["70058BBC"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 521
    ["700173CF"] = { s = "S", k = "inst", p = "Library at Tham Mírdain" }, -- 527
    ["7003EAF9"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 650
    ["70018199"] = { s = "F", k = "open", p = "Nud-melek, Moria" }, -- 742
    ["70001104"] = { s = "F", k = "open", p = "South Trollshaws, The Trollshaws" }, -- 761
    ["7002C60A"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 870
    ["7002BD50"] = { s = "R", k = "open", p = "Nan Curunír, Dunland" }, -- 887
    ["7002CE2B"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 930
    ["7000BFC5"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 942
    ["70022B44"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1001
    ["70000152"] = { s = "S", k = "open", p = "Tookland, The Shire" }, -- 1013
    ["7000A8B8"] = { s = "S", k = "inst", p = "Annúminas" }, -- 1042
    ["7000BFCB"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 1065
    ["7000C38A"] = { s = "S", k = "open", p = "Northern High Pass, The Misty Mountains" }, -- 1076
    ["700076BE"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1140
    ["7000BFC9"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 1141
    ["70022B2D"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1271
    ["70022B2A"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1273
    ["70022B47"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1274
    ["700001BA"] = { s = "F", k = "open", p = "Western Malenhad, Angmar" }, -- 1276
    ["7000D7A2"] = { s = "F", k = "open", p = "Western Malenhad, Angmar" }, -- 1277
    ["700647D4"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 1302
    ["700088F2"] = { s = "F", k = "open", p = "Coldfells, The Ettenmoors" }, -- 1306
    ["700088F3"] = { s = "F", k = "open", p = "Coldfells, The Ettenmoors" }, -- 1310
    ["700088F4"] = { s = "F", k = "open", p = "Coldfells, The Ettenmoors" }, -- 1311
    ["700088F5"] = { s = "F", k = "open", p = "Coldfells, The Ettenmoors" }, -- 1312
    ["700088F6"] = { s = "R", k = "open", p = "Coldfells, The Ettenmoors" }, -- 1313
    ["7003E516"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 1341
    ["70058BB7"] = { s = "S", k = "open", p = "Elderslade" }, -- 1362
    ["7000A16A"] = { s = "F", k = "inst", p = "Barad Gúlaran" }, -- 1371
    ["7000ED96"] = { s = "F", k = "open", p = "Länsi-mâ, Forochel" }, -- 1373
    ["700006B7"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 1382
    ["70043407"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 1398
    ["70043409"] = { s = "S", k = "open", p = "Osgiliath, Eastern Gondor" }, -- 1400
    ["7004340B"] = { s = "F", k = "open", p = "Osgiliath, Eastern Gondor" }, -- 1402
    ["7005B453"] = { s = "S", k = "inst", p = "Assault on Dhúrstrok" }, -- 1419
    ["7005B452"] = { s = "S", k = "inst", p = "Assault on Dhúrstrok" }, -- 1420
    ["7005B450"] = { s = "S", k = "inst", p = "Assault on Dhúrstrok" }, -- 1421
    ["700381C4"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 1426
    ["70029FBE"] = { s = "R", k = "skirm", p = "Assault on the Ringwraiths' Lair" }, -- 1428
    ["70029FCB"] = { s = "R", k = "skirm", p = "Attack At Dawn" }, -- 1463
    ["700442CD"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 1482
    ["7003E367"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 1498
    ["7000A8F5"] = { s = "F", k = "inst", p = "Annúminas: Ost Elendil" }, -- 1533
    ["7000E3D9"] = { s = "S", k = "open", p = "Esteldín, Angmar" }, -- 1538
    ["7000D6B4"] = { s = "F", k = "open", p = "Imlad Balchorth, Angmar" }, -- 1542
    ["7001D1C7"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 1557
    ["7001D1CF"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 1558
    ["7001E5D6"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 1559
    ["70022B35"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1573
    ["70022B46"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 1574
    ["7001AB99"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 1576
    ["7005A748"] = { s = "F", k = "open", p = "Welkin-lofts, Gundabad" }, -- 1591
    ["7005A74A"] = { s = "S", k = "open", p = "Welkin-lofts, Gundabad" }, -- 1592
    ["7005A74F"] = { s = "F", k = "open", p = "Welkin-lofts, Gundabad" }, -- 1596
    ["7005A750"] = { s = "S", k = "open", p = "Welkin-lofts, Gundabad" }, -- 1598
    ["70029FC8"] = { s = "R", k = "skirm", p = "Battle of the Deep-way" }, -- 1606
    ["70029FCA"] = { s = "R", k = "skirm", p = "Battle of the Twenty-first Hall" }, -- 1611
    ["70029FC9"] = { s = "R", k = "skirm", p = "Battle of the Way of Smiths" }, -- 1612
    ["700173AD"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 1635
    ["700442CB"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 1644
    ["7005307C"] = { s = "S", k = "open", p = "Vales of Anduin: Gladdenmere" }, -- 1645
    ["70001813"] = { s = "F", k = "open", p = "Nan Amlug West, The North Downs" }, -- 1725
    ["700173AA"] = { s = "S", k = "open", p = "Emyn Naer, Eregion" }, -- 1730
    ["700173CE"] = { s = "S", k = "open", p = "Emyn Naer, Eregion" }, -- 1758
    ["70072F8C"] = { s = "S", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 1771
    ["70045221"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 1799
    ["70045251"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 1800
    ["700084CB"] = { s = "F", k = "open", p = "Western Malenhad, Angmar" }, -- 1805
    ["70022484"] = { s = "F", k = "inst", p = "Annúminas" }, -- 1806
    ["7000835B"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 1810
    ["70051640"] = { s = "R", k = "open", p = "Himbar, Angmar" }, -- 1826
    ["70048F7E"] = { s = "F", k = "open", p = "Dor Amarth, Mordor" }, -- 1832
    ["7000A8A9"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 1892
    ["7000B8DD"] = { s = "S", k = "open", p = "Rivendell Valley, The Trollshaws" }, -- 1913
    ["7000B8A2"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 1922
    ["7000B8A5"] = { s = "S", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 1928
    ["7000B8A6"] = { s = "S", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 1930
    ["7000B8A7"] = { s = "S", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 1932
    ["7000B8A8"] = { s = "S", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 1933
    ["7000B8E1"] = { s = "S", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 1937
    ["7000D4C4"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 1943
    ["7000D4BF"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 1944
    ["7000D4C0"] = { s = "F", k = "open", p = "Carn Dûm, Angmar" }, -- 1949
    ["7000D4C1"] = { s = "F", k = "open", p = "Carn Dûm, Angmar" }, -- 1950
    ["7000D558"] = { s = "F", k = "open", p = "Carn Dûm, Angmar" }, -- 1954
    ["7000D4C3"] = { s = "F", k = "open", p = "Carn Dûm, Angmar" }, -- 1957
    ["7000E064"] = { s = "S", k = "open", p = "Talvi-mûri, Forochel" }, -- 1977
    ["7000E069"] = { s = "F", k = "open", p = "Talvi-mûri, Forochel" }, -- 1985
    ["7001016C"] = { s = "F", k = "open", p = "Jä-rannit, Forochel" }, -- 1988
    ["7001016F"] = { s = "F", k = "open", p = "Rivendell Valley, The Trollshaws" }, -- 1991
    ["70010172"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 1994
    ["700169E6"] = { s = "F", k = "open", p = "Himbar, The Trollshaws" }, -- 2014
    ["70000686"] = { s = "F", k = "open", p = "Nain Enidh, The Lone-lands" }, -- 2030
    ["70000703"] = { s = "F", k = "open", p = "The Weather Hills, The Lone-lands" }, -- 2045
    ["70001802"] = { s = "F", k = "open", p = "Nan Amlug West, The North Downs" }, -- 2076
    ["700000F5"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 2081
    ["70000100"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 2086
    ["70000FBF"] = { s = "F", k = "open", p = "Bruinen Gorges, The Trollshaws" }, -- 2126
    ["70001103"] = { s = "F", k = "open", p = "Bruinen Gorges, The Trollshaws" }, -- 2139
    ["70000FC2"] = { s = "F", k = "open", p = "Rivendell Valley, The Trollshaws" }, -- 2147
    ["7000113F"] = { s = "F", k = "open", p = "Bruinen Source West, The Misty Mountains" }, -- 2172
    ["700001E6"] = { s = "F", k = "open", p = "Rivendell Valley, The Trollshaws" }, -- 2178
    ["7000019C"] = { s = "F", k = "pe", p = "The Gates of Carn Dûm" }, -- 2236
    ["7000018E"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 2245
    ["7000019E"] = { s = "S", k = "open", p = "Himbar, Angmar" }, -- 2256
    ["70059A0B"] = { s = "F", k = "open", p = "Agamaur, The Lone-lands" }, -- 2298
    ["70059A71"] = { s = "F", k = "open", p = "Agamaur, The Lone-lands" }, -- 2299
    ["70059A72"] = { s = "F", k = "open", p = "Agamaur, The Lone-lands" }, -- 2300
    ["7005A464"] = { s = "F", k = "open", p = "Spring Festival" }, -- 2301
    ["70051EF6"] = { s = "F", k = "inst", p = "Boss from the Vaults: Storvâgûn" }, -- 2302
    ["7004DE61"] = { s = "F", k = "inst", p = "Boss from the Vaults: Thrâng" }, -- 2303
    ["70009A0E"] = { s = "S", k = "open", p = "Tyrn Fornech, Evendim" }, -- 2314
    ["70045220"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 2322
    ["7005467C"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 2323
    ["7006AA3A"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 2329
    ["7006AA3B"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 2330
    ["7006AA3E"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 2331
    ["7005A955"] = { s = "S", k = "open", p = "Máttugard, Gundabad" }, -- 2370
    ["70068F38"] = { s = "S", k = "open", p = "Zamarzîr, The Shield Isles" }, -- 2384
    ["70068F36"] = { s = "S", k = "open", p = "Zamarzîr, The Shield Isles" }, -- 2385
    ["70068F37"] = { s = "S", k = "open", p = "Zamarzîr, The Shield Isles" }, -- 2386
    ["70068F35"] = { s = "S", k = "open", p = "Zamarzîr, The Shield Isles" }, -- 2387
    ["70068F39"] = { s = "S", k = "open", p = "Zamarzîr, The Shield Isles" }, -- 2388
    ["7006AA3D"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 2389
    ["7006AA3C"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 2390
    ["70044C15"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 2412
    ["70044F24"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 2414
    ["70044C17"] = { s = "S", k = "open", p = "Ashes and Stars" }, -- 2415
    ["70044F8C"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 2416
    ["70044C16"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 2417
    ["7003694E"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 2452
    ["700381C0"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 2453
    ["70029FC0"] = { s = "R", k = "skirm", p = "Breaching the Necromancer's Gate" }, -- 2455
    ["700381C2"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 2475
    ["7000B3E1"] = { s = "S", k = "open", p = "Isendeep Mine" }, -- 2496
    ["700442DB"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 2506
    ["700509C1"] = { s = "F", k = "open", p = "Ered Mithrin, The Dwarf-holds" }, -- 2512
    ["70035059"] = { s = "S", k = "open", p = "The Fallows, Wildermore" }, -- 2513
    ["700005E9"] = { s = "S", k = "open", p = "Nen Harn, Bree-land" }, -- 2576
    ["700509C7"] = { s = "F", k = "open", p = "Ered Mithrin, The Dwarf-holds" }, -- 2583
    ["7000D4F2"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 2584
    ["70054D7B"] = { s = "F", k = "inst", p = "Bâr Nírnaeth, the Houses of Lamentation" }, -- 2586
    ["70054D79"] = { s = "F", k = "inst", p = "Bâr Nírnaeth, the Houses of Lamentation" }, -- 2587
    ["70054D7A"] = { s = "F", k = "inst", p = "Bâr Nírnaeth, the Houses of Lamentation" }, -- 2588
    ["7002C60C"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 2589
    ["7000874F"] = { s = "R", k = "open", p = "Steps of Gram, The Ettenmoors" }, -- 2631
    ["7000173A"] = { s = "F", k = "open", p = "Rhunenlad, The North Downs" }, -- 2634
    ["70017AEA"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 2637
    ["70008852"] = { s = "F", k = "open", p = "Hithlad, The Ettenmoors" }, -- 2662
    ["7004E748"] = { s = "S", k = "inst", p = "Caverns of Thrumfall" }, -- 2688
    ["7004E74B"] = { s = "S", k = "inst", p = "Caverns of Thrumfall" }, -- 2689
    ["7004E74D"] = { s = "S", k = "inst", p = "Caverns of Thrumfall" }, -- 2690
    ["7000D6B5"] = { s = "F", k = "open", p = "Imlad Balchorth, Angmar" }, -- 2692
    ["7001ECCF"] = { s = "R", k = "open", p = "Gathbúrz, Mirkwood" }, -- 2708
    ["7001757E"] = { s = "F", k = "inst", p = "Dark Delvings" }, -- 2709
    ["7004BD2F"] = { s = "R", k = "inst", p = "The Abyss of Mordath" }, -- 2710
    ["7002BD16"] = { s = "R", k = "inst", p = "Isengard" }, -- 2711
    ["7003332C"] = { s = "R", k = "open", p = "The Road to Erebor" }, -- 2712
    ["70022483"] = { s = "F", k = "inst", p = "Annúminas" }, -- 2713
    ["7001EEF8"] = { s = "S", k = "inst", p = "Sword-hall of Dol Guldur" }, -- 2714
    ["7001E685"] = { s = "S", k = "inst", p = "The Water Wheels: Nalâ-dûm" }, -- 2715
    ["700459BE"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2716
    ["7002ADBF"] = { s = "R", k = "inst", p = "Isengard" }, -- 2718
    ["7002497E"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2719
    ["7002B09B"] = { s = "R", k = "inst", p = "Isengard" }, -- 2720
    ["7002A828"] = { s = "S", k = "inst", p = "Dargnákh Unleashed" }, -- 2721
    ["70028B8E"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2722
    ["7001E5E2"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 2723
    ["7001E684"] = { s = "S", k = "inst", p = "Moria" }, -- 2724
    ["7002497C"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2725
    ["70045222"] = { s = "S", k = "open", p = "The Battle of Pelennor" }, -- 2726
    ["700459BC"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2728
    ["7002A70B"] = { s = "R", k = "inst", p = "Isengard" }, -- 2729
    ["700223B7"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 2730
    ["700595ED"] = { s = "F", k = "open", p = "Lossarnach" }, -- 2731
    ["700595F0"] = { s = "S", k = "open", p = "Lossarnach" }, -- 2732
    ["70022B2F"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 2733
    ["7001E687"] = { s = "F", k = "inst", p = "Moria" }, -- 2734
    ["7001CD58"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 2735
    ["70022578"] = { s = "R", k = "inst", p = "Helegrod" }, -- 2736
    ["7001E686"] = { s = "F", k = "inst", p = "Moria" }, -- 2737
    ["7004356B"] = { s = "S", k = "open", p = "" }, -- 2738
    ["7001E68B"] = { s = "F", k = "inst", p = "Moria" }, -- 2739
    ["7001E689"] = { s = "F", k = "inst", p = "Moria" }, -- 2740
    ["7002D568"] = { s = "F", k = "inst", p = "Fornost" }, -- 2741
    ["7001D019"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 2742
    ["7004C02A"] = { s = "F", k = "inst", p = "The Court of Seregost" }, -- 2743
    ["7001E688"] = { s = "F", k = "inst", p = "Moria" }, -- 2744
    ["70044F25"] = { s = "S", k = "open", p = "The Battle of Pelennor" }, -- 2745
    ["70024975"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2746
    ["7002D5D4"] = { s = "F", k = "inst", p = "Fornost" }, -- 2747
    ["70036F82"] = { s = "S", k = "open", p = "Bree-land" }, -- 2748
    ["7001EEF9"] = { s = "S", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 2749
    ["7001E5E3"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 2750
    ["7002247C"] = { s = "F", k = "inst", p = "Annúminas" }, -- 2751
    ["70043535"] = { s = "F", k = "open", p = "Osgiliath, Eastern Gondor" }, -- 2752
    ["7002D478"] = { s = "F", k = "inst", p = "Fornost" }, -- 2753
    ["7002BBD3"] = { s = "R", k = "inst", p = "Isengard" }, -- 2754
    ["7003354A"] = { s = "S", k = "open", p = "The Road to Erebor" }, -- 2757
    ["70044F8B"] = { s = "F", k = "open", p = "Minas Tirith, Anórien" }, -- 2758
    ["7002CDB9"] = { s = "F", k = "inst", p = "Roots of Fangorn" }, -- 2759
    ["70022B4A"] = { s = "F", k = "inst", p = "Great Barrow: Sambrog" }, -- 2760
    ["700459C0"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2761
    ["700607AF"] = { s = "F", k = "open", p = "Bree, Bree-land" }, -- 2762
    ["700607AA"] = { s = "S", k = "open", p = "Bree, Bree-land" }, -- 2763
    ["700249BF"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2764
    ["700228B3"] = { s = "R", k = "inst", p = "Helegrod" }, -- 2765
    ["70043389"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 2766
    ["70025608"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 2767
    ["7004BCEA"] = { s = "F", k = "inst", p = "The Dungeons of Naerband" }, -- 2768
    ["70022B32"] = { s = "F", k = "inst", p = "Great Barrow: Thadúr" }, -- 2769
    ["7001E683"] = { s = "F", k = "inst", p = "Moria" }, -- 2770
    ["70033C7F"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 2771
    ["7002D418"] = { s = "F", k = "inst", p = "Fornost" }, -- 2772
    ["70051B72"] = { s = "F", k = "open", p = "Frostbluff, Festival Grounds" }, -- 2773
    ["70051B77"] = { s = "S", k = "open", p = "Frostbluff, Festival Grounds" }, -- 2774
    ["7001E681"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 2775
    ["70051398"] = { s = "S", k = "pe", p = "The Howling Pit" }, -- 2776
    ["7001ECE1"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 2777
    ["7001E68A"] = { s = "F", k = "inst", p = "Moria" }, -- 2778
    ["7002371A"] = { s = "F", k = "inst", p = "Lost Temple" }, -- 2779
    ["7004BD2D"] = { s = "R", k = "inst", p = "The Abyss of Mordath" }, -- 2780
    ["7002712C"] = { s = "S", k = "open", p = "Lone-lands" }, -- 2781
    ["70024C7B"] = { s = "R", k = "open", p = "Lich Bluffs, Enedwaith" }, -- 2782
    ["7004BD2E"] = { s = "R", k = "inst", p = "The Abyss of Mordath" }, -- 2783
    ["700459C1"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2784
    ["7002B6DB"] = { s = "F", k = "inst", p = "The Foundry" }, -- 2785
    ["7001ECE2"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 2786
    ["70025384"] = { s = "S", k = "open", p = "In Their Absence" }, -- 2787
    ["700255E0"] = { s = "S", k = "open", p = "Northcotton Farm, The Shire" }, -- 2788
    ["70037E08"] = { s = "S", k = "open", p = "Westfold" }, -- 2789
    ["7001E682"] = { s = "F", k = "inst", p = "Dol Guldur" }, -- 2790
    ["7004E1AF"] = { s = "F", k = "open", p = "Green Hill Country, The Shire" }, -- 2791
    ["7004E1AC"] = { s = "R", k = "open", p = "Green Hill Country, The Shire" }, -- 2792
    ["7004E1AE"] = { s = "S", k = "open", p = "Green Hill Country, The Shire" }, -- 2793
    ["7002497D"] = { s = "R", k = "open", p = "In Their Absence" }, -- 2794
    ["700459BD"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2795
    ["7001ECE0"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 2796
    ["700459BF"] = { s = "R", k = "open", p = "The Battle of Pelennor" }, -- 2797
    ["70022489"] = { s = "F", k = "inst", p = "Annúminas" }, -- 2798
    ["700374ED"] = { s = "S", k = "open", p = "Westfold" }, -- 2799
    ["70032BDC"] = { s = "F", k = "inst", p = "Webs of the Scuttledells" }, -- 2800
    ["700228C6"] = { s = "R", k = "inst", p = "Helegrod" }, -- 2801
    ["7006447E"] = { s = "F", k = "open", p = "Ephel Angren, Angmar" }, -- 2802
    ["7000256A"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 2812
    ["70025394"] = { s = "F", k = "open", p = "Nan Laeglin, Enedwaith" }, -- 2872
    ["7001AC57"] = { s = "S", k = "inst", p = "The Mirror-halls of Lumul-nar" }, -- 3101
    ["7001AC58"] = { s = "S", k = "inst", p = "The Water Wheels: Nalâ-dûm" }, -- 3143
    ["70025378"] = { s = "F", k = "open", p = "Nan Laeglin, Enedwaith" }, -- 3150
    ["70025391"] = { s = "F", k = "open", p = "Nan Laeglin, Enedwaith" }, -- 3270
    ["70014647"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 3277
    ["700173A6"] = { s = "S", k = "open", p = "Mirobel, Eregion" }, -- 3378
    ["70022B34"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 3382
    ["700173B1"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 3422
    ["7001BEB4"] = { s = "F", k = "open", p = "Vale of Thrain, Ered Luin" }, -- 3437
    ["70025134"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 3477
    ["70022A85"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 3478
    ["700033FD"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 3499
    ["700173AB"] = { s = "S", k = "open", p = "Emyn Naer, Eregion" }, -- 3513
    ["70058AEC"] = { s = "R", k = "inst", p = "Amdân Dammul, the Bloody Threshold" }, -- 3529
    ["70058AF8"] = { s = "R", k = "inst", p = "Amdân Dammul, the Bloody Threshold" }, -- 3530
    ["70058AF9"] = { s = "R", k = "inst", p = "Amdân Dammul, the Bloody Threshold" }, -- 3531
    ["70058AFA"] = { s = "R", k = "inst", p = "Amdân Dammul, the Bloody Threshold" }, -- 3532
    ["70058AFB"] = { s = "R", k = "inst", p = "Amdân Dammul, the Bloody Threshold" }, -- 3533
    ["70056968"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 3535
    ["70056966"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 3536
    ["70056967"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 3537
    ["700579A3"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 3538
    ["700579A4"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 3539
    ["70022B45"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 3546
    ["7003EA77"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 3569
    ["7000AC4F"] = { s = "F", k = "open", p = "Hoardale, The Ettenmoors" }, -- 3640
    ["7000887D"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 3746
    ["70022B2B"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 3747
    ["7000D4E4"] = { s = "S", k = "open", p = "Himbar, Angmar" }, -- 3754
    ["7002272A"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 3775
    ["7001D0CE"] = { s = "S", k = "open", p = "Gathbúrz, Mirkwood" }, -- 3778
    ["70043DFA"] = { s = "S", k = "inst", p = "Osgiliath: Court of Isildur" }, -- 3783
    ["70065E97"] = { s = "S", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 3813
    ["70043DEC"] = { s = "F", k = "inst", p = "Osgiliath: Court of Anárion" }, -- 3835
    ["7006AA44"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 3883
    ["7006AAC8"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 3892
    ["7006AAAC"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 3893
    ["7006AA93"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 3894
    ["7006AA94"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 3897
    ["70022744"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 3942
    ["7002C60E"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 3943
    ["7002A827"] = { s = "S", k = "inst", p = "Dargnákh Unleashed" }, -- 3944
    ["7002BDB5"] = { s = "R", k = "inst", p = "Dargnákh Unleashed" }, -- 3945
    ["7002BD17"] = { s = "S", k = "open", p = "Nan Curunír, Dunland" }, -- 3946
    ["7001EDFF"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 3950
    ["700173B4"] = { s = "F", k = "open", p = "Silvertine Lodes, Moria" }, -- 3951
    ["70017516"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 3952
    ["7001750E"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 3953
    ["7001751C"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 3954
    ["7000222D"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 3957
    ["7000222F"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 3966
    ["7002247B"] = { s = "F", k = "inst", p = "Annúminas" }, -- 3970
    ["7004117C"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 3991
    ["70058B89"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 4059
    ["70002231"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 4069
    ["7001BECC"] = { s = "F", k = "open", p = "Vale of Thrain, Ered Luin" }, -- 4077
    ["700173BA"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 4079
    ["70029FC4"] = { s = "R", k = "skirm", p = "Defence of The Prancing Pony" }, -- 4087
    ["70009E79"] = { s = "F", k = "open", p = "Tírith Rhaw, The Ettenmoors" }, -- 4088
    ["70009E77"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 4089
    ["70009E78"] = { s = "F", k = "open", p = "Arador's End, The Ettenmoors" }, -- 4093
    ["70009E76"] = { s = "F", k = "open", p = "Hithlad, The Ettenmoors" }, -- 4094
    ["7002560B"] = { s = "F", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 4117
    ["7005B0D6"] = { s = "S", k = "inst", p = "Den of Pughlak" }, -- 4165
    ["7005B0D1"] = { s = "S", k = "inst", p = "Den of Pughlak" }, -- 4166
    ["7005B0D3"] = { s = "S", k = "inst", p = "Den of Pughlak" }, -- 4167
    ["700267F8"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 4169
    ["700173B5"] = { s = "F", k = "open", p = "Silvertine Lodes, Moria" }, -- 4172
    ["700442CE"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 4187
    ["700173B9"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 4264
    ["70000192"] = { s = "S", k = "open", p = "Imlad Balchorth, Angmar" }, -- 4279
    ["7001BE11"] = { s = "F", k = "open", p = "Vale of Thrain, Ered Luin" }, -- 4313
    ["70022B3A"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 4333
    ["7002C60F"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 4372
    ["70062EF4"] = { s = "R", k = "skirm", p = "Doom of Caras Gelebren" }, -- 4374
    ["7006AACB"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 4375
    ["7000B961"] = { s = "F", k = "open", p = "Tâl Bruinen, The Trollshaws" }, -- 4387
    ["7000E39D"] = { s = "S", k = "open", p = "Taur Orthon, Forochel" }, -- 4422
    ["700442DA"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 4429
    ["7004BCE9"] = { s = "F", k = "inst", p = "The Dungeons of Naerband" }, -- 4447
    ["7004BCEB"] = { s = "F", k = "inst", p = "The Dungeons of Naerband" }, -- 4448
    ["7005A2E3"] = { s = "R", k = "open", p = "Azanulbizar, T.A. 2799, Tales of Yore: Azanulbizar" }, -- 4464
    ["70008762"] = { s = "F", k = "open", p = "Steps of Gram, The Ettenmoors" }, -- 4478
    ["700192D2"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4505
    ["700192CE"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4506
    ["700193D1"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4507
    ["700192D1"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4508
    ["700192D3"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4509
    ["700192D0"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4511
    ["700195A4"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 4512
    ["70053A96"] = { s = "S", k = "inst", p = "Eithel Gwaur, the Filth-well" }, -- 4614
    ["70053AB0"] = { s = "S", k = "inst", p = "Eithel Gwaur, the Filth-well" }, -- 4615
    ["70053ABB"] = { s = "S", k = "inst", p = "Eithel Gwaur, the Filth-well" }, -- 4616
    ["7000D6B7"] = { s = "S", k = "open", p = "Imlad Balchorth, Angmar" }, -- 4634
    ["7005AFFF"] = { s = "S", k = "open", p = "Azanulbizar, T.A. 2799, Tales of Yore: Azanulbizar" }, -- 4642
    ["70051605"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 4702
    ["70051608"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 4703
    ["70051602"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 4705
    ["70051609"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 4706
    ["7004799E"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 4720
    ["7000A8F7"] = { s = "F", k = "inst", p = "Annúminas" }, -- 4727
    ["7000885B"] = { s = "F", k = "open", p = "Hithlad, The Ettenmoors" }, -- 4729
    ["700001AA"] = { s = "S", k = "open", p = "Nan Gurth, Angmar" }, -- 4730
    ["700001A6"] = { s = "F", k = "inst", p = "Urugarth" }, -- 4731
    ["7000807F"] = { s = "S", k = "open", p = "Fields of Fornost, The North Downs" }, -- 4732
    ["70058BB6"] = { s = "S", k = "open", p = "Elderslade: The War of Three Peaks" }, -- 4745
    ["70058B85"] = { s = "S", k = "open", p = "Elderslade: The War of Three Peaks" }, -- 4746
    ["700173CD"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 4751
    ["70043DFC"] = { s = "F", k = "inst", p = "Osgiliath: Court of Isildur" }, -- 4761
    ["70043DED"] = { s = "F", k = "inst", p = "Osgiliath: Court of Anárion" }, -- 4762
    ["70058B87"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 4765
    ["70056942"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 4773
    ["700442C9"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 4795
    ["700442D8"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 4797
    ["700442CA"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 4799
    ["700442D5"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 4801
    ["70042885"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 4806
    ["7000A8F8"] = { s = "F", k = "inst", p = "Annúminas: Ost Elendil" }, -- 4878
    ["700076B8"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 4881
    ["7006E967"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 4884
    ["700077F6"] = { s = "F", k = "open", p = "Staddle, Bree-land" }, -- 4987
    ["7003EB04"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 4998
    ["700083A5"] = { s = "S", k = "open", p = "Fasach-larran, Angmar" }, -- 5004
    ["70025774"] = { s = "S", k = "inst", p = "Halls of Night" }, -- 5010
    ["70008822"] = { s = "F", k = "open", p = "Lugazag, The Ettenmoors" }, -- 5028
    ["7001A6ED"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5072
    ["7001E803"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5073
    ["7001A6EB"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5074
    ["7001A6F3"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5075
    ["7001A6F5"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5076
    ["7001A6F1"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5077
    ["7001A6E9"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5078
    ["7001A6F7"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5079
    ["7001A6EF"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5080
    ["70050DF7"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 5115
    ["7004E5E1"] = { s = "F", k = "inst", p = "Fornost: Wraith of Shadow" }, -- 5116
    ["70050DF6"] = { s = "R", k = "inst", p = "Helegrod: Spider Wing" }, -- 5117
    ["7004E5DD"] = { s = "F", k = "inst", p = "Ost Dunhoth" }, -- 5118
    ["7004E5DE"] = { s = "F", k = "open", p = "In Their Absence" }, -- 5119
    ["70050DF3"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 5120
    ["7004E5DC"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 5121
    ["70050DF5"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 5122
    ["7004E5E2"] = { s = "F", k = "inst", p = "The Northcotton Farm" }, -- 5123
    ["70050DF2"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 5124
    ["70050DF4"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 5125
    ["7004E5DF"] = { s = "F", k = "inst", p = "Webs of the Scuttledells" }, -- 5126
    ["7006435B"] = { s = "S", k = "inst", p = "Agoroth, the Narrowdelve" }, -- 5127
    ["70064360"] = { s = "S", k = "inst", p = "Agoroth, the Narrowdelve" }, -- 5128
    ["7006436A"] = { s = "S", k = "inst", p = "Askâd-mazal, the Chamber of Shadows" }, -- 5129
    ["7006435F"] = { s = "S", k = "inst", p = "Askâd-mazal, the Chamber of Shadows" }, -- 5130
    ["7004A087"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 5131
    ["7004A088"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 5132
    ["70050DDA"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 5133
    ["70050DDF"] = { s = "S", k = "inst", p = "Blood of the Black Serpent" }, -- 5134
    ["7006436C"] = { s = "S", k = "inst", p = "The Court of Seregost" }, -- 5135
    ["70064365"] = { s = "S", k = "inst", p = "The Court of Seregost" }, -- 5136
    ["70046240"] = { s = "F", k = "inst", p = "Dungeons of Dol Guldur" }, -- 5137
    ["7004623E"] = { s = "F", k = "inst", p = "Dungeons of Dol Guldur" }, -- 5138
    ["7006435C"] = { s = "F", k = "inst", p = "The Dungeons of Naerband" }, -- 5139
    ["70064369"] = { s = "F", k = "inst", p = "The Dungeons of Naerband" }, -- 5140
    ["70048711"] = { s = "R", k = "inst", p = "Flight to the Lonely Mountain" }, -- 5141
    ["70048706"] = { s = "R", k = "inst", p = "Flight to the Lonely Mountain" }, -- 5142
    ["70048709"] = { s = "F", k = "inst", p = "Fornost: Wraith of Earth" }, -- 5143
    ["70048710"] = { s = "F", k = "inst", p = "Fornost: Wraith of Earth" }, -- 5144
    ["7004CF5B"] = { s = "F", k = "inst", p = "Fornost: Wraith of Fire" }, -- 5145
    ["7004CF5C"] = { s = "F", k = "inst", p = "Fornost: Wraith of Fire" }, -- 5146
    ["7004E514"] = { s = "F", k = "inst", p = "Fornost: Wraith of Shadow" }, -- 5147
    ["7004E515"] = { s = "F", k = "inst", p = "Fornost: Wraith of Shadow" }, -- 5148
    ["70046FD4"] = { s = "F", k = "inst", p = "Fornost: Wraith of Water" }, -- 5149
    ["70046FCB"] = { s = "F", k = "inst", p = "Fornost: Wraith of Water" }, -- 5150
    ["70048707"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 5151
    ["7004870B"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 5152
    ["7006435E"] = { s = "F", k = "inst", p = "Great Barrow: Thadúr" }, -- 5153
    ["70064361"] = { s = "F", k = "inst", p = "Great Barrow: Thadúr" }, -- 5154
    ["7004CF5E"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 5155
    ["7004CF5D"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 5156
    ["70045683"] = { s = "S", k = "open", p = "Angmar" }, -- 5157
    ["7004567F"] = { s = "S", k = "open", p = "Angmar" }, -- 5158
    ["70046FCD"] = { s = "F", k = "inst", p = "Annúminas: Haudh Valandil" }, -- 5159
    ["70046FCF"] = { s = "F", k = "inst", p = "Annúminas: Haudh Valandil" }, -- 5160
    ["70046241"] = { s = "R", k = "inst", p = "Helegrod: Drake Wing" }, -- 5161
    ["7004623F"] = { s = "R", k = "inst", p = "Helegrod: Drake Wing" }, -- 5162
    ["70064363"] = { s = "R", k = "inst", p = "Helegrod: Giant Wing" }, -- 5163
    ["7006435A"] = { s = "R", k = "inst", p = "Helegrod: Giant Wing" }, -- 5164
    ["70050DDE"] = { s = "R", k = "inst", p = "Helegrod: Spider Wing" }, -- 5165
    ["70050DDB"] = { s = "R", k = "inst", p = "Helegrod: Spider Wing" }, -- 5166
    ["7004567E"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 5167
    ["70045685"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 5168
    ["70046FCC"] = { s = "S", k = "inst", p = "Iorbar's Peak" }, -- 5169
    ["70046FD1"] = { s = "S", k = "inst", p = "Iorbar's Peak" }, -- 5170
    ["7006434E"] = { s = "S", k = "inst", p = "Library at Tham Mírdain" }, -- 5171
    ["7006434F"] = { s = "S", k = "inst", p = "Library at Tham Mírdain" }, -- 5172
    ["7004870C"] = { s = "F", k = "open", p = "In Their Absence" }, -- 5173
    ["7004870D"] = { s = "F", k = "open", p = "In Their Absence" }, -- 5174
    ["70046FD0"] = { s = "S", k = "inst", p = "The Northcotton Farm" }, -- 5175
    ["70046FCE"] = { s = "S", k = "inst", p = "The Northcotton Farm" }, -- 5176
    ["70046FF7"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5177
    ["70046FF8"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5178
    ["70064362"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5179
    ["70064367"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5180
    ["70045315"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5181
    ["70045549"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 5182
    ["70045684"] = { s = "F", k = "inst", p = "Annúminas: Ost Elendil" }, -- 5183
    ["7004567C"] = { s = "F", k = "inst", p = "Annúminas: Ost Elendil" }, -- 5184
    ["70050DDD"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 5185
    ["70050DE0"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 5186
    ["70045680"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 5187
    ["70045681"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 5188
    ["70064366"] = { s = "F", k = "inst", p = "Sarch Vorn, the Black Grave" }, -- 5189
    ["70064368"] = { s = "F", k = "inst", p = "Sarch Vorn, the Black Grave" }, -- 5190
    ["70050DD7"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 5191
    ["70050DD8"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 5192
    ["7004870F"] = { s = "S", k = "inst", p = "Seat of the Great Goblin" }, -- 5193
    ["7004870A"] = { s = "S", k = "inst", p = "Seat of the Great Goblin" }, -- 5194
    ["700461CA"] = { s = "S", k = "open", p = "In Their Absence" }, -- 5195
    ["7004623A"] = { s = "S", k = "open", p = "In Their Absence" }, -- 5196
    ["7004CF56"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 5197
    ["7004CF55"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 5198
    ["70048708"] = { s = "S", k = "inst", p = "Sword-hall of Dol Guldur" }, -- 5199
    ["7004870E"] = { s = "S", k = "inst", p = "Sword-hall of Dol Guldur" }, -- 5200
    ["70046FD3"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 5201
    ["70046FD2"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 5202
    ["7004CF62"] = { s = "R", k = "inst", p = "The Battle for Erebor" }, -- 5203
    ["7004CF61"] = { s = "R", k = "inst", p = "The Battle for Erebor" }, -- 5204
    ["70045682"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 5205
    ["7004567D"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 5206
    ["7004CF5A"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 5207
    ["7004CF59"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 5208
    ["7004CF58"] = { s = "S", k = "open", p = "Eastern Gondor: Osgiliath" }, -- 5209
    ["7004CF57"] = { s = "S", k = "open", p = "Eastern Gondor: Osgiliath" }, -- 5210
    ["70050DDC"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 5211
    ["70050DD9"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 5212
    ["7006436D"] = { s = "S", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 5213
    ["7006435D"] = { s = "S", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 5214
    ["7004CF5F"] = { s = "S", k = "inst", p = "Webs of the Scuttledells" }, -- 5215
    ["7004CF60"] = { s = "S", k = "inst", p = "Webs of the Scuttledells" }, -- 5216
    ["7006436B"] = { s = "S", k = "inst", p = "Woe of the Willow" }, -- 5217
    ["70064364"] = { s = "S", k = "inst", p = "Woe of the Willow" }, -- 5218
    ["700006DD"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 5238
    ["70051643"] = { s = "R", k = "open", p = "Himbar, Angmar" }, -- 5246
    ["70001119"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 5274
    ["70017510"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 5276
    ["7001751E"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 5277
    ["70017519"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 5278
    ["7002C60B"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 5317
    ["70041185"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 5338
    ["70007800"] = { s = "F", k = "open", p = "Staddle, Bree-land" }, -- 5352
    ["7000887E"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 5355
    ["70017B87"] = { s = "S", k = "open", p = "The Twenty-first Hall, Moria" }, -- 5356
    ["7000E8B7"] = { s = "S", k = "open", p = "Esteldín, Evendim" }, -- 5373
    ["7003332A"] = { s = "R", k = "inst", p = "Flight to the Lonely Mountain" }, -- 5375
    ["7003332B"] = { s = "R", k = "inst", p = "Flight to the Lonely Mountain" }, -- 5376
    ["70008877"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 5391
    ["7000703C"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 5428
    ["70072F8D"] = { s = "S", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 5439
    ["70000614"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 5448
    ["700173CA"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 5459
    ["70029FBC"] = { s = "R", k = "skirm", p = "Ford of Bruinen" }, -- 5460
    ["7002CE24"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 5465
    ["70017518"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 5495
    ["7001751D"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 5496
    ["7001750F"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 5497
    ["700017AA"] = { s = "F", k = "inst", p = "Fornost" }, -- 5513
    ["7000173D"] = { s = "F", k = "inst", p = "Fornost" }, -- 5514
    ["7002D5D9"] = { s = "F", k = "inst", p = "Fornost" }, -- 5515
    ["7002D569"] = { s = "F", k = "inst", p = "Fornost: Wraith of Fire" }, -- 5516
    ["70008087"] = { s = "F", k = "inst", p = "Fornost" }, -- 5517
    ["70008074"] = { s = "F", k = "inst", p = "Fornost" }, -- 5518
    ["70008088"] = { s = "F", k = "inst", p = "Fornost" }, -- 5519
    ["7002D583"] = { s = "F", k = "inst", p = "Fornost" }, -- 5520
    ["7002D574"] = { s = "F", k = "inst", p = "Fornost" }, -- 5521
    ["7002D41F"] = { s = "F", k = "inst", p = "Fornost: Wraith of Water" }, -- 5522
    ["700080DA"] = { s = "F", k = "inst", p = "Fornost" }, -- 5523
    ["70002D55"] = { s = "F", k = "inst", p = "Fornost" }, -- 5524
    ["7002D5D1"] = { s = "F", k = "inst", p = "Fornost: Wraith of Shadow" }, -- 5525
    ["7002D462"] = { s = "F", k = "inst", p = "Fornost: Wraith of Earth" }, -- 5526
    ["70008085"] = { s = "F", k = "inst", p = "Fornost" }, -- 5527
    ["7002D42A"] = { s = "F", k = "inst", p = "Fornost" }, -- 5528
    ["700000FA"] = { s = "F", k = "inst", p = "Fornost" }, -- 5529
    ["70008058"] = { s = "F", k = "inst", p = "Fornost" }, -- 5530
    ["7002D479"] = { s = "F", k = "inst", p = "Fornost" }, -- 5531
    ["7002D48D"] = { s = "F", k = "inst", p = "Fornost" }, -- 5532
    ["7001752F"] = { s = "F", k = "inst", p = "Dark Delvings" }, -- 5556
    ["70006FB7"] = { s = "S", k = "open", p = "Thorin's Gate, Ered Luin" }, -- 5620
    ["70000193"] = { s = "F", k = "inst", p = "Urugarth" }, -- 5645
    ["70001711"] = { s = "F", k = "open", p = "Fasach-falroid, Angmar" }, -- 5665
    ["70022B30"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 5666
    ["70001206"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 5667
    ["700542E7"] = { s = "S", k = "inst", p = "Gath Daeroval, the Shadow-roost" }, -- 5684
    ["700542EA"] = { s = "S", k = "inst", p = "Gath Daeroval, the Shadow-roost" }, -- 5685
    ["700542E9"] = { s = "S", k = "inst", p = "Gath Daeroval, the Shadow-roost" }, -- 5686
    ["700542E8"] = { s = "S", k = "inst", p = "Gath Daeroval, the Shadow-roost" }, -- 5687
    ["7001BA6D"] = { s = "S", k = "open", p = "Bree, Bree-land" }, -- 5698
    ["700173BB"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 5720
    ["70022B33"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 5731
    ["70008660"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 5738
    ["7001D0D0"] = { s = "S", k = "open", p = "Gathbúrz, Mirkwood" }, -- 5742
    ["7002C60D"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 5747
    ["70055A57"] = { s = "F", k = "inst", p = "Ghashan-kútot, the Halls of Black Lore" }, -- 5762
    ["70055916"] = { s = "S", k = "inst", p = "Ghashan-kútot, the Halls of Black Lore" }, -- 5764
    ["70055919"] = { s = "S", k = "inst", p = "Ghashan-kútot, the Halls of Black Lore" }, -- 5765
    ["70055917"] = { s = "S", k = "inst", p = "Ghashan-kútot, the Halls of Black Lore" }, -- 5766
    ["70000FF0"] = { s = "F", k = "open", p = "Misty Mountains" }, -- 5774
    ["70007843"] = { s = "F", k = "open", p = "Bree, Bree-land" }, -- 5776
    ["7005307E"] = { s = "S", k = "open", p = "Vales of Anduin: Gladdenmere" }, -- 5777
    ["7004E74A"] = { s = "S", k = "inst", p = "Glimmerdeep" }, -- 5804
    ["7004E749"] = { s = "S", k = "inst", p = "Glimmerdeep" }, -- 5805
    ["7000A8D4"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 5811
    ["7004D372"] = { s = "F", k = "open", p = "Eryn Lasgalen, Strongholds of the North" }, -- 5818
    ["700088DC"] = { s = "F", k = "open", p = "Arador's End, The Ettenmoors" }, -- 5833
    ["7001ABA3"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 5853
    ["700088BB"] = { s = "R", k = "open", p = "Tírith Rhaw, The Ettenmoors" }, -- 5860
    ["7002C4DD"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 5878
    ["70053A9B"] = { s = "S", k = "inst", p = "Gorthad Nûr, the Deep-barrow" }, -- 5886
    ["70053AB2"] = { s = "S", k = "inst", p = "Gorthad Nûr, the Deep-barrow" }, -- 5887
    ["70053AAB"] = { s = "S", k = "inst", p = "Gorthad Nûr, the Deep-barrow" }, -- 5888
    ["7006E968"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 5897
    ["70022B2C"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 5930
    ["70000613"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 5931
    ["70048F7A"] = { s = "F", k = "open", p = "Lhingris" }, -- 5938
    ["700088B5"] = { s = "F", k = "open", p = "Tírith Rhaw, The Ettenmoors" }, -- 5977
    ["70022746"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 5990
    ["7006432F"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 5994
    ["70064336"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 5995
    ["70064335"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 5996
    ["70064334"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 5997
    ["70064333"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 5998
    ["7006463B"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 6000
    ["7006461F"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 6001
    ["7006463C"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 6002
    ["70019211"] = { s = "S", k = "inst", p = "The Mirror-halls of Lumul-nar" }, -- 6022
    ["70019612"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 6026
    ["700195A5"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 6027
    ["70019613"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 6028
    ["70019614"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 6029
    ["70019615"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 6030
    ["700442D6"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 6038
    ["70072F8F"] = { s = "S", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 6079
    ["70041174"] = { s = "F", k = "open", p = "Western Gondor: Tarlang's Crown" }, -- 6096
    ["70007678"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 6107
    ["70000195"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 6117
    ["7000885C"] = { s = "F", k = "open", p = "Hithlad, The Ettenmoors" }, -- 6123
    ["70029FD4"] = { s = "R", k = "inst", p = "Helegrod" }, -- 6127
    ["70029FD7"] = { s = "R", k = "inst", p = "Helegrod" }, -- 6128
    ["70029FD6"] = { s = "R", k = "inst", p = "Helegrod" }, -- 6129
    ["70029FD5"] = { s = "R", k = "inst", p = "Helegrod" }, -- 6130
    ["70037DD3"] = { s = "F", k = "epic", p = "Defence of Rohan" }, -- 6136
    ["700011CA"] = { s = "S", k = "open", p = "Himbar, Angmar" }, -- 6146
    ["70058BB8"] = { s = "S", k = "open", p = "Elderslade: War of Three Peaks" }, -- 6163
    ["7001757A"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 6232
    ["7000222E"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 6240
    ["7001752B"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 6276
    ["70050212"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 6277
    ["7000AC52"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 6322
    ["7005AB00"] = { s = "S", k = "open", p = "Welkin-lofts, Gundabad" }, -- 6373
    ["70043E02"] = { s = "F", k = "inst", p = "Osgiliath: Court of Isildur" }, -- 6414
    ["70030A72"] = { s = "S", k = "open", p = "Norcrofts, Croftlands" }, -- 6422
    ["7002C5D3"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 6423
    ["70050A0A"] = { s = "F", k = "open", p = "The Withered Heath, The Dwarf-holds" }, -- 6427
    ["70017D87"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 6457
    ["70017D8A"] = { s = "F", k = "skirm", p = "Battle of the Twenty-first Hall" }, -- 6459
    ["70017D8B"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 6461
    ["70041179"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 6536
    ["7000A8D5"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 6561
    ["7001759B"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 6569
    ["7004117E"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 6589
    ["70024530"] = { s = "S", k = "open", p = "Bree, Evendim" }, -- 6594
    ["700246F2"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 6595
    ["700246F3"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 6596
    ["700246F4"] = { s = "F", k = "inst", p = "Sâri-surma" }, -- 6597
    ["700246F5"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 6598
    ["70024717"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 6599
    ["70024718"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 6600
    ["70024551"] = { s = "S", k = "open", p = "Northcotton Farm, The Shire" }, -- 6602
    ["7002468E"] = { s = "S", k = "open", p = "Stoneheight, Bree-land" }, -- 6603
    ["70024691"] = { s = "S", k = "open", p = "Stoneheight, The North Downs" }, -- 6604
    ["70024693"] = { s = "S", k = "open", p = "Stoneheight, The North Downs" }, -- 6605
    ["70024699"] = { s = "F", k = "open", p = "Stoneheight, The Trollshaws" }, -- 6606
    ["7002469A"] = { s = "F", k = "inst", p = "Lost Temple" }, -- 6607
    ["7002469B"] = { s = "F", k = "inst", p = "Lost Temple" }, -- 6608
    ["70009E5A"] = { s = "S", k = "open", p = "Arador's End, The Ettenmoors" }, -- 6610
    ["70017528"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 6635
    ["70017532"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 6637
    ["700268BF"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 6672
    ["7002685D"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 6673
    ["70026862"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 6674
    ["7002684B"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 6675
    ["70015AD5"] = { s = "S", k = "pe", p = "A Flight of Drakes" }, -- 6714
    ["70000DF5"] = { s = "S", k = "pe", p = "A Gift for the North" }, -- 6718
    ["7000D7A3"] = { s = "F", k = "pe", p = "The Ancient Lair" }, -- 6799
    ["700253DC"] = { s = "F", k = "pe", p = "Attack on Zudrugund" }, -- 6810
    ["7000D5B3"] = { s = "F", k = "pe", p = "Barad Tironn" }, -- 6816
    ["7001ECCE"] = { s = "R", k = "pe", p = "Challenge at the Gate" }, -- 6846
    ["700253DD"] = { s = "F", k = "pe", p = "The Forsaken Road" }, -- 6873
    ["7000D6F9"] = { s = "F", k = "pe", p = "Minas Maur" }, -- 6874
    ["7000D6F8"] = { s = "F", k = "pe", p = "Minas Angos" }, -- 6875
    ["7000D6FA"] = { s = "F", k = "pe", p = "Minas Agar" }, -- 6876
    ["7000D6FB"] = { s = "F", k = "pe", p = "Minas Caul" }, -- 6877
    ["70000FD4"] = { s = "F", k = "pe", p = "Helegrod Treasury" }, -- 6907
    ["70041184"] = { s = "F", k = "pe", p = "First of the Heirs" }, -- 6909
    ["70017B88"] = { s = "S", k = "pe", p = "Chamber of Dancing Shadows" }, -- 6911
    ["700698D5"] = { s = "S", k = "inst", p = "The Isle of Storms" }, -- 6984
    ["7006A1D3"] = { s = "S", k = "inst", p = "The Isle of Storms" }, -- 6985
    ["7006A1D4"] = { s = "S", k = "inst", p = "The Isle of Storms" }, -- 6986
    ["7006A1D5"] = { s = "S", k = "inst", p = "The Isle of Storms" }, -- 6987
    ["7006A1D6"] = { s = "S", k = "inst", p = "The Isle of Storms" }, -- 6988
    ["7000D5B9"] = { s = "F", k = "pe", p = "Sammath Baul" }, -- 6995
    ["70015E43"] = { s = "S", k = "pe", p = "Tawarond" }, -- 6999
    ["700253DB"] = { s = "F", k = "pe", p = "Lhaid Ogo" }, -- 7002
    ["700159DC"] = { s = "S", k = "pe", p = "Midnight Raid" }, -- 7022
    ["7000B04E"] = { s = "S", k = "pe", p = "Castle of the Witch-king" }, -- 7029
    ["700147F0"] = { s = "F", k = "pe", p = "Azanarukâr" }, -- 7042
    ["7000069D"] = { s = "F", k = "pe", p = "Red-pass" }, -- 7077
    ["7001AC1B"] = { s = "S", k = "pe", p = "Azanarukâr" }, -- 7085
    ["70014670"] = { s = "F", k = "pe", p = "The Deep Way" }, -- 7159
    ["70014672"] = { s = "F", k = "pe", p = "The Battle of the Twenty-first Hall" }, -- 7162
    ["70014671"] = { s = "F", k = "pe", p = "The Heart of Fire" }, -- 7163
    ["7000A8AA"] = { s = "S", k = "pe", p = "Barad Tironn" }, -- 7208
    ["700011AA"] = { s = "F", k = "pe", p = "The Gates of Carn Dûm" }, -- 7228
    ["70017B89"] = { s = "S", k = "pe", p = "Mamalsul" }, -- 7254
    ["7000114F"] = { s = "F", k = "pe", p = "The Last Refuge" }, -- 7263
    ["700256E0"] = { s = "F", k = "open", p = "Bree-land" }, -- 7275
    ["7000E374"] = { s = "F", k = "pe", p = "Halla-kolo" }, -- 7297
    ["7002CDBE"] = { s = "F", k = "inst", p = "Roots of Fangorn" }, -- 7327
    ["7001627B"] = { s = "S", k = "pe", p = "The Siege of Barad Morlas" }, -- 7340
    ["700097E6"] = { s = "F", k = "pe", p = "Elendil's Tomb" }, -- 7364
    ["700010FA"] = { s = "F", k = "pe", p = "The Unmarked Trail" }, -- 7372
    ["7000D5BA"] = { s = "F", k = "pe", p = "Barad Dúrgul" }, -- 7441
    ["7000D4EA"] = { s = "S", k = "open", p = "Himbar, Angmar" }, -- 7496
    ["70061383"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 7508
    ["70061391"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 7509
    ["70061396"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 7510
    ["70061397"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 7511
    ["70061398"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 7512
    ["7006A1DD"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 7522
    ["7006A1DB"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 7523
    ["7006A1DC"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 7524
    ["7006A1DA"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 7525
    ["7006A1D9"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 7526
    ["7002BD4E"] = { s = "S", k = "open", p = "Isengard, Dunland" }, -- 7527
    ["70032E40"] = { s = "S", k = "inst", p = "Iorbar's Peak" }, -- 7666
    ["70032E3E"] = { s = "S", k = "inst", p = "Iorbar's Peak" }, -- 7667
    ["70032E3F"] = { s = "S", k = "inst", p = "Iorbar's Peak" }, -- 7668
    ["7000075C"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 7693
    ["7004D371"] = { s = "F", k = "open", p = "The Dale-lands, Strongholds of the North" }, -- 7722
    ["7000D4EC"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 7726
    ["7000A8D6"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 7727
    ["70015E21"] = { s = "S", k = "open", p = "Glâd Ereg, Eregion" }, -- 7734
    ["7002C5AF"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 7737
    ["70017522"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 7753
    ["7000E8B9"] = { s = "S", k = "open", p = "Esteldín, The Misty Mountains" }, -- 7758
    ["70050A0B"] = { s = "F", k = "open", p = "The Withered Heath, The Dwarf-holds" }, -- 7813
    ["70047B43"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7835
    ["70047B42"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7836
    ["70047B47"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7837
    ["70047B3F"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7838
    ["70047B45"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7839
    ["70047B44"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7840
    ["70047B46"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7841
    ["70047B41"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7842
    ["70047B40"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 7843
    ["7000D4E6"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 7856
    ["70015E22"] = { s = "S", k = "open", p = "Glâd Ereg, Eregion" }, -- 7861
    ["70008757"] = { s = "F", k = "open", p = "Steps of Gram, The Ettenmoors" }, -- 7863
    ["70017523"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 7869
    ["700516A3"] = { s = "F", k = "inst", p = "Annúminas: Glinghant" }, -- 7889
    ["7005169E"] = { s = "F", k = "inst", p = "Annúminas: Haudh Valandil" }, -- 7890
    ["7005169D"] = { s = "F", k = "inst", p = "Annúminas: Ost Elendil" }, -- 7891
    ["70051687"] = { s = "F", k = "inst", p = "Barad Gúlaran" }, -- 7892
    ["70051689"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 7893
    ["700516E0"] = { s = "R", k = "open", p = "Himbar, Angmar" }, -- 7894
    ["700516DF"] = { s = "R", k = "open", p = "Angmar" }, -- 7895
    ["700516D6"] = { s = "F", k = "open", p = "Angmar" }, -- 7896
    ["700516A5"] = { s = "F", k = "inst", p = "Fornost: Wraith of Earth" }, -- 7897
    ["70051699"] = { s = "F", k = "inst", p = "Fornost: Wraith of Fire" }, -- 7898
    ["700516A2"] = { s = "F", k = "inst", p = "Fornost: Wraith of Shadow" }, -- 7899
    ["7005169C"] = { s = "F", k = "inst", p = "Fornost: Wraith of Water" }, -- 7900
    ["700516A4"] = { s = "F", k = "inst", p = "Great Barrow: Sambrog" }, -- 7901
    ["700516A0"] = { s = "F", k = "inst", p = "Great Barrow: Thadúr" }, -- 7902
    ["7005169A"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 7903
    ["70051686"] = { s = "S", k = "open", p = "Angmar" }, -- 7904
    ["700516A1"] = { s = "R", k = "inst", p = "Helegrod: Dragon Wing" }, -- 7905
    ["70051698"] = { s = "R", k = "inst", p = "Helegrod: Drake Wing" }, -- 7906
    ["7005169F"] = { s = "R", k = "inst", p = "Helegrod: Giant Wing" }, -- 7907
    ["7005169B"] = { s = "R", k = "inst", p = "Helegrod: Spider Wing" }, -- 7908
    ["70051685"] = { s = "S", k = "inst", p = "Inn of the Forsaken" }, -- 7909
    ["700516D5"] = { s = "R", k = "open", p = "Angmar" }, -- 7910
    ["7005168A"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 7911
    ["70051688"] = { s = "F", k = "inst", p = "Urugarth" }, -- 7912
    ["70053417"] = { s = "S", k = "inst", p = "Dargnákh Unleashed" }, -- 7913
    ["70053410"] = { s = "R", k = "inst", p = "Draigoch's Lair" }, -- 7914
    ["70053413"] = { s = "S", k = "inst", p = "Fangorn's Edge" }, -- 7915
    ["7005340C"] = { s = "S", k = "inst", p = "Pits of Isengard" }, -- 7916
    ["7005340D"] = { s = "R", k = "open", p = "Legendary Isengard" }, -- 7917
    ["70053419"] = { s = "F", k = "inst", p = "Roots of Fangorn" }, -- 7918
    ["70053414"] = { s = "F", k = "open", p = "Legendary Isengard" }, -- 7920
    ["70053416"] = { s = "R", k = "inst", p = "The Tower of Orthanc" }, -- 7921
    ["700533B6"] = { s = "R", k = "inst", p = "Barad Guldur" }, -- 7922
    ["70053418"] = { s = "R", k = "open", p = "Nan Laeglin, Enedwaith" }, -- 7923
    ["70053412"] = { s = "R", k = "open", p = "Legendary Mirkwood" }, -- 7924
    ["700533DB"] = { s = "R", k = "inst", p = "Dungeons of Dol Guldur" }, -- 7925
    ["700533CC"] = { s = "R", k = "open", p = "Legendary Mirkwood" }, -- 7926
    ["700533CB"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 7927
    ["700533CD"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 7928
    ["700533D2"] = { s = "R", k = "inst", p = "Ost Dunhoth" }, -- 7929
    ["700533DF"] = { s = "R", k = "inst", p = "Sammath Gûl" }, -- 7930
    ["700533D4"] = { s = "R", k = "skirm", p = "Assault on the Ringwraiths' Lair" }, -- 7931
    ["700533CE"] = { s = "R", k = "skirm", p = "Breaching the Necromancer's Gate" }, -- 7932
    ["700533D7"] = { s = "R", k = "skirm", p = "Protectors of Thangúlhad" }, -- 7933
    ["700533D9"] = { s = "R", k = "skirm", p = "Strike Against Dannenglor" }, -- 7934
    ["700533DA"] = { s = "R", k = "skirm", p = "The Battle in the Tower" }, -- 7935
    ["700533E2"] = { s = "R", k = "open", p = "Legendary Mirkwood" }, -- 7936
    ["700533E4"] = { s = "R", k = "inst", p = "Sword-hall of Dol Guldur" }, -- 7937
    ["700533D5"] = { s = "R", k = "inst", p = "Sâri-surma" }, -- 7938
    ["700533E1"] = { s = "R", k = "inst", p = "The Northcotton Farm" }, -- 7939
    ["700533D1"] = { s = "R", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 7940
    ["70052602"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 7941
    ["700525FC"] = { s = "R", k = "inst", p = "Dâr Narbugud" }, -- 7942
    ["70052606"] = { s = "S", k = "inst", p = "Library at Tham Mírdain" }, -- 7943
    ["70052605"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 7944
    ["70052600"] = { s = "F", k = "inst", p = "Fil Gashan" }, -- 7945
    ["70052604"] = { s = "R", k = "inst", p = "Filikul" }, -- 7946
    ["70052609"] = { s = "F", k = "inst", p = "Halls of Crafting" }, -- 7947
    ["700525FB"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 7951
    ["70052608"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 7952
    ["700525FE"] = { s = "F", k = "inst", p = "The Forgotten Treasury" }, -- 7953
    ["70052601"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 7954
    ["7005260D"] = { s = "S", k = "inst", p = "The Mirror-halls of Lumul-nar" }, -- 7955
    ["700525FA"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 7956
    ["7005260A"] = { s = "R", k = "inst", p = "The Vile Maw" }, -- 7957
    ["7005260F"] = { s = "S", k = "inst", p = "The Water Wheels: Nalâ-dûm" }, -- 7958
    ["70052643"] = { s = "R", k = "open", p = "The Twenty-first Hall, Moria" }, -- 7959
    ["70052641"] = { s = "R", k = "open", p = "Legendary Moria" }, -- 7960
    ["70019034"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 7961
    ["7001ABA1"] = { s = "S", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 7968
    ["7000874E"] = { s = "F", k = "open", p = "Steps of Gram, The Ettenmoors" }, -- 8044
    ["700001AB"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 8054
    ["70017599"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 8056
    ["7002248A"] = { s = "F", k = "inst", p = "Annúminas" }, -- 8073
    ["70047DB5"] = { s = "F", k = "open", p = "The Wastes: The Slag-hills" }, -- 8104
    ["70047DBC"] = { s = "F", k = "open", p = "The Wastes: The Slag-hills" }, -- 8105
    ["700490FF"] = { s = "F", k = "open", p = "The Wastes: The Slag-hills" }, -- 8106
    ["70049100"] = { s = "F", k = "open", p = "The Wastes: The Slag-hills" }, -- 8107
    ["7005CE67"] = { s = "F", k = "inst", p = "Adkhât-zahhar, the Houses of Rest" }, -- 8112
    ["700006C0"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 8120
    ["700001B0"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 8148
    ["7001900B"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 8246
    ["700196B5"] = { s = "S", k = "inst", p = "Moria" }, -- 8267
    ["700196B3"] = { s = "S", k = "inst", p = "Moria" }, -- 8268
    ["700196B4"] = { s = "S", k = "inst", p = "Moria" }, -- 8269
    ["70050215"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 8287
    ["70028B7E"] = { s = "R", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 8325
    ["700509C4"] = { s = "F", k = "inst", p = "Glimmerdeep" }, -- 8360
    ["7000A16B"] = { s = "F", k = "inst", p = "Barad Gúlaran" }, -- 8363
    ["700173C5"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 8364
    ["7000239A"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 8365
    ["7000173E"] = { s = "F", k = "open", p = "Dol Dínen, The North Downs" }, -- 8366
    ["70017530"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 8367
    ["700082D1"] = { s = "F", k = "open", p = "North Downs" }, -- 8375
    ["7006218A"] = { s = "F", k = "open", p = "Ettenmoors" }, -- 8406
    ["7006460F"] = { s = "F", k = "open", p = "Ettenmoors" }, -- 8407
    ["700173C0"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 8417
    ["7004117A"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 8426
    ["700159DD"] = { s = "S", k = "open", p = "Nan Sirannon, Eregion" }, -- 8537
    ["70002CCF"] = { s = "S", k = "open", p = "Ram Dúath, Angmar" }, -- 9094
    ["7003720F"] = { s = "R", k = "open", p = "Broadacres, Eastfold" }, -- 9115
    ["70002DF1"] = { s = "F", k = "open", p = "Giant Valley, The Trollshaws" }, -- 9152
    ["700001AF"] = { s = "F", k = "inst", p = "Urugarth" }, -- 9164
    ["7004117D"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 9168
    ["7000839B"] = { s = "F", k = "open", p = "Fasach-falroid, Angmar" }, -- 9174
    ["7000BFC6"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 9182
    ["700173D0"] = { s = "S", k = "inst", p = "School at Tham Mírdain" }, -- 9184
    ["7000135C"] = { s = "S", k = "open", p = "Imlad Balchorth, Angmar" }, -- 9210
    ["7001925D"] = { s = "S", k = "inst", p = "Moria" }, -- 9238
    ["7001925E"] = { s = "S", k = "inst", p = "Moria" }, -- 9239
    ["7001925C"] = { s = "S", k = "inst", p = "Moria" }, -- 9240
    ["70055926"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 9241
    ["7000A8FA"] = { s = "F", k = "inst", p = "Annúminas" }, -- 9280
    ["70017612"] = { s = "F", k = "open", p = "The Twenty-first Hall, Moria" }, -- 9295
    ["70058BBB"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 9311
    ["700256CD"] = { s = "S", k = "inst", p = "The Northcotton Farm" }, -- 9335
    ["70048F7F"] = { s = "F", k = "open", p = "Dor Amarth, Mordor" }, -- 9362
    ["70037BF0"] = { s = "S", k = "open", p = "Stonedeans, Westfold" }, -- 9363
    ["70022729"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 9364
    ["7001C69E"] = { s = "S", k = "open", p = "Esteldín, The North Downs" }, -- 9366
    ["7001C69F"] = { s = "S", k = "open", p = "Esteldín, The North Downs" }, -- 9370
    ["70007CC3"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9374
    ["700173BC"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 9397
    ["70000DAD"] = { s = "F", k = "open", p = "Green Hill Country, The Shire" }, -- 9423
    ["700447FA"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 9435
    ["7001AB9E"] = { s = "S", k = "inst", p = "Sword-hall of Dol Guldur" }, -- 9458
    ["7001CD5B"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9482
    ["7001D01A"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9483
    ["7001E5E4"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 9484
    ["7001CD59"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9485
    ["7001E5E5"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 9486
    ["7001D01B"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9487
    ["7001D01C"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9489
    ["7001CD5C"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9490
    ["7001D01D"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 9491
    ["7001E5E6"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 9492
    ["7000173F"] = { s = "F", k = "open", p = "Dol Dínen, Bree-land" }, -- 9515
    ["70009E74"] = { s = "F", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 9552
    ["7004799D"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 9579
    ["70008B8C"] = { s = "R", k = "inst", p = "Helegrod" }, -- 9659
    ["700223AB"] = { s = "S", k = "open", p = "Mirobel, Eregion" }, -- 9667
    ["7000AE1A"] = { s = "S", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 9668
    ["70017535"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 9681
    ["70015E2E"] = { s = "S", k = "open", p = "Glâd Ereg, Eregion" }, -- 9686
    ["7000E8B5"] = { s = "S", k = "open", p = "Bree, The North Downs" }, -- 9706
    ["7002CB80"] = { s = "F", k = "open", p = "Limlight Gorge, Great River" }, -- 9715
    ["7002CB7E"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 9716
    ["7002CB7C"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 9717
    ["7000D4E8"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 9741
    ["7001BA79"] = { s = "S", k = "open", p = "Bree, Bree-land" }, -- 9790
    ["7004117B"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 9801
    ["70000D4B"] = { s = "F", k = "open", p = "Greenfields, The Shire" }, -- 9860
    ["7002BD4D"] = { s = "S", k = "open", p = "Rise of Isengard" }, -- 9884
    ["70029FC1"] = { s = "R", k = "skirm", p = "Protectors of Thangúlhad" }, -- 9899
    ["70041172"] = { s = "F", k = "open", p = "Western Gondor: Tarlang's Crown" }, -- 9926
    ["700007B6"] = { s = "F", k = "inst", p = "Great Barrow" }, -- 9930
    ["700173A8"] = { s = "S", k = "open", p = "Mirobel, Eregion" }, -- 9931
    ["7000135E"] = { s = "F", k = "open", p = "Imlad Balchorth, Angmar" }, -- 9934
    ["70054666"] = { s = "S", k = "open", p = "Cirith Ungol, Imlad Morgul" }, -- 9958
    ["700001A3"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 9959
    ["70002E24"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 9960
    ["700001B7"] = { s = "F", k = "inst", p = "Urugarth" }, -- 9970
    ["70008B84"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10017
    ["70008B83"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10018
    ["700228B4"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10019
    ["70000197"] = { s = "R", k = "open", p = "Himbar, Angmar" }, -- 10020
    ["700087E9"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 10021
    ["700087E5"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 10022
    ["700087A6"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 10023
    ["700087E7"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 10025
    ["700087E6"] = { s = "R", k = "open", p = "Gramsfoot, The Ettenmoors" }, -- 10026
    ["70008857"] = { s = "R", k = "open", p = "Hithlad, The Ettenmoors" }, -- 10027
    ["70022577"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10028
    ["70008B8A"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10029
    ["700228B5"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10030
    ["70008B7F"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10031
    ["7000889F"] = { s = "R", k = "open", p = "Arador's End, The Ettenmoors" }, -- 10032
    ["70064483"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 10033
    ["70008B8B"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10034
    ["70008B8D"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10035
    ["70008B91"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10036
    ["700228C5"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10037
    ["70008B81"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10038
    ["70008B8F"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10039
    ["700608FF"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 10040
    ["70008B90"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10041
    ["7000135D"] = { s = "R", k = "open", p = "Imlad Balchorth, Angmar" }, -- 10042
    ["70043BDB"] = { s = "R", k = "open", p = "Pelargir, Lebennin" }, -- 10043
    ["70043BDC"] = { s = "R", k = "pe", p = "Dead Cave" }, -- 10044
    ["70008B89"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10045
    ["700088C5"] = { s = "R", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 10046
    ["700088C7"] = { s = "R", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 10048
    ["700088CA"] = { s = "R", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 10049
    ["700088C6"] = { s = "R", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 10050
    ["700088C8"] = { s = "R", k = "open", p = "Glân Vraig, The Ettenmoors" }, -- 10051
    ["70008B85"] = { s = "R", k = "inst", p = "Helegrod" }, -- 10052
    ["7005A9A0"] = { s = "S", k = "open", p = "Máttugard, Gundabad" }, -- 10054
    ["700442CC"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 10062
    ["7000C38C"] = { s = "S", k = "open", p = "Northern High Pass, The Misty Mountains" }, -- 10068
    ["700082EC"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 10134
    ["7000889D"] = { s = "F", k = "open", p = "Arador's End, The Ettenmoors" }, -- 10152
    ["70000623"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 10164
    ["700173D2"] = { s = "F", k = "open", p = "Silvertine Lodes, Moria" }, -- 10226
    ["7003E2AF"] = { s = "S", k = "open", p = "Nan Wathren, The North Downs" }, -- 10232
    ["70000CA8"] = { s = "S", k = "inst", p = "Garth Agarwen" }, -- 10234
    ["70022728"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 10236
    ["70057388"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 10244
    ["70057389"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 10245
    ["7005738A"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 10246
    ["700579A5"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 10247
    ["700579A6"] = { s = "R", k = "inst", p = "Remmorchant, the Net of Darkness" }, -- 10248
    ["700173B2"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 10254
    ["7001A63D"] = { s = "S", k = "open", p = "The Drownholt, Mirkwood" }, -- 10258
    ["70029FC7"] = { s = "R", k = "skirm", p = "Rescue in Nûrz Ghâshu" }, -- 10293
    ["7000E8BA"] = { s = "F", k = "open", p = "Bree, The Lone-lands" }, -- 10342
    ["700006BF"] = { s = "S", k = "open", p = "Agamaur, The Lone-lands" }, -- 10384
    ["70017525"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 10387
    ["700006E9"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 10425
    ["7000AE1B"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 10453
    ["70072F8B"] = { s = "S", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 10471
    ["70048F83"] = { s = "F", k = "open", p = "Talath Úrui, Mordor" }, -- 10474
    ["70041C81"] = { s = "F", k = "open", p = "Lower Lebennin, Lebennin" }, -- 10496
    ["70072B84"] = { s = "F", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 10497
    ["7004288E"] = { s = "F", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 10498
    ["70041C6E"] = { s = "S", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 10499
    ["7004288D"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 10500
    ["700715A5"] = { s = "F", k = "open", p = "The Gated Vale of Zajâna, Kighân, the Shornvale" }, -- 10501
    ["700473A0"] = { s = "F", k = "open", p = "The Noman-lands, The Wastes" }, -- 10502
    ["70043C25"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 10503
    ["70041AF2"] = { s = "F", k = "open", p = "Ringló Vale" }, -- 10504
    ["70043C21"] = { s = "S", k = "open", p = "Esteldín, The North Downs" }, -- 10505
    ["700473A4"] = { s = "F", k = "open", p = "Lang Rhuven, The Wastes" }, -- 10506
    ["700473A5"] = { s = "F", k = "open", p = "The Noman-lands, The Wastes" }, -- 10507
    ["70043C26"] = { s = "F", k = "open", p = "Emyn Lûm, Mirkwood" }, -- 10508
    ["70042889"] = { s = "F", k = "open", p = "Jä-rannit, Forochel" }, -- 10509
    ["70042892"] = { s = "F", k = "open", p = "Bruinen Source West, The Misty Mountains" }, -- 10510
    ["70041AF0"] = { s = "S", k = "open", p = "Ringló Vale" }, -- 10511
    ["70042898"] = { s = "F", k = "open", p = "Dol Amroth, Western Gondor" }, -- 10512
    ["7004288B"] = { s = "S", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 10513
    ["70043C24"] = { s = "S", k = "open", p = "Emyn Lûm, Mirkwood" }, -- 10514
    ["7004288F"] = { s = "S", k = "open", p = "Bruinen Source West, The Misty Mountains" }, -- 10515
    ["70041C70"] = { s = "S", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 10516
    ["70042F74"] = { s = "R", k = "open", p = "South Ithilien, Eastern Gondor" }, -- 10517
    ["7004288C"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 10518
    ["70042893"] = { s = "S", k = "open", p = "Bruinen Source West, The Misty Mountains" }, -- 10519
    ["70042897"] = { s = "S", k = "open", p = "Jä-rannit, Forochel" }, -- 10520
    ["70041C7E"] = { s = "S", k = "open", p = "Lower Lebennin, Lebennin" }, -- 10521
    ["700473A6"] = { s = "F", k = "open", p = "The Noman-lands, The Wastes" }, -- 10522
    ["70042F72"] = { s = "S", k = "open", p = "South Ithilien, Eastern Gondor" }, -- 10523
    ["70042891"] = { s = "F", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 10524
    ["70042884"] = { s = "S", k = "open", p = "Jä-rannit, Forochel" }, -- 10525
    ["70041C7F"] = { s = "F", k = "open", p = "Lower Lebennin, Lebennin" }, -- 10526
    ["70041C6C"] = { s = "F", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 10527
    ["70043C2A"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 10528
    ["70041AF1"] = { s = "S", k = "open", p = "Ringló Vale" }, -- 10529
    ["70042888"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 10530
    ["70042F73"] = { s = "F", k = "open", p = "South Ithilien, Eastern Gondor" }, -- 10531
    ["70042883"] = { s = "S", k = "open", p = "Dol Amroth, Western Gondor" }, -- 10532
    ["70043C22"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 10533
    ["70042887"] = { s = "F", k = "open", p = "Bruinen Source West, The Misty Mountains" }, -- 10534
    ["70043C29"] = { s = "S", k = "open", p = "Emyn Lûm, Mirkwood" }, -- 10535
    ["700473A9"] = { s = "F", k = "open", p = "The Noman-lands, The Wastes" }, -- 10536
    ["70043C28"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 10537
    ["70042896"] = { s = "F", k = "open", p = "Jä-rannit, Forochel" }, -- 10538
    ["7004289A"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 10539
    ["70043C23"] = { s = "S", k = "open", p = "Esteldín, The North Downs" }, -- 10540
    ["70042886"] = { s = "F", k = "open", p = "Aughaire, Angmar" }, -- 10541
    ["70043C27"] = { s = "F", k = "open", p = "Emyn Lûm, Mirkwood" }, -- 10542
    ["70017582"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 10591
    ["70022B49"] = { s = "F", k = "inst", p = "Great Barrow: Sambrog" }, -- 10617
    ["70008B80"] = { s = "R", k = "open", p = "Rivendell Valley, The Trollshaws" }, -- 10651
    ["700011F7"] = { s = "S", k = "open", p = "Eastern Malenhad, Angmar" }, -- 10661
    ["700523DD"] = { s = "F", k = "open", p = "Frostbluff, Festival Grounds" }, -- 10768
    ["7005A45E"] = { s = "F", k = "open", p = "The Horsefields, Bree-land" }, -- 10769
    ["700537D6"] = { s = "F", k = "open", p = "The Hill, The Shire" }, -- 10770
    ["70033548"] = { s = "S", k = "inst", p = "Seat of the Great Goblin" }, -- 10772
    ["70033549"] = { s = "S", k = "inst", p = "Seat of the Great Goblin" }, -- 10773
    ["7001758E"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 10777
    ["700381C1"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 10789
    ["70015E2F"] = { s = "S", k = "open", p = "Glâd Ereg, Eregion" }, -- 10797
    ["70041181"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 10817
    ["70019031"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 10828
    ["70019032"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 10829
    ["70019033"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 10830
    ["70008750"] = { s = "F", k = "open", p = "Steps of Gram, The Ettenmoors" }, -- 10835
    ["70017584"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 10853
    ["7000A16C"] = { s = "F", k = "inst", p = "Barad Gúlaran" }, -- 10921
    ["700033CD"] = { s = "F", k = "open", p = "Greenfields, The Shire" }, -- 10923
    ["700381C6"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 10924
    ["700509C0"] = { s = "F", k = "inst", p = "Glimmerdeep" }, -- 10960
    ["700381BF"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 10968
    ["70029FBD"] = { s = "R", k = "skirm", p = "Siege of Gondamon" }, -- 10974
    ["7003A490"] = { s = "S", k = "open", p = "Stonedeans, Westfold" }, -- 10976
    ["700082D4"] = { s = "F", k = "open", p = "Dol Dínen, The North Downs" }, -- 10977
    ["700082D3"] = { s = "F", k = "open", p = "Dol Dínen, The North Downs" }, -- 10978
    ["7001751B"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 11023
    ["70017520"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 11024
    ["70017513"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 11025
    ["700001B5"] = { s = "F", k = "inst", p = "Urugarth" }, -- 11028
    ["7001CD79"] = { s = "R", k = "skirm", p = "" }, -- 11048
    ["70047457"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 11066
    ["7004745C"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 11067
    ["70047459"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 11069
    ["700173B8"] = { s = "F", k = "open", p = "Silvertine Lodes, Moria" }, -- 11073
    ["70017514"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 11074
    ["70017515"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 11075
    ["70017521"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 11076
    ["70017517"] = { s = "F", k = "inst", p = "Skûmfil" }, -- 11077
    ["7005AF83"] = { s = "S", k = "open", p = "Pit of Stonejaws, Gundabad" }, -- 11091
    ["7004799C"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 11154
    ["7000A16D"] = { s = "F", k = "inst", p = "Barad Gúlaran" }, -- 11157
    ["7003EAFE"] = { s = "F", k = "open", p = "Trollshaws" }, -- 11176
    ["70032F04"] = { s = "F", k = "open", p = "The Scuttledells, Mirkwood" }, -- 11197
    ["700333E8"] = { s = "F", k = "open", p = "The Scuttledells, Mirkwood" }, -- 11198
    ["700085D9"] = { s = "S", k = "open", p = "Imlad Balchorth, Angmar" }, -- 11215
    ["70048F80"] = { s = "F", k = "open", p = "Talath Úrui, Mordor" }, -- 11219
    ["700173C9"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 11261
    ["7000D4F1"] = { s = "S", k = "open", p = "Himbar, Angmar" }, -- 11264
    ["70029FC3"] = { s = "R", k = "skirm", p = "Stand at Amon Sûl" }, -- 11266
    ["70041175"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 11276
    ["700173C3"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 11295
    ["70041180"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 11296
    ["70002CD1"] = { s = "S", k = "open", p = "Ram Dúath, Angmar" }, -- 11318
    ["70017531"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 11324
    ["7002B212"] = { s = "R", k = "skirm", p = "Storm on Methedras" }, -- 11356
    ["70043DF5"] = { s = "S", k = "inst", p = "Osgiliath: Court of Anárion" }, -- 11358
    ["70051F7C"] = { s = "F", k = "open", p = "Frostbluff" }, -- 11361
    ["70051F7E"] = { s = "F", k = "open", p = "The Misty Mountains" }, -- 11362
    ["7003707C"] = { s = "S", k = "open", p = "Stonedeans, Westfold" }, -- 11378
    ["7001AB98"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 11381
    ["7001ABA2"] = { s = "S", k = "inst", p = "Warg-pens of Dol Guldur" }, -- 11385
    ["7000AE1E"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 11394
    ["70029FC2"] = { s = "R", k = "skirm", p = "Strike Against Dannenglor" }, -- 11402
    ["7000AC58"] = { s = "F", k = "open", p = "Tol Ascarnen, The Ettenmoors" }, -- 11411
    ["7004338A"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 11441
    ["70043390"] = { s = "S", k = "inst", p = "Sunken Labyrinth" }, -- 11442
    ["7000A8B5"] = { s = "S", k = "open", p = "Annúminas, Evendim" }, -- 11450
    ["7000A8B6"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 11451
    ["7000A8B7"] = { s = "S", k = "open", p = "Annúminas, Evendim" }, -- 11452
    ["70008362"] = { s = "S", k = "open", p = "Western Malenhad, Angmar" }, -- 11498
    ["7003E2AC"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 11567
    ["7004103C"] = { s = "F", k = "open", p = "Dol Amroth, Western Gondor" }, -- 11568
    ["7004103B"] = { s = "F", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 11569
    ["70041032"] = { s = "F", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 11570
    ["7004103D"] = { s = "F", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 11571
    ["7001ABA0"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 11583
    ["7001F4B0"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 11591
    ["7006E117"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 11592
    ["7006E119"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 11593
    ["7006E118"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 11594
    ["7006DD43"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11595
    ["7006DD47"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11596
    ["7006DD48"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11597
    ["7006E01A"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11598
    ["7006E01B"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11599
    ["7006E01C"] = { s = "R", k = "open", p = "Ikorbân Valley" }, -- 11600
    ["7006AACA"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 11614
    ["7000A209"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 11616
    ["70022B31"] = { s = "F", k = "inst", p = "Great Barrow: Thadúr" }, -- 11626
    ["7004E7EA"] = { s = "R", k = "inst", p = "The Anvil of Winterstith" }, -- 11695
    ["70050227"] = { s = "R", k = "inst", p = "The Anvil of Winterstith" }, -- 11696
    ["70051879"] = { s = "R", k = "inst", p = "The Anvil of Winterstith" }, -- 11697
    ["70051878"] = { s = "R", k = "inst", p = "The Anvil of Winterstith" }, -- 11698
    ["70051877"] = { s = "R", k = "inst", p = "The Anvil of Winterstith" }, -- 11699
    ["7000256B"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 11703
    ["700544D7"] = { s = "S", k = "open", p = "Parth Daenath, Mordor Besieged" }, -- 11724
    ["70010167"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 11732
    ["70010166"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 11736
    ["70033CA2"] = { s = "R", k = "inst", p = "The Battle for Erebor" }, -- 11738
    ["70033CA3"] = { s = "R", k = "inst", p = "The Battle for Erebor" }, -- 11739
    ["70033CA4"] = { s = "R", k = "inst", p = "The Battle for Erebor" }, -- 11740
    ["70029FC6"] = { s = "R", k = "skirm", p = "The Battle in the Tower" }, -- 11747
    ["70058BC5"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 11748
    ["70019013"] = { s = "F", k = "open", p = "Caras Galadhon, Lothlórien" }, -- 11750
    ["70010168"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 11752
    ["70033C7D"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 11758
    ["70033C7A"] = { s = "F", k = "inst", p = "The Bells of Dale" }, -- 11759
    ["70022743"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 11765
    ["700544D5"] = { s = "S", k = "open", p = "Parth Daenath, Mordor Besieged" }, -- 11773
    ["700173AF"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 11779
    ["700084CA"] = { s = "S", k = "open", p = "Western Malenhad, Angmar" }, -- 11789
    ["700084CE"] = { s = "S", k = "open", p = "Western Malenhad, Angmar" }, -- 11791
    ["70058520"] = { s = "R", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 11795
    ["7001EE03"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 11829
    ["7002272B"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 11846
    ["7000135A"] = { s = "F", k = "open", p = "Imlad Balchorth, Angmar" }, -- 11858
    ["700001FA"] = { s = "F", k = "open", p = "Rivendell Valley, Angmar" }, -- 11862
    ["70022745"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 11895
    ["7004C034"] = { s = "F", k = "inst", p = "The Court of Seregost" }, -- 11918
    ["7004C033"] = { s = "F", k = "inst", p = "The Court of Seregost" }, -- 11919
    ["700559A2"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 11920
    ["7000BFC7"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 11921
    ["7004E9E4"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 11946
    ["700544D6"] = { s = "S", k = "open", p = "Parth Daenath, Mordor Besieged" }, -- 11949
    ["7004117F"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 11962
    ["70002E23"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 11974
    ["700173BE"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 11985
    ["700442C8"] = { s = "S", k = "epic", p = "War for Gondor" }, -- 12000
    ["7000E8BB"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 12001
    ["70018182"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 12002
    ["7002C913"] = { s = "S", k = "open", p = "Wailing Hills, Great River" }, -- 12003
    ["7003E2AB"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 12004
    ["70053550"] = { s = "F", k = "inst", p = "The Depths of Kidzul-kâlah" }, -- 12017
    ["70069839"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 12022
    ["7006A150"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 12023
    ["7006A14F"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 12024
    ["7006A14E"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 12025
    ["7006A14D"] = { s = "R", k = "inst", p = "Depths of Mâkhda Khorbo" }, -- 12026
    ["70043534"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 12036
    ["70043536"] = { s = "F", k = "open", p = "Ashes and Stars" }, -- 12037
    ["7000A8F6"] = { s = "F", k = "inst", p = "Annúminas" }, -- 12040
    ["70002D07"] = { s = "F", k = "open", p = "Angmar" }, -- 12049
    ["700001A1"] = { s = "F", k = "inst", p = "Urugarth" }, -- 12050
    ["700225EF"] = { s = "S", k = "open", p = "Thrór's Coomb, Enedwaith" }, -- 12064
    ["7000BFC8"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 12079
    ["7000C69E"] = { s = "S", k = "open", p = "Northern High Pass, The Misty Mountains" }, -- 12087
    ["700001B3"] = { s = "F", k = "inst", p = "Urugarth" }, -- 12100
    ["70058B88"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 12124
    ["7005AFFC"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12130
    ["70059DD4"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12131
    ["70059DDF"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12132
    ["70059DDE"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12133
    ["70059DDC"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12134
    ["70059DDA"] = { s = "R", k = "inst", p = "The Fall of Khazad-dûm" }, -- 12135
    ["7000BFC4"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 12139
    ["700556DE"] = { s = "F", k = "inst", p = "The Fallen Kings" }, -- 12145
    ["700556DD"] = { s = "F", k = "inst", p = "The Fallen Kings" }, -- 12146
    ["700556DC"] = { s = "F", k = "inst", p = "The Fallen Kings" }, -- 12147
    ["700173C6"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 12152
    ["70002CCC"] = { s = "S", k = "open", p = "Ram Dúath, Angmar" }, -- 12154
    ["7000752C"] = { s = "F", k = "open", p = "Greenfields, The Shire" }, -- 12166
    ["70064381"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 12182
    ["700173BF"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 12191
    ["70033C8D"] = { s = "R", k = "inst", p = "The Fires of Smaug" }, -- 12192
    ["70033CA0"] = { s = "R", k = "inst", p = "The Fires of Smaug" }, -- 12193
    ["70033CA1"] = { s = "R", k = "inst", p = "The Fires of Smaug" }, -- 12194
    ["7000E8B8"] = { s = "S", k = "open", p = "Esteldín, The Misty Mountains" }, -- 12211
    ["700173C4"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 12217
    ["70070B02"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 12224
    ["70070B00"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 12225
    ["70070B06"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 12226
    ["70072F8A"] = { s = "S", k = "open", p = "Downs of Farad Shóta, Adagím, the Moulder-wood" }, -- 12237
    ["700173B7"] = { s = "F", k = "inst", p = "The Forgotten Treasury" }, -- 12242
    ["700173B6"] = { s = "F", k = "inst", p = "The Forgotten Treasury" }, -- 12243
    ["700544DA"] = { s = "S", k = "open", p = "Emyn Duir, Mordor Besieged" }, -- 12246
    ["7002B8F9"] = { s = "F", k = "inst", p = "Isengard" }, -- 12253
    ["7002BC54"] = { s = "F", k = "inst", p = "Isengard" }, -- 12254
    ["70017536"] = { s = "F", k = "inst", p = "The Sixteenth Hall" }, -- 12272
    ["7003EAFD"] = { s = "F", k = "open", p = "Trollshaws" }, -- 12298
    ["700544D8"] = { s = "S", k = "open", p = "Parth Daenath, Mordor Besieged" }, -- 12306
    ["70002CCD"] = { s = "S", k = "open", p = "Ram Dúath, Angmar" }, -- 12314
    ["7001949E"] = { s = "S", k = "open", p = "Nimrodel, Lothlórien" }, -- 12319
    ["7001751A"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 12320
    ["70017512"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 12321
    ["70017511"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 12322
    ["7001751F"] = { s = "F", k = "inst", p = "The Grand Stair" }, -- 12323
    ["7000834D"] = { s = "F", k = "open", p = "Fasach-larran, Angmar" }, -- 12327
    ["7000E8B6"] = { s = "S", k = "open", p = "Esteldín, The North Downs" }, -- 12338
    ["700544D3"] = { s = "S", k = "open", p = "Arandor, Mordor Besieged" }, -- 12345
    ["700559A4"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 12351
    ["70042EAF"] = { s = "S", k = "open", p = "Eastern Gondor: South Ithilien" }, -- 12364
    ["70054F5A"] = { s = "S", k = "inst", p = "The Harrowing of Morgul" }, -- 12370
    ["70054F55"] = { s = "S", k = "inst", p = "The Harrowing of Morgul" }, -- 12371
    ["70054F52"] = { s = "S", k = "inst", p = "The Harrowing of Morgul" }, -- 12372
    ["700608E8"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12393
    ["7006028C"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12394
    ["7006028E"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12395
    ["7006028D"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12396
    ["7006028B"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12397
    ["7006028A"] = { s = "R", k = "inst", p = "The Hiddenhoard of Abnankâra" }, -- 12398
    ["700544DB"] = { s = "S", k = "open", p = "Emyn Duir, Mordor Besieged" }, -- 12401
    ["700268CD"] = { s = "S", k = "open", p = "Lone-lands" }, -- 12412
    ["70051399"] = { s = "S", k = "open", p = "Járnfast, The Dwarf-holds" }, -- 12424
    ["70029FCC"] = { s = "R", k = "skirm", p = "The Icy Crevasse" }, -- 12440
    ["700017AB"] = { s = "F", k = "open", p = "Fields of Fornost, The North Downs" }, -- 12451
    ["700559A6"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 12472
    ["700011CB"] = { s = "F", k = "open", p = "Himbar, Angmar" }, -- 12473
    ["7000A8F9"] = { s = "F", k = "inst", p = "Annúminas: Haudh Valandil" }, -- 12475
    ["7005AB13"] = { s = "S", k = "open", p = "Welkin-lofts, Gundabad" }, -- 12483
    ["7000E8BD"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 12506
    ["70058BBA"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 12539
    ["7002C5F5"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 12552
    ["700436CF"] = { s = "F", k = "open", p = "Osgiliath, Eastern Gondor" }, -- 12573
    ["700083A6"] = { s = "F", k = "open", p = "Fasach-larran, Angmar" }, -- 12575
    ["7000325D"] = { s = "F", k = "open", p = "High Crag, The Misty Mountains" }, -- 12636
    ["7000BFCC"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 12669
    ["7000D3CF"] = { s = "F", k = "open", p = "Fasach-falroid, Angmar" }, -- 12676
    ["7005307D"] = { s = "S", k = "open", p = "Gladdenmere, The Vales of Anduin" }, -- 12698
    ["70041178"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 12726
    ["700514B7"] = { s = "F", k = "open", p = "Fields of Fornost, The North Downs" }, -- 12727
    ["700001BB"] = { s = "F", k = "open", p = "Western Malenhad, Angmar" }, -- 12729
    ["7000D3C5"] = { s = "S", k = "open", p = "Aughaire, Angmar" }, -- 12736
    ["7003E2AE"] = { s = "S", k = "open", p = "Greenway, The North Downs" }, -- 12745
    ["7003EE80"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 12746
    ["70002C69"] = { s = "F", k = "open", p = "Trestlebridge, The North Downs" }, -- 12764
    ["7001817F"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 12770
    ["7001818B"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 12771
    ["70018185"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 12772
    ["7001818E"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 12773
    ["70018190"] = { s = "F", k = "open", p = "Nud-melek, Moria" }, -- 12774
    ["70018194"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 12775
    ["7004DD81"] = { s = "R", k = "open", p = "Farmers Faire" }, -- 12785
    ["700290BE"] = { s = "F", k = "open", p = "Starkmoor, Dunland" }, -- 12794
    ["700290BF"] = { s = "F", k = "open", p = "Starkmoor, Dunland" }, -- 12795
    ["700290C0"] = { s = "F", k = "open", p = "Starkmoor, Dunland" }, -- 12796
    ["700290C1"] = { s = "F", k = "open", p = "Starkmoor, Dunland" }, -- 12797
    ["7002C619"] = { s = "S", k = "open", p = "Limlight Gorge, Great River" }, -- 12827
    ["70044F27"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 12831
    ["70044F26"] = { s = "S", k = "inst", p = "The Quays of the Harlond" }, -- 12832
    ["700169BF"] = { s = "S", k = "open", p = "Redhorn Lodes, Moria" }, -- 12835
    ["70045B8F"] = { s = "S", k = "open", p = "Beacon Hills, Anórien" }, -- 12840
    ["70049FF1"] = { s = "F", k = "open", p = "Nain Enidh, The Lone-lands" }, -- 12854
    ["700173C8"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 12881
    ["7002BD51"] = { s = "F", k = "open", p = "Isengard, Dunland" }, -- 12885
    ["7002BD4F"] = { s = "R", k = "open", p = "Rise of Isengard" }, -- 12886
    ["7000A11A"] = { s = "S", k = "open", p = "Parth Aduial, Evendim" }, -- 12903
    ["7000F0BE"] = { s = "S", k = "open", p = "Länsi-mâ, Forochel" }, -- 12907
    ["7002CE2E"] = { s = "F", k = "inst", p = "Roots of Fangorn" }, -- 12909
    ["7004356A"] = { s = "S", k = "open", p = "Eastern Gondor: Osgiliath" }, -- 12920
    ["70043568"] = { s = "S", k = "open", p = "Eastern Gondor: Osgiliath" }, -- 12921
    ["70041182"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 12938
    ["7001752A"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 12969
    ["700176CD"] = { s = "S", k = "open", p = "The Twenty-first Hall, Moria" }, -- 12978
    ["7000D779"] = { s = "S", k = "pe", p = "Krúslë Lannan" }, -- 12992
    ["7000D787"] = { s = "S", k = "open", p = "Gorothlad, Angmar" }, -- 12993
    ["7005766A"] = { s = "S", k = "inst", p = "Askâd-mazal, the Chamber of Shadows" }, -- 13001
    ["700006AC"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 13004
    ["7001627C"] = { s = "S", k = "open", p = "Nan Sirannon, Eregion" }, -- 13010
    ["70044F89"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 13016
    ["70044F8A"] = { s = "F", k = "inst", p = "The Silent Street" }, -- 13017
    ["700559A5"] = { s = "S", k = "open", p = "Minas Morgul, Imlad Morgul" }, -- 13019
    ["7001EE00"] = { s = "F", k = "inst", p = "Sammath Gûl" }, -- 13022
    ["7004799B"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 13026
    ["7001752E"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 13095
    ["700176B5"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 13096
    ["70064F6E"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 13110
    ["70064F70"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 13111
    ["70064F6F"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 13112
    ["70064F72"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 13113
    ["70064F71"] = { s = "R", k = "inst", p = "Gwathrenost, the Witch-king's Citadel" }, -- 13114
    ["7006A167"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13118
    ["7006A165"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13119
    ["7006A168"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13120
    ["7006A166"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13121
    ["7006A16A"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13122
    ["7006A169"] = { s = "S", k = "inst", p = "The Streets of Râhal Bakh" }, -- 13123
    ["700001AD"] = { s = "F", k = "inst", p = "Carn Dûm" }, -- 13125
    ["700085E7"] = { s = "F", k = "open", p = "Gorothlad, Angmar" }, -- 13135
    ["700085E8"] = { s = "F", k = "open", p = "Gorothlad, Angmar" }, -- 13142
    ["700085E9"] = { s = "F", k = "open", p = "Gorothlad, Angmar" }, -- 13143
    ["700085EB"] = { s = "F", k = "open", p = "Gorothlad, Angmar" }, -- 13144
    ["700085EA"] = { s = "F", k = "open", p = "Gorothlad, Angmar" }, -- 13145
    ["7001752C"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 13185
    ["700097E3"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 13199
    ["7001EE04"] = { s = "F", k = "inst", p = "Dol Guldur" }, -- 13208
    ["70025A19"] = { s = "S", k = "open", p = "In Their Absence" }, -- 13210
    ["70051F7D"] = { s = "F", k = "open", p = "Helegrod, The Misty Mountains" }, -- 13218
    ["70008283"] = { s = "F", k = "open", p = "Taur Gonwaith, The North Downs" }, -- 13227
    ["7000E8BC"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 13242
    ["700381C7"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 13267
    ["70017526"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 13272
    ["700588AA"] = { s = "S", k = "open", p = "Elderslade: The War Effort" }, -- 13290
    ["700033BE"] = { s = "F", k = "open", p = "Green Hill Country, The Shire" }, -- 13297
    ["7003EE86"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 13298
    ["700173C1"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 13300
    ["7003E2AD"] = { s = "S", k = "open", p = "North Downs" }, -- 13301
    ["7001AB9D"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 13303
    ["70018196"] = { s = "F", k = "open", p = "The Foundations of Stone, Moria" }, -- 13308
    ["70019212"] = { s = "S", k = "inst", p = "The Water Wheels: Nalâ-dûm" }, -- 13309
    ["7000EABB"] = { s = "S", k = "open", p = "Jä-rannit, Forochel" }, -- 13318
    ["700544D9"] = { s = "F", k = "open", p = "Emyn Duir, Mordor Besieged" }, -- 13363
    ["700544D4"] = { s = "S", k = "open", p = "Arandor, Mordor Besieged" }, -- 13365
    ["7001A636"] = { s = "S", k = "open", p = "The Drownholt, Mirkwood" }, -- 13393
    ["70002E25"] = { s = "F", k = "open", p = "Trollshaws" }, -- 13398
    ["70028B5A"] = { s = "R", k = "open", p = "Galtrev, Dunland" }, -- 13402
    ["70009E12"] = { s = "F", k = "open", p = "Parth Aduial, Evendim" }, -- 13418
    ["70029FC5"] = { s = "R", k = "skirm", p = "Thievery and Mischief" }, -- 13420
    ["7004E980"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 13431
    ["7004E989"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 13432
    ["7004E98A"] = { s = "F", k = "inst", p = "Thikil-gundu" }, -- 13433
    ["700001A7"] = { s = "F", k = "inst", p = "Urugarth" }, -- 13445
    ["7000BFCA"] = { s = "R", k = "inst", p = "The Rift of Nûrz Ghâshu" }, -- 13534
    ["700588A9"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 13539
    ["700588A7"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 13540
    ["700588A8"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 13541
    ["700588A6"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 13542
    ["700001EB"] = { s = "F", k = "open", p = "Giant Halls, The Misty Mountains" }, -- 13564
    ["700173BD"] = { s = "F", k = "open", p = "The Flaming Deeps, Moria" }, -- 13573
    ["700173C2"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 13574
    ["7003EE78"] = { s = "F", k = "open", p = "Nan Wathren, The North Downs" }, -- 13667
    ["70058BBD"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 13681
    ["7003FC13"] = { s = "S", k = "open", p = "Dol Amroth, Belfalas & Dor-en-Ernil" }, -- 13733
    ["7003FC16"] = { s = "S", k = "open", p = "The Havens of Belfalas, Belfalas & Dor-en-Ernil" }, -- 13734
    ["7003FC14"] = { s = "S", k = "open", p = "Western Gondor: Dol Amroth" }, -- 13735
    ["7003FC15"] = { s = "S", k = "open", p = "The Havens of Belfalas, Belfalas & Dor-en-Ernil" }, -- 13736
    ["700173B3"] = { s = "F", k = "inst", p = "The Forges of Khazad-dûm" }, -- 13762
    ["70034A79"] = { s = "F", k = "open", p = "The Road to Erebor" }, -- 13769
    ["7000324A"] = { s = "F", k = "open", p = "High Crag, The Misty Mountains" }, -- 13799
    ["70047454"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 13801
    ["70047456"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 13804
    ["70047460"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 13806
    ["700173CB"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 13842
    ["7006E966"] = { s = "R", k = "open", p = "Sûr Akil, Urash Dâr" }, -- 13889
    ["700173AE"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 13902
    ["7003EAF7"] = { s = "F", k = "open", p = "North Trollshaws, The Trollshaws" }, -- 13916
    ["7005307F"] = { s = "S", k = "open", p = "Gladdenmere, The Vales of Anduin" }, -- 13918
    ["70053080"] = { s = "S", k = "open", p = "Gladdenmere, The Vales of Anduin" }, -- 13922
    ["70029FBF"] = { s = "R", k = "skirm", p = "Trouble in Tuckborough" }, -- 13963
    ["7005AB04"] = { s = "S", k = "open", p = "Welkin-lofts, Gundabad" }, -- 14051
    ["70048F78"] = { s = "F", k = "open", p = "Ghâshghurm, Mordor" }, -- 14056
    ["70053081"] = { s = "S", k = "open", p = "Gladdenmere, The Vales of Anduin" }, -- 14100
    ["7006AAC9"] = { s = "S", k = "open", p = "Dil-irmíz, The Berths, Umbar-môkh" }, -- 14133
    ["70044117"] = { s = "F", k = "epic", p = "War for Gondor" }, -- 14146
    ["7004D370"] = { s = "F", k = "open", p = "The Dale-lands, Strongholds of the North" }, -- 14153
    ["7001AB9A"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 14158
    ["700381C3"] = { s = "R", k = "epic", p = "Defence of Rohan" }, -- 14180
    ["700006BE"] = { s = "S", k = "open", p = "Agamaur, The Lone-lands" }, -- 14185
    ["70058B8A"] = { s = "S", k = "open", p = "The War of Three Peaks, Elderslade" }, -- 14189
    ["70000628"] = { s = "F", k = "inst", p = "Garth Agarwen" }, -- 14206
    ["70007F4A"] = { s = "S", k = "open", p = "Vale of Thrain, Ered Luin" }, -- 14222
    ["7001CC82"] = { s = "S", k = "open", p = "Emyn Lûm, Mirkwood" }, -- 14242
    ["7001CC83"] = { s = "S", k = "open", p = "Egladil, Mirkwood" }, -- 14243
    ["7001CC6F"] = { s = "F", k = "open", p = "The Twenty-first Hall, Mirkwood" }, -- 14245
    ["7001CC5E"] = { s = "S", k = "open", p = "Gathbúrz, Mirkwood" }, -- 14249
    ["7004799A"] = { s = "F", k = "open", p = "The Slag-hills, The Wastes" }, -- 14258
    ["700173C7"] = { s = "F", k = "open", p = "Redhorn Lodes, Moria" }, -- 14289
    ["70035A75"] = { s = "S", k = "open", p = "Forlaw, Wildermore" }, -- 14297
    ["70035A80"] = { s = "S", k = "open", p = "Forlaw, Wildermore" }, -- 14298
    ["70035A7C"] = { s = "R", k = "open", p = "Forlaw, Wildermore" }, -- 14299
    ["70035A78"] = { s = "R", k = "open", p = "Forlaw, Fangorn" }, -- 14303
    ["70035A77"] = { s = "R", k = "open", p = "Forlaw, Wildermore" }, -- 14304
    ["70035A79"] = { s = "S", k = "open", p = "Forlaw, Fangorn" }, -- 14307
    ["70035A7F"] = { s = "F", k = "open", p = "Forlaw, Wildermore" }, -- 14308
    ["70035A76"] = { s = "F", k = "open", p = "Forlaw, Wildermore" }, -- 14309
    ["700350B1"] = { s = "S", k = "open", p = "The Fallows, Wildermore" }, -- 14311
    ["70035762"] = { s = "S", k = "open", p = "Writhendowns, Wildermore" }, -- 14313
    ["7003A470"] = { s = "R", k = "open", p = "Westfold" }, -- 14315
    ["700466E4"] = { s = "F", k = "open", p = "North Ithilien, Ithilien" }, -- 14316
    ["7003A471"] = { s = "R", k = "open", p = "Westfold" }, -- 14317
    ["70030FB8"] = { s = "S", k = "open", p = "The Wold, Wold" }, -- 14318
    ["700384E1"] = { s = "F", k = "open", p = "Eastfold" }, -- 14319
    ["70037A8E"] = { s = "F", k = "open", p = "Broadacres, Entwash" }, -- 14321
    ["700379E7"] = { s = "R", k = "open", p = "Broadacres, Entwash" }, -- 14322
    ["70034D76"] = { s = "R", k = "open", p = "Whitshaws, Wildermore" }, -- 14323
    ["7003F2D0"] = { s = "R", k = "open", p = "Lamedon, Western Gondor" }, -- 14324
    ["70030FB4"] = { s = "S", k = "open", p = "Sutcrofts, Croftlands" }, -- 14325
    ["700384E0"] = { s = "S", k = "open", p = "Eastfold" }, -- 14328
    ["7003108A"] = { s = "S", k = "open", p = "The Entwash Vale, Entwash" }, -- 14329
    ["70031082"] = { s = "S", k = "open", p = "The Entwash Vale, Entwash" }, -- 14330
    ["700384DF"] = { s = "F", k = "open", p = "Eastfold" }, -- 14331
    ["70044239"] = { s = "S", k = "open", p = "Talath Anor, Anórien" }, -- 14332
    ["7003A6EC"] = { s = "F", k = "open", p = "Kingstead, Eastfold" }, -- 14336
    ["70042EAD"] = { s = "F", k = "open", p = "South Ithilien, Eastern Gondor" }, -- 14337
    ["70030F83"] = { s = "S", k = "open", p = "Norcrofts, Croftlands" }, -- 14339
    ["70041359"] = { s = "S", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 14340
    ["7003FDBE"] = { s = "F", k = "open", p = "Blackroot Vale, Western Gondor" }, -- 14342
    ["70041360"] = { s = "F", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 14343
    ["7004529F"] = { s = "S", k = "open", p = "Beacon Hills, Anórien" }, -- 14345
    ["70043220"] = { s = "S", k = "open", p = "Upper Lebennin, Lebennin" }, -- 14347
    ["700466E5"] = { s = "S", k = "open", p = "North Ithilien, Ithilien" }, -- 14348
    ["70030FB7"] = { s = "F", k = "open", p = "Sutcrofts, Croftlands" }, -- 14349
    ["70045415"] = { s = "S", k = "open", p = "Taur Drúadan, Anórien" }, -- 14350
    ["7003A49B"] = { s = "F", k = "open", p = "Westfold" }, -- 14351
    ["7004423A"] = { s = "F", k = "open", p = "Pelennor, Old Anórien" }, -- 14352
    ["700385A6"] = { s = "R", k = "open", p = "Stonedeans, Westfold" }, -- 14353
    ["7004423B"] = { s = "S", k = "open", p = "Talath Anor, Anórien" }, -- 14354
    ["7003108D"] = { s = "S", k = "open", p = "The Entwash Vale, Entwash" }, -- 14355
    ["700385AB"] = { s = "F", k = "open", p = "Stonedeans, Westfold" }, -- 14358
    ["7003A6EB"] = { s = "F", k = "open", p = "Kingstead, Eastfold" }, -- 14359
    ["700466E6"] = { s = "S", k = "open", p = "North Ithilien, Ithilien" }, -- 14361
    ["7004423C"] = { s = "F", k = "open", p = "Pelennor, Old Anórien" }, -- 14362
    ["7003FDB3"] = { s = "S", k = "open", p = "Blackroot Vale, Western Gondor" }, -- 14363
    ["7003F2E5"] = { s = "S", k = "open", p = "Lamedon, Western Gondor" }, -- 14364
    ["7003A6EA"] = { s = "S", k = "open", p = "Kingstead, Eastfold" }, -- 14365
    ["7003A49C"] = { s = "S", k = "open", p = "Westfold" }, -- 14366
    ["700385AA"] = { s = "F", k = "open", p = "Stonedeans, Westfold" }, -- 14367
    ["70035920"] = { s = "R", k = "open", p = "Balewood, Fangorn" }, -- 14368
    ["700384E2"] = { s = "R", k = "open", p = "Eastfold" }, -- 14369
    ["700350B3"] = { s = "R", k = "open", p = "The Fallows, Wildermore" }, -- 14370
    ["7004423D"] = { s = "S", k = "open", p = "Pelennor, Old Anórien" }, -- 14371
    ["70041AB5"] = { s = "S", k = "open", p = "Lower Lebennin, Lebennin" }, -- 14372
    ["7004135A"] = { s = "F", k = "open", p = "Dor-en-Ernil, Belfalas & Dor-en-Ernil" }, -- 14373
    ["700413BB"] = { s = "S", k = "open", p = "Ringló Vale" }, -- 14375
    ["70040B6A"] = { s = "S", k = "open", p = "The Havens of Belfalas, Belfalas & Dor-en-Ernil" }, -- 14376
    ["70042EAE"] = { s = "R", k = "open", p = "South Ithilien, Eastern Gondor" }, -- 14380
    ["7003F2F3"] = { s = "S", k = "open", p = "Lamedon, Western Gondor" }, -- 14381
    ["7004139A"] = { s = "S", k = "open", p = "The Dead Marshes, The Wastes" }, -- 14384
    ["7004423E"] = { s = "F", k = "open", p = "Talath Anor, Anórien" }, -- 14385
    ["70031088"] = { s = "F", k = "open", p = "The Entwash Vale, Entwash" }, -- 14386
    ["70035921"] = { s = "S", k = "open", p = "Balewood, Fangorn" }, -- 14388
    ["70041AB3"] = { s = "F", k = "open", p = "Lower Lebennin, Lebennin" }, -- 14389
    ["70035761"] = { s = "F", k = "open", p = "Writhendowns, Wildermore" }, -- 14391
    ["70030FB9"] = { s = "R", k = "open", p = "Sutcrofts, Croftlands" }, -- 14392
    ["700350B2"] = { s = "F", k = "open", p = "The Fallows, Wildermore" }, -- 14393
    ["700082F0"] = { s = "F", k = "open", p = "Dol Dínen, The North Downs" }, -- 14424
    ["7001ABA4"] = { s = "S", k = "inst", p = "Dol Guldur" }, -- 14434
    ["70007DF1"] = { s = "F", k = "open", p = "High Crag, The Misty Mountains" }, -- 14444
    ["7003E2B0"] = { s = "S", k = "open", p = "North Downs" }, -- 14457
    ["7000F0BC"] = { s = "S", k = "open", p = "Länsi-mâ, Forochel" }, -- 14466
    ["700082D2"] = { s = "F", k = "open", p = "Dol Dínen, The North Downs" }, -- 14474
    ["7000E3DA"] = { s = "F", k = "open", p = "Esteldín, The North Downs" }, -- 14486
    ["70001204"] = { s = "F", k = "open", p = "Eastern Malenhad, Angmar" }, -- 14490
    ["70032BD5"] = { s = "F", k = "inst", p = "Webs of the Scuttledells" }, -- 14499
    ["70032BD6"] = { s = "F", k = "inst", p = "Webs of the Scuttledells" }, -- 14500
    ["70072E0F"] = { s = "F", k = "open", p = "Khadakh Lûr, Kighân, the Shornvale" }, -- 14512
    ["70072E15"] = { s = "F", k = "open", p = "The Dry-whelm, Idagâl, the Dry-whelm" }, -- 14513
    ["70072E0E"] = { s = "F", k = "open", p = "The Drenchmead, Adagím, the Moulder-wood" }, -- 14514
    ["70072E16"] = { s = "F", k = "open", p = "Uhumêlu, An Shêru, the Height of the Sky" }, -- 14515
    ["70041177"] = { s = "F", k = "open", p = "Tarlang's Crown, Western Gondor" }, -- 14566
    ["70002CD3"] = { s = "S", k = "open", p = "Ram Dúath, Angmar" }, -- 14643
    ["70047F5A"] = { s = "F", k = "inst", p = "Filikul" }, -- 14780
    ["70073BC5"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 14837
    ["70073BC6"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 14838
    ["70073BC7"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 14839
    ["70073C91"] = { s = "R", k = "inst", p = "The Folly of Nagakhêdi" }, -- 14840
}
