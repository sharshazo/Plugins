
import "Turbine.Class";
import "Turbine.Type";

function _G.mixin( ... )
	local args = { ... };
	local i;
	local object;

	-- Mixins can only inherit from other mixins.
	if ( args ~= nil ) then
		for i, object in pairs( args ) do		
			local type = Type.StaticGetType( object );

			if ( type:IsMixin() ) then
				if ( type:IsFinal() ) then
					error( "Cannot extend a mixin that is final." );
				end
			elseif ( type:IsClass() ) then
				error( "A mixin cannot inherit from a class." );
			else
				error( "Invalid base mixin specified in mixin declaration." );
			end
		end
	end

	local mixin, mixinMetaTable, mixinInfo = static_class( ... );
	mixinInfo.Static = nil;
	mixinInfo.Mixin = true;
	mixinInfo.Class = nil;

	return mixin, mixinMetaTable, mixinInfo;
end
