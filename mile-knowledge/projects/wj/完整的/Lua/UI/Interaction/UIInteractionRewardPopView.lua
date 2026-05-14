-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractionRewardPopView
-- Date: 2023-02-09 17:12:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractionRewardPopView = class("UIInteractionRewardPopView")

local m_tMasterReward = {--师父奖励
	{5, 22216, 1}, -- 桃李芬芳
	{5, 5170, 1}, -- 桃李情
}
local m_tDirectMasterReward1 = {--亲传师父普通奖励
    {5, 85498, 10},
    {5, 85494, 20},
    {5, 71540, 12},
    {5, 71543, 80},
}
local m_tApprenticeReward = {--徒弟奖励
	{5, 21496, 1}, -- 知遇礼盒？
	{5, 21504, 1},
}
local m_tDirectMasterReward2 = {--亲传师父吃鸡奖励
    {5, 85493, 10},
}
function UIInteractionRewardPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIInteractionRewardPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractionRewardPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLabel1,EventType.OnClick,function ()
        local tAward = m_tMasterReward[1]
        self:ShowRewardTip(tAward)
    end)

    UIHelper.BindUIEvent(self.BtnLabel2,EventType.OnClick,function ()
        local tAward = m_tMasterReward[2]
        self:ShowRewardTip(tAward)
    end)

    UIHelper.BindUIEvent(self.BtnLabel1A,EventType.OnClick,function ()
        local tAward = m_tApprenticeReward[1]
        self:ShowRewardTip(tAward)
    end)

    UIHelper.BindUIEvent(self.BtnLabel5,EventType.OnClick,function ()
        local tAward = m_tApprenticeReward[2]
        self:ShowRewardTip(tAward)
    end)

    -- for k,v in ipairs(self.tbTogTeacherTitle) do
    --     UIHelper.BindUIEvent(v,EventType.OnSelectChanged,function (_,bSelected)
    --         UIHelper.SetVisible(self.tbWidgetTeacherLabel[k],bSelected)
    --         if k == 4 then
    --             self:SetRewardVisible(bSelected)
    --         end
    --         UIHelper.ScrollViewDoLayout(self.ScrollView)
    --         UIHelper.ScrollToTop(self.ScrollView,0)
    --     end)
    -- end

    -- UIHelper.BindUIEvent(self.BtnMask,EventType.OnClick,function ()
    --     UIHelper.RemoveAllChildren(self.WidgetItemTip)
    --     UIHelper.SetVisible(self.WidgetItemTip,false)
    --     UIHelper.SetVisible(self.BtnMask,false)

    -- end)

    UIHelper.BindUIEvent(self.BtnAwardTips,EventType.OnClick,function ()
        local tbPoint = self.tbInfo.tPoint or {self.tbInfo.fX, self.tbInfo.fY, self.tbInfo.fZ}
        MapMgr.SetTracePoint(UIHelper.GBKToUTF8(self.tbInfo.szNpcName), self.tbInfo.dwMapID, tbPoint)
        UIMgr.Open(VIEW_ID.PanelMiddleMap, self.tbInfo.dwMapID, 0)
        UIMgr.Close(self)
    end)
end

function UIInteractionRewardPopView:RegEvent()
end

function UIInteractionRewardPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionRewardPopView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAwardList)

    local m_tValueGiftInfo = Table_GetMentorPanelValueGift()
    local tAllLinkInfo = Table_GetCareerGuideAllLink(2044) -- 纪天下的LinkID
    self.tbInfo = tAllLinkInfo[1]
    for k,v in ipairs(m_tValueGiftInfo) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionRewardAward,self.ScrollViewAwardList,v)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAwardList)
    UIHelper.ScrollToTop(self.ScrollViewAwardList,0)
end

function UIInteractionRewardPopView:SetRewardVisible(bVisible)
    UIHelper.SetVisible(self.LabelAwardTips,bVisible)
end

function UIInteractionRewardPopView:ShowRewardTip(tAward)
    UIHelper.SetVisible(self.WidgetItemTip,true)
    UIHelper.SetVisible(self.BtnMask,true)
    UIHelper.RemoveAllChildren(self.WidgetItemTip)
    TipsHelper.ShowItemTips(self.BtnLabel1A, tAward[1],tAward[2])
end

return UIInteractionRewardPopView