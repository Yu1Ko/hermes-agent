-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildDesignEnterView
-- Date: 2024-01-18 15:42:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildDesignEnterView = class("UIHomelandBuildDesignEnterView")

local DataModel = {
    tArea = Table_GetGroundArea(),
}

function DataModel.Init()
    DataModel.nLength     = 100
    DataModel.nWidth      = 72

    DataModel.tLevelList  = {}
    for i = 1, HOMELAND_MAX_LEVEL do
        table.insert(DataModel.tLevelList, i)
    end
    DataModel.nLevel      = HOMELAND_MAX_LEVEL

    DataModel.tSceneList  = g_tStrings.tHomelandDesignScene
    DataModel.nSceneIndex = 0
end

function DataModel.UnInit()
    DataModel.nLength     = nil
    DataModel.nWidth      = nil
    DataModel.tLevelList  = nil
    DataModel.nLevel      = nil
    DataModel.tSceneList  = nil
    DataModel.nSceneIndex = nil
end

function UIHomelandBuildDesignEnterView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:UpdateInfo()
end

function UIHomelandBuildDesignEnterView:OnExit()
    self.bInit = false

    DataModel.UnInit()
end

function UIHomelandBuildDesignEnterView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose1, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        DataModel.nLevel = math.min(HOMELAND_MAX_LEVEL, DataModel.nLevel + 1)
        UIHelper.SetText(self.EditPaginate, DataModel.nLevel)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
        DataModel.nLevel = math.max(1, DataModel.nLevel - 1)
        UIHelper.SetText(self.EditPaginate, DataModel.nLevel)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        local tDesignInfo = {nSceneIndex = DataModel.nSceneIndex, nLength = DataModel.nLength, nWidth = DataModel.nWidth, nLevel = DataModel.nLevel, bPrivateHome = DataModel.bPrivateHome}
        HomelandBuildData.OpenAsDesign(tDesignInfo)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
			local szLevel = UIHelper.GetText(self.EditPaginate)
			local nLevel = tonumber(szLevel)
            if nLevel then
                nLevel = math.min(HOMELAND_MAX_LEVEL, nLevel)
                nLevel = math.max(1, nLevel)
                DataModel.nLevel = nLevel
            end
            UIHelper.SetText(self.EditPaginate, DataModel.nLevel)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
			local szLevel = UIHelper.GetText(self.EditPaginate)
			local nLevel = tonumber(szLevel)
            if nLevel then
                nLevel = math.min(HOMELAND_MAX_LEVEL, nLevel)
                nLevel = math.max(1, nLevel)
                DataModel.nLevel = nLevel
            end
            UIHelper.SetText(self.EditPaginate, DataModel.nLevel)
        end)
    end
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIHomelandBuildDesignEnterView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildDesignEnterView:UpdateInfo()
    self:UpdateAreaInfo()
    self:UpdateLevelInfo()
    self:UpdateStyleInfo()
    self:UpdateBtnState()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIHomelandBuildDesignEnterView:UpdateAreaInfo()
    UIHelper.HideAllChildren(self.LayoutAreaList)

    self.tbAreaCells = self.tbAreaCells or {}

    local i = 1
    for _, v in pairs(DataModel.tArea) do
        local nArea  = v.nLength * v.nWidth
        local szArea = nArea .. g_tStrings.STR_SQUARE_METRE
        if not self.tbAreaCells[i] then
            self.tbAreaCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_XS, self.LayoutAreaList)
            UIHelper.SetToggleGroupIndex(self.tbAreaCells[i].tbToggleList[1], -1)
            UIHelper.ToggleGroupAddToggle(self.TogGroupArea, self.tbAreaCells[i].tbToggleList[1])
        end

        UIHelper.SetVisible(self.tbAreaCells[i]._rootNode, true)
        UIHelper.BindUIEvent(self.tbAreaCells[i].tbToggleList[1], EventType.OnClick, function(btn)
            DataModel.nLength = v.nLength
            DataModel.nWidth  = v.nWidth
            DataModel.bPrivateHome = v.bPrivateHome
        end)
        UIHelper.SetString(self.tbAreaCells[i].tbLabelList[1], szArea)

        i = i + 1
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupArea, 3)
    UIHelper.LayoutDoLayout(self.LayoutAreaList)
    UIHelper.LayoutDoLayout(self.WidgetArea)
end

function UIHomelandBuildDesignEnterView:UpdateLevelInfo()
    UIHelper.LayoutDoLayout(self.WidgetLevel)
end

function UIHomelandBuildDesignEnterView:UpdateStyleInfo()
    UIHelper.HideAllChildren(self.LayoutStyleList)

    self.tbStyleCells = self.tbStyleCells or {}

    local i = 1
    for _, v in pairs(DataModel.tSceneList) do
        if not self.tbStyleCells[i] then
            self.tbStyleCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetTogTypeSingle_XS, self.LayoutStyleList)
            UIHelper.SetToggleGroupIndex(self.tbStyleCells[i].tbToggleList[1], -1)
            UIHelper.ToggleGroupAddToggle(self.TogGroupStyle, self.tbStyleCells[i].tbToggleList[1])
        end

        UIHelper.SetVisible(self.tbStyleCells[i]._rootNode, true)
        UIHelper.BindUIEvent(self.tbStyleCells[i].tbToggleList[1], EventType.OnClick, function(btn)
            DataModel.nSceneIndex = v[1]
        end)
        UIHelper.SetString(self.tbStyleCells[i].tbLabelList[1], v[2])

        i = i + 1
    end

    UIHelper.LayoutDoLayout(self.LayoutStyleList)
    UIHelper.LayoutDoLayout(self.WidgetStyle)
end

function UIHomelandBuildDesignEnterView:UpdateBtnState()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
        return
    end

    if hPlayer.nLevel < 100 then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, g_tStrings.STR_DATANGJIAYUAN_LEVEL_LIMIT)
        return
    end

    if CheckPlayerIsRemote() then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, g_tStrings.STR_REMOTE_NOT_TIP)
        return
    end

    UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
end

return UIHomelandBuildDesignEnterView