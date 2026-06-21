local UIWidgetFusionInsert = class("UIWidgetFusionInsert")

local MAIN_SLOT_NAME_FORMAT = "%s栏"
local MAX_SLOT_NUM = 3       --最大熔嵌孔数量
local MAIN_SLOT_QUALITY_FORMAT = "装备品级≤%d，精炼属性已生效"
local szQuality = "%d品及以下生效"
local szEffectivePostFix = "，已生效"
local szNotEffectivePostFix = "，未生效"

local nMaxWeaponBindNum = 6

local nSlotToPositionDesc = {
    [1] = "熔嵌于栏位一",
    [2] = "熔嵌于栏位二",
    [3] = "熔嵌于栏位三",
    [4] = "熔嵌于栏位四",
    [5] = "熔嵌于装备",
}

local tStoneIcon = {
    [1] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing01.png",
    [2] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing02.png",
    [3] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing03.png",
    [4] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing04.png",
    [5] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing05.png",
    [6] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing06.png",
    [7] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing07.png",
    [8] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing08.png",
}

function SelectColorDiamond(bSelect, nStoneIndex, nWeaponIndex, nEquipIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if bSelect then
        local pWeapon = DataModel.GetEquipItem(nEquipIndex)
        local dwEnchantID = hPlayer.GetColorDiamondSlotInfo(nStoneIndex)

        if (not pWeapon or dwEnchantID <= 0) and nWeaponIndex == 0 then
            --没穿武器或者选择空的熔嵌五彩石格子
            --View.UpdateSelectStone(nStoneIndex, nWeaponIndex)
            --View.DrawColorDiamond(hFrame)
            return
        elseif dwEnchantID <= 0 then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NEED_COLOR_DIAMOND)
            return
        end
    end

    local tInfo = GetBindWeapon(nWeaponIndex, nEquipIndex)
    if tInfo.dwItemIndex == 0 then
        --没有武器
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.WEAPON_NULL)
        return
    elseif IsEmpty(tInfo) then
        --方案满了
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.WEAPON_BIND_FULL)
        return
    end

    local dwItemType = tInfo.dwItemType
    local dwItemIndex = tInfo.dwItemIndex
    local nBindIndex = tInfo.nBindIndex
    local nConfigIndex = bSelect and nStoneIndex or 0
    RemoteCallToServer("OnSetColorDiamondBind", dwItemType, dwItemIndex, nConfigIndex, nBindIndex)
end

function UIWidgetFusionInsert:OnEnter(nEquip, bColor)
    if not self.bInit then
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogWuXing)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogWuCai)
        UIHelper.SetVisible(self.WidgetAnchorRight, false)
        UIHelper.SetVisible(self.WidgetAttriList, false)
        UIHelper.SetVisible(self.WidgetWuCaiEmpty, false)
        UIHelper.SetVisible(self.WidgetHintCangJian, g_pClientPlayer.dwForceID == FORCE_TYPE.CANG_JIAN)
        UIHelper.SetVisible(self.WidgetAnchorTabs, false)

        self:ClearData()

        self.nHeightLarge = UIHelper.GetHeight(self.LargeScrollListParent)
        self.nHeightSmall = UIHelper.GetHeight(self.ScrollViewDetail)
        self.nMaterialType = MaterialType.WuXingStone
        self.LeftBagScript = UIMgr.AddPrefab(PREFAB_ID.WidgetRefineBag, self._rootNode) ---@type UICharacterLeftBag

        self.WuXingSlotScripts = {} ---@type UIWidgetFusionCell[]
        for _, node in ipairs(self.FusionSlots) do
            local compLuaBind = node:getComponent("LuaBind")
            local scriptView = compLuaBind and compLuaBind:getScriptObject()
            table.insert(self.WuXingSlotScripts, scriptView)
        end

        self.WidgetColorAttributeLineScripts = {}
        for _, node in ipairs(self.WidgetColorAttributeLines) do
            table.insert(self.WidgetColorAttributeLineScripts, UIHelper.GetBindScript(node))
        end

        local compLuaBind = self.WidgetWuCaiSlot:getComponent("LuaBind")
        self.WidgetWuCaiSlotScript = compLuaBind and compLuaBind:getScriptObject()

        self.WidgetEquipSlotList = UIMgr.AddPrefab(PREFAB_ID.WidgetEquipSlotList, self.WidgetAnchorEquipBar, true) ---@type UIWidgetEquipBarList
        self.WidgetEquipSlotList:Init(true, function(nEquip, dwTabType, dwIndex)
            self:ClearData()
            self.bHasChosen = true
            self.nEquip = nEquip
            DataModel.SetSelect(nEquip)
            self:UpdateInfo()
        end)

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nColorEquipIndex = EQUIPMENT_INVENTORY.MELEE_WEAPON
        self.nStoneIndex = 1
        self.bHasChosen = false -- 防止在未选中装备栏槽位时来回切换五彩石五行石tab导致显示问题
        self.bFirstEnterColorDiamond = true -- 第一次进入五彩石界面时选中激活的五彩石

        self:ResetState()
        self:UpdateLevelInfo()
        self:UpdateNoEffectiveSlotString()
        self:InitStones()

        if nEquip then
            Timer.AddFrame(self, 1, function()
                if bColor == true then
                    self.nMaterialType = MaterialType.WuCaiStone
                    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.TogWuCai)
                end

                self.bHasChosen = true
                self.nEquip = nEquip
                DataModel.SetSelect(nEquip)
                self.WidgetEquipSlotList:SetSelected(nEquip)
                self:UpdateInfo()
            end)
        end
    end
end

function UIWidgetFusionInsert:OnExit()
    self.bInit = false

    self.LeftBagScript:CloseLeftPanel()
end

function UIWidgetFusionInsert:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnIcon, EventType.OnClick, function()
        local pItem = DataModel.GetEquipItem()
        if self.nEquip and pItem then
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnIcon, TipsLayoutDir.LEFT_CENTER)
            script:HidePreviewBtn(true)
            script:SetForbidShowEquipCompareBtn(true)
            script:OnInit(ItemData.GetItemPos(pItem.dwID))
            script:SetBtnState({ })
            tip:Update()
        end
    end)

    UIHelper.BindUIEvent(self.TogWuXing, EventType.OnSelectChanged, function(toggle, bValue)
        if bValue then
            self.nMaterialType = MaterialType.WuXingStone
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogWuCai, EventType.OnSelectChanged, function(toggle, bValue)
        if bValue then
            self.nMaterialType = MaterialType.WuCaiStone
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnInsert, EventType.OnClick, function()
        self:StartSlotEquipBox()
    end)

    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function()
        local szDesc = "1、藏剑的轻重剑栏位共享五行石熔嵌状态\n2、藏剑的轻重剑共用一套五彩石预设，互不冲突\n3、轻重剑栏位所熔嵌的五行石数量与等级仅计算一次，不叠加计算"
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnHint, TipsLayoutDir.TOP_CENTER, szDesc)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)

    for slotIndex = 1, MAX_SLOT_NUM do
        local script = self.WuXingSlotScripts[slotIndex]
        UIHelper.BindUIEvent(script.BtnEmptyTop, EventType.OnClick, function()
            local fnAction = function(dwIndex)
                self:AddWuXingStoneToSlot(dwIndex, slotIndex)
                --self.LeftBagScript:CloseLeftPanel()
                self:UpdateInfo()
            end
            self.LeftBagScript:OpenLeftPanel(LeftTabType.WuXingStone, fnAction, self.chosenMaterialCountDict)
        end)
    end

    local fnChoseWucai = function()
        local fnAction = function(dwIndex)
            self:AddWuCaiStoneToSlot(dwIndex)
            self.LeftBagScript:CloseLeftPanel()
            self:UpdateInfo()
        end
        self.LeftBagScript:OpenLeftPanel(LeftTabType.WuCaiStone, fnAction, self.chosenMaterialCountDict)
    end
    UIHelper.BindUIEvent(self.WidgetWuCaiSlotScript.BtnEmptyTop, EventType.OnClick, fnChoseWucai)
    UIHelper.BindUIEvent(self.BtnColorReplace, EventType.OnClick, fnChoseWucai)

    UIHelper.BindUIEvent(self.BtnPresetBind, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelWuCaiPresetManage)
    end)

    UIHelper.BindUIEvent(self.BtnRefineStrip, EventType.OnClick, function()
        local script = UIMgr.GetViewScript(VIEW_ID.PanelPowerUp)
        script:OpenStrip(self.nEquip)
    end)

    UIHelper.BindUIEvent(self.BtnGoToColor, EventType.OnClick, function()
        self.nMaterialType = MaterialType.WuCaiStone
        DataModel.SetSelect(EQUIPMENT_INVENTORY.MELEE_WEAPON)
        self.nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.TogWuCai)
        self.WidgetEquipSlotList:SetSelected(self.nEquip)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnHint01, EventType.OnClick, function()
        local szMsg = self.szNoEffectiveSlot
        if szMsg then
            local tips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips,
                    self.BtnHint01, TipsLayoutDir.BOTTOM_RIGHT, szMsg)
            tips:SetOffset(-15, -10)
            tips:Update()
        end
    end)
end

function UIWidgetFusionInsert:RegEvent()
    Event.Reg(self, "MOUNT_DIAMON", function(arg0)
        local nResult = arg0
        if nResult == DIAMOND_RESULT_CODE.SUCCESS then
            UIHelper.SetVisible(self.WidgetSuccess, true)
            Timer.Add(self, 2, function()
                UIHelper.SetVisible(self.WidgetSuccess, false)
            end)
            self:PlayAnim("AniFusion")
            --OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tActivation.SUCCESS)
        elseif nResult == DIAMOND_RESULT_CODE.CAN_NOT_OPERATE_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tActivation.CAN_NOT_OPERATE_IN_FIGHT)
        elseif nResult == DIAMOND_RESULT_CODE.NEED_EQUIP_BIND then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tActivation.NEED_EQUIP_BIND)
        elseif nResult == DIAMOND_RESULT_CODE.SCENE_FORBID then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFECommon.SCENE_FORBID)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tActivation.FAILED)
        end

        self:ClearData()
        self:UpdateInfo()
    end)

    Event.Reg(self, "MOUNT_COLOR_DIAMON", function(arg0)
        local nResult = arg0
        if nResult == DIAMOND_RESULT_CODE.SUCCESS then
            UIHelper.SetVisible(self.WidgetSuccess, true)
            Timer.Add(self, 2, function()
                UIHelper.SetVisible(self.WidgetSuccess, false)
            end)
            self:PlayAnim("AniFusion")
            --OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tActivation.SUCCESS)
        elseif nResult == DIAMOND_RESULT_CODE.CAN_NOT_OPERATE_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.CAN_NOT_OPERATE_COLOR_IN_FIGHT)
        elseif nResult == DIAMOND_RESULT_CODE.SCENE_FORBID then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tFECommon.SCENE_COLOR_FORBID)
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.FAILED)
        end

        self:UpdateInfo()
    end)

    Event.Reg(self, "WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        local nResult = arg0
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            DataModel.UpdateBindWeaponInfo()
            self:UpdateInfo()
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tActivation.WEAPON_BIND_SUCCESS)
        elseif nResult == DIAMOND_RESULT_CODE.CAN_NOT_OPERATE_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.CAN_NOT_BIND_WEAPON_IN_FIGHT)
        elseif nResult == DIAMOND_RESULT_CODE.SCENE_FORBID then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tFECommon.SCENE_COLOR_FORBID)
        elseif nResult == DIAMOND_RESULT_CODE.WEAPON_ALREADY_BIND_COLOR_DIAMOND_SLOT then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.WEAPON_ALREADY_BIND)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.TOO_OFFTEN then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.TOO_OFFTEN)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.NULL_CONFIG_INDEX then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NO_SELECT_BOX)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.NULL_EQUIP_INDEX then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NULL_EQUIP)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.QUALITY_TOO_HIGH then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.QUALITY_TOO_HIGH)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.NULL_COLOR_DIAMOND then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NEED_COLOR_DIAMOND)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.BIND_PLAN_FULL then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.WEAPON_BIND_FULL)
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.WEAPON_BIND_FAILED)
        end
    end)

    Event.Reg(self, "DELETE_WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            DataModel.UpdateBindWeaponInfo()
            self:UpdateInfo()
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.tActivation.DELETE_WEAPON_BIND_SUCCESS)
        elseif nResult == DIAMOND_RESULT_CODE.CAN_NOT_OPERATE_IN_FIGHT then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.CAN_NOT_BIND_WEAPON_IN_FIGHT)
        elseif nResult == DIAMOND_RESULT_CODE.SCENE_FORBID then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tFECommon.SCENE_COLOR_FORBID)
        elseif nResult == DIAMOND_EXTEND_RESULT_CODE.NULL_EQUIP_INDEX then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NULL_EQUIP)
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.DELETE_WEAPON_BIND_FAILED)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 3, function()
            self:CalculateColorScrollView()
        end)
    end)
end

function UIWidgetFusionInsert:ResetState()
    if self.nEquip then
        DataModel.SetSelect(self.nEquip)
    end
    DataModel.UpdateEquipList(true)
end

function UIWidgetFusionInsert:UpdateInfo()
    local nType = self:GetMaterialType()
    UIHelper.SetVisible(self.WidgetWuXingShiBar, self.bHasChosen and nType == MaterialType.WuXingStone)
    UIHelper.SetVisible(self.WidgetWuXingShi, nType == MaterialType.WuXingStone)
    UIHelper.SetVisible(self.WidgetWuCaiShi, nType ~= MaterialType.WuXingStone)
    UIHelper.SetVisible(self.WidgetWuCaiShiBar, nType ~= MaterialType.WuXingStone)
    UIHelper.SetVisible(self.WidgetHint, false)
    UIHelper.SetVisible(self.WidgetHintMessage, false)

    self:UpdateEquipSlotInfo(nType)
    self:UpdateLevelInfo()
    self:UpdateNoEffectiveSlotString()

    local nDiamondCount, nDiamondIntensity = GetAllEquipDiamondInfo()
    UIHelper.SetString(self.LabelCount, nDiamondCount)
    UIHelper.SetString(self.LabelLevel, nDiamondIntensity)

    if nType == MaterialType.WuXingStone then
        self:UpdateDiamond()
        UIHelper.SetButtonState(self.BtnInsert, self:CheckWuXingStoneValidity() and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetVisible(self.WidgetActivated, false)
        UIHelper.SetVisible(self.BtnInsert, true)
        UIHelper.SetString(self.LabelInsert, "熔嵌")

        if self.bHasChosen then
            local nEquip = DataModel.GetSelect(1)
            local bIsWeaponSlot = nEquip == EQUIPMENT_INVENTORY.MELEE_WEAPON or nEquip == EQUIPMENT_INVENTORY.BIG_SWORD
            local bHasColorDiamond = self:UpdateColorAttribute()
            UIHelper.SetVisible(self.WidgetWuCaiEmpty, not bIsWeaponSlot and not bHasColorDiamond)
            UIHelper.SetVisible(self.WidgetAnchorTabs, bIsWeaponSlot)
        end
    elseif nType == MaterialType.WuCaiStone then
        if g_pClientPlayer.dwForceID == FORCE_TYPE.CANG_JIAN then
            UIHelper.SetVisible(self.WidgetHintMessage, true)
            UIHelper.SetString(self.LabelHintMessage, string.format("当前正在使用%s，仅显示其激活状态", g_pClientPlayer.bBigSwordSelected and "重剑" or "轻剑"))
        end

        UIHelper.SetVisible(self.WidgetAnchorTabs, true)

        self:UpdateColorAttribute()
        self:RefreshWeaponBindInfo()

        if self.bFirstEnterColorDiamond then
            self.bFirstEnterColorDiamond = false
            self:SetToggleToActiveStone()
        end

        local bSelectCurrentStone = self.nCurrentWeaponActiveSlot == self.nStoneIndex
        local bShowActivated = not self.bIsColorFusion and bSelectCurrentStone

        self:UpdateColorStones()
        local bSlotQualityTooLow = self:UpdateColorDiamondInfo()

        UIHelper.SetVisible(self.WidgetWuCaiEmpty, false)
        UIHelper.SetVisible(self.WidgetActivated, not bSlotQualityTooLow and bShowActivated)
        UIHelper.SetVisible(self.BtnInsert, self.bIsColorFusion or (not bSelectCurrentStone and not bSlotQualityTooLow))
        UIHelper.SetVisible(self.WidgetHint, not self.bIsColorFusion and bSlotQualityTooLow)

        UIHelper.SetString(self.LabelInsert, (self.bIsColorFusion and self.nStoneIndex ~= 5) and "熔嵌" or "激活")
        UIHelper.SetButtonState(self.BtnInsert, self:CheckWuCaiStoneValidity() and BTN_STATE.Normal or BTN_STATE.Disable)

        self:CalculateColorScrollView()
    end
end

function UIWidgetFusionInsert:UpdateEquipSlotInfo(nType)
    UIHelper.SetVisible(self.ImgMaxFrame, false)

    local bShowRight = false
    if nType == MaterialType.WuXingStone then
        if self.bHasChosen then
            bShowRight = true
            UIHelper.SetVisible(self.WidgetNoEquip, false)
            UIHelper.SetVisible(self.WidgetRefineClassNormal, false)
            UIHelper.SetVisible(self.WidgetRefineClassTooHigh, false)

            local nEquip, szName = DataModel.GetSelect(1), DataModel.GetSelect(2)
            local tEquipBoxInfo = DataModel.GetRefineBoxInfo(nEquip)
            local nBoxQuality = tEquipBoxInfo.nQuality
            local nBoxMaxQuality = tEquipBoxInfo.nMaxQuality
            local bNeedUnstrength = nBoxQuality < nBoxMaxQuality and nBoxQuality > 0

            local pItem = DataModel.GetEquipItem(nEquip)
            UIHelper.SetString(self.LabelBarName, string.format(MAIN_SLOT_NAME_FORMAT, szName))
            UIHelper.SetSpriteFrame(self.ImgBar, EquipToDefaultIcon[nEquip])
            UIHelper.SetVisible(self.ImgMaxFrame, tEquipBoxInfo.nLevel >= MAX_FRAME_VISIBLE_LEVEL)

            for i = 1, MAX_SLOT_NUM, 1 do
                local tInfo = DataModel.GetSlotBoxInfo(self.nEquip, i - 1)
                local nSlotLevel = 0
                local nQuality = tInfo.nQuality
                local nMaxQuality = tInfo.nMaxQuality
                local bShow = tInfo and tInfo.bCanMount

                local szFramePath = nil
                UIHelper.SetVisible(self.WidgetWuXings[i], bShow)
                if bShow then
                    if tInfo.dwEnchantID ~= 0 then
                        local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tInfo.dwEnchantID)
                        if dwTabType and dwTabIndex then
                            local pItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
                            nSlotLevel = pItemInfo.nDetail

                            szFramePath = tStoneIcon[nSlotLevel]
                        end
                    end
                end
                UIHelper.SetVisible(self.WuXingIcons[i], szFramePath ~= nil)
                UIHelper.SetSpriteFrame(self.WuXingIcons[i], szFramePath)
            end

            UIHelper.LayoutDoLayout(self.LayoutInlayHat)

            if pItem then
                local nTempBoxQuality = nBoxQuality == 0 and nBoxMaxQuality or nBoxQuality -- 槽位品质为0时视为最高品质状态
                if pItem.nLevel <= nTempBoxQuality then
                    UIHelper.SetVisible(self.WidgetRefineClassNormal, true)
                    UIHelper.SetString(self.LabelRefineClassNormal1, string.format(MAIN_SLOT_LEVEL_FORMAT, pItem.nLevel))
                    UIHelper.SetString(self.LabelRefineClassNormal2, string.format(MAIN_SLOT_QUALITY_FORMAT, nTempBoxQuality))
                else
                    UIHelper.SetVisible(self.WidgetRefineClassTooHigh, true)
                    UIHelper.SetString(self.LabelRefineClassTooHigh1, string.format(MAIN_SLOT_LEVEL_FORMAT, pItem.nLevel))
                    UIHelper.SetString(self.LabelRefineClassTooHigh2, string.format(MAIN_SLOT_QUALITY_INVALID_FORMAT, nTempBoxQuality))
                end
            else
                UIHelper.SetVisible(self.WidgetNoEquip, true)
            end
        end
    elseif nType == MaterialType.WuCaiStone then
        bShowRight = true
    end

    if UIHelper.GetVisible(self.WidgetAnchorRight) ~= bShowRight then
        UIHelper.SetVisible(self.WidgetAnchorRight, bShowRight)
        self:PlayAnim(bShowRight and "AniToLeft" or "AniToRight")
    end
end

function UIWidgetFusionInsert:UpdateDiamond()
    local nEquip = DataModel.GetSelect(1)
    local bHasCantMount = false
    local bQualityLowerThanEquip = false

    for slotIndex = 1, MAX_SLOT_NUM do
        local cpp_SlotIndex = slotIndex - 1
        local tInfo = DataModel.GetSlotBoxInfo(nEquip, cpp_SlotIndex)
        local bCanMount = tInfo.bCanMount
        UIHelper.SetActiveAndCache(self, UIHelper.GetParent(self.WuXingSlotScripts[slotIndex]._rootNode), bCanMount)

        if bCanMount then
            bHasCantMount = true

            self.WuXingSlotScripts[slotIndex]:RefreshWuXing(nEquip, cpp_SlotIndex, self.slotToChosenMaterialDict[slotIndex])
            self.WuXingSlotScripts[slotIndex]:BindCancelFunc(function()
                local dwIndex = self.slotToChosenMaterialDict[slotIndex].dwIndex
                self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] - 1
                self.slotToChosenMaterialDict[slotIndex] = nil
                Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, -1)
                self:UpdateDiamond()
            end)

            local pItem = DataModel.GetEquipItem(nEquip)
            if pItem and tInfo.nQuality ~= 0 and tInfo.nQuality < pItem.nLevel then
                bQualityLowerThanEquip = true -- 未熔嵌孔的Quality默认为0，忽略
            end
        end
    end

    UIHelper.SetVisible(self.WidgetLimit, not bHasCantMount)
    UIHelper.LayoutDoLayout(self.LayoutWuXingShiGoods)
    UIHelper.SetVisible(self.WidgetHint, bQualityLowerThanEquip)
end

function UIWidgetFusionInsert:UpdateColorDiamondInfo()
    local szContent = " "
    local nCurLevel = 0
    local nEquipIndex = self.nColorEquipIndex
    local bDiamondOnEquip = false
    local bInsertState = self.chosenWuCaiStone ~= nil
    local pItemWeapon = DataModel.GetEquipItem(nEquipIndex)

    local dwSelectedEnchantID = 0 -- 尝试查看是否绑定了五行石方案
    if self.nStoneIndex >= 1 and self.nStoneIndex <= MAX_COLOR_DIAMOND_NUM then
        dwSelectedEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(self.nStoneIndex)
    end

    if self.nStoneIndex == 5 and self.nWeaponMountedEnchantID > 0 then
        dwSelectedEnchantID = self.nWeaponMountedEnchantID
        bDiamondOnEquip = true
    end

    -- 在选中槽位为5时忽略熔嵌行为
    local newDiamond = self.nStoneIndex ~= 5 and self.chosenWuCaiStone or nil
    self.WidgetWuCaiSlotScript:RefreshWuCai(dwSelectedEnchantID, newDiamond)
    self.WidgetWuCaiSlotScript:BindCancelFunc(function()
        if self.chosenWuCaiStone then
            local dwIndex = self.chosenWuCaiStone.dwIndex
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] - 1
            Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, -1)
            self.chosenWuCaiStone = nil
            self:UpdateInfo()
        end
    end)

    local nEnchantID = dwSelectedEnchantID
    local dwTabType, dwIndex

    if bInsertState then
        dwTabType = self.chosenWuCaiStone.dwTabType
        dwIndex = self.chosenWuCaiStone.dwIndex

        local pItemInfo = dwTabType and dwIndex and GetItemInfo(dwTabType, dwIndex) or nil
        if pItemInfo then
            nEnchantID = pItemInfo.dwEnchantID
        end
    end

    szContent = GetColorDiamondInfo(nEnchantID)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function()
        local szName = UIHelper.GBKToUTF8(self.KItemWeapon.szName)
        local strMessage = string.format("该五彩石根据以往资料片的规则，已熔嵌在【%s】上，当前不再支持替换该五彩石。", szName)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnTips, TipsLayoutDir.BOTTOM_LEFT, strMessage)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetOffset(-10, -10)
        tips:SetSize(x, y)
        tips:Update()
    end)
    UIHelper.SetVisible(self.BtnTips, self.nStoneIndex == 5)
    UIHelper.SetVisible(self.BtnColorReplace, nEnchantID > 0 and not bInsertState)
    UIHelper.SetVisible(self.LabelPosition, nEnchantID > 0)
    UIHelper.SetVisible(self.LabelEffective, nCurLevel > 0 and not bInsertState)

    local szEffectiveString = string.format(szQuality, nCurLevel)
    if pItemWeapon then
        local bEffective = nCurLevel >= pItemWeapon.nLevel
        szEffectiveString = szEffectiveString .. (bEffective and szEffectivePostFix or szNotEffectivePostFix)
        szEffectiveString = UIHelper.AttachTextColor(szEffectiveString, bEffective and FontColorID.ImportantGreen
                or FontColorID.ImportantRed)
    end

    UIHelper.SetRichText(self.RichTextDetail, szContent)
    UIHelper.SetRichText(self.LabelEffective, szEffectiveString)
    UIHelper.SetString(self.LabelPosition, nSlotToPositionDesc[self.nStoneIndex])
    UIHelper.SetVisible(self.ImgRedDot, DataModel.GetBindWeaponCount() == nMaxWeaponBindNum)
    UIHelper.LayoutDoLayout(self.LayoutTop, nSlotToPositionDesc[self.nStoneIndex])

    if nEnchantID > 0 and nCurLevel > 0 and not bInsertState then
        if pItemWeapon and pItemWeapon.nLevel > nCurLevel then
            --UIHelper.SetVisible(self.WidgetHintMessage, true)
            --UIHelper.SetString(self.LabelHintMessage, FormatString(g_tStrings.tActivation.STR_SLOT_QUALITY_LEVEL, nCurLevel))
            return true
        end
    end
end

function UIWidgetFusionInsert:RefreshWeaponBindInfo()
    self.nCurrentWeaponActiveSlot = 0
    self.nCurrentWeaponIndex = 0
    self.bIsColorFusion = self.chosenWuCaiStone ~= nil

    local KItemWeapon = DataModel.GetEquipItem(self.nColorEquipIndex)
    if KItemWeapon then
        for k, v in pairs(DataModel.tBindWeaponInfo) do
            if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
                self.nCurrentWeaponActiveSlot = v[3]
                self.nCurrentWeaponIndex = k
                break
            end
        end
    end

    self.KItemWeapon = KItemWeapon
    self.nWeaponMountedEnchantID = KItemWeapon and KItemWeapon.GetMountFEAEnchantID() or 0
end

function UIWidgetFusionInsert:UpdateLevelInfo()
    local nDiamondCount, nDiamondIntensity = GetAllEquipDiamondInfo()
    UIHelper.SetString(self.LabelCount, nDiamondCount)
    UIHelper.SetString(self.LabelLevel, nDiamondIntensity)
end

function UIWidgetFusionInsert:ChoseStoneIndex(nIndex)
    self:ClearData()
    self.nStoneIndex = nIndex
    if self.nStoneIndex >= 1 and self.nStoneIndex <= MAX_COLOR_DIAMOND_NUM then
        local dwSelectedEnchantID, _ = g_pClientPlayer.GetColorDiamondSlotInfo(self.nStoneIndex)
        if dwSelectedEnchantID == 0 then
            TipsHelper.ShowImportantBlueTip("请先在该孔位上置入五彩石")
        end
    end
    self:UpdateInfo()
end

function UIWidgetFusionInsert:ShowItemTip(pItem)
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetItemWeapon01, TipsLayoutDir.LEFT_CENTER)
    scriptItemTip:OnInit(ItemData.GetItemPos(pItem.dwID))
    scriptItemTip:SetBtnState({ })
    tip:SetOffset(0, 0)
    tip:Update()
end

function UIWidgetFusionInsert:SetToggleToActiveStone()
    self:RefreshWeaponBindInfo()

    if self.nCurrentWeaponActiveSlot > 0 then
        self.nStoneIndex = self.nCurrentWeaponActiveSlot
    elseif self.nWeaponMountedEnchantID > 0 then
        self.nStoneIndex = 5
    else
        self.nStoneIndex = 1
    end

    UIHelper.SetToggleGroupSelected(self.ToggleGroupStone, self.nStoneIndex - 1)
    UIHelper.SetVisible(self.tStoneScripts[self.nStoneIndex].ImgUpArrow, true) -- 右侧选中箭头
end

function UIWidgetFusionInsert:UpdateColorAttribute()
    if not self.bHasChosen then
        return
    end

    local KItemWeapon = DataModel.GetEquipItem(EQUIPMENT_INVENTORY.MELEE_WEAPON)
    local nCurrentWeaponActiveSlot
    if KItemWeapon then
        for k, v in pairs(DataModel.tBindWeaponInfo) do
            if v[1] == KItemWeapon.dwTabType and v[2] == KItemWeapon.dwIndex then
                nCurrentWeaponActiveSlot = v[3]
                break
            end
        end
    end

    local nBindEnchantID = 0
    if nCurrentWeaponActiveSlot and nCurrentWeaponActiveSlot > 0 then
        local dwSelectedEnchantID, _ = g_pClientPlayer.GetColorDiamondSlotInfo(nCurrentWeaponActiveSlot)
        nBindEnchantID = dwSelectedEnchantID
    end

    local szGreen, szGray, szRed = FontColorID.ImportantGreen, FontColorID.Text_Level2, UI_FAILED_COLOR
    local nFinalEnchantID = nBindEnchantID > 0 and nBindEnchantID or (KItemWeapon and KItemWeapon.GetMountFEAEnchantID() or 0)
    if nFinalEnchantID > 0 then
        local tDiamondInfoList = GetColorDiamondInfoTable(nFinalEnchantID)
        for _, script in ipairs(self.WidgetColorAttributeLineScripts) do
            local tDiamondInfo = tDiamondInfoList[_]
            if tDiamondInfo then
                local bActivated = tDiamondInfo.bActivated
                UIHelper.SetRichText(script.LabelAttriName, UIHelper.AttachTextColor(tDiamondInfo.szAttributeName, bActivated and szGreen or szGray))
                UIHelper.SetVisible(script.WidgetActivated, bActivated)
                UIHelper.SetVisible(script.WidgetNotActivated, not bActivated)

                if not tDiamondInfo.bActivated then
                    local nDiamondCount, nDiamondIntensity = GetAllEquipDiamondInfo()
                    UIHelper.SetRichText(script.LabelWuxingNum, UIHelper.AttachTextColor(tDiamondInfo.nDiamondCount
                    , nDiamondCount >= tDiamondInfo.nDiamondCount and szGreen or szRed))
                    UIHelper.SetRichText(script.LabelWuxingLv, UIHelper.AttachTextColor(tDiamondInfo.nDiamondIntensity,
                            nDiamondIntensity >= tDiamondInfo.nDiamondIntensity and szGreen or szRed))
                end
            end
            UIHelper.SetVisible(script._rootNode, tDiamondInfo ~= nil)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAttriList, true)
    UIHelper.SetVisible(self.WidgetAttriList, nFinalEnchantID > 0)
    return nFinalEnchantID > 0
end

-----------------------五行石相关-------------------------------

function UIWidgetFusionInsert:AddWuXingStoneToSlot(dwIndex, nSlotIndex)
    local itemCount = DataModel.GetItemCount(dwIndex)
    if itemCount and itemCount > 0 then
        local KItem = DataModel.GetFirstAvailableItemInList(dwIndex, self.chosenMaterialCountDict)
        local nEquip = DataModel.GetSelect(1)
        local cpp_slotIndex = nSlotIndex - 1
        if KItem then
            -- 边界处理
            if KItem.nGenre ~= ITEM_GENRE.COLOR_DIAMOND
                    and KItem.nGenre ~= ITEM_GENRE.DIAMOND then
                return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_ONLY_DIAMOND_OR_COLOR_DIAMOND) and false
            end

            local lastChosenItemInfo = self.slotToChosenMaterialDict[nSlotIndex]
            if lastChosenItemInfo ~= nil then
                Event.Dispatch(EventType.EquipRefineSelectChanged, lastChosenItemInfo.dwIndex, -1)
                self.chosenMaterialCountDict[lastChosenItemInfo.dwIndex] = nil
                self.slotToChosenMaterialDict[nSlotIndex] = nil
            end

            local newItemInfo = ItemData.GetItemInfo(KItem.dwTabType, KItem.dwIndex)
            local tInfo = DataModel.GetSlotBoxInfo(nEquip, cpp_slotIndex)
            if tInfo.dwEnchantID > 0 then
                local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tInfo.dwEnchantID)
                if dwTabType and dwTabIndex then
                    local oldItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
                    local bIsMax = tInfo.nQuality >= tInfo.nMaxQuality
                    if oldItemInfo.nDetail >= newItemInfo.nDetail and bIsMax then
                        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_FUSION_LEVEL_LOW) and false
                    end
                end
            end

            ------ 开始添加
            local nStackNum = 1
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] or 0
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] + nStackNum

            local nBox, nIndex = ItemData.GetItemPos(KItem.dwID)

            self.slotToChosenMaterialDict[nSlotIndex] = {
                dwBox = nBox,
                dwX = nIndex,
                nUiId = KItem.nUiId,
                nGenre = KItem.nGenre,
                dwTabType = KItem.dwTabType,
                dwIndex = KItem.dwIndex,
                nStackNum = nStackNum,
                nQuality = KItem.nQuality,
                nDetail = newItemInfo.nDetail,
                bBind = KItem.bBind,
                szName = KItem.szName,
                nIcon = Table_GetItemIconID(KItem.nUiId),
            }
            --LOG.TABLE(self.slotToChosenMaterialDict[nSlotIndex])
            Event.Dispatch(EventType.EquipRefineSelectChanged, dwIndex, 1)
            return true
        else
            return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_AMOUNT_REACH_UBOUND) and false
        end
    end
end

function UIWidgetFusionInsert:CheckWuXingStoneValidity()
    local newFusionCount = 0
    local nEquip = DataModel.GetSelect(1)
    for slotIndex = 1, MAX_SLOT_NUM, 1 do
        local cppSlotIndex = slotIndex - 1
        local newItemInfo = self.slotToChosenMaterialDict[slotIndex]
        local tInfo = DataModel.GetSlotBoxInfo(nEquip, cppSlotIndex)
        if newItemInfo then
            if tInfo.dwEnchantID > 0 then
                local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tInfo.dwEnchantID)
                if dwTabType and dwTabIndex then
                    local oldItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
                    local bIsMax = tInfo.nQuality >= tInfo.nMaxQuality
                    if oldItemInfo.nDetail >= newItemInfo.nDetail and bIsMax then
                        self:ClearData()
                        self:UpdateInfo()
                        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_FUSION_LEVEL_LOW) and false
                    end
                end
            end
            newFusionCount = newFusionCount + 1
        end
    end
    return newFusionCount > 0
end

---装备栏融嵌 - 五行石
function UIWidgetFusionInsert:FusionInlayWuXingStone()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end

    local nEquipInv = DataModel.GetSelect(1)
    if nEquipInv == EQUIPMENT_INVENTORY.BIG_SWORD then
        nEquipInv = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    ---检查是否合法
    if self:CheckWuXingStoneValidity() then
        local fnAction = function()
            for slotIndex = 1, MAX_SLOT_NUM, 1 do
                local cppSlotIndex = slotIndex - 1
                local tbItemInfo = self.slotToChosenMaterialDict[slotIndex]
                if tbItemInfo ~= nil then
                    --LOG.TABLE(tbItemInfo)
                    RemoteCallToServer("OnMountDiamondBox", tbItemInfo.dwBox, tbItemInfo.dwX, nEquipInv, cppSlotIndex)
                end
            end
        end

        UIHelper.ShowConfirm(GetFormatText(g_tStrings.tActivation.MESSAGE), fnAction, nil, true)
    end
end

-----------------------五彩石头相关-------------------------------

function UIWidgetFusionInsert:CalculateColorScrollView()
    local bShowBottom = UIHelper.GetVisible(self.WidgetHintMessage)
    if not bShowBottom then
        UIHelper.SetHeight(self.ScrollViewDetail, self.nHeightLarge)
    else
        UIHelper.SetHeight(self.ScrollViewDetail, self.nHeightSmall)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetail)
end

function UIWidgetFusionInsert:UpdateColorStones()
    local bHasActivated = self.nCurrentWeaponActiveSlot > 0
    for nStoneIndex = 1, MAX_COLOR_DIAMOND_NUM do
        local script = self.tStoneScripts[nStoneIndex] ---@type UIWidgetWuCaiPresetCell LayoutDetail中可选择的五彩石预制
        local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(nStoneIndex)
        if dwEnchantID > 0 then
            local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(dwEnchantID)
            if dwTabType and dwTabIndex then
                script:OnInit(dwTabType, dwTabIndex)
            end
        else
            script:OnInit()
        end

        script:SetActive(self.nCurrentWeaponActiveSlot == nStoneIndex)
    end

    local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(self.nWeaponMountedEnchantID)
    self.tStoneScripts[5]:OnInitCancelBtn(dwTabType, dwIndex)
    self.tStoneScripts[5]:SetActive(not bHasActivated)

    -- 当武器上没有旧版五彩石时会根据激活状态切换取消激活按钮的显示或隐藏状态
    if self.nWeaponMountedEnchantID == 0 then
        UIHelper.SetVisible(self.LayoutOldPreset, bHasActivated)
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutWuCaiPresetSlot, true, false)
end

function UIWidgetFusionInsert:InitStones()
    self.tStoneScripts = {} ---@type UIWidgetWuCaiPresetCell[]

    -- 初始化五彩石槽位
    for nIndex = 1, MAX_COLOR_DIAMOND_NUM do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPreset, self.LayoutCurrentPresets, true) ---@type UIWidgetWuCaiPresetCell
        table.insert(self.tStoneScripts, script)

        script:AddToggleGroup(self.ToggleGroupStone)
        script:BindClickFunc(function()
            self:ChoseStoneIndex(nIndex)
        end)
    end

    -- 初始化清空五彩石按钮
    local deleteAllScript = UIHelper.AddPrefab(PREFAB_ID.WidgetWuCaiPreset, self.LayoutOldPreset, true)---@type UIWidgetWuCaiPresetCell
    deleteAllScript:AddToggleGroup(self.ToggleGroupStone)
    deleteAllScript:BindDeactivateFunc(function()
        if self.nCurrentWeaponIndex > 0 then
            SelectColorDiamond(false, 0, self.nCurrentWeaponIndex, self.nColorEquipIndex)
        end
    end)
    deleteAllScript:BindClickFunc(function()
        self:ChoseStoneIndex(5)
    end)
    table.insert(self.tStoneScripts, deleteAllScript)

    -- 初始化轻剑&重剑栏位
    local tbEquipEnumList = { EQUIPMENT_INVENTORY.MELEE_WEAPON, EQUIPMENT_INVENTORY.BIG_SWORD }
    local tbNodes = { {
                          itemParent = self.WidgetItemWeapon01,
                          tog = self.WidgetWeaponTog01,
                          name1 = self.LabelWeaponInBarType01,
                          name2 = self.LabelWeaponInBarType01Normal
                      },
                      {
                          itemParent = self.WidgetItemWeapon02,
                          tog = self.WidgetWeaponTog02,
                          name1 = self.LabelWeaponInBarType02,
                          name2 = self.LabelWeaponInBarType02Normal
                      } }
    for _, nEnum in ipairs(tbEquipEnumList) do
        local KItemWeapon = DataModel.GetEquipItem(nEnum)
        local nodes = tbNodes[_]
        local szMeleeName = "暂无武器"
        if KItemWeapon then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, nodes.itemParent)
            script:OnInitWithTabID(KItemWeapon.dwTabType, KItemWeapon.dwIndex)
            script:SetClickNotSelected(true)
            script:SetClickCallback(function()
                if self.nColorEquipIndex ~= nEnum then
                    self.nColorEquipIndex = nEnum
                    self:SetToggleToActiveStone()
                    self:UpdateInfo()
                    UIHelper.SetSelected(nodes.tog, true)
                end
                self:ShowItemTip(KItemWeapon)
            end)
            UIHelper.BindUIEvent(nodes.tog, EventType.OnSelectChanged, function(tog, bSelect)
                if bSelect and self.nColorEquipIndex ~= nEnum then
                    self.nColorEquipIndex = nEnum
                    self:SetToggleToActiveStone()
                    self:UpdateInfo()
                end
            end)
            szMeleeName = UIHelper.GBKToUTF8(KItemWeapon.szName)
        end

        UIHelper.SetString(nodes.name1, szMeleeName)
        UIHelper.SetString(nodes.name2, szMeleeName)
        UIHelper.SetVisible(nodes.tog, KItemWeapon ~= nil)
    end

    UIHelper.LayoutDoLayout(self.LayoutWeapons)
end

function UIWidgetFusionInsert:AddWuCaiStoneToSlot(dwIndex)
    local itemCount = DataModel.GetItemCount(dwIndex)

    if itemCount and itemCount > 0 then
        local KItem = DataModel.GetFirstAvailableItemInList(dwIndex, self.chosenMaterialCountDict)
        if KItem then
            local lastChosenItemInfo = self.chosenWuCaiStone
            if lastChosenItemInfo ~= nil then
                Event.Dispatch(EventType.EquipRefineSelectChanged, lastChosenItemInfo.dwIndex, -1)
                self.chosenMaterialCountDict[lastChosenItemInfo.dwIndex] = nil
            end

            --local newItemInfo = ItemData.GetItemInfo(KItem.dwTabType, KItem.dwIndex)
            --local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(self.nStoneIndex)
            --if dwEnchantID > 0 then
            --    local dwTabType, dwTabIndex = GetColorDiamondInfoFromEnchantID(dwEnchantID)
            --    if dwTabType and dwTabIndex then
            --        local oldItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
            --        local bIsMax = tInfo.nQuality >= tInfo.nMaxQuality
            --        if oldItemInfo.nDetail >= newItemInfo.nDetail and bIsMax then
            --            return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_FUSION_LEVEL_LOW) and false
            --        end
            --    end
            --end

            ------ 开始添加
            local nStackNum = 1
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] or 0
            self.chosenMaterialCountDict[dwIndex] = self.chosenMaterialCountDict[dwIndex] + nStackNum

            local nBox, nIndex = ItemData.GetItemPos(KItem.dwID)
            self.chosenWuCaiStone = {
                dwBox = nBox,
                dwX = nIndex,
                nUiId = KItem.nUiId,
                nGenre = KItem.nGenre,
                dwTabType = KItem.dwTabType,
                dwIndex = KItem.dwIndex,
                nStackNum = nStackNum,
                nQuality = KItem.nQuality,
                nDetail = KItem.nDetail,
                nIcon = Table_GetItemIconID(KItem.nUiId),
            }
            return true
        else
            return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_REFINE_EXPEND_AMOUNT_REACH_UBOUND) and false
        end
    end
end

function UIWidgetFusionInsert:CheckWuCaiStoneValidity()
    if self.nStoneIndex == 5 and self.KItemWeapon then
        return self.nCurrentWeaponActiveSlot ~= 0
    end

    if self.bIsColorFusion then
        local newItemInfo = self.chosenWuCaiStone
        if newItemInfo ~= nil and not IsTableEmpty(newItemInfo)
                and self.nStoneIndex and self.nStoneIndex >= 1 and self.nStoneIndex <= MAX_COLOR_DIAMOND_NUM then
            return true
        end
    else
        if self.KItemWeapon and (self.nCurrentWeaponIndex == 0 or self.nCurrentWeaponActiveSlot ~= self.nStoneIndex) then
            local dwEnchantID, nCurLevel = g_pClientPlayer.GetColorDiamondSlotInfo(self.nStoneIndex)
            return dwEnchantID > 0
        end
    end

    return false
end

--- 熔嵌五彩石到特定孔位
function UIWidgetFusionInsert:AddColorDiamondToSlot()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, "OPERATE_DIAMOND") then
        return
    end

    local dwSlotBox = self.chosenWuCaiStone.dwBox
    local dwSlotX = self.chosenWuCaiStone.dwX

    if not self.nStoneIndex or self.nStoneIndex == 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tActivation.NO_SELECT_BOX)
        return
    end

    local fnAction = function()
        self:ClearData()
        self:UpdateInfo()
        RemoteCallToServer("OnMountEquipBoxColorDiamond", self.nStoneIndex, dwSlotBox, dwSlotX)
    end

    local szMessage = GetFormatText(FormatString(g_tStrings.tActivation.MOUNT_COLOR_DIAMOND, self.nStoneIndex))
    UIHelper.ShowConfirm(szMessage, function()
        fnAction()
    end, nil, true)
end

---装备栏融嵌 - 五彩石
function UIWidgetFusionInsert:SelectColorDiamond()
    SelectColorDiamond(true, self.nStoneIndex, self.nCurrentWeaponIndex, self.nColorEquipIndex)
end

---装备栏融嵌 - 五彩石
function UIWidgetFusionInsert:DeactivateColorDiamond()
    SelectColorDiamond(false, 0, self.nCurrentWeaponIndex, self.nColorEquipIndex)
end

---装备栏融嵌
function UIWidgetFusionInsert:StartSlotEquipBox()
    local nType = self:GetMaterialType()

    if nType == MaterialType.WuXingStone then
        self:FusionInlayWuXingStone()
    elseif nType == MaterialType.WuCaiStone then
        if self.nStoneIndex == 5 then
            self:DeactivateColorDiamond()
            return
        end

        if self.bIsColorFusion then
            self:AddColorDiamondToSlot()
        else
            self:SelectColorDiamond()
        end
    end
end

function UIWidgetFusionInsert:GetMaterialType()
    return (self.nEquip == EQUIPMENT_INVENTORY.MELEE_WEAPON or self.nEquip == EQUIPMENT_INVENTORY.BIG_SWORD)
            and self.nMaterialType or MaterialType.WuXingStone
end

function UIWidgetFusionInsert:ClearData()
    self.nBox = nil
    self.nIndex = nil
    self.slotToChosenMaterialDict = {}
    self.chosenWuCaiStone = nil
    self.chosenMaterialCountDict = {}
end

function UIWidgetFusionInsert:PlayAnim(szAnimeName)
    UIHelper.PlayAni(self, self.AniAll, szAnimeName)
end

function UIWidgetFusionInsert:UpdateNoEffectiveSlotString()
    local nIndexToName = {
        "槽位一",
        "槽位二",
        "槽位三",
    }

    self.szNoEffectiveSlot = nil
    local szMsg = "以下槽位已失效："
    local bHasNoEffective = false
    for _, equipSlotInfo in pairs(DataModel.tEquipBoxList) do
        local nEquip = equipSlotInfo[1]
        local szName = equipSlotInfo[2]
        local pItem = DataModel.GetEquipItem(nEquip)

        if pItem then
            local szSub = ""
            for slotIndex = 1, MAX_SLOT_NUM do
                local cpp_SlotIndex = slotIndex - 1
                local tInfo = DataModel.GetSlotBoxInfo(nEquip, cpp_SlotIndex)
                local bCanMount = tInfo.bCanMount

                if bCanMount and tInfo.dwEnchantID > 0 then
                    local nSlotQuality = tInfo.nQuality
                    if nSlotQuality < pItem.nLevel then
                        bHasNoEffective = true
                        if szSub ~= "" then
                            szSub = szSub .. "、"
                        end
                        szSub = szSub .. nIndexToName[slotIndex]
                    end
                end
            end

            if szSub ~= "" then
                szMsg = szMsg .. string.format("\n%s(%s)", szName, szSub)
            end
        end
    end
    if bHasNoEffective then
        self.szNoEffectiveSlot = szMsg
    end

    UIHelper.SetVisible(self.BtnHint01, bHasNoEffective)
end

return UIWidgetFusionInsert