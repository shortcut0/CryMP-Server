--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful string utils for lua
--
--=====================================================

-------------------
mathutils = {
	version = "0.1",
	author = "shortcut0",
	description = "all kinds of utiliy functions that might come in handy"
}

---------------------------
math.INF = (1 / 0)

---------------------------
-- math.t

math.t = tonumber;

---------------------------
-- math.isnumber

math.isnumber = function(i)
	return type(i) == "number"
end

---------------------------
-- math.fix

math.fix = function(i)
	if (i == math.INF or (i == 1 / 0) or tostring(i) == "inf") then
		i = 0
	end
	return i
end

---------------------------
-- math.div

math.div = function(i, d)
	if (i == 0 and d == 0) then
		return 0 
	elseif (i == 0) then
		return 0 
	elseif (d == 0) then
		return i end
		
	return i / d
end

---------------------------
-- math.round

math.round = function(i)
	return (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))
end

---------------------------
-- math.fits

math.fits = function(target, number)
	local t = math.t;
	local f = string.gsub(target / number, "%.(%d+)$", "");
	local _ = t(f:sub(1, 1));
	if (not _ or _ < 1 or f:find("e")) then
		return 0, target;
	end;
	f = t(f);
	local r = target;
	if (f > 0) then
		r = r - (number * f);
	end;
	return (tonumber(string.format("%0.0f", f)) or 0), r; 
end;

---------------------------
-- math.loopindex

math.loopindex = function(num, target)
	local f = num / target
	if (target > num or f < 1) then
		return { 0, num }
	end
	local fits = string.gsub(f, "%.(.*)", "")
	local rem = num - (fits * target)
	return { fits, rem }
end;

---------------------------
-- math.calctime

math.calctime = function(seconds, style, datemax)

	if (not isNumber(seconds)) then
		-- error() :oOOO
		return seconds
	end

	seconds = checkNumber(seconds, 0)
	style = checkVar(style, 1)

	if (seconds < 0) then
		return "Infinite"
	elseif (seconds < 1) then
		return "0s"
	end

	local units = {
		{ name = "mille", 	value = 86400 * 365 * 100 * 100 * 100 }, -- Decades
		{ name = "c", 		value = 86400 * 365 * 100 * 100 }, 		 -- Decades
		{ name = "dec", 	value = 86400 * 365 * 100 },			 -- Decades
		{ name = "y", 		value = 86400 * 365 },      			 -- Years
		{ name = "d", 		value = 86400 },           			 	 -- Days
		{ name = "h", 		value = 3600 },            				 -- Hours
		{ name = "m", 		value = 60 },               			 -- Minutes
		{ name = "s", 		value = 1 }                			     -- Seconds
	}

	local count = table.count(units)
	if (datemax) then
		while (count > 1 and count > datemax) do
			table.popFirst(units)
			count = table.count(units)
		end
	end

	local result = {}
	local s = seconds

	for _, unit in ipairs(units) do
		local fits = { math.floor(s / unit.value), s % unit.value }
		table.insert(result, { name = unit.name, value = fits[1] })
		s = fits[2]
	end

	local function formatResult(style)
		local formatted = {}
		local includeNext = false

		for i, unit in ipairs(result) do
			if unit.value > 0 then
				includeNext = true
			end
			if includeNext or i == #result then
				table.insert(formatted, string.format("%d%s", unit.value, unit.name))
			end
		end

		if style == 3 then
			return { result[6].value, result[5].value, result[4].value, result[3].value, result[2].value, result[1].value }
		elseif style == 2 then
			return table.concat(formatted, ", ")
		elseif style == 1 then
			return table.concat(formatted, ": ")
		else
			return table.concat(formatted, ":")
		end
	end

	return formatResult(style)
end

---------------------------
-- math.increase

math.increase = function(hVar, iAdd)
	return (checkNumber(hVar, 0) + checkNumber(iAdd, 0))
end

---------------------------
-- math.positive

math.positive = function(iNum)
	if (iNum < 0) then
		return (iNum * -1)
	end
	return iNum
end

---------------------------
-- math.negative

math.negative = function(iNum)
	if (iNum > 0) then
		return (iNum * -1)
	end
	return iNum
end

---------------------------
-- math.decrease

math.decrease = function(hVar, iRem)
	return (checkNumber(hVar, 0) - checkNumber(iRem, 0))
end

---------------------------
-- math.maxex

math.maxex = function(iNum, iMax)
	if (iNum > iMax) then
		return iMax
	end
	return iNum
end

---------------------------
-- math.minex

math.minex = function(iNum, iMin)
	if (iNum < iMin) then
		return iMin
	end
	return iNum
end

---------------------------
-- math.limit

math.limit = function(iNum, iMin, iMax)
	local iNew = iNum
	if (isNumber(iMin)) then
		iNew = math.minex(iNew, iMin)
	end
	if (isNumber(iMax)) then
		iNew = math.maxex(iNew, iMax)
	end
	return iNew
end

---------------------------
-- math.frandom

math.frandom = function(min, max)
	return min + math.random() * (max - min)
end

-------------------
mathutils.t = math.t
mathutils.div = math.div
mathutils.fits = math.fits
mathutils.calctime = math.calctime
mathutils.isnumber = math.isnumber
mathutils.maxex = math.maxex
mathutils.minex = math.minex
mathutils.limit = math.limit
mathutils.frandom = math.frandom

-------------------
return mathutils