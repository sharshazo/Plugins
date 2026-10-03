
import "Turbine.Class";
import "Turbine.Event";

--[[

A service container is a container the holds onto service maintaining a map
of service type to a service instance.

]]--

ServiceContainer = class();

function ServiceContainer:Constructor()
	self.services = { }
	
	-- Events that can be registered for.
	self.ServiceAdded = nil;
	self.ServiceRemoved = nil;
end

local function ResolveServiceType( serviceType )
	return serviceType.GetType():GetClass();
end

function ServiceContainer:HasService( serviceType )
	return ( self:GetService( serviceType ) ~= nil );
end

function ServiceContainer:GetService( serviceType )
	-- Don't allow nil service types.
	if ( serviceType == nil ) then
		error( "Service type must not be nil." );
	end

	-- Figure out what the actual type desired is. This allows a user to
	-- specify the class directly instead of having to do class.GetType().
	local type = ResolveServiceType( serviceType );

	if ( type == nil ) then
		error( "Invalid service type." );
	end

	return self.services[type];
end

function ServiceContainer:AddService( service, serviceType )
	if ( service == nil ) then
		Log:Warning( "Attempt to register a nil service." );
		return;
	end

	if ( not service:IsA( Turbine.Service ) ) then
		error( "Attempt to register something other than a service." );
	end

	-- If a service type was specified, use that as the type of service
	-- to register the service instance as, otherwise fall back to the
	-- actual type of the service supplied.
	local type = nil;

	-- If there is a service type specified, resolve the service type off of
	-- that, otherwise resolve the type off of the actual service instead.
	if ( serviceType ~= nil ) then
		type = ResolveServiceType( serviceType );
	else
		type = ResolveServiceType( service );
	end

	if ( type == nil ) then
		error( "Unable to determine the service type to register the service as." );
	end

	if ( self.services[type] ~= nil ) then
		error( "Attempt to register a duplicate service on a game control." );		
	end

	self.services[type] = service;

	self:OnServiceAdded( { Type = type, Service = service } );
end

function ServiceContainer:RemoveService( serviceOrServiceType )
	if ( serviceOrServiceType == nil ) then
		Log:Warning( "Attempt to unregister a nil service." );
		return;
	end

	-- Get the type of the argument.
	local type = Type.StaticGetType( serviceOrServiceType );

	-- And insure it's a class.
	if ( not type:IsClass() ) then
		error( "Argument must be a class instance." );
	end

	-- If the service type is a Type, use that for unregistering, otherwise
	-- resolve the service type from the object specified. This should handle
	-- both the case of an instance of a class and the class definition itself.
	local type = nil;

	if ( serviceOrServiceType:IsA( Type ) ) then
		type = serviceOrServiceType;
	else
		type = ResolveServiceType( serviceOrServiceType );
	end

	if ( type ~= nil ) then
		self.services[type] = nil;
		self:OnServiceRemoved( { Type = type } );
	end
end

function ServiceContainer:OnServiceAdded( args )
	Event.Fire( self.ServiceAdded, self, args );
end

function ServiceContainer:OnServiceRemoved( args )
	Event.Fire( self.ServiceRemoved, self, args );
end
