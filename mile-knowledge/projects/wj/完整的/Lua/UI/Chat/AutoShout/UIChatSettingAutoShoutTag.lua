-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutTag
-- Date: 2024-10-14 19:51:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSettingAutoShoutTag = class("UIChatSettingAutoShoutTag")

function UIChatSettingAutoShoutTag:OnEnter(bTog, bDots)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bTog = bTog
    self.bDots = bDots or false

    UIHelper.SetVisible(self.LabelOption, bTog)
    UIHelper.SetVisible(self.ImgOptionBg01, bTog and not bDots)
    UIHelper.SetVisible(self.ImgOptionBg02, bTog and bDots)
    UIHelper.SetVisible(self.LabelOther, not bTog)
end

function UIChatSettingAutoShoutTag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutTag:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnOnSelectTag then
            self.fnOnSelectTag(bSelected)
        end
    end)
end

function UIChatSettingAutoShoutTag:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatSettingAutoShoutTag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingAutoShoutTag:SetTitle(szTitle)
    local label = self.bTog and self.LabelOption or self.LabelOther
    UIHelper.SetString(label, szTitle)
end

function UIChatSettingAutoShoutTag:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self._rootNode, bSelected, bCallback)
end

function UIChatSettingAutoShoutTag:BindOnSelectChanged(fnOnSelectTag)
    self.fnOnSelectTag = fnOnSelectTag
end

return UIChatSettingAutoShoutTag