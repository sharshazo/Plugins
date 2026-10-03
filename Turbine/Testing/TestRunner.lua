
import "Turbine";
import "Turbine.Testing";

TestRunner = class();

local function GetTestUtilityMethod( class, name )
	local method = class[name];
	
	if ( type( method ) == "function" ) then
		return method;
	end
	
	return nil;
end

local function IsUnitTestMethod( memberName, member )
	return ( string.startsWith( memberName, "Test" ) ) and ( type( member ) == "function" );
end

function TestRunner:BeginUnitTestSet()
end

function TestRunner:EndUnitTestSet()
end

function TestRunner:BeginUnitTest( unitTest )
end

function TestRunner:EndUnitTest( unitTest )
end

function TestRunner:BeginTest( unitTest, test )
end

function TestRunner:EndTest( unitTest, test, success, result )
end

function TestRunner:RunUnitTestByName( name )
	local unitTestClass = UnitTest.GetUnitTestByName( name );

	return self:RunUnitTest( unitTestClass );
end

function TestRunner:RunUnitTest( unitTestClass )
	return self:RunUnitTestSet( { unitTestClass } );
end

function TestRunner:RunUnitTestSet( unitTestClasses )
	local testResults = TestResults();
	local class;
	local v;

	self:BeginUnitTestSet();

	for v, class in pairs( unitTestClasses ) do
		self:RunUnitTestHelper( class, testResults );
	end
	
	self:EndUnitTestSet( testResults );

	return testResults;
end

function TestRunner:RunUnitTestHelper( unitTestClass, testResults )
	if ( not unitTestClass ) then
		error( string.format( "Unable to load the unit test %q.", name ) );
	end

	local success, result = pcall(
		function()
			return unitTestClass();
		end
	);

	if ( not success ) then
		error( string.format( "Failed to load unit test %q\n%s.", name or "<unknown>", result ) );
	end

	local unitTest = result;

	local setupMethod = GetTestUtilityMethod( unitTest, "Setup" );
	local tearDownMethod = GetTestUtilityMethod( unitTest, "TearDown" );

	local memberName;
	local member;

	local currentClass = unitTest:GetType();

	self:BeginUnitTest( unitTest );

	while ( currentClass ~= nil ) do
		local class = currentClass:GetClass();

		if ( class ~= nil ) then
			for memberName, member in pairs( class ) do
				if ( IsUnitTestMethod( memberName, member ) ) then
					self:BeginTest( unitTest, memberName );

					local testSuccess = false;
					local testResult = false;
					local reported = false;

					success = true;

					-- Invoke the setup method if it is available.
					if ( setupMethod ~= nil ) then
						success, result = pcall(
							function()
								setupMethod( unitTest );
							end
						);

						if ( not success ) then
							testResults:AddResult( unitTest, memberName, false, string.format( "Test failed during Setup.\n%s", result ) );
							reported = true;
						end
					end

					-- Safely invoke the unit test method.
					if ( success ) then
						testSuccess, testResult = pcall(
							function()
								member( unitTest );
							end
						);
					end

					-- Invoke the teardown method if it is available.
					if ( tearDownMethod ~= nil ) then
						success, result = pcall(
							function()
								tearDownMethod( unitTest );
							end
						);

						if ( not success ) then
							testResults:AddResult( unitTest, memberName, false, string.format( "Test failed during TestDown.\n%s", result ) );
							reported = true;
						end
					end

					if ( not reported ) then
						testResults:AddResult( unitTest, memberName, testSuccess, testResult );
						success = testSuccess;
					end
					
					self:EndTest( unitTest, memberName, success, result );
				end
			end
		end

		local baseClass = currentClass:GetBaseClass();
		
		if ( baseClass ~= nil ) then
			currentClass = baseClass:GetType();
		else
			currentClass = nil;
		end
	end
	
	self:EndUnitTest( unitTest );
end
