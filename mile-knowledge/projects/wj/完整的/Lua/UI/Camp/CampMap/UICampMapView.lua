-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UICampMapView
-- Date: 2023-06-15 09:50:56
-- Desc: 阵营沙盘界面 UICampMapView
-- ---------------------------------------------------------------------------------

local UICampMapView = class("UICampMapView")

--地图放大缩小相关
local SCALE_MAX = 2
local SCALE_MIN = 0.85
local SCALE_SELECTED = 1.5 --选中时的地图Scale

local MAP_CENTER_OFFSET_X = -200
local MAP_TWEEN_RATIO_POS = 0.5
local MAP_TWEEN_RATIO_SCALE = 0.5

local CAMP_WAR_BRANCH_OPEN_ACTIVITY = 880 -- 攻防分线开启活动
local GOOD_MAP = CampData.CAMP_MAP_ID[CAMP.GOOD] --25 --浩气盟地图
local EVIL_MAP = CampData.CAMP_MAP_ID[CAMP.EVIL] --27 --恶人谷地图
local RANK_LIST_ID = 282 --攻防分线排行榜ID
local ACTIVITY_CAMP_EVIL = 706 --周六恶人谷大攻防
local ACTIVITY_CAMP_GOOD = 707 --周日浩气大攻防

local tThreeLine =
{
    [1] = {231, 232, 1391, 1392, 131, 132, 91, 92},
    [2] = {1531, 1532, 1001, 1002, 351, 352, 211, 212},
    [3] = {1031, 1032, 1041, 1042, 1011, 1012, 1051, 1052},
}

--右侧显示信息类型
local INFO_TYPE = {
    NONE            = 1, --无/关闭
    CASTLE_INFO     = 2, --据点详情
    WAR_INFO        = 3, --攻防概况
    SELECT_MAP      = 4, --地图分线选择
}

local fnSortCampBigThings = function(tLeft, tRight)
    return tLeft.time > tRight.time
end

local fnSortGoodPlayer = function(tLeft, tRight)
    return tLeft.nGoodPlayerCount < tRight.nGoodPlayerCount
end

local fnSortEvilPlayer = function(tLeft, tRight)
    return tLeft.nEvilPlayerCount < tRight.nEvilPlayerCount
end

function UICampMapView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        self:InitUI()

        Timer.AddFrameCycle(self, 1, function()
            self:UpdateMapTween()
        end)
        Timer.AddCycle(self, 0.5, function()
            self:UpdateTime()
        end)
        Timer.AddCycle(self, 5, function()
            RemoteCallToServer("On_Castle_GetCastleTipsRequest") --Respond: ON_CASTLE_GETTIPS_RESPOND
            GetCustomRecording(CUSTOM_RECORDING_TYPE.CAMP_SYSTEM)
        end)

        self.bInit = true
    end

    self.nInfoType = INFO_TYPE.NONE
    self.bInActivity = CampData.IsInCastleActivity()
    self:InitBtnState()
    self:UpdateTime()
    self:UpdateCastleState()
    self:UpdateWeather()

    ApplyCustomRankList(RANK_LIST_ID)
    RemoteCallToServer("On_Castle_GetCastleTipsRequest") --Respond: ON_CASTLE_GETTIPS_RESPOND
    RemoteCallToServer("On_Castle_GetWarSituation") --Respond: ON_CASTLE_GET_WARSITUAION_RESPOND
    GetCustomRecording(CUSTOM_RECORDING_TYPE.CAMP_SYSTEM)
end

function UICampMapView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindUIZoom()
end

function UICampMapView:UpdateMapTween()
    if not self.TouchComponent then
        return
    end

    local bIteration = false

    if self.nTargetMapPos then
        local nMin = 1
        local nCurMapPosX, nCurMapPosY = UIHelper.GetPosition(self.WidgetMap)
        if math.abs(self.nTargetMapPos.nX - nCurMapPosX) < nMin and math.abs(self.nTargetMapPos.nY - nCurMapPosY) < nMin then
            self.TouchComponent:SetPosition(self.nTargetMapPos.nX, self.nTargetMapPos.nY)
            self.nTargetMapPos = nil
        else
            local nTargetPosX = nCurMapPosX + (self.nTargetMapPos.nX - nCurMapPosX) * MAP_TWEEN_RATIO_POS
            local nTargetPosY = nCurMapPosY + (self.nTargetMapPos.nY - nCurMapPosY) * MAP_TWEEN_RATIO_POS
            self.TouchComponent:SetPosition(nTargetPosX, nTargetPosY)
            bIteration = true
        end
    end

    if self.nTargetMapScale then
        local nMin = 0.01
        local nMapScale = UIHelper.GetScale(self.WidgetMap)
        if math.abs(self.nTargetMapScale - nMapScale) < nMin then
            self.TouchComponent:Scale(self.nTargetMapScale)
            self.nTargetMapScale = nil
        else
            local nTargetScale = nMapScale + (self.nTargetMapScale - nMapScale) * MAP_TWEEN_RATIO_SCALE
            self.TouchComponent:Scale(nTargetScale)
            bIteration = true
        end
    end

    if bIteration then
        self:OnCastleSelectTransform()
    end
end

function UICampMapView:BindUIEvent()
    UIHelper.SetTouchEnabled(self.WidgetTouch, true) --layout
    UIHelper.SetSwallowTouches(self.WidgetTouch, false)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchBegan, function(btn, nX, nY)
        self.TouchComponent:TouchBegin(nX, nY)
    end)
    UIHelper.BindUIEvent(self.WidgetTouch, EventType.OnTouchMoved, function(btn, nX, nY)
        self.TouchComponent:TouchMoved(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnWar, EventType.OnClick, function()
        self:ShowWarInfo()
    end)
    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function()
        local player = GetClientPlayer()
        local nCamp = player and player.nCamp
        if not nCamp or nCamp == CAMP.NEUTRAL then
            nCamp = CAMP.GOOD
        end
        UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.Military, nCamp)
    end)
    UIHelper.SetMultiTouch(self.BtnNothing, true) --阻挡多指，防止穿透
    UIHelper.SetSwallowTouches(self.BtnCloseRight, false)
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        if not self.bClickBtn then
            self:SetRightInfoState(INFO_TYPE.NONE)
            self:OnCastleSelect(nil)
            self:ClearSelectFlag()
        end
    end)
    UIHelper.BindUIEvent(self.BtnCloseRight2, EventType.OnClick, function()
        self:SetRightInfoState(INFO_TYPE.NONE)
        self:OnCastleSelect(nil)
        self:ClearSelectFlag()
    end)
    UIHelper.BindUIEvent(self.BtnMenuChange, EventType.OnClick, function()
        print("[Camp Map] BtnMenuChange") --菜单
    end)
    UIHelper.BindUIEvent(self.BtnCityHistory, EventType.OnClick, function()
        --据点历史
        UIMgr.Open(VIEW_ID.PanelCityHistoryPop, CUSTOM_RECORDING_TYPE.CASTLE_SYSTEM, self.dwSelCastleID)
    end)
    UIHelper.BindUIEvent(self.BtnCityLocation, EventType.OnClick, function()
        --查看位置
        self:OnClickShowCastleMapBtn(self.dwSelCastleID)
    end)
    UIHelper.BindUIEvent(self.BtnBelong, EventType.OnClick, function()
        --据点归属
        UIMgr.Open(VIEW_ID.PanelCityBelongPop, self.dwSelCastleID)
    end)
    UIHelper.BindUIEvent(self.BtnYinshan, EventType.OnClick, function()
        --阴山大草原分线
        UIMgr.Open(VIEW_ID.PanelYinshanLine)
    end)
    UIHelper.BindUIEvent(self.BtnGo1, EventType.OnClick, function()
        if not self.tSelBusiness then
            return
        end

        local dwLinkID = self.tSelBusiness.dwSourceLinkID
        local dwMapID = self.tSelBusiness.dwSourceMapID
        if not dwLinkID or not dwMapID then
            return
        end

        if HomelandData.CheckIsHomelandMapTeleportGo(dwLinkID, dwMapID, nil, nil, function ()
                UIMgr.Close(VIEW_ID.PanelCampMap)
                UIMgr.Close(VIEW_ID.PanelRoadCollection)
                UIMgr.Close(VIEW_ID.PanelSystemMenu)
            end) then
            return
        end

        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_Teleport_Go", dwLinkID, dwMapID)
            UIMgr.Close(VIEW_ID.PanelCampMap)
            UIMgr.Close(VIEW_ID.PanelRoadCollection)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end, dwMapID)
    end)
    UIHelper.BindUIEvent(self.BtnGo2, EventType.OnClick, function()
        --self:ShowWarInfo()
        self:ShowMapSelectInfo(216)
    end)
    UIHelper.BindUIEvent(self.BtnGo3, EventType.OnClick, function()
        -- local nWeekDay = TimeLib.GetCurrentWeekday()
        -- if nWeekDay == 7 then
        --     --UIMgr.Open(VIEW_ID.PanelLineSelectPop, GOOD_MAP, true)
        --     self:ShowMapSelectInfo(GOOD_MAP, true)
        -- elseif nWeekDay == 6 then
        --     --UIMgr.Open(VIEW_ID.PanelLineSelectPop, EVIL_MAP, true)
        --     self:ShowMapSelectInfo(EVIL_MAP, true)
        -- else
        --     --UIMgr.Open(VIEW_ID.PanelLineSelectPop, 0, true, {GOOD_MAP, EVIL_MAP})
        --     self:ShowMapSelectInfo(0, true, {GOOD_MAP, EVIL_MAP})
        -- end
        self:ShowMapSelectInfoByTime()
    end)
    UIHelper.BindUIEvent(self.BtnHelp1, EventType.OnClick, function()
        local tLine = g_tTable.StringCampMaps:Search("STR_JDMYTIP")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\n", "\n")
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp1, TipsLayoutDir.LEFT_CENTER, szContent)
        end
    end)
    UIHelper.BindUIEvent(self.BtnHelp2, EventType.OnClick, function()
        local tLine = g_tTable.StringCampMaps:Search("STR_ZLZYTIP")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\n", "\n")
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp2, TipsLayoutDir.LEFT_CENTER, szContent)
        end
    end)
    UIHelper.BindUIEvent(self.BtnHelp3, EventType.OnClick, function()
        local tLine = g_tTable.StringCampMaps:Search("STR_ZYGFZTIP")
        local szContent = tLine and UIHelper.GBKToUTF8(tLine.szString)
        if not string.is_nil(szContent) then
            szContent = string.gsub(szContent, "\\n", "\n")
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp3, TipsLayoutDir.LEFT_CENTER, szContent)
        end
    end)
    UIHelper.BindUIEvent(self.BtnHelp4, EventType.OnClick, function()
        local szContent = "开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果。"
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp4, TipsLayoutDir.TOP_CENTER, szContent)
    end)

    --浩气盟的按钮因为形状问题，拆成了两个按钮
    UIHelper.BindUIEvent(self.BtnCampMap21, EventType.OnClick, function()
        if self.tCopyInfo and ActivityData.IsActivityOn(ACTIVITY_CAMP_GOOD) then
            UIMgr.Open(VIEW_ID.PanelLineSelectPop, GOOD_MAP)
        else
            CampData.CampTransfer(GOOD_MAP)
        end
    end)
    UIHelper.BindUIEvent(self.BtnCampMap22, EventType.OnClick, function()
        UIHelper.SimulateClick(self.BtnCampMap21)
    end)
    UIHelper.BindUIEvent(self.BtnCampMap1, EventType.OnClick, function()
        if self.tCopyInfo and ActivityData.IsActivityOn(ACTIVITY_CAMP_EVIL) then
            UIMgr.Open(VIEW_ID.PanelLineSelectPop, EVIL_MAP)
        else
            CampData.CampTransfer(EVIL_MAP)
        end
    end)
    UIHelper.BindUIEvent(self.BtnWeatherMap1, EventType.OnClick, function()
        if string.is_nil(self.szWeatherTipER) then
            return
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnWeatherMap1, TipsLayoutDir.RIGHT_CENTER, self.szWeatherTipER)
    end)
    UIHelper.BindUIEvent(self.BtnWeatherMap2, EventType.OnClick, function()
        if string.is_nil(self.szWeatherTipHQ) then
            return
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnWeatherMap2, TipsLayoutDir.LEFT_CENTER, self.szWeatherTipHQ)
    end)
    UIHelper.BindUIEvent(self.ToggleLightPositionSwitch, EventType.OnSelectChanged, function(_, bSelected)
        local function _setActivityPreset()
            SelfieData.EnableActivityPreset(bSelected)
            local dwCurMapID = MapHelper.GetMapID()
            if dwCurMapID == GOOD_MAP or dwCurMapID == EVIL_MAP then
                SelfieData.ResetFilterFromStorage()
            end
        end

        if bSelected then
            UIHelper.ShowConfirm("开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果，会影响性能消耗，是否开启？",
            _setActivityPreset,
            function()
                UIHelper.SetSelected(self.ToggleLightPositionSwitch, false, false)
            end)
        else
            _setActivityPreset()
        end
    end)
end

function UICampMapView:RegEvent()
    Event.Reg(self, "ON_SYNC_CUSTOM_RECORDING", function(nType, dwID, tRecord)
        if nType == CUSTOM_RECORDING_TYPE.CAMP_SYSTEM then
            table.sort(tRecord, fnSortCampBigThings)
            self:UpdateCampBigThing(tRecord[1])
        end
    end)
    Event.Reg(self, "ON_CASTLE_GET_WARSITUAION_RESPOND", function(tBattleLine) --Requset: On_Castle_GetWarSituation
        print("[Camp Map] ON_CASTLE_GET_WARSITUAION_RESPOND")
        self.tBattleLine = tBattleLine
        self:UpdateBattleLine()
    end)
    Event.Reg(self, "ON_CASTLE_GETTIPS_RESPOND", function(tCastleTips, nWillResetTime, tBusiness) --Request: On_Castle_GetCastleTipsRequest
        --print("[Camp Map] ON_CASTLE_GETTIPS_RESPOND")
        self.tCastleTips = tCastleTips
        self.nBusinessIndex = tBusiness and tBusiness[1] --2024.4.12 跑商路线只用第一条
        self.bInActivity = CampData.IsInCastleActivity()

        -- print_table("[Camp Map] ON_CASTLE_GETTIPS_RESPOND", {
        --     tCastleTips = tCastleTips,
        --     nWillResetTime = nWillResetTime,
        --     tBusiness = tBusiness,
        --     bInActivity = self.bInActivity
        -- })

        self:UpdateResetTime(nWillResetTime)
        self:UpdateInfo()
    end)
    Event.Reg(self, "ON_MAP_PLAYER_COUNT_UPDATE", function()
        --print("[Camp Map] ON_MAP_PLAYER_COUNT_UPDATE")
        self:UpdateWarInfo()
    end)
    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        if dwActivityID == CAMP_WAR_BRANCH_OPEN_ACTIVITY then
            self:UpdateBtnBranchState(bOpen)
        else
            self:UpdateWeather()
        end
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        UIMgr.Close(self)
    end)
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nRankListID, nTotalNum)
        if nRankListID == RANK_LIST_ID then
            self.tCopyInfo = GetCustomRankListByID(RANK_LIST_ID, 2)
        end
    end)
    Event.Reg(self, EventType.OnUpdateRankEntrance, function()
        self:UpdateBtnBelongState(self.dwSelCastleID)
    end)
    -- Event.Reg(self, "ON_SCHEDULE_MAP_APPOINTMENT_RESPOND", function(dwMapID, nResultCode)
    --     self:UpdateMapAppointment()
    -- end)
    Event.Reg(self, "ON_ACTIVITY_PRESET_ENABLE_STATE_CHANGE", function()
        self:UpdateWeather()
    end)
end

function UICampMapView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICampMapView:InitUI()
    local tMapWidget = {}
    local tCastleWidget = {}

    self.TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
    self.TouchComponent:Init(self.WidgetMap)
    self.TouchComponent:SetScaleLimit(SCALE_MIN, SCALE_MAX)
    self.TouchComponent:Scale(1)
    self.TouchComponent:RegisterScaleEvent(function(nScale)
        for dwCastleID, tWidgetInfo in pairs(self.tCastleWidget or {}) do
            UIHelper.SetScale(tWidgetInfo.togBig, 1 / nScale, 1 / nScale)
        end
    end)

    UITouchHelper.BindUIZoom(self.WidgetZoom, function(nDelta)
        self.nTargetMapScale = nil
        if self.TouchComponent then
            self.TouchComponent:Zoom(nDelta)
        end
    end)

    local function _getMapWidget(dwMapID)
        local widgetMap, widgetTogMap, imgMapFight, imgBook
        if tMapWidget[dwMapID] then
            widgetMap    = tMapWidget[dwMapID].widgetMap
            widgetTogMap = tMapWidget[dwMapID].widgetTogMap
            imgMapFight  = tMapWidget[dwMapID].imgMapFight
            imgBook      = tMapWidget[dwMapID].imgBook
        else
            widgetMap    = self.WidgetMap:getChildByName("WidgetCampMap"    .. dwMapID)         assert(widgetMap,   dwMapID)
            widgetTogMap = self.WidgetMap:getChildByName("WidgetTogCampMap" .. dwMapID)
            imgMapFight  = widgetMap     :getChildByName("ImgCampMapBg"     .. dwMapID .. "_F") assert(imgMapFight, dwMapID)
            imgBook      = widgetMap     :getChildByName("ImgYuyue"         .. dwMapID)         assert(imgBook,     dwMapID)

            tMapWidget[dwMapID] = {
                widgetMap = widgetMap,
                widgetTogMap = widgetTogMap,
                imgMapFight = imgMapFight,
                imgBook = imgBook,
            }

            UIHelper.SetVisible(imgMapFight, false)
            UIHelper.SetVisible(imgBook, false)
        end
        return widgetMap, widgetTogMap, imgMapFight, imgBook
    end

    local function _getCampWidgetTable(widgetParent, szPrefix, dwCastleID, bAssertNeutral)
        assert(widgetParent)

        local tWidget = {}
        local szAssert = widgetParent:getName() .. "/" .. szPrefix .. dwCastleID
        local widgetNeutral = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_N") assert(not bAssertNeutral or widgetNeutral, szAssert)
        local widgetGood = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_J") assert(widgetGood, szAssert)
        local widgetEvil = widgetParent:getChildByName(szPrefix .. dwCastleID .. "_E") assert(widgetEvil, szAssert)
        tWidget[CAMP.NEUTRAL] = widgetNeutral
        tWidget[CAMP.GOOD] = widgetGood
        tWidget[CAMP.EVIL] = widgetEvil

        UIHelper.SetVisible(widgetNeutral, true)
        UIHelper.SetVisible(widgetGood, false)
        UIHelper.SetVisible(widgetEvil, false)

        return tWidget
    end

    local function _getChildWidget(widgetParent)
        if not widgetParent then return end
        local children = widgetParent:getChildren()
        return children and children[1]
    end

    local function _bindUIEvent(dwCastleID, tWidgetInfo)
        UIHelper.BindUIEvent(tWidgetInfo.togBig, EventType.OnSelectChanged, function(_, bSelected)
            self:OnCastleSelect(bSelected and dwCastleID)
            self.bClickBtn = false
        end)
        UIHelper.BindUIEvent(tWidgetInfo.togBig, EventType.OnTouchBegan, function()
            self.bClickBtn = true
        end)
    end

    local function _initCastleWidget(dwMapID, dwCastleID)
        local widgetMap, widgetTogMap, imgMapFight, imgBook = _getMapWidget(dwMapID)

        local togBig        = widgetMap:getChildByName("TogCampMapBig"   .. dwCastleID) or widgetTogMap:getChildByName("TogCampMapBig" .. dwCastleID) assert(togBig, dwCastleID)
        local widgetSelect  = togBig   :getChildByName("WidgetSelect"    .. dwCastleID) assert(widgetSelect,  dwCastleID)
        local widgetBigBarn = togBig   :getChildByName("WidgetLiangcang" .. dwCastleID) assert(widgetBigBarn, dwCastleID)
        local widgetBigTong = togBig   :getChildByName("WidgetBanghui"   .. dwCastleID) assert(widgetBigTong, dwCastleID)
        local labelNameBig  = togBig   :getChildByName("LabelNameBig"    .. dwCastleID) assert(labelNameBig,  dwCastleID)

        local tImgCampBg  = _getCampWidgetTable(widgetMap,     "ImgCampMapBg",    dwCastleID, true)
        local tImgBigBg   = _getCampWidgetTable(togBig,        "ImgBtnBgBig",     dwCastleID, true)
        local tImgBigBarn = _getCampWidgetTable(widgetBigBarn, "ImgBigLiangcang", dwCastleID)
        local tImgBigTong = _getCampWidgetTable(widgetBigTong, "ImgBigBanghui",   dwCastleID)
        local tImgSelect  = _getCampWidgetTable(widgetSelect,  "ImgSelect",       dwCastleID, true)

        local imgBigBarn_Broke = widgetBigBarn:getChildByName("ImgBigLiangcang" .. dwCastleID .. "_F") assert(imgBigBarn_Broke,    dwCastleID)


        local tImgBgLight = {
            [CAMP.NEUTRAL] = _getChildWidget(tImgBigBg[CAMP.NEUTRAL]),
            [CAMP.GOOD] = _getChildWidget(tImgBigBg[CAMP.GOOD]),
            [CAMP.EVIL] = _getChildWidget(tImgBigBg[CAMP.EVIL]),
        }

        local tWidgetInfo = {
            tImgCampBg        = tImgCampBg,       --地图底色
            togBig            = togBig,           --大按钮
            tImgBigBg         = tImgBigBg,        --大按钮底色
            widgetSelect      = widgetSelect,     --选中Widget
            tImgSelect        = tImgSelect,       --大按钮-选中态底色
            widgetBigBarn     = widgetBigBarn,    --大按钮-粮仓
            tImgBigBarn       = tImgBigBarn,      --大按钮-粮仓底色
            imgBigBarn_Broke  = imgBigBarn_Broke, --大按钮-粮仓毁坏
            widgetBigTong     = widgetBigTong,    --大按钮-帮会
            tImgBigTong       = tImgBigTong,      --大按钮-帮会底色
            tImgBgLight       = tImgBgLight,      --帮会常驻特效

            dwMapID           = dwMapID,
        }

        _bindUIEvent(dwCastleID, tWidgetInfo)

        --初始隐藏
        UIHelper.SetVisible(togBig, false)
        UIHelper.SetVisible(widgetSelect, false)
        UIHelper.SetVisible(widgetBigBarn, false)
        UIHelper.SetVisible(widgetBigTong, false)
        UIHelper.SetVisible(imgBigBarn_Broke, false)

        tCastleWidget[dwCastleID] = tWidgetInfo
    end

    local nCount = g_tTable.CastleInfo:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.CastleInfo:GetRow(i)

        local dwCastleID = tLine.dwCastleID
        local dwMapID = tLine.dwMapID

        _initCastleWidget(dwMapID, dwCastleID)
    end

    self.tMapWidget = tMapWidget
    self.tCastleWidget = tCastleWidget

    self:InitArrowWidget()
    self:SetRightInfoState(INFO_TYPE.NONE)
end

function UICampMapView:InitArrowWidget()
    local tArrowWidget = {}

    local tCamp2Str = {
        [CAMP.GOOD] = "J",
        [CAMP.EVIL] = "E",
    }

    local tIndex2Dir = {
        [1] = "Up",
        [2] = "Mid",
        [3] = "Down",
    }

    for nCamp, szCamp in pairs(tCamp2Str) do
        local parent = self.WidgetArrow:getChildByName("WidgetArrow_" .. szCamp)
        local tArrow = {}
        for nIndex, szDir in pairs(tIndex2Dir) do
            local szArrow = "ImgArrow" .. szDir .. "_" .. szCamp
            local szNum1 = "ImgNum1Arrow" .. szDir .. "_" .. szCamp
            local szNum2 = "ImgNum2Arrow" .. szDir .. "_" .. szCamp

            local arrow = parent:getChildByName(szArrow)    assert(arrow, szArrow)
            local num1  = parent:getChildByName(szNum1)     assert(num1, szNum1)
            local num2  = parent:getChildByName(szNum2)     assert(num2, szNum2)

            local tDir = {
                arrow = arrow,
                num1 = num1,
                num2 = num2,
            }
            tArrow[nIndex] = tDir
        end
        tArrow.widgetArrow = parent
        tArrowWidget[nCamp] = tArrow
    end

    self.tArrowWidget = tArrowWidget
end

function UICampMapView:InitBtnState()
    local dwActivityID = CAMP_WAR_BRANCH_OPEN_ACTIVITY
    local bOpen = ActivityData.IsActivityOn(dwActivityID) or UI_IsActivityOn(dwActivityID)
    self:UpdateBtnBranchState(bOpen)
    self:UpdateBusinessInfo()
    -- self:UpdateBtnState()
end

function UICampMapView:UpdateInfo()
    self:UpdateCastleState()
    self:UpdateBusinessInfo()
    self:UpdateBigArrow()
    self:UpdateBattleLine()
    -- self:UpdateMapAppointment()

    --如果界面已打开则暂不更新，否则会使ScrollView刷到开头
    if not UIHelper.GetVisible(self.WidgetScrollViewLineup) then
        self:UpdateWarInfo()
    end
end

function UICampMapView:UpdateCastleBtnState()
    local tCastleWidget = self.tCastleWidget or {}

    local dwSelCastleID = self.dwSelCastleID
    local nScale = UIHelper.GetScale(self.WidgetMap)

    local tSelWidgetInfo = dwSelCastleID and tCastleWidget[dwSelCastleID]
    local dwSelMapID = tSelWidgetInfo and tSelWidgetInfo.dwMapID

    for dwCastleID, tWidgetInfo in pairs(tCastleWidget) do
        local dwMapID = tWidgetInfo.dwMapID
        local bShow = dwSelCastleID == dwCastleID or dwSelMapID == dwMapID
        local bSel = dwSelCastleID == dwCastleID

        UIHelper.SetVisible(tWidgetInfo.togBig, bShow)
        UIHelper.SetSelected(tWidgetInfo.togBig, bSel, false)
    end
end

function UICampMapView:UpdateResetTime(nWillResetTime)
    local bShow = nWillResetTime and nWillResetTime > 0
    UIHelper.SetVisible(self.WidgetResetTime, bShow)
    UIHelper.LayoutDoLayout(self.LayoutRightMessage)
    if bShow then
        --local szText = g_tStrings.CAMP_MAP_RESET_TIME .. TimeLib.GetDateTextHour(nWillResetTime)
        local szText = TimeLib.GetDateTextHour(nWillResetTime)
        UIHelper.SetString(self.LabelResetTimeNum, szText)
    end
end

function UICampMapView:UpdateTime()
    local nCurrentTime = GetCurrentTime()
    local tTime = TimeToDate(nCurrentTime)
    local bInActivity, bQueueTime = CampData.IsInCastleActivity() --周二周四小攻防
    local bIsInCampActivity, bCampQueueTime = CampData.IsInCampActivity() --周六周日大攻防

    UIHelper.SetVisible(self.WidgetTime, true)

    if bInActivity ~= self.bInActivity then
        self.bInActivity = bInActivity
        self:UpdateInfo()
    end

    local szTime = string.format("%02d:%02d:%02d", tTime.hour, tTime.minute, tTime.second)
    UIHelper.SetString(self.LabelTimeNum1, szTime)

    local nStartTime, nEndTime
    if bInActivity or bQueueTime then
        nStartTime, nEndTime = CampData.ACTIVITY_START_TIME, CampData.ACTIVITY_END_TIME
    elseif bIsInCampActivity or bCampQueueTime then
        if tTime.hour < CampData.ACTIVITY_CAMP_END_TIME_1 then
            nStartTime, nEndTime = CampData.ACTIVITY_CAMP_START_TIME_1, CampData.ACTIVITY_CAMP_END_TIME_1
        else
            nStartTime, nEndTime = CampData.ACTIVITY_CAMP_START_TIME_2, CampData.ACTIVITY_CAMP_END_TIME_2
        end
    end

    local bReadyQueue = nStartTime and tTime.hour == nStartTime - 1 and tTime.minute < 30 --活动前1小时到活动前30分钟，显示排队开始时间
    local bReadyStart = nStartTime and tTime.hour == nStartTime - 1 and tTime.minute >= 30 --活动前30分钟到活动开始，显示活动开始时间
    local bReadyEnd = nStartTime and tTime.hour >= nStartTime and tTime.hour <= nEndTime --活动开始到活动结束，显示活动结束时间
    local bShow = bReadyQueue or bReadyStart or bReadyEnd

    UIHelper.SetVisible(self.ImgTimeBg2, bShow)
    UIHelper.SetVisible(self.LabelTimeName2, bShow)
    UIHelper.SetVisible(self.LabelTimeNum2, bShow)

    if bReadyQueue then
        UIHelper.SetString(self.LabelTimeName2, "攻防排队时间：")
        UIHelper.SetString(self.LabelTimeNum2, (nStartTime - 1) .. ":30:00")
    elseif bReadyStart then
        UIHelper.SetString(self.LabelTimeName2, "攻防开战时间：")
        UIHelper.SetString(self.LabelTimeNum2, nStartTime .. ":00:00")
    elseif bReadyEnd then
        UIHelper.SetString(self.LabelTimeName2, "攻防结束时间：")
        UIHelper.SetString(self.LabelTimeNum2, nEndTime .. ":00:00")
    end
end

function UICampMapView:UpdateCastleState()
    local function _updateWidgetStateByCamp(tCampWidget, nCamp)
        UIHelper.SetVisible(tCampWidget[CAMP.NEUTRAL], nCamp == CAMP.NEUTRAL)
        UIHelper.SetVisible(tCampWidget[CAMP.GOOD], nCamp == CAMP.GOOD)
        UIHelper.SetVisible(tCampWidget[CAMP.EVIL], nCamp == CAMP.EVIL)
    end

    --print("[Camp Map] UpdateCastleState")

    local player = GetClientPlayer()
    local nCamp = player.nCamp
    local dwTongID = player.dwTongID
    local bInActivity = self.bInActivity
    local tCastleWidget = self.tCastleWidget or {}
    local tCastleWarMap = {}

    --选中 放大/缩小 相关
    local dwSelCastleID = self.dwSelCastleID
    local tSelWidgetInfo = dwSelCastleID and tCastleWidget[dwSelCastleID]
    local dwSelMapID = tSelWidgetInfo and tSelWidgetInfo.dwMapID

    --跑商相关
    local tSelBusiness = self.tSelBusiness

    for dwCastleID, tInfo in pairs(self.tCastleTips or {}) do
        local tWidgetInfo = tCastleWidget[dwCastleID]
        if tWidgetInfo then
            local dwMapID = tWidgetInfo.dwMapID
            --local bShow = not tSelBusiness or (tSelBusiness.dwSourceCastleID == dwCastleID or tSelBusiness.dwTargetCastleID == dwCastleID) --跑商时，只显示跑商路线上的大图标

            local bShow = true
            local bSel = dwSelCastleID == dwCastleID

            --Camp底色
            local nCastleCamp = tInfo.nCamp

            --粮仓
            local bShowBarn = tInfo.nGrainState == 0 --0可被攻击 1已毁坏
            local nBarnCamp = bInActivity and bShowBarn and nCastleCamp
            local bShowBrokeBarn = bInActivity and not bShowBarn

            --帮会
            local bHasTong = dwTongID and dwTongID ~= 0 and dwTongID == tInfo.dwTongID
            local bShowTong = bHasTong and not bInActivity --攻防期间要显示粮仓，不显示帮会

            --Map
            local tMapWidget = self.tMapWidget[dwMapID]
            if tMapWidget then
                local bWarState = tInfo.nCastleState == 1
                UIHelper.SetVisible(tMapWidget.imgMapFight, bInActivity and bWarState)

                if bWarState then
                    --人数
                    tCastleWarMap[dwMapID] = true
                end
            end

            UIHelper.SetVisible(tWidgetInfo.togBig, bShow)

            if bShow then
                _updateWidgetStateByCamp(tWidgetInfo.tImgBigBg, nCastleCamp)
                _updateWidgetStateByCamp(tWidgetInfo.tImgBigBarn, nBarnCamp)
                _updateWidgetStateByCamp(tWidgetInfo.tImgBigTong, bShowTong and nCastleCamp)
                _updateWidgetStateByCamp(tWidgetInfo.tImgBgLight, bHasTong and nCastleCamp)
                UIHelper.SetVisible(tWidgetInfo.imgBigBarn_Broke, bShowBrokeBarn)
                UIHelper.SetVisible(tWidgetInfo.widgetBigBarn, bInActivity and bShowBarn)
                UIHelper.SetVisible(tWidgetInfo.widgetBigTong, bShowTong)
            end

            _updateWidgetStateByCamp(tWidgetInfo.tImgCampBg, nCastleCamp)
            _updateWidgetStateByCamp(tWidgetInfo.tImgSelect, nCastleCamp)

            UIHelper.SetSelected(tWidgetInfo.togBig, bSel, false)
        else
            LOG.ERROR("[Camp Map] dwCastleID [%s] does not exist." .. tostring(dwCastleID))
        end
    end

    --跑商特殊处理，低保路线
    -- local bRoute_Good, bRoute_Evil = false, false
    -- if tSelBusiness and tSelBusiness.bCampRoute then
    --     if nCamp == CAMP.GOOD then
    --         bRoute_Good = true
    --     elseif nCamp == CAMP.EVIL then
    --         bRoute_Evil = true
    --     end
    -- end
    -- UIHelper.SetVisible(self.ImgCampMap2_T, bRoute_Good)
    -- UIHelper.SetVisible(self.ImgCampMapBg21_T, bRoute_Good)
    -- UIHelper.SetVisible(self.ImgCampMap1_T, bRoute_Evil)
    -- UIHelper.SetVisible(self.ImgCampMapBg23_T, bRoute_Evil)

    -- UIHelper.SetVisible(self.ImgIconCamp_h, nCamp == CAMP.GOOD)
    -- UIHelper.SetVisible(self.ImgIconCamp_e, nCamp == CAMP.EVIL)

    self.tCastleWarMap = tCastleWarMap
end

function UICampMapView:UpdateBigArrow()
    local bInActivity = self.bInActivity
    if not bInActivity then
        UIHelper.SetVisible(self.WidgetArrow, false)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local nCamp = player.nCamp
    if nCamp == CAMP.NEUTRAL then
        return
    end

    UIHelper.SetVisible(self.WidgetArrow, true)
    UIHelper.SetVisible(self.tArrowWidget[CAMP.GOOD].widgetArrow, nCamp == CAMP.GOOD)
    UIHelper.SetVisible(self.tArrowWidget[CAMP.EVIL].widgetArrow, nCamp == CAMP.EVIL)

    local nOpenedLine = 0
    local tCastleTips = self.tCastleTips or {}
    for nIndex, tLine in pairs(tThreeLine) do
        local bShow = true
        for i, dwCastleID in pairs(tLine) do
            local tInfo = tCastleTips[dwCastleID]
            if tInfo and tInfo.nCamp ~= nCamp then
                bShow = false
                break
            end
        end

        local tArrow = self.tArrowWidget[nCamp][nIndex]
        if bShow then
            nOpenedLine = nOpenedLine + 1

            local bShowNum1 = nOpenedLine ~= 1
            UIHelper.SetVisible(tArrow.arrow, true)
            UIHelper.SetVisible(tArrow.num1, bShowNum1) -- +100人
            UIHelper.SetVisible(tArrow.num2, not bShowNum1) -- +200人
        else
            UIHelper.SetVisible(tArrow.arrow, false)
            UIHelper.SetVisible(tArrow.num1, false)
            UIHelper.SetVisible(tArrow.num2, false)
        end
    end
end

function UICampMapView:UpdateMapAppointment()
    if self.dwBookMapID then
        local tMapWidget = self.tMapWidget[self.dwBookMapID]
        if tMapWidget then
            UIHelper.SetVisible(tMapWidget.imgBook, false)
        end
    end

    UIHelper.SetVisible(self.ImgYuyue1, false)
    UIHelper.SetVisible(self.ImgYuyue2, false)

    local dwBookMapID = GetScheduledMap()
    local tMapWidget = self.tMapWidget[dwBookMapID]
    if tMapWidget then
        UIHelper.SetVisible(tMapWidget.imgBook, true)
    elseif dwBookMapID == GOOD_MAP then
        UIHelper.SetVisible(self.ImgYuyue2, true)
    elseif dwBookMapID == EVIL_MAP then
        UIHelper.SetVisible(self.ImgYuyue1, true)
    end

    self.dwBookMapID = dwBookMapID
end

function UICampMapView:UpdateBattleLine()
    local tBattleLine = self.tBattleLine
    --小箭头功能不要了
end

function UICampMapView:UpdateCampBigThing(tRecord)
    -- if not tRecord or IsTableEmpty(tRecord) then
    --     local szText = g_tStrings.STR_NO_CAMP_BIGTHING
    -- else
    --     local tDate = TimeToDate(tRecord.time)
    --     local szTime = g_tStrings.STR_TIME_7 .. FormatString(g_tStrings.STR_TIME_4, tDate.year, tDate.month, tDate.day, tDate.hour, string.format("%02d",tDate.minute)) .. "\n"
    --     local szText = szTime .. " " .. tRecord.text
    -- end
end

function UICampMapView:ClearSelectFlag()
    if self.dwSelCastleID then
        self.dwSelCastleID = nil
        self:UpdateCastleState()
    end
end

-------------------------------- 据点详情 --------------------------------

function UICampMapView:OnCastleSelect(dwCastleID)
    if self.dwSelCastleID == dwCastleID then
        return
    end

    if dwCastleID then
        print("[Camp Map] OnCastleSelect", dwCastleID)
    end

    self.dwSelCastleID = dwCastleID
    self:OnCastleSelectTransform()
    self:UpdateCastleState()
    self:UpdateSelectedCastle(dwCastleID)
    self:UpdateBtnBelongState(dwCastleID)
end

--使Castle居中显示、放大等变换
function UICampMapView:OnCastleSelectTransform()
    local dwSelCastleID = self.dwSelCastleID
    local tWidgetInfo = dwSelCastleID and self.tCastleWidget[dwSelCastleID]
    if not tWidgetInfo then
        self.nTargetMapPos = nil
        self.nTargetMapScale = 1
        return
    end

    local widgetSel = tWidgetInfo.widgetSelect
    local nPosX, nPosY = UIHelper.GetWorldPosition(widgetSel)
    local nMapPosX, nMapPosY = UIHelper.GetWorldPosition(self.WidgetMap)

    self.nTargetMapPos = {
        nX = nMapPosX - nPosX + MAP_CENTER_OFFSET_X, --向左偏移一点
        nY = nMapPosY - nPosY
    }
    self.nTargetMapScale = SCALE_SELECTED
end

function UICampMapView:UpdateSelectedCastle(dwCastleID)
    if not dwCastleID then
        self:SetRightInfoState(INFO_TYPE.NONE)
        return
    end

    local tInfo = Table_GetCastleInfo(dwCastleID)
    if not tInfo then
        return
    end

    self:SetRightInfoState(INFO_TYPE.CASTLE_INFO)

    local dwMapID = tInfo.dwMapID
    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)) --地图名称
    local szCastleName = UIHelper.GBKToUTF8(tInfo.szCastleName) --据点名称
    local nDefance = tInfo.nDefance --箭塔
    local szCar = "可产出" --载具

    local szImgPath = string.format("Resource/CampMapImg/%s.png", tostring(dwCastleID))
    UIHelper.SetTexture(self.ImgCityBg,  szImgPath)

    local tCastleTips = self.tCastleTips or {}
    local tCastle = tCastleTips[dwCastleID]
    if not tCastle then
        return
    end

    --状态
    local szState
    if tCastle.nCastleState == 0 then
        szState = g_tStrings.STR_CASTLE_STATE1
    elseif tCastle.nCastleState == 1 then
        szState = g_tStrings.STR_CASTLE_STATE2
    end

    if tInfo.nActivityState == 1 then --self.bInActivity or tInfo.nActivityState?
        if tInfo.nGrainState == 0 then
            szState = szState .. UIHelper.AttachTextColor("（粮仓可被攻击）", FontColorID.ImportantGreen)
        else
            szState = szState .. UIHelper.AttachTextColor("（粮仓已被洗劫）", FontColorID.ImportantRed)
        end
    end

    --归属
    local szCamp = g_tStrings.STR_CAMP_TITLE[tCastle.nCamp or CAMP.NEUTRAL]

    UIHelper.SetString(self.LabelCityMessageTitle2, szMapName)
    UIHelper.SetString(self.LabelCityMessageName, szCastleName)
    UIHelper.SetRichText(self.LabelCityMessage12, szState)
    UIHelper.SetString(self.LabelCityMessage22, nDefance)
    UIHelper.SetString(self.LabelCityMessage32, szCar)
    UIHelper.SetString(self.LabelCityMessage42, szCamp)

    --帮会
    local bHasTong = tCastle.dwTongID ~= 0
    UIHelper.SetVisible(self.LayoutCityMessage5, bHasTong)
    UIHelper.SetVisible(self.LayoutCityMessage6, bHasTong)
    UIHelper.SetVisible(self.LayoutCityMessage7, bHasTong)
    UIHelper.SetVisible(self.LayoutCityMessage8, bHasTong)
    UIHelper.SetVisible(self.LayoutCityMessage9, bHasTong)
    UIHelper.SetVisible(self.LayoutCityMessage10, bHasTong)
    UIHelper.SetVisible(self.WidgetCityEmpty, not bHasTong)

    if not bHasTong then
        UIHelper.LayoutDoLayout(self.LayoutCityMessage)
        return
    end

    local szTongName = UIHelper.GBKToUTF8(tCastle.szTongName) --帮会
    local szMasterName = UIHelper.GBKToUTF8(tCastle.szMasterName) --帮主
    local szSchool = Table_GetForceName(tCastle.dwMasterForceID) --职业
    local szAchievement = UIHelper.GBKToUTF8(tInfo.szAchievement) --称号
    local szAllianceName = UIHelper.GBKToUTF8(tCastle.szAllianceName) --同盟
    local nRidePiece = tCastle.nRidePiece --战功牌

    UIHelper.SetString(self.LabelCityMessage52, szTongName)
    UIHelper.SetString(self.LabelCityMessage62, szMasterName)
    UIHelper.SetString(self.LabelCityMessage72, szSchool)
    UIHelper.SetString(self.LabelCityMessage82, szAchievement)
    UIHelper.SetString(self.LabelCityMessage92, szAllianceName)
    UIHelper.SetString(self.LabelCityMessage102, nRidePiece)

    --TODO 帮主头像？端游CampMapsTips.lua: 114
    --UIHelper.RoleChange_UpdateAvatar(playerImgNode, dwMiniAvatarID, SFXPlayerIconNode, playerAniNode, tCastle.nMasterRoleType, tCastle.dwMasterForceID)

    UIHelper.LayoutDoLayout(self.LayoutCityMessage)
end

function UICampMapView:OnClickShowCastleMapBtn(dwCastleID)
    local tInfo = Table_GetCastleInfo(dwCastleID)
    local dwMapID = tInfo and tInfo.dwMapID
    CampData.CampTransfer(dwMapID)
end

-------------------------------- 攻防概况 --------------------------------

function UICampMapView:ShowWarInfo()
    self.dwSelCastleID = nil
    self:UpdateCastleState()
    self:SetRightInfoState(INFO_TYPE.WAR_INFO)
    self:UpdateWarInfo()
end

function UICampMapView:UpdateWarInfo()
    local bInActivity = self.bInActivity
    local tCastleWarMap = self.tCastleWarMap or {}
    local tMapNumer = GetCampPlayerCountPerMap()

    local szTitle = bInActivity and "开战地图人数" or "今日攻防地图" --按钮19:00出现，19:00-20:00攻防战未开始期间显示“今日攻防地图”
    UIHelper.SetString(self.LabelLineupTitle2, szTitle)

    UIHelper.RemoveAllChildren(self.ScrollViewLineup)

    --非攻防期间按for pairs排，攻防期间按人数排序
    if not bInActivity or not tMapNumer or IsTableEmpty(tMapNumer) then
        for dwMapID, bWar in pairs(tCastleWarMap) do
            UIMgr.AddPrefab(PREFAB_ID.WidgetLineupCity, self.ScrollViewLineup, dwMapID)
        end
    else
        local tNumber = clone(tMapNumer)
        if not tNumber then
            return
        end

        local nCamp = GetClientPlayer().nCamp
        if nCamp == CAMP.GOOD then
            table.sort(tNumber, fnSortGoodPlayer)
        elseif nCamp == CAMP.EVIL then
            table.sort(tNumber, fnSortEvilPlayer)
        end

        for _, tData in ipairs(tNumber) do
            local dwMapID = tData.dwMapID
            if not IsTableEmpty(Table_GetCastleByMapID(dwMapID)) and tCastleWarMap[dwMapID] then
                local nNumber, nLimit
                if nCamp == CAMP.GOOD then
                    nNumber = tData.nGoodPlayerCount
                    nLimit = tData.nMaxGoodPlayerCount
                elseif nCamp == CAMP.EVIL then
                    nNumber = tData.nEvilPlayerCount
                    nLimit = tData.nMaxEvilPlayerCount
                end

                local szPerson = nNumber .. "/" .. nLimit .. g_tStrings.STR_PERSON
                if nNumber < 100 then
                    szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantGreen)
                elseif nNumber < 150 then
                    szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantYellow)
                elseif nNumber < 180 then
                    szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.Backup2_Orange)
                else
                    szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantRed)
                end

                UIMgr.AddPrefab(PREFAB_ID.WidgetLineupCity, self.ScrollViewLineup, dwMapID, szPerson)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLineup)
end

function UICampMapView:OnClickGoWarMapBtn(dwMapID)
    UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
end

-------------------------------- 跑商路线 --------------------------------

function UICampMapView:UpdateBusinessInfo()
    local function _parseText(szText)
        return string.match(szText, "%[(.+)·(.+)%]")
    end

    local function _parseLink(szLink)
        local szLinkID, szMapID = string.match(szLink, "TrackingNpc/(%w+)/(%w+)")
        return tonumber(szLinkID), tonumber(szMapID)
    end

    local function _getCastleInfoByCastleName(szCastleName)
        for dwCastleID, tInfo in pairs(self.tCastleTips or {}) do
            local tLine = Table_GetCastleInfo(dwCastleID)
            local szName = tLine and UIHelper.GBKToUTF8(tLine.szCastleName) --名称
            if szCastleName == szName then
                return dwCastleID, tInfo.nCastleState == 1
            end
        end
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    -- local szBusinessTitle = FormatString(g_tStrings.STR_CASTLE_BUSINESS_ROUTE_TITLE, g_tStrings.STR_CAMP_TITLE[hPlayer.nCamp])
    -- UIHelper.SetString(self.LabelTradeRoute, szBusinessTitle)
    UIHelper.SetString(self.LabelTransactionCamp, "(" .. g_tStrings.STR_CAMP_TITLE[hPlayer.nCamp] .. ")")
    UIHelper.SetVisible(self.ImgTransactionBg2, hPlayer.nCamp == CAMP.GOOD)
    UIHelper.SetVisible(self.ImgTransactionBg1, hPlayer.nCamp == CAMP.EVIL)

    local tInfo = self.nBusinessIndex and g_tStrings.tBusinessRoute[self.nBusinessIndex]
    if not tInfo then
        return
    end

    local bInActivity = self.bInActivity
    local szSourceMapName, szSourceCastleName = _parseText(tInfo.SourceText)
    local szTargetMapName, szTargetCastleName = _parseText(tInfo.TargetText)
    local dwSourceLinkID, dwSourceMapID = _parseLink(tInfo.SourceLink)
    local dwTargetLinkID, dwTargetMapID = _parseLink(tInfo.TargetLink)
    local dwSourceCastleID, bSourceWarState = _getCastleInfoByCastleName(szTargetCastleName)
    local dwTargetCastleID, bTargetWarState = _getCastleInfoByCastleName(szSourceCastleName)

    self.tSelBusiness = {
        szSourceMapName = szSourceMapName,
        szSourceCastleName = szSourceCastleName,
        szTargetMapName = szTargetMapName,
        szTargetCastleName = szTargetCastleName,
        dwSourceLinkID = dwSourceLinkID,
        dwSourceMapID = dwSourceMapID,
        dwSourceCastleID = dwSourceCastleID,
        dwTargetLinkID = dwTargetLinkID,
        dwTargetMapID = dwTargetMapID,
        dwTargetCastleID = dwTargetCastleID,
        bCampRoute = szSourceMapName == g_tStrings.STR_CAMP_TITLE[CAMP.GOOD] or szSourceMapName == g_tStrings.STR_CAMP_TITLE[CAMP.EVIL], --固定低保路线
        bWarState = bInActivity and (bSourceWarState or bTargetWarState), --进战状态，用于文本提示
    }

    UIHelper.SetString(self.LabelTransactionName1, szSourceMapName .. "·" .. szSourceCastleName)
    UIHelper.SetString(self.LabelTransactionName11, szTargetMapName .. "·" .. szTargetCastleName)
    UIHelper.LayoutDoLayout(self.WidgetTransaction01)
end

-------------------------------- 地图分线选择 --------------------------------

function UICampMapView:ShowMapSelectInfo(dwMapID, bActicity, tMapList)
    self.dwSelCastleID = nil
    self:UpdateCastleState()
    self:SetRightInfoState(INFO_TYPE.SELECT_MAP)
    local scriptSelectMap = UIHelper.GetBindScript(self.WidgetCampSelectMap)
    scriptSelectMap:UpdateInfo(dwMapID, bActicity, tMapList)
end

--------------------------------  --------------------------------

function UICampMapView:SetRightInfoState(nType)
    self.nInfoType = nType
    local bShow = nType ~= INFO_TYPE.NONE
    UIHelper.SetVisible(self.WidgetAnchorRightTop, bShow)
    UIHelper.SetVisible(self.BtnCloseRight, bShow)
    UIHelper.SetVisible(self.WidgetAnchorRight, not bShow)

    if bShow then
        local bCastleInfo = nType == INFO_TYPE.CASTLE_INFO
        local bWarInfo = nType == INFO_TYPE.WAR_INFO
        local bSelectMapInfo = nType == INFO_TYPE.SELECT_MAP
        UIHelper.SetVisible(self.LabelCityMessageTitle, bCastleInfo)
        UIHelper.SetVisible(self.WidgetCityMessage, bCastleInfo)
        UIHelper.SetVisible(self.LabelLineupTitle, bWarInfo)
        UIHelper.SetVisible(self.WidgetScrollViewLineup, bWarInfo)
        UIHelper.SetVisible(self.LabelSelectMapTitle, bSelectMapInfo)
        UIHelper.SetVisible(self.WidgetCampSelectMap, bSelectMapInfo)
    end
end

--据点归属按钮
function UICampMapView:UpdateBtnBelongState(dwCastleID)
    UIHelper.SetVisible(self.BtnBelong, false)
    if not dwCastleID then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if not dwCastleID then
        return
    end

    local tInfo = Table_GetCastleInfo(dwCastleID)
    if not tInfo then
        return
    end

    local tCastle = self.tCastleTips and self.tCastleTips[dwCastleID]
    if not tCastle then
        return
    end

    local bSameMap = tInfo.dwMapID == MapHelper.GetMapID()

    local nCamp = player.nCamp
    local nCastleCamp = tCastle.nCamp
    local bOppositeCamp = (nCamp == CAMP.GOOD and nCastleCamp == CAMP.EVIL) or (nCamp == CAMP.EVIL and nCastleCamp == CAMP.GOOD)

    local bShowOpenRankEntrance = CampData.bShowOpenRankEntrance and bSameMap and bOppositeCamp
    UIHelper.SetVisible(self.BtnBelong, bShowOpenRankEntrance)
end

function UICampMapView:UpdateBtnBranchState(bOpen)
    local bEnable = bOpen and CampData.IsInCastleActivity()
    UIHelper.SetButtonState(self.BtnYinshan, bEnable and BTN_STATE.Normal or BTN_STATE.Disable, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnYinshan, TipsLayoutDir.BOTTOM_LEFT, g_tStrings.STR_BATTLE_BRANCH_NOT_OPEN_TIP)
    end)
end

function UICampMapView:UpdateBtnState()
    local bBookZLZYOn = ActivityData.IsActivityOn(941)
    local bBookZYGFOn = ActivityData.IsActivityOn(942) or ActivityData.IsActivityOn(943)

    UIHelper.SetString(self.LabelGo2, bBookZLZYOn and "预约" or "前往")
    UIHelper.SetString(self.LabelGo3, bBookZYGFOn and "预约" or "前往")
end

function UICampMapView:ShowMapSelectInfoByTime()
    local nWeekDay = TimeLib.GetCurrentWeekday()
    if nWeekDay == 7 then
        self:ShowMapSelectInfo(GOOD_MAP, true)
    elseif nWeekDay == 6 then
        self:ShowMapSelectInfo(EVIL_MAP, true)
    else
        self:ShowMapSelectInfo(0, true, {GOOD_MAP, EVIL_MAP})
    end
end

function UICampMapView:UpdateWeather()
    local bShowERWeather, tEROnPreset = CampData.IsActivityPresetOn(EVIL_MAP)
    local bShowHQWeather, tHQOnPreset = CampData.IsActivityPresetOn(GOOD_MAP)
    local bEnablePreset = SelfieData.IsActivityPresetEnabled()

    UIHelper.SetVisible(self.BtnWeatherMap1, bShowERWeather)
    UIHelper.SetVisible(self.BtnWeatherMap2, bShowHQWeather)

    local bShowSwitch = false
    if bShowERWeather then
        bShowSwitch = true
        -- UIHelper.SetSpriteFrame(self.ImgWeatherMap1, bEnablePreset and tEROnPreset.szMobileImgNormalPath or tEROnPreset.szMobileImgDisablePath)
        UIHelper.SetSpriteFrame(self.ImgWeatherMap1, tEROnPreset.szMobileImgNormalPath)
        self.szWeatherTipER = UIHelper.GBKToUTF8(tEROnPreset.szDesc)
    end
    if bShowHQWeather then
        bShowSwitch = true
        -- UIHelper.SetSpriteFrame(self.ImgWeatherMap2, bEnablePreset and tHQOnPreset.szMobileImgNormalPath or tHQOnPreset.szMobileImgDisablePath)
        UIHelper.SetSpriteFrame(self.ImgWeatherMap2, tHQOnPreset.szMobileImgNormalPath)
        self.szWeatherTipHQ = tHQOnPreset and UIHelper.GBKToUTF8(tHQOnPreset.szDesc)
    end

    UIHelper.SetVisible(self.WidgetWeatherSwitch, bShowSwitch)
    UIHelper.SetSelected(self.ToggleLightPositionSwitch, bEnablePreset, false)
end

function UICampMapView:ShowCampMapWeatherTip(dwMapID)
    local tList = Table_GetActivityFilterPresetList(dwMapID)
    local tCurPreset
    for _, tPreset in ipairs(tList) do
        if UI_IsActivityOn(tPreset.dwActivityID) then
            tCurPreset = tPreset
            break
        end
    end

    if not tCurPreset then
        return
    end

    local szDesc = UIHelper.GBKToUTF8(tCurPreset.szDesc)
    local bEnable = SelfieData.IsActivityPresetEnabled()
end

return UICampMapView