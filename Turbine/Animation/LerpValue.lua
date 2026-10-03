
import "Turbine";

LerpValue = class();

function LerpValue:Constructor()
	self.value = 0;
	self.target = 0;
	self.rate = 1;
end

function LerpValue:GetValue()
	return self.value;
end

function LerpValue:GetTargetValue()
	return self.target;
end

function LerpValue:SetValue( value )
	self.target = value;
end

function LerpValue:SetValueImmediate( value )
	self.value = value;
	self.target = value;
end

function LerpValue:GetRate()
	return rate;
end

function LerpValue:SetRate( rate )
	self.rate = rate;
end

function LerpValue:NeedsUpdate()
	return ( self.value ~= self.target );
end

function LerpValue:Update( delta )
	if ( self.value < self.target ) then
		self.value = self.value + self.rate * delta;

		if ( self.value > self.target ) then
			self.value = self.target;
		end
	elseif ( self.value > self.target ) then

		self.value = self.value - self.rate * delta;

		if ( self.value < self.target ) then
			self.value = self.target;
		end
	end
end