-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerConfigurationTog
-- Date: 2024-08-07 10:21:49
-- Desc: 侠客预设编队组件
-- Prefab: WidgetPartnerConfigurationTog
-- ---------------------------------------------------------------------------------

local REMOTE_PARTNER_PRESET      = 1170 --远程数据块ID
local REMOTE_DATA_TEAM_INDEX_POS = 0 --当前正在使用的编队序号在远程数据块中存储的位置
local PRESET_TEAM_COUNT          = 4

---@class UIPartnerConfigurationTog
local UIPartnerConfigurationTog  = class("UIPartnerConfigurationTog")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerConfigurationTog:_LuaBindList()
    self.TogShowTeamPlanList      = self.TogShowTeamPlanList --- 显示编队方案列表的toggle

    self.tTeamPlanBtnList         = self.tTeamPlanBtnList --- 编队方案按钮列表

    self.LabelCurrentTeamPlanName = self.LabelCurrentTeamPlanName --- 当前编队名称

    self.tLabelNameList           = self.tLabelNameList --- 名称的label列表
    self.tBtnRenameList           = self.tBtnRenameList --- 重命名按钮列表

    self.BtnPartnerSetClose       = self.BtnPartnerSetClose --- 全屏的遮罩按钮，用于点击空白把列表收起来
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerConfigurationTog:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerConfigurationTog:OnEnter()
    self.nUseIndex        = nil
    self.tPreSetData      = nil
    self.bDataSyncSuccess = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateTeamPlanNames()

    g_pClientPlayer.ApplyRemoteData(REMOTE_PARTNER_PRESET, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
end

function UIPartnerConfigurationTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerConfigurationTog:BindUIEvent()
    for idx = 1, PRESET_TEAM_COUNT do
        UIHelper.BindUIEvent(self.tTeamPlanBtnList[idx], EventType.OnClick, function()
            local nTeamIndex = idx - 1
            self:SwitchToTeamPlan(nTeamIndex)
        end)

        UIHelper.BindUIEvent(self.tBtnRenameList[idx], EventType.OnClick, function()
            local nTeamIndex = idx - 1

            self:TryRenameTeamPlan(nTeamIndex)
        end)
    end

    UIHelper.BindUIEvent(self.BtnPartnerSetClose, EventType.OnClick, function()
        self:Close()
    end)
end

function UIPartnerConfigurationTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "REMOTE_HEROPRESET_EVENT", function()
        self:UpdatePreSetData()
    end)
end

function UIPartnerConfigurationTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerConfigurationTog:UpdateInfo()

end

function UIPartnerConfigurationTog:UpdatePreSetData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if not pPlayer.HaveRemoteData(REMOTE_PARTNER_PRESET) then
        TipsHelper.ShowNormalTip(g_tStrings.STR_PARTNER_PRESET_DATA_DOWNLOAD_FAIL)
        self:Close()
        return
    end

    local nRemoteTeamIndex = pPlayer.GetRemoteArrayUInt(REMOTE_PARTNER_PRESET, REMOTE_DATA_TEAM_INDEX_POS, 1)
    local tPreSetData      = GDAPI_Partner_GetAllAssistPresetTeam(pPlayer)
    if not tPreSetData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_PARTNER_PRESET_DATA_DOWNLOAD_FAIL)
        self:Close()
        return
    end

    self.tPreSetData = tPreSetData
    if not self.nUseIndex or self.nUseIndex ~= nRemoteTeamIndex then
        self.nUseIndex = nRemoteTeamIndex
        self:UpdateCurrentTeamPlanName()
    end
    self.bDataSyncSuccess = true
end

function UIPartnerConfigurationTog:SwitchToTeamPlan(nTeamIndex)
    if not self.bDataSyncSuccess or not self.nUseIndex then
        return
    end

    if not nTeamIndex or nTeamIndex == self.nUseIndex then
        self:Close()
        return
    end
    
    --- 通知召请界面，避免因切换编队而触发侠客阵容变更时，召请界面误以为完成了召请留存，关闭了界面
    Event.Dispatch("PartnerSyncAssistedListWithTeamPlan")

    RemoteCallToServer("On_Partner_SetAssistPresetIndex", nTeamIndex)
    self:Close()
end

function UIPartnerConfigurationTog:UpdateTeamPlanNames()
    for idx = 1, PRESET_TEAM_COUNT do
        local szName = self:GetTeamPlanName(idx - 1)
        UIHelper.SetString(self.tLabelNameList[idx], szName)
    end

    self:UpdateCurrentTeamPlanName()
end

function UIPartnerConfigurationTog:UpdateCurrentTeamPlanName()
    if not self.nUseIndex then
        return
    end

    local szName = self:GetTeamPlanName(self.nUseIndex)

    UIHelper.SetString(self.LabelCurrentTeamPlanName, szName)
end

function UIPartnerConfigurationTog:TryRenameTeamPlan(nTeamIndex)
    local szOldName = self:GetTeamPlanName(nTeamIndex)

    local editBox   = UIMgr.Open(VIEW_ID.PanelPromptPop, szOldName, "请输入编队的新名字", function(szText)
        if szText == "" then
            TipsHelper.ShowNormalTip("内容不能为空")
            return
        end

        if TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then
            Storage.PartnerAssistTeamPlanNames[nTeamIndex + 1] = szText
            Storage.PartnerAssistTeamPlanNames.Dirty()

            self:UpdateTeamPlanNames()
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
        end
    end)
    editBox:SetTitle("助战编队")
    editBox:SetMaxLength(8)
end

function UIPartnerConfigurationTog:GetTeamPlanName(nTeamIndex)
    local szName = Storage.PartnerAssistTeamPlanNames[nTeamIndex + 1] or string.format("助战编队%s", g_tStrings.STR_NUMBER[nTeamIndex + 1])

    return szName
end

--- 关闭展开的编队列表
function UIPartnerConfigurationTog:Close()
    UIHelper.SetSelected(self.TogShowTeamPlanList, false)
end

return UIPartnerConfigurationTog