
import "Turbine.Class";
import "Turbine.LogLevel";

-- This is just a static class with static methods only. Not using
-- the class function since I don't want this to be instantiatable.
Logger = class();

-- Initialize static constants for log colors.
function Logger:Constructor( name )
	self.name = name;

	self.logLevelColor = { };
	self.logLevelColor[LogLevel.Debug] = "FF00FF";
	self.logLevelColor[LogLevel.Information] = "99FFFF";
	self.logLevelColor[LogLevel.Error] = "FF0000";
	self.logLevelColor[LogLevel.Warning] = "FFFF00";

	self.level = LogLevel.Debug;

	self:SetFormat( "<rgb=#999999>(Script)</rgb> [%date] [%logger] %level: <rgb=#%color>%message</rgb>" );
end

function Logger:GetLevel()
	return self.level;
end

function Logger:SetLevel( value )
	self.level = value;
end

function Logger:GetFormat()
	return self.format;
end

function Logger:SetFormat( value )
	self.format = value;
	self.hasTimestamp = ( string.find( value, "%%date" ) ~= nil );
end

function Logger:FormatMessage( level, message )
	local formattedMessage = self.format;

	formattedMessage = string.gsub( formattedMessage, "%%logger", self.name );

	if ( self.hasTimestamp ) then
		formattedMessage = string.gsub( formattedMessage, "%%date", self:GetTimestamp() );
	end

	formattedMessage = string.gsub( formattedMessage, "%%color", self.logLevelColor[level] );
	formattedMessage = string.gsub( formattedMessage, "%%message", message );
	formattedMessage = string.gsub( formattedMessage, "%%level", LogLevel.ToString( level ) );

	return formattedMessage;
end

function Logger:Write( level, color, message )
	Turbine.Shell.WriteLine( self:FormatMessage( level, color, message ) );
end

function Logger:GetTimestamp()
	local timestring = "";
	local time = Turbine.Engine.GetDate();

	if ( time.Hour == 0 ) then
		time.Hour = 12;
	elseif ( time.Hour > 12 ) then
		time.Hour = time.Hour - 12;
	end

	if ( time.Hour < 10 ) then
		timestring = timestring .. "0";
	end
	
	timestring = timestring .. time.Hour .. ":";

	if ( time.Minute < 10 ) then
		timestring = timestring .. "0";
	end
	
	timestring = timestring .. time.Minute .. ":";

	if ( time.Second < 10 ) then
		timestring = timestring .. "0";
	end
	
	timestring = timestring .. time.Second;
	
	return timestring;
end

function Logger:Debug( message )
	if ( self.level <= LogLevel.Debug ) then
		self:Write( LogLevel.Debug, message );
	end
end

function Logger:Information( message )
	if ( self.level <= LogLevel.Information ) then
		self:Write( LogLevel.Information, message );
	end
end

function Logger:Warning( message )
	if ( self.level <= LogLevel.Warning ) then
		self:Write( LogLevel.Warning, message );
	end
end

function Logger:Error( message )
	if ( self.level <= LogLevel.Error ) then
		self:Write( LogLevel.Error, message );
	end
end
