-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelUpgradeChatRoomPopView
-- Date: 2025-09-17 20:37:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelUpgradeChatRoomPopView = class("UIPanelUpgradeChatRoomPopView")

function UIPanelUpgradeChatRoomPopView:OnEnter(nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bSave = nLevel == nil
    self.nLevel = nLevel
    self:UpdateInfo()
end

function UIPanelUpgradeChatRoomPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelUpgradeChatRoomPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.bSave then
            RemoteCallToServer("On_Voice_Fixed")
        else
            RemoteCallToServer("On_Voice_LvUp", self.nLevel + 1)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelUpgradeChatRoomPopView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scritItem then
            self.scritItem:RawSetSelected(false)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelExteriorMain then
            UIMgr.Close(self)
        end
    end)
end

function UIPanelUpgradeChatRoomPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelUpgradeChatRoomPopView:GetUseItemNum(dwTabType, dwIndex)
    local player = GetClientPlayer()
    if not player then
        return 0
    end
	return player.GetItemAmount(dwTabType, dwIndex)
end

function UIPanelUpgradeChatRoomPopView:UpdateItem()
    local tbInfo = nil
    local nLevel = self.nLevel
    local bCanUp= true
    if nLevel then
        local tNowLevel = GDAPI_VoiceRoomLvUpCost(nLevel)
        local tNextLevel = GDAPI_VoiceRoomLvUpCost(nLevel + 1)
        if not tNextLevel then
            bCanUp = false
        end
        tbInfo = bCanUp and tNextLevel or tNowLevel
    else
        tbInfo = GDAPI_VoiceRoomLvUpCost(1)
    end
    local tbItem = tbInfo.cost
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem_60)
    script:OnInitWithTabID(tbItem[1], tbItem[2])
    script:SetClickCallback(function(nItemType, nItemIndex)
        TipsHelper.ShowItemTips(script._rootNode, nItemType, nItemIndex, false)
    end)
    self.scritItem = script
    self.tbItem = tbItem

    local nHave = self:GetUseItemNum(tbItem[1], tbItem[2])
    UIHelper.SetString(self.LabelMaterialNum, nHave)
    UIHelper.SetString(self.LabelMaterialNumTotal, tbItem[3])
    UIHelper.SetColor(self.LabelMaterialNum, nHave >= tbItem[3] and cc.c3b(149, 255, 149) or cc.c3b(255, 130, 136))
    UIHelper.LayoutDoLayout(self.LayoutMaterialNum)

    local nState = (bCanUp and nHave >= tbItem[3]) and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnConfirm, nState)
end

function UIPanelUpgradeChatRoomPopView:UpdateTitle()
    local szTitle = self.bSave and "升级为永久聊天室" or "升级语音聊天室"
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIPanelUpgradeChatRoomPopView:UpdateOtherInfo()

    if not self.bSave then
        local nLevel = self.nLevel
        local tNowLevel = GDAPI_VoiceRoomLvUpCost(nLevel)
        local tNextLevel = GDAPI_VoiceRoomLvUpCost(nLevel + 1)
        local bCanUp = true
        if not tNextLevel then
            bCanUp = false
        end

        local nLevel = self.nLevel
        local nNextLevel = bCanUp and nLevel + 1 or nLevel
        UIHelper.SetString(self.LabelLevelBefore, nLevel)
        UIHelper.SetString(self.LabelLevelAfter, nNextLevel)

        UIHelper.SetString(self.LabelEnterNumBefore, tNowLevel.num)
        UIHelper.SetString(self.LabelEnterNumAfter, bCanUp and tNextLevel.num or tNowLevel.num)
    end

    UIHelper.SetVisible(self.WidgetLevelUpgrade, not self.bSave)
    UIHelper.SetVisible(self.WidgetEnterNumUpgrade, not self.bSave)
    UIHelper.SetVisible(self.LabelGuHuaHint, self.bSave)
end

function UIPanelUpgradeChatRoomPopView:UpdateInfo()
    self:UpdateItem()
    self:UpdateTitle()
    self:UpdateOtherInfo()
end


return UIPanelUpgradeChatRoomPopView