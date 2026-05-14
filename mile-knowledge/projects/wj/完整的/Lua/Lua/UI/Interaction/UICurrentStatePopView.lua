-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrentStatePopView
-- Date: 2023-02-09 14:53:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICurrentStatePopView = class("UICurrentStatePopView")
function UICurrentStatePopView:OnEnter(bCanBeDirectMentor,m_CanFindDirectMasterNum,m_CanFindDirectAppNum,m_CanFindMasterNum,m_CanFindAppNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCanBeDirectMentor = bCanBeDirectMentor --true是亲传师父 false亲传徒弟
    self.m_CanFindDirectMasterNum = m_CanFindDirectMasterNum
    self.m_CanFindDirectAppNum = m_CanFindDirectAppNum
    self.m_CanFindMasterNum = m_CanFindMasterNum
    self.m_CanFindAppNum = m_CanFindAppNum
    self:UpdateInfo()
end

function UICurrentStatePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrentStatePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)
    for k,v in ipairs(self.tbTogRuleTitle) do
        UIHelper.BindUIEvent(v,EventType.OnSelectChanged,function (_,bSelected)
            UIHelper.SetVisible(self.tbWidgetRuleTitle[k],bSelected)
            UIHelper.ScrollViewDoLayout(self.ScrollView)
            UIHelper.ScrollToTop(self.ScrollView,0)
        end)
    end
end

function UICurrentStatePopView:RegEvent()

end

function UICurrentStatePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrentStatePopView:UpdateInfo()
    --UIHelper.SetVisible(self.LabelDescribeA, self.bCanBeDirectMentor)
    --UIHelper.SetVisible(self.LabelDescribeM, not self.bCanBeDirectMentor)
    if self.bCanBeDirectMentor then
        UIHelper.SetString(self.LableTipsLeft_1,"当前为亲传师父身份，当前赛季师徒值为")
        UIHelper.SetString(self.LableTipsLeft_2,"当前不可拜亲传")
        UIHelper.SetVisible(self.LableTipsNum1M,false)
        UIHelper.SetVisible(self.LableTipsNum1A,true)
        UIHelper.SetString(self.LableTipsLeft_3,"可收亲传徒弟")
        UIHelper.SetString(self.LableTipsMiddle,"，可拜普通师父")
        UIHelper.SetString(self.LableTipsMiddle2,"名，可收普通徒弟")
    else
        UIHelper.SetString(self.LableTipsLeft_1,"当前为亲传徒弟身份，当前赛季师徒值为")
        UIHelper.SetString(self.LableTipsLeft_2,"当前可拜亲传师父")
        UIHelper.SetString(self.LableTipsLeft_3,"不可收亲传")
        UIHelper.SetVisible(self.LableTipsNum1M,true)
        UIHelper.SetVisible(self.LableTipsNum1A,false)
        UIHelper.SetString(self.LableTipsMiddle,"名，可拜普通师父")
        UIHelper.SetString(self.LableTipsMiddle2,"，可收普通徒弟")
    end
    UIHelper.SetString(self.LableTipsNumMaster, tostring(g_pClientPlayer.nMentorAward))
    UIHelper.SetString(self.LableTipsNum1M, self.m_CanFindDirectMasterNum)
    UIHelper.SetString(self.LableTipsNum2M, self.m_CanFindMasterNum)
    UIHelper.SetString(self.LableTipsNum1A, self.m_CanFindDirectAppNum)
    UIHelper.SetString(self.LableTipsNum2A, self.m_CanFindAppNum)
    UIHelper.ScrollViewDoLayout(self.ScrollView)
    UIHelper.ScrollToTop(self.ScrollView, 0)
end

return UICurrentStatePopView