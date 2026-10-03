
import "Turbine.Class";

local EventMetatable;
local EventInfo;
local EventInstanceMetatable;

Event, EventMetatable, EventInfo, EventInstanceMetatable = class();

--[[

If event is a function, invokes the function with the passed arguments. If
event is a table, iterate through all the elements of the table and invoke
any functions with the passed arguments.

This event class simulates the logic used by the native packages for firing
events so it maintains a nice consistency with existing events.

]]--
function Event:Constructor()
	self.eventHandlers = { };
end

function Event:Add( eventHandler )
	self.eventHandlers[eventHandler] = eventHandler;
end

function Event:Remove( eventHandler )
	self.eventHandlers[eventHandler] = nil;
end

function Event.Fire( event, ... )
	local type = Type.StaticGetType( event );
	local eventHandlers = nil;

	if ( type:IsClass() and type:GetClass() == Event ) then
		eventHandlers = event.eventHandlers;
	elseif ( type:IsFunction() ) then
		eventHandlers = { event = event };
	elseif ( type:IsTable() ) then
		eventHandlers = event;
	end

	if ( eventHandlers ~= nil ) then	
		local k;
		local v;

		for k, v in pairs( eventHandlers ) do
			local subType = Type.StaticGetType( v );

			if ( subType:IsFunction() ) then
				v( ... );
			end
		end
	end
end

function EventInstanceMetatable.__call( self, ... )
	Event.Fire( self, ... );
end
