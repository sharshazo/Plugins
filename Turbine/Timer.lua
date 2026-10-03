
import "Turbine.Class";
import "Turbine.Event";
import "Turbine.TimerManager";

Timer = class();

Timer.DefaultManager = TimerManager.GetInstance();
Timer.DefaultInterval = 1000;
Timer.DefaultEnabledState = false;

--[[

Creates a new timer that can be used to fire events at regular intervals. The
valid parameters for this class constructor are:

	manager, interval, enabled
	manager, interval
	manager, enabled
	interval, enabled
	enabled

If a manager is not specified, the default TimerManager will be used.

If an interval is not specified, the default is 1 second.

If enabled is not specified, the default is to not be enabled.

]]--
function Timer:Constructor( a, b, c )
	local aType = Type.StaticGetType( a );
	local bType = Type.StaticGetType( b );
	local cType = Type.StaticGetType( c );

	-- Initialize some defaults.
	self.manager = Timer.DefaultManager;
	self.interval = Timer.DefaultInterval;
	
	-- This is explicitly set to false because a call to SetEnabled is necessary
	-- to register it with the manager that will fire it.
	self.enabled = false;

	-- The first parameter can be a manager to manager the timer.
	if ( aType:IsClass() and a:IsA( TimerManager ) ) then
		self:SetManager( a );

		a = b;
		aType = bType;
		b = c;
		bType = cType;
	end

	-- The second parameter can be an interval.
	if ( aType:IsNumber() ) then
		self:SetInterval( a );

		a = b;
		aType = bType;
	end

	-- And the last an enabled state.
	if ( aType:IsBoolean() ) then
		self:SetEnabled( a );
	else
		self:SetEnabled( Timer.DefaultEnabledState );
	end
end

function Timer:IsEnabled()
	return self.enabled;
end

function Timer:SetEnabled( value )
	if ( self.enabled ~= value ) then
		self.enabled = value;

		if ( self.enabled ) then
			self.manager:AddTimer( self );
		else
			self.manager:RemoveTimer( self );
		end
	end
end

function Timer:GetInterval()
	return self.interval;
end

function Timer:SetInterval( value )
	if ( self.interval ~= value ) then
		self.interval = value;

		if ( self.enabled ) then
			self.manager:UpdateTimer( self );
		end
	end
end

function Timer:GetManager()
	return self.manager;
end

function Timer:SetManager( value )
	if ( self.manager ~= value ) then
		if ( self.enabled and ( self.manager ~= nil ) ) then
			self.manager:RemoveTimer( self );
		end

		self.manager = value;

		if ( self.enabled and ( self.manager ~= nil ) ) then
			self.manager:AddTimer( self );
		end
	end
end

function Timer:OnTick( args )
	Event.Fire( self.Tick, self, args );
end
