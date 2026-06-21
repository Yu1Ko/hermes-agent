-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemIcon
-- Date: 2022-11-08 11:27:21
-- Desc: WidgetItem_100
-- ---------------------------------------------------------------------------------
---@class UIItemIcon
local UIItemIcon = class("UIItemIcon")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIItemIcon:_LuaBindList()
    self.ToggleSelect = self.ToggleSelect --- 是否选中的toggle
end

function UIItemIcon:OnInit(nBox, nIndex, bMailItem, bAccountWareHouseItem, dwASPSource, bLoadImgAsync)
    self:ClearTeach()
    self.nBox = nBox
    self.nIndex = nIndex
    self.bItem = true
    self.bMailItem = bMailItem or false
    self.bPersistentPress = false
    self.nSelectGroupIndex = -1
    self.dwASPSource = dwASPSource
    self.nPackageType = bAccountWareHouseItem and UI_BOX_TYPE.SHAREPACKAGE or nil
    self.bLoadImgAsync = bLoadImgAsync

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemIcon:OnInitWithTabID(nTabType, nTabID, nStackNum)
    self:ClearTeach()
    self.nTabType = nTabType
    self.nTabID = nTabID
    self.bItem = false
    self.bMailItem = false
    self.nStackNum = nStackNum
    self.bIsCurrencyType = false
    self.nSelectGroupIndex = -1

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemIcon:OnInitWithIconID(nIconID, nQuality, bCoolDown)
    self:ClearTeach()
    self.nIconID = nIconID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSelectGroupIndex = -1

    UIHelper.SetItemIconByIconID(self.ImgIcon, nIconID)

    if nQuality then
        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[nQuality + 1])
        self:UpdateEffect(nQuality)
    end

    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetVisible(self.LabelPolishCount, false)

    if bCoolDown == true then
        if self.nEmotionCDTimer then
            Timer.DelTimer(self, self.nEmotionCDTimer)
        else
            self.nEmotionCDTimer = Timer.AddCycle(self, 1, function()
                self:ShowEmotionCoolDown()
            end)
        end
    end
end

function UIItemIcon:OnInitCurrency(szName, nCount, bReputation)
    self:ClearTeach()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szCurrencyName = szName
    self.bIsCurrencyType = true
    self.bIsReputation = bReputation or false
    self.nSelectGroupIndex = -1

    if CurrencyType.Money == szName then
        self:SetMoneyIcon(nCount)
    else
        szName = self.bIsReputation and CurrencyType.Reputation or szName
        self:SetIconBySpriteFrameName(CurrencyData.tbImageBigIcon[szName])
        self:SetLabelCount(nCount)
    end

    UIHelper.SetVisible(self.ImgAttri, false)
    UIHelper.SetVisible(self.ImgTime, false)
end

function UIItemIcon:OnInitSkill(nSkillID, nSkillLevel, funcCallBack, bShowCD)
    self:ClearTeach()
    self.nSkillID = nSkillID
    self.nSkillLevel = nSkillLevel
    self.bShowCD = bShowCD
    if bShowCD == nil then
        self.bShowCD = true
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bIsSkill = true
    local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(nSkillID, nSkillLevel)
    self:SetIconByTexture(szImagePath, funcCallBack)
    self:HideLabelCount()
    self:SetClickNotSelected(true)
    if self.bShowCD then
        self:UpdateCDProgressBySkill(nSkillID, nSkillLevel)
    end
    UIHelper.SetVisible(self.ImgPolishCountBG, false)
end

function UIItemIcon:OnInitWithRideExterior(dwExteriorID, bEquip, bNoGray)
    self:ClearTeach()
    self.dwExteriorID = dwExteriorID
    self.bEquip = bEquip
    self.bItem = false
    self.bMailItem = false
    self.nStackNum = nil
    self.bIsCurrencyType = false
    self.nSelectGroupIndex = -1
    self.bRideExterior = true

    local tInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, bEquip)
    if not tInfo then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetItemIconByIconID(self.ImgIcon, tInfo.nIconID)

    if tInfo.nQuality then
        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[tInfo.nQuality + 1])
        self:UpdateEffect(tInfo.nQuality)
    end

    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetVisible(self.LabelPolishCount, false)
    UIHelper.SetVisible(self.ImgDiscount, tInfo.bCollected and tInfo.bOffer and (not tInfo.bHave))

    if (not tInfo.bHave) and (not bNoGray) then
        self:SetItemGray(true)
    end
    if (not tInfo.bCollected) and (not bNoGray) then
        self:ShowLockIcon(true)
    end
end

function UIItemIcon:OnExit()
    self.bInit = false
    self.bBatch = false
    self.bHandleChooseEvent = false
    UIHelper.SetVisible(self.WidgetMultiSelect, false)
    UIHelper.SetVisible(self.ImgChooseNum, false)
    UIHelper.SetVisible(self.ImgWeaponMark, false)

    Timer.DelAllTimer(self)

    if self.ToggleGroup then
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.ToggleSelect)
        self.ToggleGroup = nil
    end
end

function UIItemIcon:OnPoolRecycled(bSaveTexture)
    if bSaveTexture then
        self:SetSelectChangeCallback(nil)
        self:SetEnable(true)
        self:SetSelectMode(false)
    else
        UIHelper.ClearTexture(self.ImgIcon)
        self:SetEnable(true)
        self:SetSelectMode(false)
        self:SetSelectChangeCallback(nil)
    end

    self:SetClickCallback(nil)
    self:SetSelected(false)
    self:SetMultiSelected(false)
    self:SetNewItemFlag(false)
    self:SetForbidShowCoolDown(false)
    self.nStackNum = nil
    self.bNewFlag = nil
    self.bEnableTimeLimitFlag = nil
    self.nSelectGroupIndex = -1
    self.bIsSkill = false
    self.bBatch = false
    self.bHandleChooseEvent = false
    self.dwASPSource = nil
    self.nPackageType = nil
    self.bLoadImgAsync = nil

    UIHelper.SetVisible(self.WidgetDownloadShell, false)
    UIHelper.SetVisible(self.WidgetMultiSelect, false)
    UIHelper.SetVisible(self.ImgChooseNum, false)
    UIHelper.SetVisible(self.LabelChooseNum, false)
    UIHelper.SetProgressBarPercent(self.imgSkillCd, 0)
    UIHelper.SetVisible(self.ImgWeaponMark, false)
    UIHelper.SetVisible(self.WidgetCD, false)

    UIHelper.SetNodeGray(self.ImgIcon, false, true)
    UIHelper.SetOpacity(self._rootNode, 255)

    if self.ToggleGroup then
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.ToggleSelect)
        self.ToggleGroup = nil
    end

    if self.nCDTimer then
        Timer.DelTimer(self, self.nCDTimer)
        self.nCDTimer = nil
    end
end

function UIItemIcon:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.bPersistentPress then
            self.bPersistentPress = false
            return
        end
        self:OnSelectChanged(bSelected)
    end)

    UIHelper.SetButtonClickSound(self.ToggleSelect, "")
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function()
        self:OnClick()
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnLongPress, function()
        self.bPersistentPress = true
        self:OnLongPress()
        Event.Dispatch(EventType.BagItemLongPress, self.nBox, self.nIndex, self.nTabType, self.nTabID, self)
    end)

    UIHelper.BindUIEvent(self.BtnRecall, EventType.OnClick, function()
        if self.funcRecallCallback then
            self.funcRecallCallback(self.tbRecallCallbackArgs)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRecallSkill, EventType.OnClick, function()
        if self.funcSkillRecallCallback then
            self.funcSkillRecallCallback()
        end
    end)
end

function UIItemIcon:RegEvent()

    Event.Reg(self, EventType.OnClearUIItemIconSelect, function()
        self:RawSetSelected(false)
    end)

    Event.Reg(self, EventType.OnSetUIItemIconChoose, function(bSelected, _nBox, _nIndex, nCount)
        if not self.bHandleChooseEvent then
            return
        end
        local nBox = self.nBox or self.nTabType
        local nIndex = self.nIndex or self.nTabID

        if not nBox or not nIndex or (nBox == _nBox and nIndex == _nIndex) then
            if bSelected then
                UIHelper.SetVisible(self.ImgChooseNum, true)
                if UIHelper.GetVisible(self.LabelCount) then
                    UIHelper.SetVisible(self.LabelChooseNum, true)
                    if nCount then
                        UIHelper.SetString(self.LabelChooseNum, tostring(nCount))
                    else
                        UIHelper.SetString(self.LabelChooseNum, UIHelper.GetString(self.LabelCount))
                    end
                end
                UIHelper.LayoutDoLayout(self.ImgChooseNum)
            else
                UIHelper.SetVisible(self.ImgChooseNum, false)
                UIHelper.SetVisible(self.LabelChooseNum, false)
            end
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.bClearSeletedOnCloseAllHoverTips then
            UIHelper.SetSelected(self.ToggleSelect)
        end
    end)

    Event.Reg(self, EventType.OnCloseItemTeach, function()
        if not self.bInit then
            return
        end

        self:ClearTeach()
    end)
end

function UIItemIcon:GetItem()
    local item

    if self.bItem then
        local player = g_pClientPlayer
        if self.nPlayerID then
            player = GetPlayer(self.nPlayerID)
        end
        item = ItemData.GetPlayerItem(player, self.nBox, self.nIndex, self.nPackageType, self.dwASPSource)
    elseif self.nTabType == "EquipExterior" or self.nTabType == "WeaponExterior" then
        local hExteriorClient = GetExterior()
        if not hExteriorClient then
            return item
        end

        if self.nTabType == "EquipExterior" then
            item = hExteriorClient.GetExteriorInfo(self.nTabID)
        elseif self.nTabType == "WeaponExterior" then
            item = CoinShop_GetWeaponExteriorInfo(self.nTabID, hExteriorClient)
        end
    elseif self.nTabType and self.nTabID then
        item = ItemData.GetItemInfo(self.nTabType, self.nTabID)
    end

    return item
end

--教学用
function UIItemIcon:GetItemIDInfo()
    if IsNumber(self.nTabType) and IsNumber(self.nTabID) then
        return {
            dwTabType = self.nTabType,
            dwIndex = self.nTabID,
        }
    end

    local item = self:GetItem()
    return item and {
        dwTabType = ITEM_TABLE_TYPE.OTHER,
        dwIndex = item.dwID,
    }
end

function UIItemIcon:UpdateInfo(item)
    item = item or self:GetItem()

    UIHelper.SetVisible(self.LabelPolishCount, false)
    UIHelper.SetVisible(self.ImgPolishCountBG, false)
    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetVisible(self.ImgIcon, false)
    UIHelper.SetVisible(self.ImgBlack, false)
    UIHelper.SetVisible(self.ImgEnduranceLow, false)
    UIHelper.SetVisible(self.ImgAttri, false)
    UIHelper.SetVisible(self.ImgTime, false)
    UIHelper.SetVisible(self.ImgWorseArrow, false)
    UIHelper.SetVisible(self.ImgBetterArrow, false)
    UIHelper.SetVisible(self.ImgUseless, false)

    self.bShowEquipBetterArrow = false

    if item then
        if self.nTabType == "EquipExterior" or self.nTabType == "WeaponExterior" then
            self:UpdateExteriorIconInfo(item)
            return
        end

        self.nItemID = item.dwID

        -- print(item.dwTabType, item.szName, ItemData.GetItemStackNum(item), self.nItemID, item.nUiId)

        local szQualityBGColor = ItemQualityBGColor[item.nQuality + 1] or ItemQualityBGColor[1]
        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, szQualityBGColor)
        UIHelper.SetVisible(self.ImgPolishCountBG, true)
        self:UpdateEffect(item.nQuality)

        local bResult = UIHelper.SetItemIconByItemInfo(self.ImgIcon, item, false, self.bLoadImgAsync)
        if not bResult then
            UIHelper.ClearTexture(self.ImgIcon)
        end

        if self.bItem then
            local nStackNum = ItemData.GetItemStackNum(item)
            if nStackNum and not self.bHideCount then
                -- and item.nGenre ~= ITEM_GENRE.EQUIPMENT
                UIHelper.SetString(self.LabelCount, tostring(nStackNum))
                UIHelper.SetVisible(self.LabelCount, true)
            end

            local bBanUseItem = ItemData.IsBanUseItem(item)
            UIHelper.SetVisible(self.ImgUseless, bBanUseItem)
        end

        if self.nStackNum and not self.bHideCount then
            UIHelper.SetString(self.LabelCount, tostring(self.nStackNum))
            UIHelper.SetVisible(self.LabelCount, true)
        end

        UIHelper.SetVisible(self.ImgIcon, true)
        UIHelper.SetVisible(self.ImgBlack, true)

        self:UpdateCornerFlag(item)
        self:UpdateCDProgress(item)
        self:UpdateEnduranceLowState(item)
        self:UpdateEquipScoreArrowInfo(item)
    end
end

function UIItemIcon:UpdateExteriorIconInfo(item)
    if not item then
        return
    end

    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[6])
    UIHelper.SetVisible(self.ImgPolishCountBG, true)
    self:UpdateEffect(6)

    local bResult = UIHelper.SetItemIconByIconID(self.ImgIcon, item.nIconID)
    if not bResult then
        UIHelper.ClearTexture(self.ImgIcon)
    end

    UIHelper.SetVisible(self.ImgIcon, true)
    UIHelper.SetVisible(self.ImgBlack, true)
end

function UIItemIcon:SetSelected(bSelected)
    if self.ToggleGroup and not self.bBatch then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, self.ToggleSelect)
    else
        UIHelper.SetSelected(self.ToggleSelect, bSelected)
    end
end

--对ToggleSelect调用SetSelected但不触发OnSelectChanged
function UIItemIcon:RawSetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelect, bSelected, false)
end

function UIItemIcon:GetSelected()
    return UIHelper.GetSelected(self.ToggleSelect)
end

function UIItemIcon:SetMultiSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelect, bSelected)
end

function UIItemIcon:GetMultiSelected()
    return UIHelper.GetSelected(self.ToggleSelect)
end

function UIItemIcon:SetSelectEnable(nEnable)
    self.ToggleSelect:setEnabled(nEnable)
end

function UIItemIcon:SetLabelCountVisible(bVisible)
    self.bHideCount = not bVisible

    local item = ItemData.GetItem(self.nItemID)
    local nStackNum = ItemData.GetItemStackNum(item)
    if nStackNum and not self.bHideCount then
        UIHelper.SetString(self.LabelCount, tostring(nStackNum))
        UIHelper.SetVisible(self.LabelCount, true)
    else
        UIHelper.SetVisible(self.LabelCount, false)
    end
end

function UIItemIcon:HideLabelCount()
    UIHelper.SetString(self.LabelCount, "")
end

function UIItemIcon:SetLabelCountString(szCount)
    if szCount then
        UIHelper.SetVisible(self.LabelCount, true)
        UIHelper.SetString(self.LabelCount, szCount)
    else
        UIHelper.SetVisible(self.LabelCount, false)
    end
end

function UIItemIcon:SetLabelCount(nCount)
    if nCount then
        UIHelper.SetVisible(self.LabelCount, true)
        UIHelper.SetString(self.LabelCount, tostring(nCount))
    else
        UIHelper.SetVisible(self.LabelCount, false)
    end
end

function UIItemIcon:SetIconBySpriteFrameName(szSpriteFrameName)
    UIHelper.ClearTexture(self.ImgIcon)
    UIHelper.SetSpriteFrame(self.ImgIcon, szSpriteFrameName)
end

function UIItemIcon:SetIconByTexture(szTextureFile, funcCallBack)
    UIHelper.SetTexture(self.ImgIcon, szTextureFile, true, funcCallBack)
end

function UIItemIcon:SetIconVisible(bVisible)
    UIHelper.SetVisible(self.ImgIcon, bVisible)
end

function UIItemIcon:SetClickCallback(callback)
    self.funcClickCallback = callback
end

function UIItemIcon:SetLongPressCallback(callback)
    self.funcLongPressCallback = callback
end

function UIItemIcon:SetSelectChangeCallback(callback)
    self.funcSelectChangeCallback = callback
end


--- 根据剩余冷却时间生成对应格式的冷却时间标签文本
--- @param nCooldown number 剩余冷却时间（秒）
--- @return string 格式化后的冷却时间文本
--- 1. 当剩余时间超过 1 小时时，只显示小时位，忽略分钟和秒数
--- 2. 当剩余时间在 10 分钟（含）到 1 小时之间时，只显示分钟位，忽略秒数
--- 3. 当剩余时间在 9 分钟 59 秒及以下时，若剩余时间不足 1 分钟，只显示秒数；否则显示具体的分钟和秒数
local function _fnGetCoolDownLabel(nCooldown)
    local nHour = math.floor(nCooldown / 3600)
    local nMinute = math.floor((nCooldown - nHour * 3600) / 60)
    local nSecond = math.floor(nCooldown - nHour * 3600 - nMinute * 60)
    if nCooldown >= 3600 then
        return string.format("%d%s", nHour, g_tStrings.STR_TIME_HOUR)
    elseif nCooldown >= 600 then
        return string.format("%d%s", nMinute, g_tStrings.STR_TIME_MINUTE)
    else
        if nMinute > 0 then
            return string.format("%02d%s%02d%s", nMinute, g_tStrings.STR_TIME_MINUTE, nSecond, g_tStrings.STR_TIME_SECOND)
        else
            return string.format("%02d%s", nSecond, g_tStrings.STR_TIME_SECOND)
        end
    end
end

function UIItemIcon:UpdateCDProgress(item)
    if not item then
        return
    end

    local bIsCooldown, nLeftCooldown, nTotalCooldown, _bBroken, _nCDCount
    if self.bItem then
        bIsCooldown, nLeftCooldown, nTotalCooldown, _bBroken, _nCDCount = ItemData.GetItemCDProgressByPos(self.nBox, self.nIndex)
    else
        bIsCooldown, nLeftCooldown, nTotalCooldown, _bBroken, _nCDCount = ItemData.GetItemCDProgressByTab(self.nTabType, self.nTabID)
    end

    if bIsCooldown and not self.bForbidShowCoolDown then
        Timer.DelTimer(self, self.nCDTimer)
        self.nCDTimer = Timer.AddFrame(self, 1, function()
            if self.UpdateCDProgress then -- 防止被回收报错
                self:UpdateCDProgress(item)
            end
        end)

        if nLeftCooldown > 0 then
            local szCooldownText = _fnGetCoolDownLabel(math.ceil(nLeftCooldown / GLOBAL.GAME_FPS))
            UIHelper.SetVisible(self.WidgetCD, true)
            UIHelper.SetString(self.LabelCD, szCooldownText)

            UIHelper.SetProgressBarPercent(self.SliderCDMask, nLeftCooldown * 100 / nTotalCooldown)
        else
            UIHelper.SetVisible(self.WidgetCD, false)
        end
    else
        if self.nCDTimer then
            Timer.DelTimer(self, self.nCDTimer)
            self.nCDTimer = nil
        end

        UIHelper.SetVisible(self.WidgetCD, false)
    end
end

function UIItemIcon:UpdateCDProgressBySkill(skillID, skillLevel, addTimer)
    local UpdateProgress = function()
        local bCool, nLeft, nTotal, nCDCount, bPublicCD = Skill_GetCDProgress(skillID, skillLevel, nil, GetClientPlayer())
        if (nLeft and nLeft > 0) then
            UIHelper.SetVisible(self.WidgetCD, nLeft > 0)
            UIHelper.SetString(self.LabelCD, UIHelper.GetHeightestTimeText(math.ceil(nLeft / GLOBAL.GAME_FPS), false))
        else
            UIHelper.SetVisible(self.WidgetCD, false)
            UIHelper.SetString(self.LabelCD, "")
        end
    end
    if self.nCDSkillTimer then
        Timer.DelTimer(self, self.nCDSkillTimer)
        self.nCDSkillTimer = nil
    end
    self.nCDSkillTimer = Timer.AddCycle(self, 1, function()
        UpdateProgress()
    end)
    UpdateProgress()
end

function UIItemIcon:UpdateEnduranceLowState(item)
    local bEnduraceLow = false
    if self.bItem then
        if ItemData.IsPendantItem(item) or
                item.nSub == EQUIPMENT_SUB.AMULET or
                item.nSub == EQUIPMENT_SUB.RING or
                item.nSub == EQUIPMENT_SUB.PENDANT or
                item.nSub == EQUIPMENT_SUB.BULLET or
                item.nSub == EQUIPMENT_SUB.HORSE or
                item.nSub == EQUIPMENT_SUB.MINI_AVATAR or
                item.nSub == EQUIPMENT_SUB.PET or
                item.nSub == EQUIPMENT_SUB.HORSE_EQUIP or
                item.nSub == EQUIPMENT_SUB.PENDENT_PET or
                item.nSub == EQUIPMENT_SUB.PACKAGE or
                item.nSub == EQUIPMENT_SUB.ARROW then

            bEnduraceLow = false
        else
            if item.nMaxDurability > 0 and item.nCurrentDurability <= 0 then
                bEnduraceLow = true
            end
        end
    end

    UIHelper.SetVisible(self.ImgEnduranceLow, bEnduraceLow)
end

function UIItemIcon:UpdateEquipScoreArrowInfo(item)
    item = item or self:GetItem()

    local bBanUseItem = self.bItem and ItemData.IsBanUseItem(item) or false
    self.bShowEquipBetterArrow = false
    UIHelper.SetVisible(self.ImgWorseArrow, false)
    UIHelper.SetVisible(self.ImgBetterArrow, false)

    if bBanUseItem then
        return
    end

    -- 装备提升箭头与New重叠，New优先级大于提升箭头
    if not self.bShowEquipScoreArrow or self.bNewFlag then
        return
    end

    if not item or item.nGenre ~= ITEM_GENRE.EQUIPMENT then
        return
    end

    local itemInfo, nSubType, nDetailType
    if self.bItem then
        itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        nSubType = itemInfo.nSub
        nDetailType = itemInfo.nDetail
    else
        itemInfo = item
        nSubType = item.nSub
        nDetailType = item.nDetail
    end

    local itemC, itemCAdd = EquipData.GetEquipItemCompaireItem(nSubType, nDetailType)

    local nMinBaseScore = nil
    local nCount = 0
    local bShow = false
    if itemC then
        nMinBaseScore = itemC.nBaseScore
        nCount = nCount + 1
    end
    if itemCAdd then
        local nBaseScore = itemCAdd.nBaseScore
        if nMinBaseScore then
            nMinLevel = math.min(nMinBaseScore, nBaseScore)
        else
            nMinBaseScore = nBaseScore
        end
        nCount = nCount + 1
    end
    local dwPlayerKungfuID = PlayerData.GetPlayerMountKungfuID()
    local tInfo = g_tTable.EquipRecommend:Search(itemInfo.nRecommendID)
    local tIDs = string.split(tInfo.kungfu_ids, "|")
    for i = 1, #tIDs do
        tIDs[i] = tonumber(tIDs[i])
    end
    if item.nSub == EQUIPMENT_SUB.RING and nCount < 2 then
        bShow = true
    end
    local bSameKungfu = table.get_key(tIDs, dwPlayerKungfuID) or (tIDs[1] == 0)
    bShow = itemInfo and itemInfo.nRecommendID > 0 and bSameKungfu and (bShow or (not nMinBaseScore) or nMinBaseScore < item.nBaseScore)

    self.bShowEquipBetterArrow = bShow
    UIHelper.SetVisible(self.ImgWorseArrow, false)
    UIHelper.SetVisible(self.ImgBetterArrow, bShow)
end

function UIItemIcon:OnSelectChanged(bSelected)
    if self.funcSelectChangeCallback then
        if self.bItem then
            self.funcSelectChangeCallback(self.nItemID, bSelected, self.nBox, self.nIndex)
        else
            self.funcSelectChangeCallback(self.nItemID, bSelected, self.nTabType, self.nTabID)
        end
    end
end

function UIItemIcon:OnClick()
    if self.funcClickCallback then
        if UIHelper.GetSelected(self.ToggleSelect) then
            if self.bItem then
                self.funcClickCallback(self.nBox, self.nIndex)
            elseif self.bIsCurrencyType then
                self.funcClickCallback("CurrencyType", self.szCurrencyName)
            elseif self.bRideExterior then
                self.funcClickCallback(self.dwExteriorID, self.bEquip)
            else
                self.funcClickCallback(self.nTabType, self.nTabID, self.bEquip)
            end
        else
            self.funcClickCallback()
        end
    end

    local item = self:GetItem()
    if item and item.nUiId then
        SoundMgr.PlayItemSound(item.nUiId)
    else
        SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Button)
    end
end

function UIItemIcon:OnLongPress()
    if self.funcLongPressCallback then
        if self.bItem then
            self.funcLongPressCallback(self.nBox, self.nIndex)
        elseif self.bIsCurrencyType then
            self.funcLongPressCallback("CurrencyType", self.szCurrencyName)
        else
            self.funcLongPressCallback(self.nTabType, self.nTabID)
        end
    end
end

function UIItemIcon:SetMoneyIcon(nMoney)
    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetMoneyIcon(self.ImgIcon, nMoney)
end

function UIItemIcon:SetToggleGroupIndex(nToggleGroupIndex)
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, nToggleGroupIndex)
    self.nSelectGroupIndex = nToggleGroupIndex
end

function UIItemIcon:SetToggleGroup(toggleGroup)
    if self.ToggleGroup then
        UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.ToggleSelect)
        self.ToggleGroup = nil
    end

    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleSelect)
    self.ToggleGroup = toggleGroup
end

function UIItemIcon:SetSelectMode(bBatch, bHideCheck)
    if self.bBatch and bBatch then
        return
    end

    if not self.bBatch and not bBatch then
        return
    end

    self.bBatch = bBatch
    UIHelper.SetVisible(self.WidgetMultiSelect, bBatch and not bHideCheck)

    if bBatch then
        UIHelper.SetToggleGroupIndex(self.ToggleSelect, -1)
        if UIHelper.GetSelected(self.ToggleSelect) then
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
        if self.ToggleGroup then
            UIHelper.ToggleGroupRemoveToggle(self.ToggleGroup, self.ToggleSelect)
        end
    else
        UIHelper.SetToggleGroupIndex(self.ToggleSelect, self.nSelectGroupIndex)
        if UIHelper.GetSelected(self.ToggleSelect) then
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
        if self.ToggleGroup then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.ToggleSelect)
        end
    end
end

function UIItemIcon:SetEnable(bState)
    if not bState then
        self.ToggleSelect:setEnabled(false)
    else
        self.ToggleSelect:setEnabled(true)
    end

    UIHelper.SetVisible(self.ImgDisabled, not bState)
end

function UIItemIcon:HideButton()
    UIHelper.SetEnable(self.ToggleSelect, false)
end

function UIItemIcon:SetHighlight(bValue)
    UIHelper.SetVisible(self.ImgHighlighted, bValue)
end

function UIItemIcon:SetColor(color)
    UIHelper.SetColor(self.ImgIcon, color)
end

function UIItemIcon:SetRecallCallback(callback, args)
    self.funcRecallCallback = callback
    self.tbRecallCallbackArgs = args
end

function UIItemIcon:SetRecallVisible(bVisible)
    UIHelper.SetVisible(self.BtnRecall, bVisible)
end

function UIItemIcon:SetSkillRecallCallback(callback)
    self.funcSkillRecallCallback = callback
end

function UIItemIcon:SetSkillRecallVisible(bVisible)
    UIHelper.SetVisible(self.BtnRecallSkill, bVisible)
end

function UIItemIcon:SetPlayerID(nPlayerID)
    self.nPlayerID = nPlayerID
end

function UIItemIcon:SetClearSeletedOnCloseAllHoverTips(bClearSeletedOnCloseAllHoverTips)
    self.bClearSeletedOnCloseAllHoverTips = bClearSeletedOnCloseAllHoverTips
end

function UIItemIcon:SetHandleChooseEvent(bHandle)
    self.bHandleChooseEvent = bHandle
end

function UIItemIcon:SetToggleSwallowTouches(bSwallow)
    UIHelper.SetSwallowTouches(self.ToggleSelect, bSwallow)
end

function UIItemIcon:SetNewItemFlag(bNew)
    self.bNewFlag = bNew
    UIHelper.SetVisible(self.Eff_NewItem, bNew)

    if self.bInit then
        local item = self:GetItem()
        self:UpdateCornerFlag(item)
    end

    self:UpdateEquipScoreArrowInfo()
end

function UIItemIcon:EnableTimeLimitFlag(bEnable)
    self.bEnableTimeLimitFlag = bEnable

    if self.bInit then
        local item = self:GetItem()
        self:UpdateCornerFlag(item)
    end
end

local ITEM_LEFT_HOUR = 48
function UIItemIcon:UpdateCornerFlag(item)
    local bTimeLimit = false

    if self.bItem and not self.bNewFlag and item and self.bEnableTimeLimitFlag then
        local nLeftTime = item.GetLeftExistTime()
        local nLeftHour = math.floor(nLeftTime / 3600)
        local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        if tItemInfo and tItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT then
            if nLeftHour < ITEM_LEFT_HOUR then
                bTimeLimit = true
            end
        end
    end

    UIHelper.SetVisible(self.ImgTime, bTimeLimit)

    local bIsTaskItem = item and item.nGenre == ITEM_GENRE.TASK_ITEM
    UIHelper.SetVisible(self.ImgAttri, bIsTaskItem)
    UIHelper.LayoutDoLayout(self.LayoutSign)
end

function UIItemIcon:SetItemQualityBg(nQuality)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[nQuality + 1])
    UIHelper.SetVisible(self.ImgPolishCountBG, true)
    self:UpdateEffect(nQuality)
end

function UIItemIcon:SetTouchDownHideTips(bHideTips)
    UIHelper.SetTouchDownHideTips(self.ToggleSelect, bHideTips)
    UIHelper.SetTouchDownHideTips(self.BtnRecall, bHideTips)
    UIHelper.SetTouchDownHideTips(self.BtnRecallSkill, bHideTips)
end

function UIItemIcon:RegisterTouchEvent(fnTouchBegan, fnTouchMoved, fnTouchEnded, fnTouchCanceled)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchBegan, function(_, x, y)
        fnTouchBegan(self, x, y)
    end)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchMoved, function(_, x, y)
        fnTouchMoved(self, x, y)
    end)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchEnded, function(_, x, y)
        fnTouchEnded(self, x, y)
    end)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchCanceled, function()
        fnTouchCanceled(self)
    end)
end

function UIItemIcon:UnRegisterTouchEvent()
    UIHelper.UnBindUIEvent(self.ToggleSelect, EventType.OnTouchBegan)
    UIHelper.UnBindUIEvent(self.ToggleSelect, EventType.OnTouchMoved)
    UIHelper.UnBindUIEvent(self.ToggleSelect, EventType.OnTouchEnded)
    UIHelper.UnBindUIEvent(self.ToggleSelect, EventType.OnTouchCanceled)
end

function UIItemIcon:UpdateEffect(nQuality)
    UIHelper.SetVisible(self.Eff_Orange, false)
    if nQuality == 5 then
        UIHelper.SetVisible(self.Eff_Orange, true)
    end
end

function UIItemIcon:SetClickNotSelected(bEnable)
    self.bEnabelClickNotSelected = bEnable
    UIHelper.SetVisible(self.WidgetSelectBG, not bEnable)
end

function UIItemIcon:ShowItemTips()
    local function DoShowItemTips()
        if self.bItem then
            TipsHelper.ShowItemTips(self._rootNode, self.nBox, self.nIndex, true)
        else
            TipsHelper.ShowItemTips(self._rootNode, self.nTabType, self.nTabID, false)
        end
    end

    if self.bEnabelClickNotSelected then
        DoShowItemTips()
    else
        if UIHelper.GetSelected(self.ToggleSelect) then
            DoShowItemTips()
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        end
    end
end

function UIItemIcon:SetTogMultiSelected(bBatch)
    UIHelper.SetVisible(self.ToggleMultiSelect, bBatch)
    UIHelper.SetVisible(self.WidgetSelectBG, false)
    UIHelper.SetVisible(self.ImgSelectBG, false)
    if bBatch then
        UIHelper.SetVisible(self.ImgSelectRT, true)
        UIHelper.SetVisible(self.ImgChecke, true)
    else
        UIHelper.SetVisible(self.ImgSelectRT, false)
        UIHelper.SetVisible(self.ImgChecke, false)
    end
end

function UIItemIcon:ShowEmotionCoolDown()
    local dwPlayCDID = 2155
    --local nTotal = g_pClientPlayer.GetCDInterval(dwPlayCDID)
    local nCDLeft = g_pClientPlayer.GetCDLeft(dwPlayCDID)
    if nCDLeft and nCDLeft > 0 then
        local szCooldownText = string.format("%d", math.ceil(nCDLeft / GLOBAL.GAME_FPS))
        UIHelper.SetVisible(self.WidgetCD, true)
        UIHelper.SetString(self.LabelCD, szCooldownText)
    else
        UIHelper.SetVisible(self.WidgetCD, false)
    end
end

function UIItemIcon:ShowLockIcon(bShow)
    UIHelper.SetVisible(self.WidgetLock, bShow)
end

function UIItemIcon:ShowNowIcon(bShow)
    UIHelper.SetVisible(self.ImgNow, bShow)
end

function UIItemIcon:SetNowDesc(szNowDesc)
    UIHelper.SetString(self.LabelNow, szNowDesc)
end

function UIItemIcon:ShowBindIcon(bShow)
    UIHelper.SetVisible(self.WIdgetBind, bShow)
end

function UIItemIcon:SetLongPressDelay(fDelay)
    UIHelper.SetLongPressDelay(self.ToggleSelect, fDelay)
end

function UIItemIcon:SetIconGray(bGray)
    UIHelper.SetNodeGray(self.ImgIcon, bGray, true)
end

function UIItemIcon:SetIconOpacity(nOpacity)
    UIHelper.SetOpacity(self.ImgIcon, nOpacity)
    UIHelper.SetOpacity(self.ImgPolishCountBG, nOpacity)
end

function UIItemIcon:SetItemGray(bGray)
    UIHelper.SetNodeGray(self.ImgIcon, bGray, true)
    UIHelper.SetOpacity(self.ImgIcon, bGray and 120 or 255)
    UIHelper.SetOpacity(self.ImgPolishCountBG, bGray and 120 or 255)
end

function UIItemIcon:SetSpecialLabel(szContent)
    UIHelper.SetVisible(self.WidgetEnchantStatus, true)
    UIHelper.SetString(self.LabelEnchanted, szContent)
end

function UIItemIcon:SetItemReceived(bReceived)
    UIHelper.SetVisible(self.WidgetGot, bReceived)
end

function UIItemIcon:HideChoose()
    UIHelper.SetVisible(self.ImgChooseNum, false)
    UIHelper.SetVisible(self.LabelChooseNum, false)
end

function UIItemIcon:ShowEquipScoreArrow(bShow)
    self.bShowEquipScoreArrow = bShow
    self:UpdateEquipScoreArrowInfo()
end

function UIItemIcon:ShowRecommend(bShow)
    UIHelper.SetVisible(self.ImgRecommend, bShow)
end

function UIItemIcon:SetItemWear(bShow)
    UIHelper.SetVisible(self.ImgWear, bShow)
end

function UIItemIcon:UpdatePVPImg(item, nEquipUsage)
    -- local bCanShowPVP = (item.dwTabType == ITEM_TABLE_TYPE.CUST_WEAPON and item.nSub ~= 13 and item.nSub ~= 16)
    --     or item.dwTabType == ITEM_TABLE_TYPE.CUST_ARMOR
    --     or (item.dwTabType == ITEM_TABLE_TYPE.CUST_TRINKET and (item.nSub == 4 or item.nSub == 5 or item.nSub == 7))
    item = item or self:GetItem()
    UIHelper.SetVisible(self.ImgWeaponMark, false)

    if item then
        local bCanShowPVP = item.nGenre == ITEM_GENRE.EQUIPMENT and (item.nSub >= EQUIPMENT_SUB.MELEE_WEAPON and item.nSub <= EQUIPMENT_SUB.BANGLE)
        nEquipUsage = nEquipUsage or item.nEquipUsage
        if bCanShowPVP then
            if nEquipUsage == 1 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPve.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 0 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvp.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 2 then
                UIHelper.SetSpriteFrame(self.ImgWeaponMark, "UIAtlas2_Public_PublicItem_PublicItem1_MarkPvx.png")
                UIHelper.SetVisible(self.ImgWeaponMark, true)
            elseif nEquipUsage == 3 then
                UIHelper.SetVisible(self.ImgWeaponMark, false)
            end
        end
    end
end

function UIItemIcon:ShowLabelTip(bShow, szTip)
    if self.ImgTipBg and self.LabelTip then
        UIHelper.SetVisible(self.ImgTipBg, bShow)

        if szTip then
            UIHelper.SetString(self.LabelTip, szTip)
        end
    end
end

function UIItemIcon:ClearTeach()
    if self.ToggleSelect and self.ToggleSelect._nTeachID then
        TeachEvent.TeachClose(self.ToggleSelect._nTeachID) --道具刷新时强制结束教学
    end
end

function UIItemIcon:EnableRightTouch(bEnable)
    if Platform.IsWindows() then
        if self.ToggleSelect then
            UIHelper.EnableRightTouch(self.ToggleSelect, bEnable)
        end
    end
end

function UIItemIcon:ClearLongPressState()
    self.bPersistentPress = false
end

function UIItemIcon:OnInitWithCurrencyType(szCurrencyName)
    self:ClearTeach()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.currencyType = CurrencyNameToType[szCurrencyName]
    UIHelper.SetSpriteFrame(self.ImgIcon, CurrencyData.tbImageBigIcon[self.currencyType])
end

function UIItemIcon:SetForbidShowCoolDown(bForbid)
    self.bForbidShowCoolDown = bForbid
end

function UIItemIcon:OnItemIconChoose(bSelected, nBox, nIndex, nCount)
    if not nBox or not nIndex or (nBox == self.nBox and self.nIndex == nIndex) then
        if bSelected then
            UIHelper.SetVisible(self.ImgChooseNum, true)
            if UIHelper.GetVisible(self.LabelCount) then
                UIHelper.SetVisible(self.LabelChooseNum, true)
                if nCount then
                    UIHelper.SetString(self.LabelChooseNum, tostring(nCount))
                else
                    UIHelper.SetString(self.LabelChooseNum, UIHelper.GetString(self.LabelCount))
                end
            end
        else
            UIHelper.SetVisible(self.ImgChooseNum, false)
            UIHelper.SetVisible(self.LabelChooseNum, false)
        end
    end
end

function UIItemIcon:SetCanGet(bCanGet)
    if self.ImgCanGet then
        UIHelper.SetVisible(self.ImgCanGet, bCanGet)
    end
end

function UIItemIcon:ShowClearIcon(szImgPath)
    UIHelper.SetVisible(self.ImgEmptyBG, false)
    UIHelper.SetVisible(self.ImgPolishCountBG, false)
    UIHelper.SetVisible(self.ImgBlack, false)
    UIHelper.SetVisible(self.ImgItemMask, false)
    UIHelper.SetVisible(self.LabelCount, false)
    UIHelper.SetTexture(self.ImgIcon, szImgPath, true)
end

return UIItemIcon
