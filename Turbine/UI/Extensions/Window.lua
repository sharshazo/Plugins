
import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";

Window = class( Turbine.UI.Lotro.GoldWindow );

function Window:Constructor()
	Turbine.UI.Lotro.GoldWindow.Constructor( self );

	self:SetFadeSpeed( 0.2 );
	self:SetOpacity( 1 );
end

function Window:SetFadeSpeed( value )
	self.fadeSpeed = 1 / value;
end

function Window:SetVisible( value )
	if ( value == true ) then
		Turbine.UI.Lotro.GoldWindow.SetOpacity( self, 0 );
		Turbine.UI.Lotro.GoldWindow.SetVisible( self, true );
		self:SetOpacity( self.realOpacity );
	else
		self.hideOnClose = true;

		local savedOpacity = self.realOpacity
		self:SetOpacity( 0 );
		self.realOpacity = savedOpacity
	end
end

function Window:SetOpacity( value )
	self.realOpacity = value;
	self.currentTime = Turbine.Engine.GetGameTime();
	self.currentOpacity = Turbine.UI.Lotro.GoldWindow.GetOpacity( self );
	self.targetOpacity = value;
  
	if ( self.targetOpacity ~= self.currentOpacity ) then
		self:SetWantsUpdates( true );
	end
end

function Window:Update( sender, args )
	local newOpacity;

	local now = Turbine.Engine.GetGameTime();
	local delta = now - self.currentTime;
	self.currentTime = now;

	delta = delta * self.fadeSpeed;

	if ( self.currentOpacity < self.targetOpacity ) then
		newOpacity = self.currentOpacity + delta;

		if ( newOpacity > self.targetOpacity ) then
			self:SetWantsUpdates( false )
			newOpacity = self.targetOpacity
		end
	else
		newOpacity = self.currentOpacity - delta;

		if ( newOpacity < self.targetOpacity ) then
			self:SetWantsUpdates( false )
			newOpacity = self.targetOpacity
			
			if ( self.hideOnClose ) then
				Turbine.UI.Lotro.GoldWindow.SetVisible( self, false );
				self.hideOnClose = false
			end
		end
	end

	self.currentOpacity = newOpacity;
	Turbine.UI.Lotro.GoldWindow.SetOpacity( self, newOpacity );
end
