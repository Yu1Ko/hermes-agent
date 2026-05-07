-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDropListItem
-- Date: 2022-11-28 15:01:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDropListItem = class("UIDropListItem")

function UIDropListItem:OnEnter(nKey, szText, selectCallback, bIsChecked)
    self.nKey = nKey
    self.szText = szText
    self.selectCallback = selectCallback
    self.bIsChecked = bIsChecked

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIDropListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDropListItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.selectCallback then
            self.selectCallback(self.nKey, self.szText)
        end
    end)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if self.clickCallback then
            self.clickCallback(self.nKey, self.szText)
        end
    end)
end

function UIDropListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDropListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDropListItem:UpdateInfo()
    UIHelper.SetString(self.LabelSelect, self.szText)
    UIHelper.SetSelected(self.ToggleSelect, self.bIsChecked)
    UIHelper.SetString(self.LabelNormal, self.szText)
end

function UIDropListItem:SetClickCallback(fnCallback)
    self.clickCallback = fnCallback
end


return UIDropListItem