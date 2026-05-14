-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapExploreAwardCell
-- Date: 2025-09-25 16:29:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapExploreAwardCell = class("UIMiddleMapExploreAwardCell")

function UIMiddleMapExploreAwardCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIMiddleMapExploreAwardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiddleMapExploreAwardCell:BindUIEvent()
    
end

function UIMiddleMapExploreAwardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiddleMapExploreAwardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapExploreAwardCell:UpdateInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end


    local bCanGet = self.tInfo.nCurrentFinish >= self.tInfo.nFinishCount
    local bHasGot = QuestData.IsCompleted(self.tInfo.dwQuestID)
    UIHelper.SetString(self.LabelActiveValue, string.format("%d%%", self.tInfo.fPercent * 100))
    UIHelper.SetVisible(self.LabelActiveValue, false)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem)
    script:OnInitWithTabID(self.tInfo.dwTabType, self.tInfo.dwIndex, self.tInfo.nCount)
    script:SetClickNotSelected(true)
    script:SetToggleSwallowTouches(false)
    script:SetItemReceived(bHasGot)
    script:SetCanGet(bCanGet and not bHasGot)
    script:SetClickCallback(function(nItemType, nItemIndex)
        if bCanGet and not bHasGot then
            RemoteCallToServer("On_Explore_GetReward", self.tInfo.dwID, self.tInfo.dwMapID)
            return
        end
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowItemTips(script._rootNode, self.tInfo.dwTabType, self.tInfo.dwIndex, false)
        end)
    end)
end


return UIMiddleMapExploreAwardCell