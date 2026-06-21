-- ---------------------------------------------------------------------------------
-- Name: UIWidgetOfPlayer
-- Desc: 阵营指挥管理--玩家管理分页
-- Prefab:PanelCampConductor--WidgetManageCrew
-- ---------------------------------------------------------------------------------
local MEMBER_TYPE_IMAGE = {
    [1] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuguan",
    [2] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_diaoduguan",
    [3] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_fuzhihui",
    [4] = "UIAtlas2_Pvp_CampConductor_PvpCore_img_zhuzhihui",
}
local UIWidgetOfPlayer = class("UIWidgetOfPlayer")

function UIWidgetOfPlayer:_LuaBindList()
    self.LabelPlayerStatus    = self.LabelPlayerStatus --- 玩家权限总指挥、副指挥
    self.BtnAddPlayer         = self.BtnAddPlayer --- 添加玩家
    self.LabelPlayerNum       = self.LabelPlayerNum --- 当前核心玩家数量

    self.ScrollView           = self.ScrollView --- 加载玩家cell的Scroll WidgeCrewPlayerCell

    self.LayoutBtnNormal      = self.LayoutBtnNormal --- 批量移除和添加layout
    self.BtnBatchRemove       = self.BtnBatchRemove --- 批量移除btn
    self.BtnBatchAdd          = self.BtnBatchAdd --- 批量添加btn

    self.LayoutBtnBatchRemove      = self.LayoutBtnBatchRemove --- 点击批量移除后layout
    self.BtnCancel            = self.BtnCancel --- 取消移除btn
    self.BtnComfirm           = self.BtnComfirm --- 确认移除btn
end

function UIWidgetOfPlayer:OnEnter()
    if self.bExit then return end
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.cellRemovePool = PrefabPool.New(PREFAB_ID.WidgeRemoveCrewPlayerTog)
    self.cellPool = PrefabPool.New(PREFAB_ID.WidgeCrewPlayerCell)
    CommandBaseData.InitManagerList(true)
    self:UpdateBtnState()
end

function UIWidgetOfPlayer:OnExit()
    self.bExit = true
    self.bInit = false
    self:UnRegEvent()
    if self.cellPool then 
        self.cellPool:Dispose() 
        self.cellPool = nil
    end
end

function UIWidgetOfPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBatchRemove, EventType.OnClick, function()
        UIHelper.SetVisible(self.LayoutBtnNormal, false)
        UIHelper.SetVisible(self.LayoutBtnBatchRemove, true)
        self:UpdateMembers(true)
    end)

    UIHelper.BindUIEvent(self.BtnBatchAdd, EventType.OnClick, function()
        Event.Dispatch(EventType.OnBatchAddPlayer)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIHelper.SetVisible(self.LayoutBtnNormal, true)
        UIHelper.SetVisible(self.LayoutBtnBatchRemove, false)
        self:UpdateMembers()
    end)

    UIHelper.BindUIEvent(self.BtnComfirm, EventType.OnClick, function()
        UIHelper.SetVisible(self.LayoutBtnNormal, true)
        UIHelper.SetVisible(self.LayoutBtnBatchRemove, false)
        self:UpdateMembers()
        self:ConfirmDeleteMember()
    end)

    UIHelper.BindUIEvent(self.BtnAddPlayer, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelAddCampCrewPop)
    end)
end

function UIWidgetOfPlayer:RegEvent()
    Event.Reg(self, "CMDSETTING_MEMBER_CHANGE", function()
        self:UpdateMembers()
        self:InitPermissionInfo()
    end)

    Event.Reg(self, EventType.AddMemberToRemoveList, function(dwID)
        self:AddMemberToRemoveList(dwID)
    end)

    Event.Reg(self, EventType.RemoveMemberFromRemoveList, function(dwID)
        self:RemoveMemberFromRemoveList(dwID)
    end)

end

function UIWidgetOfPlayer:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOfPlayer:InitPermissionInfo()
    local nRoleType = CommandBaseData.GetRoleType()
	local nRoleLevel = CommandBaseData.GetRoleLevel()

	if nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings.STR_COMMAND_PRIORITY_COMMANDER)
	elseif nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER then
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings["STR_COMMAND_PRIORITY"..nRoleLevel])
	end
    if nRoleLevel then
        UIHelper.SetSpriteFrame(self.ImgStatus, MEMBER_TYPE_IMAGE[nRoleLevel])
    end
end

function UIWidgetOfPlayer:UpdateMembers(bRemove)
    self:RemoveAllMembers()
    local cellPool = self.cellPool
    if bRemove then cellPool = self.cellRemovePool end
    local tbSortedInfo = CommandBaseData.GetPlayerSortedInfo()
    for nIndex, tbInfo in ipairs(tbSortedInfo) do
        local node, script = cellPool:Allocate(self.ScrollView, tbInfo, bRemove)
        table.insert(self.tbMembers, {node = node, script = script, cellPool = cellPool})
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
    UIHelper.SetString(self.LabelPlayerNum, #tbSortedInfo)
end

function UIWidgetOfPlayer:UpdateBtnState()
    local nState = CommandBaseData.GetRoleType() == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnBatchAdd, nState, "暂无权限，无法操作", true)
    UIHelper.SetButtonState(self.BtnBatchRemove, nState, "暂无权限，无法操作", true)
    UIHelper.SetButtonState(self.BtnAddPlayer, nState, "暂无权限，无法操作", true)
end

function UIWidgetOfPlayer:RemoveAllMembers()
    if self.tbMembers then
        for nIndex, tbInfo in ipairs(self.tbMembers) do
            tbInfo.cellPool:Recycle(tbInfo.node)
        end
    end
    self.tbMembers = {}
end

function UIWidgetOfPlayer:AddMemberToRemoveList(dwID)
    if not self.tbRemoveList then self.tbRemoveList = {} end
    table.insert(self.tbRemoveList, dwID)
end

function UIWidgetOfPlayer:RemoveMemberFromRemoveList(dwID)
    if self.tbRemoveList then
        for nIndex, nID in ipairs(self.tbRemoveList) do
            if nID == dwID then
                table.remove(self.tbRemoveList, nIndex)
                break
            end
        end
    end
end

function UIWidgetOfPlayer:ConfirmDeleteMember()
    if not self.tbRemoveList then return end
    if self.nDeleteTimer then return end--正在删除

    local DeleteMember = function()
        if #self.tbRemoveList == 0 then 
            Timer.DelTimer(self, self.nDeleteTimer)
            self.nDeleteTimer = nil
            return 
        end
        local dwID = table.remove(self.tbRemoveList, 1)
        RemoteCallToServer("On_Camp_GFDelMember", dwID)
    end

    DeleteMember()
    self.nDeleteTimer = Timer.AddFrameCycle(self, 2, function()
        DeleteMember()
    end)
end

return UIWidgetOfPlayer