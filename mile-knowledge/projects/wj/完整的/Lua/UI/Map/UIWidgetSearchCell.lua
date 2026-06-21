-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSearchCell
-- Date: 2024-06-19 15:02:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSearchCell = class("UIWidgetSearchCell")

function UIWidgetSearchCell:OnEnter(tbNpcInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbNpcInfo = tbNpcInfo
    self:UpdateInfo()
end

function UIWidgetSearchCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSearchCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelectNpc, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            Event.Dispatch(EventType.OnClickSearchList, self.tbNpcInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        Event.Dispatch(EventType.OnClickSearchList, self.tbNpcInfo)
    end)
end

function UIWidgetSearchCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSearchCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSearchCell:UpdateInfo()
    local szName = self.tbNpcInfo.szName
    local nCount = #self.tbNpcInfo.tbNpcList
    UIHelper.SetString(self.Label1, szName .. "（" .. nCount .. "）")
    UIHelper.SetString(self.Label2, szName .. "（" .. nCount .. "）")

    UIHelper.SetVisible(self.BtnDetail, false)
    UIHelper.SetToggleGroupIndex(self.TogSelectNpc, ToggleGroupIndex.TongMemberFilter)
end

function UIWidgetSearchCell:SetSelectedWithCallBack(bSelected)
    UIHelper.SetSelected(self.TogSelectNpc, bSelected)
end

function UIWidgetSearchCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogSelectNpc, bSelected, false)
end


return UIWidgetSearchCell