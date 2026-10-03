
import "Turbine";
import "Turbine.UI";
import "Turbine.UI.Lotro";

SimpleWindow = class( Turbine.UI.Window );

function SimpleWindow:Constructor()
	Turbine.UI.Window.Constructor( self );

	self:SetFadeSpeed( 0.2 );
	self:SetOpacity( 1 );
end

function SimpleWindow:SetFadeSpeed( value )
	self.fadeSpeed = 1 / value;
end

function SimpleWindow:SetVisible( value )
	if ( value == true ) then
		Turbine.UI.Window.SetOpacity( self, 0 );
		Turbine.UI.Window.SetVisible( self, true );
		self:SetOpacity( self.realOpacity );
	else
		self.hideOnClose = true;

		local savedOpacity = self.realOpacity
		self:SetOpacity( 0 );
		self.realOpacity = savedOpacity
	end
end

function SimpleWindow:SetOpacity( value )
	self.realOpacity = value;
	self.currentTime = Turbine.Engine.GetGameTime();
	self.currentOpacity = Turbine.UI.Window.GetOpacity( self );
	self.targetOpacity = value;
  
	if ( self.targetOpacity ~= self.currentOpacity ) then
		self:SetWantsUpdates( true );
	end
end

function SimpleWindow:Update( sender, args )
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
				Turbine.UI.Window.SetVisible( self, false );
				self.hideOnClose = false
			end
		end
	end

	self.currentOpacity = newOpacity;
	Turbine.UI.Window.SetOpacity( self, newOpacity );
end
