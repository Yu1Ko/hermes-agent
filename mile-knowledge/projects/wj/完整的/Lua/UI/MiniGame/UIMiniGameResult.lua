-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameResult
-- Date: 2025-09-18 15:41:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiniGameResult = class("UIMiniGameResult")

function UIMiniGameResult:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = UIHelper.GBKToUTF8(tInfo.szTitle or "")
    self.szSubtitle = UIHelper.GBKToUTF8(tInfo.szSubtitle or "")
    self.bFailed = tInfo.bFailed
    self.tRewardList = tInfo.tRewardList
    self.tQuest = tInfo.tQuest
    self.tBtnList = tInfo.tBtnList
    self.szScore = tInfo.szScore
    self.bNewRecord = tInfo.bNewRecord
    self:UpdateInfo()
end

function UIMiniGameResult:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiniGameResult:BindUIEvent()
    
end

function UIMiniGameResult:RegEvent()
    Event.Reg(self, "MINI_GAME_RESULT_CLOSE", function ()
        UIMgr.Close(VIEW_ID.PanelMapGameSettlement)
    end)
end

function UIMiniGameResult:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiniGameResult:UpdateInfo()
    if not self.szTitle or not self.szSubtitle  then
        return
    end
    UIHelper.SetString(self.LabelLevelTitle, self.szTitle .. "\n" .. self.szSubtitle)
    UIHelper.SetString(self.LabelProgressScore, self.szScore)
    UIHelper.SetVisible(self.ImgBgVictory, not self.bFailed)
    UIHelper.SetVisible(self.ImgTitleVictory, not self.bFailed)
    UIHelper.SetVisible(self.ImgBgDefeat, self.bFailed)
    UIHelper.SetVisible(self.ImgTitleDefeat, self.bFailed)
    if self.szScore then
        UIHelper.SetString(self.LabelProgressScore, self.szScore)
        UIHelper.SetVisible(self.ImgNew, self.bNewRecord)
        UIHelper.SetVisible(self.WidgetAnchorScore, true)
    else
        UIHelper.SetVisible(self.WidgetAnchorScore, false)
    end

    --Reward
    if self.tRewardList and not IsTableEmpty(self.tRewardList) then
        UIHelper.RemoveAllChildren(self.LayoutReward)
        for _, v in pairs(self.tRewardList) do
            local ScriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutReward, v)
            local dwTabType  = v.dwTabType or v[1]
            local dwIndex    = v.dwIndex or v[2]
            local nCount     = v.nCount or v[3]
            ScriptItem:OnInitWithTabID(dwTabType, dwIndex, nCount)
            ScriptItem:SetClickNotSelected(true)
            ScriptItem:SetClickCallback(function(nItemType, nItemIndex)
                TipsHelper.ShowItemTips(ScriptItem._rootNode, dwTabType, dwIndex, false)  
            end)
        end
        UIHelper.LayoutDoLayout(self.LayoutReward)
        UIHelper.SetVisible(self.WidgetAnchorReward, true)
    else
        UIHelper.SetVisible(self.WidgetAnchorReward, false)
    end

    --Quest
    UIHelper.RemoveAllChildren(self.LayoutGameSettlement)
    for _, v in pairs(self.tQuest) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetGameSettlementCell, self.LayoutGameSettlement, v)
    end
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewGameSettlement, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewGameSettlement)
    UIHelper.ScrollToTop(self.ScrollViewGameSettlement, 0)

    --Btn
    UIHelper.RemoveAllChildren(self.LayoutButton)
    for _, v in pairs(self.tBtnList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBtnMapGameSettlement, self.LayoutButton, v)
    end
    UIHelper.LayoutDoLayout(self.LayoutButton)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end


return UIMiniGameResult