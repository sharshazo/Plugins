
-- Static class. Not instantiatable.
Table = static_class();

Table.Empty = { };

local weakKeysMetaTable = { __mode = 'k' };
local weakValuesMetaTable = { __mode = 'v' };
local weakKeysAndValuesMetaTable = { __mode = 'kv' };

function Table.SetWeakKeys( table )
	setmetatable( table, weakKeysMetaTable );
end

function Table.SetWeakValues( table )
	setmetatable( table, weakValuesMetaTable );
end

function Table.SetWeakKeysAndValues( table )
	setmetatable( table, weakKeysAndValuesMetaTable );
end

function Table.IsEmpty( table )
	local k, v;
	local isEmpty = true;

	for k, v in pairs( table ) do
		isEmpty = false;
		break;
	end

	return isEmpty;
end

function Table.Print( table )
	local k, v;
	
	for k, v in pairs( table ) do
		Turbine.Shell.WriteLine( tostring( k ) .. ": " .. tostring( v ) );
	end
end

-- Code from http://lua-users.org/wiki/CopyTable for doing a deep copy
-- of a table.
function Table.Copy( object )
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local function CompareTableElements( first, second )
	-- Insure the two items are the same type.
	local firstValueType = Type.StaticGetType( firstValue );
	local secondValueType = Type.StaticGetType( secondValue );

	if ( firstValueType ~= secondValueType ) then
		return false;
	end

	-- If they are tables, perform a deep table compare.
	if ( firstValueType:IsTable() and not Table.Equal( firstValue, secondValue ) ) then
		return false;
	elseif ( firstValue ~= secondValue ) then
		return false;
	end
	
	return true;
end

function Table.AreEqual( first, second )
	local firstType = Type.StaticGetType( first );
	local secondType = Type.StaticGetType( second );

	if ( firstType ~= secondType ) then
		return false;
	end

	if ( not firstType:IsTable() ) then
		return false;
	end

	local key;
	local firstValue;
	local secondValue;

	local checked = {};

	-- Verify all the entries in the first table are in the second
	-- table and that their values match.
	for key, firstValue in pairs( first ) do
		checked[key] = true;
		secondValue = second[key];

		if ( not CompareTableElements( firstValue, secondValue ) ) then
			return false;
		end
	end

	-- Verify that all entries in the second table are in the first
	-- table with the same value.
	for key, secondValue in pairs( second ) do
		if ( not checked[key] ) then
			firstValue = first[key];

			if ( not CompareTableElements( firstValue, secondValue ) ) then
				return false;
			end
		end
	end

	return true;
end

--[[

Ordered pairs iterator.

]]--
function _G.opairs( t, sort )
	local sortedKeys = { };
	local index = 1;

	local key;

	-- Generate a temp table of keys.
	for key in pairs( t ) do
		sortedKeys[index] = key;
		index = index + 1;
	end

	local sorter = sort or function( a, b )
		return a < b
	end;

	-- Sort the keys.
	table.sort( sortedKeys, sorter );

	local current = 0;

	-- Return an iterator that will step over the sorted
	-- keys and return the key and value.
	return function()
		current = current + 1;
		if ( current < index ) then
			local key = sortedKeys[current];
			return key, t[key];
		end
	end
end
