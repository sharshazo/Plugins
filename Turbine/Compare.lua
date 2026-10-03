

Compare = static_class();

function Compare.AreEqual( first, second )
	local firstType = Type.StaticGetType( first );
	local secondType = Type.StaticGetType( second );

	if ( firstType ~= secondType ) then
		return false;
	end

	if ( firstType:IsTable() ) then
		return Table.AreEqual( first, second )
	end

	return ( first == second );
end

function Compare.AreNotEqual( first, second )
	return not Compare.AreEqual( first, second );
end

function Compare.AreSame( first, second )
	local firstType = Type.StaticGetType( first );
	local secondType = Type.StaticGetType(  second );

	if ( not firstType:IsReferenceType() or not secondType:IsReferenceType() ) then
		return false;
	end

	return ( first == second );
end

function Compare.AreNotSame( first, second )
	return not Compare.AreSame( first, second );
end

function Compare.IsFalse( value )
	return ( value == false );
end

function Compare.IsTrue( value )
	return ( value == true );
end

function Compare.IsNil( value )
	return ( value == nil );
end
