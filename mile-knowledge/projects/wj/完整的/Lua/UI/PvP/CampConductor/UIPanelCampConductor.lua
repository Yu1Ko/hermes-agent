-- ---------------------------------------------------------------------------------
-- Name: UIPanelCampConductor
-- Desc: 阵营指挥管理页面
-- Prefab:PanelCampConductor
-- ---------------------------------------------------------------------------------

local UIPanelCampConductor = class("UIPanelCampConductor")

local tRankingTypes = {
	214,
	215,
}

function UIPanelCampConductor:_LuaBindList()
    self.BtnClose    = self.BtnClose
    self.BtnRule      = self.BtnRule --- 规则btn
    self.BtnRemovePlayer           = self.BtnRemovePlayer --- 踢玩家

    self.BtnNominateConductor      = self.BtnNominateConductor --- 任命指挥btn

    self.TogMaterials              = self.TogMaterials --- 物资tog
    self.TogCrew                   = self.TogCrew --- 玩家tog
    self.TogFaction                = self.TogFaction --- 帮会tog

    self.WidgetContentMaterials    = self.WidgetContentMaterials --- 物资分页
    self.WidgetManageCrew          = self.WidgetManageCrew --- 玩家分页
    self.WidgetManageFaction       = self.WidgetManageFaction --- 玩家分页

    self.WidgetAddCampFaction      = self.WidgetAddCampFaction --- 添加帮会分页
    self.WidgetAddCampCrew         = self.WidgetAddCampCrew --- 添加玩家分页
end

function UIPanelCampConductor:OnEnter()
    if not self.bInit then
        self:Init()
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self:Open()
end

function UIPanelCampConductor:OnExit()
    self:StopApply()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCampConductor:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelConductorRulePop)
    end)

    UIHelper.BindUIEvent(self.BtnRemovePlayer, EventType.OnClick, function()
        -- self:GetRights()
        UIMgr.Open(VIEW_ID.PanelRemovePlayerPop)
    end)

    UIHelper.BindUIEvent(self.BtnNominateConductor, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelNominateConductor)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogMaterials, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetVisible(self.WidgetContentMaterials, true)
            UIHelper.SetVisible(self.WidgetManageCrew, false)
            UIHelper.SetVisible(self.WidgetManageFaction, false)

            UIHelper.SetVisible(self.WidgetAddCampFaction, false)
            UIHelper.SetVisible(self.WidgetAddCampCrew, false)

            -- if self.scriptMaterialsTip then
            --     UIHelper.RemoveFromParent(self.scriptMaterialsTip._rootNode, true)
            --     self.scriptMaterialsTip = nil
            -- end
            self.scriptOfMaterials:HideMaterialsTips()
        end
    end)

    UIHelper.BindUIEvent(self.TogCrew, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetVisible(self.WidgetContentMaterials, false)
            UIHelper.SetVisible(self.WidgetManageCrew, true)
            UIHelper.SetVisible(self.WidgetManageFaction, false)

            UIHelper.SetVisible(self.WidgetAddCampFaction, false)
            UIHelper.SetVisible(self.WidgetAddCampCrew, false)

            -- if self.scriptMaterialsTip then
            --     UIHelper.RemoveFromParent(self.scriptMaterialsTip._rootNode, true)
            --     self.scriptMaterialsTip = nil
            -- end
            self.scriptOfMaterials:HideMaterialsTips()
        end
    end)

    UIHelper.BindUIEvent(self.TogFaction, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetVisible(self.WidgetContentMaterials, false)
            UIHelper.SetVisible(self.WidgetManageCrew, false)
            UIHelper.SetVisible(self.WidgetManageFaction, true)

            UIHelper.SetVisible(self.WidgetAddCampFaction, false)
            UIHelper.SetVisible(self.WidgetAddCampCrew, false)

            -- if self.scriptMaterialsTip then
            --     UIHelper.RemoveFromParent(self.scriptMaterialsTip._rootNode, true)
            --     self.scriptMaterialsTip = nil
            -- end
            self.scriptOfMaterials:HideMaterialsTips()
        end
    end)
end

function UIPanelCampConductor:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function()
        
    end)

    Event.Reg(self, "ON_CAMP_PLANT_APPLY_COMMANDER_INFO_RESPOND", function(arg0, arg1, arg2)
        --arg0, arg1, arg2 分别代表物资、核心管理人员、帮会白名单数据是否发生改变
        if arg0 == true then 
			self.scriptOfMaterials:UpdateInfo()
		end
		if arg1 == true then 
			CommandBaseData.ClearPlayerInfo()
            CommandBaseData.InitManagerList(true)
		end
		if arg2 == true then
			
		end
    end)

    Event.Reg(self, "On_CAMP_PLAYER_LOGIN", function(dwID, bOnline)
		
    end)


    -- Event.Reg(self, "UPDATE_COMMAND_DISTRIBUTE", function()
	-- 	if CommandDistribute.IsOpened() then 
	-- 		CommandDistribute.Open(m_tLastDistributedGood.nType, m_tLastDistributedGood.szName, m_tLastDistributedGood.nNumRest, m_tPlayerInfo, m_tPlayerIDInMemberList)
	-- 	end
    -- end)

    Event.Reg(self, EventType.OnSceneTouchTarget, function()
        if self.scriptOfMaterials:GetMaterialsTips() then
            self.scriptOfMaterials:HideMaterialsTips()
            return
        end

        if self.scriptOfAddPlayer:IsOpen() then
            self.scriptOfAddPlayer:Close()
            return 
        end

        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if self.scriptOfMaterials:GetMaterialsTips() then
            self.scriptOfMaterials:HideMaterialsTips()
            return
        end

        if self.scriptOfAddPlayer:IsOpen() then
            self.scriptOfAddPlayer:Close()
            return 
        end

        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptOfMaterials:GetMaterialsTips() then
            self.scriptOfMaterials:HideMaterialsTips()
            return
        end
    end)

    --批量添加核心人员
    Event.Reg(self, EventType.OnBatchAddPlayer, function()
        self.scriptOfAddPlayer:Open()
    end)

    --批量添加帮会
    Event.Reg(self, EventType.OnBatchAddFaction, function()
        -- self.scriptOfAddFaction
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.WidgetFoceDoAlign(self)
    end)

    Event.Reg(self, "CMDSETTING_MEMBER_CHANGE", function()
        self:SetConBtnRights()
    end)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelChatSocial then
            self.scriptOfAddPlayer:Close()
        end
    end)
end

function UIPanelCampConductor:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCampConductor:Init()
    self.scriptOfMaterials = UIHelper.GetBindScript(self.WidgetContentMaterials)
    -- self.scriptOfMaterials:SetMaterialsCallback(function(nIndex)
    --     self:ShowMaterialsTips(nIndex)
    -- end)
    self.scriptOfPlayer = UIHelper.GetBindScript(self.WidgetManageCrew)
    self.scriptOfFaction = UIHelper.GetBindScript(self.WidgetManageFaction)

    self.scriptOfAddFaction = UIHelper.GetBindScript(self.WidgetAddCampFaction)
    self.scriptOfAddPlayer = UIHelper.GetBindScript(self.WidgetAddCampCrew)
end

function UIPanelCampConductor:Open()
    if CommandBaseData.IsCommanderMeetCondition() or CommandBaseData.IsViceCommanderMeetCondition() then
		if #CommandBaseData.tbCastleList == 0 then 
			RemoteCallToServer("On_Camp_GFGetCastleInfo")
		end
        ApplyCustomRankList(tRankingTypes[g_pClientPlayer.nCamp])
        UIHelper.SetSelected(self.TogMaterials, true)
        self.scriptOfMaterials:UpdateInfo()
        self:BreathApply()
        self:SetKickBtnRights()
    else
        UIMgr.Close(self)
	end
end

-- 物资相关begin

function UIPanelCampConductor:ShowMaterialsTips(nIndex)
    if not self.scriptMaterialsTip then
        self.scriptMaterialsTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAniRight)
    end
    self.scriptMaterialsTip:OnInitConductorMaterialsTip(nIndex)
end


-- 物资相关end

function UIPanelCampConductor:BreathApply()
    self:StopApply()
    self.nTimer = Timer.AddCycle(self, 1, function()
        local CP = GetCampPlantManager()
        CP.ApplyCommanerInfo()
    end)
end

function UIPanelCampConductor:StopApply()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end


-- 按钮权限相关 begin
-- scripts tCommanderRights.tRights
function UIPanelCampConductor:SetKickBtnRights()
    local nRoleType = CommandBaseData.GetRoleType()
    local nRoleLevel = CommandBaseData.GetRoleLevel()
    if nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        UIHelper.SetButtonState(self.BtnRemovePlayer, BTN_STATE.Normal)
    else
        if nRoleLevel == 3 or nRoleLevel == 4 then
            UIHelper.SetButtonState(self.BtnRemovePlayer, BTN_STATE.Normal) 
        else
            UIHelper.SetButtonState(self.BtnRemovePlayer, BTN_STATE.Disable, g_tStrings["STR_COMMAND_PRIORITY".. nRoleLevel .."_TIP"])
        end
	end
    -- UIHelper.SetVisible(self.BtnNominateConductor, nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER)
    UIHelper.SetVisible(self.BtnRemovePlayer, nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER or nRoleLevel == 3)--主指挥或副指挥
end

function UIPanelCampConductor:SetConBtnRights()
    local dwID = GetClientPlayer().dwID
    local bTeamMember = CommandBaseData.tPlayerInfo and CommandBaseData.tPlayerInfo[dwID] and 
		CommandBaseData.tPlayerInfo[dwID]["tNumberInfo"]["DeputyInfo"][6]

	if bTeamMember ~= TEAM_MEMBER_TYPE.leader then
        UIHelper.SetString(self.LabelNominateConductor, g_tStrings.STR_COMMAND_VIEW_COMMANDER)
	end
end

-- 按钮权限相关 end

return UIPanelCampConductor