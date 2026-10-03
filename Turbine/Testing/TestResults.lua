
import "Turbine";
import "Turbine.Testing";

TestResults = class();

function TestResults:Constructor()
	self.failures = { };
	self.errors = { };
	self.successes = { };
	self.inconclusives = { };
	self.totalTests = 0;
end

function TestResults:AddResult( unitTest, test, success, result )
	local fullTestName = unitTest:GetName() .. "." .. test;

	local newlinePosition = 0;
	
	if ( result ~= nil ) then
		newlinePosition = string.find( result, "\n" );
		
		if ( newlinePosition ~= nil ) then
			result = string.sub( result, newlinePosition + 1 );
		end
	end

	self.totalTests = self.totalTests + 1;

	if ( success ) then
		self.successes[fullTestName] = true;
		return;
	end

	if ( string.startsWith( result, "Assertion:" ) or string.startsWith( result, "Failure:" ) ) then
		self.failures[fullTestName] = result;
		return;
	end

	if ( string.startsWith( result, "Inconclusive:" ) ) then
		self.inconclusives[fullTestName] = result;
		return;
	end

	self.errors[fullTestName] = result;
end

function TestResults:GetTestCount()
	return self.totalTests;
end

function TestResults:GetFailures()
	return self.failures;
end

function TestResults:GetErrors()
	return self.errors;
end

function TestResults:GetSuccesses()
	return self.successes;
end

function TestResults:GetInconclusives()
	return self.inconclusives;
end
