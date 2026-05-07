-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterMainView
-- Date: 2023-06-19 16:51:40
-- Desc: 客服中心主界面
-- ---------------------------------------------------------------------------------

local ServiceCenterMainView = class("ServiceCenterMainView")
local tbServiceList = {
    [1] = PREFAB_ID.WidgetService01,
    [2] = PREFAB_ID.WidgetService02,
    [3] = PREFAB_ID.WidgetService03,
    [4] = PREFAB_ID.WidgetService04,
    [5] = PREFAB_ID.WidgetService05,
    [6] = PREFAB_ID.WidgetService06,
    [7] = PREFAB_ID.WidgetService07,
}

function ServiceCenterMainView:OnEnter(nSelectTab, tbSelectInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMapScriptList = {}
    self.nCurSelectIndex = nSelectTab or 1
    self.tbSelectInfo = tbSelectInfo
    self.tbCurTog = nil

    if AppReviewMgr.IsReview() then
        self.nCurSelectIndex = 3
        for k, v in ipairs(self.tbToggleTab) do
            if k == 3 then
                UIHelper.SetVisible(v, true)
                UIHelper.SetPositionY(v, UIHelper.GetPositionY(self.tbToggleTab[1]))
            else
                UIHelper.SetVisible(v, false)
            end
        end
    end

    UIHelper.SetCanSelect(self.tbToggleTab[2], not CrossMgr.IsCrossing(), g_tStrings.STR_REMOTE_NOT_TIP)

    self.tbCurTog = self.tbToggleTab[self.nCurSelectIndex]
    if self.tbCurTog then
        UIHelper.SetSelected(self.tbCurTog, true)
    end
end

function ServiceCenterMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(VIEW_ID.PanelTutorialCollection)
    end)

    UIHelper.BindUIEvent(self.BtnService , EventType.OnClick , function ()
        if Platform.IsWindows() or Platform.IsMac() then
            WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK)
        else
            WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK_MOBILE)
        end
    end)

    for i, v in ipairs(self.tbToggleTab) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged , function (tog, bSelect)
            if bSelect then
                self.nCurSelectIndex = i
                self:UpdateInfo()
            end
        end)
    end
end

function ServiceCenterMainView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function ServiceCenterMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterMainView:UpdateInfo()
    for i, script in pairs(self.tbMapScriptList) do
        UIHelper.SetVisible(script._rootNode, false)
    end

    if self.tbMapScriptList[self.nCurSelectIndex] then
        UIHelper.SetVisible(self.tbMapScriptList[self.nCurSelectIndex]._rootNode, true)
    else
        local tbScript = UIHelper.AddPrefab(tbServiceList[self.nCurSelectIndex], self.WidgetlAniRight, self.tbSelectInfo)
        self.tbMapScriptList[self.nCurSelectIndex] = tbScript
    end

    UIHelper.SetVisible(self.BtnService, not AppReviewMgr.IsReview())
    RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, ServiceCenterData.tbRedPointIDs)
end


return ServiceCenterMainView