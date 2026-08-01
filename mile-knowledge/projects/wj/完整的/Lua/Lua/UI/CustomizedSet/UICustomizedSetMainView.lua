-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetMainView
-- Date: 2024-08-22 11:26:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetMainView = class("UICustomizedSetMainView")

local PageIndex2PrefabID = {
    PREFAB_ID.WidgetMySetPage,
    PREFAB_ID.WidgetExpertRecPage,
}

function UICustomizedSetMainView:OnEnter(nPageIndex, nSubIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    EquipCodeData.InitCustomizedSetData()
    self.nCurPageIndex = nPageIndex or 2
    self.bInitPageIndex = false
    if EquipCodeData.IsHadRoleEquipSet() then
        self.nCurPageIndex = nPageIndex or 1
        self.bInitPageIndex = true
    end
    self:UpdateInfo()

    if nSubIndex then
        Event.Dispatch(EventType.OnDoSelectCustomizedSetRecommendCell, nSubIndex, nPageIndex == 1)
    end
end

function UICustomizedSetMainView:OnExit()
    EquipCodeData.UnInitCustomizedSetData()
    self.bInit = false
end

function UICustomizedSetMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)


    for i, tog in ipairs(self.tbTogNavgation) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurPageIndex = i
            self:UpdateInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, tog)
    end
end

function UICustomizedSetMainView:RegEvent()
    Event.Reg(self, EventType.OnUpdateCustomizedSetList, function ()
        if not self.bInitPageIndex and EquipCodeData.IsHadRoleEquipSet() then
            self.nCurPageIndex = nPageIndex or 1
            self:UpdateInfo()
        end
    end)
end

function UICustomizedSetMainView:UpdateInfo()
    self.tbScriptPage = self.tbScriptPage or {}
    if not self.tbScriptPage[self.nCurPageIndex] then
        local nPrefabID = PageIndex2PrefabID[self.nCurPageIndex]
        self.tbScriptPage[self.nCurPageIndex] = UIHelper.AddPrefab(nPrefabID, self.tbWidgetPage[self.nCurPageIndex])
        self.tbScriptPage[self.nCurPageIndex]:OnEnter()
    end

    UIHelper.SetToggleGroupSelected(self.ToggleGroupNavigation, self.nCurPageIndex - 1)
end


return UICustomizedSetMainView