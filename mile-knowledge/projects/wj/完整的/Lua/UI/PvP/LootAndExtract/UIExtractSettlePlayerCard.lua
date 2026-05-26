-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractSettlePlayerCard
-- Date: 2025-03-31 20:17:56
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbGameState = {
    [0] = "暂未撤离",
    [1] = "撤离失败",
    [2] = "撤离成功",
}
local UIExtractSettlePlayerCard = class("UIExtractSettlePlayerCard")

function UIExtractSettlePlayerCard:OnEnter(tbStaticData, dwPlayerID, szGlobalID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData     = tbStaticData
    self.dwPlayerID = dwPlayerID
    self.szGlobalID = szGlobalID
    self:UpdateInfo()
end

function UIExtractSettlePlayerCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractSettlePlayerCard:BindUIEvent()
    
end

function UIExtractSettlePlayerCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractSettlePlayerCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractSettlePlayerCard:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetPersonalCard)
    local dwID = self.dwPlayerID
    local szGlobalID = self.szGlobalID
    local tbData = self.tbData
    local nGameState = tbData and tbData.nState or 0

    local szStateInfo = tbGameState[nGameState]
    UIHelper.SetVisible(self.LabelTeamInfo, true)
    UIHelper.SetVisible(self.LayoutMoney, false)
    UIHelper.SetString(self.LabelTeamInfo, szStateInfo)
    local scriptPersonalCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, szGlobalID)
	scriptPersonalCard:SetPlayerId(dwID)
    scriptPersonalCard:SetEquipNumVisible(false)
    scriptPersonalCard:SetXunBaoInfo(true, tbData)
end


return UIExtractSettlePlayerCard