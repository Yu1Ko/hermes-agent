-- ---------------------------------------------------------------------------------
-- Name: UIWidgetConductorRightPop
-- Desc: 分配本周攻防指挥页面——右侧分配页面
-- Prefab:WidgetChooseConductor
-- ---------------------------------------------------------------------------------

local UIWidgetConductorRightPop = class("UIWidgetConductorRightPop")

function UIWidgetConductorRightPop:_LuaBindList()
    self.BtnClose      = self.BtnClose
    self.BtnCloseRight = self.BtnCloseRight

    self.ScrollView    = self.ScrollView -- 加载cell WidgetConductorListCell
    self.BtnConfirm    = self.BtnConfirm -- 确认任命按钮
end

function UIWidgetConductorRightPop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end

    UIHelper.SetTouchDownHideTips(self.BtnConfirm, false)
end

function UIWidgetConductorRightPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetConductorRightPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function()
        -- UIHelper.RemoveFromParent(self._rootNode)
        self.fnCallBack(self.nIndex, self.nConfirmID)
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick , function()
        -- UIHelper.RemoveFromParent(self._rootNode)
        self.fnCallBack(self.nIndex, self.nConfirmID)
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick , function()
        if self.fnCallBack and self.nChoseID then
            self.fnCallBack(self.nIndex, self.nChoseID)
            RemoteCallToServer("On_Camp_GFSetCommander", self.nIndex, self.nChoseID)
        end
        self.nConfirmID = self.nChoseID
        -- UIHelper.RemoveFromParent(self._rootNode)
        UIHelper.SetVisible(self._rootNode, false)
    end)
end

function UIWidgetConductorRightPop:RegEvent()
    
end

function UIWidgetConductorRightPop:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetConductorRightPop:UpdateInfo(nIndex, dwID, tInfo)
    self.nIndex = nIndex
    self.nConfirmID = dwID
    self.tInfo = tInfo
    UIHelper.RemoveAllChildren(self.ScrollView)
    for dwID, tInfo in pairs(self.tInfo) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetConductorListCell, self.ScrollView, dwID, tInfo, function(dwID)
            self:UpdateSelected(dwID)
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
    UIHelper.SetTouchDownHideTips(self.ScrollView, false)
end

function UIWidgetConductorRightPop:UpdateSelected(dwID)
    self.nChoseID = dwID
    if self.fnCallBack then
        self.fnCallBack(self.nIndex, dwID)
    end
end

function UIWidgetConductorRightPop:SetClickCallBack(func)
    self.fnCallBack = func
end

function UIWidgetConductorRightPop:Hide()
    if self.fnCallBack then
        self.fnCallBack(self.nIndex, self.nConfirmID)
    end
end

return UIWidgetConductorRightPop