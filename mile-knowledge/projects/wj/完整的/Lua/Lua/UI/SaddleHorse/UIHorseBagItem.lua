-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHorseBagItem
-- Date: 2023-07-04 09:54:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHorseBagItem = class("UIHorseBagItem")

function UIHorseBagItem:OnEnter(nTabType, nTabID, bTab)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if bTab then
        self.nTabType = nTabType
        self.nTabID = nTabID
    else
        self.dwBox = nTabType
        self.dwX = nTabID
    end

    self:UpdateInfoByTab()
end

function UIHorseBagItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHorseBagItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.funcClickCallback(self.dwBox, self.dwX)
        end
    end)
end

function UIHorseBagItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if UIHelper.GetSelected(self.ToggleSelect) then
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    end)
end

function UIHorseBagItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHorseBagItem:UpdateInfoByTab()
    local item
    if self.nTabType and self.nTabID then
        item = ItemData.GetItemInfo(self.nTabType, self.nTabID)
    else
        item = ItemData.GetItemByPos(self.dwBox, self.dwX)
    end
    if not item then return end

    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[item.nQuality + 1])

    local bResult = UIHelper.SetItemIconByItemInfo(self.ImgIcon, item)
    if not bResult then
        UIHelper.ClearTexture(self.ImgIcon)
    end
end

function UIHorseBagItem:SetCurEquiped(bSelected)
    UIHelper.SetVisible(self.ImgSelectedRT, bSelected)
end

function UIHorseBagItem:SetOtherEquiped(bSelected)
    UIHelper.SetVisible(self.WidgetOtherEquiped, bSelected)
end

function UIHorseBagItem:SetClickCallback(callback)
    self.funcClickCallback = callback
end

return UIHorseBagItem