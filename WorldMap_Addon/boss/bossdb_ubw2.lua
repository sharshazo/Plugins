-- Generado desde BossCodex (Arebel) Data.lua -- no editar a mano.
-- skill = { nombre, etiquetas, reutilizacion, primer uso, induccion, iconos de efecto, gritos, area }
local DB = WorldMapAddon.BossDB
DB.inst["ubw2"] = {
  { "Sere Ritualist", {
    { "Ancient Fury", "I", 15, 5, 3, { 1091479052 }, nil, "Single Target" },
    { "Corrupted Earth", "I", 25, 10, 10, { 1091611526 }, nil, "Single Target" },
  } },
  { "Urâshi Archer", {
    { "Poisoned Dart", "ISP", 20, 0, 3, { 1090523646 }, nil, "Single Target" },
    { "Enraged Shot", "E", 3, 5, 1, { 1091401433, 1090522261 }, nil, "Single Target" },
  } },
  { "Sere Bowman", {
    { "Enraged Shot", "E", 3, 5, 1, { 1091401433, 1090522261 }, nil, "Single Target" },
  } },
  { "Utûgi Demolisher", {
    { "Sweep", "C", 7, 5, nil, nil, nil, "100° by 4.0m arc from Self" },
    { "Great Smash", "K", 5, 3, nil, nil, nil, "5.0m around Selection" },
    { "Thresh the Chaff", "CK", 10, 5, 3, nil, nil, "100° by 4.0m arc from Self" },
    { "Furious Smite", "T", 5, 5, nil, nil, nil, "Single Target" },
    { "a mighty swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a destructive swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a deadly swipe attack", "C", 0, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
  } },
  { "Urâshi Gut-slasher", {
    { "Brutal Strike", "T", 1, 0, nil, nil, nil, "Single Target" },
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Khablag", {
    { "Fresh Victim", "A", 30, 15, nil, nil, { "you cannot dodge my blade" }, "80.0m around Self" },
    { "Gather Strength", "A", 30, 15, nil, { 1091476413 }, { "you cannot dodge my blade" }, "80.0m around Self" },
    { "Thrust", "W", 1, 0, nil, { 1090531521 }, nil, "Single Target" },
    { "Heated Sweep", "C", 4, 2, nil, nil, nil, "120° by 5.5m arc from Self" },
  } },
  { "Urâshi Captain", {
    { "Blistering Derision", "I", 10, 10, 3, nil, nil, "Single Target" },
  } },
  { "Urâshi Berserker", {
    { "Jagged Cut", "CSW", 15, 0, nil, { 1090553355 }, nil, "120° by 4.5m arc from Self" },
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Sere Huntsman", {
    { "Enraged Shot", "E", 3, 5, 1, { 1091401433, 1090522261 }, nil, "Single Target" },
  } },
  { "Utûgi Hunter", {
    { "Jagged Arrow", "SW", 1, 0, 1, { 1090541187 }, nil, "Single Target" },
    { "Split Shot", "ISW", 10, 5, 3, { 1090553904 }, nil, "Single Target" },
  } },
  { "Urâshi Assassin", {
    { "Enraged Shot", "E", 3, 5, 1, { 1091401433, 1090522261 }, nil, "Single Target" },
  } },
  { "Sere Soldier", {
    { "Cruel Cut", "W", 20, 5, nil, { 1090580244 }, nil, "Single Target" },
  } },
  { "Sere Champion", {
    { "Cleave Foes", "C", 1, 0, nil, nil, nil, "120° by 4.5m arc from Self" },
    { "Barbed Arrow", "SW", 10, 8, 2, { 1090531521 }, nil, "Single Target" },
    { "Brutal Arrow", "K", 12, 8, 2, nil, nil, "Single Target" },
    { "Shadow Burst", "A", 10, 5, nil, nil, nil, "7.0m around Self" },
    { "a mighty swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a destructive swipe attack", "C", 2, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
    { "a deadly swipe attack", "C", 0, 0, nil, nil, nil, "120° by 3.0m arc from Self" },
  } },
  { "Daikhag", {
    { "Frenzied Axe", "C", 12, 10, nil, { 1090539333 }, nil, "120° by 5.5m arc from Self" },
    { "Dismissal", "R", 38, 22, nil, { 1090523949 }, { "away with you" }, "Single Target" },
    { "Axe Pummel", "C", 1, 0, nil, nil, nil, "120° by 5.5m arc from Self" },
    { "Not So Fast", "K", 10, 15, 2, nil, nil, "Single Target" },
    { "Weighted Axe-head", "CK", 30, 30, nil, nil, { "get away from me" }, "120° by 5.5m arc from Self" },
  } },
  { "Urâshi Blood-spiller", {
    { "Brutal Strike", "T", 1, 0, nil, nil, nil, "Single Target" },
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
  } },
  { "Sere Conjurer", {
    { "Tangled Shadow", "S", 15, 10, nil, { 1091429124 }, nil, "5.0m around Selection" },
    { "Death Grip", "K", 20, 10, nil, nil, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Utûgi Shatterer", {
    { "Deafening Blast", "K", 30, 10, nil, nil, nil, "Single Target" },
    { "Mesmerize", "K", 75, 12, 2, nil, nil, "Single Target" },
    { "Focused Mind", "K", 35, 5, nil, { 1090553787 }, nil, "Single Target" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Kormoltur, Lord of Terror", {
    { "Whisper of Blood", "AR", 30, 1, 6, nil, { "i whisper and your blood boi" }, "80.0m around Self" },
    { "Whisper of Steel", "C", 1, 0, nil, nil, nil, "120° by 5.5m arc from Self" },
    { "Whisper of Iron", "C", 25, 12, 2, nil, nil, "100° by 4.0m arc from Self with 180° offset" },
    { "Whisper of Weakness", "AH", 30, 75, nil, { 1091429132 }, nil, "80.0m around Self" },
  } },
  { "Utûgi Shatterer Warlord", {
    { "Deafening Blast", "K", 40, 10, nil, nil, nil, "Single Target" },
    { "Mesmerize", "K", 75, 12, 2, nil, nil, "Single Target" },
    { "Focused Mind", "K", 35, 5, nil, { 1090553787 }, nil, "Single Target" },
    { "Tainted Blood", "S", 40, 45, nil, { 1090529658 }, nil, "10.0m around Selection" },
    { "a minor tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a moderate tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a strong tactical attack", "C", 2, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
    { "a mighty tactical attack", "C", 0, 0, nil, nil, nil, "120° by 7.0m arc from Self | 12 max targets" },
  } },
  { "Utûgi Demolisher Warlord", {
    { "Sweep", "C", 7, 5, nil, nil, nil, "100° by 4.0m arc from Self" },
    { "Great Smash", "K", 5, 3, nil, nil, nil, "5.0m around Selection" },
    { "Thresh the Chaff", "CK", 10, 5, 3, nil, nil, "100° by 4.0m arc from Self" },
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
  } },
  { "Utûgi Bulwark Warlord", {
    { "Cleaving Strike", "C", 1, 0, nil, nil, nil, "100° by 4.0m arc from Self" },
  } },
  { "Rumók the Blood-spiller", {
    { "Gash", "A", 15, 15, 5, { 1090553355 }, nil, "5.0m around Self" },
    { "Wound Splitter", "C", 20, 10, nil, { 1090531635 }, nil, "100° by 4.0m arc from Self" },
    { "a weak swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a minor swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a moderate swipe attack", "C", 2, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
    { "a mighty swipe attack", "C", 0, 0, nil, nil, nil, "120° by 5.0m arc from Self" },
  } },
}
