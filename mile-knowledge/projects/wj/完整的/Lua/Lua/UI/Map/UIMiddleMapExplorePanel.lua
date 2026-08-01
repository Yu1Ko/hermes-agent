-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapExplorePanel
-- Date: 2025-09-16 17:23:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapExplorePanel = class("UIMiddleMapExplorePanel")

function UIMiddleMapExplorePanel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMiddleMapExplorePanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:SetVisible(false)
end

function UIMiddleMapExplorePanel:Show()
    self:SetVisible(true)
end

function UIMiddleMapExplorePanel:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIMiddleMapExplorePanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseExplore, EventType.OnClick, function()
        self:SetVisible(false)
    end)
end

function UIMiddleMapExplorePanel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiddleMapExplorePanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapExplorePanel:UpdateInfo(dwMapID)
    local tExploreInfo = MapHelper.GetMapExploreInfo(dwMapID)
    local nTotalCount  = 0
    local nFinishCount = 0

    UIHelper.RemoveAllChildren(self.ScrollViewContentSelectExplore)
    for nType, v in pairs(tExploreInfo) do
        local nTypeTotal  = 0
        local nTypeFinish = 0
        local tTypeInfo   = MapHelper.GetMapExploreTypeInfo(nType)
        if tTypeInfo then
             for nSubType, tList in pairs(v) do
                local nSubTypeTotal    = 0
                local nSubTypeFinish   = 0
                local tSubTypeInfo = MapHelper.GetMapExploreTypeInfo(nSubType)
                if tSubTypeInfo then
                    for _, tInfo in ipairs(tList) do
                        if tInfo.nState and tInfo.nState >= MAP_EXPLORE_STATE.FINISH then
                            nSubTypeFinish = nSubTypeFinish + 1
                        end
                        nSubTypeTotal = nSubTypeTotal + 1
                    end
                    nTypeTotal  = nTypeTotal + nSubTypeTotal
                    nTypeFinish = nTypeFinish + nSubTypeFinish
                else
                    UILog("No MapExplore nSubType: %d", nSubType)
                end
                tList.nFinishCount = nSubTypeFinish
                tList.nTotalCount  = nSubTypeTotal
            end
            local tGroupInfo = {
                nType        = nType,
                dwMapID      = dwMapID,
                tSubTypeList = clone(v),
                nFinishCount = nTypeFinish,
                nTotalCount  = nTypeTotal,
            }
            local ScriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMapExploreGroup, self.ScrollViewContentSelectExplore, tGroupInfo)
            nTotalCount  = nTotalCount + nTypeTotal
            nFinishCount = nFinishCount + nTypeFinish
        else
            UILog("No MapExplore nType: %d", nType)
        end
    end
    self.nFinishCount = nFinishCount
    self.nTotalCount  = nTotalCount
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContentSelectExplore, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewContentSelectExplore)
    UIHelper.ScrollToTop(self.ScrollViewContentSelectExplore, 0)
    -- MiddleMap.RefreshExploreEvent()
    self:UpdateProgress(dwMapID)
end

function UIMiddleMapExplorePanel:UpdateProgress(dwMapID)
    local tRewardList  = MapHelper.GetMapExploreReward(dwMapID, 0)
    if not tRewardList then
        return
    end

    local fPercent = math.floor((self.nTotalCount ~= 0 and self.nFinishCount / self.nTotalCount or 0) * 100) / 100
    local szPercent = string.format("%d%%", fPercent * 100)
    UIHelper.SetString(self.LabelTitleExploreNum, szPercent)

    UIHelper.RemoveAllChildren(self.LayoutExploreAward)
    local nRewardCount = 0
    for _, v in pairs(tRewardList) do
        if v.nFinishCount <= self.nTotalCount then
            nRewardCount = nRewardCount + 1
        end
    end

    local nWidth = nRewardCount * 80
    for _, v in pairs(tRewardList) do
        if v.nFinishCount <= self.nTotalCount then
            local t           = SplitString(v.szReward or "", ";")
            local tt          = SplitString(t[1] or "", "_")
            local dwTabType   = tonumber(tt[1])
            local dwIndex     = tonumber(tt[2])
            local nCount      = tonumber(tt[3])
            local fNowPercent = self.nTotalCount ~= 0 and v.nFinishCount / self.nTotalCount or 0
            local tCellInfo   = {
                dwTabType = dwTabType,
                dwIndex = dwIndex,
                nCount = nCount,
                fPercent = fNowPercent,
                nFinishCount = v.nFinishCount,
                nCurrentFinish = self.nFinishCount,
                dwQuestID = v.dwQuestID,
                dwID = v.dwID,
                dwMapID = v.dwMapID,
            }
            local ScriptCell  = UIHelper.AddPrefab(PREFAB_ID.WidgetExploreAwardCell, self.LayoutExploreAward, tCellInfo)
            local y           = UIHelper.GetPositionY(ScriptCell._rootNode)
            local x           = nWidth * fNowPercent
            local nCellWidth  = UIHelper.GetWidth(ScriptCell._rootNode) or 0
            UIHelper.SetPosition(ScriptCell._rootNode, x - nCellWidth / 2, y)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutExploreAward)
    UIHelper.SetWidth(self.LayoutExploreAward, nWidth)
    UIHelper.SetWidth(self.ProgressBarExplore, nWidth)
    UIHelper.SetWidth(self.ImgVersionsCountBg, nWidth)
    UIHelper.SetWidth(self.ImgVersionsCountFg, nWidth)
    UIHelper.SetWidth(self.WidgetReward, nWidth + 45)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewLevelAward, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewLevelAward)
    UIHelper.ScrollToLeft(self.ScrollViewLevelAward, 0)
    UIHelper.SetProgressBarPercent(self.ProgressBarExplore, fPercent * 100)
end

return UIMiddleMapExplorePanel