
import "Turbine";
import "Turbine.Testing";

UnitTest = class();

-- A table to contain all of the unit test classes that have been created.
local unitTestRegistry = { };

---	Gets the full name of the unit test.
---
---	@returns
---		The full name of the unittest.
function UnitTest:GetName()
	return self:GetType():GetFullName();
end

---	Gets all of the unittest that have been loaded.
---
---	@returns
---		A table of the unit test names to the unit test class.
function UnitTest.GetUnitTests()
	return Table.Copy( unitTestRegistry );
end

---	Gets a unit test by its name. If there is no unit test this will
---	return nil.
---
---	@param name
---		The name of the unit test to get.
---
---	@returns
---		The unit test class if it was found otherwise nil.
function UnitTest.GetUnitTestByName( name )
	return unitTestRegistry[name];
end

---	Global function for creating unit tests.
_G.unittest = function()
	local unittest = class( UnitTest );
	
	-- The class is only partially initialized at this point. It has enough
	-- that I can use GetName to grab it's name and register it into the
	-- registry.
	local unitTestInstance = unittest();
	
	unitTestRegistry[unitTestInstance:GetName()] = unittest;

	return unittest;
end
