-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAnchorPermissions
-- Date: 2023-01-07 18:54:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAnchorPermissions = class("UIWidgetAnchorPermissions")

local TOTAL_BANK_CNT = 9

function UIWidgetAnchorPermissions:OnEnter(nGroupIndex)
    if not self.bInit then
        self:InitData()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nGroupIndex then
        self.bCanSelect = false
        self.nGroupIndex = nGroupIndex
        self.bOnlyShowOpenAuthority = false
        self:UpdateTogSelect()
        self:UpdateInfo()
    end
end

function UIWidgetAnchorPermissions:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAnchorPermissions:InitData()
    self.tbBasicScript = {}
    self.tbWarehouseScript = {}
    self.tbGroupScript = {}
end

function UIWidgetAnchorPermissions:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm01, EventType.OnClick, function()
        self:ApplyManageChange()
        UIHelper.SetVisible(self.WidgetAnchorTips01, false)
        UIHelper.SetSelected(self.TogManagement01, false)
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetAnchorTips01, false)
        UIHelper.SetSelected(self.TogManagement01, false)
    end)
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function(btn, bSelected)
        self.bOnlyShowOpenAuthority = bSelected
        self:UpdateInfo()
    end)
    UIHelper.BindUIEvent(self.TogManagement01, EventType.OnSelectChanged, function(btn, bSelected)

    end)
end



function UIWidgetAnchorPermissions:RegEvent()
    Event.Reg(self, EventType.TongGroupSelectPermission, function ()
        UIHelper.SetVisible(self.WidgetAnchorTips01, true)
    end)
    Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()
		self:UpdateInfo()
	end)
    Event.Reg(self, "TONG_EVENT_NOTIFY", function()
		if arg0 == TONG_EVENT_CODE.MODIFY_BASE_OPERATION_MASK_SUCCESS then
			TongData.ApplyTongInfo()
        elseif arg0 == TONG_EVENT_CODE.MODIFY_ADVANCE_OPERATION_MASK_SUCCESS then
            TongData.ApplyTongInfo()
		end
	end)
end

function UIWidgetAnchorPermissions:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAnchorPermissions:UpdateInfo()
    -- self.tbScriptView = {}
    self:UpdateBasicPermission()
    self:UpdateWarehousePermission()
    self:UpdateGroupPermission()
    -- UIHelper.LayoutDoLayout(self.LayoutMemberPermissions2)
    UIHelper.ScrollViewDoLayout(self.ScrollViewMemberPermissions2)
    UIHelper.ScrollToTop(self.ScrollViewMemberPermissions2, 0)
end

function UIWidgetAnchorPermissions:UpdateTogSelect()
    UIHelper.SetSelected(self.TogSelect, self.bOnlyShowOpenAuthority, false)
end

function UIWidgetAnchorPermissions:UpdateBasicPermission()
    local tbBasicPermission = TongData.GetCurBasicPermission(self.nGroupIndex, self.bOnlyShowOpenAuthority)
    for index, info in ipairs(tbBasicPermission) do
        local scriptVidew = self.tbBasicScript[index]
        if scriptVidew then
            scriptVidew:OnEnter(info)
        else
            ---@see WidgetPermissionsManagementBasics
            scriptVidew = UIHelper.AddPrefab(PREFAB_ID.WidgetPermissionsManagementBasics, self.LayoutPermissionsManagementBasics, info)
            table.insert(self.tbBasicScript, scriptVidew)
        end
    end
    for index = #tbBasicPermission + 1, #self.tbBasicScript do
        self.tbBasicScript[index]:OnRecycled()
    end

    UIHelper.SetVisible(self.LayoutBasicsPermissions, not (#tbBasicPermission == 0))
    UIHelper.LayoutDoLayout(self.LayoutPermissionsManagementBasics)
    UIHelper.LayoutDoLayout(self.LayoutBasicsPermissions)
end

function UIWidgetAnchorPermissions:UpdateWarehousePermission()

    local tbWarehousePermission = TongData.GetWarehousePermissionList(self.nGroupIndex, self.bOnlyShowOpenAuthority)
    for index, info in ipairs(tbWarehousePermission) do
        local scriptVidew = self.tbWarehouseScript[index]
        if scriptVidew then
            scriptVidew:OnEnter(info)
        else
            ---@see WidgetPermissionsManagementPermissions
            scriptVidew = UIHelper.AddPrefab(PREFAB_ID.WidgetPermissionsManagementPermissions, self.LayoutPermissionsManagement01, info)
            table.insert(self.tbWarehouseScript, scriptVidew)
        end
    end

    for index = #tbWarehousePermission + 1, #self.tbWarehouseScript do
        self.tbWarehouseScript[index]:OnRecycled()
    end

    UIHelper.SetVisible(self.LayoutWarehousePermissions, not (#tbWarehousePermission == 0))

    UIHelper.LayoutDoLayout(self.LayoutPermissionsManagement01)
    UIHelper.LayoutDoLayout(self.LayoutWarehousePermissions)
end

function UIWidgetAnchorPermissions:UpdateGroupPermission()

    local tbGroupPermission = TongData.GetCurGroupPermissionList(self.nGroupIndex, self.bOnlyShowOpenAuthority)
    for index, info in ipairs(tbGroupPermission) do
        local scriptVidew = self.tbGroupScript[index]
        if scriptVidew then
            scriptVidew:OnEnter(info)
        else
            ---@see WidgetPermissionsManagementPermissions
            scriptVidew = UIHelper.AddPrefab(PREFAB_ID.WidgetPermissionsManagementPermissions, self.LayoutPermissionsManagement02, info)
            table.insert(self.tbGroupScript, scriptVidew)
        end
    end

    for index = #tbGroupPermission + 1, #self.tbGroupScript do
        self.tbGroupScript[index]:OnRecycled()
    end

    UIHelper.SetVisible(self.LayoutGroupingPermissions, not (#tbGroupPermission == 0))
    UIHelper.LayoutDoLayout(self.LayoutPermissionsManagement02)
    UIHelper.LayoutDoLayout(self.LayoutGroupingPermissions)
end


function UIWidgetAnchorPermissions:ApplyManageChange()

    for index, scriptVidew in ipairs(self.tbBasicScript) do
        scriptVidew:ApplyManageChange()
    end
    for index, scriptVidew in ipairs(self.tbWarehouseScript) do
        scriptVidew:ApplyManageChange()
    end
    for index, scriptVidew in ipairs(self.tbGroupScript) do
        scriptVidew:ApplyManageChange()
    end
end



return UIWidgetAnchorPermissions