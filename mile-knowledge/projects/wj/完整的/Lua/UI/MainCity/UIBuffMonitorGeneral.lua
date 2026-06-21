-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuffMonitorGeneral
-- Date: 2025-10-22 16:04:42
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nCycleTime = 1/ 8
local UIBuffMonitorGeneral = class("UIBuffMonitorGeneral")
local tbTianLuoBuffImgList = {
    [0] = "UIAtlas2_SkillDX_SpecialSkill_TangMen_Buff_JiXian",
    [1] = "UIAtlas2_SkillDX_SpecialSkill_TangMen_Buff_JiaSu",
    [2] = "UIAtlas2_SkillDX_SpecialSkill_TangMen_Buff_ShangHai"
}

--层数显示图标状态
local ICON_STATE = {
    HIDE      = 0,
    SHOW_TEXT = 1,
    SHOW_ICON = 2,
    SHOW_BOTH = 3
}

function UIBuffMonitorGeneral:OnEnter(bCustom)
    if bCustom then
        UIHelper.SetActiveAndCache(self, self._rootNode, true)
    else
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
        end
        self.tCellList = {}
        for i = 1, 5 do
            if self.tbPlayerList[i] then
                table.insert(self.tCellList, UIHelper.GetBindScript(self.tbPlayerList[i]))
            end
        end
        UIHelper.SetActiveAndCache(self, self._rootNode, false)
    end

end

function UIBuffMonitorGeneral:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIBuffMonitorGeneral:BindUIEvent()
    
end

function UIBuffMonitorGeneral:RegEvent()
    Event.Reg(self, "RefreshAllMonitorTarget", function (tMonitorList)
        self.tMonitorList = tMonitorList
        UIHelper.SetVisible(self._rootNode, true)
        self:RefreshAllMonitorTarget()
    end)
end

function UIBuffMonitorGeneral:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function SortByTeamMark(tMonitorList)
    for k, v in ipairs(tMonitorList) do
        v.nIndex = k
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer or not hPlayer.IsInParty() then
        return tMonitorList
    end

    for k, v in ipairs(tMonitorList) do
        local nMarkID = GetClientTeam().GetMarkIndex(v.nSrcTargetID) or 0
        v.nMarkID = nMarkID
    end

    local function fnSortMark(a, b)
        if a.nMarkID ~= 0 and b.nMarkID ~= 0 then
            return a.nMarkID < b.nMarkID
        elseif a.nMarkID ~= 0 then
            return true
        elseif b.nMarkID ~= 0 then
            return false
        else
            return a.nIndex < b.nIndex
        end
    end
    table.sort(tMonitorList, fnSortMark)
    return tMonitorList
end

local function IsIn33Arena()
    if ArenaData.IsInArena() then
        local nCorpsType = Arena_GetCorpsType()
        if nCorpsType and nCorpsType == ARENA_UI_TYPE.ARENA_3V3 then --33竞技场默认云剑斧
            return true
        end
    end
    return false
end

function UIBuffMonitorGeneral:UpdateInfo()
    
end

function UIBuffMonitorGeneral:RefreshAllMonitorTarget()
    local bFlag = false
    local nMaxNum      = BuffMonitorForceBase.GetMaxNum()
    local tMonitorList = self.tMonitorList

    tMonitorList = SortByTeamMark(tMonitorList)
    for i = 1, 5 do
        local tInfo = self.tMonitorList[i]
        local script = self.tCellList[i]
        if tInfo and script then
            local tLine          = tInfo.tLine
            local nMaxLevel      = tLine.nMaxLevel
            local szName = UIHelper.GBKToUTF8(tInfo.szSrcName)
            szName = UIHelper.LimitUtf8Len(szName, 6)
            local nStackNum = tInfo.nStackNum
            local szImgPath = BuffMonitorForceBase.GetImagePath(tInfo.dwFullyType, tInfo.hSrcTarget, tInfo.nSrcTargetID)
            UIHelper.SetSpriteFrame(script.ImgPlayer, szImgPath)
            UIHelper.SetLabel(script.LabelPlayerName, szName)
            UIHelper.SetLabel(script.LabelDuLevel, tostring(nStackNum))

            self:UpdateBuffSkin(script, tInfo)

            bFlag = true
        end
        if script then
            script.bVisible = tInfo ~= nil
            UIHelper.SetActiveAndCache(self, script._rootNode, script.bVisible)
        end
    end

    UIHelper.SetActiveAndCache(self, self._rootNode, bFlag)
    UIHelper.LayoutDoLayout(self.LayoutBuff)

    Timer.DelAllTimer(self)
    if bFlag then
        self:RefreshTime()
        Timer.AddCycle(self, nCycleTime, function()
            self:RefreshTime()
        end)
    end
end

function UIBuffMonitorGeneral:RefreshTime()
    local bNeeUpdateList, nListSize = BuffMonitorForceBase.CheckList()

    if nListSize == 0 and not IsIn33Arena() then
        self.tMonitorList = nil
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    if bNeeUpdateList then
        self:RefreshAllMonitorTarget()
        return
    end

    if not self.tMonitorList then
        return
    end

    for i = 1, 5 do
        local script = self.tCellList[i]
        local tInfo = self.tMonitorList[i]
        if script and script.bVisible and tInfo then
            local fPercentage = tInfo.nLeftFrame / tInfo.nTotalFrame
            local nHour, nMinute, nSecond, nTenthSec = TimeLib.GetTimeToHourMinuteSecondTenthSec(tInfo.nLeftFrame, true)
            local szTimeText = tostring(nHour * 3600 + nMinute * 60 + nSecond) .. '.' .. tostring(nTenthSec)
            UIHelper.SetProgressBarPercent(script.barYaoZongBuff, fPercentage * 100)
            UIHelper.SetLabel(script.LabelPlayerCD, szTimeText)
        end
    end
end

function UIBuffMonitorGeneral:UpdateBuffSkin(script, tBuffInfo)
    if not script or not tBuffInfo then
        return
    end

    local nBuffID = tBuffInfo.nBuffID
    if not nBuffID or nBuffID == 0 then
        return
    end

    local tInfo = Table_GetBuffMonitorBuffSkinInfo(nBuffID)
    if not tInfo then
        return
    end

    if tInfo.nShowIconState ~= ICON_STATE.SHOW_ICON then    --只显示图标,唐门天罗
        return
    end

    local nLevel = tBuffInfo.nStackNum
    if tInfo.bUseLevel then
        nLevel = tBuffInfo.nBuffLevel
    end
    nLevel = math.min(nLevel, 4)
    nLevel = math.max(nLevel, 1)
    local szString = tInfo["szBuffIcon" .. nLevel]
    if szString ~= "" then
        local t = SplitString(szString, ";")
        local nIndex = tonumber(t[2])
        if nIndex and tbTianLuoBuffImgList[nIndex] then
            UIHelper.SetSpriteFrame(script.ImgDu, tbTianLuoBuffImgList[nIndex])
        end
    end
end

return UIBuffMonitorGeneral