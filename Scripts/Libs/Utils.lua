----------
Utils = {}

----------
Utils.Init = function(self)
end

----------
Utils.replace_pre = function(old, new)
    if (not old) then
        return new
    else
        return function(...)
            local res = new(...)
            old(...)
            return res
        end
    end
end

----------
Utils.replace_post = function(old, new)
    if (not old) then
        return new
    else
        return function(...)
            local res = old(...)
            return new(...) or res
        end
    end
end