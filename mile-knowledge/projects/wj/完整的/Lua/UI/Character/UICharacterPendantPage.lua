-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantPage
-- Date: 2023-02-27 11:15:12
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@type UICharacterPendantPublicPage
---@class UICharacterPendantPage : UICharacterPendantPublicPage
local UICharacterPendantPage = class(UICharacterPendantPublicPage, "UICharacterPendantPage")

function UICharacterPendantPage:Init()
    self.nCurSelectedIndex = 1
    self:BindMainPageIndex(AccessoryMainPageIndex.Pendant)
    self:BindDataModel(CharacterPendantData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.DataModel.Init(self.nCurSelectedIndex)
    self:InitFilter()
    self:UpdateInfo()
end

function UICharacterPendantPage:OnExit()
    self.bInit = false
    self.DataModel.UnInit()
end

function UICharacterPendantPage:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self.nCurSelectedIndex = i - 1
            self:SetNowCollectPage(self.nCurSelectedIndex == 0)
            Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, self.nCurSelectedIndex)
        end)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupRightNav, self.nCurSelectedIndex)
end

function UICharacterPendantPage:RegEvent()
    Event.Reg(self, "REMOTE_DATA_PREFER_PENDANT", function()
        self.DataModel.Update()
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_EQUIP_PENDENT_PET_NOTIFY", function()
        self.DataModel.Update()
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SELECT_PENDANT", function()
        self.DataModel.Update()
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_PLAYER_SELECTED_PENDENT_NOTIFY", function()
        self.DataModel.Update()
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.ON_ADD_PENDANT, function()
        self:UpdateTogInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if not self.tbFilter or szKey ~= self.tbFilter.Key then
            return
        end

        local nSelectFilterHave = tbInfo[1][1] - 1
        local nSelectFilterClass = tbInfo[2][1] - 1
        local nSelectFilterWay = tbInfo[3][1] - 1

        self.DataModel.SetFilter(nSelectFilterClass, nSelectFilterHave, nSelectFilterWay)
        self.DataModel.UpdateFilterList()
        self.DataModel.SetCurrentPage(1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnCharacterCustomPandentOpenClose, function(bOpen)
        if UIHelper.GetVisible(self._rootNode) == false then
            return
        end

        UIHelper.SetVisible(self.WidgetAccessoryList, not bOpen)
        UIHelper.SetVisible(self.WidgetAccessoryTitle, not bOpen)
        self:ShowPublic(not bOpen)
    end)
end

function UICharacterPendantPage:InitFilter()
    self.scriptFilterTip = UIHelper.GetBindScript(self.WidgetAnchorSuitAccessoryTips)
    self.scriptFilterTip:OnEnter(function(nSelectFilterHave, nSelectFilterClass, nSelectFilterWay)
        self.DataModel.SetFilter(nSelectFilterClass, nSelectFilterHave, nSelectFilterWay)
        self:ClearSelect()
        self:UpdateListInfo()
    end)
end

function UICharacterPendantPage:UpdateInfo()
    self:UpdateTitleInfo()
    self:UpdateListInfo()
    self:UpdateTogInfo()
    self:UpdateBtnInfo()
    Event.Dispatch(EventType.OpenCloseCharacterCustomPendant, false)
end

function UICharacterPendantPage:UpdateBtnInfo()
    local bHadWear = false
    local bCustomPendant = false
	local tbTypeInfo = CharacterPendantData.GetTypeInfo(self.nCurSelectedIndex)
    if not tbTypeInfo.nPendantType then
        return
    end

    local dwUsingPendantID, tUsingPendent = self.DataModel.GetUsingPendantID(self.nCurSelectedIndex)
    bHadWear = (dwUsingPendantID and dwUsingPendantID > 0) or (tUsingPendent and not IsEmpty(tUsingPendent))
    self:ShowBtnFastTakeOff(bHadWear)
    self:ShowBtnCustom(bHadWear)

    if not bHadWear then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nEquipSub = GetEquipSubByPendantType(tbTypeInfo.nPendantType)
    self.DataModel.nRepresentType = GetRepresentSubByItemSub(nEquipSub)
    self.DataModel.nPendantType = tbTypeInfo.nPendantType
    local dwIndex = hPlayer.GetSelectPendent(self.DataModel.nPendantType)

    if dwIndex then
        bCustomPendant = CharacterPendantData.IsDIYPendant(ITEM_TABLE_TYPE.CUST_TRINKET ,dwIndex)
    end

    self:ShowBtnCustom(bCustomPendant)
end

function UICharacterPendantPage:UpdateTogInfo()
    for i, tog in ipairs(self.tbTogType) do
        -- 有红点就优先显示红点
        local ImgRedPoint = self.tbTogRedPoint[i]
        local bHasNew = RedpointHelper.Pendant_HasNewByType(i - 1)
        UIHelper.SetVisible(ImgRedPoint, bHasNew)

        local imgIconWear = self.tbIconTypeWear[i]
        if not bHasNew then
            local dwUsingPendantID, tUsingPendent = self.DataModel.GetUsingPendantID(i - 1)
            local bHadWear = (dwUsingPendantID and dwUsingPendantID > 0) or (tUsingPendent and not IsEmpty(tUsingPendent))
            UIHelper.SetVisible(imgIconWear, bHadWear)
        else
            UIHelper.SetVisible(imgIconWear, false)
        end
    end
end

function UICharacterPendantPage:UpdateTitleInfo()
    local tbInfo = self.DataModel.GetTypeInfo(self.nCurSelectedIndex)
    local tbPendantList = self.DataModel.GetPendentList(self.nCurSelectedIndex)

    self:SetImgAccessoryIcon(tbInfo.szIcon)
    self:SetImgTitle(tbInfo.szIcon2)
    self:SetLabelAccessory(tbInfo.szName)

    if tbInfo.szName == "收藏" then
        self:SetLabelEmpty("暂无收藏的挂件")
    else
        self:SetLabelEmpty(string.format("暂无符合条件的%s", tbInfo.szName))
    end

    if tbInfo.bShowGabSize then
        self:SetLabelAccessory01(string.format("%s挂件位", tbInfo.szName))
        self:SetLabelAccessory02(string.format("%s挂件位不足时，可前往交易行购买或生活技艺缝纫。", tbInfo.szName))
        self:SetLabelAccessoryTipsNum(string.format("%d/%d", tbPendantList.dwPendantBagNum, tbPendantList.dwPendantListSize))
        self:SetLabelAccessoryTogNum(string.format("%d/%d", tbPendantList.dwPendantBagNum, tbPendantList.dwPendantListSize))
    end
    self:ShowTogAccessory(tbInfo.bShowGabSize)
    self:ShowBtnHangingPetPosition(tbInfo.szType == "PendantPet" and tbPendantList.dwPendantMaxNum > 0)
end

local function IsHavePendantAction(nTabType, nTabID)
    local player = GetClientPlayer()
    local tbItemInfo = ItemData.GetItemInfo(nTabType, nTabID)
    if not tbItemInfo or not player then
        return false
    end

    local nSubType = tbItemInfo.nSub
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    if table.contain_value(tRepresentIDs, tbItemInfo.nRepresentID) and nSubType == EQUIPMENT_SUB.PENDENT_PET then
        return true
    elseif nSubType == EQUIPMENT_SUB.R_GLOVE_EXTEND then
        local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
        for _, resInfo in pairs(aRes) do
            if CharacterExteriorData.IsRHandPandent(resInfo.aRepresentIDGroups1) then
                return resInfo.dwSkillID > 0
            end
        end
    elseif nSubType == EQUIPMENT_SUB.L_GLOVE_EXTEND then
        local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
        for _, resInfo in pairs(aRes) do
            if CharacterExteriorData.IsLHandPandent(resInfo.aRepresentIDGroups1) then
                return resInfo.dwSkillID > 0
            end
        end
    elseif tbItemInfo.dwSkillID > 0 then
        return true
    end

    return false
end

function UICharacterPendantPage:UpdateListInfo()
    local tbPendantInfo = self.DataModel.GetPendentInfo(self.nCurSelectedIndex)
    local tbPendantList, dwSelectNum, dwMaxPageCount, dwCurrentPage = self.DataModel.GetSelectList()
    self.tbScriptItemIcon = self.tbScriptItemIcon or {}

    for i, scriptItem in ipairs(self.tbScriptItemIcon) do
        UIHelper.SetVisible(scriptItem._rootNode, false)
    end

    self:ShowWidgetEmpty(table.is_empty(tbPendantList))
    -- UIHelper.SetVisible(self.WidgetAccessoryPaginate, not table.is_empty(tbPendantList))

	local dwMaxNum = dwSelectNum
    local dwPage = dwCurrentPage or 1
	local dwStart = (dwPage - 1) * self.DataModel.GetMaxShowCount() + 1
	local dwEnd = dwPage * self.DataModel.GetMaxShowCount()
    local nCellIndex = 1

    local nIndex = dwStart

    local fnLoadCell = function(nIndex, nCellIndex)
        if nIndex > dwMaxNum or nIndex > dwEnd then
            return
        end

        local tbInfo = tbPendantList[nIndex]
        local scriptItem = self.tbScriptItemIcon[nCellIndex]
        if not scriptItem then
            scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryListItem, self.ScrollViewAccessoryList)
            scriptItem:OnEnter()
            table.insert(self.tbScriptItemIcon, scriptItem)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, scriptItem.ToggleSelect)
            UIHelper.SetSwallowTouches(scriptItem.ToggleSelect, false)
        end

        if tbInfo.bUnEquipItem then
            scriptItem:OnInitUnEquipBtn(self.nCurSelectedIndex)
            UIHelper.SetVisible(scriptItem._rootNode, true)
        else
            scriptItem:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, tbInfo.dwItemIndex)
            scriptItem:SetDownloadEnabled(tbInfo.bHave)
            scriptItem:SetClickCallback(function(nTabType, nTabID)
                -- 点击后取消红点
                RedpointHelper.Pendant_SetNew(self.nCurSelectedIndex, tbInfo.dwItemIndex, false)
                UIHelper.SetVisible(scriptItem.ImgNew, false)
                self:UpdateTogInfo()

                UIHelper.SetSelected(scriptItem.ToggleSelect, false)

                if nTabType and nTabID then
                    self.nCurSelectedItemID = nTabID
                    Event.Dispatch(EventType.OnCharacterPendantPageItemSelected, nTabID)
                end

                if not self.scriptItemTip then
                    self.scriptItemTip = self:GetItemTips()
                end

                if self.nCurSelectedItemID == nTabID then
                    self.scriptItemTip:SetPlayerID(PlayerData.GetPlayerID())
                    self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                    local tbBtnState = {}

                    if tbInfo.bHave then
                        if tbInfo.bUsing then
                            table.insert(tbBtnState, {szName = "脱下", OnClick = function ()
                                Event.Dispatch(EventType.HideAllHoverTips)
                                local dwPart = self.nCurSelectedIndex
                                if dwPart == 0 then
                                    dwPart = self.DataModel.GetdwPartID(tbInfo.szType)
                                end
                                self.DataModel.EquipPendant(tbInfo, dwPart, false)
                            end})

                            if IsHavePendantAction(nTabType, nTabID) then
                                table.insert(tbBtnState, {szName = "挂件动作", OnClick = function ()
                                    UIMgr.CloseAllInLayer("UIPageLayer")
                                    UIMgr.CloseAllInLayer("UIPopupLayer")
                                    UIMgr.Open(VIEW_ID.PanelQuickOperation)
                                    Event.Dispatch("ON_OPEN_ACTIONOPERATION")
                                end})
                            end
                        elseif tbInfo.tData and #tbInfo.tData > 1 then
                            table.insert(tbBtnState, {szName = "偏色", bNormalBtn = false, OnClick = function ()
                                local dwPart = self.nCurSelectedIndex
                                if dwPart == 0 then
                                    dwPart = self.DataModel.GetdwPartID(tbInfo.szType)
                                end

                                if tbInfo.bUsing then
                                    self.DataModel.EquipPendant(tbInfo, dwPart, false)
                                    Event.Dispatch(EventType.HideAllHoverTips)
                                else
                                    -- self.DataModel.EquipPendant(tbInfo, dwPart, true, 1)
                                    self:ShowChangeColorTips(tbInfo)
                                end
                            end})
                        else
                            if (tbInfo.szType ~= "Head") or (PlayerData.GetClientPlayer().GetHeadPendentSelectedPos(0)) then
                                table.insert(tbBtnState, {szName = "穿戴", OnClick = function ()
                                    Event.Dispatch(EventType.HideAllHoverTips)
                                    local dwPart = self.nCurSelectedIndex
                                    if dwPart == 0 then
                                        dwPart = self.DataModel.GetdwPartID(tbInfo.szType)
                                    end

                                    self.DataModel.EquipPendant(tbInfo, dwPart, true, nColorIndex)
                                end})
                            end
                        end
                    end

                    if self.DataModel.IsPreferPendant(nTabID) then
                        table.insert(tbBtnState, {szName = g_tStrings.STR_PENDANT_UNSTAR, OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            RemoteCallToServer("On_Pendent_UnstarPendant", tbInfo.dwItemIndex)
                        end})
                    else
                        table.insert(tbBtnState, {szName = g_tStrings.STR_PENDANT_STAR, OnClick = function ()
                            Event.Dispatch(EventType.HideAllHoverTips)
                            RemoteCallToServer("On_Pendent_StarPendant", tbInfo.dwItemIndex)
                        end})
                    end

                    --if tbInfo.bHave then
                        -- table.insert(tbBtnState, {szName = "分享", OnClick = function ()
                        --     ChatHelper.SendItemInfoToChat(nil, nTabType, nTabID)
                        --     self:ClearSelect()
                        -- end})
                    --end
                    if tbInfo.bHave and self.DataModel.IsDIYPendant(nTabType, nTabID) and tbInfo.bUsing then
                        table.insert(tbBtnState, {szName = "自定义", OnClick = function ()
                            -- local szLink = ""
                            -- local dwID, nColor1, nColor2, nColor3 = tbInfo.dwItemIndex, 0, 0, 0
                            -- if tbInfo.tData and #tbInfo.tData > 1 then
                            --     self:ShowDIYColorTips(tbInfo)
                            --     return
                            -- elseif tbInfo.tData and tbInfo.tData[1] then
                            --     local tbColorInfo = tbInfo.tData[1]
                            --     nColor1, nColor2, nColor3 = tbColorInfo.nColorID1, tbColorInfo.nColorID2, tbColorInfo.nColorID3
                            --     szLink = string.format("%d/%d/%d/%d", dwID, nColor1, nColor2, nColor3)
                            -- else
                            --     szLink = string.format("%d/%d/%d/%d", dwID, nColor1, nColor2, nColor3)
                            -- end
                            -- Event.Dispatch(EventType.HideAllHoverTips)
                            -- CoinShopData.LinkPendant(szLink, true)
                            Event.Dispatch(EventType.OpenCloseCharacterCustomPendant, true, self.DataModel.nRepresentType, self.DataModel.nPendantType)
                        end})
                    end

                    table.insert(tbBtnState, unpack(OutFitPreviewData.SetPreviewBtn(nTabType, nTabID))) -- 试穿

                    if not string.is_nil(tbInfo.szGuide) then
                        self.scriptItemTip:UpdatePendantGuideInfo(UIHelper.GBKToUTF8(tbInfo.szGuide))
                    end

                    self.scriptItemTip:SetBtnState(tbBtnState)
                end
            end)
            UIHelper.SetVisible(scriptItem._rootNode, true)
            UIHelper.SetNodeGray(scriptItem.ImgIcon, not tbInfo.bHave)
            UIHelper.SetVisible(scriptItem.ImgEquipped, tbInfo.bUsing)
            UIHelper.SetVisible(scriptItem.ImgLike, tbInfo.bStar)
            UIHelper.SetVisible(scriptItem.ImgMask, not tbInfo.bHave)

            if tbInfo.bHave then
                UIHelper.SetOpacity(scriptItem.WidgetItem, 255)
            else
                UIHelper.SetOpacity(scriptItem.WidgetItem, 120)
            end

            -- 新
            local bIsNew = RedpointHelper.Pendant_IsNew(self.nCurSelectedIndex, tbInfo.dwItemIndex)
            UIHelper.SetVisible(scriptItem.ImgNew, bIsNew)

            --特效
            if scriptItem.scriptItemIcon then
                UIHelper.SetVisible(scriptItem.scriptItemIcon.Eff_Rectangle, tbInfo.bUsing)
            end

            UIHelper.LayoutDoLayout(scriptItem.LayoutIcon)
        end
    end

    local fnLoadFinish = function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAccessoryList)
        UIHelper.ScrollViewSetupArrow(self.ScrollViewAccessoryList, self.WidgetArrow)

        UIHelper.SetString(self.EditPaginate, tostring(dwCurrentPage))
        UIHelper.SetString(self.LabelPaginate, string.format("/%d", dwMaxPageCount))

        self:ClearSelect()

        RedpointHelper.Pendant_ClearByType(self.nCurSelectedIndex)
    end

    Timer.DelTimer(self, self.nLoadTimerID)
    self.nLoadTimerID = Timer.AddFrameCycle(self, 1, function()
        if nIndex > dwMaxNum or nIndex > dwEnd then
            Timer.DelTimer(self, self.nLoadTimerID)
            fnLoadFinish()
        else
            local nOneFrameCount = 4
            for i = 1, nOneFrameCount do
                fnLoadCell(nIndex, nCellIndex)
                nIndex = nIndex + 1
                nCellIndex = nCellIndex + 1
            end
        end
    end)
end

function UICharacterPendantPage:ShowChangeColorTips(tbInfo)
    local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSimpleFilterTip, self.WidgetItemCard, TipsLayoutDir.RIGHT_CENTER)
    -- WidgetCloakColorChangeCell
    UIHelper.RemoveAllChildren(tipsScript.LayoutListShort)
    local tData = tbInfo.tData or {}
    for i, value in ipairs(tData) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetCloakColorChangeCell, tipsScript.LayoutListShort)
        cell:OnEnter(value, function ()
            self.DataModel.EquipPendant(tbInfo, self.nCurSelectedIndex, true, i)
            Event.Dispatch(EventType.HideAllHoverTips)
        end)

        if i == 1 then
            UIHelper.SetSelected(cell.TogType, true)
        end
    end
end

function UICharacterPendantPage:ShowDIYColorTips(tbInfo)
    -- 自定义跳转
    local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSimpleFilterTip, self.WidgetItemCard, TipsLayoutDir.RIGHT_CENTER)
    -- WidgetCloakColorChangeCell
    UIHelper.RemoveAllChildren(tipsScript.LayoutListShort)
    local tData = tbInfo.tData or {}

    local dwPart = self.nCurSelectedIndex
    if dwPart == 0 then
        dwPart = self.DataModel.GetdwPartID(tbInfo.szType)
    end
    local tPendent = CharacterPendantData.tList[dwPart]
    local tColorID = tPendent.tColorID
    for i, value in ipairs(tData) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetCloakColorChangeCell, tipsScript.LayoutListShort)
        local dwID, nColor1, nColor2, nColor3 = tbInfo.dwItemIndex, value.nColorID1, value.nColorID2, value.nColorID3
        local szLink = string.format("%d/%d/%d/%d", dwID, nColor1, nColor2, nColor3)
        cell:OnEnter(value, function ()
            CoinShopData.LinkPendant(szLink, true)
            Event.Dispatch(EventType.HideAllHoverTips)
        end)

        if tColorID and ExteriorCharacter.IsColorSame(tColorID, {nColor1, nColor2, nColor3}) then
            UIHelper.SetSelected(cell.TogType, true)
        elseif i == 1 and ExteriorCharacter.IsColorSame(tColorID, {0,0,0}) then
            UIHelper.SetSelected(cell.TogType, true)
        end
    end
end

function UICharacterPendantPage:ClearSelect()
    if self.tbScriptItemIcon then
        for i, scriptItem in ipairs(self.tbScriptItemIcon) do
            scriptItem:SetSelected(false)
        end
    end
end

function UICharacterPendantPage:OnClickBtnFastTakeOff()
    self.DataModel.EquipPendant(nil, self.nCurSelectedIndex, false)
end

function UICharacterPendantPage:OnClickBtnHangingPetPosition(btn)
    self:ClearSelect()

    local nIndex, nPos = PlayerData.GetClientPlayer().GetEquippedPendentPet()
    local tPosList = CoinShop_GetPendantPetInfo(nIndex)

    local tbBtnInfo = {}
    for i, tbInfo in ipairs(tPosList) do
        table.insert(tbBtnInfo, {
            szName = UIHelper.GBKToUTF8(tbInfo.szName),
            OnClick = function ()
                local hPlayer = GetClientPlayer()
                if not hPlayer then
                    return
                end
                hPlayer.ChangePendentPetPos(nIndex, tbInfo.nPos)
            end
        })
    end

    if #tbBtnInfo > 0 then
        local nX,nY = UIHelper.GetWorldPosition(btn)
        local nSizeW,nSizeH = UIHelper.GetContentSize(btn)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX-nSizeW-246,nY+nSizeH+170)
        scriptTips:OnEnter(tbBtnInfo)
    else
        TipsHelper.ShowNormalTip("暂无可配置的悬挂部位")
    end
end

function GetRepresentSubByItemSub(nSubType)
	local tItemSubToRepresentSub =
	{
		[EQUIPMENT_SUB.MELEE_WEAPON] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
		[EQUIPMENT_SUB.CHEST] = EQUIPMENT_REPRESENT.CHEST_STYLE,
		[EQUIPMENT_SUB.HELM]  = EQUIPMENT_REPRESENT.HELM_STYLE,
		[EQUIPMENT_SUB.WAIST] = EQUIPMENT_REPRESENT.WAIST_STYLE,
		[EQUIPMENT_SUB.BOOTS] = EQUIPMENT_REPRESENT.BOOTS_STYLE,
		[EQUIPMENT_SUB.BANGLE] = EQUIPMENT_REPRESENT.BANGLE_STYLE,
		[EQUIPMENT_SUB.WAIST_EXTEND] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
		[EQUIPMENT_SUB.BACK_EXTEND] = EQUIPMENT_REPRESENT.BACK_EXTEND,
		[EQUIPMENT_SUB.FACE_EXTEND] = EQUIPMENT_REPRESENT.FACE_EXTEND,
		[EQUIPMENT_SUB.L_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
		[EQUIPMENT_SUB.R_SHOULDER_EXTEND] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
		[EQUIPMENT_SUB.BACK_CLOAK_EXTEND] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
		[EQUIPMENT_SUB.BAG_EXTEND] = EQUIPMENT_REPRESENT.BAG_EXTEND,
		[EQUIPMENT_SUB.PENDENT_PET] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
		[EQUIPMENT_SUB.GLASSES_EXTEND] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
		--[EQUIPMENT_SUB.HORSE_EQUIP] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,

		[EQUIPMENT_SUB.L_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
		[EQUIPMENT_SUB.R_GLOVE_EXTEND] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
		[EQUIPMENT_SUB.HEAD_EXTEND] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
	}

	local nRepresentSub = tItemSubToRepresentSub[nSubType]
	return nRepresentSub
end

return UICharacterPendantPage