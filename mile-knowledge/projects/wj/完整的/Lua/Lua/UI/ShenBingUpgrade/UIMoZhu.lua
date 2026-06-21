
local UIMoZhu = class("UIMoZhu")

local function FindLevelUp(dwTabType, dwIndex)
    local hPlayer = GetClientPlayer()
    local nCount = #ItemData.BoxSet.Bag
    local tRet = {}
    for i = 1, nCount do
        local dwBox = BagIndexToInventoryIndex(i)
        local dwSize = hPlayer.GetBoxSize(dwBox)

        for dwX = 0, dwSize - 1 do
            local tItem = GetPlayerItem(hPlayer, dwBox, dwX)
            if tItem and tItem.dwTabType == dwTabType and tItem.dwIndex == dwIndex then
                table.insert(tRet, {dwBox, dwX})
            end
        end
    end
    return tRet
end

local tTempMozhuInfo = {
    nKungfu = 0,
    nLevel = 0,
    tCurrEquip = {
        dwTabType = 0,
        dwIndex = 0,
        dwBox = 0,
        dwX = 0,
    },
    tLevelUpEquip = {
        dwTabType = 0,
        dwIndex = 0,
        dwBox = 0,
        dwX = 0,
    },
    tTargetEquip = {
        dwTabType = 0,
        dwIndex = 0,
    },
    tLevelUpList = {},
    tTargetList = {},
}

local RES_TYPE = {
    SUCCESS = 0,
    RESET = 1,
    RESET_LEVEL = 2,
    FAIL = 3,
}

local fnIsHaveItem = function(dwTabType, dwIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    local dwBox, dwX = hPlayer.GetItemPos(dwTabType, dwIndex)
    if dwBox and dwX then
        return true
    end
    return false
end

local function GetKungfuInfo()
    local tList = {}
	local player = GetClientPlayer()
	local aSchool = player.GetSchoolList()
	local dwForceID = player.dwForceID
	for k, v in pairs(aSchool) do
		local aKungfu = player.GetKungfuList(v)
		for dwID, dwLevel in pairs(aKungfu) do
			if Table_IsSkillShow(dwID, dwLevel) then
				local skill = GetSkill(dwID, dwLevel)
				if skill and skill.nUIType == 2 and 
                    skill.nPlatformType == SKILL_PLATFORM_TYPE.MOBILE then
                    local tSkillInfo = Table_GetSkill(dwID, dwLevel)
                    if Kungfu_GetType(dwID) == dwForceID then
                        table.insert(tList, {dwID, dwLevel, dwHDKungfuID, 0, tSkillInfo.szName})
                    elseif IsNoneSchoolKungfu(dwID) then
                        table.insert(tList, {dwID, dwLevel, dwHDKungfuID, 0, tSkillInfo.szName})
                    end
				end
			end
		end
	end
    return tList
end

function UIMoZhu:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tMozhuInfo = clone(tTempMozhuInfo)
    self.bLock = false
    self.TargetIcon = nil
    self:UpdateView()
end

function UIMoZhu:OnExit()
    self.bInit = false
    self.TargetIcon = nil
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
end

function UIMoZhu:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSchoolList, EventType.OnSelectChanged, function(toggle, bState)
        if bState then
            self:UpdateSchoolList()
        end
    end)

    UIHelper.BindUIEvent(self.tCurrent[1], EventType.OnClick, function()
        self:ShowCurrentRightBag()
    end)
    UIHelper.BindUIEvent(self.tLevelUp[1], EventType.OnClick, function()
        if self.tMozhuInfo.nKungfu == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.MOZHU_CHOOSE_KUNGFU_ERROR)
            return
        end
        self:ShowLevelUpRightBag()
    end)
    UIHelper.BindUIEvent(self.tTarget[1], EventType.OnClick, function()
        if self.tMozhuInfo.tCurrEquip.dwTabType == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.MOZHU_TARGET_EQUIP_EMPTY)
            return
        end
        self:ShowTargetRightBag()
    end)
    UIHelper.BindUIEvent(self.BtnMoZhu, EventType.OnClick, function()
        if self.bLock then
            return
        end
        local szMsg = g_tStrings.MOZHU_CONFIRM
        if fnIsHaveItem(self.tMozhuInfo.tTargetEquip.dwTabType, self.tMozhuInfo.tTargetEquip.dwIndex) then
            szMsg = g_tStrings.MOZHU_HAVE_TIPS
        end
        UIHelper.ShowConfirm(szMsg, function()
            local bUseLevelUp, tCurEquip, tTargetEquip, tLevelUpEquip = self:GetMozhuRemoteVal()
            RemoteCallToServer("On_EquipCopy_Confirm", bUseLevelUp, tCurEquip, tTargetEquip, tLevelUpEquip, self.tMozhuInfo.nKungfu)
            self.bLock = true
        end)
    end)

end

function UIMoZhu:RegEvent()
    Event.Reg(self, "REMOTE_EQUIP_COPY_RES", function (nResType, tTarget)
        if tTarget and tTarget[1] == self.tMozhuInfo.tTargetEquip.dwTabType and tTarget[2] == self.tMozhuInfo.tTargetEquip.dwIndex then
            self.bLock = false
            if nResType == RES_TYPE.SUCCESS or nResType == RES_TYPE.RESET then
                local nOldKungfu = self.tMozhuInfo.nKungfu
                local nOldLevel = self.tMozhuInfo.nLevel
                self.tMozhuInfo = clone(tTempMozhuInfo)
                self.tMozhuInfo.nKungfu = nOldKungfu
                self.tMozhuInfo.nLevel = nOldLevel
            end
            if nResType == RES_TYPE.RESET_LEVEL then
                self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
                self.tMozhuInfo.tLevelUpEquip.dwIndex = 0
            end
            if nResType == RES_TYPE.SUCCESS then
                self:SetSchool()
                self:UpdateLevelUpHint()
                self:UpdateLevelUp(0)
                self:UpdateCurrent(0)
                self:UpdateSuccess()
            elseif nResType == RES_TYPE.RESET or nResType == RES_TYPE.RESET_LEVEL then
                self:UpdateView()
            end
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        Timer.AddFrame(self, 5, function()
            local childrens = UIHelper.GetChildren(self.LabelGold)
            local fSumWidth = 0
            for _, children in ipairs(childrens) do
                local fWidth = UIHelper.GetWidth(children)
                fSumWidth = fSumWidth + fWidth
            end
            UIHelper.SetWidth(self.LabelGold, fSumWidth)
            UIHelper.LayoutDoLayout(self.WidgetGold)
            UIHelper.LayoutDoLayout(self.LayoutInfo)   
        end)
    end)
end

function UIMoZhu:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMoZhu:UpdateView()
    self:UpdateBg()
    self:UpdateLevelUpHint()
    self:SetSchool()
    self:UpdateCurrent(self.tMozhuInfo.tCurrEquip.dwTabType, self.tMozhuInfo.tCurrEquip.dwIndex, self.tMozhuInfo.tCurrEquip.dwBox, self.tMozhuInfo.tCurrEquip.dwX)
    self:UpdateLevelUp(self.tMozhuInfo.tLevelUpEquip.dwTabType, self.tMozhuInfo.tLevelUpEquip.dwIndex, self.tMozhuInfo.tLevelUpEquip.dwBox, self.tMozhuInfo.tLevelUpEquip.dwX)
    self:UpdateTarget(self.tMozhuInfo.tTargetEquip.dwTabType, self.tMozhuInfo.tTargetEquip.dwIndex)
    self:UpdateMozhuComfirmBtn()
end

function UIMoZhu:UpdateSchoolList()
    local tList = SkillData.GetKungFuList(true)
    UIHelper.RemoveAllChildren(self.WidgetSimpleFilterTipShell)
    for k, v in ipairs(tList) do
        local single =  UIHelper.AddPrefab(PREFAB_ID.WidgetTogSchool , self.WidgetSimpleFilterTipShell)
        UIHelper.SetString(single.LabelTogName , UIHelper.GBKToUTF8(Table_GetSkillName(v[1], v[2]) or ""))
        UIHelper.SetSpriteFrame(single.ImgType, PlayerKungfuImg[v[1]])
        single.TogType.dwID = v[1]
        single.TogType.dwLevel = v[2]
        UIHelper.BindUIEvent(single.TogType , EventType.OnSelectChanged , function (toggle, bState)
            if bState then
                self.tMozhuInfo.nKungfu = toggle.dwID
                self.tMozhuInfo.nLevel = toggle.dwLevel
                self.tMozhuInfo.tTargetEquip.dwTabType = 0
                self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
                self:AutoSelectTarget()
                self:UpdateView()
                UIHelper.SetSelected(self.TogSchoolList, false, false)
            end
        end)
        UIHelper.SetSelected(single.TogType, single.TogType.dwID == self.tMozhuInfo.nKungfu, false)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, single.TogType)
    end
    UIHelper.LayoutDoLayout(self.WidgetSimpleFilterTipShell)
    UIHelper.SetToggleGroupSelected(self.ToggleGroup , 1)
end

function UIMoZhu:SetSchool()
    local dwID = self.tMozhuInfo.nKungfu
    local dwLevel = self.tMozhuInfo.nLevel
    UIHelper.SetVisible(self.ImgIcon, self.tMozhuInfo.nKungfu ~= 0)
    local szKungfuName = g_tStrings.MOZHU_CHOOSE_KUNGFU
    if self.tMozhuInfo.nKungfu ~= 0 then
        szKungfuName = UIHelper.GBKToUTF8(Table_GetSkillName(dwID, dwLevel) or "")
    end
    local LabName = self.LabelContent
    UIHelper.SetString(LabName, szKungfuName)
    UIHelper.SetSpriteFrame(self.ImgIcon, PlayerKungfuImg[dwID])
end

function UIMoZhu:UpdateEnchant(tImg, tbAttribInfos, item)
    for k, v in ipairs(tImg) do
        UIHelper.SetVisible(v, false)
    end
    if not tbAttribInfos then
        return
    end

    for i = 1, 2 do
        local tInfo = tbAttribInfos[i]
        if item.nSub == EQUIPMENT_SUB.PANTS and i == 2 then
            tInfo = nil --下装裤子不显示第二个附魔槽位
        end
        local bMatchSub = (item.nSub == EQUIPMENT_SUB.HELM or item.nSub == EQUIPMENT_SUB.CHEST or item.nSub == EQUIPMENT_SUB.WAIST
                or item.nSub == EQUIPMENT_SUB.BANGLE or item.nSub == EQUIPMENT_SUB.BOOTS)
        local bUsage = item.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVE_EQUIP or item.nEquipUsage == EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP -- PVP也有大附魔
        local bMatchLevel = item.nLevel >= 5600
        if i == 2 and bMatchSub and bMatchLevel and bUsage and tInfo == nil then
            tInfo = {
                szEnchantIconImg = "UIAtlas2_Character_Character2_img_Enchant_Empty.png",
                szAttr = g_tStrings.ITEM_TIP_NO_ENCHANT_PERMANENT,
                bActived = false,
            } -- 显示大附魔槽位
        end
        if tInfo then
            local szIconImg = tInfo.szEnchantIconImg
            UIHelper.SetSpriteFrame(tImg[i], szIconImg)
            UIHelper.SetVisible(tImg[i], true)
        end
    end
end

function UIMoZhu:UpdateCurrent(dwTabType, dwIndex, dwBox, dwX)
    UIHelper.RemoveAllChildren(self.tCurrent[3])
    if dwTabType == 0 then
        UIHelper.SetVisible(self.tCurrent[2], false)
        return
    end
    local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tCurrent[3]) 
    widgetItem:OnInit(dwBox, dwX)
    widgetItem:SetRecallCallback(function()
        self.tMozhuInfo.tCurrEquip.dwTabType = 0
        self.tMozhuInfo.tCurrEquip.dwIndex = 0
        self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
        self.tMozhuInfo.tLevelUpEquip.dwIndex = 0
        self.tMozhuInfo.tTargetEquip.dwTabType = 0
        self.tMozhuInfo.tTargetEquip.dwIndex = 0
        self.tMozhuInfo.tLevelUpList = {}
        self.tMozhuInfo.tTargetList = {}
        self:UpdateView()
    end)
    widgetItem:SetRecallVisible(true)
    widgetItem:SetClickCallback(function()
        self:ShowCurrentRightBag()
        if UIHelper.GetSelected(widgetItem.ToggleSelect) then
            UIHelper.SetSelected(widgetItem.ToggleSelect, false)
        end
    end)
    widgetItem:HideLabelCount()
    local item = PlayerData.GetPlayerItem(g_pClientPlayer, dwBox, dwX)
    if item then
        UIHelper.SetVisible(self.tCurrent[2], true)
        UIHelper.SetString(self.tCurrent[2], UIHelper.GBKToUTF8(item.szName))
        widgetItem:SetSpecialLabel(item.nLevel)
    end
end

function UIMoZhu:UpdateLevelUp(dwTabType, dwIndex, dwBox, dwX)
    UIHelper.RemoveAllChildren(self.tLevelUp[3])
    if dwTabType == 0 then
        UIHelper.SetVisible(self.tLevelUp[2], false)
        self:UpdateEnchant(self.tLevelUpEnchant, nil)
        return
    end
    local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tLevelUp[3])
    widgetItem:OnInit(dwBox, dwX)
    widgetItem:SetRecallCallback(function()
        self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
        self.tMozhuInfo.tLevelUpEquip.dwIndex = 0
        self:UpdateView()
    end)
    widgetItem:SetRecallVisible(true)
    widgetItem:SetClickCallback(function()
        self:ShowLevelUpRightBag()
        if UIHelper.GetSelected(widgetItem.ToggleSelect) then
            UIHelper.SetSelected(widgetItem.ToggleSelect, false)
        end
    end)
    widgetItem:HideLabelCount()
    local item = PlayerData.GetPlayerItem(g_pClientPlayer, dwBox, dwX)
    if item then
        UIHelper.SetVisible(self.tLevelUp[2], true) 
        UIHelper.SetString(self.tLevelUp[2], UIHelper.GBKToUTF8(item.szName))   
        widgetItem:SetSpecialLabel(item.nLevel)
        local tbAttribInfos, nNeedUpdate = EquipData.GetEnchantAttribTip(item)
        self:UpdateEnchant(self.tLevelUpEnchant, tbAttribInfos, item)
    else
        self:UpdateEnchant(self.tLevelUpEnchant, nil)
    end
end

function UIMoZhu:UpdateTarget(dwTabType, dwIndex)
    UIHelper.RemoveAllChildren(self.tTarget[3])
    if dwTabType == 0 then
        UIHelper.SetVisible(self.tTarget[2], false)
        self:UpdateEnchant(self.tTargetEnchant, nil)
        return
    end
    local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tTarget[3])
    self.TargetIcon = widgetItem
    widgetItem:OnInitWithTabID(dwTabType, dwIndex)
    widgetItem:SetItemGray(not fnIsHaveItem(dwTabType, dwIndex))
    widgetItem:SetRecallCallback(function()
        self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
        self.tMozhuInfo.tLevelUpEquip.dwIndex = 0
        self.tMozhuInfo.tTargetEquip.dwTabType = 0
        self.tMozhuInfo.tTargetEquip.dwIndex = 0
        self:UpdateView()
    end)
    widgetItem:SetRecallVisible(true)
    widgetItem:SetClickCallback(function()
        self:ShowTargetRightBag()
        if UIHelper.GetSelected(widgetItem.ToggleSelect) then
            UIHelper.SetSelected(widgetItem.ToggleSelect, false)
        end
    end)
    widgetItem:HideLabelCount()
    local item = ItemData.GetItemInfo(dwTabType, dwIndex)
    if item then
        UIHelper.SetVisible(self.tTarget[2], true) 
        UIHelper.SetString(self.tTarget[2], UIHelper.GBKToUTF8(item.szName))   
        widgetItem:SetSpecialLabel(item.nLevel)
    end
    if self.tMozhuInfo.tLevelUpEquip.dwTabType > 0 then
        local levelupitem = PlayerData.GetPlayerItem(g_pClientPlayer, self.tMozhuInfo.tLevelUpEquip.dwBox, self.tMozhuInfo.tLevelUpEquip.dwX)
        if levelupitem then
            local tbAttribInfos, nNeedUpdate = EquipData.GetEnchantAttribTip(levelupitem)
            self:UpdateEnchant(self.tTargetEnchant, tbAttribInfos, levelupitem)
        else
            self:UpdateEnchant(self.tTargetEnchant, nil)
        end
    else
        self:UpdateEnchant(self.tTargetEnchant, nil)
    end
end

function UIMoZhu:UpdateEquipment(szType, dwTabType, dwIndex, dwBox, dwX)
    if szType == "Current" then
        self.tMozhuInfo.tCurrEquip.dwTabType = dwTabType
        self.tMozhuInfo.tCurrEquip.dwIndex = dwIndex
        self.tMozhuInfo.tCurrEquip.dwBox = dwBox
        self.tMozhuInfo.tCurrEquip.dwX = dwX
        self.tMozhuInfo.tTargetEquip.dwTabType = 0
        self.tMozhuInfo.tLevelUpEquip.dwTabType = 0
        self:AutoSelectTarget()
        self:UpdateView()
    elseif szType == "LevelUp" then
        self.tMozhuInfo.tLevelUpEquip.dwTabType = dwTabType
        self.tMozhuInfo.tLevelUpEquip.dwIndex = dwIndex
        self.tMozhuInfo.tLevelUpEquip.dwBox = dwBox
        self.tMozhuInfo.tLevelUpEquip.dwX = dwX
        self:UpdateView()
    elseif szType == "Target" then
        self.tMozhuInfo.tTargetEquip.dwTabType = dwTabType
        self.tMozhuInfo.tTargetEquip.dwIndex = dwIndex
        self:UpdateView()
    end
end

function UIMoZhu:ShowCurrentRightBag()
    local tList = {}
    for i = 0, EQUIPMENT_INVENTORY.TOTAL - 1 do
        local item = PlayerData.GetPlayerItem(GetClientPlayer(), INVENTORY_INDEX.EQUIP, i)
        if item then
            local bCanCopy = GDAPI_CheckIfCanCopy(item.dwTabType, item.dwIndex)
            if bCanCopy then
                table.insert(tList, {nType = i, dwTabType = item.dwTabType, dwIndex = item.dwIndex, dwBox = INVENTORY_INDEX.EQUIP, dwX = i})
            end
        end
    end
    local script = UIMgr.Open(VIEW_ID.PanelMoZhuRightBag, "Current", tList)
end

function UIMoZhu:ShowLevelUpRightBag()
    local tList = self:GetLevelUpItemInPackage()
    local script = UIMgr.Open(VIEW_ID.PanelMoZhuRightBag, "LevelUp", tList)
end

function UIMoZhu:ShowTargetRightBag()
    local tList = {}
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return 
    end
    for k, v in ipairs(self.tMozhuInfo.tTargetList) do
        table.insert(tList, {dwTabType = v[1], dwIndex = v[2]})
    end
    local script = UIMgr.Open(VIEW_ID.PanelMoZhuRightBag, "Target", tList)
end

function UIMoZhu:GetMozhuRemoteVal()
    local bUseLevelUp = false
    local tCurr = self.tMozhuInfo.tCurrEquip
    local tCurEquip = {tCurr.dwTabType, tCurr.dwIndex, tCurr.dwBox, tCurr.dwX}
    local tTarget = self.tMozhuInfo.tTargetEquip
    local tTargetEquip = {tTarget.dwTabType, tTarget.dwIndex}
    local tLevelUp = self.tMozhuInfo.tLevelUpEquip
    local tLevelUpEquip = nil
    if tLevelUp.dwTabType > 0 then
        tLevelUpEquip = {tLevelUp.dwTabType, tLevelUp.dwIndex, tLevelUp.dwBox, tLevelUp.dwX}
        bUseLevelUp = true
    end
    return bUseLevelUp, tCurEquip, tTargetEquip, tLevelUpEquip
end

function UIMoZhu:UpdateMozhuComfirmBtn()
    local bEnable = self.tMozhuInfo.nKungfu > 0 and 
    self.tMozhuInfo.tTargetEquip.dwTabType > 0 and
    self.tMozhuInfo.tCurrEquip.dwTabType > 0

    UIHelper.SetButtonState(self.BtnMoZhu, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetVisible(self.WidgetHint, not bEnable)
    UIHelper.SetVisible(self.WidgetGold, bEnable)
    UIHelper.SetVisible(self.WidgetWeiMing, bEnable)
    UIHelper.SetVisible(self.RichTextSuccess, false)
    
    if bEnable then
        local bUseLevelUp, tCurEquip, tTargetEquip, tLevelUpEquip = self:GetMozhuRemoteVal()
        local nPrice, nPrestige = GDAPI_GetEquipCopyBill(tCurEquip, tTargetEquip, tLevelUpEquip)
        local nMoney = GoldSilverAndCopperToMoney64(0, 0, nPrice)
        UIHelper.SetString(self.LabelGold, "")
        UIHelper.SetMoneyText(self.LabelGold, nMoney, 20, false, "消耗金钱：")
        UIHelper.SetString(self.LabelWeiMing, nPrestige)
        UIHelper.WidgetFoceDoAlignAssignNode(self, self.ImgInitial)
    end
    UIHelper.LayoutDoLayout(self.LayoutInfo)
end

function UIMoZhu:UpdateBg()
    UIHelper.SetVisible(self.ImgArrowBg, #self.tMozhuInfo.tLevelUpList == 0)
    UIHelper.SetVisible(self.ImgArrow2Bg, #self.tMozhuInfo.tLevelUpList > 0)
    UIHelper.SetVisible(self.ImgArrow1, self.tMozhuInfo.tLevelUpEquip.dwTabType == 0 and self.tMozhuInfo.tTargetEquip.dwTabType > 0)
    UIHelper.SetVisible(self.ImgArrow2, self.tMozhuInfo.tLevelUpEquip.dwTabType > 0)
    UIHelper.SetVisible(self.WidgetMiddle, #self.tMozhuInfo.tLevelUpList > 0)
end

function UIMoZhu:UpdateLevelUpHint()
    local tList = self:GetLevelUpItemInPackage()
    UIHelper.SetVisible(self.WidgetXiaoHaoHint, #self.tMozhuInfo.tLevelUpList > 0 and #tList > 0)
end

function UIMoZhu:UpdateSuccess()
    UIHelper.SetVisible(self.RichTextSuccess, true)
    UIHelper.SetVisible(self.WidgetGold, false)
    UIHelper.SetVisible(self.WidgetWeiMing, false)
    UIHelper.LayoutDoLayout(self.LayoutInfo)
    UIHelper.SetButtonState(self.BtnMoZhu, BTN_STATE.Disable)
    UIHelper.SetVisible(self.ImgArrow1, false)
    UIHelper.SetVisible(self.ImgArrow2, false)
    if self.TargetIcon then
        self.TargetIcon:SetItemGray(false)
    end
end

function UIMoZhu:AutoSelectTarget()
    if self.tMozhuInfo.tCurrEquip.dwTabType == 0 or self.tMozhuInfo.nKungfu == 0 then
        return
    end
    local tTargetList, tLevelUpList = GDAPI_GetEquipCopyTarget(
    self.tMozhuInfo.tCurrEquip.dwTabType, self.tMozhuInfo.tCurrEquip.dwIndex, self.tMozhuInfo.nKungfu)
    self.tMozhuInfo.tLevelUpList = tLevelUpList or {}
    self.tMozhuInfo.tTargetList = tTargetList or {}
    if #tTargetList > 0 then
        self.tMozhuInfo.tTargetEquip.dwTabType = tTargetList[1][1]
        self.tMozhuInfo.tTargetEquip.dwIndex = tTargetList[1][2]
    end
end

function UIMoZhu:GetLevelUpItemInPackage()
    local tList = {}
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return tList
    end
    for k, v in ipairs(self.tMozhuInfo.tLevelUpList) do
        local nHaveItem = pPlayer.GetItemAmountInPackage(v[1], v[2])
        if nHaveItem > 0 then
            local tRes = FindLevelUp(v[1], v[2])
            for kk, vv in ipairs(tRes) do
                table.insert(tList, {dwTabType = v[1], dwIndex = v[2], dwBox = vv[1], dwX = vv[2]})
            end
        end
    end
    return tList
end

return UIMoZhu