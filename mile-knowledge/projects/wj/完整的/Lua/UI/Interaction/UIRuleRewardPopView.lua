-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRuleRewardPopView
-- Date: 2023-06-30 16:29:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRuleRewardPopView = class("UIRuleRewardPopView")

local m_tMasterReward = {--师父奖励
	{5, 22216, 1}, -- 桃李芬芳
	{5, 5170, 1}, -- 桃李情
}
local m_tApprenticeReward = {--徒弟奖励
	{5, 21496, 1}, -- 知遇礼盒？
	{5, 21504, 1},
}
local m_tDirectMasterReward1 = {--亲传师父普通奖励
	{5, 47799, 10},
	{5, 47794, 20},
	{5, 71540, 12},
	{5, 71543, 80},
}
local m_tDirectMasterReward2 = {--亲传师父吃鸡奖励
	{5, 47787, 10},
}

function UIRuleRewardPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIRuleRewardPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRuleRewardPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLabel1, EventType.OnClick, function ()
        local tAward = m_tMasterReward[1]
        TipsHelper.ShowItemTips(self.BtnLabel1,tAward[1],tAward[2])
    end)

    UIHelper.BindUIEvent(self.BtnLabel_3, EventType.OnClick, function ()
        local tAward = m_tMasterReward[1]
        TipsHelper.ShowItemTips(self.BtnLabel_3,tAward[1],tAward[2])
    end)

    UIHelper.BindUIEvent(self.BtnLabel2, EventType.OnClick, function ()
        local tAward = m_tMasterReward[2]
        TipsHelper.ShowItemTips(self.BtnLabel2,tAward[1],tAward[2])
    end)

    UIHelper.BindUIEvent(self.BtnLabel3, EventType.OnClick, function ()
        local tAward = m_tApprenticeReward[1]
        TipsHelper.ShowItemTips(self.BtnLabel3,tAward[1],tAward[2])
    end)

    UIHelper.BindUIEvent(self.BtnLabel4, EventType.OnClick, function ()
        local _, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnLabel4)
        local szText = "<color=#ffe26e>师恩重</c>\n完成大战任务和首次满额据点贸易日常任务时,若师父在队伍中开且在少侠附近,则会消耗一层,同时少侠和师父均可获得额外奖励。"
        scriptTips:OnEnter(szText)
    end)

    UIHelper.BindUIEvent(self.BtnAwardTips,EventType.OnClick,function ()
        local tbPoint = self.tbInfo.tPoint or {self.tbInfo.fX, self.tbInfo.fY, self.tbInfo.fZ}
        MapMgr.SetTracePoint(UIHelper.GBKToUTF8(self.tbInfo.szNpcName), self.tbInfo.dwMapID, tbPoint)
        UIMgr.Open(VIEW_ID.PanelMiddleMap, self.tbInfo.dwMapID, 0)
        UIMgr.Close(self)
    end)
end

function UIRuleRewardPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRuleRewardPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRuleRewardPopView:UpdateInfo()
    UIHelper.SetString(self.LabelNum, tostring(g_pClientPlayer.nMentorAward) .." / ".. tostring(g_pClientPlayer.GetMaxMentorAward()))

    local tAllLinkInfo = Table_GetCareerGuideAllLink(2044) -- 纪天下的LinkID
    self.tbInfo = tAllLinkInfo[1]

    local m_tValueGiftInfo = Table_GetMentorPanelValueGift()
    for k,v in ipairs(m_tValueGiftInfo) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionRewardAward,self.LayoutAwardMain,v)
    end

    UIHelper.LayoutDoLayout(self.LayoutAwardMain)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScorllViewReward)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAreanList)
end


return UIRuleRewardPopView