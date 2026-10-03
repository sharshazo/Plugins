import "Turbine"
_G.LQA = _G.LQA or {}
LQA.Core = LQA.Core or {}
LQA.Core.NavigationParser = {}

function LQA.Core.NavigationParser.Parse(message)
    local result = {}
    
    if string.find(message, "lx%d+") or string.find(message, "h[%d%.%-]+") or string.find(string.lower(message), "marca de tiempo") then
        local raw_escaped = string.gsub(message, "\n", "\\n")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nRAW = " .. raw_escaped)
        
        local h_match = string.match(message, "h([%d%.%-]+)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nH_MATCH = " .. tostring(h_match))
        
        local time_match = string.match(message, "Marca de tiempo del juego ([%d%.%-]+)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nTIME_MATCH = " .. tostring(time_match))
        
        local h_simple = string.match(message, "h(%-?%d+%.?%d*)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nH_SIMPLE = " .. tostring(h_simple))
        
        local time_simple = string.match(message, "Marca de tiempo del juego (%-?%d+%.?%d*)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nTIME_SIMPLE = " .. tostring(time_simple))
        
        local test_h1 = string.match("h160.3", "h(%-?%d+%.?%d*)")
        local test_h2 = string.match("h160.3.", "h(%-?%d+%.?%d*)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nTEST_H1 = " .. tostring(test_h1) .. "\nTEST_H2 = " .. tostring(test_h2))
        
        local test_t1 = string.match("Marca de tiempo del juego 47067278.274", "Marca de tiempo del juego (%-?%d+%.?%d*)")
        local test_t2 = string.match("Marca de tiempo del juego 47067278.274.", "Marca de tiempo del juego (%-?%d+%.?%d*)")
        Turbine.Shell.WriteLine("[QA-DEBUG]\nTEST_T1 = " .. tostring(test_t1) .. "\nTEST_T2 = " .. tostring(test_t2))
    end

    local server = string.match(message, "servidor (.-) en r%d")
    if server then 
        result.server = string.match(server, "^%s*(.-)%s*$") 
    end
    
    local r, lx, ly, i, ox, oy, oz = string.match(message, "r(%d+)%s+lx(%d+)%s+ly(%d+)%s+i(%d+)%s+ox([%d%.%-]+)%s+oy([%d%.%-]+)%s+oz([%d%.%-]+)")
    
    if lx and ly and ox and oy and oz then
        result.r = tonumber(r)
        result.lx = tonumber(lx)
        result.ly = tonumber(ly)
        result.i = tonumber(i)
        result.ox = tonumber(ox)
        result.oy = tonumber(oy)
        result.oz = tonumber(oz)
        
        local h_str = string.match(message, "h([%d%.%-]+)")
        local val_h = nil
        if h_str then
            if string.sub(h_str, -1) == "." then
                h_str = string.sub(h_str, 1, -2)
            end
            val_h = h_str
            result.h = tonumber(h_str)
        end
        Turbine.Shell.WriteLine("[QA-DEBUG]\nVAL_TO_NUM_H = " .. tostring(val_h) .. "\nRES_H = " .. tostring(result.h))
        
        local time_str = string.match(message, "Marca de tiempo del juego ([%d%.%-]+)")
        local val_t = nil
        if time_str then
            if string.sub(time_str, -1) == "." then
                time_str = string.sub(time_str, 1, -2)
            end
            val_t = time_str
            result.timestamp = tonumber(time_str)
        end
        Turbine.Shell.WriteLine("[QA-DEBUG]\nVAL_TO_NUM_TIME = " .. tostring(val_t) .. "\nRES_TIME = " .. tostring(result.timestamp))
        
        return result
    end
    
    return nil
end
