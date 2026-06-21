-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBahuangMainView
-- Date: 2024-01-01 15:43:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelBahuangMainView = class("UIPanelBahuangMainView")

function UIPanelBahuangMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
    self:UpdateInfo()
end

function UIPanelBahuangMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBahuangMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHowPlay, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBahuangBackgroundPop)
    end)
    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBahuangSettings)
    end)
    UIHelper.BindUIEvent(self.BtnLast, EventType.OnClick, function()
        local nCurSceneLevel = self:GetCurSceneLevel()
        self:SetCurSceneLevel(nCurSceneLevel - 1)
    end)
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        local nCurSceneLevel = self:GetCurSceneLevel()
        self:SetCurSceneLevel(nCurSceneLevel + 1)
    end)
    UIHelper.BindUIEvent(self.BtnPersonal, EventType.OnClick, function()

        local function enterBahuangMap()
            RemoteCallToServer("On_EightWastes_EnterScene", self:GetCurSceneLevel())
            UIMgr.Close(self)
        end

        if not PakDownloadMgr.UserCheckDownloadMapRes(BahuangData.nBahuangIDMap, nil, nil, true) then
            return
        end
        enterBahuangMap()
    end)
    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function()
        
    end)

    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(3, 1415)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ToggleGroupNavigation, EventType.OnToggleGroupSelectedChanged, function(toggle, nIndex, eventType)
        self:UpdateNavigation()
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TeachBoxData.OpenTutorialPanel(63, 64, 65)
    end)

end

function UIPanelBahuangMainView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelBahuangMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelBahuangMainView:Init()
    UIHelper.SetVisible(self.BtnRank, false)--暂时隐藏风云录按钮
    RemoteCallToServer("On_EightWastes_GetLastData")
    self.nMaxSceneLevel = BahuangData.GetMaxSceneLevel()
    self:SetCurSceneLevel(self.nMaxSceneLevel)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBahuangMainView:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationPlay)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationHistory)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency,
			5, 66349, true)
end

function UIPanelBahuangMainView:UpdateNavigation()
    local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroupNavigation)
    UIHelper.SetVisible(self.WidgetPlay, nIndex == 0)
    UIHelper.SetVisible(self.WidgetHistory, nIndex == 1)
end

function UIPanelBahuangMainView:UpdateSceneLevel()
    local nSceneLevel = self.nCurSceneLevel
    local nLastState = nSceneLevel > 1 and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnLast, nLastState)

    local nNextState = nSceneLevel < self.nMaxSceneLevel and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnNext, nNextState)

    UIHelper.SetString(self.LabelLevel, g_tStrings.tRougeLikeLevel[nSceneLevel])
    self:UpdateAward()
end

function UIPanelBahuangMainView:UpdateAward()
    local nSceneLevel = self.nCurSceneLevel
    local tbAwardItemList = GDAPI_GetEightWastesAwardIList()
	local tbItemList = tbAwardItemList[nSceneLevel]
    -- for nIndex, tbItemInfo in ipairs(tbItemList) do
        
    -- end
    local tbItemInfo = tbItemList[1]
    UIHelper.SetString(self.LabelCoinNum, tbItemInfo[3])
end

function UIPanelBahuangMainView:GetMaxSceneLevel()
    local hPlayer = g_pClientPlayer
	if not hPlayer then
		return 
	end

	if IsRemotePlayer(hPlayer.dwID) then
		return
	end

	local tData = GDAPI_GetEightWastesPlayerData(hPlayer)
	local nSceneLevel = tData.nSceneLevel

	return nSceneLevel > 0 and nSceneLevel or 1
end

function UIPanelBahuangMainView:SetCurSceneLevel(nCurSceneLevel)
    if nCurSceneLevel == self.nCurSceneLevel then return end
    self.nCurSceneLevel = nCurSceneLevel
    self:UpdateSceneLevel()
end

function UIPanelBahuangMainView:GetCurSceneLevel()
    return self.nCurSceneLevel
end


return UIPanelBahuangMainView