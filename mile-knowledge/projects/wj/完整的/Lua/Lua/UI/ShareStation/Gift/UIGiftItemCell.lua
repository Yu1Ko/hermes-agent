-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGiftItemCell
-- Date: 2025-09-22 17:31:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGiftItemCell = class("UIGiftItemCell")

function UIGiftItemCell:OnEnter(tUIInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tUIInfo = tUIInfo
    self:UpdateInfo()
end

function UIGiftItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGiftItemCell:BindUIEvent()
    
end

function UIGiftItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGiftItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGiftItemCell:UpdateInfo()
    if not self.tUIInfo then
        return
    end

    local szName = self.tUIInfo.szName
    local nGold = self.tUIInfo.nGoldNum
    local szIcon = self.tUIInfo.szImagePath
    szIcon = UIHelper.FixDXUIImagePath(szIcon)

    UIHelper.SetString(self.LabelGiftName, UIHelper.GBKToUTF8(szName))
    UIHelper.SetString(self.LabelMoney_Jin, nGold)
    UIHelper.SetVisible(self.ImgGift, true)
    UIHelper.SetTexture(self.ImgGift, szIcon)
    UIHelper.LayoutDoLayout(self.WidgetMoneyJin)
end

function UIGiftItemCell:GetToggle()
    if self.TogGift then
        return self.TogGift
    end
end


return UIGiftItemCell