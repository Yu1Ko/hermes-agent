-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICohabitedHouseEndCohabitCell
-- Date: 2023-07-26 15:02:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICohabitedHouseEndCohabitCell = class("UICohabitedHouseEndCohabitCell")

function UICohabitedHouseEndCohabitCell:OnEnter(tbInfo, funcGetStringTerminateCohabitLeftTime, funcSelectedCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self.funcSelectedCallback = funcSelectedCallback
    self.funcGetStringTerminateCohabitLeftTime = funcGetStringTerminateCohabitLeftTime

    self:UpdateInfo()
end

function UICohabitedHouseEndCohabitCell:OnExit()
    self.bInit = false
end

function UICohabitedHouseEndCohabitCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRoleName, EventType.OnClick, function ()
        if self.funcSelectedCallback and (self.tbInfo.KickOutTime <= 0 or self.tbInfo.KickOutDrawer) then
            self.funcSelectedCallback(self.tbInfo)
        end
    end)
end

function UICohabitedHouseEndCohabitCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICohabitedHouseEndCohabitCell:UpdateInfo()
    UIHelper.SetString(self.LabelNum, UIHelper.GBKToUTF8(self.tbInfo.Name))

    if self.tbInfo.KickOutTime and self.tbInfo.KickOutTime > 0 then
        local szTime = ""
        if self.tbInfo.KickOutDrawer then
            szTime = string.format("门客正退出共居，%s后将终止共居状态", self.funcGetStringTerminateCohabitLeftTime(GetCurrentTime() - self.tbInfo.KickOutTime))
            UIHelper.SetButtonState(self.TogRoleName, BTN_STATE.Normal)
        else
            szTime = string.format("正在请门客离开，%s后或门客同意将生效", self.funcGetStringTerminateCohabitLeftTime(GetCurrentTime() - self.tbInfo.KickOutTime))
            UIHelper.SetButtonState(self.TogRoleName, BTN_STATE.Disable)
        end
        UIHelper.SetString(self.LabelTime, szTime)
        UIHelper.SetVisible(self.LabelTime, true)
        -- UIHelper.SetSelected(self.TogRoleName, not self.tbInfo.KickOutDrawer)
        UIHelper.SetVisible(self.TogRoleName, self.tbInfo.KickOutDrawer)
    else
        UIHelper.SetButtonState(self.TogRoleName, BTN_STATE.Normal)
        UIHelper.SetVisible(self.LabelTime, false)
        UIHelper.SetVisible(self.TogRoleName, true)
    end

    UIHelper.LayoutDoLayout(self.LayoutText)
end


return UICohabitedHouseEndCohabitCell