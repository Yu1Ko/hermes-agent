local UIWuWeiJuePop = class("UIWuWeiJuePop");

local PUBLIC_GROUP = 6

local PERSON = 1
local GLOBAL = 2

local TEMPORARY_ENCHANT_SLOT = 10

local CJ_KUNG_FU = {
    100725,
}

function UIWuWeiJuePop:OnEnter()
    self:BindUIEvent()
    self:InitData()
    
    self:InitConfig()
    self:InitKungfu()

    self:UpdateType()
    self:UpdateConfig()
    self:UpdateBuff()

    Timer.AddCycle(self, 1, function()
        self:UpdateBuff()
    end)
end

function UIWuWeiJuePop:OnExit()
end

function UIWuWeiJuePop:GetName()
    local szType = self.nType == PERSON and "五味诀配置" or "宴席配置"
    return self.KungfuList[self.nKungfuIndex].szName .. szType
end

local function WidgetIndexToDataIndex(nDataIndex)
    if nDataIndex > 10 then
        return nDataIndex - 10 + 100
    end
    return nDataIndex
end

function UIWuWeiJuePop:SortItemList(tbItemList, tbCount, tRecommend)
    table.sort(tbItemList, function(l, r)
        if not tRecommend[l.dwIndex] ~= not tRecommend[r.dwIndex] then
            return tRecommend[l.dwIndex]
        end
        if not tbCount[l.dwIndex] ~= not tbCount[r.dwIndex] then
            return tbCount[l.dwIndex]
        end
        return l.dwID < r.dwID
    end)
end

function UIWuWeiJuePop:BindUIEvent()
    Event.Reg(self, "BUFF_UPDATE", function()
        self:UpdateBuff(self.nType == GLOBAL)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm("是否一键使用已配置的物品？\n</c><color=#FFE26E>(效果大于30分钟时不可叠加)</c><color=#e5e5e5>", function()
            ItemData.FastEnchanting(self.tbData[self.nType][self.nConfigIndex], self.nKungfuSkillID)
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function(btn)
        self:ShareEnchantingToChat()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function(btn)
        -- TODO
        local szName = self.tbData[self.nType][self.nConfigIndex].szName or self:GetName()
        local szDesc = self.tbData[self.nType][self.nConfigIndex].szDesc or ""
        local script = UIMgr.Open(VIEW_ID.PanelSaveWuweijuePop)
        script:SetPlaceHolder(szName, szDesc)
        script:SetDefaultString(szName, szDesc)
        script:SetBtnConfirmFunc(function(szName, szDesc)
            if szName then
                self.tbData[self.nType][self.nConfigIndex].szName = szName
                self.tbData[self.nType][self.nConfigIndex].szDesc = szDesc
                self.bSlotChanged = false
                self:SaveConfig(self.nConfigIndex)
                self:UpdateButtonState()
                TipsHelper.ShowNormalTip("预设方案设置成功")
            end
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh1, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm("是否重置当前配置？", function()
            self.tbData[self.nType][self.nConfigIndex] = {}
            self:UpdateConfig(self.nConfigIndex)
            self:UpdateButtonState()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh2, EventType.OnClick, function(btn)
        UIHelper.ShowConfirm("是否重置当前配置？", function()
            self.tbData[self.nType][self.nConfigIndex] = {}
            self:UpdateConfig(self.nConfigIndex)
            self:UpdateButtonState()
        end)
    end)

    for i, button in ipairs(self.tbItemButtons) do
        UIHelper.BindUIEvent(button, EventType.OnClick, function(btn)
            self:OpenItemSelectPanel(i, button)
        end)
    end

    for i, button in ipairs(self.tbConfigDetailButtons) do
        UIHelper.BindUIEvent(button, EventType.OnClick, function(_)
            local tbConfig = self.tbData[self.nType][i] or {}
            local szText = tbConfig.szName or self:GetName()
            local szDesc = tbConfig.szDesc or ""

            if szDesc ~= "" then
                szText = szText .. "\n" .. szDesc
            end
            
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, button, UIHelper.RichTextEscape(szText))
        end)
    end

    UIHelper.BindUIEvent(self.TogSkillConfigurationGroup, EventType.OnSelectChanged, function(_, bSelected)
        UIHelper.SetVisible(self.WidgetKungfuListGroupTip, bSelected)
        if bSelected then
            self:UpdateKungfuList()
        end
    end)

    UIHelper.BindUIEvent(self.TogTabMelee, EventType.OnSelectChanged, function(_, bSelected)
        if self.tbData[self.nType][self.nConfigIndex].bMelee == bSelected then
            return
        end
        self.tbData[self.nType][self.nConfigIndex].bMelee = bSelected
        self.bSlotChanged = true
        self:UpdateButtonState()
    end)

    UIHelper.BindUIEvent(self.TogTabHeavy, EventType.OnSelectChanged, function(_, bSelected)
        if self.tbData[self.nType][self.nConfigIndex].bHeavy == bSelected then
            return
        end
        self.tbData[self.nType][self.nConfigIndex].bHeavy = bSelected
        self.bSlotChanged = true
        self:UpdateButtonState()
    end)

    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetMainContent)
    UIHelper.SetToggleGroupAllowedNoSelection(self.WidgetMainContent, false)
    for i, toggle in ipairs(self.tbConfigWidgets) do
        UIHelper.ToggleGroupAddToggle(self.WidgetMainContent, toggle)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self:UpdateConfig(i)
            end
        end)
    end

    for nWidgetIndex, btn in ipairs(self.tbBuffButtons) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            local nDataIndex = WidgetIndexToDataIndex(nWidgetIndex)
            local tbInfo = self.tBuffInfo[nDataIndex]
            if tbInfo then
                local buff = {
                    dwID = tbInfo.dwID,
                    nLevel = tbInfo.nLevel,
                    nStackNum = tbInfo.nStackNum,
                    nEndFrame = tbInfo.nEndFrame,
                    bShowTime = true,
                    bExpired = false,
                }
                local nX = UIHelper.GetWorldPositionX(btn)
                local nY = UIHelper.GetWorldPositionY(btn)
                local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
                script:UpdatePlayerInfo(g_pClientPlayer.dwID, {buff})
            end
        end)
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetLeftTab)
    UIHelper.SetToggleGroupAllowedNoSelection(self.WidgetLeftTab, false)
    UIHelper.ToggleGroupAddToggle(self.WidgetLeftTab, self.TogPerson)
    UIHelper.BindUIEvent(self.TogPerson, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateType(PERSON)
        end
    end)

    UIHelper.ToggleGroupAddToggle(self.WidgetLeftTab, self.TogTeam)
    UIHelper.BindUIEvent(self.TogTeam, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateType(GLOBAL)
        end
    end)

    Event.Reg(self, "EASY_EATING_SAVE_CONFIG", function(nConfigIndex)
        self:SaveConfig(nConfigIndex)
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nKungfuIndex)
        self:UpdateSlotsCount()
        self:UpdateButtonState()
    end)
end

function UIWuWeiJuePop:InitData()
    local tAllItem = Table_GetEatingQuickItemInfo()

    self.tSlotInfo = {}
    for _, tInfo in ipairs(tAllItem) do
        for _, nSlot in ipairs(tInfo.tSlot) do 
            if not self.tSlotInfo[nSlot] then
                self.tSlotInfo[nSlot] = {}
                self.tSlotInfo[nSlot].tBuff = {}
                self.tSlotInfo[nSlot].tItemList = {}
            end
            self.tSlotInfo[nSlot].nGroup = tInfo.nGroup      
            table.insert(self.tSlotInfo[nSlot].tBuff, tInfo.tShowBuff)
            table.insert(self.tSlotInfo[nSlot].tItemList, {dwTabType = tInfo.dwTabType, dwIndex = tInfo.dwIndex, dwID = tInfo.dwID})
        end
    end

    self.KungfuList = {}
    local tForce = Table_GetForceList()
    for k, dwForceID in ipairs(tForce) do
        local tbKungfu = Table_GetKungFuIDByForce(dwForceID)
        for _, v in ipairs(tbKungfu) do
            local tbSkill = TabHelper.GetDisplaySkill(v.dwKungfuID)
            local szIcon = PlayerKungfuWuImg[v.dwKungfuID] or ""
            local szKungfuName = GBKToUTF8(Table_GetSkillName(dwKungfuID, 1))
            table.insert(self.KungfuList, {dwKungfuID = v.dwKungfuID, szName = tbSkill.szName, szIcon = szIcon})
        end
    end

    local tForceToSchool = Table_GetForceToSchoolList()
    for k, tInfo in pairs(tForceToSchool) do                     -- 兼容流派
        local tKungfu = Table_GetKungFuIDByForce(tInfo.dwForceID)
        if not tKungfu or IsTableEmpty(tKungfu) then
            local dwSchoolID = Table_ForceToSchool(tInfo.dwForceID)
            local tbKungfu = Table_GetKungFuIDBySchool(dwSchoolID)
            for _, v in ipairs(tbKungfu) do
                local tbSkill = TabHelper.GetDisplaySkill(v.dwKungfuID)
                local szIcon = PlayerKungfuWuImg[v.dwKungfuID] or ""
                table.insert(self.KungfuList, {dwKungfuID = v.dwKungfuID, szName = tbSkill.szName, szIcon = szIcon})
            end
        end
    end

    self.tbSlotScripts = {}
end

function UIWuWeiJuePop:GetRecommendItemList(tbItemList)
    local res = {}
    for _, tItem in ipairs(tbItemList) do
        local tKungFu = Table_GetEatingQuickKungFuListByID(tItem.dwID)
        for _, dwKungfu in ipairs(tKungFu) do
            if dwKungfu == self.KungfuList[self.nKungfuIndex].dwKungfuID then
                res[tItem.dwIndex] = tItem.dwTabType
            end
        end
    end
    return res
end

function UIWuWeiJuePop:UpdateBuff(bPublic)
    self.tBuffInfo = {}
    local kPlayer = g_pClientPlayer

    local tbBuff = BuffMgr.GetAllBuff(g_pClientPlayer)
    local tbPlayerBuff = {}

    for _, buff in ipairs(tbBuff) do
        if buff.dwID and buff.dwID > 0 then
            tbPlayerBuff[buff.dwID] = buff
        end
    end

    for nSlot, tInfo in pairs(self.tSlotInfo) do
        if tInfo.nGroup == PUBLIC_GROUP or (not bPublic and tInfo.nGroup ~= PUBLIC_GROUP) then
            for _, v in ipairs(tInfo.tBuff) do
                for _, buff in ipairs(v) do
                    if tbPlayerBuff[buff.dwID] then
                        if buff.nLevel == 0 or buff.nLevel == tbBuff[buff.dwID].nLevel then
                            self.tBuffInfo[nSlot] = tbPlayerBuff[buff.dwID]
                        end
                    end
                end
            end
        end
    end

    for nWidgetIndex, sprite in ipairs(self.tbBuffWidgets) do
        local label = self.tbTimeLabels[nWidgetIndex]
        local nDataIndex = WidgetIndexToDataIndex(nWidgetIndex)
        if self.tBuffInfo[nDataIndex] then

            local tbInfo = self.tBuffInfo[nDataIndex]
            local szIcon = TabHelper.GetBuffIconPath(tbInfo.dwID, tbInfo.nLevel)
            local szPath = szIcon and string.format("Resource/icon/%s", szIcon)

            UIHelper.SetTexture(sprite, szPath, false)

            local nTime  = tbInfo.nEndFrame and BuffMgr.GetLeftFrame(tbInfo) or tbInfo.nLeftTime
            local szTime = tbInfo.nEndFrame and UIHelper.GetHeightestTimeText(nTime, true) or UIHelper.GetTimeHourText(nTime, false)
            UIHelper.SetString(label, szTime)

            UIHelper.SetVisible(sprite, true)
            UIHelper.SetVisible(label, true)
        else
            UIHelper.SetVisible(sprite, false)
            UIHelper.SetVisible(label, false)
        end
    end
    
    -- 附魔
    local item = GetPlayerItem(kPlayer, INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    if item and (item.nSub == EQUIPMENT_SUB.MELEE_WEAPON or item.nSub == EQUIPMENT_SUB.BIG_SWORD) then
        local sprite = self.tbBuffWidgets[TEMPORARY_ENCHANT_SLOT]
        local label = self.tbTimeLabels[TEMPORARY_ENCHANT_SLOT]
        local nTime = item.GetTemporaryEnchantLeftSeconds()
        if nTime ~= 0 then
            local szTime = UIHelper.GetHeightestTimeText(nTime, false)
            UIHelper.SetString(label, szTime)

            UIHelper.SetVisible(sprite, true)
            UIHelper.SetVisible(label, true)
        else
            UIHelper.SetVisible(sprite, false)
            UIHelper.SetVisible(label, false)
        end
    end
end

function UIWuWeiJuePop:InitKungfu()
    self.nKungfuIndex = 1
    local playerKungfu = g_pClientPlayer.GetActualKungfuMount()
    local dwID = playerKungfu.dwSkillID
    local bMobile = IsMobileSkill(dwID)
    self.nKungfuSkillID = bMobile and dwID or GetMobileKungfuID(dwID) or 0
end

function UIWuWeiJuePop:UpdateKungfu(nKungfuIndex)
    local tbData = self.tbData[self.nType][self.nConfigIndex]
    tbData.dwKungfuID = tbData.dwKungfuID or self.nKungfuSkillID
    if not nKungfuIndex then
        for i = 1, #self.KungfuList do
            if self.KungfuList[i].dwKungfuID == tbData.dwKungfuID then
                nKungfuIndex = i
                break
            end
        end
    end
    self.nKungfuIndex = nKungfuIndex or self.nKungfuIndex
    local kungfu = self.KungfuList[self.nKungfuIndex]

    tbData.dwKungfuID = kungfu.dwKungfuID

    UIHelper.SetLabel(self.LabelKungfu, kungfu.szName)

    local szIcon = PlayerKungfuImg[tbData.dwKungfuID] or ""
    UIHelper.SetSpriteFrame(self.ImgKungfu, szIcon)
    
    UIHelper.SetVisible(self.WidgetCangJIan, table.contain_value(CJ_KUNG_FU, tbData.dwKungfuID))

    if tbData.bMelee == nil then
        tbData.bMelee = true
    end
    if tbData.bHeavy == nil then
        tbData.bHeavy = true
    end

    UIHelper.SetSelected(self.TogTabMelee, tbData.bMelee)
    UIHelper.SetSelected(self.TogTabHeavy, tbData.bHeavy)
end

function UIWuWeiJuePop:UpdateType(nType)
    self.nType = nType or self.nType

    UIHelper.SetVisible(self.WidgetPerson, self.nType == PERSON)
    UIHelper.SetVisible(self.WidgetTeam, self.nType == GLOBAL)

    UIHelper.SetVisible(self.WidgetKungfu, self.nType == PERSON)

    self:UpdateConfig(self.nConfigIndex)
    self:UpdateBuff(self.nType == GLOBAL)
end

function UIWuWeiJuePop:UpdateConfig(nConfigIndex)
    self.nConfigIndex = nConfigIndex or self.nConfigIndex

    for i = 1, #self.tbItemWidgets do
        self:UpdateSlot(i)
    end

    self:UpdateKungfu()
    self:UpdateButtonState()
end

function UIWuWeiJuePop:InitConfig()
    self.nType = PERSON
    self.nConfigIndex = 1

    self.tbData = {}
    for i = 1, 2 do
        self.tbData[i] = {}
        for j = 1, 4 do
            self.tbData[i][j] = Storage.FastEnchanting.tbConfig[i] and clone(Storage.FastEnchanting.tbConfig[i][j]) or {}
        end
    end
end

function UIWuWeiJuePop:SaveConfig(nConfigIndex)
    Storage.FastEnchanting.tbConfig[self.nType] = Storage.FastEnchanting.tbConfig[self.nType] or {}
    Storage.FastEnchanting.tbConfig[self.nType][nConfigIndex] = clone(self.tbData[self.nType][nConfigIndex])

    Storage.FastEnchanting.Dirty()
end

function UIWuWeiJuePop:UpdateSlot(nWidgetIndex)
    UIHelper.RemoveAllChildren(self.tbItemWidgets[nWidgetIndex])
    self.tbSlotScripts[nWidgetIndex] = nil

    local nDataIndex = WidgetIndexToDataIndex(nWidgetIndex)

    local data = self.tbData[self.nType][self.nConfigIndex][nDataIndex]
    if not data or not data.dwTabType or not data.dwIndex then
        return
    end

    local widget = self.tbItemWidgets[nWidgetIndex]
    local widgetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.tbItemWidgets[nWidgetIndex])
	widgetScript:OnInitWithTabID(data.dwTabType, data.dwIndex)
    widgetScript:SetClickNotSelected(true)
    widgetScript:SetClickCallback(function()
        local nStackNum = ItemData.GetItemAmountInPackage(data.dwTabType, data.dwIndex)
        local tips, itemTipScript = TipsHelper.ShowItemTips(widgetScript._rootNode, data.dwTabType, data.dwIndex, false)
        local tbBtnState = {
            {
                szName = "替换",
                bNormalBtn = true,
                OnClick = function()
                    self:OpenItemSelectPanel(nWidgetIndex, widget)
                end
            },
            {
                szName = "卸下",
                bNormalBtn = true,
                OnClick = function()
                    self.tbData[self.nType][self.nConfigIndex][nDataIndex] = nil
                    self.bSlotChanged = true
                    self:UpdateSlot(nWidgetIndex)
                    self:UpdateButtonState()
                    Event.Dispatch(EventType.HideAllHoverTips)
                end
            }
        }
        if nStackNum > 0 then
            table.insert(tbBtnState, {
                szName = "使用",
                OnClick = function()
                    ItemData.FastEnchanting({
                        [nDataIndex] = {dwTabType = data.dwTabType, dwIndex = data.dwIndex}
                    })
                    Event.Dispatch(EventType.HideAllHoverTips)
                end
            })
        end

        itemTipScript:SetBtnState(tbBtnState)
    end)
    self:UpdateSlotCount(data, widgetScript)

    self.tbSlotScripts[nWidgetIndex] = widgetScript
end

function UIWuWeiJuePop:UpdateSlotCount(data, script)
    if data and data.dwTabType and data.dwIndex then
        local nStackNum = ItemData.GetItemAmountInPackage(data.dwTabType, data.dwIndex)
        script:SetLabelCount(nStackNum)
        script:SetIconGray(nStackNum <= 0)
        script:SetIconOpacity(nStackNum == 0 and 120 or 255)
    end
end

function UIWuWeiJuePop:UpdateSlotsCount()
    for nSlot, script in pairs(self.tbSlotScripts) do
        if script then
            local nDataIndex = WidgetIndexToDataIndex(nSlot)
            self:UpdateSlotCount(self.tbData[self.nType][self.nConfigIndex][nDataIndex], script)
        end
    end
end

function UIWuWeiJuePop:UpdateButtonState()
    local bHasItem = false
    local bHasEmptyItem = false

    for nSlot, tItem in pairs(self.tbData[self.nType][self.nConfigIndex]) do
        if type(tItem) == "table" and tItem.dwTabType and tItem.dwIndex then
            bHasItem = true
        end
    end

    UIHelper.SetButtonState(self.BtnUse, bHasItem and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnSave, bHasItem and self.bSlotChanged and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnShare, bHasItem and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetVisible(self.BtnRefresh1, bHasItem)
    UIHelper.SetVisible(self.BtnRefresh2, bHasItem)
end

function UIWuWeiJuePop:UpdateKungfuList()
    UIHelper.RemoveAllChildren(self.ScrollViewKungfuList)

    for i, kungfu in ipairs(self.KungfuList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetXinfaGroupBtn, self.ScrollViewKungfuList)
        script:UpdateInfo(kungfu.szName, kungfu.szIcon)
        script:SetClickCallback(function()
            self.bSlotChanged = true
            self:UpdateKungfu(i)
            self:UpdateButtonState()
            UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewKungfuList)
end

function UIWuWeiJuePop:OpenItemSelectPanel(nWidgetIndex, widget)
    local nDataIndex = WidgetIndexToDataIndex(nWidgetIndex)
    local tItemList = self.tSlotInfo[nDataIndex].tItemList
    local tbRecommend = self:GetRecommendItemList(tItemList)
    local tbCount = {}

    for _, tItem in ipairs(tItemList) do
        local nCount = ItemData.GetItemAmountInPackage(tItem.dwTabType, tItem.dwIndex)
        tbCount[tItem.dwIndex] = nCount > 0 and nCount or nil
    end

    self:SortItemList(tItemList, tbCount, tbRecommend)

    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetWuWeiJueTip, widget, TipsLayoutDir.MIDDLE, tbRecommend)
    script:UpdateInfo(tItemList)
    script:SetBtnConfirmFunc(function(nIndex)
        self.tbData[self.nType][self.nConfigIndex][nDataIndex] = tItemList[nIndex]
        self.bSlotChanged = true
        self:UpdateSlot(nWidgetIndex)
        self:UpdateButtonState()
    end)
end

function UIWuWeiJuePop:GetShareContent()
    local xml = {}
    local tbData = self.tbData[self.nType][self.nConfigIndex]
    local nMelee = tbData.bMelee and 1 or 0
    local nHeavy = tbData.bHeavy and 1 or 0
    table.insert(xml, "QuickEating/")
    table.insert(xml, g_pClientPlayer.szName)
    table.insert(xml, "/")
    table.insert(xml, self.KungfuList[self.nKungfuIndex].dwKungfuID or 0)
    table.insert(xml, "/")
    table.insert(xml, nMelee)
    table.insert(xml, "/")
    table.insert(xml, nHeavy)
    for nSlot, tItem in pairs(tbData) do
        if type(tItem) == "table" then
            table.insert(xml, "/")
            table.insert(xml, nSlot)
            table.insert(xml, "/")
            table.insert(xml, tItem.dwID or 0)
        end
    end
    return table.concat(xml)
end

function UIWuWeiJuePop:ShareEnchantingToChat()
    local szLinkInfo = self:GetShareContent()
    local szName = GBKToUTF8(g_pClientPlayer.szName) .. self:GetName()

    ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
end

return UIWuWeiJuePop