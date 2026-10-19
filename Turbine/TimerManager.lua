
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
	self.timer_versions = { };
	Table.SetWeakKeys( self.timer_versions );
	self.schedule_revision = 0;
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
	self.schedule_revision = self.schedule_revision + 1;
	self.timer_versions[timer] = self.schedule_revision;
	self.updateControl:SetWantsUpdates( true );
end

function TimerManager:RemoveTimer( timer )
	if ( self.timers[timer] == nil ) then
		error( "Timer is not managed by this manager." );
	end

	self.timers[timer] = nil;
	self.timer_versions[timer] = nil;
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
	self.schedule_revision = self.schedule_revision + 1;
	self.timer_versions[timer] = self.schedule_revision;
end

function TimerManager:ProcessTimers()
	local gameTime = Turbine.Engine.GetGameTime();

	-- 2026-10-18 (TUR-02): the due timers are collected first (a Tick may
	-- add or remove timers) and a timer is only rescheduled if it is still
	-- managed here after its own Tick (it may have disabled itself).
	local due = { };
	for timer, fireTime in pairs( self.timers ) do
		if ( fireTime < gameTime ) then
			table.insert( due, { timer = timer, fire_time = fireTime, version = self.timer_versions[timer] } );
		end
	end

	for _, scheduled in ipairs( due ) do
		local timer = scheduled.timer;
		-- Another callback may explicitly move, disable or reschedule this timer.
		if ( self.timers[timer] == scheduled.fire_time and self.timer_versions[timer] == scheduled.version ) then
			local ok, err = pcall( function() timer:OnTick( Table.Empty ); end );
			if ( not ok ) then
				-- Disable only this timer; other due callbacks must still run.
				if ( type( timer.SetEnabled ) == "function" ) then
					pcall( timer.SetEnabled, timer, false );
				end
				self.timers[timer] = nil;
				self.timer_versions[timer] = nil;
				if ( Turbine.Shell ~= nil and type( Turbine.Shell.WriteLine ) == "function" ) then
					Turbine.Shell.WriteLine( "Timer disabled after callback error: " .. tostring( err ) );
				end
			elseif ( self.timers[timer] == scheduled.fire_time and self.timer_versions[timer] == scheduled.version ) then
				self:UpdateTimer( timer );
			end
		end
	end

	if ( Table.IsEmpty( self.timers ) ) then
		self.updateControl:SetWantsUpdates( false );
	end
end
