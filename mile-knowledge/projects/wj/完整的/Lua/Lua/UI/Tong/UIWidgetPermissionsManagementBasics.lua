-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetPermissionsManagementBasics
-- Date: 2023-01-07 20:11:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class WidgetPermissionsManagementBasics
local WidgetPermissionsManagementBasics = class("WidgetPermissionsManagementBasics")

function WidgetPermissionsManagementBasics:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbInfo then
        self.tbInfo = tbInfo
        self:UpdateInfo()
    end
end

function WidgetPermissionsManagementBasics:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetPermissionsManagementBasics:BindUIEvent()
    UIHelper.SetClickInterval(self.TogBasicsPermissions, 0)

    -- UIHelper.BindUIEvent(btn, nEventType, func)
    UIHelper.BindUIEvent(self.TogBasicsPermissions, EventType.OnSelectChanged, function(btn, bSelect)
        if not self.tbInfo.tips then
            Event.Dispatch(EventType.TongGroupSelectPermission)
        end
        if self.tbInfo.tips then
            Timer.AddFrame(self, 1, function()
                UIHelper.SetSelected(self.TogBasicsPermissions, self.tbInfo.bPermission, false)
                self.tbInfo.tips()
            end)
        end
    end)

end

function WidgetPermissionsManagementBasics:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function WidgetPermissionsManagementBasics:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function WidgetPermissionsManagementBasics:OnRecycled()
    UIHelper.SetVisible(self._rootNode, false)
    self.tbInfo = nil
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetPermissionsManagementBasics:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelBasicsPermissions, self.tbInfo.szName)
    UIHelper.SetSelected(self.TogBasicsPermissions, self.tbInfo.bPermission, false)
    -- UIHelper.SetEnable(self.TogBasicsPermissions, self.tbInfo.bCanGrant)
    UIHelper.SetNodeGray(self.TogBasicsPermissions,not self.tbInfo.bCanGrant, true)
end



function WidgetPermissionsManagementBasics:ApplyManageChange()
    local bSelect = UIHelper.GetSelected(self.TogBasicsPermissions)
    self.tbInfo.callback(bSelect)
end


return WidgetPermissionsManagementBasics