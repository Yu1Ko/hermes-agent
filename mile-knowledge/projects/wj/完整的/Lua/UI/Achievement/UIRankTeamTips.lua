-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIRankTeamTips
-- Date: 2023-02-22 15:54:17
-- Desc: 隐元秘鉴 - 五甲 - 成就widget - 排行信息 - 排行widget - 队伍信息widget
-- Prefab: WidgetRankTeamTips
-- ---------------------------------------------------------------------------------

local UIRankTeamTips = class("UIRankTeamTips")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIRankTeamTips:_LuaBindList()
    self.LayoutMemberInfo = self.LayoutMemberInfo --- 队伍信息的 layout
end

function UIRankTeamTips:OnEnter(aGroup, szServer)
    --aGroup = list tMember
    --    tMember = {szName, szTongName, nTime, dwFoceID, nCamp}
    self.aGroup   = aGroup
    self.szServer = szServer

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRankTeamTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRankTeamTips:BindUIEvent()

end

function UIRankTeamTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRankTeamTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRankTeamTips:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutMemberInfo)

    for _, tMember in ipairs(self.aGroup) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementContentRankPlayerCell, self.LayoutMemberInfo,
                           tMember, self.szServer
        )
    end

    UIHelper.LayoutDoLayout(self.LayoutMemberInfo)
end

return UIRankTeamTips