-- 2026-10-18 (PVMP-01): the timestamps are "seconds of the year" (no
-- year). Right after New Year "now" restarts at 0, so an entry from the end
-- of December gives a negative difference; it is the previous year, so the
-- length of that year is added back. Used by GetRecentData and
-- DeleteObsoleteData.
function GetAgeSeconds(now, timestamp)
	local dif = now - (tonumber(timestamp) or now)
	if dif < 0 then
		local year = Turbine.Engine.GetDate().Year
		dif = dif + GetDaysPerYear(year - 1) * 86400
	end
	return dif
end

function GetRecentData(input)
	local now = GetSecondsOfYear()
	local last_10_minutes = 0
	local last_hour = 0
	local last_24_hours = 0

	for i, j in pairs(input) do
		local dif = GetAgeSeconds(now, i)
		if (dif <= 86400 and dif >= 0) then
			last_24_hours = last_24_hours + j
			if (dif <= 3600) then
				last_hour = last_hour + j
				if (dif <= 600) then
					last_10_minutes = last_10_minutes + j
				end
			end
		end
	end
	return FormatPoints(last_24_hours), FormatPoints(last_hour), FormatPoints(last_10_minutes)
end

function GetDaysPerYear(year)
	local days_per_year = 365
	if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
		days_per_year = 366
	end
	return days_per_year
end

function GetDaysPerMonth(month, year)
	if month == 4 or month == 6 or month == 9 or month == 11 then
		return 30
	elseif month == 2 then
		if GetDaysPerYear(year) == 366 then
			return 29
		else
			return 28
		end
	else
		return 31
	end
end

function GetSecondsOfYear()
	local timestamp = Turbine.Engine.GetDate()
	return (timestamp.DayOfYear - 1) * 86400 + timestamp.Hour * 3600 + timestamp.Minute * 60 + timestamp.Second
end

function GetRemainingPoints()
	for i = 0, #Ranks - 1 do
		if (data.numbers.points_total >= Ranks[i] and data.numbers.points_total < Ranks[i + 1]) then
			return Ranks[i + 1] - data.numbers.points_total
		end
	end
	return 0
end

function GetRemainingFrags()
	for j = 0, #Tiers - 1 do
		if (data.numbers.frags_total >= Tiers[j] and data.numbers.frags_total < Tiers[j + 1]) then
			return Tiers[j + 1] - data.numbers.frags_total
		end
	end
	return 0
end

function FormatPoints(points)
	local left, middle, right = string.match(tostring(points), '([^%d]*%d)(%d*)(,-)')
	return left .. (middle:reverse():gsub('(%d%d%d)','%1%.'):reverse()) .. right
end

function Round(number)
	local decimals = 1
	local mult = 10 ^ (decimals or 0)
	return math.floor(number * mult + 0.5) / mult
end

function ThresholdRound(value, threshold)
	return math.floor(value / threshold) * threshold
end

function FindIndex(tbl, val)
	for index, value in pairs(tbl) do
		if value == val then
			return index
		end
	end
end

function SetContains(set, key)
	return set[key]
end