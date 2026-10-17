-- Mecanicas de jefe: generado desde BossCodex (Arebel) + PrimePlugins RaidTools. No editar a mano.
-- mecanica = { nombre, etiquetas, reutilizacion, primer uso, iconos de efecto, gritos, aviso, aviso de Prime, nombres en espanol, nombre ES, aviso ES }
local DB = WorldMapAddon.BossDB
DB.inst["ubw2"] = {
  { "Sere Ritualist", {
    { "Ancient Fury", "I", 15, 5, nil, nil, nil },
    { "Corrupted Earth", "I", 25, 10, { 1091611526 }, nil, nil, nil, { "Tierra corrupta" } },
  } },
  { "Urâshi Archer", {
    { "Poisoned Dart", "ISP", 20, 0, { 1090523646 }, nil, nil, nil, { "Dardo envenenado" } },
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Sere Bowman", {
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Utûgi Demolisher", {
    { "Sweep", "C", 7, 5, nil, nil, nil, nil, { "Barrido" } },
    { "Great Smash", "K", 5, 3, nil, nil, nil },
    { "Thresh the Chaff", "CK", 10, 5, nil, nil, nil, nil, { "Trillar la paja" } },
    { "Furious Smite", "T", 5, 5, nil, nil, nil, nil, { "Golpe Furioso", "Golpe furioso" } },
  } },
  { "Urâshi Gut-slasher", {
    { "Brutal Strike", "T", 1, 0, nil, nil, nil, nil, { "Golpe Brutal" } },
  } },
  { "Khablag", {
    { "Fresh Victim", "A", 30, 15, nil, { "you cannot dodge my blade", "no puedes esquivar mi espada" }, nil, nil, { "Víctima fresca" } },
    { "Gather Strength", "A", 30, 15, { 1091476413 }, { "you cannot dodge my blade", "no puedes esquivar mi espada" }, nil },
    { "Thrust", "W", 1, 0, { 1090531521 }, nil, nil, nil, { "Estocada" } },
    { "Heated Sweep", "C", 4, 2, nil, nil, nil },
  } },
  { "Urâshi Captain", {
    { "Blistering Derision", "I", 10, 10, nil, nil, nil, nil, { "Burla abrasadora" } },
  } },
  { "Urâshi Berserker", {
    { "Jagged Cut", "CSW", 15, 0, { 1090553355 }, nil, nil, nil, { "Corte Dentado" } },
  } },
  { "Sere Huntsman", {
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Utûgi Hunter", {
    { "Jagged Arrow", "SW", 1, 0, { 1090541187 }, nil, nil, nil, { "Flecha dentada" } },
    { "Split Shot", "ISW", 10, 5, { 1090553904 }, nil, nil },
  } },
  { "Urâshi Assassin", {
    { "Enraged Shot", "E", 3, 5, nil, nil, nil, nil, { "Disparo enfurecido" } },
  } },
  { "Sere Soldier", {
    { "Cruel Cut", "W", 20, 5, { 1090580244 }, nil, nil, nil, { "Corte cruel" } },
  } },
  { "Sere Champion", {
    { "Cleave Foes", "C", 1, 0, nil, nil, nil, nil, { "Hender enemigos" } },
    { "Barbed Arrow", "SW", 10, 8, { 1090531521 }, nil, nil, nil, { "Flecha con púas" } },
    { "Brutal Arrow", "K", 12, 8, nil, nil, nil, nil, { "Flecha brutal" } },
    { "Shadow Burst", "A", 10, 5, nil, nil, nil },
  } },
  { "Daikhag", {
    { "Frenzied Axe", "C", 12, 10, nil, nil, nil, nil, { "Hacha frenética" } },
    { "Dismissal", "R", 38, 22, { 1090523949 }, { "away with you", "fuera de aquí" }, nil },
    { "Axe Pummel", "C", 1, 0, nil, nil, nil, nil, { "Golpe de hacha" } },
    { "Not So Fast", "K", 10, 15, nil, nil, nil, nil, { "¡No tan rápido!", "No tan rápido" } },
    { "Weighted Axe-head", "CK", 30, 30, nil, { "get away from me", "aléjate de mí", "alÉjate de mÍ" }, nil, nil, { "Cabeza de hacha pesada" } },
  } },
  { "Urâshi Blood-spiller", {
    { "Brutal Strike", "T", 1, 0, nil, nil, nil, nil, { "Golpe Brutal" } },
  } },
  { "Sere Conjurer", {
    { "Tangled Shadow", "S", 15, 10, { 1091429124 }, nil, nil, nil, { "Sombra enredada" } },
    { "Death Grip", "K", 20, 10, nil, nil, nil },
  } },
  { "Utûgi Shatterer", {
    { "Deafening Blast", "K", 30, 10, nil, nil, nil, nil, { "Explosión ensordecedora" } },
    { "Mesmerize", "K", 75, 12, nil, nil, nil, nil, { "Hipnotizar" } },
    { "Focused Mind", "K", 35, 5, { 1090553787 }, nil, nil, nil, { "Mente enfocada" } },
  } },
  { "Kormoltur, Lord of Terror", {
    { "Whisper of Blood", "AR", 30, 1, nil, { "i whisper and your blood boils", "susurro y tu sangre hierve" }, nil, nil, { "Susurro de sangre" } },
    { "Whisper of Steel", "C", 1, 0, nil, nil, nil, nil, { "Susurro de acero" } },
    { "Whisper of Iron", "C", 25, 12, nil, nil, nil, nil, { "Susurro de hierro" } },
    { "Whisper of Weakness", "AH", 30, 75, { 1091429132 }, nil, nil, nil, { "Susurro de debilidad" } },
  } },
  { "Utûgi Shatterer Warlord", {
    { "Deafening Blast", "K", 40, 10, nil, nil, nil, nil, { "Explosión ensordecedora" } },
    { "Mesmerize", "K", 75, 12, nil, nil, nil, nil, { "Hipnotizar" } },
    { "Focused Mind", "K", 35, 5, { 1090553787 }, nil, nil, nil, { "Mente enfocada" } },
    { "Tainted Blood", "S", 40, 45, { 1090529658 }, nil, nil },
  } },
  { "Utûgi Demolisher Warlord", {
    { "Sweep", "C", 7, 5, nil, nil, nil, nil, { "Barrido" } },
    { "Great Smash", "K", 5, 3, nil, nil, nil },
    { "Thresh the Chaff", "CK", 10, 5, nil, nil, nil, nil, { "Trillar la paja" } },
  } },
  { "Utûgi Bulwark Warlord", {
    { "Cleaving Strike", "C", 1, 0, nil, nil, nil, nil, { "Golpe de hendidura" } },
  } },
  { "Rumók the Blood-spiller", {
    { "Gash", "A", 15, 15, { 1090553355 }, nil, nil },
    { "Wound Splitter", "C", 20, 10, { 1090531635 }, nil, nil },
  } },
}
