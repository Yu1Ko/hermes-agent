-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPermissionsMember
-- Date: 2023-01-07 17:25:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPermissionsMember = class("UIWidgetPermissionsMember")

function UIWidgetPermissionsMember:OnEnter(tbInfo)
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

function UIWidgetPermissionsMember:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPermissionsMember:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function(toggle, bSelect)
        Event.Dispatch(EventType.TongGroupSelectPeople, bSelect)
    end)
end

function UIWidgetPermissionsMember:RegEvent()
end

function UIWidgetPermissionsMember:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetPermissionsMember:OnRecycled()
    UIHelper.SetVisible(self._rootNode, false)
    self.tbInfo = nil
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPermissionsMember:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelRoleName, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelGrade, self.tbInfo.nLevel.."级")
    UIHelper.SetString(self.LabelEquipScore, self.tbInfo.nEquipScore)
     -- 头像
    self:UpdatePlayerIcon(true)

    UIHelper.SetSelected(self.TogSelect, false, false)
end

function UIWidgetPermissionsMember:UpdatePlayerIcon(bUpdateIfNotExists)
    local dwMiniAvatarID = 0
    local nRoleType      = nil
    local dwForceID      = self.tbInfo.nForceID

    UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, nRoleType, dwForceID, true)
end

function UIWidgetPermissionsMember:SwitchToggleSelect(bVisible)
    UIHelper.SetVisible(self.TogSelect, bVisible)
end

function UIWidgetPermissionsMember:GetSelected()
    return UIHelper.GetSelected(self.TogSelect)
end

function UIWidgetPermissionsMember:SetSelect(bSelect)
    UIHelper.SetSelected(self.TogSelect, bSelect)
end

function UIWidgetPermissionsMember:GetID()
    return self.tbInfo.dwID
end


return UIWidgetPermissionsMember