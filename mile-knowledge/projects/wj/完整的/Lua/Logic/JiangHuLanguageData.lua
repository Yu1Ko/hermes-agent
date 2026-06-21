-------------------------------------------------------------------------
-- 江湖语言
-------------------------------------------------------------------------
JiangHuLanguageData = JiangHuLanguageData or {}
local self = JiangHuLanguageData

local _tJiangHuLanguageMap  = {}

function JiangHuLanguageData.Init()
    if not self.bInit then
        _tJiangHuLanguageMap = CustomData.GetData(CustomDataType.Account, "JiangHuLanguage")
        if not _tJiangHuLanguageMap or #_tJiangHuLanguageMap == 0 then
            _tJiangHuLanguageMap = g_tStrings.tJiangHu
            CustomData.Register(CustomDataType.Account, "JiangHuLanguage", _tJiangHuLanguageMap)
        end
    end
end

function JiangHuLanguageData.UnInit()
    self.bInit = false
    CustomData.Register(CustomDataType.Account, "JiangHuLanguage", _tJiangHuLanguageMap)
end

function JiangHuLanguageData.GetJiangHuData()
    return _tJiangHuLanguageMap
end

function JiangHuLanguageData.GetJiangHuDataAtNPos(nPos)
    if nPos < 1 or nPos > #_tJiangHuLanguageMap then
        return nil
    else
        return _tJiangHuLanguageMap[nPos]
    end
end

function JiangHuLanguageData.GetNPosOfJiangHuLanguage(tJiangHu)
    for i = 1, #_tJiangHuLanguageMap, 1 do
        if _tJiangHuLanguageMap[i][1] == tJiangHu[1] then
            return i
        end
    end
    return nil
end

function JiangHuLanguageData.IsJiangHuData(szCmd, tSelJiangHu)
    if tSelJiangHu then
        for _, v in pairs(_tJiangHuLanguageMap) do
            if v[1] == szCmd and v[1] ~= tSelJiangHu[1] then
                return true
            end
        end
        return false
    else
        for _, v in pairs(_tJiangHuLanguageMap) do
            if v[1] == szCmd then
                return true
            end
        end
        return false
    end
end

function JiangHuLanguageData.ProcessJiangHuWord(tJiangHu)
    Event.Dispatch("ProcessJiangHuWord", tJiangHu)
end

function JiangHuLanguageData.BackDefaults()
    _tJiangHuLanguageMap = g_tStrings.tJiangHu
end

function JiangHuLanguageData.AddNew(tJiangHu)
    table.insert(_tJiangHuLanguageMap, tJiangHu)
end

function JiangHuLanguageData.Delete(nPos)
    table.remove(_tJiangHuLanguageMap, nPos)
end

function JiangHuLanguageData.Modify(tJiangHu, nPos)
    table.insert(_tJiangHuLanguageMap, nPos, tJiangHu)
    table.remove(_tJiangHuLanguageMap, nPos + 1)
end