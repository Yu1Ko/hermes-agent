local _M = {className = "TreasureBattleFieldInfoHandler"}
local self = _M

--绝境战场
_M.szInfoType = TraceInfoType.TreasureBattleField

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        local bTreauseBattleField = BattleFieldData.IsInTreasureBattleFieldMap() and (tbInfo.szName == "bar49" or tbInfo.szName == "bar50")
        if bTreauseBattleField then
            self.tName2Info = self.tName2Info or {}
            self.tName2Info[tbInfo.szName] = tbInfo

            TraceInfoData.UpdateInfo(TraceInfoType.TreasureBattleField)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.TreasureBattleField, true, tbInfo)
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        local bTreauseBattleField = BattleFieldData.IsInTreasureBattleFieldMap() and (szName == "bar49" or szName == "bar50")
        if bTreauseBattleField then
            self.tName2Info = self.tName2Info or {}
            self.tName2Info[szName] = nil

            TraceInfoData.UpdateInfo(TraceInfoType.TreasureBattleField)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.TreasureBattleField, false)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateTreasureBattleFieldInfo(scrollViewParent)
end

function _M.OnClear(script)

end

--------------------------------  --------------------------------

function _M.UpdateTreasureBattleFieldInfo(scrollViewParent)
    UIHelper.RemoveAllChildren(scrollViewParent)

    self.tName2Info = self.tName2Info or {}

    if self.tName2Info["bar49"] then
        local tbInfo = self.tName2Info["bar49"]
        local szTitle = UIHelper.GBKToUTF8(tbInfo.szTitle)
        local szDesc = UIHelper.GBKToUTF8(tbInfo.szDiscrible) .. " " .. tbInfo.nMolecular .. "/" .. tbInfo.nDenominator
        UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szTitle, 5)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szDesc)
    end

    if self.tName2Info["bar50"] then
        local tbInfo = self.tName2Info["bar50"]
        local szTitle = UIHelper.GBKToUTF8(tbInfo.szTitle)
        local szDesc = UIHelper.GBKToUTF8(tbInfo.szDiscrible) .. " " .. tbInfo.nMolecular .. "秒"
        UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szTitle, 5)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRichTextOtherDescribe, scrollViewParent, szDesc)
    end
end

return _M