
function _G.string.startsWith( value, test )
   return ( string.sub( value, 1, string.len( test ) ) == test );
end

function _G.string.endsWith( value, test )
   return ( test == "" ) or ( string.sub( value, -string.len( test ) ) == test );
end

function _G.string.trim( value )
  return string.gsub( value, "^%s*(.-)%s*$", "%1" );
end
