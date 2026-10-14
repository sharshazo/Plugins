-- Español (interfaz). Se carga DESPUES de en.lua: solo cambia los textos
-- que ve el jugador. Los patrones del chat, nombres de mejoras, fortalezas,
-- rangos y PNJ siguen en ingles porque el juego los envia en ingles.

local isCreep = (L.InfamyRenown == "Infamy")
L.InfamyRenown = isCreep and "Infamia" or "Renombre"
L.Battle_Task_Message = isCreep and "¡Consigue una Tarea de batalla, gusano!" or "¡Reclama una Tarea de batalla!"

if type(L.Chat_Channels) == "table" then
	local names = { "Decir", "Grupo", "Banda", "Hermandad", "Fuera de rol" }
	for i, ch in ipairs(L.Chat_Channels) do
		if type(ch) == "table" then
			if names[i] ~= nil then
				ch[2] = names[i]
			elseif i >= 6 then
				ch[2] = "Canal de usuario " .. (i - 5)
			end
		end
	end
end

L.Months = {
	[1] = "Ene", [2] = "Feb", [3] = "Mar", [4] = "Abr", [5] = "May", [6] = "Jun",
	[7] = "Jul", [8] = "Ago", [9] = "Sep", [10] = "Oct", [11] = "Nov", [12] = "Dic"
}

L.Init_Points = "Escribe tu total de " .. L.InfamyRenown .. ":"
L.Init_Frags = "Escribe tu total de golpes mortales:"
L.Init_Invalid_Input = "¡Valor no válido!"

L.Window_Confirm = "Aceptar"
L.Window_Save = "Guardar"
L.Window_Cancel = "Cancelar"

L.Stats_Bonus = "Bonificación: "
L.Stats_Total_Points = L.InfamyRenown .. " total: "
L.Stats_Remaining_Points = L.InfamyRenown .. " para subir de rango: "
L.Stats_Total_Points_Short = L.InfamyRenown .. ": "
L.Stats_Remaining_Points_Short = "Subir rango: "

L.Menu = { "Total", "Subir rango", "Mes", "Día", "Hora", "10 min", "Combate" }
L.Stats_Points_Type = "Mi " .. L.InfamyRenown .. ": "
L.Stats_Total = "Total: "
L.Stats_Current = "Actual: "
L.Stats_To_RankUp = "Para subir de rango: "
L.Stats_To_TierUp = "Para subir de nivel: "

L.Stats_Last_Year = "último año"
L.Stats_Last_Month = "último mes"
L.Stats_Last_24h = "Últimas 24 horas: "
L.Stats_Today = "Hoy: "

L.Stats_Current_Month = "Este mes: "
L.Stats_Current_Day = "Hoy: "
L.Stats_Last_Hour = "Última hora: "
L.Stats_Last_10min = "Últimos 10 min: "
L.Stats_Last_Fight = "Último combate: "
L.Stats_Current_Month_Short = "Mes: "
L.Stats_Current_Day_Short = "Día: "
L.Stats_Last_Hour_Short = "Hora: "
L.Stats_Last_10min_Short = "10 min: "
L.Stats_Last_Fight_Short = "Combate: "

L.Statistics_Header = "Estadísticas"
L.Progress_Header = "Progreso"
L.Stats_Rank = "Rango "
L.Stats_Tier = "Nivel "
L.Commendations_Header = "Menciones"
L.KillingBlows_Header = "Golpes mortales"
L.Deaths_Header = "Muertes"
L.Tracks_Header = "Rastreos"

L.Tab_Statistics = "Estadísticas del personaje"
L.Tab_Log = "Registro de golpes mortales"
L.Tab_Points = "Estadísticas de " .. L.InfamyRenown
L.Tab_Commendations = "Estadísticas de menciones"
L.Tab_Killing_Blows = "Estadísticas de golpes mortales"
L.Tab_Deaths = "Estadísticas de muertes"
L.Tab_Tracks = "Estadísticas de rastreos"

L.Log_Search = "Buscar: "
L.Log_Name = "Nombre"
L.Log_KillingBlows = "Bajas"

L.Stats_Maximum_Kill = "Máximo por baja: "
L.Stats_Maximum_Day = "Máximo en un día: "
L.Stats_Maximum_Month = "Máximo en un mes: "
L.Stats_Points_Per_KillingBlow = L.InfamyRenown .. " por golpe mortal: "
L.Stats_KillingBlows_Per_Death = "Golpes mortales por muerte: "

L.Recent_Hits_Header = "Golpes recientes"
L.Recent_Hits_Link_Count = "Enviar recuento"
L.Recent_Hits_Amount = "Cantidad"

L.Recent_Kills_Header = "Últimas 5 bajas"
L.String_Loc = "Pos"
L.String_Send = "Enviar"
L.Map_Show = "Mostrar mapa"
L.Map_Hide = "Ocultar mapa"
L.Get_Own_Position = "Mostrar mi posición"

L.Options_Header = "Opciones"
L.Options_Data_Settings = "Datos"
L.Options_Update_Points = "Fijar " .. L.InfamyRenown
L.Options_Update_Frags = "Fijar golpes mortales"
L.Options_Display_Settings = "Pantalla"
L.Options_Show_Stats = "Mostrar estadísticas"
L.Options_Bonus = "Mostrar multiplicador %"
L.Options_OPs = "Mostrar puestos"
L.Options_Keeps = "Mostrar fortalezas"
L.Options_DOF = "Mostrar mejoras DoF"
L.Options_Relic = "Mostrar reliquias"
L.Options_ON = "Mostrar mejora ON"
L.Options_Alert_Settings = "Avisos"
L.Options_Track_Warning = "Aviso de rastreo"
L.Options_StealthAlert = "Aviso de sigilo"
L.Options_YourFragAlert = "Aviso de golpe mortal"
L.Options_LootboxAlert = "Aviso de cofre"
L.Options_Commendation_Warning = "Aviso de menciones"
L.Options_Battle_Task_Warning = "Aviso de tarea de batalla"
L.Options_Other_Windows_Settings = "Ventanas secundarias"
L.Options_Recent_Kills = "Ventana de últimas bajas"
L.Options_Recent_Hits = "Ventana de golpes recientes"
L.Options_Other_Settings = "Otros"
L.Options_Daily_Reset_Time = "Hora de reinicio diario"
L.Options_Window_Size = "Tamaño de la barra"
L.Options_Reset = "Restablecer opciones"
L.Options_Reset_Header = "Restablecer"
L.Options_Reset_Warning = "¡Atención!"
L.Options_Reset_Warning_Text = "Al pulsar " .. L.Window_Confirm .. " todas las opciones volverán a sus valores por defecto.\n\n¿Seguro que quieres restablecer las opciones?"
L.Options_Open_Settings = "Abrir opciones"
L.Strings_Points_Out_Of_Sync = "Datos desincronizados:\nvuelve a escribir tu total de " .. L.InfamyRenown
L.Strings_Frags_Out_Of_Sync = "Datos desincronizados:\nvuelve a escribir tu total de golpes mortales"

L.DragBar_Alert = "PvMP+ Avisos"
L.DragBar_Battle_Task = "PvMP+ Tarea de batalla"
L.DragBar_Recent_Hits_Window = "PvMP+ Golpes recientes"
L.DragBar_Secondary_Window = "PvMP+ Últimas bajas"
L.DragBar_Map = "PvMP+ Mapa"

L.Command_Help = "Opciones: /pvmp+ opciones | Mapa: /pvmp+ mapa | Idioma: /pvmp+ idioma es|en | Gaergoth: /pvmp+ gaergoth muerto|activo | Asedios: /pvmp+ asedios | Auras: /pvmp+ auras on|off"
L.Command_Settings = "opciones"
L.Command_Map = "mapa"

L.YourFrag_Message_Start = "Tu golpe mortal derriba a "

-- textos de los avisos (el patron del chat sigue en ingles)
L.Alert_Tracked = "Sientes que alguien te sigue..."
L.Alert_Stealth_Nearby = "Hay un enemigo oculto cerca."
L.Alert_Stealth_Spotted = "Has descubierto a un enemigo en sigilo."

L.Boss_Respawn = "Reaparece en "
L.Boss_Ready = "¡Disponible!"
L.Boss_Active = "¡ACTIVO!"
L.Boss_Active_Alert = "¡Gaergoth the Unbound está activo!"
L.Boss_Killed_Alert = "Gaergoth derrotado: reaparece en 1 hora"
L.Boss_Ready_Alert = "¡Gaergoth the Unbound ya está disponible!"

L.Siege_Title = "Asedios"
L.Siege_Alert = "¡Están tomando %s!"
L.Siege_Taken = "¡%s ha sido tomada!"
L.Help_Alert = "¡%s pide ayuda!"
L.Help_Click = "Clic: ver en el mapa  |  clic der.: cerrar"

L.Options_Language = "Idioma: Español (clic: English)"
L.Language_Changed = "PvMP+: idioma cambiado. Recargando..."
