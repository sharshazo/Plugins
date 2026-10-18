
import "Turbine.Class";
import "Turbine.UI";
import "Turbine.Table";

TimerManager = class();

TimerManager.Instance = nil;

function TimerManager:Constructor()
	self.updateControl = Turbine.UI.Control();
	
	self.updateControl.Update = function( sender, args )
		self:ProcessTimers();
	end

	self.timers = { };
	Table.SetWeakKeys( self.timers );
end

function TimerManager.GetInstance()
	if ( TimerManager.Instance == nil ) then
		TimerManager.Instance = TimerManager();
	end

	return TimerManager.Instance;
end

function TimerManager:AddTimer( timer )
	if ( timer == nil ) then
		error( "Timer cannot be nil." );
	end

	if ( self.timers[timer] ~= nil ) then
		error( "Timer is already being managed by this manager" );
	end

	-- Calculate when the timer needs to fire.
	local nextFireTime = Turbine.Engine.GetGameTime() + ( timer:GetInterval() / 1000 );
	self.timers[timer] = nextFireTime;
	self.updateControl:SetWantsUpdates( true );
end

function TimerManager:RemoveTimer( timer )
	if ( self.timers[timer] == nil ) then
		error( "Timer is not managed by this manager." );
	end

	self.timers[timer] = nil;
	-- 2026-10-18 (TUR-01): "timerCount" was never set nor used; removing a
	-- timer failed here halfway. The empty check below is enough.

	if ( Table.IsEmpty( self.timers ) ) then
		self.updateControl:SetWantsUpdates( false );
	end
end

function TimerManager:UpdateTimer( timer )
	if ( self.timers[timer] == nil ) then
		error( "Timer is not managed by this manager." );
	end

	-- When updating the count of timers won't change so the set wants updates
	-- state does not need to change.
	local nextFireTime = Turbine.Engine.GetGameTime() + ( timer:GetInterval() / 1000 );
	self.timers[timer] = nextFireTime;
end

function TimerManager:ProcessTimers()
	local gameTime = Turbine.Engine.GetGameTime();

	-- 2026-10-18 (TUR-02): the due timers are collected first (a Tick may
	-- add or remove timers) and a timer is only rescheduled if it is still
	-- managed here after its own Tick (it may have disabled itself).
	local due = { };
	for timer, fireTime in pairs( self.timers ) do
		if ( fireTime < gameTime ) then
			table.insert( due, timer );
		end
	end

	for _, timer in ipairs( due ) do
		if ( self.timers[timer] ~= nil ) then
			local ok, err = pcall( function() timer:OnTick( Table.Empty ); end );
			if ( not ok ) then
				-- Disable only this timer; other due callbacks must still run.
				if ( type( timer.SetEnabled ) == "function" ) then
					pcall( timer.SetEnabled, timer, false );
				end
				self.timers[timer] = nil;
				if ( Turbine.Shell ~= nil and type( Turbine.Shell.WriteLine ) == "function" ) then
					Turbine.Shell.WriteLine( "Timer disabled after callback error: " .. tostring( err ) );
				end
			elseif ( self.timers[timer] ~= nil ) then
				self:UpdateTimer( timer );
			end
		end
	end

	if ( Table.IsEmpty( self.timers ) ) then
		self.updateControl:SetWantsUpdates( false );
	end
end
