
import "Turbine.Testing";
import "Turbine.Testing.TestRunner";

ShellTestRunner = class( TestRunner );

function ShellTestRunner:Constructor()
	self.verbose = false;
end

function ShellTestRunner:SetVerbose( value )
	self.verbose = value;
end

function ShellTestRunner:BeginUnitTestSet()
end

function ShellTestRunner:EndUnitTestSet( results )
	if ( results:GetTestCount() == 0 ) then
		Turbine.Shell.WriteLine( "No test ran." );
		return;
	end

	if ( not self.verbose ) then
		Turbine.Shell.WriteLine( " " );
	end

	Turbine.Shell.WriteLine( "<rgb=#AAAAFF>Results:</rgb>" );
	
	local allResults = { };
	local test;
	local result;
	local v;

	local failures = results:GetFailures();
	local errors = results:GetErrors();
	local inconclusives = results:GetInconclusives();
	local errorCount = 0;

	for test, result in pairs( failures ) do
		allResults[test] = 1;
		errorCount = errorCount + 1;
	end

	for test, result in pairs( errors ) do
		allResults[test] = 1;
		errorCount = errorCount + 1;
	end

	for test, result in pairs( inconclusives ) do
		allResults[test] = 1;
		errorCount = errorCount + 1;
	end

	if ( errorCount == 0 ) then
		Turbine.Shell.WriteLine( "  <rgb=#99FF99>All test completed successfully.</rgb>" );
	else
		for test, v in opairs( allResults ) do
			if ( failures[test] ~= nil ) then
				Turbine.Shell.WriteLine( string.format( "<rgb=#FF9999>Failure: %s:</rgb>\n%s\n\n", test, failures[test] ) );
			elseif ( errors[test] ~= nil ) then
				Turbine.Shell.WriteLine( string.format( "<rgb=#FF9999>Error: %s:</rgb>\n%s\n\n", test, errors[test] ) );
			elseif ( inconclusives[test] ~= nil ) then
				Turbine.Shell.WriteLine( string.format( "<rgb=#FFFF99>Inconclusive: %s:</rgb>\n%s\n\n", test, inconclusives[test] ) );
			end
		end
	end
end

function ShellTestRunner:BeginUnitTest( unitTest )	
	Turbine.Shell.WriteLine( "<rgb=#AAAAFF>Executing " .. unitTest:GetName() .. ":</rgb>" );
	self.currentTestString = "<rgb=#FFFFFF>  ";
end

function ShellTestRunner:EndUnitTest( unitTest )
	Turbine.Shell.WriteLine( self.currentTestString .. "</rgb>" );
end

function ShellTestRunner:BeginTest( unitTest, test )
end

function ShellTestRunner:EndTest( unitTest, test, success, result )
	if ( self.verbose ) then
		if ( success ) then
			Turbine.Shell.WriteLine( "  <rgb=#FFFFFF>[<rgb=#99FF99>Pass</rgb>] " .. test .. "</rgb>" );
		else
			Turbine.Shell.WriteLine( "  <rgb=#FFFFFF>[<rgb=#FF9999>Fail</rgb>] " .. test .. "</rgb>" );
		end
	else
		self.currentTestString = self.currentTestString .. ".";

		if ( not success ) then
			self.currentTestString = self.currentTestString .. "F";
		end
	end
end
