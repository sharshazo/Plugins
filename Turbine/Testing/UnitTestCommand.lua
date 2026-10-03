
import "Turbine";

UnitTestCommand = class( Turbine.ShellCommand );

function UnitTestCommand:Execute( command, arguments )
	local runner = ShellTestRunner();
	runner:SetVerbose( true );
	runner:RunUnitTestByName( arguments );
end

function UnitTestCommand:GetHelp()
	return "Executes a unit test.";
end

function UnitTestCommand:GetShortHelp()
	return "Executes a unit test.";
end
