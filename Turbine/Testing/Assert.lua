
--- This class provides static methods for evaluating the truth of
--- various conditions and on failure will raise errors with information
--- about the failures.
Assert = static_class();

--- Raises an error with a specific type and user message. This method
--- removes all stack frames related to the generation of the error in
--- the actual error raised.
---
--- @param type
---		The type of the error.
---
--- @param userMessage
---		An optional message provided by the user to be included in the
---		message.
---
---	@param assert
---		The assertion message to be included.	
local function RaiseError( type, userMessage, assert )
	local fullMessage = "\n" .. type .. ":";
	
	if ( userMessage ) then
		fullMessage = fullMessage .. " " .. userMessage;
	end
	
	if ( assert ) then
		if ( userMessage ) then
			fullMessage = fullMessage .. "\n";
		end

		fullMessage = fullMessage .. " " .. assert;
	end
	
	error( Turbine.Engine.GetCallStack( fullMessage, 4 ) );
end

---	Compares two objects. If they are not equal and error will be raised.
---
---	@param first
---		The first object to compare.
---
---	@param second
---		The second object to compare.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.AreEqual( first, second, message )
	if ( not Turbine.Compare.AreEqual( first, second ) ) then
		RaiseError( "Assertion", message, string.format( "Expected equal values. (First: %q, Second: %q)", tostring( first ), tostring( second ) ) );
	end
end

---	Compares two objects. If they are equal and error will be raised.
---
---	@param first
---		The first object to compare.
---
---	@param second
---		The second object to compare.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.AreNotEqual( first, second, message )
	if ( not Turbine.Compare.AreNotEqual( first, second ) ) then
		RaiseError( "Assertion", message, string.format( "Expected unequal values. (First: %q, Second: %q)", tostring( first ), tostring( second ) ) );
	end
end

---	Compares two objects. If they are reference types (thread, userdata,
---	coroutine, table) and they do not refer to the same object, an error
--- is raised.
---
---	@param first
---		The first object to compare.
---
---	@param second
---		The second object to compare.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.AreSame( first, second, message )
	if ( not Turbine.Compare.AreSame( first, second ) ) then
		RaiseError( "Assertion", message, string.format( "Expected same values. (First: %q, Second: %q)", tostring( first ), tostring( second ) ) );
	end
end

---	Compares two objects. If the two objects refer to the same object, an error
--- is raised.
---
---	@param first
---		The first object to compare.
---
---	@param second
---		The second object to compare.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.AreNotSame( first, second, message )
	if ( not Turbine.Compare.AreNotSame( first, second ) ) then
		RaiseError( "Assertion", message, string.format( "Expected values that are not the same. (First: %q, Second: %q)", tostring( first ), tostring( second ) ) );
	end
end

--- Raises a failure.
function Assert.Fail( message )
	RaiseError( "Failure", message );
end

--- Raises an inconclusive assert.
function Assert.Inconclusive( message )
	RaiseError( "Inconclusive", message );
end

--- Raises an error if the value is not false.
---
---	@param value
---		The value to test for being false.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.IsFalse( value, message )
	if ( not Turbine.Compare.IsFalse( value ) ) then
		RaiseError( "Assertion", message, string.format( "Expected false value. (Value: %q)\n", tostring( value ) ) );
	end
end

--- Raises an error if the value is not true.
---
---	@param value
---		The value to test for being true.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.IsTrue( value, message )
	if ( not Turbine.Compare.IsTrue( value ) ) then
		RaiseError( "Assertion", message, string.format( "Expected true value. (Value: %q)\n", tostring( value ) ) );
	end
end

--- Raises an error if the value is not nil.
---
---	@param value
---		The value to test for being nil.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.IsNil( value, message )
	if ( not Turbine.Compare.IsNil( value ) ) then
		RaiseError( "Assertion", message, string.format( "Expected nil value. (Value: %q)\n", tostring( value ) ) );
	end
end

--- Raises an error if the value is nil.
---
---	@param value
---		The value to test for being nil.
---
---	@param message
---		An optional message to include in the assertion.
function Assert.IsNotNil( value, message )
	if ( Turbine.Compare.IsNil( value ) ) then
		RaiseError( "Assertion", message, string.format( "Expected a non-nil value. (Value: %q)\n", tostring( value ) ) );
	end
end