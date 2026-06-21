-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISetCodeUploadTag
-- Date: 2024-07-30 17:41:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISetCodeUploadTag = class("UISetCodeUploadTag")

function UISetCodeUploadTag:OnEnter(szName, bIsSingle, funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = szName
    self.bIsSingle = bIsSingle
    self.funcClickCallback = funcClickCallback
    self:UpdateInfo()
end

function UISetCodeUploadTag:OnExit()
    self.bInit = false
end

function UISetCodeUploadTag:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function(btn)
        if self.funcClickCallback then
            self.funcClickCallback()
        end
    end)
end

function UISetCodeUploadTag:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISetCodeUploadTag:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, PlayerEquipTags2Chinese[self.szName])
    UIHelper.SetVisible(self.WidgetSingle, self.bIsSingle)
    UIHelper.SetVisible(self.WidgetMulti, not self.bIsSingle)
end


return UISetCodeUploadTag