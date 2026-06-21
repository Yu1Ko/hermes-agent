-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOtherCharacterRidePage
-- Date: 2023-03-07 19:58:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOtherCharacterRidePage = class("UIOtherCharacterRidePage")

function UIOtherCharacterRidePage:OnEnter(nPlayerID, nCenterID, szGlobalRoleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerID = nPlayerID
    self.nCenterID = nCenterID
    self.szGlobalRoleID = szGlobalRoleID

    self:UpdateInfo()
end

function UIOtherCharacterRidePage:OnExit()
    self.bInit = false
end

function UIOtherCharacterRidePage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelpIcon,EventType.OnClick,function ()
        if not UIMgr.GetView(VIEW_ID.PanelAttributeAtlas) then
            UIMgr.Open(VIEW_ID.PanelAttributeAtlas)
        end
    end)
end

function UIOtherCharacterRidePage:RegEvent()
    Event.Reg(self, "PEEK_PLAYER_EXTERIOR", function()
        self:UpdateInfo()
    end)
end

function UIOtherCharacterRidePage:UpdateInfo()
    local player = self:GetPlayer()
    if not player then return end

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(player.szName))

    local item = player.GetEquippedHorse()
    if item then
        local szRideName = ItemData.GetItemNameByItem(item)
        UIHelper.SetString(self.LabelRideName, UIHelper.GBKToUTF8(szRideName))
        UIHelper.SetString(self.LabelTroughHarness, UIHelper.GBKToUTF8(szRideName))
        UIHelper.SetVisible(self.ImgBgRide, true)
        UIHelper.SetVisible(self.WidgetAnchorHorseTips, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)

        self:UpdateHorseAttribute(item, false)
        self:UpdateHorseEquip()
        self:UpdateExterior()
    else
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetAnchorHorseTips, false)
        UIHelper.SetVisible(self.ImgBgRide, false)
    end
end

local function FromHMagicInfo_To_HSkill_ID_lv(dwMagicID, dwValue1, dwValue2,nRepresentID)
	local dwHSkillID
	local dwHSkilllv
	local dwHSkillValue

	if dwMagicID == ATTRIBUTE_TYPE.HORSE_ATTRIBUTE then
		--坐骑卡槽属性
		dwHSkillID = math.floor(dwValue2 / 1000)
		dwHSkilllv = math.floor(dwValue2 % 1000)
		if dwHSkillID == 4 or dwHSkillID == 5 or dwHSkillID == 6 or dwHSkillID == 12 or dwHSkillID == 13 or dwHSkillID == 29 then
			dwHSkilllv = 0
		end
	end
	--============================================================================================
	if dwMagicID == ATTRIBUTE_TYPE.MOVE_SPEED_PERCENT then
		--坐骑速度属性
		dwHSkillID = 1
		dwHSkilllv = math.floor(dwValue1 * 5 / 256 - 11 + 0.5)
		dwHSkillValue = math.floor(dwValue1 * 100 / 1024 + 0.5)
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end
	if dwMagicID == ATTRIBUTE_TYPE.ENABLE_DOUBLE_RIDE then
		--atEnableDoubleRide
		--能否双人同骑，value1值应该为1，value2没意义
		dwHSkillID = 3
		dwHSkilllv = 0
	end
	if dwMagicID == ATTRIBUTE_TYPE.HORSE_CAN_SWIM then
		--atHorseCanSwim
		--能否能凫水，value1值应该为1，value2没意义
		dwHSkillID = 2
		dwHSkilllv = 0
	end
	--============================================================================================
	if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_MAX then
		--atAddHorseSprintPowerMax
		--增加马术气力值最大值，value1增加的值，value2没意义
		--气力值属性最终值需除以100来还原。
		dwHSkillID = 7
		dwHSkilllv = math.floor((dwValue1 / 100 - 8) / 16)
		dwHSkillValue = math.floor(dwValue1 / 100)
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end
	if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_COST then
		--atAddHorseSprintPowerCost
		--增加马术气力值每帧消耗速率，value1增加的值，value2没意义
		--气力值属性最终值需除以100来还原。
		dwHSkillID = 9
		dwHSkilllv = math.abs(math.floor(dwValue1 * 16 / 100))
		dwHSkillValue = math.abs(math.floor(dwValue1 * 16 / 100))
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end
	if dwMagicID == ATTRIBUTE_TYPE.ADD_HORSE_SPRINT_POWER_REVIVE then
		--atAddHorseSprintPowerRevive
		--增加马术气力值每帧恢复速率，value1增加的值，value2没意义
		--气力值属性最终值需除以100来还原。
		dwHSkillID = 8
		dwHSkilllv = math.floor(dwValue1 * 16 / 100)
		dwHSkillValue = math.floor(dwValue1 * 16 / 100)
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end

	if dwMagicID == ATTRIBUTE_TYPE.ADD_SPRINT_POWER_REVIVE then
		--atAddSprintPowerRevive
		--轻功气力值恢复速度，value1值应该为1，value2没意义
		dwHSkillID = 10
		dwHSkilllv = math.floor(dwValue1 * 16 / 100)
		dwHSkillValue = math.floor(dwValue1 * 16 / 100)
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end
	if dwMagicID == ATTRIBUTE_TYPE.DROP_DEFENCE then
		-- atDropDefence
		--抗摔伤系数
		dwHSkillID = 11
		dwHSkilllv = math.floor((dwValue1 - 110) / 35)
		dwHSkillValue = dwValue1
		if dwHSkilllv <= 0 then
			dwHSkilllv = 1
		end
	end
	--============================================================================================
	if dwHSkillValue then
		return dwHSkillID, dwHSkilllv, dwHSkillValue
	else
        if dwHSkillID == 14 then
			if nRepresentID == 362 or nRepresentID == 372 then
				dwHSkillID = 48
			end
		end
		return dwHSkillID, dwHSkilllv
	end
end

function UIOtherCharacterRidePage:UpdateHorseAttribute(item, bNotHave)
    if not item then return end

    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetQualityBar, (item.nQuality or 1) + 1)
    if self.scriptQualityBar then
        self.scriptQualityBar:OnEnter((item.nQuality or 1) + 1)
    end

    UIHelper.RemoveAllChildren(self.LayoutSkill)
    self.tAllAttr = {}
    local baseAttib = item.GetBaseAttrib()
    local nRepresentID = item.nRepresentID
    for _, v in pairs(baseAttib) do
		local nID = v.nID
		local nValue1 = v.nValue1 or v.nMin
		local nValue2 = v.nValue2 or v.nMax
		local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
		table.insert(self.tAllAttr, {dwID, dwLevel, nValue})
	end
    local magicAttib
    if not bNotHave then
        magicAttib = item.GetMagicAttrib()
    else
        magicAttib = GetItemMagicAttrib(item.GetMagicAttribIndexList())
    end
    for _, v in pairs(magicAttib) do
        local nID = v.nID
        local nValue1 = v.nValue1 or v.Param0
        local nValue2 = v.nValue2 or v.Param2
        local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
        table.insert(self.tAllAttr, {dwID, dwLevel, nValue})
	end

    local szBaseAttrTips = ""
    for _,tab in ipairs(self.tAllAttr) do
        local dwID, nLevel, nValue = tab[1], tab[2], tab[3]
        local tAttr = Table_GetHorseChildAttr(dwID, nLevel)
        if tAttr and tAttr.nType == 0 then
            tAttr.nValue = nValue
			tAttr.nLevel = nLevel
            if szBaseAttrTips == "" then
                szBaseAttrTips = self:OutputHorseChildAttrTip(tAttr)
            else
                szBaseAttrTips = szBaseAttrTips.."\n"..self:OutputHorseChildAttrTip(tAttr)
            end
        elseif tAttr and tAttr.nType == 1 then
            tAttr.nValue = nValue
			tAttr.nLevel = nLevel
            local szName, szAttrTips = self:OutputHorseChildAttrTip(tAttr,true)
            UIHelper.AddPrefab(PREFAB_ID.WidgetLevelContent,self.LayoutSkill,szName,szAttrTips,tAttr.nIconID)
        end
    end

    UIHelper.SetRichText(self.RichTextBasicAttrib,szBaseAttrTips)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutSkill, true, true)
    local requireAttrib = item.GetRequireAttrib()
    local needLevel
    for _,v in ipairs(requireAttrib) do
        if v.nID == 5 then
            needLevel = v.nValue1
        end
    end
    if bNotHave then
        UIHelper.SetVisible(self.LabelBackgroundStory,true)
        local szDesc = UIHelper.GBKToUTF8(Table_GetItemDesc(item.nUiId))
        szDesc = string.match(szDesc,'\".-\"')
        szDesc = string.gsub(szDesc,'\"',"")
        UIHelper.SetString(self.LabelBackgroundStory,szDesc)
        UIHelper.SetString(self.LabelNeedLevel,"需要等级 1")
    else
        UIHelper.SetVisible(self.LabelBackgroundStory,false)
        UIHelper.SetString(self.LabelNeedLevel,"需要等级 "..needLevel)
        --背包里有的奇趣
        if self.szFilter == "Qiqu" then
            UIHelper.SetVisible(self.LabelBackgroundStory,true)
            local szDesc = UIHelper.GBKToUTF8(Table_GetItemDesc(item.nUiId))
            szDesc = string.match(szDesc,'\".-\"')
            szDesc = string.gsub(szDesc,'\"',"")
            UIHelper.SetString(self.LabelBackgroundStory,szDesc)
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewAtrribute, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewAtrribute)
    UIHelper.ScrollToTop(self.ScrollViewAtrribute)
end

function UIOtherCharacterRidePage:UpdateHorseEquip()
    local player = self:GetPlayer()
	if not player then
		return
	end

    for i = 1, HORSE_ADORNMENT_COUNT do
        local widget = self.tbWidgetHorseEquip[i]
        UIHelper.RemoveAllChildren(widget)

        local dwX = CoinShop_GetRideEquipIndex(i)
        local hItem = player.GetEquippedHorseEquip(dwX)
		if hItem then
            local nType, nIndex = hItem.dwTabType, hItem.dwIndex
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widget)
            scriptItem:SetClearSeletedOnCloseAllHoverTips(true)
	    	scriptItem:OnInitWithTabID(nType, nIndex)
            scriptItem:SetClickCallback(function ()
                scriptItem:ShowItemTips()
            end)
	    end
    end
end

function UIOtherCharacterRidePage:UpdateExterior()
    local player = self:GetPlayer()
	if not player then
		return
	end

    local tInfo = RideExteriorData.GetPlayerRideExterior(player)
    for k, v in pairs(tInfo) do
        local dwExteriorID = v
        local nIndex = RideExteriorData.tLogicIndexToUIIndex[k]
        UIHelper.RemoveAllChildren(self.tExterior[nIndex])
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, not (k == RideExteriorData.HORSE_EXTERIOR_INDEX))
        if tExteriorInfo then
            local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tExterior[nIndex])
            if ItemIcon then
                ItemIcon:OnInitWithRideExterior(dwExteriorID,  k ~= RideExteriorData.HORSE_EXTERIOR_INDEX, true)
            end
            ItemIcon:SetClickCallback(function(dwExteriorID, bEquip)
                local tips, scriptTips = TipsHelper.ShowItemTips(ItemIcon._rootNode)
                scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                scriptTips:SetBtnState({})
                if UIHelper.GetSelected(ItemIcon.ToggleSelect) then
                    UIHelper.SetSelected(ItemIcon.ToggleSelect, false)
                end
            end)
        end
    end
end

function UIOtherCharacterRidePage:OutputHorseChildAttrTip(tAttr,bMagic)
    if not tAttr then return end
    local player = g_pClientPlayer
    if not player then return end
    if not bMagic then
        local szChildTip = UIHelper.GBKToUTF8(FormatString(tAttr.szTip, tAttr.nValue)) or ""
        szChildTip = string.match(szChildTip,'\".-\"')
        szChildTip = string.gsub(szChildTip,'\"',"")
        return szChildTip
    elseif bMagic then
        local szName = UIHelper.GBKToUTF8(tAttr.szName)
        local szChildTip = UIHelper.GBKToUTF8(FormatString(tAttr.szTip, tAttr.nValue)) or ""
        local nLevel = tAttr.nLevel
        szChildTip = string.match(szChildTip,'\".-\"')
        szChildTip = string.gsub(szChildTip,'\"',"")
        return szName..nLevel, szChildTip
    end
end

function UIOtherCharacterRidePage:GetPlayer()
    if self.nPlayerID then
        local player = GetPlayer(self.nPlayerID)
        return player
    end

    if self.szGlobalRoleID then
        local player = GetPlayerByGlobalID(self.szGlobalRoleID)
        return player
    end
end

return UIOtherCharacterRidePage