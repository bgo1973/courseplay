-- DEBUG CHANNELS
courseplay.numAvailableDebugChannels = 24;
courseplay.numDebugChannels = 20;
courseplay.numDebugChannelButtonsPerLine = 12;
courseplay.numDebugChannelSections = math.ceil(courseplay.numAvailableDebugChannels / courseplay.numDebugChannelButtonsPerLine);
courseplay.debugChannelSection = 1;
courseplay.debugChannelSectionStart = 1;
courseplay.debugChannelSectionEnd = courseplay.numDebugChannelButtonsPerLine;
courseplay.debugChannels = {};
for channel=1, courseplay.numAvailableDebugChannels do
	courseplay.debugChannels[channel] = false;
end;
--[[
Debug channels legend:
 1	Raycast (drive + tipTriggers)
 2	unload_tippers
 3	traffic collision
 4	Combines/mode2, register and unload combines
 5	Multiplayer
 6	implements (updateWorkTools etc)
 7	course generation
 8	course management
 9	path finding
10	mode9
11	mode7
12	all other debugs (uncategorized)
13	reverse
14	EifokLiquidManure
15	mode3 (AugerWagon)
16	recording
17	mode4/6
18	hud action
19	special triggers
20	WeightStation
--]]

--------------------------------------------------

-- GENERAL DEBUG
function courseplay:debug(str, channel)
	if channel ~= nil and courseplay.debugChannels[channel] ~= nil and courseplay.debugChannels[channel] == true then
		print('[dbg' .. tostring(channel) .. ' lp' .. g_updateLoopIndex .. '] ' .. str);
	end;
end;

local lines = {
	('-'):rep(50),
	('_'):rep(50),
	('#'):rep(50)
};
function cpPrintLine(debugChannel, line)
	if debugChannel == nil or courseplay.debugChannels[debugChannel] then
		line = line or 1;
		print(lines[line]);
	end;
end;

function tableShow(t, name, channel, indent, maxDepth)
	-- important performance backup: the channel is checked first before proceeding with the compilation of the table
	if channel ~= nil and courseplay.debugChannels[channel] ~= nil and courseplay.debugChannels[channel] == false then
		return;
	end;


	local cart; -- a container
	local autoref; -- for self references
	maxDepth = maxDepth or 50;
	local depth = 0;

	-- (RiciLake) returns true if the table is empty
	local function isemptytable(t)
		return next(t) == nil;
	end;

	local function basicSerialize(o)
		local so = tostring(o);
		if type(o) == 'function' then
			local info = debug.getinfo(o, 'S')
			-- info.name is nil because o is not a calling level
			if info.what == 'C' then
				return ('"%s, C function"'):format(so);
			else
				-- the information is defined in a script
				return ('"%s, defined in %s (lines %d-%d)"'):format(so, info.source, info.linedefined, info.lastlinedefined);
			end
		elseif type(o) == 'number' then
			return so;
		else
			return ('%q'):format(so);
		end
	end

	local function addToCart(value, name, indent, saved, field, curDepth)
		indent = indent or ''
		saved = saved or {}
		field = field or name
		-- cart = cart .. indent .. field
		cart = indent .. field
		-- print(('addToCart(value=%q, name=%q, indent, saved, field=%q, curDepth=%d)'):format(tostring(value), tostring(name), tostring(field), tostring(curDepth)));

		if type(value) ~= 'table' then
			cart = cart .. ' = ' .. basicSerialize(value) .. ';';
			print(cart);
		else
			if saved[value] then
				cart = cart .. ' = {}; -- ' .. saved[value] .. ' (self reference)';
				print(cart);
				autoref = autoref .. name .. ' = ' .. saved[value] .. ';\n';
			else
				saved[value] = name;
				if isemptytable(value) then
					cart = cart .. ' = {};';
					print(cart);
				else
					if curDepth <= maxDepth then
						cart = cart .. ' = {';
						print(cart);
						for k, v in pairs(value) do
							k = basicSerialize(k);
							local fname = string.format('%s[%s]', name, k);
							field = string.format('[%s]', k);
							-- three spaces between levels
							addToCart(v, fname, indent .. '\t', saved, field, curDepth + 1);
						end;
						cart = indent .. '};';
						print(cart);
					else
						cart = cart .. ' = { ... };';
						print(cart);
					end;
				end;
			end;
		end;
	end;

	name = name or '__unnamed__';
	if type(t) ~= 'table' then
		return name .. ' = ' .. basicSerialize(t);
	end;
	cart, autoref = '', '';
	addToCart(t, name, indent, nil, nil, depth + 1)
	-- return cart .. autoref
	print(autoref);
	return ('%s %s -END- %s'):format(('#'):rep(40), name, ('#'):rep(40));
end;

function eval(str)
	return assert(loadstring(str))()
end

--------------------------------------------------

-- MULTIPLAYER DEBUG
stream_debug_counter = 0

function streamDebugWriteFloat32(streamId, value)
	value = Utils.getNoNil(value, 0.0)
	stream_debug_counter = stream_debug_counter + 1
	--[[courseplay:debug("++++++++++++++++", 5)
	courseplay:debug(stream_debug_counter, 5)
	courseplay:debug("float: " .. value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: writing float: %f",stream_debug_counter, value ),5)
	streamWriteFloat32(streamId, value)
end

function streamDebugWriteBool(streamId, value)
	value = Utils.getNoNil(value, false)
	if value == 1 then
		value = true
	end

	if value == 0 then
		value = false
	end

	stream_debug_counter = stream_debug_counter + 1
	--[[courseplay:debug("++++++++++++++++", 5)
	courseplay:debug(stream_debug_counter, 5)
	courseplay:debug("Bool: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: writing bool: %s",stream_debug_counter, tostring(value) ),5)	
	streamWriteBool(streamId, value)
end

function streamDebugWriteInt32(streamId, value)
	value = Utils.getNoNil(value, 0)
	stream_debug_counter = stream_debug_counter + 1
	--[[courseplay:debug("++++++++++++++++", 5)
	courseplay:debug(stream_debug_counter, 5)
	courseplay:debug("Int32: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: writing int: %d",stream_debug_counter, value ),5)
	streamWriteInt32(streamId, value)
end

function streamDebugWriteString(streamId, value)
	value = Utils.getNoNil(value, "")
	stream_debug_counter = stream_debug_counter + 1
	--[[courseplay:debug("++++++++++++++++", 5)
	courseplay:debug(stream_debug_counter, 5)
	courseplay:debug("String: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: writing string: %s",stream_debug_counter, value ),5)
	streamWriteString(streamId, value)
end


function streamDebugReadFloat32(streamId)
	stream_debug_counter = stream_debug_counter + 1
	--courseplay:debug("++++++++++++++++", 5)
	--courseplay:debug(stream_debug_counter, 5)
	local value = streamReadFloat32(streamId)
	--[[courseplay:debug("Float32: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: reading float: %f",stream_debug_counter, value ),5)
	return value
end


function streamDebugReadInt32(streamId)
	stream_debug_counter = stream_debug_counter + 1
	--courseplay:debug("++++++++++++++++", 5)
	--courseplay:debug(stream_debug_counter, 5)
	local value = streamReadInt32(streamId)
	--[[courseplay:debug("Int32: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: reading int: %d",stream_debug_counter, value ),5)
	return value
end

function streamDebugReadBool(streamId)
	stream_debug_counter = stream_debug_counter + 1
	--courseplay:debug("++++++++++++++++", 5)
	--courseplay:debug(stream_debug_counter, 5)
	local value = streamReadBool(streamId)
	--[[courseplay:debug("Bool: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: reading bool: %s",stream_debug_counter, tostring(value)),5)
	return value
end

function streamDebugReadString(streamId)
	stream_debug_counter = stream_debug_counter + 1
	--courseplay:debug("++++++++++++++++", 5)
	--courseplay:debug(stream_debug_counter, 5)
	local value = streamReadString(streamId)
	--[[courseplay:debug("String: ", 5)
	courseplay:debug(value, 5)
	courseplay:debug("-----------------", 5)]]
	courseplay:debug(string.format("%d: reading string: %s",stream_debug_counter, value ),5)
	return value
end