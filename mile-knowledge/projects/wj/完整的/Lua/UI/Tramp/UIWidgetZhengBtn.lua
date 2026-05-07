-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetZhengBtn
-- Date: 2023-04-24 11:41:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetZhengBtn = class("UIWidgetZhengBtn")

function UIWidgetZhengBtn:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetZhengBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetZhengBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTop, EventType.OnClick, function()
        self.tbInfo[3].callback()
    end)

    UIHelper.BindUIEvent(self.BtnMiddle, EventType.OnClick, function()
        self.tbInfo[2].callback()
    end)

    UIHelper.BindUIEvent(self.BtnDown, EventType.OnClick, function()
        self.tbInfo[1].callback()
    end)
end

function UIWidgetZhengBtn:RegEvent()
    Event.Reg(self, "OnSkillBoxFlash", function(nSkillID, bStart, nCount)
        UIHelper.SetVisible(self.Eff_UITop, self.tbInfo[3].id == nSkillID and bStart)
        UIHelper.SetVisible(self.Eff_UIMiddle, self.tbInfo[2].id == nSkillID and bStart)
        UIHelper.SetVisible(self.Eff_UIDown, self.tbInfo[1].id == nSkillID and bStart)
    end)
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        for _, tData in ipairs(self.tbInfo) do
            if tData.key == szKeyName then
                tData.callback()
                break
            end
        end
    end)
    Event.Reg(self, "OnMobileKeyboardConnected", function()
        self:UpdateKey()
    end)
    Event.Reg(self, "OnMobileKeyboardDisConnected", function()
        self:UpdateKey()
    end)
end

function UIWidgetZhengBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetZhengBtn:UpdateInfo()
    UIHelper.SetButtonClickSound(self.BtnTop, "")
    UIHelper.SetButtonClickSound(self.BtnDown, "")
    UIHelper.SetButtonClickSound(self.BtnMiddle, "")
    UIHelper.SetClickInterval(self.BtnTop, 0)
    UIHelper.SetClickInterval(self.BtnDown, 0)
    UIHelper.SetClickInterval(self.BtnMiddle, 0)

    -- 具体使用快捷键见UIPanelPlayZheng.lua
    UIHelper.SetString(self.LabelTop, string.format("[%s]", ShortcutInteractionData.GetKeyViewName(self.tbInfo[3].key)))
    UIHelper.SetString(self.LabelMiddle, string.format("[%s]", ShortcutInteractionData.GetKeyViewName(self.tbInfo[2].key)))
    UIHelper.SetString(self.LabelDown, string.format("[%s]", ShortcutInteractionData.GetKeyViewName(self.tbInfo[1].key)))

    self:UpdateKey()
end

function UIWidgetZhengBtn:UpdateKey()
    local bShowKey = Platform.IsWindows() or Platform.IsMac() or KeyBoard.MobileHasKeyboard() or false
    UIHelper.SetVisible(self.LabelTop, bShowKey)
    UIHelper.SetVisible(self.LabelMiddle, bShowKey)
    UIHelper.SetVisible(self.LabelDown, bShowKey)
end


return UIWidgetZhengBtn