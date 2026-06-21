-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: UISelfieStudio
-- Date: 2025-03-06 10:33:36
-- Desc: 万景阁
-- ---------------------------------------------------------------------------------

local UISelfieStudio = class("UISelfieStudio")
local REMOTE_STUDIO_PHOTOSTUDIO = 1178
local PREFER_REMOTE_DATA_START 	= 1
local PREFER_REMOTE_DATA_END 	= 31
local SELFIE_STUDIO_MAP_LIST    = {705}
local _MAX_SERVANTS_PER_TABLE = 3
local m_nCurPageTable = 1
local DataModel = {}

local tPreset2WeatherOpenIcon = 
{
     [2] = "UIAtlas2_CampMap_Weather_Rain1.png",
     [4] = "UIAtlas2_CampMap_Weather_Snow1.png",
     [6] = "UIAtlas2_CampMap_Weather_Rain1.png",
}

local tPreset2WeatherCloseIcon = 
{
     [2] = "UIAtlas2_CampMap_Weather_Rain2.png",
     [4] = "UIAtlas2_CampMap_Weather_Snow2.png",
     [6] = "UIAtlas2_CampMap_Weather_Rain2.png",
}

local tOpenWeatherPresetID = {2,4,6}

function UISelfieStudio:OnEnter(onHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.onHideCallback = onHideCallback
    self:UpdateInfo()
    local tbEngineOption = KG3DEngine.GetMobileEngineOption()
    if not tbEngineOption.bEnableWeather then 
        SelfieData.ChangeDynamicWeather(0)
    else
        self:InitSwitchInfo()
    end
end

function UISelfieStudio:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel = {}
    m_nCurPageTable = 1
end

function UISelfieStudio:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnUse , EventType.OnClick , function ()
        local dwNowMapID = SelfieData.GetCurrentMapID()
        if self.nTargetMapID == dwNowMapID and DataModel.dwInitLine == DataModel.dwSelectLine then
            self:PhotoStudioMapTeleport(self.nCurSelectDwID, DataModel.dwSelectLine)
        else
            local dialog = UIHelper.ShowConfirm(g_tStrings.STR_SELFIE_STUDIO_MSG, function()
                SelfieData.bOpenAgain = true
                self:PhotoStudioMapTeleport(self.nCurSelectDwID, DataModel.dwSelectLine)
            end)
            dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
            dialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
        end
    end)

    UIHelper.BindUIEvent(self.BtnLeave , EventType.OnClick , function ()
        SelfieData.OnLeaveStudioScene(true)
    end)

    UIHelper.BindUIEvent(self.BtnRightClose, EventType.OnClick , function ()
        self:Hide()
    end)
    
    -- UIHelper.BindUIEvent(self.ToggleLightPositionSwitch, EventType.OnSelectChanged, function (_,bSelected)
    --     if bSelected ~= self.bEnableWeather then
    --         if bSelected then
    --             UIHelper.ShowConfirm("当前开启的雨雪效果性能负载较高，是否确定要开启？",function ()
    --                 Event.Dispatch(EventType.OnSelfieStudioWeatherChange, bSelected)
    --                 GameSettingData.ApplyNewValue(UISettingKey.WeatherSimulation, bSelected) 
    --             end,function ()
    --                 UIHelper.SetSelected(self.ToggleLightPositionSwitch, false)
    --             end)
    --         else
    --             Event.Dispatch(EventType.OnSelfieStudioWeatherChange, bSelected)
    --             GameSettingData.ApplyNewValue(UISettingKey.WeatherSimulation, bSelected) 
    --         end
    --         self.bEnableWeather = bSelected
    --         -- self:UpdatePresetState()
    --     end
    -- end)

    for nIndex, tog in ipairs(self.tbTogTabWeather) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            local tbEngineOption = KG3DEngine.GetMobileEngineOption()
            if not tbEngineOption.bEnableWeather then 
                UIHelper.ShowConfirm("当前功能需要开启的雨雪效果，性能负载较高，是否确定要开启？",function ()
                    Event.Dispatch(EventType.OnSelfieStudioWeatherChange, true)
                        GameSettingData.ApplyNewValue(UISettingKey.WeatherSimulation, true) 
                        self:SetWeatherSwitch(nIndex - 1)
                    end,function ()
                        self:InitSwitchInfo()
                    end)
            else

                self:SetWeatherSwitch(nIndex - 1)
            end
        end)
    end
end

function UISelfieStudio:RegEvent()
    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        local onClickCallback = function(nDwID,nTargetMapID)
            if self.nCurSelectDwID == nDwID then
                nDwID = -1
            end 
            self:SelectScene(nDwID,nTargetMapID)
            Event.Dispatch(EventType.OnSelfieStuidoCellSelect , nDwID) 
        end

        local onGetState = function(nDwID)
            local tState = 
            {
                bGet = DataModel.tGetData[nDwID],
                bSelect =  DataModel.bInSelfieStudioMap and DataModel.nInitPhotoStudioID ==nDwID
            }
            return tState
        end
        local tbDataInfo = {}
        local nStartIndex = math.min((nIndex - 1) * _MAX_SERVANTS_PER_TABLE + 1 ,self.nDataCount)
        for i = nStartIndex, math.min(nStartIndex + _MAX_SERVANTS_PER_TABLE - 1 ,self.nDataCount), 1 do
            table.insert(tbDataInfo , DataModel.tStudio[i])
        end
        if script then
            script:OnEnter(tbDataInfo, onGetState, onClickCallback)
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        UIHelper.TableView_scrollToTop(self.TableView)
    end)

    Event.Reg(self, "REMOTE_DATA_PHOTOSTUDIO", function()
        self:DataModel_UpdateStudioData()
        self:InitTableView()
        if DataModel.bInSelfieStudioMap then
            self:InitPresetList()
            self:InitLineList(SelfieData.GetCurrentMapID())
        else
            Event.Dispatch(EventType.OnSelfieStudioLineCellSelect, DataModel.dwSelectLine)
        end
    end)

    Event.Reg(self, "PHOTOSTUDIO_CHANGE", function()
        SelfieData.nPresetIndex = 0
        self:DataModel_InitPhotoStudio()
        self:InitTableView()
        if DataModel.bInSelfieStudioMap then
            self:InitPresetList()
            self:InitLineList(SelfieData.GetCurrentMapID())
        else
            Event.Dispatch(EventType.OnSelfieStudioLineCellSelect, DataModel.dwSelectLine)
        end
    end)

    Event.Reg(self, EventType.OnSelfieStudioLineCellSelect, function(nLineIndex)
        DataModel.dwSelectLine = nLineIndex
        self:UpdateUseButtonState()
    end)

    Event.Reg(self, "SELFIE_STUDIO_DYNAMIC_WEATHER_UPDATE", function()
        self:InitSwitchInfo()
    end)
end

function UISelfieStudio:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UISelfieStudio:Open()
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
end

function UISelfieStudio:Hide()
    self.bIsOpen = false
    UIHelper.SetVisible(self._rootNode , false)
    if self.onHideCallback then
        self.onHideCallback()
    end
end

function UISelfieStudio:IsOpen()
    return self.bIsOpen
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieStudio:UpdateInfo()
    if UIHelper.GetScreenPortrait() then
        _MAX_SERVANTS_PER_TABLE = 6
    else
        _MAX_SERVANTS_PER_TABLE = 3
    end
    self:DataModelInit()
    self:InitTableView()
    UIHelper.SetVisible(self.BtnLeave, DataModel.bInSelfieStudioMap)
    UIHelper.LayoutDoLayout(self.LayoutBtnList)
    
    UIHelper.SetVisible(self.WidgetCameraStudioAction, DataModel.bInSelfieStudioMap)
    UIHelper.SetVisible(self.WidgetWeatherSwitch, DataModel.bInSelfieStudioMap)
    if DataModel.bInSelfieStudioMap then
        self:InitPresetList()
        self:InitLineList(SelfieData.GetCurrentMapID())
    end
end

function UISelfieStudio:UpdateWeatherState()
    if DataModel.nInitPhotoStudioID then
        local tInfo = Table_GetSelfieStudioInfo(DataModel.nInitPhotoStudioID)
        if tInfo then
            UIHelper.SetVisible(self.WidgetWeatherChooseSwitch, tInfo.bCanWeather)
        end
    end
end

function UISelfieStudio:SelectScene(nSceneID, nTargetMapID)
    self.nCurSelectDwID = nSceneID
    self.nTargetMapID = nTargetMapID
    -- 更新按钮
    self:UpdateUseButtonState()
    self:InitLineList(nTargetMapID)
    Event.Dispatch(EventType.OnSelfieStudioLineCellEnable, nSceneID ~= -1)
end

function UISelfieStudio:UpdateUseButtonState()
    local szText = SelfieData.IsInStudioMap() and "应用" or "前往"
    local btnState = BTN_STATE.Normal
    if DataModel.dwInitLine == DataModel.dwSelectLine then
        if self.nCurSelectDwID == DataModel.nInitPhotoStudioID then
            btnState = BTN_STATE.Disable
        end
    else
        szText = "前往"
        btnState = self.nCurSelectDwID ~= -1 and BTN_STATE.Normal or BTN_STATE.Disable
    end
    UIHelper.SetString(self.LabelApplication, szText)
    UIHelper.SetButtonState(self.BtnUse, btnState)
end

-- ----------------------------------------------------------
-- DataModel Start
-- ----------------------------------------------------------
function UISelfieStudio:DataModelInit()
    self:DataModel_InitInfo()
    self:DataModel_UpdateStudioData()
    DataModel.bInSelfieStudioMap = SelfieData.IsInStudioMap()
    self:DataModel_InitPhotoStudio()

end

function UISelfieStudio:DataModel_InitInfo()
    local nCount = g_tTable.SelfieStudio:GetRowCount()
	local tRes = {}
    local nStudioMaxID = 0
	for i = 2, nCount do
		local tLine = g_tTable.SelfieStudio:GetRow(i)
		table.insert(tRes, tLine)
        nStudioMaxID = math.max(nStudioMaxID, tLine.dwID)
	end
    DataModel.tStudio = tRes
    DataModel.nStudioMaxID = nStudioMaxID
end

function UISelfieStudio:DataModel_UpdateStudioData()
	DataModel.bGetRemote            = false
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local dwPlayerID = hPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		DataModel.tGetData 		    = {}
		DataModel.bGetRemote 	    = true
		return
	end

	if not hPlayer.HaveRemoteData(REMOTE_STUDIO_PHOTOSTUDIO) then
		hPlayer.ApplyRemoteData(REMOTE_STUDIO_PHOTOSTUDIO, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
		return
	end

	local tGetData = {}
    local nEnd = math.min(DataModel.nStudioMaxID, PREFER_REMOTE_DATA_END)
	for i = PREFER_REMOTE_DATA_START, nEnd do
		local bGet = hPlayer.GetRemoteBitArray(REMOTE_STUDIO_PHOTOSTUDIO, i)
		tGetData[i] = bGet
	end
    
	DataModel.tGetData 		     = tGetData
	DataModel.bGetRemote 	     = true
    self:DataModel_SortTable()
end

function UISelfieStudio:DataModel_SortTable()
    if not DataModel.bGetRemote then
        return
    end

    local function fnDegree(a, b)
		if DataModel.tGetData[a.dwID] == DataModel.tGetData[b.dwID] then
			return a.dwID < b.dwID
		elseif DataModel.tGetData[a.dwID] then
			return true
		else
			return false
		end
	end 
    table.sort(DataModel.tStudio, fnDegree)
end

function UISelfieStudio:DataModel_InitPhotoStudio()
    if DataModel.bInSelfieStudioMap then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        DataModel.nInitPhotoStudioID, DataModel.dwInitLine = GDAPI_GetPhotoStudioInfo(hPlayer, SelfieData.GetCurrentMapID())    
        DataModel.dwSelectLine = DataModel.dwInitLine
    end
end

function UISelfieStudio:DataModel_GetStudioPresetList()
    if not DataModel.bInSelfieStudioMap then
        return
    end

    local tPreset = Table_GetASelfieStudioPreset(DataModel.nInitPhotoStudioID)
    local tRes = {}
    for _, szID in ipairs(tPreset) do
        local tLine = Table_GetSelfieStudioPresetInfo(tonumber(szID))
        if tLine then
            table.insert(tRes, tLine)
        end
    end
    return tRes
end
-- ----------------------------------------------------------
-- DataModel End
-- ----------------------------------------------------------

-- ----------------------------------------------------------
-- View Start
-- ----------------------------------------------------------

function UISelfieStudio:InitSwitchInfo()
    local nIndex = SelfieData.GetDynamicWeather()
    self.nCurTabWeatherIndex = nIndex
    UIHelper.SetToggleGroupSelected(self.WidgetWeatherChooseSwitch, self.nCurTabWeatherIndex)
end

function UISelfieStudio:SetWeatherSwitch(nIndex)
    SelfieData.ChangeDynamicWeather(nIndex, true)
    if not self.nCurTabWeatherIndex or self.nCurTabWeatherIndex ~= nIndex then
        UIHelper.SetToggleGroupSelected(self.WidgetWeatherChooseSwitch, nIndex)
        self.nCurTabWeatherIndex = nIndex
    end
end

function UISelfieStudio:InitTableView()
    local nTable, nIndex = self:GetCurTablePos(0)
    self:TurnToPage(nTable, nIndex)
    self:SelectScene(DataModel.bInSelfieStudioMap and DataModel.nInitPhotoStudioID or -1)
    UIHelper.LayoutDoLayout(self.Layout)
    self:UpdateWeatherState()
end

function UISelfieStudio:GetCurTablePos(nMapID)
    
	if nMapID == 0 then
		return 1, 0
	end

	for nIndex, info in ipairs(DataModel.tStudio) do
		if nMapID == info.dwMapID then
			return math.ceil(nIndex / _MAX_SERVANTS_PER_TABLE), (nIndex - 1) % _MAX_SERVANTS_PER_TABLE + 1
		end
	end
    return 1, 0
end


function UISelfieStudio:TurnToPage(nTable , nIndex)
    if not DataModel.bGetRemote then
        UIHelper.TableView_scrollToTop(self.TableView)
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    self.nDataCount = #DataModel.tStudio
	self.nMaxTable = math.ceil(math.max(1, self.nDataCount / _MAX_SERVANTS_PER_TABLE))
    if nTable < 1 or nTable > self.nMaxTable then
		nTable = math.max(1, math.min(nTable, self.nMaxTable))
	end
    m_nCurPageTable = nTable
    if UIHelper.GetScreenPortrait() then
        UIHelper.TableView_init(self.TableView, self.nMaxTable, PREFAB_ID.WidgetCameraStudioPerfabLong)
    else
        UIHelper.TableView_init(self.TableView, self.nMaxTable, PREFAB_ID.WidgetCameraStudioPerfab)
    end
    UIHelper.TableView_reloadData(self.TableView)
    UIHelper.TableView_scrollToTop(self.TableView)
end

--摄影棚传送，不消耗神行CD
function UISelfieStudio:PhotoStudioMapTeleport(dwID, nCopy)
    if not PakDownloadMgr.UserCheckDownloadMapRes(SELFIE_STUDIO_MAP_LIST, function ()
        RemoteCallToServer("On_PhotoStudio_Apply", dwID, nCopy) 
    end, "万景阁地图资源文件下载完成，是否前往？") then
        return
    end
    RemoteCallToServer("On_PhotoStudio_Apply", dwID, nCopy) 
end

--离开摄影棚
function UISelfieStudio:LeavePhotoStudioMap()
	RemoteCallToServer("On_PhotoStudio_Leave") 
end

function UISelfieStudio:InitPresetList()
    local tList = self:DataModel_GetStudioPresetList()
    self.tPresetCellList = {}
    UIHelper.RemoveAllChildren(self.WidgetCameraStudioActionList)
    for k, v in pairs(tList) do
        local widgetAction = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownFriendAction , self.WidgetCameraStudioActionList)
		widgetAction:OnEnter({
            szIconPath = string.format("Resource_UICommon_Camera_SelfieStudioPreset_%d.png", v.dwPreset),
            szName = v.szName,
            dwActionID = v.dwPreset
        }, function (dwID)
	        local bEnableBloom = KG3DEngine.GetMobileEngineOption().bEnableBloom

            SelfieData.nPresetIndex = dwID
            SelfieData.SetEnvPreset(dwID)
            self:UpdatePresetState()

            Timer.Add(self, 0.5, function ()
                local tbEngineOption = KG3DEngine.GetMobileEngineOption()
                tbEngineOption.bEnableBloom = bEnableBloom
                KG3DEngine.SetMobileEngineOption(tbEngineOption)
            end)
        end)
        if SelfieData.nPresetIndex <= 0 and k == 1 then
            SelfieData.SetEnvPreset(v.dwPreset)
            SelfieData.nPresetIndex = v.dwPreset
        end
        table.insert(self.tPresetCellList, widgetAction)
    end
    UIHelper.LayoutDoLayout(self.WidgetCameraStudioActionList)
    
    -- self.bEnableWeather = false
    -- local bShowWeather = table.get_len(tList) > 0

    -- if bShowWeather then
    --     local tbEngineOption = KG3DEngine.GetMobileEngineOption()
    --     self.bEnableWeather = tbEngineOption.bEnableWeather
    --     UIHelper.SetSelected(self.ToggleLightPositionSwitch, self.bEnableWeather)
    -- end
    self:UpdatePresetState()
end


function UISelfieStudio:InitLineList(nTargetMapID)
    --LOG.INFO("InitLineList:%s,%s,%s,%s", tostring(nTargetMapID), tostring(self.nCurSelectDwID), tostring(self.bInitLine),tostring(DataModel.dwSelectLine))
    if self.bInitLine then
        Event.Dispatch(EventType.OnSelfieStudioLineCellSelect, DataModel.dwSelectLine, true)
        return
    end
   
    UIHelper.RemoveAllChildren(self.ScrollViewActionList)
    local nPrefabID =  UIHelper.GetScreenPortrait() and PREFAB_ID.WidgetCameraStudioLineListPortrait or PREFAB_ID.WidgetCameraStudioLineList
 

    if self.nCurSelectDwID and self.nCurSelectDwID > 0 and nTargetMapID then
        local bRandom = not DataModel.dwSelectLine
        local randomCell = UIMgr.AddPrefab(nPrefabID,self.ScrollViewActionList,nil)
        randomCell:SetSelected(bRandom)
        local nMaxCopy  = GDAPI_GetPhotoStudioMaxCopy(nTargetMapID)
        if nMaxCopy then
            for i = 1, nMaxCopy do
               local lineCell = UIMgr.AddPrefab(nPrefabID,self.ScrollViewActionList,i)
               lineCell:SetSelected(bRandom and false or DataModel.dwSelectLine == i)
            end
        end
        self.bInitLine = true
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionList)
    
end

function UISelfieStudio:UpdatePresetState()
    -- local bShowWeather = table.contain_value(tOpenWeatherPresetID, SelfieData.nPresetIndex)
    -- local weatherIcon = self.bEnableWeather and tPreset2WeatherOpenIcon or tPreset2WeatherCloseIcon
    -- UIHelper.SetVisible(self.WidgetWeatherSwitch, bShowWeather)
    for k, v in pairs(self.tPresetCellList) do
        UIHelper.SetVisible(v.ImgBtnSelect, SelfieData.nPresetIndex == v.tbActionInfo.dwActionID)
        -- if weatherIcon[v.tbActionInfo.dwActionID] then
        --     UIHelper.SetVisible(v.ImgWeather, true)
        --     UIHelper.SetSpriteFrame(v.ImgWeather, weatherIcon[v.tbActionInfo.dwActionID])
        -- end
    end
end
-- ----------------------------------------------------------
-- View SEnd
-- ----------------------------------------------------------
return UISelfieStudio