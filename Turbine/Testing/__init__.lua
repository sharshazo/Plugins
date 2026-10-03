
import "Turbine.Testing.Assert";
import "Turbine.Testing.ShellTestRunner";
import "Turbine.Testing.TestResults";
import "Turbine.Testing.TestRunner";
import "Turbine.Testing.UnitTest";
import "Turbine.Testing.UnitTestCommand";

unitTestCommand = UnitTestCommand();

Turbine.Shell.AddCommand( "unittest", unitTestCommand );
