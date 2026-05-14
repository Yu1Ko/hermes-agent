-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInvitationMessagePop
-- Date: 2023-03-24 09:24:58
-- Desc: PanelInvitationMessagePop
-- ---------------------------------------------------------------------------------

local _nDragThreshold = 300

local JX_GetDistanceTwice = JX.GetDistanceTwice
local sformat = string.format
local mmin = math.min
local mceil = math.ceil

local MOVE_STATE_ON_DEATH = MOVE_STATE.ON_DEATH

TARGET_FOCUS_COLOR_NEUTRAL = "#c3a355"
TARGET_FOCUS_COLOR_ALLY = "#4c994f"
TARGET_FOCUS_COLOR_ENEMY = "#c25959"
TARGET_FOCUS_COLOR_NEUTRAL_C3B = UIHelper.ChangeHexColorStrToColor("#c3a355")
TARGET_FOCUS_COLOR_ALLY_C3B = UIHelper.ChangeHexColorStrToColor("#4c994f")
TARGET_FOCUS_COLOR_ENEMY_C3B = UIHelper.ChangeHexColorStrToColor("#c25959")
TARGET_FOCUS_COLOR_SELF_C3B = UIHelper.ChangeHexColorStrToColor("#54a9b6")

local ListClassifyName = {
    [1] = "NPC",
    [2] = "玩家",
    [3] = "自定义",
    [4] = "阵营活动",
    [5] = "物品",
}

local tListForceColor = {
    [1] = UIHelper.ChangeHexColorStrToColor("#ffe26e"), -- 黄
    [2] = UIHelper.ChangeHexColorStrToColor("#95ff95"), -- 绿
    [3] = UIHelper.ChangeHexColorStrToColor("#ff7676"), -- 红
}

local UIWidgetTargetFocusList = class("UIWidgetTargetFocusList")

function UIWidgetTargetFocusList:OnEnter(ballScript)
    self.ballScript = ballScript

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self._tItemList = {}

    self.tTargetDataList = {}

    self:UpdateTitle()
    self:RefreshGeneralInfo()
    self:InitRefreshList()

    Timer.DelAllTimer(self)
    Timer.AddCycle(self, 0.8, function()
        if UIHelper.GetHierarchyVisible(self.ballScript._rootNode) then
            self:RefreshList()
        end
    end)

    self:UpdateFilterInfo()
    self:InitBgOpacity()
end

function UIWidgetTargetFocusList:OnExit()
    Timer.DelAllTimer(self)
    Event.UnRegAll(self)

    self:UnInitScrollList()
end

function UIWidgetTargetFocusList:BindUIEvent()
    self.ballScript:BindDrag(self.BtnDrag)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.bLikeMsg == true then
            Event.Dispatch(EventType.OnCloseLikeTip, false)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogPublish, EventType.OnClick, function()
        self:ShowPublishTip()
    end)

    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function()
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSwitch, TipsLayoutDir.RIGHT_CENTER, FilterDef.FocusList)
        script:BindFocusMoreCallBack(function()
            UIMgr.Open(VIEW_ID.PanelGameSettings, SettingCategory.Focus, 1)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        JX_TargetList.nListClassify = JX_TargetList.nListClassify - 1
        if JX_TargetList.nListClassify < 1 then
            JX_TargetList.nListClassify = #ListClassifyName
        end

        self:UpdateTitle()
        self:InitRefreshList()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        JX_TargetList.nListClassify = JX_TargetList.nListClassify + 1
        if JX_TargetList.nListClassify > #ListClassifyName then
            JX_TargetList.nListClassify = 1
        end

        self:UpdateTitle()
        self:InitRefreshList()
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelGameSettings, SettingCategory.Focus, 3)
    end)
end

function UIWidgetTargetFocusList:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.FocusList.Key then
            self:UpdateFilterInfo()
        end
    end)

    Event.Reg(self, "LOADING_END", function()
        self:InitRefreshList()
    end)

    Event.Reg(self, EventType.OnFocusCampCountUpdate, function()
        self:RefreshGeneralInfo()
    end)

    Event.Reg(self, EventType.OnSetDragDpsBgOpacity, function(nOpacity)
        if nOpacity then
            UIHelper.SetOpacity(self.ImgListBg, nOpacity)
        end
    end)
end

function UIWidgetTargetFocusList:UpdateTitle()
    UIHelper.SetString(self.LabelSwtich, ListClassifyName[JX_TargetList.nListClassify])
    --UIHelper.SetVisible(self.BtnLeft, JX_TargetList.nListClassify >= 2)
    --UIHelper.SetVisible(self.BtnRight, JX_TargetList.nListClassify <= 3)
end

function UIWidgetTargetFocusList:InitRefreshList()
    for i = 1, #self._tItemList do
        self.FocustListCellPool:Recycle(self._tItemList[i]._rootNode) -- 回收无用Cell
    end
    self._tItemList = {}
    self.tTargetDataList = {}

    if self.tScrollList == nil then
        self:InitScrollList()
    end
    self:UpdateInfo_Content() --重置属性
    self:RefreshList()
    UIHelper.ScrollToTop(self.ScrollViewPlayList)
end

function UIWidgetTargetFocusList:RefreshList()
    if not JX_TargetList.bShowList or not g_pClientPlayer then
        return
    end

    self._tItemList = self._tItemList or {}

    local nListClassify = _JX_TargetList.IsInMobaMap and 1 or JX_TargetList.nListClassify
    local tObjectList = CopyTable(_JX_TargetList.GetObjectByType(nListClassify))
    local me = g_pClientPlayer
    local nFocusCount = 0
    local nItemTopCount = (JX_TargetList.bJJCHideList and JX.IsArenaMap() or _JX_TargetList.bGFObserver) and 6 or 3

    if me and me.IsInParty() then
        _JX_TargetList.tPartyMark = GetClientTeam().GetTeamMark() or {}
    else
        _JX_TargetList.tPartyMark = {}
    end

    ---------------将焦点放入列表中 --------------------
    local fnAddFocusToList = function(tList)
        tList = tList or {}
        for dwID, _ in pairs(tList) do
            local tar = JX.GetObject(dwID)
            if tar then
                if not tObjectList[dwID] then
                    tObjectList[dwID] = tar -- 当前分类没有该物品
                end
            end
        end
    end
    fnAddFocusToList(_JX_TargetList.tTempFocusID)
    fnAddFocusToList(_JX_TargetList._tItemListFocus)

    _JX_TargetList._tItemTopFocus = {}
    for dwID, _ in pairs(_JX_TargetList.tTopFocusID) do
        local tar = JX.GetObject(dwID)
        if JX.GetTableCount(_JX_TargetList._tItemTopFocus) < nItemTopCount and tar then
            if not tObjectList[dwID] then
                tObjectList[dwID] = tar -- 当前分类没有该物品
            end
            _JX_TargetList._tItemTopFocus[dwID] = 1 -- 设为置顶
        end
    end

    -------------------------------------------------

    local lst = {}
    local nAllObjectNum, nLiveObjectNum = 0, 0
    for dwObID, hObject in pairs(tObjectList) do
        local szName = JX.GetObjectName(hObject)
        if not IsPlayer(dwObID) then
            szName = "NPC_" .. szName
        end
        local bIsTop = _JX_TargetList._tItemTopFocus[dwObID] ~= nil
        local bIsPermanent = Storage.FocusList._tFocusTargetData[szName] ~= nil
        local bIsFocus = (_JX_TargetList.tTempFocusID[dwObID] or _JX_TargetList._tItemListFocus[dwObID] ~= nil
                or bIsPermanent or bIsTop)
        local bShowFocus = not bIsTop or JX_TargetList.bShowTopFocus -- 若为置顶焦点则需判断bShowTopFocus

        local function CreateTargetInfo(dwObID, targetObj, bIsDoodad)
            local tFocusCellInfo = {}
            local fPercentage = 1
            tFocusCellInfo.nDis = JX_GetDistanceTwice(me, targetObj)
            tFocusCellInfo.hObject = targetObj
            tFocusCellInfo.dwID = dwObID
            tFocusCellInfo.bIsFocus = bIsFocus
            tFocusCellInfo.bIsPermanent = bIsPermanent
            tFocusCellInfo.bIsTop = bIsTop

            tFocusCellInfo._perLife = 100
            tFocusCellInfo.bIsDoodad = bIsDoodad

            if not bIsDoodad then
                fPercentage = JX.GetCurrentLife(targetObj) / JX.GetMaxLife(targetObj)
                tFocusCellInfo._perLife = mmin(mceil(fPercentage * 100), 100)
            end

            if JX_TargetList.nSortType == 0 or JX_TargetList.nSortType == 2 then
                tFocusCellInfo.nSortValue = tFocusCellInfo.nDis   -- 排序
            elseif JX_TargetList.nSortType == 1 or JX_TargetList.nSortType == 3 then
                tFocusCellInfo.nSortValue = mmin(fPercentage, 1)
            end

            if not bIsDoodad and targetObj.nMoveState == MOVE_STATE_ON_DEATH and JX_TargetList.bFootDie then
                tFocusCellInfo.nSortValue = (tFocusCellInfo.nSortValue or 0) + 10000
            end

            if not bIsFocus then
                tFocusCellInfo.nSortValue = (tFocusCellInfo.nSortValue or 0) + 1000000 -- 预留前1000000给临时焦点
            else
                if not bIsTop then
                    tFocusCellInfo.nSortValue = (tFocusCellInfo.nSortValue or 0) + 500000 -- 预留前500000给置顶焦点
                end
                nFocusCount = nFocusCount + 1
            end

            if JX_TargetList.bFootDis and tFocusCellInfo.nDis > JX_TargetList.nFootDis then
                tFocusCellInfo.nSortValue = tFocusCellInfo.nSortValue + 30000
            end

            table.insert(lst, tFocusCellInfo)
        end

        -- 策划说doodad和玩家dwid重复时两者都需要显示
        if IsDoodadExist(dwObID) then
            nLiveObjectNum = nLiveObjectNum + 1
            nAllObjectNum = nAllObjectNum + 1
            CreateTargetInfo(dwObID, GetDoodad(dwObID), true)
        end

        if IsPlayerExist(dwObID) or IsNpcExist(dwObID) then
            if bIsFocus or nListClassify == 4 or _JX_TargetList.ShouldShowObject(dwObID, hObject) then
                if not (JX_TargetList.bFilterFocus and bIsFocus and not _JX_TargetList.IsInMobaMap) and bShowFocus then
                    CreateTargetInfo(dwObID, hObject,false)  -- 阵营活动分页不检查条件
                end

                if hObject.nMoveState ~= MOVE_STATE_ON_DEATH then
                    nLiveObjectNum = nLiveObjectNum + 1
                end
                nAllObjectNum = nAllObjectNum + 1
            end
        end
    end

    self.tTargetDataList = lst

    self.ballScript:UpdateFocusInfo(nFocusCount)
    if not UIHelper.GetVisible(self._rootNode) then
        return
    end

    table.sort(lst, function(a, b)
        return a.nSortValue < b.nSortValue -- 排序
    end)

    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    self.tScrollList:ReloadWithStartIndex(#self.tTargetDataList, min) --刷新数量

    UIHelper.SetString(self.LabelTitleNum, string.format("(%d/%d)", nLiveObjectNum, nAllObjectNum))
    local tColor = tListForceColor[JX_TargetList.nListClassifyForce]
    if self.tColor ~= tColor then
        self.tColor = tColor
        UIHelper.SetTextColor(self.LabelTitleNum, tColor) -- 标题人数颜色及显示
    end

    UIHelper.SetVisible(self.BtnSetting, #lst <= 0 and JX_TargetList.nListClassify == 3) -- 当前为自定义分页，且目标为空时显示设置按钮
end

function UIWidgetTargetFocusList:RefreshGeneralInfo()
    local szAliveFormat = "存活: %d"
    local szInjuredFormat = "重伤: %d"
    local nGoodNum, nEvilNum, nNeturalNum, nLiveGoodNum, nLiveEvilNum, nLiveNeturalNum = JX_TargetList.GetCampNumberCount()
    UIHelper.SetString(self.LabelInforlive1, string.format(szAliveFormat, nLiveGoodNum))
    UIHelper.SetString(self.LabelInforInjury1, string.format(szInjuredFormat, nGoodNum - nLiveGoodNum))

    UIHelper.SetString(self.LabelInforlive2, string.format(szAliveFormat, nLiveEvilNum))
    UIHelper.SetString(self.LabelInforInjury2, string.format(szInjuredFormat, nEvilNum - nLiveEvilNum))

    UIHelper.SetString(self.LabelInforlive3, string.format(szAliveFormat, nLiveNeturalNum))
    UIHelper.SetString(self.LabelInforInjury3, string.format(szInjuredFormat, nNeturalNum - nLiveNeturalNum))
end

function UIWidgetTargetFocusList:Allocate()
    self.FocustListCellPool = self.FocustListCellPool or PrefabPool.New(PREFAB_ID.WidgetTargetFocusListCell, 50)
    local script = select(2, self.FocustListCellPool:Allocate(self.ScrollViewPlayList))
    return script
end

function UIWidgetTargetFocusList:ShowPublishTip()
    local tbExtraMenuConfig = {
        { szName = "根据服务器", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.NoticeNearbyCount(4)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end },
        { szName = "根据帮派", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.NoticeNearbyCount(3)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end },
        { szName = "根据门派", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.NoticeNearbyCount(2)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end },
        { szName = "根据阵营", bCloseOnClick = true, OnClick = function()
            _JX_TargetList.NoticeNearbyCount(1)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
        end },
    }

    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipMoreOper, self.TogPublish, TipsLayoutDir.BOTTOM_RIGHT)
    tips:SetOffset(0, 0)
    tips:Update()
    script:OnEnter(tbExtraMenuConfig)
end

function UIWidgetTargetFocusList:UpdateFilterInfo()
    local nFilterData = FilterDef.FocusList.ReadFromStorage()
    if nFilterData then
        JX_TargetList.nListClassifyForce = nFilterData[1][1]
        JX_TargetList.nSortType = nFilterData[2][1] - 1
        self:RefreshGeneralInfo()
        self:InitRefreshList()
    end
end

--------------------------ScrollList相关--------------------------------

function UIWidgetTargetFocusList:InitScrollList()
    self:UnInitScrollList()
    --self:InitLayoutContent(nContentHeight)

    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutScrollList,
        nReboundScale = 1,
        nSpace = 5,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetTargetFocusListCell
        end,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateOneCell(cell, nIndex)
        end,
    })
    --self.tScrollList:SetScrollBarEnabled(true)
end

function UIWidgetTargetFocusList:UpdateInfo_Content()
    local nDataLen = #self.tTargetDataList
    if self.tScrollList then
        if nDataLen == 0 then
            self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
        end
    end
end

function UIWidgetTargetFocusList:UpdateOneCell(cell, nIndex)
    if not cell then
        return
    end
    local tInfo = self.tTargetDataList[nIndex]
    if tInfo then
        cell:UpdateInfo(tInfo, g_pClientPlayer)
    end
end

function UIWidgetTargetFocusList:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIWidgetTargetFocusList:InitBgOpacity()
    self:SaveDefaultBgOpacity()
    local nOpacity = MainCityCustomData.GetHurtBgOpacity() or Storage.MainCityNode.tbDpsBgOpcity.nOpacity
    if nOpacity then
        UIHelper.SetOpacity(self.ImgListBg, nOpacity)
    else
        UIHelper.SetOpacity(self.ImgListBg, Storage.MainCityNode.tbDpsBgOpcity.nDefault)
    end
end

function UIWidgetTargetFocusList:SaveDefaultBgOpacity()
    if not Storage.MainCityNode.tbDpsBgOpcity.nDefault then
        local nOpacity = UIHelper.GetOpacity(self.ImgListBg)
        Storage.MainCityNode.tbDpsBgOpcity.nDefault = nOpacity
    end
end

return UIWidgetTargetFocusList