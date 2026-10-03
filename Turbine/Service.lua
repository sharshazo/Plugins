
import "Turbine.Class";

--[[

A service is any class that provides general purpose functionality. Typically
these are used with a service container which is then queried to retrieve a
specific type of service.

]]--

Service = class();

function Service:Constructor()
	-- Placeholder.
end

function Service:GetName()
	return "<Unknown>";
end
