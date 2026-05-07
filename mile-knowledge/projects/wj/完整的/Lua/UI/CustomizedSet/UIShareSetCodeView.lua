-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareSetCodeView
-- Date: 2024-07-16 11:13:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareSetCodeView = class("UIShareSetCodeView")

function UIShareSetCodeView:OnEnter(szCode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szCode = szCode
    self:UpdateInfo()
end

function UIShareSetCodeView:OnExit()
    self.bInit = false
end

function UIShareSetCodeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        SetClipboard(self.szCode)
        TipsHelper.ShowNormalTip("已复制装备码至剪切板")
    end)
end

function UIShareSetCodeView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UIShareSetCodeView:UpdateInfo()
    UIHelper.SetString(self.LabelCode, self.szCode)
end


return UIShareSetCodeView