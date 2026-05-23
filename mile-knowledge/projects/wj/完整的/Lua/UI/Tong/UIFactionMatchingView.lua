-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionMatchingView
-- Date: 2024-01-16 19:42:52
-- Desc: 帮会约战排队
-- Prefab: PanelFactionMatching
-- ---------------------------------------------------------------------------------

---@class UIFactionMatchingView
local UIFactionMatchingView = class("UIFactionMatchingView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionMatchingView:_LuaBindList()
    self.BtnClose             = self.BtnClose --- 关闭界面

    self.BtnTeam              = self.BtnTeam --- 组队匹配按钮
    self.BtnPersonal          = self.BtnPersonal --- 个人匹配按钮
    self.BtnMatching          = self.BtnMatching --- 匹配中按钮

    self.LayoutText           = self.LayoutText --- 右侧文本上层layout
    self.LabelMatchingTimeNum = self.LabelMatchingTimeNum --- 匹配时长
    self.LabelMatchingTime    = self.LabelMatchingTime --- 匹配描述
    self.LabelTime            = self.LabelTime --- 不良记录禁止参战剩余时间

    self.LabelTitle           = self.LabelTitle --- 左上角标题
    self.LabelInfoTitle       = self.LabelInfoTitle --- 右方信息的标题
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIFactionMatchingView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIFactionMatchingView:OnEnter(dwGuildFightNpc)
    self.dwGuildFightNpc = dwGuildFightNpc


    self.dwMapID, _ = self:GetGuildFightMapIDAndName()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.5, function()
        self:OnUpdateTime()
    end)
end

function UIFactionMatchingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionMatchingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnPersonal, EventType.OnClick, function()
        if BattleFieldQueueData.IsCanEnterTongBattleField() then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JION_QUEUE_TIP1)
            return
        end
        self:EnterGuildFightQueue(false)
    end)
    
    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function()
        if BattleFieldQueueData.IsCanEnterTongBattleField() then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JION_QUEUE_TIP1)
            return
        end
        self:EnterGuildFightQueue(true)
    end)
    
    UIHelper.BindUIEvent(self.BtnMatching, EventType.OnClick, function()
        BattleFieldQueueData.DoLeaveTongBattleFieldQueue(self.dwMapID)
    end)
end

function UIFactionMatchingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "PARTY_DISBAND", function()
        self:UpdateBtnState()
    end)
    
    Event.Reg(self, "TONG_BATTLE_FIELD_STATE_UPDATE", function()
        self:UpdateBtnState()
    end)
    
    Event.Reg(self, "JOIN_TONG_BATTLE_FIELD_QUEUE", function(nErrorCode, dwErrorRoleID, szErrorRoleName)
        szErrorRoleName = UIHelper.GBKToUTF8(szErrorRoleName)
        
        OutputMessage("MSG_SYS", FormatString(g_tStrings.tTongBattleFieldResult[nErrorCode], szErrorRoleName))
        OutputMessage("MSG_ANNOUNCE_YELLOW", FormatString(g_tStrings.tTongBattleFieldResult[nErrorCode], szErrorRoleName).."\n")
    end)
end

function UIFactionMatchingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionMatchingView:UpdateInfo()
    self:UpdateBtnState()
end

function UIFactionMatchingView:UpdateBtnState()
    --local bCanOperateMatch = not BattleFieldQueueData.IsInBattleFieldBlackList()
    local bCanOperateMatch = true
    
    local bInQueue         = BattleFieldQueueData.IsInTongBattleFieldQueue(self.dwMapID)

    local bCanTeamMatch    = false
    local hPlayer          = GetClientPlayer()
    if hPlayer.IsInParty() and hPlayer.IsPartyLeader() then
        bCanTeamMatch = true
    end

    local bMatchSuccess = BattleFieldQueueData.IsCanEnterTongBattleField()

    UIHelper.SetVisible(self.LabelTime, not bCanOperateMatch)
    UIHelper.SetVisible(self.LabelMatchingTime, bInQueue)
    UIHelper.SetVisible(self.BtnPersonal, not bInQueue and not bMatchSuccess)
    UIHelper.SetVisible(self.BtnTeam, not bInQueue and not bMatchSuccess)
    UIHelper.SetVisible(self.BtnMatching, bInQueue or bMatchSuccess)

    UIHelper.SetButtonState(self.BtnPersonal, bCanOperateMatch and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnTeam, (bCanOperateMatch and bCanTeamMatch) and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnMatching, not bMatchSuccess and BTN_STATE.Normal or BTN_STATE.Disable)

    if bCanOperateMatch and bInQueue then
        self:InitMatchTime(self.dwMapID)
    else
        --self:InitBlackStateTime()
    end

    UIHelper.LayoutDoLayout(self.LayoutText)
end

--更新匹配/惩罚时间
function UIFactionMatchingView:OnUpdateTime()
    local player = g_pClientPlayer
    if self.dwGuildFightNpc then
        local npc = GetNpc(self.dwGuildFightNpc)
        if not npc or not npc.CanDialog(player) then
            UIMgr.Close(self)
        end
    end
    self:UpdateMatchTime()
    --self:UpdateBlackStateTime()
end

--匹配时间
function UIFactionMatchingView:InitMatchTime(dwMapID)
    self.m_bUpdateMatchTime = true
    local nTime             = BattleFieldQueueData.GetJoinTongBattleQueueTime(dwMapID)
    local nCurrentTime      = GetCurrentTime()
    if nTime then
        self.m_nMatchStartTime = nCurrentTime - nTime
    else
        self.m_nMatchStartTime = nil
    end
    self.m_bUpdateMatchTime = false
end

--界面上更新匹配时间
function UIFactionMatchingView:UpdateMatchTime()
    if self.m_nMatchStartTime and not self.m_bUpdateMatchTime then
        local nTime     = GetCurrentTime()
        local nShowTime = nTime - self.m_nMatchStartTime

        local dwMapID   = self.dwMapID
        local bInQueue  = BattleFieldQueueData.IsInTongBattleFieldQueue(dwMapID)

        if not bInQueue then
            return
        end

        local szTime = BattleFieldQueueData.FormatBattleFieldTime(nShowTime)
        UIHelper.SetString(self.LabelMatchingTimeNum, szTime)
    end
end

function UIFactionMatchingView:EnterGuildFightQueue(bTeam)
    JoinTongBattleFieldQueue(bTeam)
end

function UIFactionMatchingView:GetGuildFightMapList()
    local tResult = {}
    local nRow = g_tTable.BattleField:GetRowCount()
    for i = 2, nRow, 1 do
        local tLine = g_tTable.BattleField:GetRow(i)
        if tLine.nType == BATTLEFIELD_MAP_TYPE.TONGBATTLE then
            table.insert(tResult, {dwMapID = tLine.dwMapID, szMapName = tLine.szName})
        end
    end

    return tResult
end

---@return number, string
function UIFactionMatchingView:GetGuildFightMapIDAndName()
    local tList = self:GetGuildFightMapList()
    if #tList == 0 then
        return 0, ""
    end
    
    local tMapInfo = tList[1]
    return tMapInfo.dwMapID, UIHelper.GBKToUTF8(tMapInfo.szMapName)
end

return UIFactionMatchingView