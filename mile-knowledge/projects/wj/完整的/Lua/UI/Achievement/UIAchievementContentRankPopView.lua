-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentRankPopView
-- Date: 2023-02-21 19:29:45
-- Desc: 隐元秘鉴 - 五甲 - 成就widget - 排行信息
-- Prefab: PanelAchievementContentRankPop
-- ---------------------------------------------------------------------------------

---@class UIAchievementContentRankPopView
local UIAchievementContentRankPopView = class("UIAchievementContentRankPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentRankPopView:_LuaBindList()
    self.BtnClose              = self.BtnClose --- 关闭界面
    self.LabelName             = self.LabelName --- 成就名称
    self.LabelServerName       = self.LabelServerName --- 服务器名称

    self.ScrollViewRankingInfo = self.ScrollViewRankingInfo --- 排名信息的 scroll view
    self.LayoutRankingInfo     = self.LayoutRankingInfo --- 排名信息的 layout

    self.LayoutServer          = self.LayoutServer --- 服务器名称的layout
    self.WidgetEmpty           = self.WidgetEmpty --- 没有数据时的空状态

    self.WidgetRankTeamTips    = self.WidgetRankTeamTips --- 挂载队伍信息的节点
end

function UIAchievementContentRankPopView:OnEnter(dwAchievementID)
    self.dwAchievementID = dwAchievementID

    self.aAchievement    = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentRankPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentRankPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementContentRankPopView:RegEvent()
    Event.Reg(self, "ON_SYNC_RANKING_INFO", function(dwAchievement, tRankingInfo, bStatic)
        self:OnSyncRankingInfo(dwAchievement, tRankingInfo, bStatic)
    end)
end

function UIAchievementContentRankPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentRankPopView:UpdateInfo()
    local szRealServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer().szRealServer

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.aAchievement.szName))
    UIHelper.SetString(self.LabelServerName, szRealServer)

    self:UpdateRankingShow()
end

function UIAchievementContentRankPopView:UpdateRankingShow()
    self:RequestRanking()
    self:UpdateRankingData()
end

function UIAchievementContentRankPopView:RequestRanking()
    local t = AchievementData.aRanking[self.dwAchievementID]
    if not t or (not t.bNoNeedUpdate and GetTickCount() - t.nTime > 2000) then
        -- 下面这些情况下尝试请求数据
        -- 1. 本地没有数据
        -- 2. 该排行榜配置为需要更新，且距离上次更新时间已经超过两秒（控制频率）
        RemoteCallToServer("OnQueryRankingInfo", self.dwAchievementID)
    end
end

function UIAchievementContentRankPopView:OnSyncRankingInfo(dwAchievement, tRankingInfo, bStatic)
    local a       = AchievementData.aRanking[dwAchievement]

    local bChange = false
    if not a or #(a.aInfo) ~= #tRankingInfo then
        bChange = true
    else
        for i, v in ipairs(a) do
            local vO = tRankingInfo[i]
            if not vO or v[1] ~= vO[1] and #(v[2]) ~= #(vO[2]) then
                bChange = true
                break
            end

            for j, vA in ipairs(v[2]) do
                if vO[2][j] ~= vA then
                    bChange = true
                    break
                end
            end
            if bChange then
                break
            end
        end
    end

    AchievementData.aRanking[dwAchievement] = {
        aInfo = tRankingInfo,
        bNoNeedUpdate = bStatic,
        nTime = GetTickCount(),
    }
    if bChange and self.dwAchievementID == dwAchievement then
        self:UpdateRankingData()
    end
end

function UIAchievementContentRankPopView:UpdateRankingData()
    local bHasData = false

    UIHelper.RemoveAllChildren(self.ScrollViewRankingInfo)

    local dwAchievement = self.dwAchievementID
    local szRealServer  = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer().szRealServer

    local aRankingSome  = AchievementData.aRanking[dwAchievement] or {}
    local aInfo         = aRankingSome.aInfo or {}

    self:AppendRankingData(szRealServer, aInfo)

    bHasData             = bHasData or not table_is_empty(aInfo)

    -- 合并过来的服务器的排行信息
    local tMergedRanking = MergedServer.tMergedRanking
    if tMergedRanking then
        local tServers = MergedServer.GetInterworkingServers(szRealServer) or EMPTY_TABLE
        for i, szServer in ipairs(tServers) do
            local tOrg  = tMergedRanking[szServer] or {}
            local aInfo = tOrg[dwAchievement] or {}
            if #aInfo > 0 then
                self:AppendRankingData(FormatString(g_tStrings.ORG_SERVER, UIHelper.GBKToUTF8(szServer)), aInfo)
            end

            bHasData = bHasData or not table_is_empty(aInfo)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRankingInfo, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewRankingInfo)
    UIHelper.ScrollToTop(self.ScrollViewRankingInfo, 0)

    UIHelper.SetVisible(self.LayoutServer, bHasData)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasData)
end

function UIAchievementContentRankPopView:AppendRankingData(szServer, aInfo)
    -- 数据格式如下
    -- tRankingInfo = list {tLeader, aGroup}
    --      tLeader = {szName, szTongName, nTime, dwFoceID, nCamp}
    --      aGroup = list tMember
    --          tMember = {szName, szTongName, nTime, dwFoceID, nCamp}
    for i, v in ipairs(aInfo) do
        local nRanking        = i
        local tLeader, aGroup = table.unpack(v)

        ---@type UIAchievementContentRankingInfo
        UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementContentRankCell, self.ScrollViewRankingInfo, self,
                           nRanking, tLeader, aGroup, szServer
        )
    end
end

return UIAchievementContentRankPopView