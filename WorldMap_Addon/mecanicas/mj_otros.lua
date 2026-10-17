-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["otros"] = {
  { "Mozrúk the Wind-rider", {
    { "Fire Bomb", "Z", 0, 0, nil, { "fry to a crisp" }, "Fire", true, nil, "Bomba de fuego", "Fuego" },
    { "Sticky", "Q", 0, 0, nil, { "stick around won t you", "quédate por aquí quieres" }, nil, true, nil, "Pegajoso", nil },
    { "Airstrike!", "Q", 0, 0, nil, { "death from above", "muerte desde arriba" }, nil, true, nil, "¡Ataque aéreo!", nil },
  } },
  { "Remmenaeg", {
    { "Left = Bats! Right = Wights! Far = Spirit!", "Q", 0, 0, nil, { "welcome you have made it quite far but n", "bienvenidos han llegado bastante lejos p" }, nil, true, nil, "¡Izquierda murciélagos, derecha tumularios, al fondo espíritu!", nil },
  } },
  { "Brúnek I Clovenbow", {
    { "Interrupt Clovenbrow", "I", 0, 0, nil, { "how would you like", "taste my axes" }, "Clovenbrow axes (Min)", true, nil, "Interrumpe a Clovenbrow", "Hachas de Clovenbrow (Min)" },
  } },
  { "Igash the Fanatic", {
    { "AoE stun!!", "ZK", 0, 0, nil, { "let the darkness crush you", "deja que la oscuridad te aplaste" }, nil, true, nil, "¡Aturdimiento en área!", nil },
  } },
  { "Cargaraf", {
    { "Move away from Woman!", "Z", 0, 0, nil, { "away with you", "fuera de aquí" }, nil, true, nil, "¡Aléjate de la mujer!", nil },
  } },
  { "The Mistress of Pestilence", {
    { "Beware Reflect | CC limrafn to Kill", "IB", 0, 0, nil, { "your ignorance will be your final undoin", "tu ignorancia será tu perdición final" }, nil, true, nil, "Cuidado con el reflejo | controla a Limrafn para matarlo", nil },
    { "Goblin phase", "Q", 0, 0, nil, { "let darkness aid me", "que la oscuridad me ayude" }, nil, true, nil, "Fase de trasgos", nil },
    { "Overseer phase", "Q", 0, 0, nil, { "impressive your thoughts are clear but y", "impresionante tus pensamientos son claro" }, nil, true, nil, "Fase del capataz", nil },
  } },
  { "Flâgît", {
    { "Bubble phase!", "B", 0, 0, nil, { "you can not stop her army i will not all", "no pueden detener su ejército no lo per" }, nil, true, nil, "¡Fase de burbujas!", nil },
    { "Beware of eyes", "Q", 0, 0, nil, { "the mistress army is too strong we were ", "el ejército de la ama es demasiado fuer" }, nil, true, nil, "Cuidado con los ojos", nil },
    { "FASTER BUBBLES", "B", 0, 0, nil, { "the light it dims what are you doing i m", "la luz se atenúa qué están haciendo d" }, nil, true, nil, "Burbujas más rápido", nil },
  } },
  { "Blagh", {
    { "Split trolls!", "Q", 0, 0, nil, { "brother we are together let us strike in", "i am here brother you take the weak one ", "i am with you brother we shall punish th", "estoy contigo hermano los castigaremos j" }, nil, true, nil, "¡Separa a los trolls!", nil },
    { "Mushroom phase", "Q", 0, 0, nil, { "his death will mean your death", "su muerte significará su muerte" }, nil, true, nil, "Fase de hongos", nil },
  } },
  { "Vethúg Wintermind", {
    { "Check for BLUE eye", "Q", 0, 0, nil, { "freeze insects", "congelaos insectos" }, "Blue Eye", true, nil, "Atento al ojo AZUL", "Ojo azul" },
  } },
  { "Dúrchest", {
    { "Remove Corruptions on boss", "ZYX", 0, 0, nil, { "such a shame to come so far only to fail", "qué pena llegar tan lejos solo para fra" }, nil, true, nil, "Quita las corrupciones del jefe", nil },
    { "Add Entering", "Q", 0, 0, nil, { "you finish these puny creatures", "tú acaba con estas insignificantes cria", "soldier front and centre", "soldado al frente y al centro" }, nil, true, nil, "Entra un esbirro", nil },
  } },
  { "Karazgar the Weeping Warrior", {
    { "Check for BLUE eye", "Q", 0, 0, nil, { "finish them", "acabad con ellos" }, "Blue Eye", true, nil, "Atento al ojo AZUL", "Ojo azul" },
    { "Check for PURPLE eye", "Q", 0, 0, nil, { "meet your end", "by my morgul steel", "por mi acero de morgul" }, "Purple Eye", true, nil, "Atento al ojo MORADO", "Ojo morado" },
  } },
  { "Zholuga", {
    { "DO NOT touch the runestones", "Q", 0, 0, nil, { "mistress lend me your courage", "ama préstame tu valor" }, nil, true, nil, "NO toques las piedras rúnicas", nil },
  } },
  { "Urcheron", {
    { "Interupt, Move out of Flames", "IZ", 0, 0, nil, { "you will find your end soon enough", "encontrarás tu fin muy pronto" }, nil, true, nil, "Interrumpe y sal de las llamas", nil },
  } },
  { "Warchief Búrzghâsh", {
    { "Tier 2? Killing goblins boosts dmg of boss", "Q", 0, 0, nil, { "whelps you have come far enough this is ", "cachorros han llegado demasiado lejos es" }, nil, true, nil, "¿Nivel 2? Matar trasgos sube el daño del jefe", nil },
  } },
  { "Udúnion", {
    { "Scroll of Ruin - RIGHT SIDE!", "Q", 0, 0, nil, { "come dark fire", "ven fuego oscuro" }, nil, true, nil, "¡Pergamino de la Ruina: LADO DERECHO!", nil },
    { "Staff of Dark Shadows - LEFT SIDE!", "Q", 0, 0, nil, { "shadow take you", "que la sombra te lleve" }, nil, true, nil, "¡Bastón de Sombras Oscuras: LADO IZQUIERDO!", nil },
  } },
  { "Carchrien", {
    { "Careful of bat stuns!", "K", 0, 0, nil, { "mmm come to play", "mmm vienes a jugar", "hahahaha" }, nil, true, nil, "¡Cuidado con los aturdimientos de los murciélagos!", nil },
  } },
  { "Gothghaash the Firecaller", {
    { "Melee REFLECT!!", "B", 0, 0, nil, { "wreathed in flame i ll watch you burn yo", "envuelto en llamas te veré arder" }, nil, true, nil, "¡REFLEJO cuerpo a cuerpo!", nil },
  } },
  { "Blogmal Slave-master", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
  { "Gaerdring", {
    { "Killing crawlers boosts add damage!", "Q", 0, 0, nil, { "you have entered your new tomb", "han entrado en su nueva tumba" }, nil, true, nil, "¡Matar reptadores sube el daño de los esbirros!", nil },
    { "Kill Gaerdring to stop add spawn!", "Q", 0, 0, nil, { "no more talk die", "basta de hablar mueran" }, nil, true, nil, "¡Mata a Gaerdring para que no salgan esbirros!", nil },
  } },
  { "Barz", {
    { "Slave wave [Right]", "Z", 0, 0, nil, { "come slaves deal with these worms", "vamos esclavos encargaos de estos gusano" }, nil, true, nil, "Oleada de esclavos [derecha]", nil },
    { "Move away!", "Z", 0, 0, nil, { "i ll gnaw your bones", "roeré tus huesos" }, nil, true, nil, "¡Aléjate!", nil },
    { "Troll wave [Left]", "Z", 0, 0, nil, { "let us see how you fare against one of m", "veamos cómo os las arregláis contra un" }, nil, true, nil, "Oleada de trolls [izquierda]", nil },
    { "Slave-master wave [Left]", "Z", 0, 0, nil, { "quickly destroy them barz commands it", "rápido destruidlos barz lo ordena" }, nil, true, nil, "Oleada del amo de esclavos [izquierda]", nil },
    { "Random power-drain Keep distance", "Q", 0, 0, nil, { "no power is stronger than barz", "ningún poder es más fuerte que barz" }, nil, true, nil, "Drenaje de poder al azar: mantén distancia", nil },
    { "Move out of cave-in", "Z", 0, 0, nil, { "i will bring this cave down upon you", "haré que esta cueva se derrumbe sobre t" }, nil, true, nil, "Sal del derrumbe", nil },
  } },
  { "Zurm", {
    { "Slave wave [Left]", "Z", 0, 0, nil, { "slaves destroy these intruders or you wi", "esclavos destruid a estos intrusos o pro" }, nil, true, nil, "Oleada de esclavos [izquierda]", nil },
    { "Troll wave [Right]", "Z", 0, 0, nil, { "my trolls will deal with you", "mis troles se encargarán de vosotros" }, nil, true, nil, "Oleada de trolls [derecha]", nil },
    { "Slave-master wave [Right]", "Z", 0, 0, nil, { "fools aid your master destroy them", "necios ayudad a vuestro amo destruidlos" }, nil, true, nil, "Oleada del amo de esclavos [derecha]", nil },
  } },
  { "Óiko I the Bellower", {
    { "Interrupt bellower", "I", 0, 0, nil, { "súmrutu" }, "Bellower interrupt", true, nil, "Interrumpe al bramador", "Interrumpe al Bramador" },
  } },
  { "Nardur the Shield", {
    { "Knockback incoming!!", "K", 0, 0, nil, { "give me some room", "dame algo de espacio" }, nil, true, nil, "¡Viene un derribo!", nil },
  } },
  { "Ivar", {
    { "Don't kill Banner-Wights", "Q", 0, 0, nil, { "a new wretch come to fill our ranks my m" }, nil, true, nil, "No mates a los tumularios del estandarte", nil },
  } },
  { "The Blind One ", {
    { "Remove corruptions | CC clones!", "IZYX", 0, 0, nil, { "i gather the shadows", "reúno las sombras" }, nil, true, nil, "Quita corrupciones | ¡controla a los clones!", nil },
    { "Darkling phase", "Q", 0, 0, nil, { "darklings arise" }, nil, true, nil, "Fase de los oscuros", nil },
  } },
  { "Blogmal Troll-keeper", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
  { "Rhavameldir", {
    { "Adds enter on boss HP, and at 1 minute&2minutes", "Q", 0, 0, nil, { "you think to find amarthiel here do you ", "crees que encontrarás a amarthiel aquí" }, nil, true, nil, "Entran esbirros según la vida del jefe y al minuto 1 y 2", nil },
  } },
  { "Isvítha the Gluttonous", {
    { "Adds to main tank", "T", 0, 0, nil, { "help prepare" }, nil, true, nil, "Esbirros al tanque principal", nil },
    { "Check for eye", "Q", 0, 0, nil, { "scrumptious" }, "Purple eye", true, nil, "Atento al ojo", "Ojo morado" },
    { "Add spawn", "Q", 0, 0, nil, { "drakes" }, nil, true, nil, "Aparecen esbirros", nil },
  } },
  { "Óiko II Rill-Seeker", {
    { "Rill-seeker aoe", "Z", 0, 0, nil, { "i seek the", "get out of my way", "aparta de en medio" }, nil, true, nil, "Área de Rill-seeker", nil },
  } },
  { "Gorothúl", {
    { "INCOMING AOE FEAR!", "ZF", 0, 0, nil, { "let terror take you", "que el terror te consuma" }, nil, true, nil, "¡VIENE MIEDO EN ÁREA!", nil },
    { "Dont Kill Guldur-Spirits", "Q", 0, 0, nil, { "from this point forward i will teach you", "a partir de ahora te enseñaré el verda" }, nil, true, nil, "No mates a los espíritus de Guldur", nil },
  } },
  { "Îstum", {
    { "Middle worm spawn", "Q", 0, 0, nil, { "you are too strong too many it is good i", "son demasiado fuertes demasiados qué bu" }, nil, true, nil, "Gusano en el centro", nil },
    { "Corner worm spawn", "Q", 0, 0, nil, { "what is this the mistress ordered me not", "qué es esto la ama me ordenó no fallar" }, nil, true, nil, "Gusano en la esquina", nil },
  } },
  { "Brántokh II the Sunderer", {
    { "Sunderer aoe", "Z", 0, 0, nil, { "bring this mountain", "cower before the might" }, nil, true, nil, "Área del Destructor", nil },
  } },
  { "Dóbruz II Stark-heart", {
    { "Interrupt Stark-Heart", "I", 0, 0, nil, { "clan is mine", "you will not harm" }, "Stark heart interrupt", true, nil, "Interrumpe a Stark-Heart", "Interrumpe a Stark-Heart" },
  } },
  { "Dóbruz IV the Unheeding", {
    { "Unheeding challenge", "Q", 0, 0, nil, { "you look like a weakling", "i challenge you" }, nil, true, nil, "Desafío ignorado", nil },
  } },
  { "Vrarz the Cook", {
    { "INTERRUPT or move away!!!", "IZ", 0, 0, nil, { "have you tried the special", "has probado el especial" }, nil, true, nil, "¡INTERRUMPE o aléjate!", nil },
    { "Stun & Wound Incoming!", "KW", 0, 0, nil, { "would you like that pan seared" }, nil, true, nil, "¡Vienen aturdimiento y herida!", nil },
  } },
  { "Blogmal Cave-troll", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
  { "Naruhel", {
    { "Adds", "Q", 0, 0, nil, { "my strength weakens surround me nature a", "mis fuerzas flaquean naturaleza rodeáme", "i will not fall this forest is my home w", "no caeré este bosque es mi hogar dónde", "my bonds with the swamp weaken come wate", "mis vínculos con la ciénaga se debilit" }, nil, true, nil, "Esbirros", nil },
  } },
  { "Hrímil Frost-heart", {
    { "Knockback", "K", 0, 0, nil, { "glacier", "begone" }, nil, true, nil, "Derribo", nil },
    { "Hide", "Q", 0, 0, nil, { "powerless" }, "Ice-breath", true, nil, "Escóndete", "Aliento helado" },
  } },
  { "Dúnlang", {
    { "Don't kill adds!", "Q", 0, 0, nil, { "welcome welcome are you new recruits for", "bienvenidos bienvenidos sois nuevos recl" }, nil, true, nil, "¡No mates a los esbirros!", nil },
  } },
  { "Umbarrim Sorcerer", {
    { "Betray target, Move Out of Group!", "Z", 0, 0, nil, { "you will betray your friends this day" }, nil, true, nil, "Objetivo traicionado: ¡sal del grupo!", nil },
  } },
  { "Moria", {
    { "Use uniforms to not alert the guards!", "Q", 0, 0, nil, { "intruders", "intrusos", "sound the alarm", "activen la alarma", "to arms", "a las armas" }, nil, true, nil, "¡Usa uniformes para no alertar a los guardias!", nil },
    { "Put on his uniform to be invisible!", "Q", 0, 0, nil, { "an intruder get him", "un intruso atrápenlo", "how dare you come here", "intrusos cómo se atreven a venir aquí", "you re no orc", "do you think me a fool", "you can t fool me", "hey you re not an officer", "oye no eres un oficial", "you shall not pass", "no pasarás" }, nil, true, nil, "¡Ponte su uniforme para ser invisible!", nil },
    { "PREPARE THE WARBAND MANOEUVRE!", "Q", 0, 0, nil, { "prepare the warband manoeuvre", "preparen la maniobra de la hueste de gue" }, nil, true, nil, "¡PREPARA LA MANIOBRA DE GRUPO!", nil },
  } },
  { "Brogadan", {
    { "Kill Limrafn, Avoid Flames!", "Z", 0, 0, nil, { "greetings intruders you are a bit late f", "saludos intrusos llegan un poco tarde pa" }, nil, true, nil, "¡Mata a Limrafn y evita las llamas!", nil },
  } },
  { "General Talug", {
    { "Phase 3, Nuke him!", "Q", 0, 0, nil, { "show them how you ll kill those wretched", "muéstrales cómo matarás a esos misera" }, nil, true, nil, "¡Fase 3: todo el daño!", nil },
    { "Phase 1, Pull Into traps", "Q", 0, 0, nil, { "you have arrived at the perfect time", "has llegado en el momento perfecto" }, nil, true, nil, "Fase 1: llévalo a las trampas", nil },
    { "INTERRUPT or move away!!!", "IZ", 0, 0, nil, { "mind your legs", "cuidado con las piernas" }, nil, true, nil, "¡INTERRUMPE o aléjate!", nil },
    { "Phase 2, Kill fire-first next to him and then trap him", "Z", 0, 0, nil, { "you have the honour of witnessing the po", "tienes el honor de presenciar el poder d" }, nil, true, nil, "Fase 2: mata primero al de fuego a su lado y luego atrápalo", nil },
  } },
  { "Tarkrîp Cave-troll", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
  { "Tarkrîp Slave-master", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
  { "Commander Greb", {
    { "Collect Key from chest!", "Q", 0, 0, nil, { "the general will avenge me", "el general me vengará" }, nil, true, nil, "¡Toma la llave del cofre!", nil },
    { "200% MELEE REFLECT!!!!", "B", 0, 0, nil, { "ha i ll return your puny blows", "ja devolveré tus insignificantes golpes" }, nil, true, nil, "¡Reflejo cuerpo a cuerpo 200%!", nil },
    { "Adds Entering!", "Q", 0, 0, nil, { "now you shall witness my defences", "ahora presenciarás mis defensas" }, nil, true, nil, "¡Entran esbirros!", nil },
    { "DONT APPLY MELEE DOTS!", "Q", 0, 0, nil, { "no more games prepare to fall to my flam", "se acabaron los juegos prepárate para c" }, nil, true, nil, "¡NO pongas daño continuo cuerpo a cuerpo!", nil },
  } },
  { "Alagossír", {
    { "Get in Melee Range!", "Q", 0, 0, nil, { "you stray too far" }, nil, true, nil, "¡Ponte cuerpo a cuerpo!", nil },
    { "Stack up or Line of Sight!", "LG", 0, 0, nil, { "can you handle the burn" }, nil, true, nil, "¡Júntense o rompan la línea de visión!", nil },
    { "Stay In Melee Range!", "Q", 0, 0, nil, { "the storms are gathering quickly", "las tormentas se están reuniendo rápid" }, nil, true, nil, "¡Quédate cuerpo a cuerpo!", nil },
    { "Hug left brazier to avoid lightning!", "Z", 0, 0, nil, { "the storm s pace hastens it is only a ma", "el ritmo de la tormenta se acelera ahora" }, nil, true, nil, "¡Pégate al brasero izquierdo para evitar el rayo!", nil },
  } },
  { "Rung", {
    { "Split trolls!", "Q", 0, 0, nil, { "brother we are together let us strike in", "i am here brother you take the weak one ", "i am with you brother we shall punish th", "estoy contigo hermano los castigaremos j" }, nil, true, nil, "¡Separa a los trolls!", nil },
    { "Mushroom phase", "Q", 0, 0, nil, { "his death will mean your death", "su muerte significará su muerte" }, nil, true, nil, "Fase de hongos", nil },
  } },
  { "Thadúr", {
    { "Kill adds to drop shield!", "B", 0, 0, nil, { "i grow bored of this my hounds will deal", "esto ya me aburre mis sabuesos se encarg", "do you mock me with this refusal to die ", "se burlan de mí con esta negativa a mor", "this is becoming quite frustrating i mus", "esto se está volviendo muy frustrante d" }, nil, true, nil, "¡Mata a los esbirros para quitar el escudo!", nil },
  } },
  { "Talug's Fire-fist", {
    { "ARCHER PLACING TRAP!", "Q", 0, 0, nil, { "mind your feet", "cuidado con los pies" }, nil, true, nil, "¡Arquero poniendo trampa!", nil },
    { "Kill fire-first next to boss, then drag into trap!", "Z", 0, 0, nil, { "aaaiiiieee" }, nil, true, nil, "¡Mata primero al de fuego junto al jefe y llévalo a la trampa!", nil },
  } },
  { "Tarkrîp Troll-keeper", {
    { "Stack on keeper!", "G", 0, 0, nil, { "hah hah hah now master not near to tell ", "ja ja ja ahora el maestro no está cerca", "you dead now little squishies me swing r", "estás muerto ahora pequeños blandengue", "no problem smashing when master far away", "no hay problema en aplastar cuando el ma" }, nil, true, nil, "¡Júntense en el guardián!", nil },
    { "Interrupt Slave-master", "I", 0, 0, nil, { "i will put an end to you vermin", "acabaré contigo sabandija" }, nil, true, nil, "Interrumpe al amo de esclavos", nil },
  } },
}
