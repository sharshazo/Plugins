
import "Turbine.Class";

_G.enum = function()
	local enumClass = static_class();

	-- List of elements to ignore in the enum class when performing
	-- translation of keys to values and back.
	local ignoreSet = { };

	enumClass.ParseString = function ( name )
		local k, v;

		for k, v in ipairs( enumClass ) do
			if ( ( ignoreSet[v] == nil ) and ( k == name ) ) then
				return v;
			end
		end

		error( "Unknown enumeration name." );
	end

	enumClass.ToString = function ( value )
		local k, v;

		for k, v in pairs( enumClass ) do
			if ( ( ignoreSet[v] == nil ) and ( v == value ) ) then
				return k;
			end
		end

		error( "Unknown enumeration value." );
	end

	ignoreSet[enumClass.ParseString] = 0;
	ignoreSet[enumClass.ToString] = 0;
	ignoreSet[enumClass.GetType] = 0;
	ignoreSet[enumClass.IsA] = 0;

	return enumClass;
end
