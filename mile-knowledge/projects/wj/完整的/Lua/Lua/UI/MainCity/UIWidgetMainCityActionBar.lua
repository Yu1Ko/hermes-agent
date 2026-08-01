-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMainCityActionBar
-- Date: 2023-12-06 10:15:27
-- Desc: ?
-- ---------------------------------------------------------------------------------



local FUNCTIONLIST = {
    [ACTION_BAR_STATE.COMMON] = "UpdateSkill",
    [ACTION_BAR_STATE.IDENTITY] = "UpdateSkill",
    [ACTION_BAR_STATE.SWORDSMAN] = "UpdatePartNer",
    [ACTION_BAR_STATE.MARK] = "UpdateMarkInfo",
    [ACTION_BAR_STATE.TREASUREBATTLE] = "UpdateTreasureBattle",
    [ACTION_BAR_STATE.BAIZHAN] = "UpdateBaiZhan",
    [ACTION_BAR_STATE.CUSTOM] = "UpdateCustom",
    [ACTION_BAR_STATE.TOY] = "UpdateToy",
    [ACTION_BAR_STATE.FLYSTAR] = "UpdateFlyStar",
    [ACTION_BAR_STATE.DXTEAMMARK] = "UpdateDXTeamMark",
    [ACTION_BAR_STATE.DXYAOZONGPLANT] = "UpdateDXYaoZongPlant",
    [ACTION_BAR_STATE.ARENATOWER] = "UpdateArenaTower",
}

local tbBarBgList_1 ={
    [ACTION_BAR_STATE.COMMON] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
    [ACTION_BAR_STATE.IDENTITY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg2.png",
    [ACTION_BAR_STATE.SWORDSMAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg4.png",
    [ACTION_BAR_STATE.MARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg3.png",
    [ACTION_BAR_STATE.TREASUREBATTLE] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
    [ACTION_BAR_STATE.BAIZHAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
    [ACTION_BAR_STATE.CUSTOM] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
    [ACTION_BAR_STATE.TOY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
    [ACTION_BAR_STATE.FLYSTAR] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg3.png",
    [ACTION_BAR_STATE.DXTEAMMARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg2.png",
    [ACTION_BAR_STATE.DXYAOZONGPLANT] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg4.png",
    [ACTION_BAR_STATE.ARENATOWER] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1.png",
}

local tbBarBgList_2 ={
    [ACTION_BAR_STATE.COMMON] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
    [ACTION_BAR_STATE.IDENTITY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg2_1.png",
    [ACTION_BAR_STATE.SWORDSMAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg4_1.png",
    [ACTION_BAR_STATE.MARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg3_1.png",
    [ACTION_BAR_STATE.TREASUREBATTLE] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
    [ACTION_BAR_STATE.BAIZHAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
    [ACTION_BAR_STATE.CUSTOM] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
    [ACTION_BAR_STATE.TOY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
    [ACTION_BAR_STATE.FLYSTAR] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg3_1.png",
    [ACTION_BAR_STATE.DXTEAMMARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg2_1.png",
    [ACTION_BAR_STATE.DXYAOZONGPLANT] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg4_1.png",
    [ACTION_BAR_STATE.ARENATOWER] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarBg1_1.png",
}

local tbBarIconBgList = {
    [ACTION_BAR_STATE.COMMON] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
    [ACTION_BAR_STATE.IDENTITY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame2.png",
    [ACTION_BAR_STATE.SWORDSMAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame4.png",
    [ACTION_BAR_STATE.MARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame3.png",
    [ACTION_BAR_STATE.TREASUREBATTLE] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
    [ACTION_BAR_STATE.BAIZHAN] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
    [ACTION_BAR_STATE.CUSTOM] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
    [ACTION_BAR_STATE.TOY] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
    [ACTION_BAR_STATE.FLYSTAR] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame3.png",
    [ACTION_BAR_STATE.DXTEAMMARK] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame2.png",
    [ACTION_BAR_STATE.DXYAOZONGPLANT] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame4.png",
    [ACTION_BAR_STATE.ARENATOWER] = "UIAtlas2_MainCity_MainCitySkill1_ActionBarFrame1.png",
}

local tbBarIconPath = {
    [ACTION_BAR_STATE.FLYSTAR] = PlayerForceID2SchoolImg[FORCE_TYPE.TANG_MEN],
    [ACTION_BAR_STATE.DXYAOZONGPLANT] = PlayerForceID2SchoolImg[FORCE_TYPE.YAO_ZONG],
}

local SWITCH_IMG = "UIAtlas2_Public_PublicButton_PublicButton1_BtnShuaXin.png"
local EXIT_IMG = "UIAtlas2_MainCity_MainCitySkill1_img_skill_Esc.png"

---@class UIWidgetMainCityActionBar
local UIWidgetMainCityActionBar = class("UIWidgetMainCityActionBar")

function UIWidgetMainCityActionBar:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end


function UIWidgetMainCityActionBar:Init()

    if not self.bInitData then
        self.tbStates = {}
        self.cellSkill = self.cellSkill or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellSwordMan = self.cellSwordMan or PrefabPool.New(PREFAB_ID.WidgetActionBarBtnPartner, 10)
        self.cellMark = self.cellMark or PrefabPool.New(PREFAB_ID.WidgetActionBarBtnUsed, 10)
        self.cellTreasureBattle = self.cellTreasureBattle or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellBaiZhan = self.cellBaiZhan or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellCustom = self.cellCustom or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellToy = self.cellToy or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellFlyStar = self.cellFlyStar or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellDXTeamMark = self.cellDXTeamMark or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 10)
        self.cellDXYaoZongPlant = self.cellDXYaoZongPlant or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 2)
        self.cellArenaTower = self.cellArenaTower or PrefabPool.New(PREFAB_ID.WidgetActionBarSkillUsed, 2)

        self.nTimer = Timer.AddFrameCycle(self, 1, function()
            self:UpdateNpcMorphPower()
        end)

        self.scriptTip = UIHelper.AddPrefab(PREFAB_ID.WidgetActionBarTips, self._rootNode)
        self.bInitData = true
        Event.Dispatch(EventType.OnActionBarInit)

        self:UpdateNodeScale()
    end
end

function UIWidgetMainCityActionBar:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.cellSkill then self.cellSkill:Dispose() end
    if self.cellSwordMan then self.cellSwordMan:Dispose() end
    if self.cellMark then self.cellMark:Dispose() end
    if self.cellTreasureBattle then self.cellTreasureBattle:Dispose() end
    if self.cellBaiZhan then self.cellBaiZhan:Dispose() end
    if self.cellCustom then self.cellCustom:Dispose() end
    if self.cellToy then self.cellToy:Dispose() end
    if self.cellFlyStar then self.cellFlyStar:Dispose() end
    if self.cellDXTeamMark then self.cellDXTeamMark:Dispose() end
    if self.cellDXYaoZongPlant then self.cellDXYaoZongPlant:Dispose() end
    if self.cellArenaTower then self.cellArenaTower:Dispose() end

    self.cellSkill = nil
    self.cellSwordMan = nil
    self.cellMark = nil
    self.cellTreasureBattle = nil
    self.cellBaiZhan = nil
    self.cellCustom = nil
    self.cellToy = nil
    self.cellFlyStar = nil
    self.cellDXTeamMark = nil
    self.cellDXYaoZongPlant = nil
    self.cellArenaTower = nil
end

function UIWidgetMainCityActionBar:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function()
        if self:CanUserExitDynamicSkill() then
            QTEMgr.ExitDynamicSkillState()
            return
        end
        local nStateNum = self:GetStateNum()
        if nStateNum > 2 then
            -- TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetActionBarTips, self.BtnSwitch, self.tbStates, self.nBarState, self)
            self:ShowTip()
        else
            local nOtherState = self:GetOtherState()
            self:EnterState(nOtherState)
        end
    end)

    UIHelper.BindUIEvent(self.BtnTurnPage, EventType.OnClick, function()
        self.nCurPage = self.nCurPage == 1 and 2 or 1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnActionBar, EventType.OnClick, function()
        if MainCityCustomData.bSubsidiaryCustomState then
            return
        end
        local bVisible = UIHelper.GetVisible(self.widgetActionBar)
        UIHelper.SetVisible(self.widgetActionBar, not bVisible)
    end)

    UIHelper.BindFreeDrag(self, self.BtnActionBar)

    UIHelper.BindUIEvent(self.BtnClearWorldPins, EventType.OnClick, function()
        if self.nBarState == ACTION_BAR_STATE.DXTEAMMARK then
            TeamData.CancelWorldMarkAll()
        end
    end)
end

function UIWidgetMainCityActionBar:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.UpdateNodeInsideScreen(self._rootNode)
    end)

    Event.Reg(self, EventType.OnSceneTouchBegan, function()
        self:CloseTip()
    end)

    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.SET_MORPH_LIST_SUCCESS
                or nResultCode == NPC_ASSISTED_RESULT_CODE.RESET_MORPH_LIST_SUCCESS
                or nResultCode == NPC_ASSISTED_RESULT_CODE.SET_ASSISTED_LIST_SUCCESS
        then
            if self.nBarState == ACTION_BAR_STATE.SWORDSMAN then
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, EventType.OnActionBarSwitchState, function()
        local nStateNum = self:GetStateNum()
        local nCurStateIndex = 0
        for nIndex, nState in ipairs(self.tbStates) do
            if nState == self.nBarState then
                nCurStateIndex = nIndex
            end
        end
        local nBarState = self.tbStates[nCurStateIndex % nStateNum + 1]
        if nBarState and nBarState ~= self.nBarState then
            self:EnterState(nBarState)
        end
    end)

    --Event.Reg(self, "ON_CHANGE_FONT_SIZE", function (tbSizeType)
	--	UIHelper.SetScale(self._rootNode, tbSizeType["nSkill"], tbSizeType["nSkill"])
    --end)
--
    --Event.Reg(self, "ON_CHANGE_MAINCITYPOSITION", function(nMode)
    --    local tbSizeInfo = Storage.ControlMode.tbMainCityNodeScaleType[nMode]
    --    UIHelper.SetScale(self._rootNode, tbSizeInfo["nSkill"], tbSizeInfo["nSkill"])
    --end)

    Event.Reg(self, EventType.OnSetDragNodeScale, function (tbSizeType)
        if tbSizeType then
            UIHelper.SetScale(self._rootNode, tbSizeType["nActionBar"]  or 1, tbSizeType["nActionBar"] or 1)
        end

    end)

    Event.Reg(self, EventType.OnUpdateDragNodeCustomState, function (bSubsidiaryCustomState)
        if bSubsidiaryCustomState then
            UIHelper.SetVisible(self._rootNode, true)
            self:EnterCustomInfo()
            self:AddCustom()
        else
            self:CheckVis()
            self:ExitCustomInfo()
            self:ExitCustom()
        end
    end)

    Event.Reg(self, EventType.OnSaveDragNodePosition, function ()
        local targetNode = UIHelper.GetParent(self._rootNode)
        local node = self.BtnActionBar
        local size = UIHelper.GetCurResolutionSize()
        if targetNode then
            Storage.MainCityNode.tbMaincityNodePos[targetNode:getName()] =
            {
                nX = UIHelper.GetWorldPositionX(node),
                nY = UIHelper.GetWorldPositionY(node),
                Height = size.height,
                Width = size.width,
            }
        end
        Storage.MainCityNode.Dirty()
    end)

    Event.Reg(self, EventType.OnResetDragNodePosition, function (tbDefaultPositionList, nType)
        if nType ~= DRAGNODE_TYPE.ACTIONBAR then
			return
		end
        local size = UIHelper.GetCurResolutionSize()
        local tbDefaultPosition = tbDefaultPositionList[DRAGNODE_TYPE.ACTIONBAR]
        local nX, nY = table.unpack(tbDefaultPosition)
        local nRadioX, nRadioY = size.width / 1600, size.height / 900
        UIHelper.SetWorldPosition(self._rootNode, nX * nRadioX, nY * nRadioY)
        MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.ACTIONBAR)
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function(dwKungFuID)
        self:UpdateInfo()
    end)
end

function UIWidgetMainCityActionBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMainCityActionBar:ShowTip()
    self.scriptTip:Show(self.tbStates, self.nBarState, self)
    local nX, nY = UIHelper.GetPosition(self.BtnSwitch)
    UIHelper.SetPosition(self.scriptTip._rootNode, nX, nY)
end

function UIWidgetMainCityActionBar:CloseTip()
    self.scriptTip:Close()
end

function UIWidgetMainCityActionBar:UpdateInfo()
    if not self.nBarState then
        return
    end

    local nStateNum = self:GetStateNum()
    UIHelper.SetVisible(self.BtnTurnPage, false)
    UIHelper.SetVisible(self.BtnSwitch, nStateNum >= 2 or self:CanUserExitDynamicSkill())
    UIHelper.SetVisible(self.ImgPatnerSlider, self.nBarState == ACTION_BAR_STATE.SWORDSMAN)
    UIHelper.SetSpriteFrame(self.ImgIconBg, tbBarIconBgList[self.nBarState])
    UIHelper.SetVisible(self.BtnClearWorldPins, self.nBarState == ACTION_BAR_STATE.DXTEAMMARK)

    -- UIHelper.SetSpriteFrame(self.LayoutActionBar1, tbBarBgList_1[self.nBarState])
    UIHelper.SetLayoutBackGroundImage(self.LayoutActionBar1, tbBarBgList_1[self.nBarState])
    UIHelper.SetLocalZOrder(self.BtnTurnPage, 1)
    UIHelper.SetLocalZOrder(self.BtnSwitch, 1)
    UIHelper.SetLocalZOrder(self.BtnClearWorldPins, 1)

    local szIconPath = ACTIONBAR_ICON[self.nBarState] or tbBarIconPath[self.nBarState]
    UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath, true)

    local szImage = self:CanUserExitDynamicSkill() and EXIT_IMG or SWITCH_IMG
    UIHelper.SetSpriteFrame(self.imgSwitch1, szImage)

    if self.nBarState ~= ACTION_BAR_STATE.MARK then
        self.tbMarkList = {}
    end

    local szBarFunction = FUNCTIONLIST[self.nBarState]
    if szBarFunction then
        self[szBarFunction](self)
    end
end

function UIWidgetMainCityActionBar:UpdateBtnSwitchState()
    local nStateNum = self:GetStateNum()
    UIHelper.SetVisible(self.BtnSwitch, nStateNum >= 2 or self:CanUserExitDynamicSkill())
    UIHelper.LayoutDoLayout(self.LayoutActionBar1)

    local nStateNum = self:GetStateNum()
    UIHelper.SetWidth(self.imgBg, nStateNum >= 2 and 540 or 480)
    self:CloseTip()
end

function UIWidgetMainCityActionBar:RemoveAllChildren()
    if self.tbBarList and self.prefabPool then
        self:ClearShortcut()
        for index, node in ipairs(self.tbBarList) do
            self.prefabPool:Recycle(node)
        end
    end
    self.tbBarList = {}
end

function UIWidgetMainCityActionBar:RemoveChildren(node, nIndex)
    if not node then
        return
    end

    if self.tbBarList and self.prefabPool then
        local widgetKeyBoard = UIHelper.FindChildByName(node, "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            script:SetID(-1)
            script:RefreshUI()
        end
        self.prefabPool:Recycle(node)
        table.remove(self.tbBarList, nIndex)
    end
end

function UIWidgetMainCityActionBar:AddChildren(node)
    table.insert(self.tbBarList, node)
end

function UIWidgetMainCityActionBar:InsertChildren(node, nIndex)
    table.insert(self.tbBarList, nIndex, node)
end

function UIWidgetMainCityActionBar:UpdateSkill()


    self:RemoveAllChildren()

    self.prefabPool = self.cellSkill

    local bCommon = self.nBarState == ACTION_BAR_STATE.COMMON

    local nCount = bCommon and QTEMgr.GetDynamicSkillCount() or IdentitySkillData.GetDynamicSkillCount()
    for nIndex = 1, nCount do
        local tbSkillInfo = bCommon and QTEMgr.GetDynamicSkillData(nIndex) or IdentitySkillData.GetDynamicSkillData(nIndex)
        local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
        local node, scriptView = self.cellSkill:Allocate(parent, tbSkillInfo, false, nIndex, bCommon)
        local szName = UIHelper.GetName(node)
        UIHelper.SetName(node, szName .. tostring(nIndex))
        self:AddChildren(node)
        if nIndex >= 10 then
            break
        end
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount)
end


function UIWidgetMainCityActionBar:UpdatePartNer()
    local tMorphIDList = PartnerData.GetMorphList()

    self:RemoveAllChildren()
    self.prefabPool = self.cellSwordMan

    for idx, dwPartnerID in ipairs(tMorphIDList) do
        local node, scriptView = self.cellSwordMan:Allocate(self.LayoutActionBar1, idx, dwPartnerID)
        self:AddChildren(node)
        if idx >= 10 then
            break
        end
    end

    local nCount = #tMorphIDList
    self:UpdateShortcut()
    self:UpdateLayout(nCount)

end

function UIWidgetMainCityActionBar:UpdateNpcMorphPower()
    if self.nBarState ~= ACTION_BAR_STATE.SWORDSMAN then return end
    local nPowerNum = g_pClientPlayer and g_pClientPlayer.GetMorphPower() * 3 or 0
    local fPercent  = nPowerNum / PartnerData.nMaxPowerNum

    UIHelper.SetProgressBarPercent(self.SliderPatner, 100 * fPercent)
end

function UIWidgetMainCityActionBar:UpdateMarkInfo()
    local tbMarkList = TeamMarkData.GetTeamMarkInfo()
    local nCount = #tbMarkList

    --2025.12.23 频繁刷新会导致无法选中，这里若pool类型未变化则仅刷新变化了的节点
    if self.prefabPool ~= self.cellMark then
        self:RemoveAllChildren()
        self.prefabPool = self.cellMark

        for nIndex, tbMarkInfo in ipairs(tbMarkList) do
            local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
            local node, scriptView = self.cellMark:Allocate(parent, nIndex, tbMarkInfo)
            self:AddChildren(node)
            if nIndex >= 10 then
                break
            end
        end
    else
        self.tbMarkList = self.tbMarkList or {}
        --[1, #tbMarkList]
        for nIndex = 1, nCount do
            local tbCurMarkInfo = self.tbMarkList[nIndex]
            local tbNewMarkInfo = tbMarkList[nIndex]
            if not IsTableEqual(tbCurMarkInfo, tbNewMarkInfo) then
                local node = self.tbBarList[nIndex]
                self:RemoveChildren(node, nIndex)
                local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
                local newNode, scriptView = self.cellMark:Allocate(parent, nIndex, tbNewMarkInfo)
                self:InsertChildren(newNode, nIndex)
            end
            if nIndex >= 10 then
                break
            end
        end
        --(#tbMarkList, #self.tbMarkList]
        for nIndex = #self.tbBarList, nCount + 1, -1 do
            local node = self.tbBarList[nIndex]
            self:RemoveChildren(node, nIndex)
        end
    end
    self.tbMarkList = tbMarkList

    self:UpdateShortcut()
    self:UpdateLayout(nCount)
end


function UIWidgetMainCityActionBar:UpdateTreasureBattle()
    local player = GetClientPlayer()
	if not player then
        return
    end

    local tbActionBar = TreasureBattleFieldData.tbActionBarInfo
    local tbTBSkill = TravellingBagData.GetTBSKill()

    local bShowInPage = tbActionBar and tbActionBar.bMobileShowInPage
    UIHelper.SetVisible(self.BtnTurnPage, bShowInPage)

    self:RemoveAllChildren()
    self.prefabPool = self.cellTreasureBattle

    local nCount = 0
    if tbActionBar then
        local tbParams = tbActionBar.tbParams
        if bShowInPage then
            tbParams = {}
            for _, tbList in ipairs(tbActionBar.tbParams[self.nCurPage]) do
                table.insert(tbParams, {tbList})
            end
        end

        for _, tbList in ipairs(tbParams) do
            local tbInfoList = {}
            local bItem = false
            for _, tbParam in ipairs(tbList) do
                local nType, data1, data2, data3 = unpack(tbParam)
                if nType == UI_OBJECT.ITEM_INFO then
                    table.insert(tbInfoList, {dwTabType = data2, dwIndex = data3})
                    bItem = true
                elseif nType == UI_OBJECT.SKILL then
                    local nSkillID = data1
                    local nLevel = math.max(1, player.GetSkillLevel(nSkillID))
                    tbInfoList = {id = nSkillID, level = nLevel}
                    break
                end
            end

            if table.is_empty(tbInfoList) and tbTBSkill and tbTBSkill.id ~= 0 then
                tbInfoList = tbTBSkill
            end

            if not table_is_empty(tbInfoList) then
                nCount = nCount + 1
                local parent = nCount <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
                local node, scriptView = self.cellTreasureBattle:Allocate(parent, tbInfoList, bItem, nCount)
                local szName = UIHelper.GetName(node)
                UIHelper.SetName(node, szName .. tostring(nCount))
                self:AddChildren(node)
                if nCount >= 10 then
                    break
                end
            end
        end
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount, bShowInPage)
end

function UIWidgetMainCityActionBar:UpdateBaiZhan()
    local tbActionBarList = MonsterBookData.GetActiveSkillData()

    self:RemoveAllChildren()
    self.prefabPool = self.cellBaiZhan

    local nCount = #tbActionBarList
    for nIndex, tbSKill in ipairs(tbActionBarList) do
        local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
        local node, scriptView = self.cellBaiZhan:Allocate(parent, tbSKill, false, nIndex)
        local szName = UIHelper.GetName(node)
        UIHelper.SetName(node, szName .. tostring(nIndex))
        self:AddChildren(node)
        if nIndex >= 10 then
            break
        end
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount)

end

function UIWidgetMainCityActionBar:UpdateCustom()
    local player = GetClientPlayer()
	if not player then
        return
    end

    local tbParams = MainCityCustomData.GetCustomActionSkillData()

    self:RemoveAllChildren()
    self.prefabPool = self.cellCustom

    local nCount = 0
    if tbParams then
        for _, tbList in pairs(tbParams) do
            local tbInfoList = {}
            local bItem = false
            local nType, data1, data2, data3 = unpack(tbList)
            table.insert(tbInfoList, {dwTabType = data2, dwIndex = data3})
            bItem = true
            if not table_is_empty(tbInfoList) then
                nCount = nCount + 1
                local parent = nCount <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
                local node, scriptView = self.cellCustom:Allocate(parent, tbInfoList, bItem, nCount)
                scriptView:UnBindUIEvent()
                UIHelper.SetVisible(scriptView.WidgetSkillNormal, true)
                self:AddChildren(node)
                if nCount >= 10 then
                    break
                end
            end
        end
        UIHelper.SetVisible(self.BtnSwitch, false)
    end

    --self:UpdateShortcut()
    self:UpdateLayout(nCount)
end

function UIWidgetMainCityActionBar:UpdateToy()
    local player = GetClientPlayer()
	if not player then
        return
    end

    local tbToyList = ToyBoxData.GetActionToyList()
    self:RemoveAllChildren()
    self.prefabPool = self.cellToy

    local nCount = #tbToyList
    if nCount > 0 then
        for nIndex = 1, nCount do
            local dwID = tbToyList[nIndex]
            local tbToy = Table_GetToyBox(dwID)
            local tbSkillInfo = {id = tbToy.nSkillID, level = tbToy.nSkillLevel}
            local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
            local node, scriptView = self.cellToy:Allocate(parent, tbSkillInfo, false, nIndex, true)
            local szPath = UIHelper.GetIconPathByIconID(tbToy.nIcon)
            if not string.is_nil(szPath) then
                UIHelper.SetTexture(scriptView.scriptSkill.imgSkillIcon, szPath, true)
                Timer.Add(self, 0.01, function ()
                    UIHelper.UpdateMask(scriptView.scriptSkill.MaskSkillIcon)
                end)
            end
            local szName = UIHelper.GetName(node)
            UIHelper.SetName(node, szName .. tostring(nIndex))
            self:AddChildren(node)
            if nIndex >= 10 then
                break
            end
        end

        self:UpdateShortcut()
        self:UpdateLayout(nCount)
    end

end

function UIWidgetMainCityActionBar:UpdateFlyStar()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tbShowList = TangMenHidden.GetFlyStarList()
    if not tbShowList or table.is_empty(tbShowList) then
        return
    end
    self:RemoveAllChildren()
    self.prefabPool = self.cellFlyStar

    local nCount = table.get_len(tbShowList)
    for nIndex = 1, 2 do
        local tShadowInfo = tbShowList[nIndex]
        if tShadowInfo then
            local nSkillID = tShadowInfo.id
            local nBuff = tShadowInfo.buff

            tShadowInfo.bSimpleSkill = true

            local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
            local node, scriptView = self.cellFlyStar:Allocate(parent, tShadowInfo, false, nIndex)

            SpecialDXSkillData.SetSkillBuffTimeEnd(nSkillID, nBuff)

            local szName = UIHelper.GetName(node)
            UIHelper.SetName(node, szName .. tostring(nIndex))
            self:AddChildren(node)

            if nIndex >= 10 then
                break
            end
        end
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount)
end

function UIWidgetMainCityActionBar:UpdateDXTeamMark()
    local player = GetClientPlayer()
    if not player then
        return
    end

    self:RemoveAllChildren()
    self.prefabPool = self.cellDXTeamMark

    local nCount = #TeamData.WORLD_MARK_SKILL
    if nCount <= 0 then
        return
    end
    for nIndex = 1, nCount do
        local parent = nIndex <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
        local node, scriptView = self.cellDXTeamMark:Allocate(parent, nil, false, nIndex, false)
        scriptView:UpdateQuickMark(nIndex)

        local szName = UIHelper.GetName(node)
        UIHelper.SetName(node, szName .. tostring(nIndex))
        self:AddChildren(node)
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount)
end

function UIWidgetMainCityActionBar:UpdateDXYaoZongPlant()
    local player = GetClientPlayer()
	if not player then
        return
    end

    self:RemoveAllChildren()
    self.prefabPool = self.cellDXYaoZongPlant
    local parent = self.LayoutActionBar1
    local nIndex = 1

    local tPlantList = SpecialDXSkillData.tPlantList
    if table.get_len(tPlantList) > 0 then
        for dwTemplateID, tPlant in pairs(tPlantList) do
            local node, scriptView = self.cellDXYaoZongPlant:Allocate(parent, nil, false, nIndex, false)
            scriptView:UpdateDXYaoZongPlant(nIndex)
            local szName = UIHelper.GetName(node)
            UIHelper.SetName(node, szName .. tostring(nIndex))
            self:AddChildren(node)
            nIndex = nIndex + 1
        end

        self:UpdateShortcut()
        self:UpdateLayout(#tPlantList)
    end
end

function UIWidgetMainCityActionBar:UpdateArenaTower()
    local player = GetClientPlayer()
	if not player then
        return
    end

    local tActionBarSkillInfo = ArenaTowerData.GetActionBarSkillInfo()

    UIHelper.SetVisible(self.BtnTurnPage, false)
    self:RemoveAllChildren()
    self.prefabPool = self.cellArenaTower

    local nCount = 0
    if tActionBarSkillInfo then
        for _, tSkillInfo in ipairs(tActionBarSkillInfo) do
            local tInfo = {
                id = tSkillInfo.nSkillID,
                level = tSkillInfo.nSkillLevel,
                bArenaTowerSkill = true,
            }
            nCount = nCount + 1
            local parent = nCount <= 5 and self.LayoutActionBar1 or self.LayoutActionBar2
            local node, scriptView = self.cellArenaTower:Allocate(parent, tInfo, false, nCount)
            local szName = UIHelper.GetName(node)
            UIHelper.SetName(node, szName .. tostring(nCount))
            self:AddChildren(node)
            if nCount >= 10 then
                break
            end
        end
    end

    self:UpdateShortcut()
    self:UpdateLayout(nCount)
end

function UIWidgetMainCityActionBar:UpdateShortcut()
    if not self.tbBarList then
        return
    end

    for nIndex, node in ipairs(self.tbBarList) do
        local widgetKeyBoard = UIHelper.FindChildByName(node, "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            script:SetID(SHORTCUT_KEY_BOARD_TYPE["ActionBar" .. nIndex])
            script:RefreshUI()
        end
    end
end

function UIWidgetMainCityActionBar:ClearShortcut()
    if not self.tbBarList then
        return
    end

    for nIndex, node in ipairs(self.tbBarList) do
        local widgetKeyBoard = UIHelper.FindChildByName(node, "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            script:SetID(-1)
            script:RefreshUI()
        end
    end
end

function UIWidgetMainCityActionBar:UpdateLayout(nCount, bShowInPage)
    local nOpacity = nCount <= 5 and 255 or 0
    UIHelper.SetBackGroundImageOpacity(self.LayoutActionBar1, nOpacity)

    UIHelper.LayoutDoLayout(self.LayoutActionBar1)
    UIHelper.LayoutDoLayout(self.LayoutActionBar2)

    UIHelper.SetSpriteFrame(self.imgBg, tbBarBgList_2[self.nBarState])
    UIHelper.SetVisible(self.imgBg, nCount > 5)

    local nStateNum = self:GetStateNum()
    local nBgWidth = 480
    nBgWidth = nStateNum >= 2 and nBgWidth + 60 or nBgWidth
    nBgWidth = bShowInPage and nBgWidth + 60 or nBgWidth
    UIHelper.SetWidth(self.imgBg, nBgWidth)

    local nScale = self.nBarState == ACTION_BAR_STATE.BAIZHAN and 1.2 or 1
    UIHelper.SetScale(self.LayoutActionBar1, nScale, nScale)
    UIHelper.SetScale(self.LayoutActionBar2, nScale, nScale)
    UIHelper.SetScale(self.imgBg, nScale, nScale)
end

--bCommon:是身份还是通用动态技能
function UIWidgetMainCityActionBar:AddDynamicSkill(bCommon)
    if bCommon then
        self:AddState(ACTION_BAR_STATE.COMMON)
        self:EnterState(ACTION_BAR_STATE.COMMON)
    else
        self:AddState(ACTION_BAR_STATE.IDENTITY)
        self:EnterState(ACTION_BAR_STATE.IDENTITY)
    end
end

function UIWidgetMainCityActionBar:ExitDynamicSkill(bCommon)

    if bCommon then
        self:ExitState(ACTION_BAR_STATE.COMMON)
    else
        self:ExitState(ACTION_BAR_STATE.IDENTITY)
    end
end


function UIWidgetMainCityActionBar:AddPartNer()
    self:AddState(ACTION_BAR_STATE.SWORDSMAN)
    self:EnterState(ACTION_BAR_STATE.SWORDSMAN)
end

function UIWidgetMainCityActionBar:ExitPartNer()
    self:ExitState(ACTION_BAR_STATE.SWORDSMAN)
end

function UIWidgetMainCityActionBar:AddMark(bForceUpdate)
    self:AddState(ACTION_BAR_STATE.MARK)
    if (self.nBarState == ACTION_BAR_STATE.MARK or ( not MonsterBookData.IsInBaiZhanMap() and bForceUpdate)) then
        self:EnterState(ACTION_BAR_STATE.MARK)
    end
end

function UIWidgetMainCityActionBar:ExitMark()
    self:ExitState(ACTION_BAR_STATE.MARK)
end

function UIWidgetMainCityActionBar:AddTreasureBattle(bForceUpdate)
    self:AddState(ACTION_BAR_STATE.TREASUREBATTLE)
    if self.nBarState == ACTION_BAR_STATE.TREASUREBATTLE or bForceUpdate then
        self:EnterState(ACTION_BAR_STATE.TREASUREBATTLE)
    end
end

function UIWidgetMainCityActionBar:ExitTreasureBattle()
    self:ExitState(ACTION_BAR_STATE.TREASUREBATTLE)
end

function UIWidgetMainCityActionBar:AddBaiZhan()
    self:AddState(ACTION_BAR_STATE.BAIZHAN)
    self:EnterState(ACTION_BAR_STATE.BAIZHAN)
end

function UIWidgetMainCityActionBar:ExitBaiZhan()
    self:ExitState(ACTION_BAR_STATE.BAIZHAN)
end

function UIWidgetMainCityActionBar:AddCustom()
    self:AddState(ACTION_BAR_STATE.CUSTOM)
    self:EnterState(ACTION_BAR_STATE.CUSTOM)
end

function UIWidgetMainCityActionBar:ExitCustom()
    self:ExitState(ACTION_BAR_STATE.CUSTOM)
end

function UIWidgetMainCityActionBar:AddToy()
    self:AddState(ACTION_BAR_STATE.TOY)
    self:EnterState(ACTION_BAR_STATE.TOY)
end

function UIWidgetMainCityActionBar:ExitToy()
    self:ExitState(ACTION_BAR_STATE.TOY)
end

function UIWidgetMainCityActionBar:AddTangMenHidden()
    self:AddState(ACTION_BAR_STATE.FLYSTAR)
    self:EnterState(ACTION_BAR_STATE.FLYSTAR)
end

function UIWidgetMainCityActionBar:ExitTangMenHidden()
    self:ExitState(ACTION_BAR_STATE.FLYSTAR)
end

function UIWidgetMainCityActionBar:AddDXTeamMark()
    self:AddState(ACTION_BAR_STATE.DXTEAMMARK)
    self:EnterState(ACTION_BAR_STATE.DXTEAMMARK)
end

function UIWidgetMainCityActionBar:ExitDXTeamMark()
    self:ExitState(ACTION_BAR_STATE.DXTEAMMARK)
end

function UIWidgetMainCityActionBar:AddDXYaoZongPlant()
    self:AddState(ACTION_BAR_STATE.DXYAOZONGPLANT)
    self:EnterState(ACTION_BAR_STATE.DXYAOZONGPLANT)
end

function UIWidgetMainCityActionBar:ExitDXYaoZongPlant()
    self:ExitState(ACTION_BAR_STATE.DXYAOZONGPLANT)
end

function UIWidgetMainCityActionBar:AddArenaTower()
    self:AddState(ACTION_BAR_STATE.ARENATOWER)
    self:EnterState(ACTION_BAR_STATE.ARENATOWER)
end

function UIWidgetMainCityActionBar:ExitArenaTower()
    self:ExitState(ACTION_BAR_STATE.ARENATOWER)
end

function UIWidgetMainCityActionBar:ExitState(nState)
    self:Init()
    local nRusult = self:RemoveState(nState)
    if self.nBarState == nState then
        self:UpdateInfo()
        if self:CheckVis() then
            local nNextState = self:GetLastState()
            self:EnterState(nNextState)
        end
    elseif nRusult then
        self:UpdateBtnSwitchState()
    end

end

function UIWidgetMainCityActionBar:CheckVis()
    local nNextState = self:GetLastState()
    if not nNextState and not MainCityCustomData.bSubsidiaryCustomState then
        UIHelper.SetVisible(self._rootNode, false)
        return false
    end
    return true
end

function UIWidgetMainCityActionBar:AddState(nState)
    self:Init()
    UIHelper.SetVisible(self._rootNode, true)
    if self:IsInState(nState) then return end
    table.insert(self.tbStates, nState)
    self:UpdateBtnSwitchState()
end

function UIWidgetMainCityActionBar:IsInState(nState)
    local bInState = false
    for nIndex, state in ipairs(self.tbStates) do
        if nState == state then
            bInState = true
            break
        end
    end
    return bInState
end

function UIWidgetMainCityActionBar:RemoveState(nState)
    local result = false
    for nIndex, state in ipairs(self.tbStates) do
        if nState == state then
            result = true
            table.remove(self.tbStates, nIndex)
            break
        end
    end
    return result
end

--获取最后加入的状态
function UIWidgetMainCityActionBar:GetLastState()
    local nStateNum = self:GetStateNum()
    if nStateNum >= 1 then
        return self.tbStates[nStateNum]
    end
    return nil
end

function UIWidgetMainCityActionBar:GetOtherState()
    local nStateNum = self:GetStateNum()
    if nStateNum >= 1 then
        for index, nState in ipairs(self.tbStates) do
            if nState ~= self.nBarState then
                return nState
            end
        end
    end
    return nil
end


function UIWidgetMainCityActionBar:GetStateNum()
    return #self.tbStates
end


function UIWidgetMainCityActionBar:EnterState(nState)
    -- if nState == self.nBarState then return end
    self.nCurPage = 1
    self.nBarState = nState
    self:UpdateInfo()
end

function UIWidgetMainCityActionBar:GetCurType()
    return self.nBarState
end

function UIWidgetMainCityActionBar:UpdateNodeScale()
    --local nMode = Storage.ControlMode.nMode
    --if Storage.ControlMode.tbMainCityNodeScaleType[nMode].nSkill > 0 then
    --    UIHelper.SetScale(self._rootNode, Storage.ControlMode.tbMainCityNodeScaleType[nMode].nSkill, Storage.ControlMode.tbMainCityNodeScaleType[nMode].nSkill)
    --end
	
    local tbSizeInfo = MainCityCustomData.GetFontSizeInfo()
    if tbSizeInfo then
        UIHelper.SetScale(self._rootNode, tbSizeInfo["nActionBar"] or 1, tbSizeInfo["nActionBar"] or 1)
    end
end

function UIWidgetMainCityActionBar:EnterCustomInfo()
    local function callback()
		MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.ACTIONBAR)
	end
    UIHelper.BindFreeDrag(self, self.BtnActionBar, 0 ,callback)
    UIHelper.SetVisible(self.ImgSelectZone, true)
end

function UIWidgetMainCityActionBar:ExitCustomInfo()
    UIHelper.SetVisible(self.ImgSelectZone, false)
    UIHelper.BindFreeDrag(self, self.BtnActionBar)
end

function UIWidgetMainCityActionBar:CanUserExitDynamicSkill()
    return self.nBarState == ACTION_BAR_STATE.COMMON and QTEMgr.CanCastSkill() and QTEMgr.CanUserChange()
end

return UIWidgetMainCityActionBar
