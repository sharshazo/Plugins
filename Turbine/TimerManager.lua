
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
	self.timerCount = self.timerCount - 1;

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

	local timer;
	local fireTime;

	for timer, fireTime in pairs( self.timers ) do
		if ( fireTime < gameTime ) then
			timer:OnTick( Table.Empty );
			self:UpdateTimer( timer );
		end
	end

	if ( Table.IsEmpty( self.timers ) ) then
		self.updateControl:SetWantsUpdates( false );
	end
end
