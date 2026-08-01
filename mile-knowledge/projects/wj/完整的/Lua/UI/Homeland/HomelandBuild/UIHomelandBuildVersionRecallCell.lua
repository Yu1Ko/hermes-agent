-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildVersionRecallView
-- Date: 2023-06-05 15:51:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildVersionRecallView = class("UIHomelandBuildVersionRecallView")

function UIHomelandBuildVersionRecallView:OnEnter(nIndex, onClickCallback)
    self.nIndex = nIndex
    self.onClickCallback = onClickCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildVersionRecallView:OnExit()
    self.bInit = false
end

function UIHomelandBuildVersionRecallView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if self.onClickCallback then
            self.onClickCallback()
        end
    end)
end

function UIHomelandBuildVersionRecallView:RegEvent()

end

function UIHomelandBuildVersionRecallView:UpdateInfo()
    UIHelper.SetString(self.LabelVersionName, g_tStrings.tStrHomelandRevertToVersion[self.nIndex])
end


return UIHomelandBuildVersionRecallView