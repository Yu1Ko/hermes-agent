-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentRankingInfo
-- Date: 2023-02-22 10:39:34
-- Desc: 隐元秘鉴 - 五甲 - 成就widget - 排行信息 - 排行widget
-- Prefab: WidgetAchievementContentRankCell
-- ---------------------------------------------------------------------------------

---@class UIAchievementContentRankingInfo
local UIAchievementContentRankingInfo = class("UIAchievementContentRankingInfo")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentRankingInfo:_LuaBindList()
    self.ImgRankingFirstThree = self.ImgRankingFirstThree --- 排名的图片，仅前三使用图片，其余的使用label
    self.LabelRankOthers      = self.LabelRankOthers --- 排名的label
    self.LabelName            = self.LabelName --- 名称
    self.LabelTime            = self.LabelTime --- 达成时间
    self.TogShowDetailTips    = self.TogShowDetailTips --- 点击显示队伍详细信息的 Tog
end

---@param uiAchievementContentRankPopView UIAchievementContentRankPopView
function UIAchievementContentRankingInfo:OnEnter(uiAchievementContentRankPopView, nRanking, tLeader, aGroup, szServer)
    self.uiAchievementContentRankPopView = uiAchievementContentRankPopView
    
    self.nRanking = nRanking
    self.tLeader  = tLeader
    self.aGroup   = aGroup
    self.szServer = szServer

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentRankingInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentRankingInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.TogShowDetailTips, EventType.OnClick, function()
        -- 仅队伍需要显示额外的tips
        if #self.aGroup == 0 then
            return
        end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetRankTeamTips)
        -- 显示详细队伍信息
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRankTeamTips, self.uiAchievementContentRankPopView.WidgetRankTeamTips, TipsLayoutDir.MIDDLE, 
                                              self.aGroup, self.szServer)
        end)
    end)
end

function UIAchievementContentRankingInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementContentRankingInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local tRankingToImg = {
    [1] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking01.png",
    [2] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking02.png",
    [3] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking03.png",
}

function UIAchievementContentRankingInfo:UpdateInfo()
    --tLeader = {szName, szTongName, nTime, dwFoceID, nCamp}
    --aGroup = list tMember
    --    tMember = {szName, szTongName, nTime, dwFoceID, nCamp}
    local szName, szTongName, nTime, dwFoceID, nCamp = table.unpack(self.tLeader)

    local szShowName                                 = UIHelper.GBKToUTF8(szName)
    if #(self.aGroup) > 0 then
        szShowName = szShowName .. g_tStrings.ACHIVEMENT_BY_TEAM
    end

    local time   = TimeToDate(nTime)
    local szTime = FormatString(g_tStrings.STR_TIME_2, time.year, time.month, time.day, time.hour, time.minute, time.second)

    UIHelper.SetVisible(self.ImgRankingFirstThree, false)
    UIHelper.SetVisible(self.LabelRankOthers, false)
    if self.nRanking <= 3 then
        -- 前三名使用图片
        local szRankingImg = tRankingToImg[self.nRanking]
        UIHelper.SetSpriteFrame(self.ImgRankingFirstThree, szRankingImg)
        UIHelper.SetVisible(self.ImgRankingFirstThree, true)
    else
        -- 其余使用label
        UIHelper.SetString(self.LabelRankOthers, self.nRanking)
        UIHelper.SetVisible(self.LabelRankOthers, true)
    end

    UIHelper.SetString(self.LabelName, szShowName)
    UIHelper.SetString(self.LabelTime, szTime)

    -- 确保初始状态为未选中
    UIHelper.SetSelected(self.TogShowDetailTips, false)
end

return UIAchievementContentRankingInfo