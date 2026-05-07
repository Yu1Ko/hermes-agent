-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelAddVipTimePopView
-- Date: 2025-09-18 15:28:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelAddVipTimePopView = class("UIPanelAddVipTimePopView")

function UIPanelAddVipTimePopView:OnEnter(nTime)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nTime = nTime
    self:UpdateInfo()
end

function UIPanelAddVipTimePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelAddVipTimePopView:BindUIEvent()
    UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function()
        local nCount = tonumber(UIHelper.GetText(self.WidgetEdit))
        self:SetCount(nCount)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function()
        self:SetCount(self.nMaxCount)
    end)

    UIHelper.BindUIEvent(self.BtnPlus, EventType.OnClick, function()
        self:SetCount(self.nCount + 1)
    end)

    UIHelper.BindUIEvent(self.BtnSubtract, EventType.OnClick, function()
        self:SetCount(self.nCount - 1)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        RemoteCallToServer("On_Voice_SuperRoom", self.nCount, self.nTime)
        UIMgr.Close(self)
    end)
end


function UIPanelAddVipTimePopView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.script then
            self.script:RawSetSelected(false)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelExteriorMain then
            UIMgr.Close(self)
        end
    end)
end

function UIPanelAddVipTimePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAddVipTimePopView:GetUseItemNum(dwTabType, dwIndex)
    local player = GetClientPlayer()
    if not player then
        return 0
    end
	return player.GetItemAmount(dwTabType, dwIndex)
end

function UIPanelAddVipTimePopView:UpdateInfo()
    local nTime = self.nTime
    local tbSuperInfo = GDAPI_VoiceRoomSuperCost()
    local tbItem = tbSuperInfo.cost
    local nHave = self:GetUseItemNum(tbItem[1], tbItem[2])
    self.script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem_60)
    self.script:OnInitWithTabID(tbItem[1], tbItem[2], nHave)
    self.script:SetClickCallback(function(nItemType, nItemIndex)
        TipsHelper.ShowItemTips(self.script._rootNode, nItemType, nItemIndex, false)
    end)

     local nCurrentTime = GetCurrentTime()
    local nRemainTime = 0
    if nTime > nCurrentTime then
        nRemainTime = nTime - nCurrentTime
    end
    UIHelper.SetString(self.LabelTimeNow, TimeLib.GetTimeText(nRemainTime, false, true))

    self.nMaxCount = math.min(3, math.floor(nHave / tbItem[3]))
    self:SetCount(0)
end

function UIPanelAddVipTimePopView:SetCount(nCount)
    self.nCount = math.max(0, nCount)
    self.nCount = math.min(self.nMaxCount, self.nCount)
    self:UpdateCount()
    self:UpdateTime()
end

function UIPanelAddVipTimePopView:UpdateCount()
    local nCount =self.nCount
    local nLessState = nCount > 0 and BTN_STATE.Normal or BTN_STATE.Disable
    local nAddState = nCount < self.nMaxCount and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnSubtract, nLessState)
    UIHelper.SetButtonState(self.BtnPlus, nAddState)
    UIHelper.SetButtonState(self.BtnMax, nAddState)

    UIHelper.SetText(self.WidgetEdit, nCount)
end

function UIPanelAddVipTimePopView:UpdateTime()
    UIHelper.SetString(self.LabelTimeAdd, FormatString(g_tStrings.STR_MAIL_LEFT_DAY, self.nCount * 30))
end

return UIPanelAddVipTimePopView