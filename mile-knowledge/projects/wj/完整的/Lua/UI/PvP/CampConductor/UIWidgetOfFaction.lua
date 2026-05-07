-- ---------------------------------------------------------------------------------
-- Name: UIWidgetOfFaction
-- Desc: 阵营指挥管理--帮会管理分页
-- Prefab:PanelCampConductor--WidgetManageFaction
-- ---------------------------------------------------------------------------------

local UIWidgetOfFaction = class("UIWidgetOfFaction")

function UIWidgetOfFaction:_LuaBindList()
    self.LabelPlayerStatus    = self.LabelPlayerStatus --- 玩家权限总指挥、副指挥
    self.LabelFactionNum      = self.LabelFactionNum --- 当前帮会数量

    self.ScrollView           = self.ScrollView --- 加载帮会cell的Scroll WidgeCampFactionCell

    self.LayoutBtnNormal      = self.LayoutBtnNormal --- 批量移除和添加layout
    self.BtnBatchRemove       = self.BtnBatchRemove --- 批量移除btn
    self.BtnBatchAdd          = self.BtnBatchAdd --- 批量添加btn

    self.LayoutBtnBatchRemove      = self.LayoutBtnBatchRemove --- 点击批量移除后layout
    self.BtnCancel            = self.BtnCancel --- 取消移除btn
    self.BtnComfirm           = self.BtnComfirm --- 确认移除btn
end

--已废弃核心帮会，这段代码不会跑
function UIWidgetOfFaction:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
        self.cellPool = PrefabPool.New(PREFAB_ID.WidgeManageCampFactionCell)
    end
    self:UpdateCoreGang()
end

function UIWidgetOfFaction:OnExit()
    self.bInit = false
    if self.cellPool then
        self.cellPool:Dispose()
        self.cellPool = nil
    end
    self:UnRegEvent()
end

function UIWidgetOfFaction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBatchRemove, EventType.OnClick, function()
        UIHelper.SetVisible(self.LayoutBtnNormal, false)
        UIHelper.SetVisible(self.LayoutBtnBatchRemove, true)
        self:StartDeletePeople()
    end)

    UIHelper.BindUIEvent(self.BtnBatchAdd, EventType.OnClick, function()
        Event.Dispatch(EventType.OnBatchAddFaction)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:EndDeletePeople()
        UIHelper.SetVisible(self.LayoutBtnNormal, true)
        UIHelper.SetVisible(self.LayoutBtnBatchRemove, false)
    end)

    UIHelper.BindUIEvent(self.BtnComfirm, EventType.OnClick, function()
        self:EndDeletePeople()
        CommandBaseData.DeleteTong()
    end)
end

function UIWidgetOfFaction:RegEvent()

    Event.Reg(self, "On_Camp_GFGetCastleInfo", function(tbCastleLsit)
        CommandBaseData.SetCastleList(tbCastleLsit)
        self.tbCastleLsit = tbCastleLsit
        self.nCastleEvent = 1
        self:UpdateCoreGang()
    end)

    Event.Reg(self, "CUSTOM_RANK_UPDATE", function()
        CommandBaseData.GetTongRankList()
        self.nRanListEvent = 1
        self:UpdateCoreGang()
    end)

    Event.Reg(self, "ON_CAMP_PLANT_APPLY_COMMANDER_INFO_RESPOND", function()
        if arg2 == true then
            self:UpdateCoreGang()
        end
    end)
end

function UIWidgetOfFaction:UnRegEvent()

end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UIWidgetOfFaction:InitPermissionInfo()
    local nRoleType = CommandBaseData.GetRoleType()
	local nRoleLevel = CommandBaseData.GetRoleLevel()

	if nRoleType == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings.STR_COMMAND_PRIORITY_COMMANDER)
		-- szTips = g_tStrings.STR_COMMAND_PRIORITY_COMMANDER_TIP
	elseif nRoleType == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER then
		-- szTips = g_tStrings["STR_COMMAND_PRIORITY"..nRoleLevel.."_TIP"]
        UIHelper.SetString(self.LabelPlayerStatus, g_tStrings["STR_COMMAND_PRIORITY"..nRoleLevel])
	end


end

function UIWidgetOfFaction:RemoveAllTong()
    if self.tbNode then
        for nIndex, tbInfo in ipairs(self.tbNode) do
            self.cellPool:Recycle(tbInfo.node)
        end
    end
    self.tbNode = {}
end

function UIWidgetOfFaction:UpdateCoreGang()
    if self.nCastleEvent and self.nRanListEvent then
        self:RemoveAllTong()
        local tbTongList = CommandBaseData.GetCoreTongList()
        for nIndex, nTongID in ipairs(tbTongList) do
            local node, scriptView = self.cellPool:Allocate(self.ScrollView, nTongID, false, function(bSelect)
                if bSelect then
                    CommandBaseData.AddDeleteTong(nTongID)
                else
                    CommandBaseData.RemoveDeleteTong(nTongID)
                end
            end)
            table.insert(self.tbNode, {node = node, scriptView = scriptView})
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
        UIHelper.SetString(self.LabelFactionNum, tostring(#tbTongList))
    end
end

function UIWidgetOfFaction:StartDeletePeople()
    for nIndex, tbInfo in ipairs(self.tbNode) do
        local scriptView = tbInfo.scriptView
        scriptView:SetDeleteToggle(true)
    end
end

function UIWidgetOfFaction:EndDeletePeople()
    for nIndex, tbInfo in ipairs(self.tbNode) do
        local scriptView = tbInfo.scriptView
        scriptView:SetDeleteToggle(false)
    end
end

return UIWidgetOfFaction