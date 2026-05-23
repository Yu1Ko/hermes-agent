-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentRankPlayerCell
-- Date: 2023-02-22 16:05:08
-- Desc: 隐元秘鉴 - 五甲 - 成就widget - 排行信息 - 排行widget - 队伍信息widget - 队员信息widget
-- Prefab: WidgetAchievementContentRankPlayerCell
-- ---------------------------------------------------------------------------------

local UIAchievementContentRankPlayerCell = class("UIAchievementContentRankPlayerCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentRankPlayerCell:_LuaBindList()
    self.LabelNameAndServerName = self.LabelNameAndServerName --- 玩家名称@服务器名称
    self.ImgSchool              = self.ImgSchool --- 门派图标
end

function UIAchievementContentRankPlayerCell:OnEnter(tMember, szServer)
    -- tMember = {szName, szTongName, nTime, dwFoceID, nCamp}
    self.tMember  = tMember
    self.szServer = szServer

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentRankPlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentRankPlayerCell:BindUIEvent()

end

function UIAchievementContentRankPlayerCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementContentRankPlayerCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentRankPlayerCell:UpdateInfo()
    local szName, szTongName, nTime, dwFoceID, nCamp = table.unpack(self.tMember)

    local szShowName                                 = UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(szName), 8)
    local szForceIconPath                            = PlayerForceID2SchoolImg[dwFoceID]

    UIHelper.SetString(self.LabelNameAndServerName, szShowName)
    UIHelper.SetSpriteFrame(self.ImgSchool, szForceIconPath)
end

return UIAchievementContentRankPlayerCell