
import "Turbine";

Table = static_class();

local function DumpTable( t, indentation, seen )
	if ( t == nil ) then
		Turbine.Shell.WriteLine( indentation .. "(nil)" );
		return;
	end

	seen[t] = true

	local s= {}
	local n = 0

	for k in pairs( t ) do
		n = n + 1
		s[n] = k
	end

	table.sort( s, function( a, b ) return tostring( a ) < tostring( b ) end )
	
	for k,v in pairs(s) do
		Turbine.Shell.WriteLine( indentation .. tostring( k ) .. ": " .. tostring( v ) );

		v = t[v]

		if type( v ) == "table" and not seen[v] then
			DumpTable( v, indentation .. "  ", seen )
		end
	end
end

Table.Dump = function( t, indentation )
	local seen = { }
	DumpTable( t, indentation or "  ", seen );
end
