function RandomName(nRoleType)
    local ts = g_tGlue.tSurname
    local tn = g_tGlue.tName[nRoleType]
    local talone = g_tGlue.tAloneName

    if not ts then return "" end
    if not tn then return "" end

    local tbn = g_tGlue.tBadName

    while true do
        local fChoice = math.random()
        local n
        if fChoice >= 0.5 then
            n = talone[math.random(#talone)]
        else
            n = ts[math.random(#ts)]..tn[math.random(#tn)]
        end
        if not tbn[n] then
            return GBKToUTF8(n)
        end
    end
end