--------------
Date = {}

--------------
-- Which lazy fk made this
ONE_YEAR         = 31536000  -- 60 * 60 * 24 * 365
ONE_MONTH        = 2592000   -- 60 * 60 * 24 * 30
ONE_WEEK         = 604800    -- 60 * 60 * 24 * 7
ONE_DAY          = 86400     -- 60 * 60 * 24
THREE_HOURS      = 10800     -- 60 * 60 * 3
ONE_HOUR         = 3600      -- 60 * 60
HALF_HOUR        = 1800      -- 60 * 30
FIFTEEN_MINUTES  = 900       -- 60 * 15
TEN_MINUTES      = 600       -- 60 * 10
FIVE_MINUTES     = 300       -- 60 * 5
ONE_MINUTE       = 60        -- 60
ONE_SECOND       = 1         -- 1

--------------
Date.Init = function(self)

    IsDate        = self.IsDate
    ToDate        = self.ToDate
    DateNow       = self.DateNow
    DateEpoch     = self.DateEpoch
    ParseTime     = self.ParseTime
    DateNew       = self.DateNew
    DateAdd       = self.DateAdd
    DateDiff      = self.DateDiff
    DateToSeconds = self.DateToSeconds
    GetTimestamp  = self.DateNow

    -- test
    ParseTime("100d-600d")
end

--------------
Date.IsDate = function(hDate)

    if (not isArray(hDate)) then
        return false
    end

    return (hDate.year and hDate.month and hDate.day and hDate.hour and hDate.min and hDate.sec)
end

--------------
Date.ToDate = function(sDate)

    if (isNull(sDate)) then
        ServerLog(table.tostring(ToDate("1970/0/1 00:00:00")))
        ServerLog(DateEpoch())
        throw_error("null")
    end

    if (IsDate(sDate)) then
        return sDate
    end

    local year, month, day, hour, min, sec = string.match(sDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if (year == nil) then
        year, month, day, hour, min, sec = string.match(sDate, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")
        if (year == nil) then
            year, month, day, hour, min, sec = string.match(sDate, "(%d+)\\(%d+)\\(%d+) (%d+):(%d+):(%d+)")
        end
    end

    if (year and month and day and hour and min and sec) then
        return {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec),
            isdst = false  -- Assuming no daylight saving time
        }
    else
        error("Invalid date format")
    end
end

--------------
Date.DateNow = function()
    return DateToSeconds(os.date("*t"))
end

--------------
Date.DateEpoch = function()
    return os.time(ToDate("1970/0/1 00:00:00"))
end

--------------
Date.DateNew = function(iSeconds)
    return (os.date("*t", iSeconds))
end

--------------
Date.DateDiff = function(aDate1, aDate2)
    local iTime1 = os.time(ToDate(aDate1))
    local iTime2 = os.time(ToDate(aDate2))
    return (os.difftime(iTime1, iTime2))
end

--------------
Date.DateAdd = function(aDate, iSeconds)
    local iTime = (os.time(ToDate(aDate)) + iSeconds)
    return (os.date("*t", iTime))
end

--------------
Date.DateToSeconds = function(aDate)
    return (os.time(ToDate(aDate)))
end

--------------
Date.ParseTime = function(sInput)

    if (not sInput) then
        return 0
    end

    local sTime = string.gsub(sInput, "%s", "")

    -- for randomizing times, eg: 10m-1h (random time between 10 mins and 1 hour)
    local sPre, sPost = string.match(sInput, "^(.*)%-(.*)$")
    if (sPre and sPost) then
        local iPre = ParseTime(sPre)
        local iPost = ParseTime(sPost)
        return math.random(iPre, iPost)
    end

    local aParsed = {
        g_tn(string.match(sTime, "(%d+)y")      or 0) * ONE_YEAR,   -- Years
        g_tn(string.match(sTime, "(%d+)mo")     or 0) * ONE_MONTH,  -- Months
        g_tn(string.match(sTime, "(%d+)w")      or 0) * ONE_WEEK,   -- Months
        g_tn(string.match(sTime, "(%d+)d")      or 0) * ONE_DAY,    -- Days
        g_tn(string.match(sTime, "(%d+)h")      or 0) * ONE_HOUR,   -- Hours
        g_tn(string.match(sTime, "(%d+)m[^o]")  or 0) * ONE_MINUTE, -- Minutes
        g_tn(string.match(sTime, "(%d+)s")      or 0) * ONE_SECOND, -- Seconds
    }

    return table.it(aParsed, function(x, i, v) return ((x or 0) + v)  end)
end

--------------
Date:Init()