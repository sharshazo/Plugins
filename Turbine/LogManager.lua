
import "Turbine.Class";
import "Turbine.Logger";
import "Turbine.LogLevel";

-- This is just a static class with static methods only. Not using
-- the class function since I don't want this to be instantiatable.
LogManager = class();

-- Initialize static constants for log colors.
function LogManager:Constructor()
	self.loggers = { };
end

function LogManager.GetInstance()
	if ( LogManager.Instance == nil ) then
		LogManager.Instance = LogManager();
	end
	
	return LogManager.Instance;
end

function LogManager.GetLogger( name,x )
	local instance = LogManager:GetInstance();

	local logger = instance.loggers[name];

	if ( logger == nil ) then
		logger = instance:CreateLogger( name );
		instance.loggers[name] = logger;
	end

	return logger;
end

function LogManager:CreateLogger( name )
	return Logger( name );
end
