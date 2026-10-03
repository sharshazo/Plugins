
import "Turbine.Class";

Debug = final_class();

local oldError = _G.error;

_G.error = function( message )
	if ( Turbine.Engine.GetCallStack ~= nil ) then
		oldError( Turbine.Engine.GetCallStack( message ) );
	else
		oldError( message );
	end
end
