local _M = {className = "DungeonProgressInfoHandler"}
local self = _M

--副本进度
_M.szInfoType = TraceInfoType.DungeonProgress

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()
    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        local bIsDungeon = DungeonData.IsInDungeon()
        local bIsLKX = self.IsLKXInfo(tbInfo.szName) --特殊处理，浪客行的信息由专门的LangKeXingInfoHandler显示
        if bIsDungeon and not bIsLKX and not ActivityData.IsJingHuaMap() and not ActivityData.IsHotSpringActivity() then
            self.tDungeonProgressInfoMap = self.tDungeonProgressInfoMap or {}
            self.tDungeonProgressInfoMap[tbInfo.szName] = tbInfo
            local szTitle = UIHelper.GBKToUTF8(tbInfo.szTitle)
            local szDesc = GeneralProgressBarData.GetStringValue(tbInfo)
            local nPercent = 100
            if tbInfo.nDenominator then 
                nPercent = tbInfo.nMolecular / tbInfo.nDenominator*100
            end
            self.UpdateDungeonProgressBar(szTitle, szDesc, nPercent)

            TraceInfoData.UpdateInfo(TraceInfoType.DungeonProgress)
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.DungeonProgress, true)
        end
    end)
    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        -- 副本进度
        local bIsDungeon = DungeonData.IsInDungeon()
        local bIsLKX = self.IsLKXInfo(szName)
        if bIsDungeon and not bIsLKX and not ActivityData.IsJingHuaMap() and not ActivityData.IsHotSpringActivity() then
            self.tDungeonProgressInfoMap = self.tDungeonProgressInfoMap or {}
            self.tDungeonProgressInfoMap[szName] = nil

            TraceInfoData.UpdateInfo(TraceInfoType.DungeonProgress)
            -- 当数据被清空时再关闭进度条分页
            if table_is_empty(self.tDungeonProgressInfoMap) then
                Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.DungeonProgress, false)
            end
        end
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local bIsDungeon = DungeonData.IsInDungeon()
        if not bIsDungeon then
            --换地图清状态
            Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.DungeonProgress, false)
        end
    end)
end

function _M.OnUpdateView(script, scrollViewParent, tData)
    self.UpdateDungeonProgressInfo(scrollViewParent)
end

function _M.OnClear(script)

end

--------------------------------  --------------------------------

function _M.UpdateDungeonProgressInfo(scrollViewParent)
    if not self.tDungeonProgressInfoMap then
        return
    end

    UIHelper.RemoveAllChildren(scrollViewParent)
    -- 墨家机关城
    if self.tDungeonProgressInfoMap["bar148"] then
        local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, "墨家机关城", 5)        
        scriptTitle:SetClickCallBack(function ()
            TeachBoxData.OpenTutorialPanel(134, 135, 136, 137, 138, 139)
        end)
        scriptTitle:SetBtnHintVis(true)
    end
    local tProgressInfoList = {}
    for szName, tInfo in pairs(self.tDungeonProgressInfoMap) do
        table.insert(tProgressInfoList, {
            szName = szName,
            tInfo = tInfo,
        })
    end
    table.sort(tProgressInfoList, function (tProgress1, tProgress2)
        local nWeight1, nWeight2 = 0, 0
        if not tProgress1.tInfo.nDenominator then nWeight1 = 1 end
        if not tProgress2.tInfo.nDenominator then nWeight2 = 1 end
        return nWeight1 > nWeight2
    end)

    for _, tProgress in ipairs(tProgressInfoList) do
        local szName = tProgress.szName
        local tInfo = tProgress.tInfo
        local szTitle = UIHelper.GBKToUTF8(tInfo.szTitle)
        local szDesc = UIHelper.GBKToUTF8(tInfo.szDesc)
        local nPercent = tInfo.nPercent
        if szName == "ThermometerPanel" then
            UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, scrollViewParent, szTitle, 5)
            UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamHotIceSlider, scrollViewParent, UIHelper.UTF8ToGBK(szTitle), szDesc, nPercent, 20)
        elseif szDesc then
            local scriptSlider = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderOtherDescribe, scrollViewParent, UIHelper.UTF8ToGBK(szTitle), szDesc, nPercent, 20)
            local szColor = tInfo.tbLine.szMobileProgressColor
            if scriptSlider and szColor then
                local color = cc.c3b(tonumber(string.sub(szColor,1,2),16), tonumber(string.sub(szColor,3,4),16), tonumber(string.sub(szColor,5,6),16))
                UIHelper.SetColor(scriptSlider.SliderTarget, color)
            end
        end
    end
end

function _M.UpdateDungeonProgressBar(szTitle, szDesc, nPercent)
    self.tDungeonProgressInfoMap = self.tDungeonProgressInfoMap or {}
    for szName, tInfo in pairs(self.tDungeonProgressInfoMap) do
        if tInfo.szTitle == UIHelper.UTF8ToGBK(szTitle) then
            self.tDungeonProgressInfoMap[szName].szTitle = UIHelper.UTF8ToGBK(szTitle)
            self.tDungeonProgressInfoMap[szName].szDesc = UIHelper.UTF8ToGBK(szDesc)
            self.tDungeonProgressInfoMap[szName].nPercent = nPercent
        end
    end

    TraceInfoData.UpdateInfo(TraceInfoType.DungeonProgress)
end

function _M.IsLKXInfo(szName)
    return szName == "LKX_ShiChen" or szName == "LKX_XinQingZhi" or szName == "LKX_BaoShiDu"
end

return _M