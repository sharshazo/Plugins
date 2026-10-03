
-- Create a math.round method since one does not exist.
_G.math.round = function( value )
	return math.floor( value + 0.5 );
end
