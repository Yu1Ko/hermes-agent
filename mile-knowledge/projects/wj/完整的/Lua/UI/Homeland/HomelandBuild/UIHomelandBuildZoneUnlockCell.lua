-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildZoneUnlockCell
-- Date: 2023-05-16 17:24:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildZoneUnlockCell = class("UIHomelandBuildZoneUnlockCell")

function UIHomelandBuildZoneUnlockCell:OnEnter(nIndex, tbConfig, onClickCallback)
    self.nIndex = nIndex
    self.tbConfig = tbConfig
    self.onClickCallback = onClickCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildZoneUnlockCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildZoneUnlockCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogZoneListCell, EventType.OnClick, function ()
        if self.onClickCallback then
            self.onClickCallback()
        end
    end)
end

function UIHomelandBuildZoneUnlockCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildZoneUnlockCell:UpdateInfo()
    UIHelper.SetString(self.LabelZoneNum, UIHelper.GBKToUTF8(self.tbConfig.szAreaName))

end


return UIHomelandBuildZoneUnlockCell