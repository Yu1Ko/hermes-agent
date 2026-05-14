-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetPermissionsManagementPermissions
-- Date: 2023-01-07 20:21:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class WidgetPermissionsManagementPermissions
local WidgetPermissionsManagementPermissions = class("WidgetPermissionsManagementPermissions")

function WidgetPermissionsManagementPermissions:OnEnter(tbInfo)
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

function WidgetPermissionsManagementPermissions:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetPermissionsManagementPermissions:BindUIEvent()
    for index, toggle in ipairs(self.tbToggle) do
        UIHelper.SetClickInterval(toggle, 0)
        
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(btn, bSelect)
            if not self.tbInfo.Tips[index] then
                Event.Dispatch(EventType.TongGroupSelectPermission)
            end
            if self.tbInfo.Tips[index] then
                Timer.AddFrame(self, 1, function()
                    UIHelper.SetSelected(toggle, self.tbInfo.tbPermission[index], false)
                    self.tbInfo.Tips[index]()
                end)
            end
        end)
    end
end

function WidgetPermissionsManagementPermissions:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function WidgetPermissionsManagementPermissions:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function WidgetPermissionsManagementPermissions:OnRecycled()
    UIHelper.SetVisible(self._rootNode, false)
    self.tbInfo = nil
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetPermissionsManagementPermissions:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    
    local szTitleName = self.tbInfo.szName
    if szTitleName == "普通帮众" then
        szTitleName = szTitleName .. "(" .. g_tStrings.STR_GUILD_BASIC_ACCESS_NAME[1] .. ")"
    end
    UIHelper.SetString(self.LabelTitle, szTitleName)
    
    for index, szName in ipairs(self.tbInfo.tbName) do
       UIHelper.SetVisible(self.tbToggle[index], true)
       UIHelper.SetSelected(self.tbToggle[index], self.tbInfo.tbPermission[index], false)
    --    UIHelper.SetEnable(self.tbToggle[index], self.tbInfo.tbCanGrant[index])
       UIHelper.SetNodeGray(self.tbToggle[index],not self.tbInfo.tbCanGrant[index], true)
       UIHelper.SetString(self.tbLabelSelect[index], szName)
    end
   
    for index = #self.tbInfo.tbName + 1, #self.tbToggle do
        UIHelper.SetVisible(self.tbToggle[index], false)
    end
end

function WidgetPermissionsManagementPermissions:ApplyManageChange()
   
    local tbSelect = {}
    for index, toggle in ipairs(self.tbToggle) do
        if UIHelper.GetVisible(toggle) then
            local bSelect = UIHelper.GetSelected(toggle)
            table.insert(tbSelect, bSelect)
        end
    end

    self.tbInfo.callback(tbSelect)
end

return WidgetPermissionsManagementPermissions