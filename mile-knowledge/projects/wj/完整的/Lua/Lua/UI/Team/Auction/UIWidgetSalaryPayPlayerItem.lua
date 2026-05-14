-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSalaryPayPlayerItem
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSalaryPayPlayerItem = class("UIWidgetSalaryPayPlayerItem")

function UIWidgetSalaryPayPlayerItem:OnEnter(tData)
    if not tData then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self:UpdateInfo(true)
end

function UIWidgetSalaryPayPlayerItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSalaryPayPlayerItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogMulti, EventType.OnClick, function ()
        local bSelected = UIHelper.GetSelected(self.TogMulti)
        self:SetSelected(bSelected)
        Event.Dispatch(EventType.OnSalaryDataChanged)
    end)

    UIHelper.BindUIEvent(self.TogMore, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSingleTextTips, self.TogMore, self.szReason)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelPayBonusPop, self.tData.dwGID)
    end)
end

function UIWidgetSalaryPayPlayerItem:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogMore, false)
    end)

    Event.Reg(self, EventType.OnSalaryDataChanged, function (tData)
        self:UpdateInfo(false)
    end)

    Event.Reg(self, EventType.OnAuctionTagChanged, function ()
        local szTag = AuctionData.GetPlayerTag(self.tData.dwPlayerID)
        UIHelper.SetString(self.LabelTag, szTag)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)
end

function UIWidgetSalaryPayPlayerItem:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSalaryPayPlayerItem:UpdateInfo(bInit)
    local tData = self.tData
    local dwPlayerID = tData.dwPlayerID
    local dwGID = tData.dwGID

    local szRoleName = tData.tMemberInfo.szName
    szRoleName = UIHelper.GBKToUTF8(szRoleName)
    local szTag = AuctionData.GetPlayerTag(dwPlayerID)
    local szImagePath = PlayerForceID2SchoolImg2[tData.tMemberInfo.dwForceID]

    local tClientTeam = GetClientTeam()
    local nGroupID = tClientTeam.GetMemberGroupIndex(dwPlayerID)
    local dwTeamLeader  = GetClientTeam().dwTeamLeader
    local bLeader = dwTeamLeader == dwPlayerID

    local dwDistributeMan = tClientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDestDistributer = dwDistributeMan == dwPlayerID
    local bSelfDistributer = dwDistributeMan == UI_GetClientPlayerID()
    local _, _, _, _, nBasic = AuctionData.GetAllMoneyInfo()
    local nBasicBrick = math.floor(nBasic / 10000)
    local nBasicGold = nBasic % 10000

    local nConsumeBrick = math.floor(self.tData.nConsumeGolds / 10000)
    local nConsumeGold = self.tData.nConsumeGolds % 10000

    self.szReason = "暂无补贴"
    local tSubsidy = AuctionData.tSubsidies[dwGID]
    if not tSubsidy then
        tSubsidy = {nMoney = 0, szReason = UIHelper.UTF8ToGBK(self.szReason)}
    end
    
    if tSubsidy.szReason then
        self.szReason = UIHelper.GBKToUTF8(tSubsidy.szReason)
    end

    local nSubBrick = math.floor(tSubsidy.nMoney / 10000)
    local nSubGold = tSubsidy.nMoney % 10000
    local nSumGolds = tSubsidy.nMoney + nBasic
    local nSumBrick = math.floor(nSumGolds / 10000)
    local nSumGold = nSumGolds % 10000

    local bSelected = AuctionData.tCheckTeamers[dwGID] or false
    UIHelper.SetSelected(self.TogMulti, bSelected, false)
    
    UIHelper.SetString(self.LabelPlayerName, szRoleName, 8)
    UIHelper.SetString(self.LabelTag, szTag)
    UIHelper.SetSpriteFrame(self.ImgSchool, szImagePath)
    UIHelper.SetVisible(self.LayoutRole, bLeader or bDestDistributer)
    if bLeader then
        UIHelper.SetString(self.LabelRole, "队长")
        UIHelper.SetSpriteFrame(self.ImgRole, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_captain.png")
    elseif bDestDistributer then
        UIHelper.SetString(self.LabelRole, "分配者")
        UIHelper.SetSpriteFrame(self.ImgRole, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_allot.png")
    end

    UIHelper.SetVisible(self.TogMulti, bSelfDistributer)
    UIHelper.SetVisible(self.TogMore, not bSelfDistributer)
    UIHelper.SetVisible(self.BtnEdit, bSelfDistributer)
    UIHelper.SetVisible(self.LayoutCurrencyBonus, bSelected)
    UIHelper.SetVisible(self.LayoutCurrencyBase,  bSelected)
    UIHelper.SetVisible(self.LayoutCurrencySumUp, bSelected)
    UIHelper.SetString(self.LabelMoney_ZhuanFee, tostring(nConsumeBrick))
    UIHelper.SetString(self.LabelMoney_JinFee, tostring(nConsumeGold))
    UIHelper.SetString(self.LabelMoney_ZhuanBonus, tostring(nSubBrick))
    UIHelper.SetString(self.LabelMoney_JinBonus, tostring(nSubGold))
    UIHelper.SetString(self.LabelMoney_ZhuanBase, tostring(nBasicBrick))
    UIHelper.SetString(self.LabelMoney_JinBase, tostring(nBasicGold))
    UIHelper.SetString(self.LabelMoney_ZhuanSumUp, tostring(nSumBrick))
    UIHelper.SetString(self.LabelMoney_JinSumUp, tostring(nSumGold))

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetSalaryPayPlayerItem:SetSelected(bSelected)
    local bOldSelected = UIHelper.GetSelected(self.TogMulti)
    if bSelected then
        AuctionData.tCheckTeamers[self.tData.dwGID] = bSelected
        if not AuctionData.tSubsidies[self.tData.dwGID] then
            AuctionData.tSubsidies[self.tData.dwGID] = {["nMoney"] = 0}
        end
    else
        AuctionData.tCheckTeamers[self.tData.dwGID] = nil
        AuctionData.tSubsidies[self.tData.dwGID] = nil
    end
    if bSelected ~= bOldSelected then
        UIHelper.SetSelected(self.TogMulti, bSelected)
    end
end

return UIWidgetSalaryPayPlayerItem